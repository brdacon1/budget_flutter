import 'package:material_ui/material_ui.dart';
import 'package:oflite/shared/common/constants/colors.dart';

/// Bolha do bot com três pontinhos animados — "digitando…" enquanto a IA
/// pensa ou executa uma ação. Mesmo formato/cor da bolha do bot.
class ChatTypingIndicator extends StatefulWidget {
  const ChatTypingIndicator({super.key});

  @override
  State<ChatTypingIndicator> createState() => _ChatTypingIndicatorState();
}

class _ChatTypingIndicatorState extends State<ChatTypingIndicator>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 1200),
  )..repeat();

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.symmetric(vertical: 4, horizontal: 12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          Container(
            width: 32,
            height: 32,
            decoration: const BoxDecoration(
              color: chatBotAvatarColor,
              shape: BoxShape.circle,
            ),
            child: const Icon(Icons.support_agent, size: 18, color: whiteColor),
          ),
          const SizedBox(width: 6),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
            decoration: const BoxDecoration(
              color: secondaryColor,
              borderRadius: BorderRadius.only(
                topLeft: Radius.circular(16),
                topRight: Radius.circular(16),
                bottomLeft: Radius.circular(4),
                bottomRight: Radius.circular(16),
              ),
            ),
            child: AnimatedBuilder(
              animation: _controller,
              builder:
                  (context, _) => Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [for (var i = 0; i < 3; i++) _dot(i)],
                  ),
            ),
          ),
        ],
      ),
    );
  }

  /// Cada ponto sobe e clareia com um atraso em relação ao anterior.
  Widget _dot(int index) {
    final t = (_controller.value - index * 0.2) % 1.0;
    final wave = t < 0.5 ? t * 2 : (1 - t) * 2; // 0 → 1 → 0
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 2.5),
      child: Transform.translate(
        offset: Offset(0, -3 * wave),
        child: Opacity(
          opacity: 0.4 + 0.6 * wave,
          child: Container(
            width: 7,
            height: 7,
            decoration: const BoxDecoration(
              color: mutedTextColor,
              shape: BoxShape.circle,
            ),
          ),
        ),
      ),
    );
  }
}
