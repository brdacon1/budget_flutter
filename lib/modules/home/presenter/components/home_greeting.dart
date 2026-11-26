import 'package:google_fonts/google_fonts.dart';
import 'package:material_ui/material_ui.dart';
import 'package:oflite/modules/dashboard/presenter/strings/dashboard_pt_string.dart';
import 'package:oflite/modules/home/presenter/strings/home_pt_string.dart';
import 'package:oflite/shared/common/constants/colors.dart';

/// "Bom dia, Fulano 👋".
class HomeGreeting extends StatelessWidget {
  const HomeGreeting({super.key, required this.firstName});

  final String firstName;

  @override
  Widget build(BuildContext context) {
    final name =
        firstName.isEmpty
            ? DashboardStrings.userFallback
            : firstName[0].toUpperCase() + firstName.substring(1).toLowerCase();
    return Text(
      '${HomeStrings.greeting(DateTime.now())}\n$name 👋',
      style: GoogleFonts.heebo(
        color: whiteColor,
        fontSize: 26,
        fontWeight: FontWeight.bold,
        height: 1.2,
      ),
    );
  }
}
