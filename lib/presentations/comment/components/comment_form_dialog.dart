import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:oflite/common/constants/constants.dart';
import 'package:oflite/models/observation_budget.dart';
import '../../../Services/display_alert.dart';
import '../comment_list_view_model.dart';

enum CommentField { commentText }

/// Exibe o dialog de adicionar/editar comentário.
///
/// Retorna `true` quando o comentário foi salvo/atualizado com sucesso,
/// `false` em caso de falha e `null` quando o usuário fechou sem salvar.
Future<bool?> showCommentFormDialog({
  required BuildContext context,
  required CommentListViewModel viewModel,
  required ObservationBudget comment,
  required DisplayAlert displayAlert,
}) {
  final TextEditingController descricaoController = TextEditingController();
  descricaoController.text = comment.observacao ?? '';

  final bool isNew = comment.id == null || comment.id!.isEmpty;
  final String textButtonName = isNew ? "ADICIONAR" : "ATUALIZAR";

  final we = MediaQuery.of(context).size.width;
  final he = MediaQuery.of(context).size.height;

  const Color enabled = Color(0xFF827F8A);
  const Color enabledtxt = Colors.white;
  const Color deaible = Colors.grey;

  return showDialog<bool>(
    context: context,
    builder: (BuildContext context) {
      CommentField? selected;
      return StatefulBuilder(
        builder: (BuildContext context, StateSetter setState) {
          return AlertDialog(
            insetPadding: const EdgeInsets.all(19),
            backgroundColor: bgColor,
            content: SizedBox(
              height: he * 0.5,
              width: we,
              child: Column(
                children: <Widget>[
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    mainAxisSize: MainAxisSize.max,
                    children: <Widget>[
                      GestureDetector(
                        onTap: () {
                          Navigator.pop(context, false);
                        },
                        child: Container(
                          alignment: Alignment.topLeft,
                          margin: EdgeInsets.only(left: we * 0.0),
                          child: const Icon(
                            Icons.close,
                            color: Colors.white,
                            size: 30.0,
                          ),
                        ),
                      ),
                      Container(
                        margin: EdgeInsets.only(right: we * 0.25),
                        child: Text(
                          "Comentário",
                          style: GoogleFonts.heebo(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                            fontSize: 20,
                          ),
                        ),
                      ),
                    ],
                  ),
                  SizedBox(height: he * 0.02),
                  Container(
                    width: we * 0.80,
                    height: he * 0.35,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(color: secondaryColor, width: 2),
                      color:
                          selected == CommentField.commentText ? enabled : bgColor,
                    ),
                    padding: const EdgeInsets.all(8.0),
                    child: TextField(
                      controller: descricaoController,
                      keyboardType: TextInputType.multiline,
                      maxLines: 50,
                      onTap: () {
                        setState(() {
                          selected = CommentField.commentText;
                        });
                      },
                      decoration: InputDecoration(
                        enabledBorder: InputBorder.none,
                        border: InputBorder.none,
                        hintText: 'Escreva o comentário...',
                        hintStyle: TextStyle(
                          color: selected == CommentField.commentText
                              ? enabledtxt
                              : deaible,
                        ),
                      ),
                      style: TextStyle(
                        color: selected == CommentField.commentText
                            ? enabledtxt
                            : deaible,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  const Padding(padding: EdgeInsets.only(top: 16.5)),
                  Align(
                    alignment: Alignment.bottomCenter,
                    child: TextButton(
                      onPressed: () async {
                        bool success;
                        if (isNew) {
                          success = await viewModel.addComment(descricaoController.text);
                          if (success) {
                            await viewModel.loadComments();
                            if (context.mounted) {
                              await displayAlert.notification(
                                  context, "Feito!", "Cometário adicionado com sucesso!");
                            }
                          } else {
                            if (context.mounted) {
                              await displayAlert.notificationError(
                                  context, "Erro!", "Não foi possível adicionar o comentário");
                            }
                          }
                        } else {
                          comment.observacao = descricaoController.text;
                          success = await viewModel.updateComment(comment);
                          if (success) {
                            if (context.mounted) {
                              await displayAlert.notification(
                                  context, "Feito!", "Cometário atualizado com sucesso!");
                            }
                          } else {
                            if (context.mounted) {
                              await displayAlert.notificationError(
                                  context, "Erro!", "Não foi possível atualizar o comentário");
                            }
                          }
                        }
                        if (context.mounted) {
                          Navigator.pop(context, success);
                        }
                      },
                      style: TextButton.styleFrom(
                        backgroundColor: buttonColor,
                        padding: const EdgeInsets.symmetric(
                            vertical: 15.0, horizontal: 90),
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(30.0)),
                      ),
                      child: Text(
                        textButtonName,
                        style: GoogleFonts.heebo(
                          color: Colors.black,
                          letterSpacing: 0,
                          fontSize: 18.0,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      );
    },
  );
}
