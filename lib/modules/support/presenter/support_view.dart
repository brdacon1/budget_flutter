import 'package:material_ui/material_ui.dart';
import 'package:oflite/injection.dart';
import 'package:oflite/modules/support/presenter/strings/support_pt_string.dart';
import 'package:oflite/modules/support/presenter/support_view_model.dart';
import 'package:oflite/shared/common/constants/colors.dart';

/// Página pública de suporte (Web — `/support`).
///
/// URL usada no campo "Support URL" da App Store. O número do WhatsApp fica
/// em `SupportViewModel.whatsappNumber`.
class SupportView extends StatefulWidget {
  const SupportView({super.key});

  @override
  State<SupportView> createState() => _SupportViewState();
}

class _SupportViewState extends State<SupportView> {
  late final SupportViewModel _viewModel = getIt<SupportViewModel>();

  @override
  void dispose() {
    _viewModel.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: bgColor,
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 480),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  SupportPtString.appName,
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    color: buttonColor,
                    fontSize: 28,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 12),
                Text(
                  SupportPtString.description,
                  textAlign: TextAlign.center,
                  style: const TextStyle(color: Colors.white70, fontSize: 16),
                ),
                const SizedBox(height: 32),
                SizedBox(
                  width: double.infinity,
                  height: 52,
                  child: ElevatedButton.icon(
                    onPressed: _viewModel.openWhatsApp,
                    icon: const Icon(Icons.chat_bubble_outline),
                    label: Text(
                      SupportPtString.button,
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: buttonColor,
                      foregroundColor: bgColor,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                SelectableText(
                  'WhatsApp: ${_viewModel.displayNumber}',
                  style: const TextStyle(color: Colors.white54, fontSize: 14),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
