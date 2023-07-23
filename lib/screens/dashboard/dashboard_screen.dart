import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:oflite/screens/dashboard/components/month_evolution.dart';
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
  final List<DADOS> _foundUsers = <DADOS>[];
  final MyBudgetDashboard _myBudgetDashboard = MyBudgetDashboard(
      qtdTotal: 0,
      qtdIntApproved: 0,
      qtdIntPending: 0,
      qtdIntFinish: 0,
      qtdIntDisapproved: 0,
      qtdDoubleApproved: 0,
      qtdDoublePending: 0,
      qtdDoubleFinish: 0,
      qtdDoubleDisapproved: 0);

  @override
  initState() {
    super.initState();
    try {
      setState(() async {
        await getInformationBudget().then((value) => {
        _myBudgetDashboard.qtdTotal = value.length,
          for (int i = 0; i < value.length; i++) {
            if (value[i].STATUS == "APROVADO") {
              _myBudgetDashboard.qtdIntApproved = _myBudgetDashboard.qtdIntApproved! + 1,
              _myBudgetDashboard.qtdDoubleApproved = _myBudgetDashboard.qtdDoubleApproved! + 1,
            } else if (_foundUsers[i].STATUS == "PENDENTE") {
              _myBudgetDashboard.qtdIntPending = _myBudgetDashboard.qtdIntPending! + 1,
              _myBudgetDashboard.qtdDoublePending = _myBudgetDashboard.qtdDoublePending! + 1,
            } else if (_foundUsers[i].STATUS == "REPROVADO") {
              _myBudgetDashboard.qtdIntDisapproved = _myBudgetDashboard.qtdIntDisapproved! + 1,
              _myBudgetDashboard.qtdDoubleDisapproved = _myBudgetDashboard.qtdDoubleDisapproved! + 1,
            } else if (_foundUsers[i].STATUS == "FINALIZADO") {
              _myBudgetDashboard.qtdIntFinish = _myBudgetDashboard.qtdIntFinish! + 1,
              _myBudgetDashboard.qtdDoubleFinish = _myBudgetDashboard.qtdDoubleFinish! + 1,},
          },
          setState(() {})});
      });
    } catch (e) {}
  }

  Future<List<DADOS>> getInformationBudgetMonths() async {
    _foundUsers.clear();

    // Obter a data atual
    DateTime currentDate = DateTime.now();

    // Subtrair 30 dias da data atual
    DateTime thirtyDaysAgo = currentDate.subtract(const Duration(days: 90));

    // Converter as datas para milissegundos desde a época em string
    String currentMillis = currentDate.millisecondsSinceEpoch.toString();
    String thirtyDaysAgoMillis = thirtyDaysAgo.millisecondsSinceEpoch.toString();

    final querySnapshot = await FirebaseFirestore.instance
        .collection("EMPRESAS/${UID.USER}/USERS/${UID.USER}/ORCAMENTOS")
        .where('ID', isGreaterThanOrEqualTo: thirtyDaysAgoMillis)
        .where('ID', isLessThanOrEqualTo: currentMillis)
        .orderBy('ID', descending: false)
        .get();

    for (var questionTmp in querySnapshot.docs) {
      final data = questionTmp.data();
      if (data != null) {
        // Verifica se os dados não são nulos antes de criar a instância de DADOS
        _foundUsers.add(DADOS.fromMap(data));
      }
    }

    return _foundUsers;
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

    final querySnapshot = await FirebaseFirestore.instance
        .collection("EMPRESAS/${UID.USER}/USERS/${UID.USER}/ORCAMENTOS")
        .where('ID', isGreaterThanOrEqualTo: thirtyDaysAgoMillis)
        .where('ID', isLessThanOrEqualTo: currentMillis)
        .orderBy('ID', descending: false)
        .get();

    for (var questionTmp in querySnapshot.docs) {
      final data = questionTmp.data();
      if (data != null) {
        // Verifica se os dados não são nulos antes de criar a instância de DADOS
        _foundUsers.add(DADOS.fromMap(data));
      }
    }

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
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  flex: 5,
                  child: Column(
                    children: [
                         MyFiles(item: _myBudgetDashboard),
                      const SizedBox(height: defaultPadding),
                      if (Responsive.isMobile(context))
                        const SizedBox(height: defaultPadding),
                      if (Responsive.isMobile(context))
                         StarageDetails(item: _myBudgetDashboard),
                      const SizedBox(height: defaultPadding),
                            MonthEvolution(items: _foundUsers!),
                      const SizedBox(height: defaultPadding),
                            RecentFiles(items: _foundUsers!),
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