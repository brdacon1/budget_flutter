import 'package:google_fonts/google_fonts.dart';
import 'package:material_ui/material_ui.dart';
import 'package:oflite/injection.dart';
import 'package:oflite/modules/auth/domain/usecase/get_access_status_usecase.dart';
import 'package:oflite/modules/main_tab/presenter/strings/main_tab_pt_string.dart';
import 'package:oflite/modules/subscription/presenter/subscription_view.dart';
import 'package:oflite/shared/common/constants/colors.dart';

/// Faixa discreta com o tempo restante do teste grátis. Some para assinante,
/// para teste expirado e quando o trial ainda não foi sincronizado.
class MainTabTrialBanner extends StatelessWidget {
  const MainTabTrialBanner({super.key});

  @override
  Widget build(BuildContext context) {
    final access = getIt<GetAccessStatusUseCase>();
    final remaining = access.trialRemaining();
    if (access() != AccessStatus.trial ||
        remaining == null ||
        remaining <= Duration.zero) {
      return const SizedBox.shrink();
    }
    final hours = (remaining.inMinutes / 60).ceil();
    return Material(
      color: buttonColor,
      child: InkWell(
        onTap:
            () => Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const SubscriptionView()),
            ),
        child: Container(
          width: double.infinity,
          padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 16),
          alignment: Alignment.center,
          child: Text(
            MainTabStrings.trialBanner(hours),
            style: GoogleFonts.heebo(
              color: bgColor,
              fontSize: 13,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
      ),
    );
  }
}
