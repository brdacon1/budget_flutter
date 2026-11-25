import 'package:oflite/modules/auth/presenter/change_name/show_change_name_modal.dart';
import 'package:oflite/shared/common/widgets/adaptive/show_app_modal.dart';
import 'package:oflite/shared/common/widgets/alert/alert_snack_bar_widget.dart';
import 'package:oflite/shared/common/widgets/modals/change_password_bottom_modal_widget.dart';
import 'package:material_ui/material_ui.dart';
import 'package:oflite/injection.dart';
import 'package:oflite/modules/auth/presenter/login/components/login_card_clipper.dart';
import 'package:oflite/modules/auth/presenter/login/components/login_footer.dart';
import 'package:oflite/modules/auth/presenter/login/components/login_header.dart';
import 'package:oflite/modules/auth/presenter/login/components/login_session_loading.dart';
import 'package:oflite/modules/auth/presenter/login/components/login_signup_tab.dart';
import 'package:oflite/modules/auth/presenter/login/components/login_tab.dart';
import 'package:oflite/modules/auth/presenter/login/components/login_tab_toggle.dart';
import 'package:oflite/modules/auth/presenter/login/strings/login_pt_string.dart';
import 'package:oflite/modules/core/loading_event/domain/repository/loading_event_repository.dart';
import 'package:oflite/shared/common/widgets/adaptive/app_page_container.dart';
import 'package:oflite/shared/common/widgets/responsive_widget.dart';
import 'package:oflite/shared/common/constants/colors.dart';

import '../../../terms_conditions/presenter/terms_conditions_view.dart';
import 'login_view_model.dart';

class LoginView extends StatefulWidget {
  const LoginView({super.key});

  @override
  State<LoginView> createState() => _LoginViewState();
}

class _LoginViewState extends State<LoginView> {
  final LoginViewModel _viewModel = getIt<LoginViewModel>();
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

  LoginState? _lastState;

  void _onViewModelChanged() {
    final state = _viewModel.state;
    final previous = _lastState;
    _lastState = state;

    if (state == LoginState.loading) {
      // Só abre o loading na transição; notificações extras não empilham.
      if (previous == LoginState.loading) return;
      _loadingEvent.alertLoading(context);
      return;
    }

    // Cancelamento (ex.: fechou o picker do Google) volta para idle.
    if (state == LoginState.idle) {
      _loadingEvent.closeLoading(context);
      return;
    }

    if (state == LoginState.success) {
      _loadingEvent.closeLoading(context);
      _viewModel.consumeState();
      WidgetsBinding.instance.addPostFrameCallback((_) async {
        if (!mounted) return;
        // Login social sem nome (Apple só envia na 1ª autorização):
        // pede o nome antes de entrar.
        if (_viewModel.needsUserName) {
          await showChangeNameModal(context);
          if (!mounted) return;
        }
        Navigator.pushNamedAndRemoveUntil(context, '/menu', (_) => false);
      });
      return;
    }

    if (state == LoginState.error) {
      _loadingEvent.closeLoading(context);
      final message = _viewModel.errorMessage ?? LoginStrings.loginErrorDefault;
      _viewModel.consumeState();
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) {
          AlertSnackBar.error(
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
              child: _buildForm(),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildForm() {
    return Column(
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
            onForgotPassword: _openChangePassword,
            onGoogleLogin: () => _viewModel.loginWithGoogle(context),
            onAppleLogin: _viewModel.loginWithApple,
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
                    builder: (context) => const TermsConditionsView(),
                  ),
                );
              },
            ),
          ),
        ),
      ],
    );
  }

  /// Tela larga: logo à esquerda, formulário centralizado à direita.
  Widget _buildSideBySide() {
    return Row(
      children: <Widget>[
        Expanded(
          child: Container(
            color: secondaryColor,
            alignment: Alignment.center,
            child: const LoginHeader(width: 600, height: 800),
          ),
        ),
        Expanded(
          child: Container(
            color: bgColor,
            child: SafeArea(
              child: Center(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.all(32),
                  child: ConstrainedBox(
                    constraints: BoxConstraints(
                      maxWidth: AppPageWidth.auth.maxWidth,
                    ),
                    child: _buildForm(),
                  ),
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }

  Future<void> _openChangePassword() async {
    final sent = await showAppModal<bool>(
      context,
      builder:
          (_) => ChangePasswordBottomModalWidget(
            onSave: _viewModel.sendPasswordReset,
          ),
    );
    if (sent == true && mounted) {
      AlertSnackBar.success(
        context,
        'Feito!',
        'Você recebeu um email para trocar de senha',
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;
    final we = size.width;
    final he = size.height;

    return AnimatedBuilder(
      animation: _viewModel,
      builder: (context, child) {
        if (_viewModel.state == LoginState.checkingSession) {
          return const LoginSessionLoading();
        }
        return Scaffold(
          backgroundColor: secondaryColor,
          body:
              ResponsiveWidget.isDesktop(context)
                  ? _buildSideBySide()
                  : Column(
                    children: <Widget>[
                      Expanded(
                        flex: 1,
                        child: LoginHeader(width: we, height: he),
                      ),
                      _buildScreen(),
                    ],
                  ),
        );
      },
    );
  }
}
