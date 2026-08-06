import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import 'package:oflite/models/customer_info.dart';
import 'package:oflite/models/global_uid_user.dart' as UID;
import 'package:oflite/models/month_calculate.dart';
import 'package:oflite/models/my_budget_dashboard.dart';
import 'package:permission_handler/permission_handler.dart';

class DashboardViewModel extends ChangeNotifier {
  final List<CustomerInfo> _foundUsers = <CustomerInfo>[];
  List<CustomerInfo> get foundUsers => _foundUsers;

  MyBudgetDashboard _myBudgetDashboard = MyBudgetDashboard(
    qtdTotal: 0,
    qtdIntApproved: 0,
    qtdIntPending: 0,
    qtdIntFinish: 0,
    qtdIntDisapproved: 0,
    qtdDoubleApproved: 0,
    qtdDoublePending: 0,
    qtdDoubleFinish: 0,
    qtdDoubleDisapproved: 0,
  );
  MyBudgetDashboard get myBudgetDashboard => _myBudgetDashboard;

  MonthCalculate _monthCalculate = MonthCalculate(
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
  MonthCalculate get monthCalculate => _monthCalculate;

  bool _loading = false;
  bool get isLoading => _loading;

  /// Calcula a semana do mês (1 a ~4.5) a partir de um timestamp.
  double getWeekOfMonthFromMilliseconds(int millisecondsSinceEpoch) {
    DateTime dateTime =
        DateTime.fromMillisecondsSinceEpoch(millisecondsSinceEpoch);
    int day = dateTime.day;
    double week = day / 7;
    return week;
  }

  /// Inicializa o dashboard: pede permissão de storage, busca os orçamentos
  /// do mês corrente e recalcula os totais/quantidades por status e semana.
  Future<void> startDashboard() async {
    _loading = true;
    notifyListeners();

    try {
      await Permission.storage.request();
      final value = await getInformationBudget();

      // Reinicia os acumuladores antes de recalcular.
      _myBudgetDashboard = MyBudgetDashboard(
        qtdTotal: value.length,
        qtdIntApproved: 0,
        qtdIntPending: 0,
        qtdIntFinish: 0,
        qtdIntDisapproved: 0,
        qtdDoubleApproved: 0,
        qtdDoublePending: 0,
        qtdDoubleFinish: 0,
        qtdDoubleDisapproved: 0,
      );
      _monthCalculate = MonthCalculate(
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

      for (int i = 0; i < value.length; i++) {
        final item = value[i];
        double weekNumber = 0;

        if (item.status == "APROVADO") {
          _myBudgetDashboard.qtdIntApproved =
              _myBudgetDashboard.qtdIntApproved! + 1;
          _myBudgetDashboard.qtdDoubleApproved =
              _myBudgetDashboard.qtdDoubleApproved! + 1;
          weekNumber = getWeekOfMonthFromMilliseconds(int.parse(item.id!));
          _accumulateByWeek(
            weekNumber,
            item.totalValue! / 1000,
            (v) => _monthCalculate.totalApprovedMonth_0 =
                v + _monthCalculate.totalApprovedMonth_0!,
            (v) => _monthCalculate.totalApprovedMonth_1 =
                v + _monthCalculate.totalApprovedMonth_1!,
            (v) => _monthCalculate.totalApprovedMonth_2 =
                v + _monthCalculate.totalApprovedMonth_2!,
            (v) => _monthCalculate.totalApprovedMonth_3 =
                v + _monthCalculate.totalApprovedMonth_3!,
          );
        } else if (item.status == "PENDENTE") {
          _myBudgetDashboard.qtdIntPending =
              _myBudgetDashboard.qtdIntPending! + 1;
          _myBudgetDashboard.qtdDoublePending =
              _myBudgetDashboard.qtdDoublePending! + 1;
          weekNumber = getWeekOfMonthFromMilliseconds(int.parse(item.id!));
          _accumulateByWeek(
            weekNumber,
            item.totalValue! / 1000,
            (v) => _monthCalculate.totalPendingMonth_0 =
                v + _monthCalculate.totalPendingMonth_0!,
            (v) => _monthCalculate.totalPendingMonth_1 =
                v + _monthCalculate.totalPendingMonth_1!,
            (v) => _monthCalculate.totalPendingMonth_2 =
                v + _monthCalculate.totalPendingMonth_2!,
            (v) => _monthCalculate.totalPendingMonth_3 =
                v + _monthCalculate.totalPendingMonth_3!,
          );
        } else if (item.status == "REPROVADO") {
          _myBudgetDashboard.qtdIntDisapproved =
              _myBudgetDashboard.qtdIntDisapproved! + 1;
          _myBudgetDashboard.qtdDoubleDisapproved =
              _myBudgetDashboard.qtdDoubleDisapproved! + 1;
          weekNumber = getWeekOfMonthFromMilliseconds(int.parse(item.id!));
          _accumulateByWeek(
            weekNumber,
            item.totalValue! / 1000,
            (v) => _monthCalculate.totalReprovedMonth_0 =
                v + _monthCalculate.totalReprovedMonth_0!,
            (v) => _monthCalculate.totalReprovedMonth_1 =
                v + _monthCalculate.totalReprovedMonth_1!,
            (v) => _monthCalculate.totalReprovedMonth_2 =
                v + _monthCalculate.totalReprovedMonth_2!,
            (v) => _monthCalculate.totalReprovedMonth_3 =
                v + _monthCalculate.totalReprovedMonth_3!,
          );
        } else if (item.status == "FINALIZADO") {
          _myBudgetDashboard.qtdIntFinish =
              _myBudgetDashboard.qtdIntFinish! + 1;
          _myBudgetDashboard.qtdDoubleFinish =
              _myBudgetDashboard.qtdDoubleFinish! + 1;
          weekNumber = getWeekOfMonthFromMilliseconds(int.parse(item.id!));
          _accumulateByWeek(
            weekNumber,
            item.totalValue! / 1000,
            (v) => _monthCalculate.totalFinishMonth_0 =
                v + _monthCalculate.totalFinishMonth_0!,
            (v) => _monthCalculate.totalFinishMonth_1 =
                v + _monthCalculate.totalFinishMonth_1!,
            (v) => _monthCalculate.totalFinishMonth_2 =
                v + _monthCalculate.totalFinishMonth_2!,
            (v) => _monthCalculate.totalFinishMonth_3 =
                v + _monthCalculate.totalFinishMonth_3!,
          );
        }
      }
    } catch (e) {
      print(e);
    }

    _loading = false;
    notifyListeners();
  }

  /// Distribui o valor [value] para o acumulador da semana correspondente.
  void _accumulateByWeek(
    double weekNumber,
    double value,
    void Function(double) week0,
    void Function(double) week1,
    void Function(double) week2,
    void Function(double) week3,
  ) {
    if (weekNumber <= 1) {
      week0(value);
    } else if (weekNumber <= 2) {
      week1(value);
    } else if (weekNumber <= 3) {
      week2(value);
    } else if (weekNumber <= 4.5) {
      week3(value);
    }
  }

  /// Busca no Firestore os orçamentos do mês corrente.
  Future<List<CustomerInfo>> getInformationBudget() async {
    _foundUsers.clear();
    DateTime currentDate = DateTime.now();
    DateTime firstDayOfCurrentMonth =
        DateTime(currentDate.year, currentDate.month, 1);
    DateTime lastDayOfCurrentMonth =
        DateTime(currentDate.year, currentDate.month + 1, 0);

    int firstDayMillis = firstDayOfCurrentMonth.millisecondsSinceEpoch;
    int lastDayMillis = lastDayOfCurrentMonth.millisecondsSinceEpoch;

    final querySnapshot = await FirebaseFirestore.instance
        .collection("EMPRESAS/${UID.user}/USERS/${UID.user}/ORCAMENTOS")
        .where('ID', isGreaterThanOrEqualTo: firstDayMillis.toString())
        .where('ID', isLessThanOrEqualTo: lastDayMillis.toString())
        .orderBy('ID', descending: false)
        .get();

    for (var questionTmp in querySnapshot.docs) {
      final data = questionTmp.data();
      _foundUsers.add(CustomerInfo.fromMap(data));
    }

    return _foundUsers;
  }
}
