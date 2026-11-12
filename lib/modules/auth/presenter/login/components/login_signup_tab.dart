import 'package:flutter/material.dart';
import 'package:oflite/injection.dart';
import 'package:oflite/modules/auth/presenter/login/components/login_button.dart';
import 'package:oflite/modules/auth/presenter/login/components/login_signup_field.dart';
import 'package:oflite/modules/auth/presenter/login/strings/login_pt_string.dart';
import 'package:oflite/modules/auth/presenter/singup/singup_view_model.dart';
import 'package:oflite/modules/auth/presenter/singup/strings/singup_pt_string.dart';
import 'package:oflite/modules/core/display_alert/domain/repository/display_alert_repository.dart';
import 'package:oflite/shared/common/constants/constants.dart';

/// Aba de cadastro exibida inline dentro do card de login.
///
/// Reutiliza [SingUpViewModel] para manter toda a regra de negócio do
/// cadastro já existente no modal de signup.
class LoginSignUpTab extends StatefulWidget {
  const LoginSignUpTab({super.key});

  @override
  State<LoginSignUpTab> createState() => _LoginSignUpTabState();
}

class _LoginSignUpTabState extends State<LoginSignUpTab> {
  late final SingUpViewModel _viewModel;
  final DisplayAlertRepository _displayAlert = getIt<DisplayAlertRepository>();

  final TextEditingController _confirmPasswordController =
      TextEditingController();
  bool _isPasswordVisible = true;
  bool _isConfirmPasswordVisible = true;

  @override
  void initState() {
    super.initState();
    _viewModel = getIt<SingUpViewModel>();
    _viewModel.addListener(_onViewModelChanged);
  }

  @override
  void dispose() {
    _viewModel.removeListener(_onViewModelChanged);
    _viewModel.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  void _onViewModelChanged() {
    if (_viewModel.state == SingUpState.success) {
      _viewModel.consumeState();
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) {
          Navigator.pushReplacementNamed(context, '/menu');
        }
      });
      return;
    }
    if (_viewModel.state == SingUpState.error) {
      final message =
          _viewModel.errorMessage ?? SingUpStrings.signUpErrorDefault;
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
    setState(() {});
  }

  void _register() {
    final password = _viewModel.passwordText.text.trim();
    final confirmPassword = _confirmPasswordController.text.trim();

    if (password != confirmPassword) {
      _displayAlert.notificationError(
        context,
        LoginStrings.errorTitle,
        SingUpStrings.signUpErrorPasswordsDoNotMatch,
      );
      return;
    }

    _viewModel.register();
  }

  @override
  Widget build(BuildContext context) {
    final registering = _viewModel.state == SingUpState.loading;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      mainAxisSize: MainAxisSize.min,
      children: [
        const SizedBox(height: 10),
        LoginSignUpField(
          controller: _viewModel.nomeText,
          labelText: SingUpStrings.signUpNameHint,
          keyboardType: TextInputType.text,
        ),
        const SizedBox(height: 20),
        LoginSignUpField(
          controller: _viewModel.emailText,
          labelText: SingUpStrings.signUpEmailHint,
          keyboardType: TextInputType.emailAddress,
        ),
        const SizedBox(height: 20),
        LoginSignUpField(
          controller: _viewModel.passwordText,
          labelText: SingUpStrings.signUpPasswordHint,
          obscureText: _isPasswordVisible,
          suffixIcon: IconButton(
            icon: Icon(
              _isPasswordVisible ? Icons.visibility_off : Icons.visibility,
              color: Colors.white.withValues(alpha: 0.7),
            ),
            onPressed:
                () => setState(() => _isPasswordVisible = !_isPasswordVisible),
          ),
        ),
        const SizedBox(height: 20),
        LoginSignUpField(
          controller: _confirmPasswordController,
          labelText: SingUpStrings.signUpConfirmPasswordHint,
          obscureText: _isConfirmPasswordVisible,
          suffixIcon: IconButton(
            icon: Icon(
              _isConfirmPasswordVisible
                  ? Icons.visibility_off
                  : Icons.visibility,
              color: Colors.white.withValues(alpha: 0.7),
            ),
            onPressed:
                () => setState(
                  () => _isConfirmPasswordVisible = !_isConfirmPasswordVisible,
                ),
          ),
        ),
        const SizedBox(height: 22),
        LoginButton(
          label:
              registering
                  ? SingUpStrings.signUpButtonLoading
                  : SingUpStrings.signUpButton,
          onPressed: registering ? () {} : _register,
          width: double.infinity,
          borderRadius: 26,
          backgroundColor: buttonColor,
          textColor: bgColor,
        ),
      ],
    );
  }
}
