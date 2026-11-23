import 'package:material_ui/material_ui.dart';
import 'package:oflite/shared/common/constants/colors.dart';

/// Lista à esquerda + detalhe à direita (tela larga).
///
/// O detalhe é um `Navigator` próprio: telas empilhadas lá dentro abrem só no
/// painel e a lista continua visível. A rota-base é [emptyDetail]; abrir um
/// item = `detailNavigatorKey.currentState!.pushAndRemoveUntil(rota,
/// (r) => r.isFirst)`. Voltar (`Navigator.pop`) na tela do item "fecha" o
/// detalhe e volta para [emptyDetail] — [onDetailClosed] avisa.
class AppMasterDetail extends StatelessWidget {
  const AppMasterDetail({
    super.key,
    required this.master,
    required this.emptyDetail,
    required this.detailNavigatorKey,
    this.onDetailClosed,
    this.masterWidth = 440,
  });

  final Widget master;
  final Widget emptyDetail;
  final GlobalKey<NavigatorState> detailNavigatorKey;
  final VoidCallback? onDetailClosed;
  final double masterWidth;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        SizedBox(width: masterWidth, child: master),
        const VerticalDivider(width: 1, thickness: 1, color: cardBorderColor),
        Expanded(
          child: AppDetailPane(
            child: Navigator(
              key: detailNavigatorKey,
              observers: [_DetailClosedObserver(onDetailClosed)],
              onGenerateRoute:
                  (_) => MaterialPageRoute<void>(builder: (_) => emptyDetail),
            ),
          ),
        ),
      ],
    );
  }
}

/// Marca as telas que estão dentro do painel de detalhe. Telas-raiz do painel
/// (ex.: abas do orçamento) escondem a seta de voltar: quem troca o item é a
/// lista ao lado.
class AppDetailPane extends InheritedWidget {
  const AppDetailPane({super.key, required super.child});

  /// `true` quando [context] está dentro de um painel de detalhe.
  static bool isInside(BuildContext context) =>
      context.dependOnInheritedWidgetOfExactType<AppDetailPane>() != null;

  @override
  bool updateShouldNotify(AppDetailPane oldWidget) => false;
}

/// Avisa quando a pilha do detalhe volta para a rota-base.
class _DetailClosedObserver extends NavigatorObserver {
  _DetailClosedObserver(this.onClosed);

  final VoidCallback? onClosed;

  @override
  void didPop(Route<dynamic> route, Route<dynamic>? previousRoute) {
    if (previousRoute?.isFirst ?? false) onClosed?.call();
  }
}
