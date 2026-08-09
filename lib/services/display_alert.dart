import 'dart:async';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:oflite/common/enums/alert_type_enum.dart';
import 'package:oflite/common/widgets/alert/alert_snack_bar_widget.dart';
import 'package:oflite/common/widgets/modals/ads_option_bottom_modal_widget.dart';
import 'package:oflite/common/widgets/modals/change_name_bottom_modal_widget.dart';
import 'package:oflite/common/widgets/modals/change_password_bottom_modal_widget.dart';
import 'package:oflite/common/widgets/modals/item_option_bottom_modal_widget.dart';
import 'package:oflite/models/global_uid_user.dart' as global_uid_user;
import 'package:oflite/models/info_user.dart';

import 'http_request.dart';
import 'loading_event.dart';

final FirebaseAuth _auth = FirebaseAuth.instance;

/// Centraliza os alertas e modais do app.
///
/// Os antigos dialogs `AwesomeDialog`/`AlertDialog` foram substituídos por:
/// - **Snackbars** (verde/vermelho/laranja) para os alertas `notification*`;
/// - **Bottom modals** (fundo branco, acompanham o teclado) para os modais de
///   formulário e seleção.
///
/// As assinaturas públicas foram mantidas para não quebrar as regras de
/// negócio das ViewModels/Views que já chamam estes métodos. A lógica de
/// negócio (Firebase Auth, `updateUserAdm`, etc.) continua aqui — apenas a
/// camada visual foi refatorada.
class DisplayAlert {
  final HttpRequest db = HttpRequest();
  final InfoUser DADOS = InfoUser();
  final LoadingEvent alertDisplayLoading = LoadingEvent();

  // -----------------------------------------------------------------------
  // Alertas (snackbars)
  // -----------------------------------------------------------------------

  /// Alerta de erro (vermelho).
  Future<void> notificationError(
    BuildContext context,
    String firstMessage,
    String secondMessage,
  ) async {
    AlertSnackBar.show(
      context,
      type: AlertType.error,
      title: firstMessage,
      message: secondMessage,
    );
    // Mantém o contrato de retornar um Future que completa após a chamada,
    // mas sem bloquear a tela (snackbar é não modal).
  }

  /// Alerta de aviso (laranja).
  Future<void> notificationWarning(
    BuildContext context,
    String firstMessage,
    String secondMessage,
  ) async {
    AlertSnackBar.show(
      context,
      type: AlertType.warning,
      title: firstMessage,
      message: secondMessage,
    );
  }

  /// Alerta de sucesso (verde) — não fecha a tela atual.
  Future<void> notificationNotCloseScreen(
    BuildContext context,
    String firstMessage,
    String secondMessage,
  ) async {
    AlertSnackBar.show(
      context,
      type: AlertType.success,
      title: firstMessage,
      message: secondMessage,
    );
  }

  /// Alerta de sucesso (verde).
  Future<void> notification(
    BuildContext context,
    String firstMessage,
    String secondMessage,
  ) async {
    AlertSnackBar.show(
      context,
      type: AlertType.success,
      title: firstMessage,
      message: secondMessage,
    );
  }

  // -----------------------------------------------------------------------
  // Modais (bottom modals)
  // -----------------------------------------------------------------------

  /// Modal de recuperação de senha (bottom modal com campo de e-mail).
  Future<void> dialogChangePassword(BuildContext context) {
    return showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => ChangePasswordBottomModalWidget(
        onSubmit: (modalContext, email) async {
          try {
            await _auth.sendPasswordResetEmail(email: email);
            if (modalContext.mounted) {
              Navigator.of(modalContext).pop();
              await notification(
                modalContext,
                'Feito!',
                'Você recebeu um email para trocar de senha',
              );
            }
          } catch (e) {
            if (modalContext.mounted) {
              await notificationError(
                modalContext,
                'Erro!',
                'Problemas para restaurar sua senha verifique seu e-mail se está correto!',
              );
            }
          }
        },
      ),
    );
  }

  /// Modal para trocar o nome do usuário (bottom modal com campo de nome).
  Future<void> dialogChangeName(BuildContext context) {
    return showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => ChangeNameBottomModalWidget(
        onSubmit: (modalContext, name) async {
          try {
            alertDisplayLoading.alertLoading(modalContext);
            if (name.isNotEmpty) {
              DADOS.AutoRenewing = global_uid_user.autoRenewing;
              DADOS.EMAIL = global_uid_user.email;
              DADOS.FONE = global_uid_user.phone;
              DADOS.Id = global_uid_user.id;
              DADOS.IdPay = global_uid_user.idPay;
              DADOS.NOME = name;
              DADOS.ProductId = global_uid_user.productId;
              DADOS.PurchaseToken = global_uid_user.purchaseToken;
              DADOS.USER = global_uid_user.user;

              await db.updateUserAdm(DADOS).then((value) async {
                global_uid_user.name = name;
                alertDisplayLoading.closeLoading(modalContext);
                if (modalContext.mounted) {
                  Navigator.of(modalContext).pop();
                  await notification(
                    modalContext,
                    'Feito!',
                    'Nome atualizado com sucesso!',
                  );
                }
              });
            } else {
              alertDisplayLoading.closeLoading(modalContext);
              if (modalContext.mounted) {
                await notificationError(
                  modalContext,
                  'Erro!',
                  'O campo nome não pode ser vazio!',
                );
              }
            }
          } catch (e) {
            alertDisplayLoading.closeLoading(modalContext);
            if (modalContext.mounted) {
              await notificationError(
                modalContext,
                'Erro!',
                'Problemas para atualizar o nome verifique os dados!',
              );
            }
          }
        },
      ),
    );
  }

  /// Modal de opções para adicionar orçamento (anúncio x premium).
  Future<String> adsNotification(BuildContext context) async {
    String resultText = '';
    await showModalBottomSheet<String>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => const AdsOptionBottomModalWidget(),
    ).then((value) {
      resultText = value ?? '';
    });
    return resultText;
  }

  /// Modal de opções para inserir item (criar novo x selecionar da lista).
  Future<String> listNotification(BuildContext context) async {
    String resultText = '';
    await showModalBottomSheet<String>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => const ItemOptionBottomModalWidget(),
    ).then((value) {
      resultText = value ?? '';
    });
    return resultText;
  }
}
