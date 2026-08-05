import 'package:flutter/material.dart';
import 'package:oflite/common/constants/constants.dart';
import 'package:oflite/services/display_alert.dart';
import 'package:oflite/services/loading_event.dart';
import '../terms_conditions/terms_conditions_view.dart';
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
  final LoginViewModel _viewModel = LoginViewModel();
  final DisplayAlert _displayAlert = DisplayAlert();
  final LoadingEvent _loadingEvent = LoadingEvent();

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
    } else if (state == LoginState.success) {
      _loadingEvent.closeLoading(context);
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) {
          Navigator.pushReplacementNamed(context, '/menu');
        }
      });
    } else if (state == LoginState.error) {
      _loadingEvent.closeLoading(context);
      _displayAlert.notificationError(
        context,
        'Erro!',
        _viewModel.errorMessage ?? 'Problemas para realizar seu login. Verifique sua senha e e-mail.',
      );
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
                    hintText: 'E-mail',
                    prefixIcon: Icons.email_outlined,
                    viewModel: _viewModel,
                    width: we,
                    height: he,
                  ),
                  SizedBox(height: he * 0.02),
                  LoginTextField(
                    field: LoginField.password,
                    controller: _viewModel.passwordController,
                    hintText: 'Senha',
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
                    label: 'Entrar',
                    onPressed: () => _viewModel.loginWithEmailAndPassword(context),
                  ),
                  SizedBox(height: he * 0.01),
                  LoginButton(
                    label: 'Esqueceu sua senha?',
                    onPressed: () => _displayAlert.dialogChangePassword(context),
                    backgroundColor: bgColor,
                    textColor: buttonColor,
                    fontSize: 14.0,
                  ),
                  SizedBox(height: he * 0.02),
                  LoginButton(
                    label: 'Login com Google',
                    onPressed: () => _viewModel.loginWithGoogle(context),
                    backgroundColor: Colors.red,
                    textColor: Colors.white,
                  ),
                  SizedBox(height: he * 0.025),
                  LoginButton(
                    label: 'Politica de privacidade',
                    onPressed: () async {
                      await Navigator.of(context).push(
                        MaterialPageRoute(
                          builder: (context) => const TermsConditionsView(),
                        ),
                      );
                    },
                    backgroundColor: bgColor,
                    textColor: buttonColor,
                    fontSize: 14.0,
                  ),
                ],
              ),
            ),
          ),
          bottomNavigationBar: LoginFooter(
            onRegisterClosed: () => _viewModel.init(),
          ),
        );
      },
    );
  }
}
