import 'dart:async';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:oflite/injection.dart';
import 'package:oflite/modules/core/display_alert/domain/repository/display_alert_repository.dart';
import 'package:oflite/modules/core/loading_event/domain/repository/loading_event_repository.dart';
import 'package:oflite/modules/auth/data/datasource/user_remote_datasource.dart';
import 'package:oflite/modules/auth/data/model/info_user.dart';
import 'package:oflite/modules/auth/domain/repository/user_repository.dart';
import 'package:oflite/shared/common/enums/alert_type_enum.dart';
import 'package:oflite/shared/common/widgets/alert/alert_snack_bar_widget.dart';
import 'package:oflite/shared/common/widgets/modals/ads_option_bottom_modal_widget.dart';
import 'package:oflite/shared/common/widgets/modals/change_name_bottom_modal_widget.dart';
import 'package:oflite/shared/common/widgets/modals/change_password_bottom_modal_widget.dart';
import 'package:oflite/shared/common/widgets/modals/item_option_bottom_modal_widget.dart';

final FirebaseAuth _auth = FirebaseAuth.instance;

/// Implementação dos alertas e modais do app.
///
/// Mantém a lógica de negócio (Firebase Auth, `updateUserAdm`, etc.) e
/// consome [LoadingEventRepository] para o spinner de loading.
class DisplayAlertRepositoryImpl implements DisplayAlertRepository {
  final LoadingEventRepository _loadingEvent;
  final UserRepository _userRepository;

  DisplayAlertRepositoryImpl({
    required LoadingEventRepository loadingEvent,
    required UserRepository userRepository,
  }) : _loadingEvent = loadingEvent,
       _userRepository = userRepository;

  final InfoUser infoUser = InfoUser();

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
      builder:
          (context) => ChangePasswordBottomModalWidget(
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
  Future<String?> dialogChangeName(BuildContext context) async {
    String? savedName;
    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder:
          (context) => ChangeNameBottomModalWidget(
            onSubmit: (modalContext, name) async {
              try {
                _loadingEvent.alertLoading(modalContext);
                if (name.isNotEmpty) {
                  final session =
                      _userRepository.selectUser.value ?? InfoUser();
                  infoUser.autoRenewing = session.autoRenewing;
                  infoUser.email = session.email;
                  infoUser.phone = session.phone;
                  infoUser.id = session.id;
                  infoUser.idPay = session.idPay;
                  infoUser.name = name;
                  infoUser.productId = session.productId;
                  infoUser.purchaseToken = session.purchaseToken;
                  infoUser.user = session.user;

                  await getIt<UserRemoteDataSource>().updateUser(infoUser);
                  session.name = name;
                  _userRepository.selectUser.value = session;
                  savedName = name;
                  _loadingEvent.closeLoading(modalContext);
                  if (modalContext.mounted) {
                    Navigator.of(modalContext).pop();
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
    return savedName;
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
