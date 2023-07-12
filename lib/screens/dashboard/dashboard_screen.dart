import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import '../../Objetos/DADOS.dart';
import '../../Objetos/MyBudgetDashboard.dart';
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
  final MyBudgetDashboard _myBudgetDashboard = MyBudgetDashboard(
    qtdApproved: 0,
    qtdPending: 0,
    qtdDisapproved: 0,
    qtdFinish: 0,
  );
  @override
  initState() {
    try {
      setState(() async {
        await getInformationBudget().then((value) => {
        setState(() {}),
        });
      });

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

      for (int i = 0; i < _foundUsers.length; i++) {
        if (_foundUsers[i].STATUS == "APROVADO") {
          _myBudgetDashboard.qtdApproved = _myBudgetDashboard.qtdApproved! + 1;
        } else if (_foundUsers[i].STATUS == "PENDENTE") {
          _myBudgetDashboard.qtdPending = _myBudgetDashboard.qtdPending! + 1;
        } else if (_foundUsers[i].STATUS == "REPROVADO") {
          _myBudgetDashboard.qtdDisapproved = _myBudgetDashboard.qtdDisapproved! + 1;
        } else if (_foundUsers[i].STATUS == "FINALIZADO") {
          _myBudgetDashboard.qtdFinish = _myBudgetDashboard.qtdFinish! + 1;
        }
      }
    }).then((value) => {
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
                      //MyFiles(item: _myBudgetDashboard),
                      const SizedBox(height: defaultPadding),
                      if (Responsive.isMobile(context))
                        const SizedBox(height: defaultPadding),
                      if (Responsive.isMobile(context))
                         StarageDetails(item: _myBudgetDashboard,),
                      const SizedBox(height: defaultPadding),
                      const RecentFiles(),
                    ],
                  ),
                ),
                if (!Responsive.isMobile(context))
                  const SizedBox(width: defaultPadding),
                // On Mobile means if the screen is less than 850 we dont want to show it
                if (!Responsive.isMobile(context))
                    Expanded(
                    flex: 2,
                    child: StarageDetails(item: _myBudgetDashboard,),
                  ),
              ],
            )
          ],
        ),
      ),
    );
  }
}