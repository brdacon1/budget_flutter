import 'package:flutter/material.dart';
import 'package:oflite/injection.dart';
import 'package:oflite/shared/common/constants/global_uid_user.dart' as uid;
import 'package:oflite/modules/budget/budget_list/presenter/budget_list_view.dart';
import 'package:oflite/modules/chat_assistant/presenter/chat_assistant/chat_assistant_view.dart';
import 'package:oflite/modules/main_config_menu/presenter/main_config_menu_view.dart';
import 'package:oflite/modules/dashboard/presenter/dashboard_view.dart';
import 'package:oflite/modules/core/notification/domain/repository/notification_repository.dart';
import 'package:oflite/shared/common/constants/constants.dart';
import 'main_tab_view_model.dart';

class MainTabView extends StatefulWidget {
  const MainTabView({super.key});

  @override
  State<MainTabView> createState() => _MainTabView();
}

class _MainTabView extends State<MainTabView> {
  final MainTabViewModel _viewModel = getIt<MainTabViewModel>();

  @override
  void initState() {
    super.initState();
    // Após o login (auto-login ou manual), a tela principal está pronta e o
    // dono está autenticado: consome um possível orçamento pendente de abrir
    // (caso de cold-start pelo toque no banner da notificação).
    WidgetsBinding.instance.addPostFrameCallback((_) {
      getIt<NotificationRepository>().tryOpenPendingBudget();
      // REDUNDÂNCIA de persistência do token FCM: o login já tenta salvar,
      // mas aqui (dashboard) o dono está definitivamente autenticado e o
      // token já foi obtido no startup. Se por algum motivo o save do login
      // não chegou ao Firestore (ex.: race com o `global_uid_user.user`),
      // esta chamada garante que o token deste device entre na lista
      // `EMPRESAS/{uid}/USERS/{uid}/FCM/{token}`. Idempotente.
      final ownerUid = uid.user;
      if (ownerUid != null && ownerUid.trim().isNotEmpty) {
        getIt<NotificationRepository>()
            .persistCurrentTokenToFirebase(ownerUid);
      }
    });
  }

  @override
  void dispose() {
    _viewModel.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final List<Widget> children = [
      const ChatAssistantView(),
      const BudgetListView(),
      const DashboardView(),
    ];

    return AnimatedBuilder(
      animation: _viewModel,
      builder: (context, _) {
        return Scaffold(
          body: children[_viewModel.currentIndex],
          bottomNavigationBar: Theme(
            data: Theme.of(context).copyWith(
              canvasColor: secondaryColor,
            ),
            child: BottomNavigationBar(
              showUnselectedLabels: true,
              selectedItemColor: Colors.cyan[50],
              selectedLabelStyle:
                  const TextStyle(fontSize: 11.0, fontWeight: FontWeight.bold),
              unselectedItemColor: Colors.grey,
              onTap: _viewModel.onTabTapped,
              currentIndex: _viewModel.currentIndex,
              items: _viewModel.tabItems
                  .map(
                    (tabItem) => BottomNavigationBarItem(
                      icon: Icon(tabItem.icon),
                      label: tabItem.title,
                    ),
                  )
                  .toList(),
            ),
          ),
        );
      },
    );
  }
}
