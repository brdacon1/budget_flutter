import 'package:material_ui/material_ui.dart';
import 'package:oflite/modules/comment_library/data/model/comment_library_model.dart';
import 'package:oflite/shared/common/constants/colors.dart';

/// Card de comentário: nome (negrito) + 2 linhas do texto + check circular
/// de remoção. Mesmo visual do card da lista de preço.
class CommentLibraryCard extends StatelessWidget {
  const CommentLibraryCard({
    super.key,
    required this.comment,
    required this.selected,
    required this.onTap,
    required this.onToggleSelect,
  });

  final CommentLibraryModel comment;
  final bool selected;
  final VoidCallback onTap;
  final VoidCallback onToggleSelect;

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.symmetric(vertical: 6.0),
      decoration: BoxDecoration(
        color: selected ? buttonColor.withValues(alpha: 0.08) : secondaryColor,
        borderRadius: BorderRadius.circular(16.0),
        border: Border.all(
          color: selected ? buttonColor : priceCardBorderColor,
          width: 1.2,
        ),
      ),
      child: Material(
        color: transparentColor,
        borderRadius: BorderRadius.circular(16.0),
        child: InkWell(
          borderRadius: BorderRadius.circular(16.0),
          onTap: onTap,
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        comment.name,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          color: whiteColor,
                          fontSize: 15.0,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        comment.text,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          color: priceTextColor,
                          fontSize: 13.0,
                        ),
                      ),
                    ],
                  ),
                ),
                InkResponse(
                  onTap: onToggleSelect,
                  radius: 24,
                  child: Padding(
                    padding: const EdgeInsets.all(11),
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 150),
                      width: 26,
                      height: 26,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: selected ? buttonColor : transparentColor,
                        border: Border.all(
                          color: selected ? buttonColor : priceTextColor,
                          width: 2.2,
                        ),
                      ),
                      child:
                          selected
                              ? const Icon(Icons.check, size: 16, color: bgColor)
                              : null,
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
