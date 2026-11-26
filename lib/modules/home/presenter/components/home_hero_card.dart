import 'package:google_fonts/google_fonts.dart';
import 'package:material_ui/material_ui.dart';
import 'package:oflite/injection.dart';
import 'package:oflite/modules/core/convert_coin/domain/repository/convert_coin_repository.dart';
import 'package:oflite/modules/dashboard/domain/entity/dashboard_month_summary.dart';
import 'package:oflite/modules/dashboard/presenter/strings/dashboard_pt_string.dart';
import 'package:oflite/modules/home/presenter/strings/home_pt_string.dart';
import 'package:oflite/shared/common/constants/colors.dart';

/// Card em gradiente: valor total e quantidade dos aprovados do mês.
class HomeHeroCard extends StatelessWidget {
  const HomeHeroCard({super.key, required this.summary, required this.month});

  final DashboardMonthSummary summary;
  final DateTime month;

  @override
  Widget build(BuildContext context) {
    final approved = summary.of(DashboardStatus.approved);
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: const BoxDecoration(
        borderRadius: BorderRadius.all(Radius.circular(20)),
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [homeHeroStartColor, homeHeroEndColor],
        ),
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '${HomeStrings.heroTitle} · ${DashboardStrings.monthLabel(month)}',
                  style: const TextStyle(
                    color: blackColor,
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 10),
                FittedBox(
                  fit: BoxFit.scaleDown,
                  alignment: Alignment.centerLeft,
                  child: Text(
                    getIt<ConvertCoinRepository>().convertFromDouble(
                      approved.budgeted,
                    ),
                    style: GoogleFonts.heebo(
                      color: blackColor,
                      fontSize: 30,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  HomeStrings.heroCount(approved.count),
                  style: const TextStyle(color: blackColor, fontSize: 13),
                ),
              ],
            ),
          ),
          const SizedBox(width: 12),
          const Icon(Icons.verified_outlined, color: blackColor, size: 56),
        ],
      ),
    );
  }
}
