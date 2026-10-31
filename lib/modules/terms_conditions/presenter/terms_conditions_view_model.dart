import 'package:flutter/material.dart';
import 'package:webview_flutter/webview_flutter.dart';
import 'package:oflite/modules/terms_conditions/presenter/strings/terms_conditions_pt_string.dart';

enum TermsConditionsState { idle, loading, loaded, error }

class TermsConditionsViewModel extends ChangeNotifier {
  static const String routeName = '/terms-and-conditions';
  static const String _pageUrl = 'https://orcamentofacilbr.wordpress.com/';

  late final WebViewController controller;

  TermsConditionsState state = TermsConditionsState.loading;
  String? errorMessage;
  int _loadingProgress = 0;

  int get loadingProgress => _loadingProgress;

  TermsConditionsViewModel() {
    _initController();
  }

  void _initController() {
    controller =
        WebViewController()
          ..setJavaScriptMode(JavaScriptMode.unrestricted)
          ..setBackgroundColor(const Color(0x00000000))
          ..setNavigationDelegate(
            NavigationDelegate(
              onProgress: _onProgress,
              onPageStarted: _onPageStarted,
              onPageFinished: _onPageFinished,
              onWebResourceError: _onWebResourceError,
              onNavigationRequest: _onNavigationRequest,
            ),
          )
          ..loadRequest(Uri.parse(_pageUrl));
  }

  void _onProgress(int progress) {
    _loadingProgress = progress;
    notifyListeners();
  }

  void _onPageStarted(String url) {
    state = TermsConditionsState.loading;
    notifyListeners();
  }

  void _onPageFinished(String url) {
    state = TermsConditionsState.loaded;
    notifyListeners();
  }

  void _onWebResourceError(WebResourceError error) {
    state = TermsConditionsState.error;
    errorMessage = TermsConditionsStrings.errorLoadPage;
    notifyListeners();
  }

  NavigationDecision _onNavigationRequest(NavigationRequest request) {
    if (request.url.startsWith(_pageUrl)) {
      return NavigationDecision.navigate;
    }
    return NavigationDecision.prevent;
  }

  void reload() {
    state = TermsConditionsState.loading;
    errorMessage = null;
    notifyListeners();
    controller.reload();
  }
}
