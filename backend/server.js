const cors = require('cors');
const dotenv = require('dotenv');
const express = require('express');
const fs = require('fs/promises');
const path = require('path');
const Stripe = require('stripe');

dotenv.config();

const secretKey = process.env.STRIPE_SECRET_KEY;
const port = Number(process.env.PORT || 4242);
const host = process.env.HOST || '0.0.0.0';
const stripeApiVersion = process.env.STRIPE_API_VERSION || '2024-06-20';
const customerStorePath = path.join(__dirname, 'customer-store.json');

if (!secretKey) {
  throw new Error(
    'STRIPE_SECRET_KEY is missing. Set it in backend/.env or in the environment.',
  );
}

const stripe = new Stripe(secretKey);
const app = express();

async function readCustomerStore() {
  try {
    const raw = await fs.readFile(customerStorePath, 'utf8');
    const parsed = JSON.parse(raw);

    if (isNamespacedStore(parsed)) {
      return parsed;
    }

    // Backward compatibility with the old flat format.
    return {
      [getStripeEnvironmentKey()]: parsed,
    };
  } catch (error) {
    if (error && error.code === 'ENOENT') {
      return {};
    }

    throw error;
  }
}

async function writeCustomerStore(store) {
  await fs.writeFile(customerStorePath, JSON.stringify(store, null, 2));
}

function getStripeEnvironmentKey() {
  if (secretKey.startsWith('sk_live_')) {
    return 'live';
  }

  if (secretKey.startsWith('sk_test_')) {
    return 'test';
  }

  return 'unknown';
}

function isPlainObject(value) {
  return value !== null && typeof value === 'object' && !Array.isArray(value);
}

function isNamespacedStore(value) {
  if (!isPlainObject(value)) {
    return false;
  }

  return Object.values(value).every(
    (entry) =>
      isPlainObject(entry) &&
      Object.values(entry).every((customerId) => typeof customerId === 'string'),
  );
}

function getValidatedCustomerKey(value) {
  if (typeof value !== 'string' || value.trim().length < 6) {
    return null;
  }

  return value.trim();
}

async function getOrCreateCustomer(customerKey) {
  const store = await readCustomerStore();
  const environmentKey = getStripeEnvironmentKey();
  const environmentStore = isPlainObject(store[environmentKey])
    ? store[environmentKey]
    : {};
  const existingCustomerId = environmentStore[customerKey];

  if (existingCustomerId) {
    try {
      await stripe.customers.retrieve(existingCustomerId);
      return existingCustomerId;
    } catch (error) {
      const message = error instanceof Error ? error.message : '';
      if (!message.toLowerCase().includes('no such customer')) {
        throw error;
      }
    }
  }

  const customer = await stripe.customers.create({
    metadata: {
      customer_key: customerKey,
      source: 'pedido_facil_flutter',
    },
  });

  store[environmentKey] = {
    ...environmentStore,
    [customerKey]: customer.id,
  };
  await writeCustomerStore(store);
  return customer.id;
}

app.use(cors({ origin: true }));
app.use(express.json());

app.get('/health', (_request, response) => {
  response.json({ ok: true });
});

app.post('/create-payment-intent', async (request, response) => {
  try {
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
        error: 'amountInCents must be a positive integer in the smallest currency unit',
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
    const message =
      error instanceof Error ? error.message : 'Unexpected Stripe error';

    return response.status(500).json({ error: message });
  }
});

app.get('/payment-methods', async (request, response) => {
  try {
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
    const message =
      error instanceof Error ? error.message : 'Unexpected Stripe error';

    return response.status(500).json({ error: message });
  }
});

app.post('/customer-sheet', async (request, response) => {
  try {
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
    const message =
      error instanceof Error ? error.message : 'Unexpected Stripe error';

    return response.status(500).json({ error: message });
  }
});

app.listen(port, host, () => {
  console.log(`Stripe backend listening on http://${host}:${port}`);
});
