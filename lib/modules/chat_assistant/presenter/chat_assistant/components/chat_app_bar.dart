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
      centerTitle: true,
      title: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 36,
            height: 36,
            decoration: const BoxDecoration(
              color: chatBotAvatarColor,
              shape: BoxShape.circle,
            ),
            child: const Icon(Icons.support_agent, size: 20, color: whiteColor),
          ),
          const SizedBox(width: 10),
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
