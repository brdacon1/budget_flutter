import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:oflite/common/constants/constants.dart';
import 'package:oflite/models/customer_info.dart';
import 'package:oflite/models/observation_budget.dart';
import '../../Services/display_alert.dart';
import '../../common/widgets/anmition/fade_animation_widget.dart';
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
  final DisplayAlert _displayAlert = DisplayAlert();

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
          context, "Erro!", "Não foi possível carregar os comentários");
    }
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

  @override
  Widget build(BuildContext context) {
    final we = MediaQuery.of(context).size.width;
    final he = MediaQuery.of(context).size.height;

    return Scaffold(
      backgroundColor: bgColor,
      body: Column(
        mainAxisSize: MainAxisSize.max,
        children: <Widget>[
          SizedBox(height: he * 0.07),
          _backButton(we),
          SizedBox(height: he * 0.03),
          _title(we),
          SizedBox(height: he * 0.03),
          Expanded(
            child: RefreshIndicator(
              color: Colors.cyan[50],
              backgroundColor: bgColor,
              onRefresh: () async {
                await _viewModel.loadComments();
                _viewModel.resetSelectionState();
              },
              child: _commentList(),
            ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          final newObservation = ObservationBudget()
            ..checkbox = false
            ..id = ''
            ..data = ''
            ..uid = ''
            ..observacao = '';
          _openCommentForm(newObservation);
        },
        backgroundColor: buttonColor,
        child: const Icon(Icons.add, color: Colors.black),
      ),
    );
  }

  Widget _backButton(double we) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      mainAxisSize: MainAxisSize.max,
      children: <Widget>[
        GestureDetector(
          onTap: () {
            Navigator.pop(context, true);
          },
          child: Container(
            alignment: Alignment.topLeft,
            margin: EdgeInsets.only(left: we * 0.02),
            child: const Icon(
              Icons.arrow_back_outlined,
              color: Colors.white,
              size: 35.0,
            ),
          ),
        ),
      ],
    );
  }

  Widget _title(double we) {
    return FadeAnimationWidget(
      delay: 1,
      child: Container(
        alignment: Alignment.topLeft,
        margin: EdgeInsets.only(left: we * 0.028),
        child: Text(
          "Comentários",
          style: GoogleFonts.heebo(
            color: Colors.white,
            fontWeight: FontWeight.bold,
            fontSize: 26,
            letterSpacing: 2,
          ),
        ),
      ),
    );
  }

  Widget _commentList() {
    return ListView.builder(
      shrinkWrap: true,
      padding: const EdgeInsets.only(bottom: 150, left: 15, right: 15, top: 10),
      itemCount: _viewModel.foundObservation.length,
      itemBuilder: (context, index) {
        final comment = _viewModel.foundObservation[index];
        return CommentListItem(
          comment: comment,
          onDelete: (obs) async {
            final success = await _viewModel.deleteComment(obs);
            if (!success && mounted) {
              await _displayAlert.notificationError(
                  context, "Erro!", "Não foi possível remover o comentário");
            }
          },
          onEdit: (obs) async {
            await _openCommentForm(obs);
          },
        );
      },
    );
  }
}
