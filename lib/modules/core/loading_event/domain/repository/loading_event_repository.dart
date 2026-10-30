import 'package:flutter/material.dart';

/// Contrato para exibição e controle de dialog de loading.
///
/// Mantém estado interno (_isLoading) e trabalha com [BuildContext].
abstract class LoadingEventRepository {
  /// Abre um [AlertDialog] com [CircularProgressIndicator] e texto
  /// "Aguarde...". Não é dismissible via back.
  Future<void> alertLoading(BuildContext context);

  /// Fecha o dialog de loading se estiver aberto.
  void closeLoading(BuildContext context);
}
