import 'package:expansion_tile_card/expansion_tile_card.dart';
import 'package:flutter/material.dart';
import 'package:oflite/shared/common/constants/constants.dart';
import 'package:oflite/shared/models/observation_budget.dart';
import 'package:oflite/modules/comment/presenter/strings/comment_pt_string.dart';

/// Item da lista de comentários, exibido em um [ExpansionTileCard].
class CommentListItem extends StatelessWidget {
  const CommentListItem({
    Key? key,
    required this.comment,
    required this.onDelete,
    required this.onEdit,
  }) : super(key: key);

  final ObservationBudget comment;
  final Future<void> Function(ObservationBudget comment) onDelete;
  final Future<void> Function(ObservationBudget comment) onEdit;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 5),
      child: Theme(
        data: Theme.of(context).copyWith(unselectedWidgetColor: whiteColor),
        child: ExpansionTileCard(
          expandedTextColor: whiteColor,
          baseColor: secondaryColor,
          expandedColor: secondaryColor,
          leading: const CircleAvatar(
            backgroundColor: bgColor,
            child: Icon(Icons.comment, color: whiteColor),
          ),
          title: Text(
            "${comment.observacao}",
            maxLines: 2,
            style: const TextStyle(
              color: whiteColor,
              letterSpacing: 0.5,
              fontSize: 12.0,
              fontWeight: FontWeight.bold,
            ),
          ),
          subtitle: Text(
            "Data: ${comment.data}",
            style: const TextStyle(
              color: whiteColor,
              letterSpacing: 0.5,
              fontSize: 12.0,
            ),
          ),
          children: <Widget>[
            const Divider(
              thickness: 1.0,
              height: 1.0,
            ),
            Align(
              alignment: Alignment.centerLeft,
              child: Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: 20.0,
                  vertical: 5.0,
                ),
                child: Text(
                  "Comentário: ${comment.observacao}",
                  style: const TextStyle(
                    color: whiteColor,
                    letterSpacing: 0.5,
                    fontSize: 12.0,
                  ),
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.only(bottom: 5, top: 10),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: <Widget>[
                  _ActionButton(
                    icon: Icons.delete_outline_rounded,
                    label: CommentStrings.deleteLabel,
                    onTap: () => onDelete(comment),
                  ),
                  _ActionButton(
                    icon: Icons.edit,
                    label: CommentStrings.editLabel,
                    onTap: () => onEdit(comment),
                  ),
                ],
              ),
            )
          ],
        ),
      ),
    );
  }
}

class _ActionButton extends StatelessWidget {
  const _ActionButton({
    required this.icon,
    required this.label,
    required this.onTap,
  });

  final IconData icon;
  final String label;
  final Future<void> Function() onTap;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 85.0,
      height: 52.0,
      child: ElevatedButton(
        style: ElevatedButton.styleFrom(
          backgroundColor: whiteColor,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(5.0),
          ),
        ),
        onPressed: onTap,
        child: Column(
          children: <Widget>[
            const SizedBox(height: 4),
            Icon(icon, color: bgColor),
            const SizedBox(height: 2.0),
            Text(label, style: const TextStyle(fontSize: 8.5, color: bgColor)),
          ],
        ),
      ),
    );
  }
}
