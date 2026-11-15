import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:core_auth/core_auth.dart';

class CourierLoginScreen extends ConsumerStatefulWidget {
  const CourierLoginScreen({super.key});

  @override
  ConsumerState<CourierLoginScreen> createState() => _CourierLoginScreenState();
}

class _CourierLoginScreenState extends ConsumerState<CourierLoginScreen> {
  static const Color _hoppaOrange = Color(0xFFFF6B00);
  static const Color _hoppaOrangeDeep = Color(0xFFE05500);

  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();
  final TextEditingController _phoneController = TextEditingController();
  final TextEditingController _otpController = TextEditingController();

  bool _otpSent = false;
  String _submittedPhone = '';
  String? _localError;

  @override
  void dispose() {
    _phoneController.dispose();
    _otpController.dispose();
    super.dispose();
  }

  /// Normalizes common TR/KKTC or E.164 phone inputs into `+90...` format.
  /// Returns `null` if the input does not match a valid phone pattern.
  String? _normalizePhone(String raw) {
    final cleaned = raw.replaceAll(RegExp(r'[\s\-\(\)]'), '').trim();
    if (cleaned.isEmpty) return null;

    if (cleaned.startsWith('+')) {
      if (RegExp(r'^\+[1-9]\d{8,14}$').hasMatch(cleaned)) {
        return cleaned;
      }
      return null;
    }

    if (RegExp(r'^05\d{9}$').hasMatch(cleaned)) {
      return '+90${cleaned.substring(1)}';
    }
    if (RegExp(r'^905\d{9}$').hasMatch(cleaned)) {
      return '+$cleaned';
    }
    if (RegExp(r'^5\d{9}$').hasMatch(cleaned)) {
      return '+90$cleaned';
    }

    return null;
  }

  String? _validatePhone(String? value) {
    final normalized = _normalizePhone(value ?? '');
    if (normalized == null) {
      return 'Geçerli bir telefon numarası girin (ör. +90 5XX XXX XX XX)';
    }
    return null;
  }

  String? _validateOtp(String? value) {
    final code = (value ?? '').trim();
    if (!RegExp(r'^\d{6}$').hasMatch(code)) {
      return 'Lütfen 6 haneli doğrulama kodunu eksiksiz girin';
    }
    return null;
  }

  Future<void> _handleSendOtp() async {
    FocusScope.of(context).unfocus();
    setState(() => _localError = null);

    if (!(_formKey.currentState?.validate() ?? false)) return;

    final normalized = _normalizePhone(_phoneController.text);
    if (normalized == null) return;

    _submittedPhone = normalized;
    await ref.read(authControllerProvider.notifier).sendOtp(normalized);
  }

  Future<void> _handleVerifyOtp() async {
    FocusScope.of(context).unfocus();
    setState(() => _localError = null);

    if (!(_formKey.currentState?.validate() ?? false)) return;

    final phone = _submittedPhone.isNotEmpty
        ? _submittedPhone
        : (_normalizePhone(_phoneController.text) ?? '');
    if (phone.isEmpty) {
      setState(() {
        _otpSent = false;
        _localError = 'Telefon numarası doğrulanamadı. Lütfen tekrar girin.';
      });
      return;
    }

    await ref
        .read(authControllerProvider.notifier)
        .verifyOtp(phone, _otpController.text.trim());
  }

  void _resetToPhoneStep() {
    setState(() {
      _otpSent = false;
      _localError = null;
      _otpController.clear();
    });
  }

