import 'package:material_ui/material_ui.dart';
import 'package:oflite/shared/common/constants/colors.dart';

/// Botão flutuante que abre o Assistente (chat).
class HomeChatFab extends StatelessWidget {
  const HomeChatFab({super.key, required this.icon, required this.onTap});

  final IconData icon;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return FloatingActionButton(
      heroTag: 'home_chat',
      onPressed: onTap,
      backgroundColor: buttonColor,
      foregroundColor: blackColor,
      child: Icon(icon),
    );
  }
}
