import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../../anmition/fadeanimation.dart';
import '../../../constants.dart';
import 'package:oflite/Objetos/globalUIDUser.dart' as globalUIDUser;
import '../../../login.dart';
import '../../../responsive.dart';


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
        if (!Responsive.isDesktop(context))
          FadeAnimation(
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
        if (!Responsive.isMobile(context))
          Spacer(flex: Responsive.isDesktop(context) ? 2 : 1),
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
  final String _selectedItem = capitalizeFirstLetter(globalUIDUser.NOME!.split(' ')[0]);
  final List<String> _dropdownItems = [
    capitalizeFirstLetter(globalUIDUser.NOME!.split(' ')[0]),
    'Sair',
  ];

  final List<IconData> _dropdownIcons = [
    Icons.person,
    Icons.logout,
  ];

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
              await _logout();
              await prefs.remove('email');
              await prefs.remove('password');
                Navigator.pushAndRemoveUntil(
                  context,
                  MaterialPageRoute(builder: (context) => Login()),
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
