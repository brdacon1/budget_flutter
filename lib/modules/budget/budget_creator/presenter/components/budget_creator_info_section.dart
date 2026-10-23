import 'package:flutter/material.dart';
import 'package:expansion_tile_card/expansion_tile_card.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:oflite/shared/common/constants/constants.dart';
import 'package:oflite/modules/budget/budget_creator/presenter/budget_creator_view_model.dart';
import 'budget_creator_field.dart';

class BudgetCreatorInfoSection extends StatelessWidget {
  const BudgetCreatorInfoSection({
    super.key,
    required this.viewModel,
    required this.onSelectStatus,
  });

  final BudgetCreatorViewModel viewModel;
  final Future<void> Function() onSelectStatus;

  @override
  Widget build(BuildContext context) {
    final he = MediaQuery.of(context).size.height;
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 20),
      child: Theme(
        data: Theme.of(context).copyWith(unselectedWidgetColor: whiteColor),
        child: ExpansionTileCard(
          expandedTextColor: whiteColor,
          baseColor: secondaryColor,
          expandedColor: secondaryColor,
          leading: const CircleAvatar(
              backgroundColor: bgColor,
              child: Icon(Icons.request_page_outlined, color: whiteColor)),
          title: Text(
            "Informações do orçamento",
            style: GoogleFonts.heebo(
                color: whiteColor,
                fontWeight: FontWeight.bold,
                fontSize: 14,
                letterSpacing: 1),
          ),
          subtitle: Text(
            viewModel.titleBox!,
            style: GoogleFonts.heebo(
                color: whiteColor,
                fontWeight: FontWeight.normal,
                fontSize: 13,
                letterSpacing: 1),
          ),
          children: <Widget>[
            SizedBox(height: he * 0.02),
            BudgetCreatorField(
              field: Gender.status,
              viewModel: viewModel,
              hintText: 'Status do orçamentos',
              prefixIcon: Icons.domain_verification_outlined,
              controller: viewModel.statusController,
              readOnly: true,
              enableInteractiveSelection: true,
              onTap: onSelectStatus,
              suffixIcon: Icon(
                Icons.keyboard_arrow_down_outlined,
                color: viewModel.selected == Gender.status
                    ? viewModel.enabledtxt
                    : viewModel.deaible,
              ),
            ),
            SizedBox(height: he * 0.02),
            Visibility(
              visible: viewModel.fieldVisible,
              child: BudgetCreatorField(
                field: Gender.data,
                viewModel: viewModel,
                hintText: 'Data do orçamento',
                prefixIcon: Icons.calendar_month_outlined,
                controller: viewModel.dataController,
                enabled: false,
                onTap: () => viewModel.selectField(Gender.data),
              ),
            ),
            SizedBox(height: he * 0.02),
            Visibility(
              visible: viewModel.fieldVisible,
              child: BudgetCreatorField(
                field: Gender.id,
                viewModel: viewModel,
                hintText: 'Número do orçamento',
                prefixIcon: Icons.confirmation_number_outlined,
                controller: viewModel.idController,
                enabled: false,
                onTap: () => viewModel.selectField(Gender.id),
              ),
            ),
            SizedBox(height: he * 0.02),
          ],
        ),
      ),
    );
  }
}
