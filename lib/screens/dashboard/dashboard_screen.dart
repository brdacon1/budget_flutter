import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import '../../Objetos/DADOS.dart';
import '../../constants.dart';
import '../../responsive.dart';
import 'components/header.dart';
import 'components/my_fields.dart';
import 'components/recent_files.dart';
import 'components/storage_details.dart';
import 'package:oflite/Objetos/globalUIDUser.dart' as UID;

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({Key? key}) : super(key: key);
  @override
  _DashboardScreen createState() => _DashboardScreen();
}


class _DashboardScreen extends State<DashboardScreen> {
  final _foundUsers = <DADOS>[];

  @override
  initState() {
    try {
      setState(() async {
        await getInformationBudget();
      });
      setState(() {});
    } catch (e) {}
    super.initState();
  }

  Future<List<DADOS>> getInformationBudget() async {
    _foundUsers.clear();

    // Obter a data atual
    DateTime currentDate = DateTime.now();

    // Subtrair 30 dias da data atual
    DateTime thirtyDaysAgo = currentDate.subtract(const Duration(days: 30));

    // Converter as datas para milissegundos desde a época em string
    String currentMillis = currentDate.millisecondsSinceEpoch.toString();
    String thirtyDaysAgoMillis = thirtyDaysAgo.millisecondsSinceEpoch.toString();

    await FirebaseFirestore.instance
        .collection("EMPRESAS/${UID.USER}/USERS/${UID.USER}/ORCAMENTOS")
        .where('ID', isGreaterThanOrEqualTo: thirtyDaysAgoMillis)
        .where('ID', isLessThanOrEqualTo: currentMillis)
        .orderBy('ID', descending: false)
        .get()
        .then((value) async {
      for (var questionTmp in value.docs) {
        _foundUsers.add(DADOS.fromMap(questionTmp));
      }
    });
    return _foundUsers;
  }


  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(defaultPadding),
        child: Column(
          children: [
            const Header(),
            const SizedBox(height: defaultPadding),
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  flex: 5,
                  child: Column(
                    children: [
                      const MyFiles(),
                      const SizedBox(height: defaultPadding),
                      if (Responsive.isMobile(context))
                        const SizedBox(height: defaultPadding),
                      if (Responsive.isMobile(context))
                        const StarageDetails(),
                      const SizedBox(height: defaultPadding),
                      const RecentFiles(),
                    ],
                  ),
                ),
                if (!Responsive.isMobile(context))
                  const SizedBox(width: defaultPadding),
                // On Mobile means if the screen is less than 850 we dont want to show it
                if (!Responsive.isMobile(context))
                  const Expanded(
                    flex: 2,
                    child: StarageDetails(),
                  ),
              ],
            )
          ],
        ),
      ),
    );
  }
}