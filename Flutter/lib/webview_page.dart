import 'package:flutter/material.dart';
import 'package:webview_flutter/webview_flutter.dart';
import 'package:google_fonts/google_fonts.dart';

class WebViewPage extends StatefulWidget {
  final String paymentUrl;

  const WebViewPage({super.key, required this.paymentUrl});

  @override
  State<WebViewPage> createState() => _WebViewPageState();
}

class _WebViewPageState extends State<WebViewPage> {
  late final WebViewController _controller;
  bool isLoading = true;

  @override
  void initState() {
    super.initState();

    _controller = WebViewController()
      ..setJavaScriptMode(JavaScriptMode.unrestricted)
      ..setNavigationDelegate(
        NavigationDelegate(
          onPageStarted: (url) {
            print('🔗 Loading: $url');
          },
          onPageFinished: (url) {
            setState(() => isLoading = false);
            print('✅ Loaded: $url');
          },
          onNavigationRequest: (request) {
            final url = request.url.toLowerCase();

            print('🔍 Navigation: $url');

            // ✅ Detect payment success
            if (url.contains('finish') ||
                url.contains('success') ||
                url.contains('status_code=200')) {
              print('✅ Payment Success Detected!');
              Navigator.pop(context, true); // Return true = success
              return NavigationDecision.prevent;
            }

            // ⚠️ Detect payment pending (transfer/VA belum dibayar)
            if (url.contains('pending')) {
              print('⏳ Payment Pending');
              Navigator.pop(context, null); // Return null = pending
              return NavigationDecision.prevent;
            }

            // ❌ Detect payment cancel/error
            if (url.contains('cancel') ||
                url.contains('error') ||
                url.contains('failure')) {
              print('❌ Payment Cancelled/Failed');
              Navigator.pop(context, false); // Return false = cancel
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
      backgroundColor: Colors.white,
      appBar: AppBar(
        elevation: 0,
        backgroundColor: Colors.white,
        centerTitle: true,
        title: Text(
          'Pembayaran',
          style: GoogleFonts.poppins(
            color: Colors.black87,
            fontWeight: FontWeight.w600,
          ),
        ),
        leading: IconButton(
          icon: const Icon(Icons.close, color: Colors.black87),
          onPressed: () {
            // User close manual
            showDialog(
              context: context,
              builder: (ctx) => AlertDialog(
                title: Text('Batalkan Pembayaran?'),
                content: Text('Apakah Anda yakin ingin membatalkan pembayaran ini?'),
                actions: [
                  TextButton(
                    onPressed: () => Navigator.pop(ctx),
                    child: Text('Tidak'),
                  ),
                  TextButton(
                    onPressed: () {
                      Navigator.pop(ctx); // Close dialog
                      Navigator.pop(context, false); // Close WebView
                    },
                    child: Text('Ya, Batalkan', style: TextStyle(color: Colors.red)),
                  ),
                ],
              ),
            );
          },
        ),
      ),
      body: Stack(
        children: [
          WebViewWidget(controller: _controller),

          // Loading indicator
          if (isLoading)
            Container(
              color: Colors.white,
              child: Center(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    CircularProgressIndicator(
                      color: Colors.green.shade600,
                    ),
                    SizedBox(height: 16),
                    Text(
                      'Memuat halaman pembayaran...',
                      style: GoogleFonts.poppins(
                        color: Colors.grey.shade600,
                        fontSize: 14,
                      ),
                    ),
                  ],
                ),
              ),
            ),
        ],
      ),
    );
  }
}