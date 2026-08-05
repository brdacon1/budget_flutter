import 'package:flutter/material.dart';
import 'package:expansion_tile_card/expansion_tile_card.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:oflite/common/constants/constants.dart';
import 'package:oflite/presentations/budget/budget_creator/budget_creator_view_model.dart';
import 'budget_creator_field.dart';

class BudgetCreatorAddressSection extends StatelessWidget {
  const BudgetCreatorAddressSection({super.key, required this.viewModel});

  final BudgetCreatorViewModel viewModel;

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
              child: Icon(Icons.location_on_outlined, color: whiteColor)),
          title: Text(
            "Endereço do cliente",
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
              field: Gender.cep,
              viewModel: viewModel,
              hintText: 'CEP',
              prefixIcon: Icons.add_location_outlined,
              controller: viewModel.cepController,
              focusNode: viewModel.cepNode,
              keyboardType: TextInputType.number,
              inputFormatters: [viewModel.maskCep],
              onChanged: viewModel.onCepChanged,
              onTap: () {
                viewModel.cepNode.requestFocus();
                viewModel.selectField(Gender.cep);
              },
            ),
            SizedBox(height: he * 0.02),
            BudgetCreatorField(
              field: Gender.rua,
              viewModel: viewModel,
              hintText: 'Rua',
              prefixIcon: Icons.location_on_outlined,
              controller: viewModel.ruaController,
              focusNode: viewModel.ruaNode,
              onTap: () {
                viewModel.ruaNode.requestFocus();
                viewModel.selectField(Gender.rua);
              },
            ),
            SizedBox(height: he * 0.02),
            BudgetCreatorField(
              field: Gender.city,
              viewModel: viewModel,
              hintText: 'Cidade',
              prefixIcon: Icons.location_city_outlined,
              controller: viewModel.cityController,
              focusNode: viewModel.cityNode,
              onTap: () {
                viewModel.cityNode.requestFocus();
                viewModel.selectField(Gender.city);
              },
            ),
            SizedBox(height: he * 0.02),
            BudgetCreatorField(
              field: Gender.bairro,
              viewModel: viewModel,
              hintText: 'Bairro',
              prefixIcon: Icons.location_searching,
              controller: viewModel.bairroController,
              focusNode: viewModel.bairroNode,
              onTap: () {
                viewModel.selectField(Gender.bairro);
                viewModel.bairroNode.requestFocus();
              },
            ),
            SizedBox(height: he * 0.02),
          ],
        ),
      ),
    );
  }
}
