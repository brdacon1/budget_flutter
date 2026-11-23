import 'package:material_ui/material_ui.dart';
import 'package:oflite/modules/budget/data/model/customer_info_model.dart';
import 'package:oflite/modules/pdf/presenter/pdf_menu/pdf_menu_view_model.dart';
import 'package:oflite/modules/pdf/presenter/strings/pdf_pt_string.dart';
import 'package:oflite/shared/common/constants/colors.dart';
import 'package:oflite/shared/common/widgets/header/app_header_second_title.dart';

import 'components/pdf_menu_card.dart';

class PdfMenuView extends StatefulWidget {
  final CustomerInfo item;
  final bool showCustomerBudgets;

  const PdfMenuView({
    super.key,
    required this.item,
    this.showCustomerBudgets = true,
  });

  @override
  State<PdfMenuView> createState() => _PdfMenuView();
}

class _PdfMenuView extends State<PdfMenuView> {
  late final PdfMenuViewModel _viewModel;

  @override
  void initState() {
    super.initState();
    _viewModel = PdfMenuViewModel(
      item: widget.item,
      showCustomerBudgets: widget.showCustomerBudgets,
    );
    WidgetsBinding.instance.addPostFrameCallback(
      (_) => _viewModel.inicialData(),
    );
  }

  @override
  void dispose() {
    _viewModel.dispose();
    super.dispose();
  }

  String _sectionTitle(PdfMenuSection section) {
    switch (section) {
      case PdfMenuSection.budget:
        return PdfStrings.sectionBudget;
      case PdfMenuSection.share:
        return PdfStrings.sectionShare;
      case PdfMenuSection.finance:
        return PdfStrings.sectionFinance;
    }
  }

  List<Widget> _buildSection(BuildContext context, PdfMenuSection section) {
    final items =
        _viewModel.menuItems.where((m) => m.section == section).toList();
    if (items.isEmpty) return const [];
    return [
      Padding(
        padding: const EdgeInsets.fromLTRB(20, 18, 20, 6),
        child: Text(
          _sectionTitle(section).toUpperCase(),
          style: const TextStyle(
            color: mutedTextColor,
            fontSize: 12,
            fontWeight: FontWeight.w700,
            letterSpacing: 1.2,
          ),
        ),
      ),
      for (final menuItem in items)
        PdfMenuCard(
          item: menuItem,
          onTap:
              () => _viewModel.openOption(
                context,
                _viewModel.menuItems.indexOf(menuItem),
              ),
        ),
    ];
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: bgColor,
      body: AnimatedBuilder(
        animation: _viewModel,
        builder: (context, _) {
          return Column(
            mainAxisAlignment: MainAxisAlignment.start,
            mainAxisSize: MainAxisSize.max,
            children: <Widget>[
              AppHeaderSecondTitle(
                titlePage: PdfStrings.optionsTitle,
                secondTitle: PdfStrings.optionsSubtitle,
                onBack: () => Navigator.pop(context, true),
                isBottomPadding: false,
              ),
              Expanded(
                child: ListView(
                  padding: const EdgeInsets.only(bottom: 24),
                  children: [
                    for (final section in PdfMenuSection.values)
                      ..._buildSection(context, section),
                  ],
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}
