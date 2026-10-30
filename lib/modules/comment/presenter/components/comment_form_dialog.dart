import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:oflite/shared/common/widgets/modals/app_bottom_modal_widget.dart';
import 'package:oflite/shared/models/observation_budget.dart';
import 'package:oflite/modules/core/display_alert/domain/repository/display_alert_repository.dart';
import '../comment_list_view_model.dart';

/// Exibe o bottom modal de adicionar/editar comentário.
///
/// Retorna `true` quando o comentário foi salvo/atualizado com sucesso,
/// `false` em caso de falha e `null` quando o usuário fechou sem salvar.
/// Fundo branco, campo multilinha no padrão do projeto (cinza máximo) e
/// botão no padrão dos botões. Acompanha o teclado.
Future<bool?> showCommentFormDialog({
  required BuildContext context,
  required CommentListViewModel viewModel,
  required ObservationBudget comment,
  required DisplayAlertRepository displayAlert,
}) {
  final TextEditingController descricaoController = TextEditingController();
  descricaoController.text = comment.observacao ?? '';

  final bool isNew = comment.id == null || comment.id!.isEmpty;
  final String textButtonName = isNew ? 'ADICIONAR' : 'ATUALIZAR';

  return showModalBottomSheet<bool>(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    builder: (context) => _CommentFormModal(
      descricaoController: descricaoController,
      buttonLabel: textButtonName,
      isNew: isNew,
      comment: comment,
      viewModel: viewModel,
      displayAlert: displayAlert,
    ),
  );
}

class _CommentFormModal extends StatefulWidget {
  const _CommentFormModal({
    required this.descricaoController,
    required this.buttonLabel,
    required this.isNew,
    required this.comment,
    required this.viewModel,
    required this.displayAlert,
  });

  final TextEditingController descricaoController;
  final String buttonLabel;
  final bool isNew;
  final ObservationBudget comment;
  final CommentListViewModel viewModel;
  final DisplayAlertRepository displayAlert;

  @override
  State<_CommentFormModal> createState() => _CommentFormModalState();
}

class _CommentFormModalState extends State<_CommentFormModal> {
  bool _submitting = false;

  @override
  void dispose() {
    widget.descricaoController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (_submitting) return;
    setState(() => _submitting = true);
    bool success;
    if (widget.isNew) {
      success = await widget.viewModel.addComment(widget.descricaoController.text);
      if (success) {
        await widget.viewModel.loadComments();
        if (mounted) {
          await widget.displayAlert.notification(
              context, 'Feito!', 'Comentário adicionado com sucesso!');
        }
      } else {
        if (mounted) {
          await widget.displayAlert.notificationError(
              context, 'Erro!', 'Não foi possível adicionar o comentário');
        }
      }
    } else {
      widget.comment.observacao = widget.descricaoController.text;
      success = await widget.viewModel.updateComment(widget.comment);
      if (success) {
        if (mounted) {
          await widget.displayAlert.notification(
              context, 'Feito!', 'Comentário atualizado com sucesso!');
        }
      } else {
        if (mounted) {
          await widget.displayAlert.notificationError(
              context, 'Erro!', 'Não foi possível atualizar o comentário');
        }
      }
    }
    if (mounted) {
      Navigator.pop(context, success);
    }
  }

  @override
  Widget build(BuildContext context) {
    return AppBottomModal(
      title: 'Comentário',
      buttonLabel: _submitting ? 'Salvando...' : widget.buttonLabel,
      onButtonPressed: _submitting ? () {} : _submit,
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 16),
        child: Container(
          constraints: BoxConstraints(
            maxHeight: MediaQuery.of(context).size.height * 0.35,
          ),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(10),
            border: Border.all(color: const Color(0xFF9E9E9E), width: 2),
            color: Colors.white,
          ),
          padding: const EdgeInsets.all(8.0),
          child: TextField(
            controller: widget.descricaoController,
            keyboardType: TextInputType.multiline,
            maxLines: null,
            decoration: InputDecoration(
              enabledBorder: InputBorder.none,
              border: InputBorder.none,
              hintText: 'Escreva o comentário...',
              hintStyle: TextStyle(color: Colors.grey[600]),
            ),
            style: GoogleFonts.heebo(
              color: AppBottomModal.grayColor,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
      ),
    );
  }
}
