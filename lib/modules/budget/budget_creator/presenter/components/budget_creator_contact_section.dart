import 'package:flutter/material.dart';
import 'package:expansion_tile_card/expansion_tile_card.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:oflite/shared/common/constants/constants.dart';
import 'package:oflite/modules/budget/budget_creator/presenter/budget_creator_view_model.dart';
import 'budget_creator_field.dart';

class BudgetCreatorContactSection extends StatelessWidget {
  const BudgetCreatorContactSection({
    super.key,
    required this.viewModel,
    required this.onPickContact,
  });

  final BudgetCreatorViewModel viewModel;
  final Future<void> Function() onPickContact;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 20),
      child: Theme(
        data: Theme.of(context).copyWith(unselectedWidgetColor: whiteColor),
        child: ExpansionTileCard(
          initiallyExpanded: true,
          expandedTextColor: whiteColor,
          baseColor: secondaryColor,
          expandedColor: secondaryColor,
          leading: const CircleAvatar(
              backgroundColor: bgColor,
              child: Icon(Icons.person_outlined, color: whiteColor)),
          title: Text(
            "Contato do cliente",
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
            BudgetCreatorField(
              field: Gender.fullname,
              viewModel: viewModel,
              hintText: 'Nome do cliente',
              prefixIcon: Icons.person_outlined,
              controller: viewModel.nameController,
              focusNode: viewModel.nameNode,
              readOnly: viewModel.fieldFone,
              onTap: onPickContact,
            ),
            SizedBox(height: MediaQuery.of(context).size.height * 0.02),
            BudgetCreatorField(
              field: Gender.phone,
              viewModel: viewModel,
              hintText: 'Telefone',
              prefixIcon: Icons.phone_android_outlined,
              controller: viewModel.phoneController,
              focusNode: viewModel.phoneNode,
              keyboardType: TextInputType.number,
              inputFormatters: [viewModel.maskFormatter],
              onTap: () {
                viewModel.phoneNode.requestFocus();
                viewModel.selectField(Gender.phone);
              },
            ),
            SizedBox(height: MediaQuery.of(context).size.height * 0.02),
          ],
        ),
      ),
    );
  }
}
