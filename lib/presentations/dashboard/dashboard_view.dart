import 'package:flutter/material.dart';
import '../../common/constants/constants.dart';
import '../../common/widgets/responsive_widget.dart';
import 'components/header.dart';
import 'components/month_evolution.dart';
import 'components/recent_files.dart';
import 'components/storage_details.dart';
import 'dashboard_view_model.dart';

class DashboardView extends StatefulWidget {
  const DashboardView({Key? key}) : super(key: key);

  @override
  State<DashboardView> createState() => _DashboardView();
}

class _DashboardView extends State<DashboardView> {
  late DashboardViewModel _viewModel;

  @override
  void initState() {
    super.initState();
    _viewModel = DashboardViewModel();
    _viewModel.addListener(_onViewModelChanged);
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _viewModel.startDashboard();
  }

  @override
  void dispose() {
    _viewModel.removeListener(_onViewModelChanged);
    _viewModel.dispose();
    super.dispose();
  }

  void _onViewModelChanged() {
    setState(() {});
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
                      const SizedBox(height: defaultPadding),
                      if (ResponsiveWidget.isMobile(context))
                        const SizedBox(height: defaultPadding),
                      if (ResponsiveWidget.isMobile(context))
                        StarageDetails(item: _viewModel.myBudgetDashboard),
                      const SizedBox(height: defaultPadding),
                      MonthEvolution(item: _viewModel.monthCalculate),
                      const SizedBox(height: defaultPadding),
                      RecentFiles(items: _viewModel.foundUsers),
                    ],
                  ),
                ),
                if (!ResponsiveWidget.isMobile(context))
                  const SizedBox(width: defaultPadding),
                if (!ResponsiveWidget.isMobile(context))
                  Expanded(
                    flex: 2,
                    child: StarageDetails(
                      item: _viewModel.myBudgetDashboard,
                    ),
                  ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
