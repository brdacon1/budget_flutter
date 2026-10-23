import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:oflite/shared/common/constants/constants.dart';
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
      // O header que oculta a lista deve ocupar a largura toda da tela
      // (sem recuo lateral). Padding de 2 só para não encostar na borda do
      // canvas — solicitado na spec do Web.
      padding: const EdgeInsets.symmetric(horizontal: 2.0, vertical: 10),
      child: Theme(
        data: Theme.of(context).copyWith(unselectedWidgetColor: whiteColor),
        child: ExpansionTileCard(
          initiallyExpanded: true,
          // Sombra para separar visualmente cada bloco de "Meus dados"
          // (Contato / Informações / Endereço), mesmo quando recolhido.
          initialElevation: 2,
          elevation: 4,
          shadowColor: Colors.black54,
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
          // Cada informação (linha) é separada por um divisor sutil, para
          // que cada "divisão de informação" fique visualmente delimitada —
          // antes as linhas se misturavam sem sombra/divisão.
          children: _withDividers(
              rows.map((row) => _ReadOnlyRow(label: row.label, value: row.value)).toList()),
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

/// Intercala um [Divider] entre cada linha, sem colocar no final.
List<Widget> _withDividers(List<Widget> rows) {
  if (rows.length <= 1) return rows;
  final out = <Widget>[];
  for (var i = 0; i < rows.length; i++) {
    out.add(rows[i]);
    if (i < rows.length - 1) {
      out.add(const Divider(
        height: 1,
        thickness: 0.5,
        indent: 20,
        endIndent: 20,
        color: Color(0x33FFFFFF),
      ));
    }
  }
  return out;
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
