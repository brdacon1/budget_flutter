import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:oflite/common/constants/constants.dart';
import 'package:oflite/services/display_alert.dart';
import 'package:oflite/services/loading_event.dart';
import '../../common/widgets/anmition/fade_animation_widget.dart';
import '../singup/singup_view.dart';
import '../terms_conditions/terms_conditions_view.dart';
import 'login_view_model.dart';

class LoginView extends StatefulWidget {
  const LoginView({Key? key}) : super(key: key);

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
      Navigator.pushReplacementNamed(context, '/menu');
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
                  FadeAnimationWidget(
                    delay: 0.8,
                    child: Image.asset(
                      'assets/login-initial-page.png',
                      width: we * 0.5,
                      height: he * 0.25,
                    ),
                  ),
                  FadeAnimationWidget(
                    delay: 1,
                    child: Container(
                      margin: const EdgeInsets.only(right: 240.0),
                      child: Text(
                        'Entrar',
                        style: GoogleFonts.heebo(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                          fontSize: 35,
                          letterSpacing: 2,
                        ),
                      ),
                    ),
                  ),
                  SizedBox(height: he * 0.01),
                  _buildTextField(
                    field: LoginField.email,
                    controller: _viewModel.emailController,
                    hintText: 'E-mail',
                    prefixIcon: Icons.email_outlined,
                    width: we,
                    height: he,
                  ),
                  SizedBox(height: he * 0.02),
                  _buildTextField(
                    field: LoginField.password,
                    controller: _viewModel.passwordController,
                    hintText: 'Senha',
                    prefixIcon: Icons.lock_open_outlined,
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
                  FadeAnimationWidget(
                    delay: 1,
                    child: TextButton(
                      onPressed: () => _viewModel.loginWithEmailAndPassword(context),
                      style: TextButton.styleFrom(
                        backgroundColor: buttonColor,
                        padding: const EdgeInsets.symmetric(
                          vertical: 15.0,
                          horizontal: 80,
                        ),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(30.0),
                        ),
                      ),
                      child: Text(
                        'Entrar',
                        style: GoogleFonts.heebo(
                          color: Colors.black,
                          letterSpacing: 0.5,
                          fontSize: 20.0,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ),
                  SizedBox(height: he * 0.01),
                  FadeAnimationWidget(
                    delay: 1,
                    child: TextButton(
                      onPressed: () => _displayAlert.dialogChangePassword(context),
                      style: TextButton.styleFrom(
                        backgroundColor: bgColor,
                        padding: const EdgeInsets.symmetric(
                          vertical: 15.0,
                          horizontal: 80,
                        ),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(30.0),
                        ),
                      ),
                      child: Text(
                        'Esqueceu sua senha?',
                        style: GoogleFonts.heebo(
                          color: buttonColor,
                          letterSpacing: 0.5,
                          fontSize: 14.0,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ),
                  SizedBox(height: he * 0.02),
                  FadeAnimationWidget(
                    delay: 1,
                    child: TextButton(
                      onPressed: () => _viewModel.loginWithGoogle(context),
                      style: TextButton.styleFrom(
                        backgroundColor: Colors.red,
                        padding: const EdgeInsets.symmetric(
                          vertical: 15.0,
                          horizontal: 80,
                        ),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(30.0),
                        ),
                      ),
                      child: Text(
                        'Login com Google',
                        style: GoogleFonts.heebo(
                          color: Colors.white,
                          letterSpacing: 0.5,
                          fontSize: 20.0,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ),
                  SizedBox(height: he * 0.025),
                  FadeAnimationWidget(
                    delay: 1,
                    child: TextButton(
                      onPressed: () async {
                        await Navigator.of(context).push(
                          MaterialPageRoute(
                            builder: (context) => const TermsConditionsView(),
                          ),
                        );
                      },
                      style: TextButton.styleFrom(
                        backgroundColor: bgColor,
                        padding: const EdgeInsets.symmetric(
                          vertical: 15.0,
                          horizontal: 80,
                        ),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(30.0),
                        ),
                      ),
                      child: Text(
                        'Politica de privacidade',
                        style: GoogleFonts.heebo(
                          color: buttonColor,
                          letterSpacing: 0.5,
                          fontSize: 14.0,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
          bottomNavigationBar: BottomAppBar(
            color: bgColor,
            elevation: 0,
            child: Container(
              height: 65.0,
              color: bgColor,
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    'Quer se cadastrar? ',
                    style: GoogleFonts.heebo(
                      color: Colors.grey,
                      letterSpacing: 0.5,
                    ),
                  ),
                  GestureDetector(
                    onTap: () {
                      Navigator.of(context)
                          .push(
                            MaterialPageRoute(
                              builder: (context) => const SingUpView(),
                            ),
                          )
                          .then((_) => _viewModel.init());
                    },
                    child: Text(
                      'Clique aqui',
                      style: GoogleFonts.heebo(
                        color: buttonColor.withOpacity(0.9),
                        fontWeight: FontWeight.bold,
                        letterSpacing: 0.5,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildTextField({
    required LoginField field,
    required TextEditingController controller,
    required String hintText,
    required IconData prefixIcon,
    required double width,
    required double height,
    bool obscureText = false,
    Widget? suffixIcon,
  }) {
    final isSelected = _viewModel.selectedField == field;

    return FadeAnimationWidget(
      delay: 1,
      child: Container(
        width: width * 0.9,
        height: height * 0.082,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: secondaryColor, width: 2),
          color: isSelected ? _viewModel.enabled : bgColor,
        ),
        padding: const EdgeInsets.all(8.0),
        child: TextField(
          controller: controller,
          onTap: () => _viewModel.selectField(field),
          obscureText: obscureText,
          decoration: InputDecoration(
            enabledBorder: InputBorder.none,
            border: InputBorder.none,
            prefixIcon: Icon(
              prefixIcon,
              color: isSelected ? _viewModel.enabledtxt : _viewModel.deaible,
            ),
            suffixIcon: suffixIcon,
            hintText: hintText,
            hintStyle: TextStyle(
              color: isSelected ? _viewModel.enabledtxt : _viewModel.deaible,
            ),
          ),
          style: TextStyle(
            color: isSelected ? _viewModel.enabledtxt : _viewModel.deaible,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
    );
  }
}
