import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:oflite/screens/dashboard/components/month_evolution.dart';
import '../../Objetos/DADOS.dart';
import '../../Objetos/MyBudgetDashboard.dart';
import '../../Objetos/month_calculate.dart';
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


  @override
  void dispose() {
    super.dispose();
  }


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

  final MonthCalculate _monthCalculate = MonthCalculate(
    totalApprovedMonth_0: 0,
    totalApprovedMonth_1: 0,
    totalApprovedMonth_2: 0,
    totalApprovedMonth_3: 0,

    totalReprovedMonth_0: 0,
    totalReprovedMonth_1: 0,
    totalReprovedMonth_2: 0,
    totalReprovedMonth_3: 0,

    totalPendingMonth_0: 0,
    totalPendingMonth_1: 0,
    totalPendingMonth_2: 0,
    totalPendingMonth_3: 0,

    totalFinishMonth_0: 0,
    totalFinishMonth_1: 0,
    totalFinishMonth_2: 0,
    totalFinishMonth_3: 0,
  );

  double getWeekOfMonthFromMilliseconds(int millisecondsSinceEpoch) {
    DateTime dateTime = DateTime.fromMillisecondsSinceEpoch(millisecondsSinceEpoch);
    int day = dateTime.day;
    double week = day / 7;
    return week;
  }


  void startDashBoard() async{
    int millisecondsSinceEpoch = 0;
    double weekNumber = 0;
    try {
      var value = await getInformationBudget();
      _myBudgetDashboard.qtdTotal = value.length;
      for (int i = 0; i < value.length; i++) {
        weekNumber = 0;
        if (value[i].STATUS == "APROVADO") {
          _myBudgetDashboard.qtdIntApproved = _myBudgetDashboard.qtdIntApproved! + 1;
          _myBudgetDashboard.qtdDoubleApproved = _myBudgetDashboard.qtdDoubleApproved! + 1;
          millisecondsSinceEpoch = int.parse(value[i].ID!);
          weekNumber = getWeekOfMonthFromMilliseconds(millisecondsSinceEpoch);

          if (weekNumber <= 1) {
            _monthCalculate.totalApprovedMonth_0 = (value[i].VALORTOTAL! / 1000) + _monthCalculate.totalApprovedMonth_0!;
          } else if (weekNumber <= 2) {
            _monthCalculate.totalApprovedMonth_1 = (value[i].VALORTOTAL! / 1000) + _monthCalculate.totalApprovedMonth_1!;
          } else if (weekNumber <= 3) {
            _monthCalculate.totalApprovedMonth_2 = (value[i].VALORTOTAL! / 1000) + _monthCalculate.totalApprovedMonth_2!;
          } else if (weekNumber <= 4.5) {
            _monthCalculate.totalApprovedMonth_3 = (value[i].VALORTOTAL! / 1000) + _monthCalculate.totalApprovedMonth_3!;
          }

        } else if (value[i].STATUS == "PENDENTE") {
          _myBudgetDashboard.qtdIntPending = _myBudgetDashboard.qtdIntPending! + 1;
          _myBudgetDashboard.qtdDoublePending = _myBudgetDashboard.qtdDoublePending! + 1;

          millisecondsSinceEpoch = int.parse(value[i].ID!);
          weekNumber = getWeekOfMonthFromMilliseconds(millisecondsSinceEpoch);

          if (weekNumber <= 1) {
            _monthCalculate.totalPendingMonth_0 = (value[i].VALORTOTAL! / 1000) + _monthCalculate.totalPendingMonth_0!;
          } else if (weekNumber <= 2) {
            _monthCalculate.totalPendingMonth_1 = (value[i].VALORTOTAL! / 1000) + _monthCalculate.totalPendingMonth_1!;
          } else if  (weekNumber <= 3) {
            _monthCalculate.totalPendingMonth_2 = (value[i].VALORTOTAL! / 1000) + _monthCalculate.totalPendingMonth_2!;
          } else if (weekNumber <= 4.5) {
            _monthCalculate.totalPendingMonth_3 = (value[i].VALORTOTAL! / 1000) + _monthCalculate.totalPendingMonth_3!;
          }

        } else if (value[i].STATUS == "REPROVADO") {

          _myBudgetDashboard.qtdIntDisapproved = _myBudgetDashboard.qtdIntDisapproved! + 1;
          _myBudgetDashboard.qtdDoubleDisapproved = _myBudgetDashboard.qtdDoubleDisapproved! + 1;
          millisecondsSinceEpoch = int.parse(value[i].ID!);
          weekNumber = getWeekOfMonthFromMilliseconds(millisecondsSinceEpoch);

          if (weekNumber <= 1) {
            _monthCalculate.totalReprovedMonth_0 = (value[i].VALORTOTAL! / 1000) + _monthCalculate.totalReprovedMonth_0!;
          } else if (weekNumber <= 2) {
            _monthCalculate.totalReprovedMonth_1 = (value[i].VALORTOTAL! / 1000) + _monthCalculate.totalReprovedMonth_1!;
          } else if  (weekNumber <= 3) {
            _monthCalculate.totalReprovedMonth_2 = (value[i].VALORTOTAL! / 1000) + _monthCalculate.totalReprovedMonth_2!;
          } else if (weekNumber <= 4.5) {
            _monthCalculate.totalReprovedMonth_3 = (value[i].VALORTOTAL! / 1000) + _monthCalculate.totalReprovedMonth_3!;
          }
        } else if (value[i].STATUS == "FINALIZADO") {
          _myBudgetDashboard.qtdIntFinish = _myBudgetDashboard.qtdIntFinish! + 1;
          _myBudgetDashboard.qtdDoubleFinish = _myBudgetDashboard.qtdDoubleFinish! + 1;

          millisecondsSinceEpoch = int.parse(value[i].ID!);
          weekNumber = getWeekOfMonthFromMilliseconds(millisecondsSinceEpoch);

          if (weekNumber <= 1) {
            _monthCalculate.totalFinishMonth_0 = (value[i].VALORTOTAL! / 1000) + _monthCalculate.totalFinishMonth_0!;
          } else if (weekNumber <= 2) {
            _monthCalculate.totalFinishMonth_1 = (value[i].VALORTOTAL! / 1000) + _monthCalculate.totalFinishMonth_1!;
          } else if  (weekNumber <= 3) {
            _monthCalculate.totalFinishMonth_2 = (value[i].VALORTOTAL! / 1000) + _monthCalculate.totalFinishMonth_2!;
          } else if (weekNumber <= 4.5) {
            _monthCalculate.totalFinishMonth_3 = (value[i].VALORTOTAL! / 1000) + _monthCalculate.totalFinishMonth_3!;
          }
        }
      }

    } catch (e) {
      print(e);
    }
    setState(() {});
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    startDashBoard();
    setState(() {});
  }

  @override
  initState() {
    super.initState();
  }

  Future<List<DADOS>> getInformationBudget() async {
    _foundUsers.clear();
    DateTime currentDate = DateTime.now();
    DateTime firstDayOfCurrentMonth = DateTime(currentDate.year, currentDate.month, 1);

    DateTime lastDayOfCurrentMonth;
    if (currentDate.month == 12) {
      lastDayOfCurrentMonth = DateTime(currentDate.year + 1, 1, 0);
    } else {
      lastDayOfCurrentMonth = DateTime(currentDate.year, currentDate.month + 1, 0);
    }

    int firstDayMillis = firstDayOfCurrentMonth.millisecondsSinceEpoch;
    int lastDayMillis = lastDayOfCurrentMonth.millisecondsSinceEpoch;


    print(firstDayMillis);
    print(lastDayMillis);

    final querySnapshot = await FirebaseFirestore.instance
        .collection("EMPRESAS/${UID.USER}/USERS/${UID.USER}/ORCAMENTOS")
        .where('ID', isGreaterThanOrEqualTo: firstDayMillis)
        .where('ID', isLessThanOrEqualTo: lastDayMillis)
        .orderBy('ID', descending: false)
        .get();

    for (var questionTmp in querySnapshot.docs) {
      final data = questionTmp.data();
      _foundUsers.add(DADOS.fromMap(data));
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
            // Restante do seu código permanece inalterado
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
                      MonthEvolution(item: _monthCalculate),
                      const SizedBox(height: defaultPadding),
                      RecentFiles(items: _foundUsers),
                    ],
                  ),
                ),
                if (!Responsive.isMobile(context))
                  const SizedBox(width: defaultPadding),
                if (!Responsive.isMobile(context))
                  Expanded(
                    flex: 2,
                    child: StarageDetails(item: _myBudgetDashboard,),
                  ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}