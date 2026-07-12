import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart' as legacy_provider;
import 'package:core_auth/core_auth.dart';
import 'package:core_network/core_network.dart';
import 'package:consumer_app/apps/consumer/address/delivery_provider.dart';
import 'package:consumer_app/apps/consumer/repositories/address_repository.dart';
import 'package:consumer_app/apps/consumer/checkout/checkout_page.dart';

class NameSurnameInputPage extends ConsumerStatefulWidget {
  final bool fromCheckout;

  const NameSurnameInputPage({super.key, this.fromCheckout = false});

  @override
  ConsumerState<NameSurnameInputPage> createState() => _NameSurnameInputPageState();
}

class _NameSurnameInputPageState extends ConsumerState<NameSurnameInputPage> {
  final _formKey = GlobalKey<FormState>();
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
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);

    try {
      final apiClient = ref.read(apiClientProvider);
      final response = await apiClient.put(
        '/api/consumer/profile',
        body: {
          'name': _nameController.text.trim(),
          'surname': _surnameController.text.trim(),
        },
      );

      final data = response['data'];
      final authState = ref.read(authControllerProvider);
      if (data != null && authState is AuthAuthenticated) {
        final updatedUser = AuthUser(
          id: authState.user.id,
          phone: authState.user.phone,
          name: data['name']?.toString() ?? _nameController.text.trim(),
          surname: data['surname']?.toString() ?? _surnameController.text.trim(),
          role: authState.user.role,
        );

        // Update local auth controller & shared preferences
        await ref.read(authControllerProvider.notifier).updateUserData(updatedUser);
      }

      // Auto-migrate guest address if exists
      if (mounted) {
        final deliveryProvider = legacy_provider.Provider.of<DeliveryProvider>(context, listen: false);
        final guestAddress = deliveryProvider.selectedAddress;
        
        if (guestAddress != null && guestAddress.id.startsWith('guest')) {
          try {
            final addressRepo = ref.read(addressRepositoryProvider);
            // Save address to database
            final savedAddress = await addressRepo.createAddress(guestAddress);
            // Select the newly generated address
            await deliveryProvider.setAddress(savedAddress);
          } catch (e) {
            debugPrint("Guest address migration failed: $e");
          }
        }
      }

      if (mounted) {
        if (widget.fromCheckout) {
          // If came from checkout, navigate to checkout page directly
          Navigator.pushAndRemoveUntil(
            context,
            MaterialPageRoute(builder: (context) => const CheckoutPage()),
            (route) => route.isFirst,
          );
        } else {
          // Otherwise, pop back to home page
          Navigator.popUntil(context, (route) => route.isFirst);
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text("Kaydedilemedi: ${e.toString()}"),
            backgroundColor: Colors.red,
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
    const kPrimaryColor = Color(0xFF00A651);

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        automaticallyImplyLeading: false,
        title: Image.asset(
          'assets/images/hoppa_logo.png',
          height: 40,
          fit: BoxFit.contain,
          errorBuilder: (context, error, stackTrace) => Text(
            "Hoppa",
            style: GoogleFonts.poppins(
              fontWeight: FontWeight.bold,
              color: kPrimaryColor,
              fontSize: 24,
            ),
          ),
        ),
        centerTitle: true,
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24.0),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const SizedBox(height: 20),
                Text(
                  "Hesabınızı Tamamlayın 👤",
                  style: GoogleFonts.poppins(
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                    color: Colors.black87,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 8),
                Text(
                  "Lütfen siparişlerinizde ve iletişimde kullanılmak üzere isim ve soyisminizi giriniz.",
                  style: GoogleFonts.inter(
                    fontSize: 14,
                    color: Colors.grey.shade600,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 40),

                // Name Field
                Text(
                  "Adınız",
                  style: GoogleFonts.poppins(
                    fontWeight: FontWeight.bold,
                    fontSize: 14,
                    color: Colors.black87,
                  ),
                ),
                const SizedBox(height: 8),
                TextFormField(
                  controller: _nameController,
                  keyboardType: TextInputType.name,
                  textCapitalization: TextCapitalization.words,
                  decoration: InputDecoration(
                    hintText: "Örn: Ahmet",
                    filled: true,
                    fillColor: Colors.grey.shade50,
                    contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(16),
                      borderSide: BorderSide(color: Colors.grey.shade200),
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(16),
                      borderSide: BorderSide(color: Colors.grey.shade200),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(16),
                      borderSide: const BorderSide(color: kPrimaryColor, width: 1.5),
                    ),
                  ),
                  validator: (v) => v!.trim().isEmpty ? "Lütfen adınızı girin" : null,
                ),
                const SizedBox(height: 24),

                // Surname Field
                Text(
                  "Soyadınız",
                  style: GoogleFonts.poppins(
                    fontWeight: FontWeight.bold,
                    fontSize: 14,
                    color: Colors.black87,
                  ),
                ),
                const SizedBox(height: 8),
                TextFormField(
                  controller: _surnameController,
                  keyboardType: TextInputType.name,
                  textCapitalization: TextCapitalization.words,
                  decoration: InputDecoration(
                    hintText: "Örn: Yılmaz",
                    filled: true,
                    fillColor: Colors.grey.shade50,
                    contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(16),
                      borderSide: BorderSide(color: Colors.grey.shade200),
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(16),
                      borderSide: BorderSide(color: Colors.grey.shade200),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(16),
                      borderSide: const BorderSide(color: kPrimaryColor, width: 1.5),
                    ),
                  ),
                  validator: (v) => v!.trim().isEmpty ? "Lütfen soyadınızı girin" : null,
                ),
                const SizedBox(height: 40),

                // Submit Button
                SizedBox(
                  height: 56,
                  child: ElevatedButton(
                    onPressed: _isLoading ? null : _submit,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: kPrimaryColor,
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                      ),
                      elevation: 0,
                    ),
                    child: _isLoading
                        ? const SizedBox(
                            width: 24,
                            height: 24,
                            child: CircularProgressIndicator(
                              color: Colors.white,
                              strokeWidth: 2,
                            ),
                          )
                        : Text(
                            "Kaydet ve Devam Et",
                            style: GoogleFonts.poppins(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
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
