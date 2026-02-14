import 'package:flutter/material.dart';
import 'package:hoppa/core/services/business_service.dart';
import 'package:hoppa/core/services/auth_service.dart';
import 'package:hoppa/features/merchant/merchant_dashboard_page.dart';
import 'package:hoppa/models/business.dart';

class MerchantLoginSelectionPage extends StatefulWidget {
  const MerchantLoginSelectionPage({super.key});

  @override
  State<MerchantLoginSelectionPage> createState() =>
      _MerchantLoginSelectionPageState();
}

class _MerchantLoginSelectionPageState
    extends State<MerchantLoginSelectionPage> {
  final BusinessService _businessService = BusinessService();
  final AuthService _authService = AuthService();
  bool _isLoading = true;
  List<Business> _businesses = [];

  @override
  void initState() {
    super.initState();
    _fetchBusinesses();
  }

  Future<void> _fetchBusinesses() async {
    try {
      final businesses = await _businessService.getBusinessesFuture();
      if (mounted) {
        setState(() {
          _businesses = businesses;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLoading = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("İşletmeler yüklenirken hata oluştu: $e")),
        );
      }
    }
  }

  Future<void> _loginAsMerchant(Business business) async {
    setState(() => _isLoading = true);

    // 1. Önce Anonim/Google Giriş yapılmış mı kontrol et (yoksa anonim giriş yap)
    if (_authService.currentUser == null) {
      await _authService.signInAnonymously();
    }

    if (_authService.currentUser == null) {
      if (mounted) {
        setState(() => _isLoading = false);
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text("Giriş yapılamadı!")));
      }
      return;
    }

    // 2. Kullanıcı rolünü ve businessId'yi güncelle
    await _authService.upgradeToMerchant(business.id);

    if (mounted) {
      setState(() => _isLoading = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text("${business.name} olarak giriş yapılıyor..."),
          backgroundColor: Colors.green,
          duration: const Duration(seconds: 1),
        ),
      );

      // 3. Yönlendir
      Future.delayed(const Duration(seconds: 1), () {
        if (mounted) {
          Navigator.pushAndRemoveUntil(
            context,
            MaterialPageRoute(
              builder: (context) =>
                  MerchantDashboardPage(businessId: business.id),
            ),
            (route) => false,
          );
        }
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("İşletme Seçimi")),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _businesses.isEmpty
          ? const Center(child: Text("Kayıtlı işletme bulunamadı."))
          : ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: _businesses.length,
              itemBuilder: (context, index) {
                final business = _businesses[index];
                return Card(
                  elevation: 2,
                  margin: const EdgeInsets.only(bottom: 12),
                  child: ListTile(
                    leading: CircleAvatar(
                      backgroundImage: NetworkImage(business.logoUrl),
                      backgroundColor: Colors.grey.shade200,
                      onBackgroundImageError: (_, __) {},
                      child: business.logoUrl.isEmpty
                          ? const Icon(Icons.store)
                          : null,
                    ),
                    title: Text(
                      business.name,
                      style: const TextStyle(fontWeight: FontWeight.bold),
                    ),
                    subtitle: Text(business.address),
                    trailing: const Icon(Icons.arrow_forward_ios, size: 16),
                    onTap: () => _loginAsMerchant(business),
                  ),
                );
              },
            ),
    );
  }
}
