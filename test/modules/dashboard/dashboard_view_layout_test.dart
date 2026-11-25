import 'package:flutter_test/flutter_test.dart';
import 'package:get_it/get_it.dart';
import 'package:material_ui/material_ui.dart';
import 'package:oflite/modules/auth/domain/repository/user_repository.dart';
import 'package:oflite/modules/core/convert_coin/domain/repository/convert_coin_repository.dart';
import 'package:oflite/modules/dashboard/domain/entity/dashboard_month_summary.dart';
import 'package:oflite/modules/dashboard/domain/entity/month_receipt_comparison.dart';
import 'package:oflite/modules/dashboard/domain/usecase/get_dashboard_month_summary_usecase.dart';
import 'package:oflite/modules/dashboard/domain/usecase/get_receipts_comparison_usecase.dart';
import 'package:oflite/modules/dashboard/presenter/components/dashboard_month_filter.dart';
import 'package:oflite/modules/dashboard/presenter/components/dashboard_monthly_progress.dart';
import 'package:oflite/modules/dashboard/presenter/components/dashboard_receipts_comparison.dart';
import 'package:oflite/modules/dashboard/presenter/components/dashboard_sold_items.dart';
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

  testWidgets('expanded: resumo à esquerda e gráficos à direita', (
    tester,
  ) async {
    await pump(tester, const Size(1194, 834));
    final charts = tester.getTopLeft(find.byType(DashboardMonthlyProgress));
    final overview = tester.getTopLeft(find.byType(DashboardStatusOverview));
    expect(charts.dx, greaterThan(overview.dx));
    expect(overview.dy, charts.dy);
    expect(
      tester.getSize(find.byType(DashboardStatusOverview)).width,
      greaterThan(400),
    );
  });

  testWidgets('expanded: cards da mesma linha alinhados (topo e base)', (
    tester,
  ) async {
    await pump(tester, const Size(1194, 834));
    Rect r(Type t) => tester.getRect(find.byType(t));
    final progress = r(DashboardMonthlyProgress);
    final status = r(DashboardStatusOverview);
    final comparison = r(DashboardReceiptsComparison);
    final sold = r(DashboardSoldItems);
    expect(progress.top, status.top);
    expect(progress.bottom, status.bottom);
    expect(comparison.top, sold.top);
    expect(comparison.bottom, sold.bottom);
    expect(comparison.top, greaterThan(progress.bottom));
    expect(sold.left, status.left);
    expect(status.right, lessThan(progress.left));
  });

  testWidgets('expanded: filtro de mês na largura da coluna da esquerda', (
    tester,
  ) async {
    await pump(tester, const Size(1194, 834));
    final filter = tester.getRect(find.byType(DashboardMonthFilter));
    final status = tester.getRect(find.byType(DashboardStatusOverview));
    expect(filter.left, status.left);
    expect(filter.right, status.right);
    expect(filter.bottom, lessThan(status.top));
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
