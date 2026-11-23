import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import 'package:material_ui/material_ui.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:oflite/injection.dart';
import 'package:oflite/modules/auth/domain/repository/user_repository.dart';
import 'package:oflite/modules/auth/presenter/login/login_view.dart';
import 'package:oflite/modules/core/crashlytics/domain/repository/crashlytics_repository.dart';
import 'package:oflite/modules/core/notification/domain/repository/notification_repository.dart';
import 'package:oflite/modules/delete_account/presenter/delete_account_in_app/delete_account_in_app_view.dart';
import 'package:oflite/modules/subscription/presenter/subscription_view.dart';
import 'package:oflite/modules/dashboard/presenter/strings/dashboard_pt_string.dart';
import 'package:oflite/shared/common/constants/colors.dart';
import 'package:oflite/shared/common/widgets/responsive_widget.dart';
import 'package:shared_preferences/shared_preferences.dart';

final FirebaseAuth _auth = FirebaseAuth.instance;

class Header extends StatelessWidget {
  const Header({super.key});

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.center,
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Container(
          alignment: Alignment.topLeft,
          child: Text(
            DashboardStrings.pageTitle,
            style: GoogleFonts.heebo(
              color: Colors.white,
              fontWeight: FontWeight.bold,
              fontSize: 26,
              letterSpacing: 1,
            ),
          ),
        ),
        if (!ResponsiveWidget.isMobile(context)) const Spacer(),
        const ProfileCard(),
      ],
    );
  }
}

Future<void> _logout() async {
  try {
    await GoogleSignIn.instance.signOut();
  } catch (e) {
    debugPrint('Erro ao fazer signOut do GoogleSignIn: $e');
  }
  try {
    await _auth.signOut();
  } catch (e) {
    debugPrint('Erro ao fazer signOut do FirebaseAuth: $e');
  }
}

class ProfileCard extends StatefulWidget {
  const ProfileCard({super.key});

  @override
  State<ProfileCard> createState() => _ProfileCard();
}

String capitalizeFirstLetter(String text) {
  if (text.isEmpty) {
    return '';
  }
  return text[0].toUpperCase() + text.substring(1).toLowerCase();
}

class _ProfileCard extends State<ProfileCard> {
  late String _selectedItem;
  late final List<String> _dropdownItems;

  late final List<IconData> _dropdownIcons;

  @override
  void initState() {
    super.initState();
    final name =
        getIt<UserRepository>().selectUser.value?.name ??
        DashboardStrings.userFallback;
    _selectedItem = capitalizeFirstLetter(name.split(' ')[0]);
    // Premium e exclusão de conta só no app (web tem página própria).
    _dropdownItems = [
      _selectedItem,
      if (!kIsWeb) DashboardStrings.premium,
      if (!kIsWeb) DashboardStrings.deleteAccount,
      DashboardStrings.logout,
    ];
    _dropdownIcons = [
      Icons.person,
      if (!kIsWeb) Icons.workspace_premium_outlined,
      if (!kIsWeb) Icons.delete_forever_outlined,
      Icons.logout,
    ];
  }

  Future<void> _openNavigationScreen() async {
    await Navigator.pushAndRemoveUntil(
      context,
      MaterialPageRoute(builder: (context) => const LoginView()),
      (Route<dynamic> route) => false,
    ).then((value) async => {});
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(left: defaultPadding),
      padding: const EdgeInsets.symmetric(
        horizontal: defaultPadding,
        vertical: defaultPadding / 2,
      ),
      decoration: BoxDecoration(
        color: Theme.of(context).canvasColor,
        borderRadius: const BorderRadius.all(Radius.circular(10)),
        border: Border.all(color: Colors.white10),
      ),
      // PopupMenuButton: a largura acompanha só o nome, não o item mais
      // longo do menu (DropdownButton sempre usa o mais largo).
      child: PopupMenuButton<String>(
        tooltip: '',
        color: Theme.of(context).canvasColor,
        onSelected: (String newValue) async {
          if (newValue == DashboardStrings.premium) {
            await Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const SubscriptionView()),
            );
            return;
          }
          if (newValue == DashboardStrings.deleteAccount) {
            await Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const DeleteAccountInAppView()),
            );
            return;
          }
          if (newValue == DashboardStrings.logout) {
            SharedPreferences prefs = await SharedPreferences.getInstance();
            getIt<NotificationRepository>().stopBudgetApprovalListener();
            getIt<CrashlyticsRepository>().setUser(null);
            await _logout();
            await prefs.remove('email');
            await prefs.remove('password');
            await _openNavigationScreen();
          }
        },
        itemBuilder: (context) => [
          for (var i = 1; i < _dropdownItems.length; i++)
            PopupMenuItem<String>(
              value: _dropdownItems[i],
              child: Row(
                children: [
                  Icon(_dropdownIcons[i]),
                  const SizedBox(width: 8),
                  Text(_dropdownItems[i], style: const TextStyle(fontSize: 12)),
                ],
              ),
            ),
        ],
        child: ValueListenableBuilder(
          valueListenable: getIt<UserRepository>().selectUser,
          builder: (context, user, _) {
            final name = capitalizeFirstLetter(
              (user?.name ?? '').trim().split(' ').first,
            );
            return Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.person),
                const SizedBox(width: 5),
                Text(
                  name.isEmpty ? DashboardStrings.userFallback : name,
                  style: const TextStyle(fontSize: 12),
                ),
                const SizedBox(width: 5),
                const Icon(Icons.arrow_drop_down),
              ],
            );
          },
        ),
      ),
    );
  }
}

class SearchField extends StatelessWidget {
  const SearchField({super.key});

  @override
  Widget build(BuildContext context) {
    return TextField(
      decoration: InputDecoration(
        hintText: "Search",
        fillColor: Theme.of(context).canvasColor,
        filled: true,
        border: const OutlineInputBorder(
          borderSide: BorderSide.none,
          borderRadius: BorderRadius.all(Radius.circular(10)),
        ),
        suffixIcon: InkWell(
          onTap: () {},
          child: Container(
            padding: const EdgeInsets.all(defaultPadding * 0.75),
            margin: const EdgeInsets.symmetric(horizontal: defaultPadding / 2),
            decoration: const BoxDecoration(
              color: primaryColor,
              borderRadius: BorderRadius.all(Radius.circular(10)),
            ),
            child: SvgPicture.asset("assets/icons/Search.svg"),
          ),
        ),
      ),
    );
  }
}
