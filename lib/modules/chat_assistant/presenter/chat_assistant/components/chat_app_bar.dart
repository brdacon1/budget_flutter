import 'package:material_ui/material_ui.dart';
import 'package:oflite/modules/chat_assistant/presenter/chat_assistant/strings/chat_assistant_pt_string.dart';
import 'package:oflite/shared/common/constants/colors.dart';

/// App bar do chat: avatar + "Assistente / online" + reiniciar conversa.
class ChatAppBar extends StatelessWidget implements PreferredSizeWidget {
  final VoidCallback onRestart;

  const ChatAppBar({super.key, required this.onRestart});

  @override
  Size get preferredSize => const Size.fromHeight(kToolbarHeight);

  @override
  Widget build(BuildContext context) {
    return AppBar(
      backgroundColor: chatBarColor,
      elevation: 0,
      scrolledUnderElevation: 0,
      shape: const Border(bottom: BorderSide(color: chatDividerColor)),
      centerTitle: true,
      title: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Stack(
            clipBehavior: Clip.none,
            children: [
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [Color(0xFF00E5FF), Color(0xFF00BFA5)],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  shape: BoxShape.circle,
                  boxShadow: [
                    BoxShadow(
                      color: chatHighlightColor.withValues(alpha: 0.35),
                      blurRadius: 10,
                    ),
                  ],
                ),
                child: const Icon(
                  Icons.support_agent,
                  size: 22,
                  color: whiteColor,
                ),
              ),
              Positioned(
                right: -1,
                bottom: -1,
                child: Container(
                  width: 12,
                  height: 12,
                  decoration: BoxDecoration(
                    color: chatOnlineColor,
                    shape: BoxShape.circle,
                    border: Border.all(color: chatBarColor, width: 2),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(width: 12),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                ChatAssistantStrings.assistantTitle,
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
              Text(
                ChatAssistantStrings.online,
                style: const TextStyle(fontSize: 12, color: chatOnlineColor),
              ),
            ],
          ),
        ],
      ),
      actions: [
        IconButton(
          icon: const Icon(Icons.refresh),
          tooltip: ChatAssistantStrings.restartConversation,
          onPressed: onRestart,
        ),
      ],
    );
  }
}
