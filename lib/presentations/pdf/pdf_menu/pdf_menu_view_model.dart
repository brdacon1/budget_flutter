import 'package:flutter/material.dart';
import 'package:oflite/Services/display_alert.dart';
import 'package:oflite/models/customer_info.dart';
import 'package:oflite/presentations/comment/comment_list_view.dart';
import 'package:oflite/presentations/receipt/receipt_list/receipt_list_view.dart';
import 'package:oflite/services/budget_share_link_service.dart';
import 'package:share_plus/share_plus.dart';

class MenuItem {
  final IconData icon;
  final String title;

  const MenuItem({required this.icon, required this.title});
}

class PdfMenuViewModel extends ChangeNotifier {
  final DisplayAlert displayAlert = DisplayAlert();
  final CustomerInfo item;

  List<MenuItem> menuItems = <MenuItem>[];

  PdfMenuViewModel({required this.item});

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
        await shareBudget(context);
        break;
    }
    await inicialData();
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
      await displayAlert.notificationWarning(
        context,
        'Ainda não!',
        'Salve o orçamento antes de compartilhar o link.',
      );
      return;
    }

    try {
      final url = await BudgetShareLinkService.buildShareUrl(
        enderecoNumero: enderecoNumero,
      );
      if (url == null) {
        if (!context.mounted) return;
        await displayAlert.notificationError(
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
        await displayAlert.notificationError(
          context,
          'Erro!',
          'Não foi possível compartilhar o link agora.',
        );
      }
    }
  }
}
