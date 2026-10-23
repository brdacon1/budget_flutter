import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:oflite/shared/common/widgets/anmition/fade_animation_widget.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:oflite/shared/common/constants/constants.dart';
import 'package:oflite/shared/models/global_uid_user.dart' as global_uid_user;
import 'package:oflite/modules/core/services/data/service/notification_service.dart';
import 'package:oflite/modules/login/presenter/login_view.dart';
import 'package:oflite/shared/common/widgets/responsive_widget.dart';


final FirebaseAuth _auth = FirebaseAuth.instance;

class Header extends StatelessWidget {
  const Header({
    Key? key,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.center,
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        if (!ResponsiveWidget.isDesktop(context))
          FadeAnimationWidget(
            delay: 1,
            child: Container(
              alignment: Alignment.topLeft,
              child: Text("Dashboard",style: GoogleFonts.heebo(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                  fontSize: 26,
                  letterSpacing: 1
              ),
              ),
            ),
          ),
        if (!ResponsiveWidget.isMobile(context))
          Spacer(flex: ResponsiveWidget.isDesktop(context) ? 2 : 1),
        const ProfileCard()
      ],
    );
  }
}

Future<void> _logout() async {
  await _auth.signOut();
}

class ProfileCard extends StatefulWidget {

  const ProfileCard({
    Key? key,
  }) : super(key: key);
  @override
  _ProfileCard createState() => _ProfileCard();
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

  final List<IconData> _dropdownIcons = [
    Icons.person,
    Icons.logout,
  ];

  @override
  void initState() {
    super.initState();
    final name = global_uid_user.name ?? 'Usuário';
    _selectedItem = capitalizeFirstLetter(name.split(' ')[0]);
    _dropdownItems = [
      _selectedItem,
      'Sair',
    ];
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
      child: DropdownButton<String>(
        underline: Container(color: Colors.transparent),
        value: _selectedItem,
        onChanged: (String? newValue)  async {
            SharedPreferences prefs = await SharedPreferences.getInstance();
            if(newValue! == 'Sair')
            {
              NotificationService.instance.stopBudgetApprovalListener();
              await _logout();
              await prefs.remove('email');
              await prefs.remove('password');
                Navigator.pushAndRemoveUntil(
                  context,
                  MaterialPageRoute(builder: (context) => LoginView()),
                    (Route<dynamic> route) => false,
                 ).then((value) async => {
              });
            }
        },
        items: _dropdownItems.asMap().entries.map<DropdownMenuItem<String>>((entry) {
          int index = entry.key;
          String value = entry.value;
          return DropdownMenuItem<String>(
            value: value,
            child: Row(
              children: [
                Icon(_dropdownIcons[index]), // Ícone
                const SizedBox(width: 5), // Espaçamento entre o ícone e o texto
                Text(value, style: const TextStyle(fontSize: 12),),
                const SizedBox(width: 5),// Texto do item
              ],
            ),
          );
        }).toList(),
      ),
    );
  }
}


class SearchField extends StatelessWidget {
  const SearchField({
    Key? key,
  }) : super(key: key);

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
