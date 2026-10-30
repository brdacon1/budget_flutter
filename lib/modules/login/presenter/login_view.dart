import 'package:flutter/material.dart';
import 'package:oflite/injection.dart';
import 'package:oflite/modules/login/presenter/strings/login_pt_string.dart';
import 'package:oflite/shared/common/constants/constants.dart';
import 'package:oflite/modules/core/display_alert/domain/repository/display_alert_repository.dart';
import 'package:oflite/modules/core/loading_event/domain/repository/loading_event_repository.dart';
import 'package:oflite/modules/singup/presenter/singup_view.dart';
import '../../terms_conditions/presenter/terms_conditions_view.dart';
import 'components/login_button.dart';
import 'components/login_footer.dart';
import 'components/login_header.dart';
import 'components/login_text_field.dart';
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
      // Consome o estado para não reentrar no fluxo de sucesso em
      // notificações futuras (ex.: interações com os campos).
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
      // Captura a mensagem e consome o estado ANTES de qualquer chamada
      // que possa disparar novas notificações, para que o modal de erro
      // seja exibido apenas uma vez (one-shot).
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

  @override
  Widget build(BuildContext context) {
    final we = MediaQuery.of(context).size.width;
    final he = MediaQuery.of(context).size.height;

    return AnimatedBuilder(
      animation: _viewModel,
      builder: (context, child) {
        return Scaffold(
          backgroundColor: bgColor,
          body: Center(
            child: SingleChildScrollView(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: <Widget>[
                  SizedBox(height: he * 0.020),
                  LoginHeader(width: we, height: he),
                  SizedBox(height: he * 0.01),
                  LoginTextField(
                    field: LoginField.email,
                    controller: _viewModel.emailController,
                    hintText: LoginStrings.loginEmailHint,
                    prefixIcon: Icons.email_outlined,
                    viewModel: _viewModel,
                    width: we,
                    height: he,
                  ),
                  SizedBox(height: he * 0.02),
                  LoginTextField(
                    field: LoginField.password,
                    controller: _viewModel.passwordController,
                    hintText: LoginStrings.loginPasswordHint,
                    prefixIcon: Icons.lock_open_outlined,
                    viewModel: _viewModel,
                    width: we,
                    height: he,
                    obscureText: _viewModel.isPasswordVisible,
                    suffixIcon: IconButton(
                      icon: _viewModel.isPasswordVisible
                          ? Icon(
                              Icons.visibility_off,
                              color: _viewModel.selectedField == LoginField.password
                                  ? _viewModel.enabledtxt
                                  : _viewModel.deaible,
                            )
                          : Icon(
                              Icons.visibility,
                              color: _viewModel.selectedField == LoginField.password
                                  ? _viewModel.enabledtxt
                                  : _viewModel.deaible,
                            ),
                      onPressed: _viewModel.togglePasswordVisibility,
                    ),
                  ),
                  SizedBox(height: he * 0.02),
                  LoginButton(
                    label: LoginStrings.loginButton,
                    onPressed: () => _viewModel.loginWithEmailAndPassword(context),
                  ),
                  SizedBox(height: he * 0.015),
                  // Botão de cadastro em destaque: abre o modal de cadastro
                  // (bottom modal) no padrão do app.
                  LoginButton(
                    label: LoginStrings.loginRegisterButton,
                    onPressed: () {
                      showSingUpBottomModal(context)
                          .then((_) => _viewModel.init());
                    },
                    backgroundColor: Colors.white,
                    textColor: bgColor,
                  ),
                  SizedBox(height: he * 0.01),
                  LoginButton(
                    label: LoginStrings.loginForgotPassword,
                    onPressed: () => _displayAlert.dialogChangePassword(context),
                    backgroundColor: bgColor,
                    textColor: buttonColor,
                    fontSize: 14.0,
                  ),
                  SizedBox(height: he * 0.02),
                  LoginButton(
                    label: LoginStrings.loginWithGoogle,
                    onPressed: () => _viewModel.loginWithGoogle(context),
                    backgroundColor: Colors.red,
                    textColor: Colors.white,
                  ),
                ],
              ),
            ),
          ),
          bottomNavigationBar: LoginFooter(
            onPrivacyPolicy: () async {
              await Navigator.of(context).push(
                MaterialPageRoute(
                  builder: (context) => const TermsConditionsView(),
                ),
              );
            },
          ),
        );
      },
    );
  }
}
