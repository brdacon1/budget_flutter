import 'package:material_ui/material_ui.dart';
import 'package:oflite/injection.dart';
import 'package:oflite/modules/legal/presenter/components/legal_body.dart';
import 'package:oflite/modules/legal/presenter/components/legal_link_chip.dart';
import 'package:oflite/modules/legal/domain/entity/legal_document.dart';
import 'package:oflite/modules/legal/presenter/legal_view_model.dart';
import 'package:oflite/shared/common/constants/colors.dart';

/// Página pública de documento legal (Web — `/termos-de-uso`,
/// `/politica-de-privacidade`, `/terms-of-use`, `/privacy-policy`).
class LegalView extends StatefulWidget {
  final LegalDocument document;

  const LegalView({super.key, required this.document});

  @override
  State<LegalView> createState() => _LegalViewState();
}

class _LegalViewState extends State<LegalView> {
  late final LegalViewModel _viewModel = getIt<LegalViewModel>();

  @override
  void dispose() {
    _viewModel.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final doc = widget.document;
    return Title(
      title: doc.title,
      color: bgColor,
      child: Scaffold(
        backgroundColor: bgColor,
        body: SelectionArea(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 32),
            child: Center(
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 760),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: [
                        LegalLinkChip(
                          label: doc.otherDocumentLabel,
                          onTap: () => _viewModel.open(doc.otherDocumentPath),
                        ),
                        LegalLinkChip(
                          label: doc.switchLanguageLabel,
                          onTap: () => _viewModel.open(doc.switchLanguagePath),
                        ),
                      ],
                    ),
                    const SizedBox(height: 24),
                    Text(
                      doc.title,
                      style: const TextStyle(
                        color: buttonColor,
                        fontSize: 26,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      doc.lastUpdated,
                      style: const TextStyle(color: mutedTextColor, fontSize: 14),
                    ),
                    if (doc.intro != null) ...[
                      const SizedBox(height: 24),
                      LegalBody(doc.intro!),
                    ],
                    for (final section in doc.sections) ...[
                      const SizedBox(height: 28),
                      Text(
                        section.title,
                        style: const TextStyle(
                          color: whiteColor,
                          fontSize: 18,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const SizedBox(height: 8),
                      LegalBody(section.body),
                    ],
                    const SizedBox(height: 40),
                    const Divider(color: cardBorderColor),
                    const SizedBox(height: 16),
                    Text(
                      doc.footer,
                      style: const TextStyle(color: mutedTextColor, fontSize: 14),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
