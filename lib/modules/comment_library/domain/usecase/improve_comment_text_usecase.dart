import 'package:oflite/modules/comment_library/domain/entity/comment_library_exceptions.dart';
import 'package:oflite/modules/comment_library/domain/usecase/save_library_comment_usecase.dart';
import 'package:oflite/modules/core/ai_text/domain/usecase/generate_ai_text_usecase.dart';
import 'package:oflite/shared/design_pattern/result.dart';

/// Reescreve o comentário com IA (claro, profissional, sem erros).
///
/// Não grava nada: devolve o texto novo para o campo do modal.
/// Rejeita a resposta se ela perder qualquer número do original
/// (valores, prazos, datas) — a IA não pode alterar condições.
class ImproveCommentTextUsecase {
  static const system =
      'Reescreva o comentário de orçamento abaixo de forma clara, profissional '
      'e cordial, no mesmo idioma. Corrija ortografia e gramática. Mantenha '
      'todos os valores, prazos, datas e condições exatamente. Não invente '
      'informação. Responda só o texto reescrito.';

  final GenerateAiTextUsecase _ai;

  ImproveCommentTextUsecase(this._ai);

  Future<Result<String>> call(String text) async {
    final original = text.trim();
    if (original.isEmpty) {
      return Result.error(const CommentTextEmptyException());
    }
    final result = await _ai(system: system, prompt: original);
    if (result is! Ok<String>) return result;
    final improved = result.value.trim();
    if (improved.length > SaveLibraryCommentUsecase.maxTextLength ||
        !_keepsNumbers(original, improved)) {
      return Result.error(const CommentImproveInvalidException());
    }
    return Result.ok(improved);
  }

  bool _keepsNumbers(String original, String improved) {
    final found = RegExp(r'\d+').allMatches(improved).map((m) => m[0]).toSet();
    return RegExp(r'\d+').allMatches(original).every((m) => found.contains(m[0]));
  }
}
