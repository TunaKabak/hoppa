import 'package:core_auth/core_auth.dart';
import 'package:core_shared/core_shared.dart';
import 'package:core_ui/core_ui.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart' as legacy_provider;
import 'package:consumer_app/apps/consumer/address/delivery_provider.dart';
import 'package:consumer_app/apps/consumer/repositories/address_repository.dart';
import 'package:consumer_app/apps/consumer/checkout/checkout_page.dart';
import 'widgets/auth_layout.dart';
import 'widgets/auth_text_field.dart';

class NameSurnameInputPage extends ConsumerStatefulWidget {
  final bool fromCheckout;

  const NameSurnameInputPage({super.key, this.fromCheckout = false});

  @override
  ConsumerState<NameSurnameInputPage> createState() =>
      _NameSurnameInputPageState();
}

class _NameSurnameInputPageState extends ConsumerState<NameSurnameInputPage> {
  final _nameController = TextEditingController();
  final _surnameController = TextEditingController();
  bool _isLoading = false;

  @override
  void dispose() {
    _nameController.dispose();
    _surnameController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    FocusScope.of(context).unfocus();
    final firstName = _nameController.text.trim();
    final lastName = _surnameController.text.trim();

    if (firstName.isEmpty || lastName.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Lütfen ad ve soyadınızı eksiksiz girin.')),
      );
      return;
    }

    setState(() => _isLoading = true);

    try {
      final apiClient = ref.read(apiClientProvider);
      final response = await apiClient.put(
        '/api/consumer/profile',
        body: {
          'name': firstName,
          'surname': lastName,
        },
      );

      final data = response['data'];
      final authState = ref.read(authControllerProvider);
      if (data != null && authState is AuthAuthenticated) {
        final updatedUser = AuthUser(
          id: authState.user.id,
          phone: authState.user.phone,
          name: data['name']?.toString() ?? firstName,
          surname: data['surname']?.toString() ?? lastName,
          role: authState.user.role,
        );

        await ref
            .read(authControllerProvider.notifier)
            .updateUserData(updatedUser);
      }

      if (mounted) {
        final deliveryProvider =
            legacy_provider.Provider.of<DeliveryProvider>(context, listen: false);
        final guestAddress = deliveryProvider.selectedAddress;

        if (guestAddress != null && guestAddress.id.startsWith('guest')) {
          try {
            final addressRepo = ref.read(addressRepositoryProvider);
            final savedAddress = await addressRepo.createAddress(guestAddress);
            await deliveryProvider.setAddress(savedAddress);
          } catch (e) {
            debugPrint('Guest address migration failed: $e');
          }
        }
      }

      if (mounted) {
        if (widget.fromCheckout) {
          Navigator.pushAndRemoveUntil(
            context,
            MaterialPageRoute(builder: (context) => const CheckoutPage()),
            (route) => route.isFirst,
          );
        } else {
          Navigator.popUntil(context, (route) => route.isFirst);
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Bilgileriniz kaydedilemedi. Lütfen tekrar deneyin.'),
            backgroundColor: HoppaDesignTokens.statusDanger,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final primary = theme.colorScheme.primary;
    final textPrimary = isDark
        ? HoppaDesignTokens.textPrimaryDark
        : HoppaDesignTokens.textPrimaryLight;
    final textSecondary = isDark
        ? HoppaDesignTokens.textSecondaryDark
        : HoppaDesignTokens.textSecondaryLight;

    return AuthLayout(
      showAppBar: false,
      enableGlass: true,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const Center(child: HoppaBrandLogo(height: 44)),
          const SizedBox(height: 16),
          Container(
            width: 56,
            height: 56,
            margin: const EdgeInsets.symmetric(horizontal: 120),
            decoration: BoxDecoration(
              color: primary.withValues(alpha: 0.12),
              shape: BoxShape.circle,
            ),
            child: Icon(Icons.person_add_alt_1_rounded, color: primary, size: 28),
          ),
          const SizedBox(height: 14),
          Text(
            'Profilinizi Tamamlayın',
            textAlign: TextAlign.center,
            style: GoogleFonts.plusJakartaSans(
              fontSize: 22,
              fontWeight: FontWeight.w800,
              color: textPrimary,
              letterSpacing: -0.3,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Kuryemizin siparişi size güvenle teslim edebilmesi için ad ve soyadınızı paylaşın.',
            textAlign: TextAlign.center,
            style: GoogleFonts.plusJakartaSans(
              fontSize: 13.5,
              color: textSecondary,
              height: 1.45,
            ),
          ),
          const SizedBox(height: 26),
          Text(
            'Adınız',
            style: GoogleFonts.plusJakartaSans(
              fontSize: 13,
              fontWeight: FontWeight.w600,
              color: textPrimary,
            ),
          ),
          const SizedBox(height: 8),
          AuthTextField(
            controller: _nameController,
            hint: 'Örn: Ahmet',
            icon: Icons.person_outline_rounded,
            primaryColor: primary,
            textCapitalization: TextCapitalization.words,
            textInputAction: TextInputAction.next,
          ),
          const SizedBox(height: 16),
          Text(
            'Soyadınız',
            style: GoogleFonts.plusJakartaSans(
              fontSize: 13,
              fontWeight: FontWeight.w600,
              color: textPrimary,
            ),
          ),
          const SizedBox(height: 8),
          AuthTextField(
            controller: _surnameController,
            hint: 'Örn: Yılmaz',
            icon: Icons.badge_outlined,
            primaryColor: primary,
            textCapitalization: TextCapitalization.words,
            textInputAction: TextInputAction.done,
            onSubmitted: (_) {
              if (!_isLoading) _submit();
            },
          ),
          const SizedBox(height: 26),
          SizedBox(
            height: 54,
            child: ElevatedButton(
              onPressed: _isLoading ? null : _submit,
              style: ElevatedButton.styleFrom(
                backgroundColor: primary,
                foregroundColor: Colors.white,
                elevation: 0,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
              ),
              child: _isLoading
                  ? const SizedBox(
                      width: 22,
                      height: 22,
                      child: CircularProgressIndicator(
                        color: Colors.white,
                        strokeWidth: 2.2,
                      ),
                    )
                  : Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(
                          'Kaydet ve Devam Et',
                          style: GoogleFonts.plusJakartaSans(
                            fontSize: 15.5,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        const SizedBox(width: 8),
                        const Icon(Icons.check_rounded, size: 19),
                      ],
                    ),
            ),
          ),
        ],
      ),
    );
  }
}
