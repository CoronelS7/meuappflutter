const cors = require('cors');
const express = require('express');
const Stripe = require('stripe');
const { onRequest } = require('firebase-functions/v2/https');
const { defineSecret } = require('firebase-functions/params');
const logger = require('firebase-functions/logger');

const stripeSecretKey = defineSecret('STRIPE_SECRET_KEY');
const zeroBounceApiKey = defineSecret('ZEROBOUNCE_API_KEY');
const stripeApiVersion = process.env.STRIPE_API_VERSION || '2024-06-20';

let stripeClient = null;
let stripeClientKey = null;
const customerCache = new Map();

function getStripe() {
  const secretKey = stripeSecretKey.value();
  if (!secretKey) {
    throw new Error('STRIPE_SECRET_KEY is missing in Firebase Secrets.');
  }

  if (!stripeClient || stripeClientKey !== secretKey) {
    stripeClient = new Stripe(secretKey);
    stripeClientKey = secretKey;
  }

  return stripeClient;
}

function getValidatedCustomerKey(value) {
  if (typeof value !== 'string' || value.trim().length < 6) {
    return null;
  }

  return value.trim();
}

function toSafeStripeErrorMessage(error) {
  if (!(error instanceof Error)) {
    return 'Unexpected Stripe error';
  }

  const message = error.message || '';
  if (/invalid api key/i.test(message)) {
    return 'Stripe server key is invalid. Update STRIPE_SECRET_KEY in Firebase Functions Secrets.';
  }

  return message;
}

function getValidatedEmail(value) {
  if (typeof value !== 'string') {
    return null;
  }

  const email = value.trim().toLowerCase();
  if (!email || email.length > 254 || !email.includes('@')) {
    return null;
  }

  return email;
}

async function getOrCreateCustomer(customerKey) {
  const stripe = getStripe();
  const existingCustomerId = await findCustomerByKey(customerKey);
  if (existingCustomerId) {
    return existingCustomerId;
  }

  const customer = await stripe.customers.create({
    metadata: {
      customer_key: customerKey,
      source: 'pedido_facil_flutter',
    },
  });

  customerCache.set(customerKey, customer.id);
  return customer.id;
}

