import 'package:core_ui/core_ui.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:webview_flutter/webview_flutter.dart';

class ThreeDSecurePage extends StatefulWidget {
  final String paymentUrl;

  const ThreeDSecurePage({super.key, required this.paymentUrl});

  @override
  State<ThreeDSecurePage> createState() => _ThreeDSecurePageState();
}

class _ThreeDSecurePageState extends State<ThreeDSecurePage> {
  static const Set<String> _trustedCallbackHosts = {
    'hoppa-backend.onrender.com',
    'api.hoppanow.com',
    'hoppanow.com',
    'www.hoppanow.com',
  };

  late final WebViewController _controller;
  Uri? _initialPaymentUri;
  bool _isLoading = true;
  int _loadingProgress = 0;
  bool _hasCompleted = false;

  bool _isAllowedScheme(Uri uri) {
    if (uri.scheme == 'https') return true;
    if (!kReleaseMode && uri.scheme == 'http') {
      final h = uri.host.toLowerCase();
      return h == 'localhost' || h == '127.0.0.1' || h == '10.0.2.2';
    }
    return false;
  }

  bool _isTrustedCallbackHost(Uri uri) {
    final host = uri.host.toLowerCase();
    if (_trustedCallbackHosts.contains(host) || host.endsWith('.hoppanow.com')) {
      return uri.scheme == 'https';
    }
    if (_initialPaymentUri != null &&
        host == _initialPaymentUri!.host.toLowerCase() &&
        _isAllowedScheme(uri)) {
      return true;
    }
    if (!kReleaseMode &&
        (host == 'localhost' || host == '127.0.0.1' || host == '10.0.2.2')) {
      return true;
    }
    return false;
  }

  void _completeWithResult(bool isSuccess) {
    if (_hasCompleted || !mounted) {
      return;
    }
    _hasCompleted = true;
    Navigator.pop(context, isSuccess);
  }

  Future<void> _confirmAbort3DS() async {
    if (_hasCompleted || !mounted) return;
    final shouldAbort = await showHoppaConfirmDialog(
      context,
      title: '3D Secure İşlemini İptal Et',
      message:
          'Doğrulamayı kapatırsanız ödemeniz tamamlanmayacak ve sepetiniz korunacaktır.',
      confirmText: 'Ödemeyi İptal Et',
      cancelText: 'Doğrulamaya Dön',
      isDestructive: true,
      icon: Icons.gpp_maybe_rounded,
    );
    if (shouldAbort && mounted) {
      _completeWithResult(false);
    }
  }

  bool? _resolveCompletionFromUrl(String rawUrl) {
    final uri = Uri.tryParse(rawUrl);
    if (uri == null || !_isAllowedScheme(uri)) {
      return null;
    }

    // Backend callback/return rotaları kesilmeden sunucuya ulaşmalıdır
    if (uri.path.contains('/3d-callback') ||
        uri.path.contains('/stripe/return') ||
        uri.path.contains('/paytr/pending')) {
      return null;
    }

    // Yalnızca güvenilir Hoppa sunucusu üzerindeki /api/payments/3d-complete sonucu kabul edilir
    if (!uri.path.endsWith('/api/payments/3d-complete') ||
        !_isTrustedCallbackHost(uri)) {
      return null;
    }

    final result = uri.queryParameters['result']?.toLowerCase();
    if (result == 'success') {
      return true;
    }
    if (result == 'failed') {
      return false;
    }

    return null;
  }

  @override
  void initState() {
    super.initState();
    final initialUri = Uri.tryParse(widget.paymentUrl);
    if (initialUri == null || !_isAllowedScheme(initialUri)) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _completeWithResult(false);
      });
      _controller = WebViewController();
      return;
    }
    _initialPaymentUri = initialUri;

    _controller = WebViewController()
      ..setJavaScriptMode(JavaScriptMode.unrestricted)
      ..setNavigationDelegate(
        NavigationDelegate(
          onProgress: (int progress) {
            if (mounted) {
              setState(() {
                _loadingProgress = progress.clamp(0, 100);
              });
            }
          },
          onPageFinished: (String url) {
            if (mounted) {
              setState(() {
                _isLoading = false;
                _loadingProgress = 100;
              });
            }
            final completionResult = _resolveCompletionFromUrl(url);
            if (completionResult != null) {
              _completeWithResult(completionResult);
            }
          },
          onNavigationRequest: (NavigationRequest request) {
            final uri = Uri.tryParse(request.url);
            if (uri == null || !_isAllowedScheme(uri)) {
              return NavigationDecision.prevent;
            }
            final completionResult = _resolveCompletionFromUrl(request.url);
            if (completionResult != null) {
              _completeWithResult(completionResult);
              return NavigationDecision.prevent;
            }
            return NavigationDecision.navigate;
          },
        ),
      )
      ..loadRequest(initialUri);
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, _) {
        if (!didPop) {
          _confirmAbort3DS();
        }
      },
      child: Scaffold(
        appBar: AppBar(
          leading: IconButton(
            icon: const Icon(Icons.close_rounded),
            tooltip: 'Doğrulamayı kapat',
            onPressed: _confirmAbort3DS,
          ),
          titleSpacing: 0,
          title: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(6),
                decoration: BoxDecoration(
                  color: HoppaDesignTokens.brandGreen.withValues(alpha: 0.14),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Icon(
                  Icons.lock_rounded,
                  size: 16,
                  color: HoppaDesignTokens.brandGreen,
                ),
              ),
              const SizedBox(width: 10),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Text(
                    '3D Secure Ödeme',
                    style: TextStyle(fontSize: 15, fontWeight: FontWeight.w700),
                  ),
                  Text(
                    '256-bit SSL Şifreli Banka Oturumu',
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w500,
                      color: theme.colorScheme.onSurfaceVariant,
                    ),
                  ),
                ],
              ),
            ],
          ),
          bottom: PreferredSize(
            preferredSize: const Size.fromHeight(3),
            child: _isLoading
                ? LinearProgressIndicator(
                    value: _loadingProgress > 0 && _loadingProgress < 100
                        ? _loadingProgress / 100.0
                        : null,
                    minHeight: 3,
                    color: HoppaDesignTokens.brandGreen,
                    backgroundColor:
                        HoppaDesignTokens.brandGreen.withValues(alpha: 0.15),
                  )
                : const SizedBox(height: 3),
          ),
        ),
        body: Stack(
          children: [
            WebViewWidget(controller: _controller),
            if (_isLoading)
              const Center(
                child: CircularProgressIndicator(),
              ),
          ],
        ),
      ),
    );
  }
}
