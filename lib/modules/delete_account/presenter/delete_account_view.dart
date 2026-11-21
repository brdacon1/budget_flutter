import 'package:material_ui/material_ui.dart';
import 'package:oflite/injection.dart';
import 'package:oflite/modules/delete_account/presenter/delete_account_view_model.dart';
import 'package:oflite/modules/delete_account/presenter/strings/delete_account_pt_string.dart';
import 'package:oflite/shared/common/constants/colors.dart';

/// Página pública para solicitação de exclusão de conta e dados.
///
/// Acessível via URL /delete-account no Flutter Web. Cumpre o requisito
/// do Google Play de expor um link para exclusão de conta com:
/// - Nome do app/desenvolvedor.
/// - Etapas claras para solicitar a exclusão.
/// - Especificação dos tipos de dados excluídos/mantidos.
class DeleteAccountView extends StatefulWidget {
  const DeleteAccountView({super.key});

  @override
  State<DeleteAccountView> createState() => _DeleteAccountViewState();
}

class _DeleteAccountViewState extends State<DeleteAccountView> {
  late final DeleteAccountViewModel _viewModel;
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _viewModel = getIt<DeleteAccountViewModel>();
    _viewModel.deleteCommand.addListener(_onCommandChanged);
    _emailController.addListener(() {
      _viewModel.email = _emailController.text;
    });
    _passwordController.addListener(() {
      _viewModel.password = _passwordController.text;
    });
  }

  @override
  void dispose() {
    _viewModel.deleteCommand.removeListener(_onCommandChanged);
    _emailController.dispose();
    _passwordController.dispose();
    _viewModel.dispose();
    super.dispose();
  }

  void _onCommandChanged() {
    if (_viewModel.deleteCommand.completed && _viewModel.success) {
      _showSuccess();
    }
    setState(() {});
  }

  void _showSuccess() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => AlertDialog(
        backgroundColor: secondaryColor,
        title: Text(
          DeleteAccountPtString.successTitle,
          style: const TextStyle(color: Colors.white),
        ),
        content: Text(
          DeleteAccountPtString.successMessage,
          style: const TextStyle(color: Colors.white70),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: const Text('OK', style: TextStyle(color: buttonColor)),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final bool isRunning = _viewModel.deleteCommand.running;

    return Scaffold(
      backgroundColor: bgColor,
      appBar: AppBar(
        backgroundColor: bgColor,
        elevation: 0,
        title: Text(
          DeleteAccountPtString.pageTitle,
          style: const TextStyle(color: Colors.white, fontSize: 20),
        ),
        centerTitle: true,
      ),
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 640),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Nome do app
                Text(
                  DeleteAccountPtString.appName,
                  style: const TextStyle(
                    color: buttonColor,
                    fontSize: 28,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  DeleteAccountPtString.subTitle,
                  style: const TextStyle(color: Colors.white70, fontSize: 16),
                ),
                const SizedBox(height: 32),

                // Etapas
                Text(
                  DeleteAccountPtString.stepsTitle,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 18,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 12),
                _buildBullet(DeleteAccountPtString.step1),
                _buildBullet(DeleteAccountPtString.step2),
                _buildBullet(DeleteAccountPtString.step3),
                const SizedBox(height: 32),

                // Dados excluídos
                Text(
                  DeleteAccountPtString.dataTitle,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 18,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 12),
                Text(
                  DeleteAccountPtString.dataDeletedIntro,
                  style: const TextStyle(color: Colors.white70, fontSize: 15),
                ),
                const SizedBox(height: 8),
                _buildBullet(DeleteAccountPtString.dataDeleted1),
                _buildBullet(DeleteAccountPtString.dataDeleted2),
                _buildBullet(DeleteAccountPtString.dataDeleted3),
                _buildBullet(DeleteAccountPtString.dataDeleted4),
                _buildBullet(DeleteAccountPtString.dataDeleted5),
                const SizedBox(height: 24),

                Text(
                  DeleteAccountPtString.dataRetainedTitle,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  DeleteAccountPtString.dataRetained,
                  style: const TextStyle(color: Colors.white70, fontSize: 14),
                ),
                const SizedBox(height: 40),

                // Formulário
                if (!_viewModel.success) ...[
                  TextField(
                    controller: _emailController,
                    enabled: !isRunning,
                    keyboardType: TextInputType.emailAddress,
                    style: const TextStyle(color: Colors.white),
                    decoration: InputDecoration(
                      labelText: DeleteAccountPtString.emailLabel,
                      labelStyle: const TextStyle(color: Colors.white54),
                      hintText: DeleteAccountPtString.emailHint,
                      hintStyle: const TextStyle(color: Colors.white24),
                      errorText: _viewModel.emailError,
                      errorStyle: const TextStyle(color: redColor),
                      filled: true,
                      fillColor: secondaryColor,
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide.none,
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: _passwordController,
                    enabled: !isRunning,
                    obscureText: true,
                    style: const TextStyle(color: Colors.white),
                    decoration: InputDecoration(
                      labelText: DeleteAccountPtString.passwordLabel,
                      labelStyle: const TextStyle(color: Colors.white54),
                      errorText: _viewModel.passwordError,
                      errorStyle: const TextStyle(color: redColor),
                      filled: true,
                      fillColor: secondaryColor,
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide.none,
                      ),
                    ),
                  ),                  const SizedBox(height: 20),
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Checkbox(
                        value: _viewModel.confirmed,
                        onChanged: isRunning
                            ? null
                            : (v) => setState(() {
                                  _viewModel.confirmed = v ?? false;
                                }),
                        activeColor: buttonColor,
                        checkColor: bgColor,
                      ),
                      Expanded(
                        child: Padding(
                          padding: const EdgeInsets.only(top: 12),
                          child: Text(
                            DeleteAccountPtString.confirmLabel,
                            style: const TextStyle(
                              color: Colors.white70,
                              fontSize: 14,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                  if (_viewModel.confirmError != null)
                    Padding(
                      padding: const EdgeInsets.only(left: 12, top: 4),
                      child: Text(
                        _viewModel.confirmError!,
                        style: const TextStyle(color: redColor, fontSize: 12),
                      ),
                    ),
                  const SizedBox(height: 24),
                  SizedBox(
                    width: double.infinity,
                    height: 52,
                    child: ElevatedButton(
                      onPressed: isRunning
                          ? null
                          : () => _viewModel.deleteCommand.execute(false),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: redColor,
                        disabledBackgroundColor: redColor.withValues(alpha: 0.4),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      child: isRunning
                          ? const SizedBox(
                              width: 20,
                              height: 20,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                color: Colors.white,
                              ),
                            )
                          : Text(
                              DeleteAccountPtString.deleteButton,
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 16,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                    ),
                  ),
                  const SizedBox(height: 12),
                  SizedBox(
                    width: double.infinity,
                    height: 52,
                    child: OutlinedButton(
                      onPressed: isRunning
                          ? null
                          : () => _viewModel.deleteCommand.execute(true),
                      style: OutlinedButton.styleFrom(
                        side: const BorderSide(color: Colors.white38),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      child: Text(
                        DeleteAccountPtString.deleteWithGoogleButton,
                        style: const TextStyle(color: Colors.white, fontSize: 15),
                      ),
                    ),
                  ),                ],

                if (_viewModel.deleteCommand.error &&
                    _viewModel.passwordError == null &&
                    _viewModel.emailError == null &&
                    _viewModel.confirmError == null)
                  Padding(
                    padding: const EdgeInsets.only(top: 16),
                    child: Text(
                      DeleteAccountPtString.errorGeneric,
                      style: const TextStyle(color: redColor, fontSize: 14),
                      textAlign: TextAlign.center,
                    ),
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildBullet(String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('• ', style: TextStyle(color: Colors.white70, fontSize: 16)),
          Expanded(
            child: Text(
              text,
              style: const TextStyle(color: Colors.white70, fontSize: 15),
            ),
          ),
        ],
      ),
    );
  }
}
