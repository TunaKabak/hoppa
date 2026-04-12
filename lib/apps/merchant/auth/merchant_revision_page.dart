import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../services/merchant_auth_service.dart';
import 'widgets/auth_text_field.dart';

class MerchantRevisionPage extends StatefulWidget {
  final Map<String, dynamic> userData;

  const MerchantRevisionPage({super.key, required this.userData});

  @override
  State<MerchantRevisionPage> createState() => _MerchantRevisionPageState();
}

class _MerchantRevisionPageState extends State<MerchantRevisionPage> {
  final MerchantAuthService _authService = MerchantAuthService();
  final _formKey = GlobalKey<FormState>();

  late TextEditingController _businessNameController;
  late TextEditingController _msNumberController;
  late TextEditingController _taxNumberController;
  late TextEditingController _phoneController;
  late TextEditingController _fullAddressController;

  static const kPrimaryColor = Color(0xFF00A651);

  final List<String> _districts = [
    'Lefkoşa',
    'Girne',
    'Mağusa',
    'Güzelyurt',
    'İskele',
    'Lefke',
  ];
  String? _selectedDistrict;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _businessNameController = TextEditingController(text: widget.userData['businessName']);
    _msNumberController = TextEditingController(text: widget.userData['msNumber']);
    _taxNumberController = TextEditingController(text: widget.userData['taxNumber']);
    
    // Split prefix if needed, for simplicity we just remove spaces and format
    String phone = widget.userData['phone'] ?? '';
    _phoneController = TextEditingController(text: phone);
    
    _fullAddressController = TextEditingController(text: widget.userData['fullAddress']);
    
    _selectedDistrict = widget.userData['district'];
    // Fallback in case old district is invalid
    if (_selectedDistrict != null && !_districts.contains(_selectedDistrict)) {
      _selectedDistrict = null;
    }
  }

  @override
  void dispose() {
    _businessNameController.dispose();
    _msNumberController.dispose();
    _taxNumberController.dispose();
    _phoneController.dispose();
    _fullAddressController.dispose();
    super.dispose();
  }

  Future<void> _submitRevision() async {
    if (!_formKey.currentState!.validate()) return;
    if (_selectedDistrict == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Lütfen ilçenizi seçiniz.'), backgroundColor: Colors.red),
      );
      return;
    }

    setState(() => _isLoading = true);

    try {
      await _authService.submitRevision(
        uid: FirebaseAuth.instance.currentUser!.uid,
        businessName: _businessNameController.text.trim(),
        msNumber: _msNumberController.text.trim(),
        taxNumber: _taxNumberController.text.trim(),
        phone: _phoneController.text.trim(),
        district: _selectedDistrict!,
        fullAddress: _fullAddressController.text.trim(),
      );

      // Successfully updated, it will just automatically update the auth stream and rebuild AuthWrapper 
      // which will see status == 'pending' and show the pending message.
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(e.toString()), backgroundColor: Colors.red),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  Future<void> _handleLogout() async {
    await _authService.signOut();
  }

  @override
  Widget build(BuildContext context) {
    final revisionMessage = widget.userData['revisionMessage'] ?? 'Bilgilerinizde eksiklikler bulundu. Lütfen gerekli alanları güncelleyiniz.';

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        title: Text("Bilgi Güncelleme", style: GoogleFonts.poppins(color: Colors.black, fontWeight: FontWeight.w600)),
        centerTitle: true,
        actions: [
          IconButton(
            icon: const Icon(Icons.logout, color: Colors.black87),
            onPressed: _handleLogout,
            tooltip: 'Çıkış Yap',
          )
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.all(24),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Revision Alert Box
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: Colors.orange.shade50,
                        border: Border.all(color: Colors.orange.shade200),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Icon(Icons.warning_amber_rounded, color: Colors.orange.shade800),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text("Yönetici Mesajı", style: TextStyle(fontWeight: FontWeight.bold, color: Colors.orange.shade900)),
                                const SizedBox(height: 4),
                                Text(revisionMessage, style: TextStyle(color: Colors.orange.shade900, fontSize: 14)),
                              ],
                            ),
                          )
                        ],
                      ),
                    ),
                    const SizedBox(height: 32),

                    Text("İşletme Detayları", style: GoogleFonts.poppins(fontSize: 18, fontWeight: FontWeight.w600)),
                    const SizedBox(height: 16),
                    
                    AuthTextField(
                      controller: _businessNameController,
                      hint: "İşletme Adı",
                      icon: Icons.storefront_rounded,
                      primaryColor: kPrimaryColor,
                      validator: (v) => v == null || v.trim().isEmpty ? "Lütfen ad giriniz." : null,
                    ),
                    const SizedBox(height: 16),
                    
                    AuthTextField(
                      controller: _msNumberController,
                      hint: "MŞ No",
                      icon: Icons.assignment_ind_outlined,
                      primaryColor: kPrimaryColor,
                      validator: (v) => v == null || v.trim().isEmpty ? "Gerekli alan" : null,
                    ),
                    const SizedBox(height: 16),
                    
                    AuthTextField(
                      controller: _taxNumberController,
                      hint: "Vergi Numarası",
                      icon: Icons.receipt_long_rounded,
                      primaryColor: kPrimaryColor,
                      validator: (v) => v == null || v.trim().isEmpty ? "Gerekli alan" : null,
                    ),
                    const SizedBox(height: 32),

                    Text("İletişim & Konum", style: GoogleFonts.poppins(fontSize: 18, fontWeight: FontWeight.w600)),
                    const SizedBox(height: 16),

                    // District Dropdown
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: Colors.grey.shade200),
                      ),
                      child: DropdownButtonHideUnderline(
                        child: DropdownButton<String>(
                          value: _selectedDistrict,
                          isExpanded: true,
                          hint: Text("Bağlı Olduğunuz İlçe", style: GoogleFonts.inter(color: Colors.grey.shade400, fontWeight: FontWeight.w600)),
                          items: _districts.map((d) => DropdownMenuItem(value: d, child: Text(d))).toList(),
                          onChanged: (val) => setState(() => _selectedDistrict = val),
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),

                    AuthTextField(
                      controller: _phoneController,
                      hint: "33 123 45 67",
                      icon: Icons.phone_in_talk_rounded,
                      primaryColor: kPrimaryColor,
                      isPhone: true,
                      validator: (v) => v == null || v.trim().isEmpty ? "Gerekli alan" : null,
                    ),
                    const SizedBox(height: 16),

                    TextFormField(
                      controller: _fullAddressController,
                      maxLines: 4,
                      minLines: 3,
                      validator: (v) => v == null || v.trim().isEmpty ? "Açık adres giriniz." : null,
                      decoration: InputDecoration(
                        hintText: "Açık adres",
                        filled: true,
                        fillColor: Colors.white,
                        enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: BorderSide(color: Colors.grey.shade200)),
                        focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: const BorderSide(color: kPrimaryColor, width: 2)),
                      ),
                    ),
                    
                    const SizedBox(height: 48),
                    
                    SizedBox(
                      width: double.infinity,
                      height: 56,
                      child: ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: kPrimaryColor,
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                        ),
                        onPressed: _submitRevision,
                        child: Text("Tekrar Gönder", style: GoogleFonts.inter(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.white)),
                      ),
                    ),
                    const SizedBox(height: 40),
                  ],
                ),
              ),
            ),
    );
  }
}
