import 'package:flutter/material.dart';
import 'package:oflite/injection.dart';
import 'package:oflite/modules/auth/presenter/login/components/login_card_clipper.dart';
import 'package:oflite/modules/auth/presenter/login/components/login_footer.dart';
import 'package:oflite/modules/auth/presenter/login/components/login_header.dart';
import 'package:oflite/modules/auth/presenter/login/components/login_signup_tab.dart';
import 'package:oflite/modules/auth/presenter/login/components/login_tab.dart';
import 'package:oflite/modules/auth/presenter/login/components/login_tab_toggle.dart';
import 'package:oflite/modules/auth/presenter/login/strings/login_pt_string.dart';
import 'package:oflite/modules/core/display_alert/domain/repository/display_alert_repository.dart';
import 'package:oflite/modules/core/loading_event/domain/repository/loading_event_repository.dart';
import 'package:oflite/shared/common/constants/constants.dart';

import '../../../terms_conditions/presenter/terms_conditions_view.dart';
import 'login_view_model.dart';

class LoginView extends StatefulWidget {
  const LoginView({super.key});

  @override
  State<LoginView> createState() => _LoginViewState();
}

class _LoginViewState extends State<LoginView> {
  final LoginViewModel _viewModel = getIt<LoginViewModel>();
  final DisplayAlertRepository _displayAlert = getIt<DisplayAlertRepository>();
  final LoadingEventRepository _loadingEvent = getIt<LoadingEventRepository>();

  bool _isLoginTab = true;

  @override
  void initState() {
    super.initState();
    _viewModel.init();
    _viewModel.addListener(_onViewModelChanged);
  }

  @override
  void dispose() {
    _viewModel.removeListener(_onViewModelChanged);
    _viewModel.dispose();
    super.dispose();
  }

  void _onViewModelChanged() {
    final state = _viewModel.state;

    if (state == LoginState.loading) {
      _loadingEvent.alertLoading(context);
      return;
    }

    if (state == LoginState.success) {
      _loadingEvent.closeLoading(context);
      _viewModel.consumeState();
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) {
          Navigator.pushReplacementNamed(context, '/menu');
        }
      });
      return;
    }

    if (state == LoginState.error) {
      _loadingEvent.closeLoading(context);
      final message = _viewModel.errorMessage ?? LoginStrings.loginErrorDefault;
      _viewModel.consumeState();
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) {
          _displayAlert.notificationError(
            context,
            LoginStrings.errorTitle,
            message,
          );
        }
      });
    }
  }

  void _switchTab(bool isLogin) {
    if (_isLoginTab == isLogin) return;
    setState(() => _isLoginTab = isLogin);
  }

  Widget _buildScreen() {
    return Expanded(
      flex: 3,
      child: ClipPath(
        clipper: LoginCardClipper(),
        child: Container(
          width: double.infinity,
          color: bgColor,
          child: SafeArea(
            top: false,
            child: SingleChildScrollView(
              padding: const EdgeInsets.fromLTRB(16, 50, 16, 16),
              child: ConstrainedBox(
                constraints: BoxConstraints(minHeight: 0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: <Widget>[
                    LoginTabToggle(
                      isLoginSelected: _isLoginTab,
                      onLoginTap: () => _switchTab(true),
                      onSignUpTap: () => _switchTab(false),
                    ),
                    const SizedBox(height: 20),
                    AnimatedCrossFade(
                      firstChild: LoginTab(
                        viewModel: _viewModel,
                        onForgotPassword:
                            () => _displayAlert.dialogChangePassword(context),
                        onGoogleLogin:
                            () => _viewModel.loginWithGoogle(context),
                      ),
                      secondChild: const LoginSignUpTab(),
                      crossFadeState:
                          _isLoginTab
                              ? CrossFadeState.showFirst
                              : CrossFadeState.showSecond,
                      duration: const Duration(milliseconds: 250),
                    ),
                    const SizedBox(height: 20),
                    Padding(
                      padding: const EdgeInsets.only(bottom: 25),
                      child: Center(
                        child: LoginFooter(
                          onPrivacyPolicy: () async {
                            await Navigator.of(context).push(
                              MaterialPageRoute(
                                builder:
                                    (context) => const TermsConditionsView(),
                              ),
                            );
                          },
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;
    final we = size.width;
    final he = size.height;

    return AnimatedBuilder(
      animation: _viewModel,
      builder: (context, child) {
        return Scaffold(
          backgroundColor: secondaryColor,
          body: Column(
            children: <Widget>[
              Expanded(flex: 1, child: LoginHeader(width: we, height: he)),
              _buildScreen(),
            ],
          ),
        );
      },
    );
  }
}
