import 'package:material_ui/material_ui.dart';
import 'package:oflite/modules/auth/presenter/login/components/login_apple_button.dart';
import 'package:oflite/modules/auth/presenter/login/components/login_button.dart';
import 'package:oflite/modules/auth/presenter/login/components/login_google_button.dart';
import 'package:oflite/modules/auth/presenter/login/components/login_text_field.dart';
import 'package:oflite/modules/auth/presenter/login/strings/login_pt_string.dart';
import 'package:oflite/shared/common/constants/colors.dart';

import '../login_view_model.dart';

class LoginTab extends StatelessWidget {
  const LoginTab({
    super.key,
    required this.viewModel,
    required this.onForgotPassword,
    required this.onGoogleLogin,
    required this.onAppleLogin,
  });

  final LoginViewModel viewModel;
  final VoidCallback onForgotPassword;
  final VoidCallback onGoogleLogin;
  final VoidCallback onAppleLogin;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      mainAxisSize: MainAxisSize.min,
      children: <Widget>[
        const SizedBox(height: 10),
        LoginTextField(
          field: LoginField.email,
          controller: viewModel.emailController,
          labelText: LoginStrings.loginEmailHint,
          viewModel: viewModel,
          keyboardType: TextInputType.emailAddress,
        ),
        const SizedBox(height: 20),
        LoginTextField(
          field: LoginField.password,
          controller: viewModel.passwordController,
          labelText: LoginStrings.loginPasswordHint,
          viewModel: viewModel,
          obscureText: viewModel.isPasswordVisible,
          suffixIcon: IconButton(
            icon: Icon(
              viewModel.isPasswordVisible
                  ? Icons.visibility_off
                  : Icons.visibility,
              color:
                  viewModel.selectedField == LoginField.password
                      ? viewModel.enabledtxt
                      : viewModel.deaible,
            ),
            onPressed: viewModel.togglePasswordVisibility,
          ),
        ),
        const SizedBox(height: 20),
        LoginButton(
          label: LoginStrings.loginButton,
          onPressed: () => viewModel.loginWithEmailAndPassword(context),
          width: double.infinity,
          borderRadius: 26,
          backgroundColor: buttonColor,
          textColor: bgColor,
        ),
        const SizedBox(height: 20),
        if (viewModel.showAppleLogin)
          Row(
            children: [
              Expanded(child: LoginAppleButton(onPressed: onAppleLogin)),
              const SizedBox(width: 10),
              Expanded(child: LoginGoogleButton(onPressed: onGoogleLogin)),
            ],
          )
        else
          LoginGoogleButton(onPressed: onGoogleLogin),
        const SizedBox(height: 15),
        Align(
          alignment: Alignment.center,
          child: LoginButton(
            label: LoginStrings.loginForgotPassword,
            onPressed: onForgotPassword,
            backgroundColor: Colors.transparent,
            textColor: buttonColor,
            fontSize: 16.0,
            padding: EdgeInsets.zero,
          ),
        ),
      ],
    );
  }
}
