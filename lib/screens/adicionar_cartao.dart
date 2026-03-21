import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_stripe/flutter_stripe.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:meu_app_flutter/cores/app_colors.dart';

class AdicionarCartaoScreen extends StatefulWidget {
  const AdicionarCartaoScreen({
    required this.setupIntentClientSecret,
    super.key,
  });

  final String setupIntentClientSecret;

  @override
  State<AdicionarCartaoScreen> createState() => _AdicionarCartaoScreenState();
}

class _AdicionarCartaoScreenState extends State<AdicionarCartaoScreen> {
  final CardEditController _cardController = CardEditController();
  CardFieldInputDetails? _card;
  bool _isSaving = false;

  BillingDetails _defaultBillingDetails() {
    final user = FirebaseAuth.instance.currentUser;
    final name = (user?.displayName ?? '').trim();
    final email = (user?.email ?? '').trim();

    return BillingDetails(
      name: name.isEmpty ? null : name,
      email: email.isEmpty ? null : email,
      address: const Address(
        city: null,
        country: 'BR',
        line1: null,
        line2: null,
        postalCode: null,
        state: null,
      ),
    );
  }

  void _dismissKeyboard() {
    FocusManager.instance.primaryFocus?.unfocus();
  }

  void _showMessage(String message, {bool error = false}) {
    if (!mounted) {
      return;
    }

    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(
          content: Text(message),
          backgroundColor: error ? AppColors.error : AppColors.primary300,
        ),
      );
  }

  bool get _canSave => !_isSaving && (_card?.complete ?? false);

  Future<void> _saveCard() async {
    _dismissKeyboard();

    if (!_canSave) {
      _showMessage('Preencha os dados do cartao para continuar.', error: true);
      return;
    }

    setState(() {
      _isSaving = true;
    });

    try {
      final setupIntent = await Stripe.instance.confirmSetupIntent(
        paymentIntentClientSecret: widget.setupIntentClientSecret,
        params: PaymentMethodParams.card(
          paymentMethodData: PaymentMethodData(
            billingDetails: _defaultBillingDetails(),
          ),
        ),
      );

      final normalizedStatus = setupIntent.status.toLowerCase();
      if (normalizedStatus != 'succeeded') {
        _showMessage(
          'Nao foi possivel salvar o cartao. Tente novamente.',
          error: true,
        );
        return;
      }

      if (!mounted) {
        return;
      }

      Navigator.of(context).pop(true);
    } on StripeException catch (error) {
      _showMessage(
        error.error.localizedMessage ??
            'Nao foi possivel salvar o cartao.',
        error: true,
      );
    } catch (_) {
      _showMessage('Falha ao salvar o cartao.', error: true);
    } finally {
      if (mounted) {
        setState(() {
          _isSaving = false;
        });
      }
    }
  }

  @override
  void dispose() {
    _cardController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final keyboardInset = MediaQuery.of(context).viewInsets.bottom;

    return GestureDetector(
      onTap: _dismissKeyboard,
      behavior: HitTestBehavior.translucent,
      child: Scaffold(
        backgroundColor: Colors.white,
        resizeToAvoidBottomInset: false,
        appBar: AppBar(
          backgroundColor: Colors.white,
          surfaceTintColor: Colors.transparent,
          elevation: 0,
          leading: IconButton(
            icon: SvgPicture.asset(
              'assets/icones/arrow.svg',
              width: 22,
              height: 22,
              colorFilter: const ColorFilter.mode(
                Colors.black,
                BlendMode.srcIn,
              ),
            ),
            onPressed: () => Navigator.pop(context),
          ),
          title: const Text(
            'Adicionar cartao',
            style: TextStyle(
              fontFamily: 'Poppins',
              fontWeight: FontWeight.w600,
              color: Colors.black,
            ),
          ),
        ),
        body: SafeArea(
          child: AnimatedPadding(
            duration: const Duration(milliseconds: 180),
            curve: Curves.easeOut,
            padding: EdgeInsets.only(bottom: keyboardInset),
            child: Column(
              children: [
                Expanded(
                  child: SingleChildScrollView(
                    keyboardDismissBehavior:
                        ScrollViewKeyboardDismissBehavior.onDrag,
                    padding: const EdgeInsets.fromLTRB(20, 12, 20, 20),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Container(
                          width: double.infinity,
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color: const Color(0xFFF8F5EF),
                            borderRadius: BorderRadius.circular(18),
                          ),
                          child: const Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Novo cartao',
                                style: TextStyle(
                                  fontFamily: 'Poppins',
                                  fontSize: 22,
                                  fontWeight: FontWeight.w700,
                                  color: Colors.black,
                                ),
                              ),
                              SizedBox(height: 6),
                              Text(
                                'Preencha os dados abaixo. O cartao sera salvo com seguranca pela Stripe para compras futuras.',
                                style: TextStyle(
                                  fontFamily: 'Poppins',
                                  fontSize: 13,
                                  height: 1.4,
                                  color: Colors.black54,
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 20),
                        const Text(
                          'Dados do cartao',
                          style: TextStyle(
                            fontFamily: 'Poppins',
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                            color: Colors.black87,
                          ),
                        ),
                        const SizedBox(height: 10),
                        DecoratedBox(
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(16),
                            boxShadow: const [
                              BoxShadow(
                                color: Color(0x11000000),
                                blurRadius: 18,
                                offset: Offset(0, 8),
                              ),
                            ],
                          ),
                          child: CardField(
                            controller: _cardController,
                            enablePostalCode: false,
                            countryCode: 'BR',
                            numberHintText: 'Numero do cartao',
                            expirationHintText: 'MM/AA',
                            cvcHintText: 'CVC',
                            androidPlatformViewRenderType:
                                AndroidPlatformViewRenderType.androidView,
                            style: const TextStyle(
                              fontFamily: 'Poppins',
                              fontSize: 16,
                              color: Colors.black,
                            ),
                            decoration: InputDecoration(
                              filled: true,
                              fillColor: Colors.white,
                              contentPadding: const EdgeInsets.symmetric(
                                horizontal: 16,
                                vertical: 18,
                              ),
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(16),
                                borderSide: const BorderSide(
                                  color: Color(0xFFE5E7EB),
                                ),
                              ),
                              enabledBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(16),
                                borderSide: const BorderSide(
                                  color: Color(0xFFE5E7EB),
                                ),
                              ),
                              focusedBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(16),
                                borderSide: const BorderSide(
                                  color: AppColors.primary300,
                                  width: 1.4,
                                ),
                              ),
                            ),
                            onCardChanged: (details) {
                              if (!mounted) {
                                return;
                              }
                              setState(() {
                                _card = details;
                              });
                            },
                          ),
                        ),
                        const SizedBox(height: 14),
                        Container(
                          width: double.infinity,
                          padding: const EdgeInsets.symmetric(
                            horizontal: 14,
                            vertical: 12,
                          ),
                          decoration: BoxDecoration(
                            color: const Color(0xFFF1F9F3),
                            borderRadius: BorderRadius.circular(14),
                            border: Border.all(color: const Color(0xFFCDE8D3)),
                          ),
                          child: const Row(
                            children: [
                              Icon(
                                Icons.lock_outline_rounded,
                                size: 18,
                                color: Color(0xFF2F7A43),
                              ),
                              SizedBox(width: 10),
                              Expanded(
                                child: Text(
                                  'Os dados do cartao nao passam pelo app em texto puro.',
                                  style: TextStyle(
                                    fontFamily: 'Poppins',
                                    fontSize: 12,
                                    fontWeight: FontWeight.w500,
                                    color: Color(0xFF2F7A43),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.fromLTRB(20, 8, 20, 20),
                  child: SizedBox(
                    width: double.infinity,
                    height: 54,
                    child: ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.primary300,
                        disabledBackgroundColor: AppColors.primary100,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(14),
                        ),
                        elevation: 0,
                      ),
                      onPressed: _canSave ? _saveCard : null,
                      child: _isSaving
                          ? const SizedBox(
                              width: 20,
                              height: 20,
                              child: CircularProgressIndicator(
                                strokeWidth: 2.2,
                                color: Colors.white,
                              ),
                            )
                          : const Text(
                              'Salvar cartao',
                              style: TextStyle(
                                fontFamily: 'Poppins',
                                fontSize: 16,
                                fontWeight: FontWeight.w700,
                                color: Colors.white,
                              ),
                            ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
