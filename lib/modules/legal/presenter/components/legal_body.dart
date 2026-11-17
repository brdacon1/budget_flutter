import 'package:material_ui/material_ui.dart';

/// Parágrafo de texto de um documento legal.
class LegalBody extends StatelessWidget {
  final String text;

  const LegalBody(this.text, {super.key});

  @override
  Widget build(BuildContext context) {
    return Text(
      text,
      style: const TextStyle(color: Colors.white70, fontSize: 15, height: 1.6),
    );
  }
}
