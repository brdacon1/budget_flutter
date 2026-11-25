import 'package:oflite/modules/auth/presenter/change_name/show_change_name_modal.dart';
import 'package:oflite/shared/common/widgets/alert/alert_snack_bar_widget.dart';
import 'package:material_ui/material_ui.dart';
import 'package:oflite/injection.dart';
import 'package:oflite/modules/comment_library/domain/usecase/check_comment_library_access_usecase.dart';
import 'package:oflite/modules/comment_library/presenter/comment_library_list/comment_library_list_view.dart';
import 'package:oflite/modules/main_config_menu/presenter/strings/main_config_menu_pt_string.dart';
import 'package:oflite/modules/delete_account/presenter/delete_account_in_app/delete_account_in_app_view.dart';
import 'package:oflite/modules/subscription/presenter/subscription_view.dart';
import 'package:oflite/modules/pdf/presenter/pdf_edit/presenter/pdf_edit_view.dart';
import 'package:oflite/modules/product/presenter/product_price_list/product_price_list_view.dart';

class MenuItem {
  final IconData icon;
  final String title;

  MenuItem({required this.icon, required this.title});
}

class MainConfigMenuViewModel extends ChangeNotifier {

  final List<MenuItem> menuItems = [
    MenuItem(icon: Icons.list, title: MainConfigMenuStrings.menuPriceList),
    MenuItem(
      icon: Icons.chat_bubble_outline,
      title: MainConfigMenuStrings.menuComments,
    ),
    MenuItem(
      icon: Icons.picture_as_pdf_outlined,
      title: MainConfigMenuStrings.menuEditPdf,
    ),
    MenuItem(
      icon: Icons.person_pin_outlined,
      title: MainConfigMenuStrings.menuChangeUsername,
    ),
    MenuItem(
      icon: Icons.workspace_premium_outlined,
      title: MainConfigMenuStrings.menuPremium,
    ),
    MenuItem(
      icon: Icons.delete_forever_outlined,
      title: MainConfigMenuStrings.menuDeleteAccount,
    ),
  ];

  void navigateToPage(BuildContext context, int index) {
    switch (index) {
      case 0:
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => const ProductPriceListView(),
          ),
        );
        break;
      case 1:
        _openComments(context);
        break;
      case 2:
        Navigator.push(
          context,
          MaterialPageRoute(builder: (context) => const PdfEditView()),
        );
        break;
      case 3:
        showChangeNameModal(context);
        break;
      case 4:
        Navigator.push(
          context,
          MaterialPageRoute(builder: (context) => const SubscriptionView()),
        );
        break;
      case 5:
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => const DeleteAccountInAppView(),
          ),
        );
        break;
    }
  }

  /// Biblioteca de comentários com IA: só assinante. Free vê o aviso e vai
  /// para a assinatura.
  Future<void> _openComments(BuildContext context) async {
    if (getIt<CheckCommentLibraryAccessUsecase>()()) {
      await Navigator.push(
        context,
        MaterialPageRoute(builder: (_) => const CommentLibraryListView()),
      );
      return;
    }
    AlertSnackBar.warning(
      context,
      MainConfigMenuStrings.premiumOnlyTitle,
      MainConfigMenuStrings.commentsPremiumOnly,
    );
    if (!context.mounted) return;
    await Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => const SubscriptionView()),
    );
  }
}
