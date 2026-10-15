import 'package:flutter/material.dart';
import 'package:webview_flutter/webview_flutter.dart';

class LivenessWebResult {
  const LivenessWebResult({required this.sessionId, this.status});

  final String sessionId;
  final String? status;
}

class BytidLivenessScreen extends StatefulWidget {
  const BytidLivenessScreen({
    required this.sessionUrl,
    required this.sessionId,
    super.key,
  });

  final String sessionUrl;
  final String sessionId;

  static LivenessWebResult? completionFromUrl(
    String value,
    String expectedSessionId,
  ) {
    final uri = Uri.tryParse(value);
    if (uri == null ||
        uri.scheme != 'transfa' ||
        uri.host != 'kyc' ||
        uri.path != '/liveness-complete') {
      return null;
    }
    final returnedId = uri.queryParameters['liveness_session_id'];
    if (returnedId == null || returnedId != expectedSessionId) return null;
    return LivenessWebResult(
      sessionId: returnedId,
      status: uri.queryParameters['status'],
    );
  }

  @override
  State<BytidLivenessScreen> createState() => _BytidLivenessScreenState();
}

class _BytidLivenessScreenState extends State<BytidLivenessScreen> {
  late final WebViewController _controller;
  late Uri _currentUri;
  int _progress = 0;
  String? _pageError;
  bool _hasReturned = false;

  @override
  void initState() {
    super.initState();
    _currentUri = Uri.parse(widget.sessionUrl);
    _controller =
        WebViewController(
            onPermissionRequest: (request) async {
              if (_isTrustedCameraOrigin(_currentUri)) {
                await request.grant();
              } else {
                await request.deny();
              }
            },
          )
          ..setJavaScriptMode(JavaScriptMode.unrestricted)
          ..setBackgroundColor(const Color(0xFFF7F8FA))
          ..setNavigationDelegate(
            NavigationDelegate(
              onProgress: (progress) {
                if (mounted) setState(() => _progress = progress);
              },
              onPageStarted: (value) {
                final uri = Uri.tryParse(value);
                if (uri != null) _currentUri = uri;
                if (mounted) setState(() => _pageError = null);
              },
              onNavigationRequest: (request) {
                final result = BytidLivenessScreen.completionFromUrl(
                  request.url,
                  widget.sessionId,
                );
                if (result != null) {
                  _returnToVerification(result);
                  return NavigationDecision.prevent;
                }
                final uri = Uri.tryParse(request.url);
                if (uri == null || uri.scheme != 'https') {
                  return NavigationDecision.prevent;
                }
                _currentUri = uri;
                return NavigationDecision.navigate;
              },
              onWebResourceError: (error) {
                if (error.isForMainFrame == true && mounted) {
                  setState(() {
                    _pageError =
                        'The secure face check could not load. Check your connection and try again.';
                  });
                }
              },
            ),
          )
          ..loadRequest(_currentUri);
  }

  bool _isTrustedCameraOrigin(Uri uri) {
    if (uri.scheme != 'https') return false;
    final host = uri.host.toLowerCase();
    final sessionHost = Uri.parse(widget.sessionUrl).host.toLowerCase();
    return host == sessionHost ||
        host == 'bytid.com' ||
        host.endsWith('.bytid.com');
  }

  void _returnToVerification(LivenessWebResult result) {
    if (_hasReturned || !mounted) return;
    _hasReturned = true;
    Navigator.of(context).pop(result);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF7F8FA),
      appBar: AppBar(
        backgroundColor: Colors.white,
        surfaceTintColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          tooltip: 'Close face check',
          onPressed: () => Navigator.of(context).pop(),
          icon: const Icon(Icons.close),
        ),
        title: const Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Live face check',
              style: TextStyle(fontSize: 17, fontWeight: FontWeight.w700),
            ),
            Text(
              'Securely powered by BytID',
              style: TextStyle(fontSize: 11, fontWeight: FontWeight.w400),
            ),
          ],
        ),
        bottom: _progress < 100
            ? PreferredSize(
                preferredSize: const Size.fromHeight(3),
                child: LinearProgressIndicator(value: _progress / 100),
              )
            : null,
      ),
      body: _pageError == null
          ? WebViewWidget(controller: _controller)
          : Center(
              child: Padding(
                padding: const EdgeInsets.all(28),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(Icons.wifi_off_rounded, size: 48),
                    const SizedBox(height: 16),
                    Text(
                      _pageError!,
                      textAlign: TextAlign.center,
                      style: const TextStyle(fontSize: 16),
                    ),
                    const SizedBox(height: 20),
                    FilledButton(
                      onPressed: () {
                        setState(() => _pageError = null);
                        _controller.reload();
                      },
                      child: const Text('Try again'),
                    ),
                  ],
                ),
              ),
            ),
    );
  }
}
