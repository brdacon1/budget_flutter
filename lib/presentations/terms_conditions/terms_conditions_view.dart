import 'package:flutter/material.dart';
import 'package:webview_flutter/webview_flutter.dart';
import '../../common/constants/constants.dart';

class TermsConditionsView extends StatefulWidget {
  static const String routeName = '/terms-and-conditions';
  const TermsConditionsView({Key? key}) : super(key: key);

  @override
  State<TermsConditionsView> createState() => _TermsConditionsView();
}

class _TermsConditionsView extends State<TermsConditionsView> {
  late final WebViewController controller;



  @override
  void initState() {
    super.initState();
    controller = WebViewController()
      ..setJavaScriptMode(JavaScriptMode.unrestricted)
      ..setBackgroundColor(const Color(0x00000000))
      ..setNavigationDelegate(
        NavigationDelegate(
          onProgress: (int progress) {
            // Update loading bar.
          },
          onPageStarted: (String url) {},
          onPageFinished: (String url) {},
          onWebResourceError: (WebResourceError error) {},
          onNavigationRequest: (NavigationRequest request) {
            if (request.url.startsWith('https://wordpress.com/page/orcamentofacilbr.wordpress.com/6')) {
              return NavigationDecision.prevent;
            }
            return NavigationDecision.navigate;
          },
        ),
      )
      ..loadRequest(Uri.parse('https://wordpress.com/page/orcamentofacilbr.wordpress.com/6'));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Politica de privacidade',
        ),
        backgroundColor: bgColor,
      ),
      body: Stack(
        children: [
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: WebViewWidget(controller: controller),
          ),
        ],
      ),
    );
  }
}
