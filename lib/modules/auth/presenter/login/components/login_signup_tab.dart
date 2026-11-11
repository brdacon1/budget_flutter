import 'package:flutter/material.dart';
import 'package:oflite/injection.dart';
import 'package:oflite/modules/auth/presenter/login/components/login_button.dart';
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
        _SignUpField(
          controller: _viewModel.nomeText,
          labelText: SingUpStrings.signUpNameHint,
          keyboardType: TextInputType.text,
        ),
        const SizedBox(height: 14),
        _SignUpField(
          controller: _viewModel.emailText,
          labelText: SingUpStrings.signUpEmailHint,
          keyboardType: TextInputType.emailAddress,
        ),
        const SizedBox(height: 14),
        _SignUpField(
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
        const SizedBox(height: 14),
        _SignUpField(
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
          borderRadius: 12,
          backgroundColor: buttonColor,
          textColor: bgColor,
        ),
      ],
    );
  }
}

class _SignUpField extends StatelessWidget {
  const _SignUpField({
    required this.controller,
    required this.labelText,
    this.keyboardType,
    this.obscureText = false,
    this.suffixIcon,
  });

  final TextEditingController controller;
  final String labelText;
  final TextInputType? keyboardType;
  final bool obscureText;
  final Widget? suffixIcon;

  @override
  Widget build(BuildContext context) {
    return TextField(
      controller: controller,
      obscureText: obscureText,
      keyboardType: keyboardType,
      decoration: InputDecoration(
        labelText: labelText,
        labelStyle: TextStyle(
          color: Colors.white.withValues(alpha: 0.85),
          fontWeight: FontWeight.w600,
        ),
        floatingLabelStyle: const TextStyle(
          color: buttonColor,
          fontWeight: FontWeight.bold,
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: Colors.white.withValues(alpha: 0.3)),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: buttonColor),
        ),
        suffixIcon: suffixIcon,
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 16,
          vertical: 14,
        ),
      ),
      style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
    );
  }
}