async function findCustomerByKey(customerKey) {
  const stripe = getStripe();
  const cachedCustomerId = customerCache.get(customerKey);
  if (cachedCustomerId) {
    try {
      const customer = await stripe.customers.retrieve(cachedCustomerId);
      if (customer && !customer.deleted) {
        return cachedCustomerId;
      }
    } catch (_error) {
      // Cache invalido: continua para busca no Stripe.
    }

    customerCache.delete(customerKey);
  }

  const escapedCustomerKey = customerKey.replace(/'/g, "\\'");

  try {
    const result = await stripe.customers.search({
      query: `metadata['customer_key']:'${escapedCustomerKey}'`,
      limit: 1,
    });

    if (result.data.length > 0) {
      const customerId = result.data[0].id;
      customerCache.set(customerKey, customerId);
      return customerId;
    }
  } catch (error) {
    const normalizedCode =
      typeof error?.code === 'string' ? error.code.toLowerCase() : '';
    const normalizedMessage =
      error instanceof Error ? error.message.toLowerCase() : '';
    const canFallbackToList =
      normalizedCode.includes('parameter_unknown') ||
      normalizedCode.includes('invalid_request_error') ||
      normalizedMessage.includes('search') ||
      normalizedMessage.includes('query');

    if (!canFallbackToList) {
      throw error;
    }
  }

  // Fallback para contas sem suporte ao endpoint search.
  let hasMore = true;
  let startingAfter;

  while (hasMore) {
    const customersPage = await stripe.customers.list({
      limit: 100,
      starting_after: startingAfter,
    });

    for (const customer of customersPage.data) {
      if (customer.metadata?.customer_key === customerKey) {
        customerCache.set(customerKey, customer.id);
        return customer.id;
      }
    }

    hasMore = customersPage.has_more;
    startingAfter =
      customersPage.data.length > 0
        ? customersPage.data[customersPage.data.length - 1].id
        : undefined;
  }

  return null;
}

const app = express();
app.use(cors({ origin: true }));
app.use(express.json());

app.get('/health', (_request, response) => {
  response.json({ ok: true });
});

app.post('/validate-email', async (request, response) => {
  try {
    const apiKey = zeroBounceApiKey.value();
    if (!apiKey) {
      return response.status(500).json({
        error:
          'ZEROBOUNCE_API_KEY is missing in Firebase Functions Secrets.',
      });
    }

    const email = getValidatedEmail(request.body?.email);
    if (!email) {
      return response.status(400).json({
        error: 'email must be a valid string',
      });
    }

    const zeroBounceUrl = new URL('https://api.zerobounce.net/v2/validate');
    zeroBounceUrl.searchParams.set('api_key', apiKey);
    zeroBounceUrl.searchParams.set('email', email);

    const zeroBounceResponse = await fetch(zeroBounceUrl.toString());
    const payload = await zeroBounceResponse.json().catch(() => ({}));

    if (!zeroBounceResponse.ok) {
      return response.status(502).json({
        error: 'ZeroBounce validation failed',
      });
    }

    const status =
      typeof payload?.status === 'string' ? payload.status.toLowerCase() : '';
    const didYouMean =
      typeof payload?.did_you_mean === 'string' ? payload.did_you_mean : '';

    return response.json({
      isValid: status === 'valid',
      status,
      didYouMean,
    });
  } catch (error) {
    logger.error('validate-email failed', {
      message: error instanceof Error ? error.message : String(error),
    });
    return response.status(500).json({
      error: 'Nao foi possivel validar o e-mail agora.',
    });
  }
});

app.post('/create-payment-intent', async (request, response) => {
  try {
    const stripe = getStripe();
    const {
      amountInCents,
      amount,
      currency = 'brl',
      description = 'Pedido Facil',
      customerKey,
      saveCard = false,
    } = request.body ?? {};

    const normalizedAmount = Number.isInteger(amountInCents)
      ? amountInCents
      : amount;

    if (!Number.isInteger(normalizedAmount) || normalizedAmount <= 0) {
      return response.status(400).json({
        error:
          'amountInCents must be a positive integer in the smallest currency unit',
      });
    }

    const validatedCustomerKey = getValidatedCustomerKey(customerKey);
    if (!validatedCustomerKey) {
      return response.status(400).json({
        error: 'customerKey must be a non-empty string',
      });
    }

    const customerId = await getOrCreateCustomer(validatedCustomerKey);
    const ephemeralKey = await stripe.ephemeralKeys.create(
      { customer: customerId },
      { apiVersion: stripeApiVersion },
    );

    const paymentIntent = await stripe.paymentIntents.create({
      amount: normalizedAmount,
      currency,
      customer: customerId,
      payment_method_types: ['card'],
      description,
      ...(saveCard ? { setup_future_usage: 'on_session' } : {}),
      metadata: {
        source: 'pedido_facil_flutter',
        save_card: String(saveCard),
      },
    });

    return response.json({
      clientSecret: paymentIntent.client_secret,
      customerId,
      customerEphemeralKeySecret: ephemeralKey.secret,
    });
  } catch (error) {
    const message = toSafeStripeErrorMessage(error);
    logger.error('create-payment-intent failed', { message });
    return response.status(500).json({ error: message });
  }
});

app.get('/payment-methods', async (request, response) => {
  try {
    const stripe = getStripe();
    const validatedCustomerKey = getValidatedCustomerKey(
      request.query.customerKey,
    );

    if (!validatedCustomerKey) {
      return response.status(400).json({
        error: 'customerKey must be a non-empty string',
      });
    }

    const customerId = await getOrCreateCustomer(validatedCustomerKey);
    const customer = await stripe.customers.retrieve(customerId);
    const paymentMethods = await stripe.customers.listPaymentMethods(customerId, {
      type: 'card',
      limit: 10,
    });

    const rawDefaultPaymentMethodId =
      typeof customer !== 'string'
        ? customer.invoice_settings?.default_payment_method
        : null;
    const defaultPaymentMethodId =
      typeof rawDefaultPaymentMethodId === 'string'
        ? rawDefaultPaymentMethodId
        : rawDefaultPaymentMethodId?.id ?? null;

    return response.json({
      customerId,
      paymentMethods: paymentMethods.data.map((paymentMethod, index) => ({
        id: paymentMethod.id,
        brand: paymentMethod.card?.brand ?? 'card',
        last4: paymentMethod.card?.last4 ?? '0000',
        expMonth: paymentMethod.card?.exp_month ?? 0,
        expYear: paymentMethod.card?.exp_year ?? 0,
        isDefault:
          paymentMethod.id === defaultPaymentMethodId ||
          (!defaultPaymentMethodId && index === 0),
      })),
    });
  } catch (error) {
    const message = toSafeStripeErrorMessage(error);
    logger.error('payment-methods failed', { message });
    return response.status(500).json({ error: message });
  }
});

app.post('/customer-sheet', async (request, response) => {
  try {
    const stripe = getStripe();
    const validatedCustomerKey = getValidatedCustomerKey(
      request.body?.customerKey,
    );

    if (!validatedCustomerKey) {
      return response.status(400).json({
        error: 'customerKey must be a non-empty string',
      });
    }

    const customerId = await getOrCreateCustomer(validatedCustomerKey);
    const ephemeralKey = await stripe.ephemeralKeys.create(
      { customer: customerId },
      { apiVersion: stripeApiVersion },
    );
    const setupIntent = await stripe.setupIntents.create({
      customer: customerId,
      payment_method_types: ['card'],
      usage: 'on_session',
    });

    return response.json({
      customerId,
      customerEphemeralKeySecret: ephemeralKey.secret,
      setupIntentClientSecret: setupIntent.client_secret,
    });
  } catch (error) {
    const message = toSafeStripeErrorMessage(error);
    logger.error('customer-sheet failed', { message });
    return response.status(500).json({ error: message });
  }
});

exports.stripeApi = onRequest(
  {
    region: 'southamerica-east1',
    timeoutSeconds: 60,
    memory: '256MiB',
    secrets: [stripeSecretKey, zeroBounceApiKey],
  },
  app,
);
