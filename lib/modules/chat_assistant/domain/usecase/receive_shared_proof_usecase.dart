import 'dart:async';

import 'package:oflite/modules/chat_assistant/domain/entity/gallery_asset_entity.dart';
import 'package:oflite/modules/chat_assistant/domain/repository/chat_media_repository.dart';
import 'package:oflite/modules/chat_assistant/domain/usecase/check_ai_access_usecase.dart';
import 'package:oflite/modules/payment_proof/domain/usecase/validate_proof_attachments_usecase.dart';

/// O que fazer com arquivos recebidos pelo compartilhamento do sistema.
sealed class SharedProofEvent {
  const SharedProofEvent();
}

/// Assinante: abrir o chat com estes anexos na prévia.
class SharedProofReady extends SharedProofEvent {
  final ProofAttachmentValidation validation;

  const SharedProofReady(this.validation);
}

/// Não assinante: mostrar a tela de assinatura (R1).
class SharedProofNeedsPremium extends SharedProofEvent {
  const SharedProofNeedsPremium();
}

/// §15.4: recebe arquivos compartilhados, valida e checa o acesso.
///
/// O último envio fica guardado em [pending] até o chat consumi-lo (ex.:
/// app aberto frio antes do login).
class ReceiveSharedProofUsecase {
  final ChatMediaRepository _media;
  final ValidateProofAttachmentsUsecase _validate;
  final CheckAiAccessUsecase _checkAccess;

  ReceiveSharedProofUsecase(this._media, this._validate, this._checkAccess);

  ProofAttachmentValidation? _pending;

  /// Retira o envio pendente (só uma vez).
  ProofAttachmentValidation? takePending() {
    final p = _pending;
    _pending = null;
    return p;
  }

  Future<SharedProofEvent?> _handle(List<RawMediaFile> raw) async {
    if (raw.isEmpty) return null;
    unawaited(_media.resetShared());
    if (!_checkAccess()) return const SharedProofNeedsPremium();
    final v = await _validate(raw);
    _pending = v;
    return SharedProofReady(v);
  }

  Future<SharedProofEvent?> initial() async =>
      _handle(await _media.initialShared());

  Stream<SharedProofEvent> stream() => _media
      .sharedStream()
      .asyncMap(_handle)
      .where((e) => e != null)
      .cast<SharedProofEvent>();
}
