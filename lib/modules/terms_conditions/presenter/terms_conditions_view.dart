import 'package:flutter/material.dart';
import 'package:oflite/injection.dart';
import 'package:webview_flutter/webview_flutter.dart';
import 'package:oflite/shared/common/constants/constants.dart';
import 'terms_conditions_view_model.dart';

class TermsConditionsView extends StatefulWidget {
  static const String routeName = TermsConditionsViewModel.routeName;

  const TermsConditionsView({super.key});

  @override
  State<TermsConditionsView> createState() => _TermsConditionsViewState();
}

class _TermsConditionsViewState extends State<TermsConditionsView> {
  late final TermsConditionsViewModel _viewModel;

  @override
  void initState() {
    super.initState();
    _viewModel = getIt<TermsConditionsViewModel>();
    _viewModel.addListener(_onViewModelChanged);
  }

  @override
  void dispose() {
    _viewModel.removeListener(_onViewModelChanged);
    _viewModel.dispose();
    super.dispose();
  }

  void _onViewModelChanged() {
    if (mounted) {
      setState(() {});
    }
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _viewModel,
      builder: (context, child) {
        return Scaffold(
          appBar: AppBar(
            title: const Text(TermsConditionsViewModel.pageTitle),
            backgroundColor: bgColor,
          ),
          body: _buildBody(),
        );
      },
    );
  }

  Widget _buildBody() {
    if (_viewModel.state == TermsConditionsState.error) {
      return _buildErrorView();
    }

    return Stack(
      children: [
        Padding(
          padding: const EdgeInsets.all(8.0),
          child: WebViewWidget(controller: _viewModel.controller),
        ),
        if (_viewModel.state == TermsConditionsState.loading)
          _buildLoadingIndicator(),
      ],
    );
  }

  Widget _buildLoadingIndicator() {
    return Container(
      color: bgColor.withValues(alpha: 0.8),
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const CircularProgressIndicator(),
            const SizedBox(height: 16),
            Text(
              '${_viewModel.loadingProgress}%',
              style: const TextStyle(color: Colors.white),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildErrorView() {
    return Container(
      color: bgColor,
      padding: const EdgeInsets.all(24),
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.error_outline, color: Colors.white, size: 48),
            const SizedBox(height: 16),
            Text(
              _viewModel.errorMessage ?? 'Erro ao carregar a página.',
              textAlign: TextAlign.center,
              style: const TextStyle(color: Colors.white, fontSize: 16),
            ),
            const SizedBox(height: 24),
            ElevatedButton(
              onPressed: _viewModel.reload,
              child: const Text('Tentar novamente'),
            ),
          ],
        ),
      ),
    );
  }
}
