import 'package:google_fonts/google_fonts.dart';
import 'package:material_ui/material_ui.dart';
import 'package:oflite/modules/subscription/presenter/strings/subscription_pt_string.dart';
import 'package:oflite/shared/common/constants/colors.dart';

/// Barra fixa no rodapé da tela Premium: botão de assinar, resumo do plano,
/// restaurar compras (iOS) e link para termos/privacidade.
class SubscriptionBottomBar extends StatelessWidget {
  const SubscriptionBottomBar({
    super.key,
    required this.caption,
    required this.isLoading,
    required this.canSubscribe,
    required this.onSubscribe,
    required this.onTerms,
    this.onRestore,
  });

  /// Resumo do plano escolhido; `null` enquanto não há preço.
  final String? caption;
  final bool isLoading;
  final bool canSubscribe;
  final VoidCallback onSubscribe;
  final VoidCallback onTerms;

  /// `null` esconde o botão (restaurar só existe na App Store).
  final VoidCallback? onRestore;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
      decoration: const BoxDecoration(
        color: bgColor,
        border: Border(top: BorderSide(color: premiumBarBorderColor)),
      ),
      child: SafeArea(
        top: false,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            SizedBox(
              width: double.infinity,
              child: TextButton(
                onPressed: isLoading || !canSubscribe ? null : onSubscribe,
                style: TextButton.styleFrom(
                  backgroundColor: buttonColor,
                  disabledBackgroundColor: premiumBorderColor,
                  minimumSize: const Size.fromHeight(50),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(30),
                  ),
                ),
                child:
                    isLoading
                        ? const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: blackColor,
                          ),
                        )
                        : Text(
                          SubscriptionStrings.subscribeButton,
                          style: GoogleFonts.heebo(
                            color: premiumOnAccentColor,
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
              ),
            ),
            if (caption != null) ...[
              const SizedBox(height: 8),
              Text(
                caption!,
                textAlign: TextAlign.center,
                style: const TextStyle(color: mutedTextColor, fontSize: 11),
              ),
            ],
            const SizedBox(height: 2),
            Wrap(
              alignment: WrapAlignment.center,
              crossAxisAlignment: WrapCrossAlignment.center,
              children: [
                if (onRestore != null)
                  TextButton(
                    onPressed: isLoading ? null : onRestore,
                    child: Text(
                      SubscriptionStrings.restoreButton,
                      style: const TextStyle(
                        color: buttonColor,
                        fontSize: 12,
                        fontFamily: 'Montserrat-Medium',
                      ),
                    ),
                  ),
                TextButton(
                  onPressed: onTerms,
                  child: Text(
                    SubscriptionStrings.termsAndPrivacy,
                    style: const TextStyle(
                      color: mutedTextColor,
                      fontSize: 11,
                      decoration: TextDecoration.underline,
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
