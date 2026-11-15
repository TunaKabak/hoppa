import 'package:flutter/material.dart';
import 'package:webview_flutter/webview_flutter.dart';

class ThreeDSecurePage extends StatefulWidget {
  final String paymentUrl;

  const ThreeDSecurePage({super.key, required this.paymentUrl});

  @override
  State<ThreeDSecurePage> createState() => _ThreeDSecurePageState();
}

class _ThreeDSecurePageState extends State<ThreeDSecurePage> {
  late final WebViewController _controller;
  bool _isLoading = true;
  bool _hasCompleted = false;

  void _completeWithResult(bool isSuccess) {
    if (_hasCompleted || !mounted) {
      return;
    }
    _hasCompleted = true;
    Navigator.pop(context, isSuccess);
  }

  bool? _resolveCompletionFromUrl(String rawUrl) {
    final uri = Uri.tryParse(rawUrl);
    if (uri == null) {
      return null;
    }

    // Backend callback rotası kesilmeden sunucuya ulaşmalıdır
    if (uri.path.contains('/3d-callback')) {
      return null;
    }

    final result = uri.queryParameters['result']?.toLowerCase();
    final success = uri.queryParameters['success']?.toLowerCase();
    final cancel = uri.queryParameters['cancel']?.toLowerCase();

    if (result == 'success' || success == 'true') {
      return true;
    }

    if (result == 'failed' || cancel == 'true' || success == 'false') {
      return false;
    }

    return null;
  }

  @override
  void initState() {
    super.initState();
    _controller = WebViewController()
      ..setJavaScriptMode(JavaScriptMode.unrestricted)
      ..setNavigationDelegate(
        NavigationDelegate(
          onPageFinished: (String url) {
            if (mounted) {
              setState(() {
                _isLoading = false;
              });
            }
            final completionResult = _resolveCompletionFromUrl(url);
            if (completionResult != null) {
              _completeWithResult(completionResult);
            }
          },
          onNavigationRequest: (NavigationRequest request) {
            final completionResult = _resolveCompletionFromUrl(request.url);
            if (completionResult != null) {
              _completeWithResult(completionResult);
              return NavigationDecision.prevent;
            }
            return NavigationDecision.navigate;
          },
        ),
      )
      ..loadRequest(Uri.parse(widget.paymentUrl));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("3D Secure Ödeme"),
        leading: IconButton(
          icon: const Icon(Icons.close),
          onPressed: () {
            _completeWithResult(false);
          },
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
    );
  }
}
