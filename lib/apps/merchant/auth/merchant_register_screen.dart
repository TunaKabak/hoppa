import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:google_fonts/google_fonts.dart';
import '../providers/merchant_register_provider.dart';
import 'widgets/auth_text_field.dart';

class MerchantRegisterScreen extends StatelessWidget {
  const MerchantRegisterScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (_) => MerchantRegisterProvider(),
      child: const _RegisterView(),
    );
  }
}

class _RegisterView extends StatefulWidget {
  const _RegisterView();

  @override
  State<_RegisterView> createState() => _RegisterViewState();
}

class _RegisterViewState extends State<_RegisterView> {
  // PageController tamamen UI katmanında yaşar.
  // Provider'dan bağımsız olduğu için animateToPage güvenilir şekilde çalışır.
  late final PageController _pageController;
  int _prevStep = 0;

  static const kPrimaryColor = Color(0xFF00A651);

  @override
  void initState() {
    super.initState();
    _pageController = PageController();

    // Provider değişikliklerini SnackBar için dinle
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<MerchantRegisterProvider>().addListener(_onProviderChange);
    });
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  void _onProviderChange() {
    if (!mounted) return;
    final provider = context.read<MerchantRegisterProvider>();

    // Adım değiştiyse animasyonu UI katmanında tetikle
    if (provider.currentStep != _prevStep) {
      _pageController.animateToPage(
        provider.currentStep,
        duration: const Duration(milliseconds: 400),
        curve: Curves.easeInOut,
      );
      _prevStep = provider.currentStep;
    }

    // Hata mesajı varsa SnackBar göster
    if (provider.errorMessage != null && provider.errorMessage!.isNotEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Row(
            children: [
              const Icon(Icons.error_outline, color: Colors.white),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  provider.errorMessage!,
                  style: GoogleFonts.inter(fontWeight: FontWeight.w500),
                ),
              ),
            ],
          ),
          backgroundColor: Colors.redAccent.shade700,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          margin: const EdgeInsets.all(16),
          duration: const Duration(seconds: 4),
        ),
      );
    }
  }

  void _submitForm(MerchantRegisterProvider provider) async {
    FocusScope.of(context).unfocus();
    final success = await provider.registerMerchant();
    if (success && mounted) {
      _showSuccessDialog();
    }
  }

  void _showSuccessDialog() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => Dialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        elevation: 0,
        backgroundColor: Colors.transparent,
        child: Container(
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(24),
            boxShadow: const [
              BoxShadow(color: Colors.black12, blurRadius: 24, offset: Offset(0, 12)),
            ],
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(color: Colors.green.shade50, shape: BoxShape.circle),
                child: const Icon(Icons.check_circle_rounded, color: Colors.green, size: 48),
              ),
              const SizedBox(height: 16),
              Text(
                "Başvuru Alındı!",
                style: GoogleFonts.poppins(fontSize: 22, fontWeight: FontWeight.bold, color: Colors.black87),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 12),
              Text(
                "Başvurunuz başarıyla sistemimize ulaştı. Ekibimiz kısa süre içerisinde sizinle iletişime geçerek süreci tamamlayacaktır.",
                style: GoogleFonts.inter(fontSize: 14, color: Colors.grey.shade600, height: 1.5),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 24),
              SizedBox(
                width: double.infinity,
                height: 50,
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: kPrimaryColor,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                    elevation: 0,
                  ),
                  onPressed: () {
                    Navigator.pop(ctx);
                    Navigator.pop(context);
                  },
                  child: Text("Harika, Giriş'e Dön", style: GoogleFonts.inter(fontWeight: FontWeight.w600, color: Colors.white)),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<MerchantRegisterProvider>();

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded, color: Colors.black87, size: 20),
          onPressed: () {
            if (provider.currentStep > 0) {
              context.read<MerchantRegisterProvider>().tryGoPrevious();
            } else {
              Navigator.pop(context);
            }
          },
        ),
        title: Text(
          "İşletme Başvurusu",
          style: GoogleFonts.poppins(fontSize: 16, fontWeight: FontWeight.w600, color: Colors.black87),
        ),
        centerTitle: true,
      ),
      // Sabit Alt Buton - PageView ve içerikten tamamen bağımsız
      bottomNavigationBar: _buildBottomBar(provider),
      body: SafeArea(
        child: Column(
          children: [
            _buildProgressBar(provider),
            Expanded(
              child: PageView(
                controller: _pageController, // UI katmanının controller'ı
                physics: const NeverScrollableScrollPhysics(),
                children: [
                  _buildStep1Account(provider),
                  _buildStep2Business(provider),
                  _buildStep3Contact(provider),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ──────────────────────────────────────────────────
  // PROGRESS BAR
  // ──────────────────────────────────────────────────

  Widget _buildProgressBar(MerchantRegisterProvider provider) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
      child: Row(
        children: List.generate(provider.totalSteps, (index) {
          final isCompleted = index <= provider.currentStep;
          return Expanded(
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 350),
              margin: EdgeInsets.only(right: index == provider.totalSteps - 1 ? 0 : 8),
              height: 6,
              decoration: BoxDecoration(
                color: isCompleted ? kPrimaryColor : Colors.grey.shade200,
                borderRadius: BorderRadius.circular(4),
              ),
            ),
          );
        }),
      ),
    );
  }

  // ──────────────────────────────────────────────────
  // BOTTOM BAR (PageView'den bağımsız)
  // ──────────────────────────────────────────────────

  Widget _buildBottomBar(MerchantRegisterProvider provider) {
    final isLastStep = provider.currentStep == provider.totalSteps - 1;

    return Container(
      padding: EdgeInsets.only(
        left: 24, right: 24, top: 16,
        bottom: MediaQuery.of(context).padding.bottom > 0
            ? MediaQuery.of(context).padding.bottom + 8
            : 24,
      ),
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border(top: BorderSide(color: Colors.grey.shade100)),
        boxShadow: const [BoxShadow(color: Colors.black12, offset: Offset(0, -4), blurRadius: 16)],
      ),
      child: SizedBox(
        width: double.infinity,
        height: 56,
        child: ElevatedButton(
          style: ElevatedButton.styleFrom(
            backgroundColor: kPrimaryColor,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
            elevation: 0,
          ),
          onPressed: provider.isLoading
              ? null
              : () {
                  FocusScope.of(context).unfocus();
                  final p = context.read<MerchantRegisterProvider>();
                  if (isLastStep) {
                    _submitForm(p);
                  } else {
                    // Validasyonu Provider çalıştırır, adımı artırır, notifyListeners çağırır
                    // _onProviderChange bunu yakalar ve animateToPage çağırır
                    p.tryGoNext();
                  }
                },
          child: provider.isLoading
              ? const SizedBox(height: 24, width: 24, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2.5))
              : Text(
                  isLastStep ? "Başvuruyu Tamamla" : "Devam Et",
                  style: GoogleFonts.inter(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.white),
                ),
        ),
      ),
    );
  }

  // ──────────────────────────────────────────────────
  // ADIM 1: HESAP BİLGİLERİ
  // ──────────────────────────────────────────────────

  Widget _buildStep1Account(MerchantRegisterProvider provider) {
    return Form(
      key: provider.formKeyStep1,
      child: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(24, 24, 24, 100),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              "Hesap Bilgileri",
              style: GoogleFonts.poppins(fontSize: 24, fontWeight: FontWeight.bold, color: Colors.black87),
            ),
            const SizedBox(height: 8),
            Text(
              "İşletme paneline yetkili girişiniz için gerekli hesap bilgilerini oluşturun.",
              style: GoogleFonts.inter(fontSize: 14, color: Colors.grey.shade600, height: 1.5),
            ),
            const SizedBox(height: 32),
            AuthTextField(
              controller: provider.emailController,
              focusNode: provider.emailFocus,
              textInputAction: TextInputAction.next,
              onSubmitted: (_) => provider.passwordFocus.requestFocus(),
              hint: "E-posta Adresi",
              icon: Icons.alternate_email_rounded,
              primaryColor: kPrimaryColor,
              validator: (value) {
                if (value == null || value.trim().isEmpty || !RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$').hasMatch(value.trim())) {
                  return "Lütfen geçerli bir e-posta adresi giriniz.";
                }
                return null;
              },
            ),
            const SizedBox(height: 16),
            AuthTextField(
              controller: provider.passwordController,
              focusNode: provider.passwordFocus,
              textInputAction: TextInputAction.next,
              onSubmitted: (_) => provider.confirmPasswordFocus.requestFocus(),
              hint: "Şifre (Min 6 Karakter)",
              icon: Icons.lock_outline_rounded,
              isPassword: true,
              primaryColor: kPrimaryColor,
              validator: (value) {
                if (value == null || value.length < 6) return "Şifreniz en az 6 karakterden oluşmalıdır.";
                return null;
              },
            ),
            const SizedBox(height: 16),
            AuthTextField(
              controller: provider.confirmPasswordController,
              focusNode: provider.confirmPasswordFocus,
              textInputAction: TextInputAction.done,
              onSubmitted: (_) {
                FocusScope.of(context).unfocus();
                context.read<MerchantRegisterProvider>().tryGoNext();
              },
              hint: "Şifre Tekrar",
              icon: Icons.lock_reset_rounded,
              isPassword: true,
              primaryColor: kPrimaryColor,
              validator: (value) {
                if (value == null || value.isEmpty) return "Lütfen şifrenizi tekrar giriniz.";
                if (value != provider.passwordController.text) return "Şifreler eşleşmiyor.";
                return null;
              },
            ),
          ],
        ),
      ),
    );
  }

  // ──────────────────────────────────────────────────
  // ADIM 2: RESMİ İŞLETME DETAYLARI
  // ──────────────────────────────────────────────────

  Widget _buildStep2Business(MerchantRegisterProvider provider) {
    return Form(
      key: provider.formKeyStep2,
      child: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(24, 24, 24, 100),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              "Resmi İşletme Detayları",
              style: GoogleFonts.poppins(fontSize: 24, fontWeight: FontWeight.bold, color: Colors.black87),
            ),
            const SizedBox(height: 8),
            Text(
              "Doğrulama süreçlerimiz için resmi kayıt numaralarınızı eksiksiz giriniz.",
              style: GoogleFonts.inter(fontSize: 14, color: Colors.grey.shade600, height: 1.5),
            ),
            const SizedBox(height: 32),
            AuthTextField(
              controller: provider.businessNameController,
              focusNode: provider.businessNameFocus,
              textInputAction: TextInputAction.next,
              onSubmitted: (_) => provider.msNumberFocus.requestFocus(),
              hint: "İşletme Adı (Marka Adınız)",
              icon: Icons.storefront_rounded,
              primaryColor: kPrimaryColor,
              validator: (v) => v == null || v.trim().isEmpty ? "Lütfen işletmenizin adını giriniz." : null,
            ),
            const SizedBox(height: 16),
            AuthTextField(
              controller: provider.msNumberController,
              focusNode: provider.msNumberFocus,
              textInputAction: TextInputAction.next,
              onSubmitted: (_) => provider.taxNumberFocus.requestFocus(),
              hint: "MŞ No (Şirket Kayıt Numarası)",
              icon: Icons.assignment_ind_outlined,
              primaryColor: kPrimaryColor,
              validator: (v) => v == null || v.trim().isEmpty ? "Lütfen Şirket Kayıt Numarasını (MŞ No) giriniz." : null,
            ),
            const SizedBox(height: 16),
            AuthTextField(
              controller: provider.taxNumberController,
              focusNode: provider.taxNumberFocus,
              textInputAction: TextInputAction.done,
              onSubmitted: (_) {
                FocusScope.of(context).unfocus();
                context.read<MerchantRegisterProvider>().tryGoNext();
              },
              hint: "Vergi Numarası",
              icon: Icons.receipt_long_rounded,
              primaryColor: kPrimaryColor,
              validator: (v) => v == null || v.trim().isEmpty ? "Lütfen Vergi Numarasını giriniz." : null,
            ),
          ],
        ),
      ),
    );
  }

  // ──────────────────────────────────────────────────
  // ADIM 3: İLETİŞİM & KONUM
  // ──────────────────────────────────────────────────

  Widget _buildStep3Contact(MerchantRegisterProvider provider) {
    return Form(
      key: provider.formKeyStep3,
      child: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(24, 24, 24, 100),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              "İletişim & Konum",
              style: GoogleFonts.poppins(fontSize: 24, fontWeight: FontWeight.bold, color: Colors.black87),
            ),
            const SizedBox(height: 8),
            Text(
              "Size ve kuryelerimize kolayca ulaşabilmemiz için KKTC içindeki iletişim detaylarınızı belirtin.",
              style: GoogleFonts.inter(fontSize: 14, color: Colors.grey.shade600, height: 1.5),
            ),
            const SizedBox(height: 32),

            // İlçe Dropdown
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.grey.shade200),
              ),
              child: DropdownButtonHideUnderline(
                child: DropdownButton<String>(
                  value: provider.selectedDistrict,
                  isExpanded: true,
                  hint: Row(
                    children: [
                      Icon(Icons.map_outlined, color: Colors.grey.shade400, size: 22),
                      const SizedBox(width: 12),
                      Text(
                        provider.isDistrictsLoading ? "İlçeler yükleniyor..." : "Bağlı Olduğunuz İlçe",
                        style: GoogleFonts.inter(color: Colors.grey.shade400, fontSize: 16, fontWeight: FontWeight.w600),
                      ),
                    ],
                  ),
                  icon: const Icon(Icons.keyboard_arrow_down_rounded, color: Colors.grey),
                  items: provider.districts.map((district) {
                    return DropdownMenuItem(
                      value: district,
                      child: Row(
                        children: [
                          Icon(Icons.location_city_rounded, color: kPrimaryColor, size: 22),
                          const SizedBox(width: 12),
                          Text(district, style: GoogleFonts.inter(fontSize: 16, fontWeight: FontWeight.w600, color: Colors.black87)),
                        ],
                      ),
                    );
                  }).toList(),
                  onChanged: provider.isLoading ? null : (val) {
                    provider.setDistrict(val);
                    provider.phoneFocus.requestFocus();
                  },
                ),
              ),
            ),
            const SizedBox(height: 16),

            // Telefon
            AuthTextField(
              controller: provider.phoneController,
              focusNode: provider.phoneFocus,
              textInputAction: TextInputAction.next,
              onSubmitted: (_) => provider.fullAddressFocus.requestFocus(),
              hint: "33 123 45 67",
              icon: Icons.phone_in_talk_rounded,
              primaryColor: kPrimaryColor,
              isPhone: true,
              prefixText: "+90 5",
              validator: (value) {
                final phone = value?.trim().replaceAll(RegExp(r'\s+'), '') ?? '';
                if (!RegExp(r'^[0-9]{9}$').hasMatch(phone)) {
                  return "Lütfen telefon numaranızı eksiksiz giriniz (Örn: 33 123 45 67).";
                }
                return null;
              },
            ),
            const SizedBox(height: 16),

            // Açık Adres (Multiline)
            TextFormField(
              controller: provider.fullAddressController,
              focusNode: provider.fullAddressFocus,
              textInputAction: TextInputAction.done,
              maxLines: 4,
              minLines: 3,
              validator: (v) => v == null || v.trim().isEmpty ? "Lütfen işletmenizin açık adresini giriniz." : null,
              autovalidateMode: AutovalidateMode.onUserInteraction,
              style: GoogleFonts.inter(fontSize: 16, fontWeight: FontWeight.w500, color: Colors.black87),
              decoration: InputDecoration(
                hintText: "Açık adres (Bina, Sokak, Kapı No, vb.)",
                hintStyle: TextStyle(color: Colors.grey.shade400),
                filled: true,
                fillColor: Colors.white,
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: BorderSide.none),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(16),
                  borderSide: BorderSide(color: Colors.grey.shade200),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(16),
                  borderSide: const BorderSide(color: kPrimaryColor, width: 2),
                ),
                contentPadding: const EdgeInsets.all(20),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
