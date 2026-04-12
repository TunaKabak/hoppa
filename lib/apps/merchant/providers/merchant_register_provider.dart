import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../services/merchant_auth_service.dart';

class MerchantRegisterProvider extends ChangeNotifier {
  final MerchantAuthService _authService = MerchantAuthService();

  // ----- Form Controllers -----
  final emailController = TextEditingController();
  final passwordController = TextEditingController();
  final confirmPasswordController = TextEditingController();

  final businessNameController = TextEditingController();
  final msNumberController = TextEditingController();
  final taxNumberController = TextEditingController();

  final phoneController = TextEditingController();
  final fullAddressController = TextEditingController();
  String? selectedDistrict;

  // ----- Form Keys -----
  final GlobalKey<FormState> formKeyStep1 = GlobalKey<FormState>();
  final GlobalKey<FormState> formKeyStep2 = GlobalKey<FormState>();
  final GlobalKey<FormState> formKeyStep3 = GlobalKey<FormState>();

  // ----- Focus Nodes -----
  final emailFocus = FocusNode();
  final passwordFocus = FocusNode();
  final confirmPasswordFocus = FocusNode();

  final businessNameFocus = FocusNode();
  final msNumberFocus = FocusNode();
  final taxNumberFocus = FocusNode();

  final phoneFocus = FocusNode();
  final fullAddressFocus = FocusNode();

  // ----- State Variables -----
  int _currentStep = 0;
  int get currentStep => _currentStep;
  final int totalSteps = 3;

  bool _isLoading = false;
  bool get isLoading => _isLoading;

  List<String> _districts = [];
  List<String> get districts => _districts;

  bool _isDistrictsLoading = false;
  bool get isDistrictsLoading => _isDistrictsLoading;

  String? _errorMessage;
  String? get errorMessage => _errorMessage;

  MerchantRegisterProvider() {
    _fetchDistricts();
    Future.delayed(const Duration(milliseconds: 300), () {
      if (!emailFocus.offset.dy.isNaN) {
        emailFocus.requestFocus();
      }
    });
  }

  @override
  void dispose() {
    emailController.dispose();
    passwordController.dispose();
    confirmPasswordController.dispose();
    businessNameController.dispose();
    msNumberController.dispose();
    taxNumberController.dispose();
    phoneController.dispose();
    fullAddressController.dispose();

    emailFocus.dispose();
    passwordFocus.dispose();
    confirmPasswordFocus.dispose();
    businessNameFocus.dispose();
    msNumberFocus.dispose();
    taxNumberFocus.dispose();
    phoneFocus.dispose();
    fullAddressFocus.dispose();

    super.dispose();
  }

  Future<void> _fetchDistricts() async {
    _isDistrictsLoading = true;
    notifyListeners();
    try {
      final snapshot = await FirebaseFirestore.instance
          .collection('districts')
          .orderBy('name')
          .get();
      if (snapshot.docs.isNotEmpty) {
        _districts = snapshot.docs.map((e) => e.data()['name'] as String).toList();
      } else {
        _setFallbackDistricts();
      }
    } catch (_) {
      _setFallbackDistricts();
    } finally {
      _isDistrictsLoading = false;
      notifyListeners();
    }
  }

  void _setFallbackDistricts() {
    _districts = ['Lefkoşa', 'Girne', 'Gazimağusa', 'Güzelyurt', 'İskele', 'Lefke'];
  }

  void setDistrict(String? value) {
    selectedDistrict = value;
    notifyListeners();
  }

  /// Geçerli adımın validasyonunu yapar.
  /// Başarılıysa [_currentStep]'i artırır ve [notifyListeners()] çağırır.
  /// UI katmanı bu değişikliği watch ederek PageController animasyonunu tetikler.
  bool tryGoNext() {
    final valid = _validateCurrentStep();
    if (valid && _currentStep < totalSteps - 1) {
      _currentStep++;
      notifyListeners(); // UI bunu izleyip animateToPage çağıracak
    }
    return valid;
  }

  bool tryGoPrevious() {
    if (_currentStep > 0) {
      _currentStep--;
      notifyListeners();
      return true;
    }
    return false;
  }

  bool _validateCurrentStep() {
    switch (_currentStep) {
      case 0:
        return formKeyStep1.currentState?.validate() ?? false;
      case 1:
        return formKeyStep2.currentState?.validate() ?? false;
      case 2:
        final isFormValid = formKeyStep3.currentState?.validate() ?? false;
        if (selectedDistrict == null || selectedDistrict!.isEmpty) {
          _showError("Lütfen bulunduğunuz ilçeyi seçiniz.");
          return false;
        }
        return isFormValid;
      default:
        return false;
    }
  }

  void _showError(String message) {
    _errorMessage = message;
    notifyListeners();
    Future.delayed(Duration.zero, () {
      _errorMessage = null;
      notifyListeners();
    });
  }

  Future<bool> registerMerchant() async {
    if (!_validateCurrentStep()) return false;

    _isLoading = true;
    notifyListeners();

    try {
      await _authService.registerMerchant(
        email: emailController.text.trim(),
        password: passwordController.text,
        businessName: businessNameController.text.trim(),
        msNumber: msNumberController.text.trim(),
        taxNumber: taxNumberController.text.trim(),
        phone: '+905${phoneController.text.trim().replaceAll(RegExp(r'\s+'), '')}',
        district: selectedDistrict!,
        fullAddress: fullAddressController.text.trim(),
      );
      return true;
    } catch (e) {
      _showError(e.toString());
      return false;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }
}
