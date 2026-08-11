import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:oflite/common/constants/constants.dart';
import 'package:expansion_tile_card/expansion_tile_card.dart';

/// Seção expansível read-only de "Meus dados", reutilizando o visual do
/// app mobile (`ExpansionTileCard`, labels idênticas). Não tem campos
/// editáveis — apenas exibição.
class BudgetWebDataSection extends StatelessWidget {
  const BudgetWebDataSection({
    super.key,
    required this.title,
    required this.icon,
    required this.rows,
  });

  final String title;
  final IconData icon;
  final List<BudgetWebDataRow> rows;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 12),
      child: Theme(
        data: Theme.of(context).copyWith(unselectedWidgetColor: whiteColor),
        child: ExpansionTileCard(
          initiallyExpanded: true,
          expandedTextColor: whiteColor,
          baseColor: secondaryColor,
          expandedColor: secondaryColor,
          leading: CircleAvatar(
            backgroundColor: bgColor,
            child: Icon(icon, color: whiteColor),
          ),
          title: Text(
            title,
            style: GoogleFonts.heebo(
              color: whiteColor,
              fontWeight: FontWeight.bold,
              fontSize: 14,
              letterSpacing: 1,
            ),
          ),
          children: rows
              .map((row) => _ReadOnlyRow(label: row.label, value: row.value))
              .toList(),
        ),
      ),
    );
  }
}

class BudgetWebDataRow {
  const BudgetWebDataRow(this.label, this.value);
  final String label;
  final String value;
}

class _ReadOnlyRow extends StatelessWidget {
  const _ReadOnlyRow({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    final he = MediaQuery.of(context).size.height;
    return Padding(
      padding: EdgeInsets.symmetric(horizontal: 20, vertical: he * 0.01),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            flex: 4,
            child: Text(
              label,
              style: GoogleFonts.heebo(
                color: Colors.white70,
                fontSize: 13,
                letterSpacing: 0.5,
              ),
            ),
          ),
          Expanded(
            flex: 6,
            child: Text(
              value,
              style: GoogleFonts.heebo(
                color: whiteColor,
                fontSize: 13,
                fontWeight: FontWeight.bold,
                letterSpacing: 0.5,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
