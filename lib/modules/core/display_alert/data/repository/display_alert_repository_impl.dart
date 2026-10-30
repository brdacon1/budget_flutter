import 'dart:async';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:oflite/modules/core/display_alert/domain/repository/display_alert_repository.dart';
import 'package:oflite/modules/core/loading_event/domain/repository/loading_event_repository.dart';
import 'package:oflite/shared/common/enums/alert_type_enum.dart';
import 'package:oflite/shared/common/widgets/alert/alert_snack_bar_widget.dart';
import 'package:oflite/shared/common/widgets/modals/ads_option_bottom_modal_widget.dart';
import 'package:oflite/shared/common/widgets/modals/change_name_bottom_modal_widget.dart';
import 'package:oflite/shared/common/widgets/modals/change_password_bottom_modal_widget.dart';
import 'package:oflite/shared/common/widgets/modals/item_option_bottom_modal_widget.dart';
import 'package:oflite/shared/models/global_uid_user.dart' as global_uid_user;
import 'package:oflite/shared/models/info_user.dart';
import 'package:oflite/injection.dart';
import 'package:oflite/modules/login/data/datasource/user_remote_datasource.dart';

final FirebaseAuth _auth = FirebaseAuth.instance;

/// Implementação dos alertas e modais do app.
///
/// Mantém a lógica de negócio (Firebase Auth, `updateUserAdm`, etc.) e
/// consome [LoadingEventRepository] para o spinner de loading.
class DisplayAlertRepositoryImpl implements DisplayAlertRepository {
  final LoadingEventRepository _loadingEvent;

  DisplayAlertRepositoryImpl({required LoadingEventRepository loadingEvent})
      : _loadingEvent = loadingEvent;

  final InfoUser DADOS = InfoUser();

  // -----------------------------------------------------------------------
  // Alertas (snackbars)
  // -----------------------------------------------------------------------

  @override
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
  }

  @override
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

  @override
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

  @override
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

  @override
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

  @override
  Future<void> dialogChangeName(BuildContext context) {
    return showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => ChangeNameBottomModalWidget(
        onSubmit: (modalContext, name) async {
          try {
            _loadingEvent.alertLoading(modalContext);
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

              await getIt<UserRemoteDataSource>().updateUser(DADOS);
              global_uid_user.name = name;
              _loadingEvent.closeLoading(modalContext);
              if (modalContext.mounted) {
                Navigator.of(modalContext).pop();
                await notification(
                  modalContext,
                  'Feito!',
                  'Nome atualizado com sucesso!',
                );
              }
            } else {
              _loadingEvent.closeLoading(modalContext);
              if (modalContext.mounted) {
                await notificationError(
                  modalContext,
                  'Erro!',
                  'O campo nome não pode ser vazio!',
                );
              }
            }
          } catch (e) {
            _loadingEvent.closeLoading(modalContext);
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

  @override
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

  @override
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
