import 'package:flutter/material.dart';
import 'package:oflite/injection.dart';
import 'package:oflite/shared/common/enums/singup_field_enum.dart';
import 'package:oflite/shared/common/strings/auth_strings.dart';
import 'package:oflite/shared/common/widgets/modals/app_bottom_modal_widget.dart';
import 'package:oflite/modules/core/display_alert/domain/repository/display_alert_repository.dart';
import 'package:oflite/modules/core/loading_event/domain/repository/loading_event_repository.dart';
import 'components/singup_field.dart';
import 'components/singup_login_link.dart';
import 'singup_view_model.dart';

/// Modal inferior de cadastro (SingUp).
///
/// Antes era uma tela cheia (`Scaffold` próprio); agora segue o padrão de
/// **modal bottom** do app, reaproveitando a base visual [AppBottomModal]
/// (header com título + botão fechar, drag handle, botão de ação no rodapé e
/// acompanhamento do teclado). Mesmo virando modal, é um **modal complexo**
/// (vários campos, seleção de campo focado, fluxo loading/success/error), então
/// **mantém View + ViewModel** — o [SingUpViewModel] (`extends ChangeNotifier`)
/// é quem detém o estado; a View só reage via `AnimatedBuilder` e trata os
/// estados terminais de forma *one-shot* (igual ao `LoginView`).
///
/// Regras seguidas (ver `.pi/sdd_arquitetura_view_model.md`):
/// - `StatefulWidget` que cria o VM em `initState` e o descarta em `dispose`.
/// - Reconstrução via `AnimatedBuilder(animation: _viewModel, ...)` — sem
///   `setState`.
/// - `BuildContext` recebido por parâmetro nos métodos (não guardado como
///   campo do VM).
/// - Componentes (`SingUpField`, `SingUpLoginLink`) recebem dados + callbacks,
///   nunca o VM inteiro.
/// - Abertura/fechamento do modal fica por conta de quem chama
///   (`showSingUpBottomModal`), mantendo a navegação desacoplada da regra.
class SingUpView extends StatefulWidget {
  const SingUpView({super.key});

  @override
  State<SingUpView> createState() => _SingUpViewState();
}

class _SingUpViewState extends State<SingUpView> {
  late final SingUpViewModel _viewModel;
  final DisplayAlertRepository _displayAlert = getIt<DisplayAlertRepository>();
  final LoadingEventRepository _loadingEvent = getIt<LoadingEventRepository>();

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
          SnackBar(
            content: Text(AuthStrings.signUpSuccess),
            backgroundColor: Colors.green,
            duration: const Duration(seconds: 2),
          ),
        );
        // O modal é a rota atual: substitui-o pelo `/menu`, deixando a
        // navegação idêntica a um login bem-sucedido.
        Navigator.pushReplacementNamed(context, '/menu');
      });
      return;
    }

    if (state == SingUpState.error) {
      _loadingEvent.closeLoading(context);
      // Captura a mensagem e consome o estado ANTES de qualquer chamada
      // que possa disparar novas notificações, para que o modal de erro
      // seja exibido apenas uma vez (one-shot).
      final message = _viewModel.errorMessage ?? AuthStrings.signUpErrorDefault;
      _viewModel.consumeState();
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!mounted) return;
        _displayAlert.notificationError(
          context,
          AuthStrings.errorTitle,
          message,
        );
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final he = MediaQuery.of(context).size.height;

    return AnimatedBuilder(
      animation: _viewModel,
      builder: (context, _) {
        final registering = _viewModel.state == SingUpState.loading;

        return AppBottomModal(
          title: AuthStrings.signUpTitle,
          buttonLabel: registering
              ? AuthStrings.signUpButtonLoading
              : AuthStrings.signUpButton,
          onButtonPressed: registering ? () {} : _viewModel.register,
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: <Widget>[
                SizedBox(height: he * 0.01),
                SingUpField(
                  controller: _viewModel.nomeText,
                  hintText: AuthStrings.signUpNameHint,
                  icon: Icons.person_pin_outlined,
                  field: SingUpFieldType.name,
                  onTap: () => _viewModel.selectField(SingUpFieldType.name),
                ),
                SizedBox(height: he * 0.02),
                SingUpField(
                  controller: _viewModel.emailText,
                  hintText: AuthStrings.signUpEmailHint,
                  icon: Icons.email_outlined,
                  field: SingUpFieldType.email,
                  onTap: () => _viewModel.selectField(SingUpFieldType.email),
                ),
                SizedBox(height: he * 0.02),
                SingUpField(
                  controller: _viewModel.passwordText,
                  hintText: AuthStrings.signUpPasswordHint,
                  icon: Icons.lock_open_outlined,
                  field: SingUpFieldType.password,
                  isPassword: true,
                  ispasswordev: _viewModel.ispasswordev,
                  onTap: () =>
                      _viewModel.selectField(SingUpFieldType.password),
                  togglePassword: _viewModel.togglePasswordVisibility,
                ),
                SizedBox(height: he * 0.03),
                SingUpLoginLink(
                  // O cadastro é aberto a partir do login: "Entre" apenas
                  // fecha o modal e devolve o fluxo para a tela de login.
                  onLogin: () => Navigator.of(context).pop(),
                ),
                SizedBox(height: he * 0.01),
              ],
            ),
          ),
        );
      },
    );
  }
}

/// Helper que abre o [SingUpView] como modal bottom sheet.
///
/// Segue o mesmo formato dos demais helpers de modal do app
/// (`showOptionBottomModal`, `showAppBottomModal`): `isScrollControlled` para
/// acompanhar o teclado, fundo transparente (a base [AppBottomModal] desenha o
/// card branco arredondado) e drag habilitado.
Future<void> showSingUpBottomModal(BuildContext context) {
  return showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    builder: (context) => const SingUpView(),
  );
}