  @override
  Widget build(BuildContext context) {
    final authState = ref.watch(authControllerProvider);
    final isLoading = authState is AuthLoading;
    final theme = Theme.of(context);

    ref.listen<AuthState>(authControllerProvider, (previous, next) {
      if (!mounted) return;
      if (next is OtpSentState) {
        setState(() {
          _otpSent = true;
          _submittedPhone = next.phoneNumber;
          _localError = null;
        });
      } else if (next is AuthInitial) {
        setState(() {
          _otpSent = false;
          _localError = null;
        });
      }
    });

    final displayError =
        _localError ?? (authState is AuthError ? authState.errorMessage : null);

    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [_hoppaOrange, _hoppaOrangeDeep, Color(0xFFF8FAFC)],
            stops: [0.0, 0.34, 0.34],
          ),
        ),
        child: SafeArea(
          child: Center(
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 440),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    // Brand header
                    Column(
                      children: [
                        Container(
                          width: 80,
                          height: 80,
                          decoration: BoxDecoration(
                            color: Colors.white,
                            shape: BoxShape.circle,
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withValues(alpha: 0.14),
                                blurRadius: 18,
                                offset: const Offset(0, 8),
                              ),
                            ],
                          ),
                          child: const Icon(
                            Icons.two_wheeler_rounded,
                            size: 42,
                            color: _hoppaOrange,
                          ),
                        ),
                        const SizedBox(height: 16),
                        Text(
                          'Hoppa Kurye',
                          style: theme.textTheme.headlineMedium?.copyWith(
                            color: Colors.white,
                            fontWeight: FontWeight.w800,
                            letterSpacing: -0.5,
                          ),
                        ),
                        const SizedBox(height: 6),
                        Text(
                          'Hızlı teslimat, canlı takip ve kazanç paneli',
                          textAlign: TextAlign.center,
                          style: theme.textTheme.bodyMedium?.copyWith(
                            color: Colors.white.withValues(alpha: 0.92),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 28),

                    // Form Card
                    Card(
                      elevation: 6,
                      shadowColor: Colors.black.withValues(alpha: 0.08),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(20),
                        side: const BorderSide(color: Color(0xFFE2E8F0)),
                      ),
                      child: Padding(
                        padding: const EdgeInsets.all(24),
                        child: Form(
                          key: _formKey,
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.stretch,
                            children: [
                              Text(
                                _otpSent
                                    ? 'SMS Doğrulama'
                                    : 'Telefon ile Giriş Yap',
                                style: theme.textTheme.titleLarge?.copyWith(
                                  fontWeight: FontWeight.w700,
                                  color: const Color(0xFF0F172A),
                                ),
                              ),
                              const SizedBox(height: 6),
                              Text(
                                _otpSent
                                    ? '$_submittedPhone numarasına gönderilen 6 haneli kodu girin.'
                                    : 'Kayıtlı telefon numaranızı girerek tek kullanımlık doğrulama kodu alın.',
                                style: theme.textTheme.bodySmall?.copyWith(
                                  color: const Color(0xFF64748B),
                                  height: 1.4,
                                ),
                              ),
                              const SizedBox(height: 20),

                              if (!_otpSent) ...[
                                TextFormField(
                                  controller: _phoneController,
                                  keyboardType: TextInputType.phone,
                                  textInputAction: TextInputAction.done,
                                  enabled: !isLoading,
                                  validator: _validatePhone,
                                  onChanged: (_) {
                                    if (_localError != null) {
                                      setState(() => _localError = null);
                                    }
                                  },
                                  onFieldSubmitted: (_) => _handleSendOtp(),
                                  decoration: const InputDecoration(
                                    labelText: 'Telefon Numarası',
                                    hintText: '+90 5XX XXX XX XX',
                                    prefixIcon: Icon(
                                      Icons.phone_android_rounded,
                                    ),
                                  ),
                                ),
                                const SizedBox(height: 18),
                                ElevatedButton(
                                  onPressed: isLoading ? null : _handleSendOtp,
                                  child: isLoading
                                      ? const SizedBox(
                                          height: 20,
                                          width: 20,
                                          child: CircularProgressIndicator(
                                            strokeWidth: 2.2,
                                            color: Colors.white,
                                          ),
                                        )
                                      : const Text('Doğrulama Kodu Gönder'),
                                ),
                              ] else ...[
                                TextFormField(
                                  controller: _otpController,
                                  keyboardType: TextInputType.number,
                                  textInputAction: TextInputAction.done,
                                  maxLength: 6,
                                  enabled: !isLoading,
                                  autofillHints: const [
                                    AutofillHints.oneTimeCode,
                                  ],
                                  inputFormatters: [
                                    FilteringTextInputFormatter.digitsOnly,
                                  ],
                                  validator: _validateOtp,
                                  onChanged: (_) {
                                    if (_localError != null) {
                                      setState(() => _localError = null);
                                    }
                                  },
                                  onFieldSubmitted: (_) => _handleVerifyOtp(),
                                  style: const TextStyle(
                                    fontSize: 20,
                                    fontWeight: FontWeight.w700,
                                    letterSpacing: 6,
                                  ),
                                  textAlign: TextAlign.center,
                                  decoration: const InputDecoration(
                                    labelText: '6 Haneli OTP Kodu',
                                    hintText: '• • • • • •',
                                    counterText: '',
                                    prefixIcon: Icon(Icons.lock_outline),
                                  ),
                                ),
                                const SizedBox(height: 18),
                                ElevatedButton(
                                  onPressed: isLoading
                                      ? null
                                      : _handleVerifyOtp,
                                  child: isLoading
                                      ? const SizedBox(
                                          height: 20,
                                          width: 20,
                                          child: CircularProgressIndicator(
                                            strokeWidth: 2.2,
                                            color: Colors.white,
                                          ),
                                        )
                                      : const Text('Doğrula ve Giriş Yap'),
                                ),
                                const SizedBox(height: 10),
                                Row(
                                  mainAxisAlignment:
                                      MainAxisAlignment.spaceBetween,
                                  children: [
                                    TextButton.icon(
                                      onPressed: isLoading
                                          ? null
                                          : _resetToPhoneStep,
                                      icon: const Icon(
                                        Icons.arrow_back_rounded,
                                        size: 18,
                                      ),
                                      label: const Text('Numarayı Değiştir'),
                                    ),
                                    TextButton(
                                      onPressed: isLoading
                                          ? null
                                          : () {
                                              if (_submittedPhone.isNotEmpty) {
                                                ref
                                                    .read(
                                                      authControllerProvider
                                                          .notifier,
                                                    )
                                                    .sendOtp(_submittedPhone);
                                              }
                                            },
                                      child: const Text('Kodu Tekrar Gönder'),
                                    ),
                                  ],
                                ),
                              ],

                              if (displayError != null &&
                                  displayError.isNotEmpty) ...[
                                const SizedBox(height: 16),
                                Container(
                                  padding: const EdgeInsets.all(12),
                                  decoration: BoxDecoration(
                                    color: const Color(0xFFFEF2F2),
                                    borderRadius: BorderRadius.circular(12),
                                    border: Border.all(
                                      color: const Color(0xFFFECACA),
                                    ),
                                  ),
                                  child: Row(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      const Icon(
                                        Icons.error_outline_rounded,
                                        color: Color(0xFFDC2626),
                                        size: 20,
                                      ),
                                      const SizedBox(width: 8),
                                      Expanded(
                                        child: Text(
                                          displayError,
                                          style: const TextStyle(
                                            color: Color(0xFF991B1B),
                                            fontSize: 13,
                                            fontWeight: FontWeight.w500,
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ],
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
