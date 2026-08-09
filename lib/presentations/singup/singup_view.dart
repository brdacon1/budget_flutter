import 'package:flutter/material.dart';
import 'package:oflite/common/constants/constants.dart';
import 'package:oflite/common/enums/singup_field_enum.dart';
import 'package:oflite/services/display_alert.dart';
import 'package:oflite/services/loading_event.dart';
import '../login/login_view.dart';
import 'components/singup_field.dart';
import 'components/singup_header.dart';
import 'components/singup_login_link.dart';
import 'components/singup_register_button.dart';
import 'singup_view_model.dart';

class SingUpView extends StatefulWidget {
  const SingUpView({super.key});

  @override
  State<SingUpView> createState() => _SingUpView();
}

class _SingUpView extends State<SingUpView> {
  late final SingUpViewModel _viewModel;
  final DisplayAlert _displayAlert = DisplayAlert();
  final LoadingEvent _loadingEvent = LoadingEvent();

  @override
  void initState() {
    super.initState();
    _viewModel = SingUpViewModel();
    _viewModel.addListener(_onViewModelChanged);
  }

  @override
  void dispose() {
    _viewModel.removeListener(_onViewModelChanged);
    _viewModel.dispose();
    super.dispose();
  }

  /// Reage ao estado do VM de forma *one-shot* (igual ao `LoginView`):
  /// loading → abre o loading; success → SnackBar verde + vai para o app;
  /// error → fecha o loading e mostra o erro.
  void _onViewModelChanged() {
    final state = _viewModel.state;

    if (state == SingUpState.loading) {
      _loadingEvent.alertLoading(context);
      return;
    }

    if (state == SingUpState.success) {
      _loadingEvent.closeLoading(context);
      // Consome o estado para não reentrar no fluxo de sucesso em
      // notificações futuras (ex.: interações com os campos).
      _viewModel.consumeState();
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Cadastro realizado com sucesso!'),
            backgroundColor: Colors.green,
            duration: Duration(seconds: 2),
          ),
        );
        Navigator.pushReplacementNamed(context, '/menu');
      });
      return;
    }

    if (state == SingUpState.error) {
      _loadingEvent.closeLoading(context);
      // Captura a mensagem e consome o estado ANTES de qualquer chamada
      // que possa disparar novas notificações, para que o modal de erro
      // seja exibido apenas uma vez (one-shot).
      final message =
          _viewModel.errorMessage ?? 'Problemas para registrar usuário!';
      _viewModel.consumeState();
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!mounted) return;
        _displayAlert.notificationError(context, 'Erro!', message);
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    var he = MediaQuery.of(context).size.height;
    return Scaffold(
      backgroundColor: bgColor,
      body: AnimatedBuilder(
        animation: _viewModel,
        builder: (context, _) {
          return SingleChildScrollView(
            child: SizedBox(
              width: MediaQuery.of(context).size.width,
              height: he,
              child: Column(
                children: <Widget>[
                  SingUpHeader(onBack: () => Navigator.pop(context)),
                  SizedBox(height: he * 0.07),
                  SingUpField(
                    controller: _viewModel.nomeText,
                    hintText: 'SEU NOME',
                    icon: Icons.person_pin_outlined,
                    field: SingUpFieldType.name,
                    selected: _viewModel.selected,
                    enabledColor: _viewModel.enabled,
                    enabledTextColor: _viewModel.enabledtxt,
                    disabledColor: _viewModel.deaible,
                    onTap: () => _viewModel.selectField(SingUpFieldType.name),
                  ),
                  SizedBox(height: he * 0.02),
                  SingUpField(
                    controller: _viewModel.emailText,
                    hintText: 'E-MAIL',
                    icon: Icons.email_outlined,
                    field: SingUpFieldType.email,
                    selected: _viewModel.selected,
                    enabledColor: _viewModel.enabled,
                    enabledTextColor: _viewModel.enabledtxt,
                    disabledColor: _viewModel.deaible,
                    onTap: () => _viewModel.selectField(SingUpFieldType.email),
                  ),
                  SizedBox(height: he * 0.02),
                  SingUpField(
                    controller: _viewModel.passwordText,
                    hintText: 'SENHA',
                    icon: Icons.lock_open_outlined,
                    field: SingUpFieldType.password,
                    selected: _viewModel.selected,
                    enabledColor: _viewModel.enabled,
                    enabledTextColor: _viewModel.enabledtxt,
                    disabledColor: _viewModel.deaible,
                    isPassword: true,
                    ispasswordev: _viewModel.ispasswordev,
                    onTap: () => _viewModel.selectField(SingUpFieldType.password),
                    togglePassword: _viewModel.togglePasswordVisibility,
                  ),
                  SizedBox(height: he * 0.06),
                  SingUpRegisterButton(
                    onPressed: () => _viewModel.register(),
                  ),
                ],
              ),
            ),
          );
        },
      ),
      bottomNavigationBar: AnimatedBuilder(
        animation: _viewModel,
        builder: (context, _) => BottomAppBar(
          color: bgColor,
          elevation: 0,
          child: Container(
            height: 65.0,
            color: bgColor,
            child: SingUpLoginLink(
              onLogin: () {
                Navigator.of(context).push(
                  MaterialPageRoute(
                    builder: (context) => const LoginView(),
                  ),
                );
              },
            ),
          ),
        ),
      ),
    );
  }
}
