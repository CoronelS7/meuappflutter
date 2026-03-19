import 'package:flutter/material.dart';
import 'package:flutter_stripe/flutter_stripe.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:meu_app_flutter/cores/app_colors.dart';
import 'package:meu_app_flutter/stripe/customer_identity_service.dart';
import 'package:meu_app_flutter/stripe/payment_methods_service.dart';
import 'package:meu_app_flutter/stripe/stripe_config.dart';

class PagamentosScreen extends StatefulWidget {
  const PagamentosScreen({super.key});

  @override
  State<PagamentosScreen> createState() => _PagamentosScreenState();
}

class _PagamentosScreenState extends State<PagamentosScreen> {
  final CustomerIdentityService _customerIdentityService =
      CustomerIdentityService();
  final PaymentMethodsService _paymentMethodsService =
      const PaymentMethodsService();

  List<SavedPaymentMethod> _cards = const [];
  bool _isLoading = true;
  bool _isAddingCard = false;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _loadCards();
  }

  Future<void> _loadCards() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final customerKey = await _customerIdentityService
          .getOrCreateCustomerKey();
      final cards = await _paymentMethodsService.listSavedCards(
        customerKey: customerKey,
      );

      if (!mounted) {
        return;
      }

      setState(() {
        _cards = cards;
        _isLoading = false;
      });
    } on PaymentMethodsException catch (error) {
      if (!mounted) {
        return;
      }

      setState(() {
        _errorMessage = error.message;
        _isLoading = false;
      });
    } catch (_) {
      if (!mounted) {
        return;
      }

      setState(() {
        _errorMessage = 'Nao foi possivel carregar os cartoes salvos.';
        _isLoading = false;
      });
    }
  }

  Future<void> _openCustomerSheet() async {
    if (StripeConfig.publishableKey.isEmpty) {
      _showSnackBar(
        'Defina STRIPE_PUBLISHABLE_KEY para adicionar cartoes no Stripe.',
      );
      return;
    }

    setState(() {
      _isAddingCard = true;
    });

    try {
      final customerKey = await _customerIdentityService
          .getOrCreateCustomerKey();
      final session = await _paymentMethodsService.createCustomerSheetSession(
        customerKey: customerKey,
      );

      await Stripe.instance.initCustomerSheet(
        customerSheetInitParams: CustomerSheetInitParams(
          customerId: session.customerId,
          customerEphemeralKeySecret: session.customerEphemeralKeySecret,
          setupIntentClientSecret: session.setupIntentClientSecret,
          merchantDisplayName: 'Pedido Facil',
          headerTextForSelectionScreen: 'Cartoes salvos',
          googlePayEnabled: false,
          applePayEnabled: false,
        ),
      );

      await Stripe.instance.presentCustomerSheet();
      await _loadCards();
    } on StripeException catch (error) {
      _showSnackBar(
        error.error.localizedMessage ??
            'Nao foi possivel abrir o CustomerSheet.',
      );
    } on PaymentMethodsException catch (error) {
      _showSnackBar(error.message);
    } catch (_) {
      _showSnackBar('Falha ao abrir o gerenciador de cartoes.');
    } finally {
      if (mounted) {
        setState(() {
          _isAddingCard = false;
        });
      }
    }
  }

  void _showSnackBar(String message) {
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(content: Text(message)));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        elevation: 0,
        backgroundColor: Colors.white,
        surfaceTintColor: Colors.transparent,
        leading: IconButton(
          onPressed: () => Navigator.pop(context),
          icon: SvgPicture.asset(
            'assets/icones/arrow.svg',
            width: 24,
            height: 24,
            colorFilter: const ColorFilter.mode(Colors.black, BlendMode.srcIn),
          ),
        ),
        centerTitle: true,
        title: const Text(
          'Pagamentos',
          style: TextStyle(
            color: Colors.black,
            fontFamily: 'Poppins',
            fontWeight: FontWeight.w600,
            fontSize: 18,
          ),
        ),
      ),
      body: RefreshIndicator(
        onRefresh: _loadCards,
        child: ListView(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 18),
          children: [
            const Text(
              'Cartoes',
              style: TextStyle(
                fontFamily: 'Poppins',
                fontSize: 16,
                fontWeight: FontWeight.w600,
                color: Colors.black54,
              ),
            ),
            const SizedBox(height: 12),
            if (_isLoading)
              const Padding(
                padding: EdgeInsets.symmetric(vertical: 40),
                child: Center(child: CircularProgressIndicator()),
              )
            else if (_errorMessage != null)
              _messageCard(
                icon: Icons.error_outline,
                iconColor: AppColors.error,
                title: _errorMessage!,
                subtitle: 'Verifique o backend Stripe e tente novamente.',
                actionLabel: 'Tentar novamente',
                onAction: _loadCards,
              )
            else if (_cards.isEmpty)
              _messageCard(
                icon: Icons.credit_card_off_outlined,
                iconColor: AppColors.gray400,
                title: 'Nenhum cartao salvo ainda',
                subtitle:
                    'Use o checkout ou o botao abaixo para adicionar o primeiro cartao.',
              )
            else
              ..._cards.map(
                (card) => Padding(
                  padding: const EdgeInsets.only(bottom: 14),
                  child: _cardItem(card: card),
                ),
              ),
            const SizedBox(height: 14),
            _addCardTile(
              isLoading: _isAddingCard,
              onTap: _isAddingCard ? null : _openCustomerSheet,
            ),
          ],
        ),
      ),
    );
  }

  Widget _cardItem({required SavedPaymentMethod card}) {
    return Material(
      color: Colors.white,
      borderRadius: BorderRadius.circular(14),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: const Color(0xFFE3E3E3)),
        ),
        child: Row(
          children: [
            _cardBrandBadge(card.brand),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    '**** ${card.last4}',
                    style: const TextStyle(
                      fontFamily: 'Poppins',
                      fontSize: 15,
                      fontWeight: FontWeight.w600,
                      color: Colors.black,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    'Expira ${card.expiryLabel}',
                    style: const TextStyle(
                      fontFamily: 'Poppins',
                      fontSize: 12,
                      color: Colors.black54,
                    ),
                  ),
                ],
              ),
            ),
            if (card.isDefault)
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 5,
                ),
                decoration: BoxDecoration(
                  color: const Color(0xFFF4E7DD),
                  borderRadius: BorderRadius.circular(999),
                ),
                child: const Text(
                  'Padrao',
                  style: TextStyle(
                    fontFamily: 'Poppins',
                    fontSize: 12,
                    color: Color(0xFF9A5B2E),
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _cardBrandBadge(String brand) {
    final normalizedBrand = brand.toLowerCase();

    if (normalizedBrand == 'mastercard') {
      return Container(
        width: 48,
        height: 34,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: const Color(0xFFEAEAEA)),
        ),
        child: Stack(
          alignment: Alignment.center,
          children: const [
            Positioned(
              left: 12,
              child: CircleAvatar(
                radius: 7,
                backgroundColor: Color(0xFFF97316),
              ),
            ),
            Positioned(
              right: 12,
              child: CircleAvatar(
                radius: 7,
                backgroundColor: Color(0xFFEF4444),
              ),
            ),
          ],
        ),
      );
    }

    return Container(
      width: 48,
      height: 34,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: const Color(0xFFEAEAEA)),
      ),
      child: Text(
        normalizedBrand == 'visa' ? 'VISA' : normalizedBrand.toUpperCase(),
        style: const TextStyle(
          fontFamily: 'Poppins',
          fontSize: 10,
          fontWeight: FontWeight.w600,
          color: AppColors.gray600,
        ),
      ),
    );
  }

  Widget _messageCard({
    required IconData icon,
    required Color iconColor,
    required String title,
    required String subtitle,
    String? actionLabel,
    Future<void> Function()? onAction,
  }) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: const Color(0xFFE3E3E3)),
      ),
      child: Column(
        children: [
          Icon(icon, color: iconColor, size: 28),
          const SizedBox(height: 10),
          Text(
            title,
            textAlign: TextAlign.center,
            style: const TextStyle(
              fontFamily: 'Poppins',
              fontSize: 15,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            subtitle,
            textAlign: TextAlign.center,
            style: const TextStyle(
              fontFamily: 'Poppins',
              fontSize: 13,
              color: Colors.black54,
            ),
          ),
          if (actionLabel != null && onAction != null) ...[
            const SizedBox(height: 12),
            OutlinedButton(
              onPressed: () {
                onAction();
              },
              child: Text(actionLabel),
            ),
          ],
        ],
      ),
    );
  }

  Widget _addCardTile({required bool isLoading, required VoidCallback? onTap}) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        borderRadius: BorderRadius.circular(8),
        onTap: onTap,
        child: Container(
          width: double.infinity,
          height: 56,
          decoration: BoxDecoration(
            border: Border.all(color: AppColors.gray500),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Center(
            child: isLoading
                ? const SizedBox(
                    height: 20,
                    width: 20,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : const Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.add),
                      SizedBox(width: 8),
                      Text(
                        'Adicionar cartao',
                        style: TextStyle(
                          fontFamily: 'Poppins',
                          fontSize: 16,
                          fontWeight: FontWeight.w500,
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
