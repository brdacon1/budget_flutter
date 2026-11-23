import 'package:material_ui/material_ui.dart';
import 'package:oflite/injection.dart';
import 'package:oflite/modules/auth/presenter/login/login_view.dart';
import 'package:oflite/modules/core/display_alert/domain/repository/display_alert_repository.dart';
import 'package:oflite/modules/delete_account/presenter/delete_account_in_app/delete_account_in_app_view_model.dart';
import 'package:oflite/modules/delete_account/presenter/delete_account_in_app/strings/delete_account_in_app_pt_string.dart';
import 'package:oflite/shared/common/constants/colors.dart';

/// Exclusão de conta dentro do app (exigência App Store 5.1.1(v)).
class DeleteAccountInAppView extends StatefulWidget {
  const DeleteAccountInAppView({super.key});

  @override
  State<DeleteAccountInAppView> createState() => _DeleteAccountInAppViewState();
}

class _DeleteAccountInAppViewState extends State<DeleteAccountInAppView> {
  late final DeleteAccountInAppViewModel _viewModel;
  final _alert = getIt<DisplayAlertRepository>();

  @override
  void initState() {
    super.initState();
    _viewModel = getIt<DeleteAccountInAppViewModel>();
    _viewModel.addListener(_onChanged);
    _viewModel.deleteCommand.addListener(_onDeleteChanged);
  }

  @override
  void dispose() {
    _viewModel.removeListener(_onChanged);
    _viewModel.deleteCommand.removeListener(_onDeleteChanged);
    _viewModel.dispose();
    super.dispose();
  }

  void _onChanged() => setState(() {});

  void _onDeleteChanged() {
    final cmd = _viewModel.deleteCommand;
    if (cmd.completed) {
      _alert.notificationNotCloseScreen(
        context,
        DeleteAccountInAppStrings.successTitle,
        DeleteAccountInAppStrings.successMessage,
      );
      Navigator.pushAndRemoveUntil(
        context,
        MaterialPageRoute(builder: (_) => const LoginView()),
        (_) => false,
      );
      return;
    }
    if (cmd.error && !_viewModel.isValidationError(cmd.result)) {
      _alert.notificationError(
        context,
        DeleteAccountInAppStrings.errorTitle,
        DeleteAccountInAppStrings.errorMessage,
      );
    }
    setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    final running = _viewModel.deleteCommand.running;
    return Scaffold(
      backgroundColor: bgColor,
      appBar: AppBar(
        backgroundColor: bgColor,
        foregroundColor: Colors.white,
        title: Text(DeleteAccountInAppStrings.title),
      ),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.all(20),
          children: [
            const Icon(Icons.warning_amber_rounded,
                color: Colors.redAccent, size: 48),
            const SizedBox(height: 16),
            Text(DeleteAccountInAppStrings.warning,
                style: const TextStyle(color: Colors.white, fontSize: 15)),
            const SizedBox(height: 12),
            Text(DeleteAccountInAppStrings.subscriptionNote,
                style: const TextStyle(color: Colors.white70, fontSize: 13)),
            const SizedBox(height: 12),
            Text(DeleteAccountInAppStrings.reauthNote,
                style: const TextStyle(color: Colors.white70, fontSize: 13)),
            if (_viewModel.needsPassword) ...[
              const SizedBox(height: 20),
              TextField(
                obscureText: true,
                style: const TextStyle(color: Colors.white),
                onChanged: (v) => _viewModel.password = v,
                decoration: InputDecoration(
                  labelText: DeleteAccountInAppStrings.passwordLabel,
                  labelStyle: const TextStyle(color: Colors.white70),
                  errorText: _viewModel.passwordError,
                ),
              ),
            ],
            const SizedBox(height: 16),
            CheckboxListTile(
              contentPadding: EdgeInsets.zero,
              controlAffinity: ListTileControlAffinity.leading,
              value: _viewModel.confirmed,
              onChanged: (v) => _viewModel.confirmed = v ?? false,
              title: Text(DeleteAccountInAppStrings.confirmLabel,
                  style: const TextStyle(color: Colors.white, fontSize: 14)),
              subtitle: _viewModel.confirmError == null
                  ? null
                  : Text(_viewModel.confirmError!,
                      style: const TextStyle(color: Colors.redAccent)),
            ),
            const SizedBox(height: 24),
            SizedBox(
              height: 50,
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.redAccent,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(26)),
                ),
                onPressed: running ? null : _viewModel.deleteCommand.execute,
                child: running
                    ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(
                            strokeWidth: 2, color: Colors.white),
                      )
                    : Text(DeleteAccountInAppStrings.button),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
