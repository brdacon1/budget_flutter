import 'package:oflite/modules/core/ads/domain/repository/ads_repository.dart';
import 'package:flutter/material.dart';
import 'package:oflite/injection.dart';
import 'package:oflite/modules/core/display_alert/domain/repository/display_alert_repository.dart';
import 'package:oflite/modules/core/share_link/domain/repository/share_link_repository.dart';
import 'package:oflite/shared/common/widgets/ads/interstitial_ad_service.dart';
import 'package:oflite/shared/common/widgets/modals/ads_option_bottom_modal_widget.dart';
import 'package:oflite/shared/models/customer_info.dart';
import 'package:oflite/modules/comment/presenter/comment_list_view.dart';
import 'package:oflite/modules/receipt/receipt_list/presenter/receipt_list_view.dart';
import 'package:oflite/modules/subscription/presenter/subscription_view.dart';
import 'package:share_plus/share_plus.dart';
import 'package:oflite/shared/models/global_uid_user.dart' as UID;

class MenuItem {
  final IconData icon;
  final String title;

  const MenuItem({required this.icon, required this.title});
}

class PdfMenuViewModel extends ChangeNotifier {
  final DisplayAlertRepository _displayAlert;
  final ShareLinkRepository _shareLinkRepository;
  final CustomerInfo item;

  List<MenuItem> menuItems = <MenuItem>[];

  PdfMenuViewModel({
    required this.item,
    DisplayAlertRepository? displayAlertRepository,
    ShareLinkRepository? shareLinkRepository,
  })  : _displayAlert = displayAlertRepository ?? getIt<DisplayAlertRepository>(),
        _shareLinkRepository = shareLinkRepository ?? getIt<ShareLinkRepository>();

  Future<void> inicialData() async {
    menuItems = const <MenuItem>[
      MenuItem(icon: Icons.comment_outlined, title: 'Inserir comentários'),
      MenuItem(icon: Icons.payments_outlined, title: 'Recibo de pagamentos'),
      MenuItem(icon: Icons.share_outlined, title: 'Compartilhar link do orçamento'),
    ];
    notifyListeners();
  }

  Future<void> refresh() => inicialData();

  Future<void> openOption(BuildContext context, int index) async {
    switch (index) {
      case 0:
        await Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => CommentListView(item: item),
          ),
        );
        break;
      case 1:
        await Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => ReceiptListView(item: item),
          ),
        );
        break;
      case 2:
        if (!UID.autoRenewing!) {
          await _displayAlert.adsNotification(context).then(
                  (value) async => {
                if (value == "Ver anuncio")
                  {
                    await shareBudget(context),
                    Future.delayed(const Duration(milliseconds: 2), ()  {
                      getIt<AdsRepository>().showInterstitial();
                    }),
                  }
                else if (value == "Se tornar premium")
                  {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                          builder: (context) =>
                              SubscriptionView()),
                    ),
                  }
              });
        } else {
          await shareBudget(context);
        }
        break;
    }
    await inicialData();
  }

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

  /// Gera o link público Web do orçamento (número do endereço + token
  /// provisório do Firebase) e abre a sheet nativa de compartilhamento.
  ///
  /// Reutiliza `BudgetShareLinkService` (aditivo, sem alterar regras do app
  /// mobile). O `id` do orçamento (`CustomerInfo.id`) é o "número do
  /// endereço" usado para localizá-lo no fluxo Web — nunca o telefone.
  Future<void> shareBudget(BuildContext context) async {
    final enderecoNumero = item.id;
    if (enderecoNumero == null || enderecoNumero.isEmpty) {
      await _displayAlert.notificationWarning(
        context,
        'Ainda não!',
        'Salve o orçamento antes de compartilhar o link.',
      );
      return;
    }

    try {
      final url = await _shareLinkRepository.buildShareUrl(
        enderecoNumero: enderecoNumero,
      );
      if (url == null) {
        if (!context.mounted) return;
        await _displayAlert.notificationError(
          context,
          'Erro!',
          'Não foi possível gerar o link. Verifique sua conexão e tente novamente.',
        );
        return;
      }
      await SharePlus.instance.share(
        ShareParams(text: url, subject: 'Orçamento'),
      );
    } catch (_) {
      if (context.mounted) {
        await _displayAlert.notificationError(
          context,
          'Erro!',
          'Não foi possível compartilhar o link agora.',
        );
      }
    }
  }
}
