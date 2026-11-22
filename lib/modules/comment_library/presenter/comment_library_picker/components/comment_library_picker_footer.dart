import 'package:material_ui/material_ui.dart';
import 'package:oflite/modules/comment_library/presenter/strings/comment_library_pt_string.dart';
import 'package:oflite/shared/common/constants/colors.dart';

/// Rodapé do modal-lista (= picker de preço, sem total em R$):
/// "n comentários" + "Adicionar".
class CommentLibraryPickerFooter extends StatelessWidget {
  const CommentLibraryPickerFooter({
    super.key,
    required this.count,
    required this.loading,
    required this.onAddAll,
  });

  final int count;
  final bool loading;
  final VoidCallback onAddAll;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: cartBarColor,
      elevation: 10,
      child: SafeArea(
        top: false,
        child: SizedBox(
          height: 80,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Row(
              children: [
                const Icon(
                  Icons.chat_bubble_outline,
                  color: cartAccentColor,
                  size: 30,
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        CommentLibraryStrings.pickerSelectedLabel,
                        style: const TextStyle(
                          color: Colors.white70,
                          fontSize: 13,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        CommentLibraryStrings.pickerCount(count),
                        style: const TextStyle(
                          color: whiteColor,
                          fontWeight: FontWeight.bold,
                          fontSize: 20,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 12),
                ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: buttonColor,
                    foregroundColor: blackColor,
                    disabledBackgroundColor: buttonColor.withValues(alpha: 0.6),
                    padding: const EdgeInsets.symmetric(
                      horizontal: 24,
                      vertical: 14,
                    ),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(24),
                    ),
                  ),
                  onPressed: loading ? null : onAddAll,
                  child: Text(
                    loading
                        ? CommentLibraryStrings.pickerAdding
                        : CommentLibraryStrings.pickerAdd,
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
