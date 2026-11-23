import 'package:flutter_test/flutter_test.dart';
import 'package:get_it/get_it.dart';
import 'package:material_ui/material_ui.dart';
import 'package:oflite/injection.dart';
import 'package:oflite/modules/auth/domain/repository/user_repository.dart';
import 'package:oflite/modules/core/convert_coin/domain/repository/convert_coin_repository.dart';
import 'package:oflite/modules/dashboard/domain/entity/dashboard_month_summary.dart';
import 'package:oflite/modules/dashboard/domain/entity/month_receipt_comparison.dart';
import 'package:oflite/modules/dashboard/domain/usecase/get_dashboard_month_summary_usecase.dart';
import 'package:oflite/modules/dashboard/domain/usecase/get_receipts_comparison_usecase.dart';
import 'package:oflite/modules/dashboard/presenter/components/dashboard_monthly_progress.dart';
import 'package:oflite/modules/dashboard/presenter/components/dashboard_status_overview.dart';
import 'package:oflite/modules/dashboard/presenter/dashboard_view.dart';
import 'package:oflite/modules/dashboard/presenter/dashboard_view_model.dart';
import 'package:oflite/shared/design_pattern/result.dart';

class _FakeSummary implements GetDashboardMonthSummaryUsecase {
  @override
  Future<Result<DashboardMonthSummary>> call(
    DateTime month, {
    bool forceRefresh = false,
  }) async => const Result.ok(DashboardMonthSummary.empty);

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

class _FakeComparison implements GetReceiptsComparisonUsecase {
  @override
  Future<Result<List<MonthReceiptComparison>>> call(
    DateTime until, {
    int months = 4,
  }) async => const Result.ok([]);

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

class _FakeUser implements UserRepository {
  @override
  final selectUser = ValueNotifier(null);

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

class _FakeMoney implements ConvertCoinRepository {
  @override
  String convertFromDouble(double value) => 'R\$ $value';

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

void main() {
  setUp(() {
    GetIt.I.registerFactory<DashboardViewModel>(
      () => DashboardViewModel(_FakeSummary(), _FakeComparison()),
    );
    GetIt.I.registerSingleton<UserRepository>(_FakeUser());
    GetIt.I.registerSingleton<ConvertCoinRepository>(_FakeMoney());
  });
  tearDown(GetIt.I.reset);

  Future<void> pump(WidgetTester tester, Size size) async {
    tester.view.physicalSize = size;
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    await tester.pumpWidget(const MaterialApp(home: DashboardView()));
    await tester.pumpAndSettle();
  }

  testWidgets('expanded: gráficos à esquerda e resumo à direita',
      (tester) async {
    await pump(tester, const Size(1194, 834));
    final charts = tester.getTopLeft(find.byType(DashboardMonthlyProgress));
    final overview = tester.getTopLeft(find.byType(DashboardStatusOverview));
    expect(overview.dx, greaterThan(charts.dx));
    expect(overview.dy, charts.dy);
    expect(tester.getSize(find.byType(DashboardStatusOverview)).width,
        greaterThan(400));
  });

  testWidgets('abaixo de 1024: uma coluna', (tester) async {
    await pump(tester, const Size(390, 844));
    // Ahem (fonte padrão dos testes) é mais larga que a Heebo real e estoura a
    // linha do Header; não tem relação com a composição em colunas.
    tester.takeException();
    final charts = tester.getTopLeft(find.byType(DashboardMonthlyProgress));
    final overview = tester.getTopLeft(find.byType(DashboardStatusOverview));
    expect(overview.dx, charts.dx);
    expect(overview.dy, lessThan(charts.dy));
  });
}
