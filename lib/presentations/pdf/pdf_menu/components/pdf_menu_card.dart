import 'package:flutter/material.dart';
import 'package:oflite/presentations/pdf/pdf_menu/pdf_menu_view_model.dart';
import '../../../../common/constants/constants.dart';

/// Item de opção do menu da tela [PdfMenuView].
///
/// Componente **Stateless** puro — recebe o item e um callback de tap.
/// Não acessa services nem conhece o ViewModel.
class PdfMenuCard extends StatelessWidget {
  final MenuItem item;
  final VoidCallback onTap;

  const PdfMenuCard({super.key, required this.item, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4, horizontal: 15),
      child: GestureDetector(
        onTap: onTap,
        child: Container(
          decoration: BoxDecoration(
            color: bgColor,
            borderRadius: BorderRadius.circular(10),
            border: Border.all(color: secondaryColor, width: 2),
          ),
          child: ListTile(
            leading: Icon(item.icon),
            title: Text(
              item.title,
              style: const TextStyle(color: Colors.white, fontSize: 14),
            ),
            trailing: const Icon(Icons.arrow_right),
          ),
        ),
      ),
    );
  }
}
