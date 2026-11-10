import 'package:flutter/material.dart';
import 'package:oflite/injection.dart';
import 'package:oflite/modules/budget/data/model/customer_info_model.dart';
import 'package:oflite/modules/budget/data/model/observation_budget_model.dart';
import 'package:oflite/modules/core/display_alert/domain/repository/display_alert_repository.dart';
import 'package:oflite/shared/common/constants/constants.dart';
import 'package:oflite/shared/common/widgets/header/app_header_second_title.dart';

import 'comment_list_view_model.dart';
import 'components/comment_form_dialog.dart';
import 'components/comment_list_item.dart';

class CommentListView extends StatefulWidget {
  final CustomerInfo item;

  const CommentListView({super.key, required this.item});

  @override
  State<CommentListView> createState() => _CommentListView();
}

class _CommentListView extends State<CommentListView> {
  late CommentListViewModel _viewModel;
  final DisplayAlertRepository _displayAlert = getIt<DisplayAlertRepository>();

  @override
  void initState() {
    super.initState();
    _viewModel = CommentListViewModel(item: widget.item);
    _viewModel.addListener(_onViewModelChanged);
    _initData();
  }

  @override
  void dispose() {
    _viewModel.removeListener(_onViewModelChanged);
    _viewModel.dispose();
    super.dispose();
  }

  void _onViewModelChanged() {
    setState(() {});
  }

  Future<void> _initData() async {
    final success = await _viewModel.loadComments();
    if (!success && mounted) {
      await _displayAlert.notificationError(
        context,
        "Erro!",
        "Não foi possível carregar os comentários",
      );
    }
  }

  Future<void> _openNotificationError() async {
    await _displayAlert.notificationError(
      context,
      "Erro!",
      "Não foi possível remover o comentário",
    );
  }

  Future<void> _openCommentForm(ObservationBudget comment) async {
    final saved = await showCommentFormDialog(
      context: context,
      viewModel: _viewModel,
      comment: comment,
      displayAlert: _displayAlert,
    );

    if (saved == null) return;
    await _viewModel.loadComments();
    _viewModel.resetSelectionState();
  }

  Widget _commentList() {
    if (_viewModel.foundObservation.isEmpty) {
      return Container(
        padding: const EdgeInsets.symmetric(vertical: 40, horizontal: 16),
        child: Text(
          "O orçamento não possui comentários",
          style: TextStyle(fontSize: 14, color: Colors.grey),
          textAlign: TextAlign.center,
        ),
      );
    }

    return ListView.builder(
      shrinkWrap: true,
      padding: const EdgeInsets.only(bottom: 150, left: 16, right: 16),
      itemCount: _viewModel.foundObservation.length,
      itemBuilder: (context, index) {
        final comment = _viewModel.foundObservation[index];
        return CommentListItem(
          comment: comment,
          onDelete: (obs) async {
            final success = await _viewModel.deleteComment(obs);
            if (!success && mounted) {
              await _openNotificationError();
            }
          },
          onEdit: (obs) async {
            await _openCommentForm(obs);
          },
        );
      },
    );
  }

  Widget _buildFloatingActionButton() {
    return AnimatedBuilder(
      animation: _viewModel,
      builder: (context, _) {
        return FloatingActionButton.extended(
          heroTag: 'adicionar_comentario',
          onPressed: () {
            final newObservation =
                ObservationBudget()
                  ..checkbox = false
                  ..id = ''
                  ..data = ''
                  ..uid = ''
                  ..observacao = '';
            _openCommentForm(newObservation);
          },
          backgroundColor: buttonColor,
          elevation: 4,
          icon: const Icon(Icons.add, color: Colors.black, size: 20),
          label: const Text(
            'Novo Comentário',
            style: TextStyle(
              color: Colors.black,
              fontWeight: FontWeight.bold,
              fontSize: 13,
            ),
          ),
        );
      },
    );
  }

  Widget _buildCommentList() {
    return Expanded(
      child: RefreshIndicator(
        color: Colors.cyan[50],
        backgroundColor: bgColor,
        onRefresh: () async {
          await _viewModel.loadComments();
          _viewModel.resetSelectionState();
        },
        child: _commentList(),
      ),
    );
  }

  Widget _buildScreen({required double height, required double we}) {
    return Column(
      mainAxisSize: MainAxisSize.max,
      children: <Widget>[
        AppHeaderSecondTitle(
          titlePage: 'Comentários',
          secondTitle: 'Comentários do orçamento',
          onBack: () => Navigator.pop(context, true),
        ),
        _buildCommentList(),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    final we = MediaQuery.of(context).size.width;
    final he = MediaQuery.of(context).size.height;
    return Scaffold(
      backgroundColor: bgColor,
      body: AnimatedBuilder(
        animation: _viewModel,
        builder: (context, _) {
          return _buildScreen(height: he, we: we);
        },
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.endFloat,
      floatingActionButton: _buildFloatingActionButton(),
    );
  }
}
