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
    this.hideBackOnRootScreens = false,
  });

  final Widget master;
  final Widget emptyDetail;
  final GlobalKey<NavigatorState> detailNavigatorKey;
  final VoidCallback? onDetailClosed;
  final double masterWidth;

  /// `true`: as telas-raiz do painel (ex.: abas do orçamento) escondem a seta
  /// de voltar, porque quem troca o item é a lista ao lado. `false`: telas
  /// abertas por um fluxo (ex.: assistente) mantêm a seta para concluí-lo.
  final bool hideBackOnRootScreens;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        SizedBox(width: masterWidth, child: master),
        const VerticalDivider(width: 1, thickness: 1, color: cardBorderColor),
        Expanded(
          child: AppDetailPane(
            hidesBack: hideBackOnRootScreens,
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
  const AppDetailPane({
    super.key,
    required this.hidesBack,
    required super.child,
  });

  final bool hidesBack;

  /// `true` quando [context] está num painel de detalhe que pede para as
  /// telas-raiz esconderem a seta de voltar.
  static bool hidesBackOf(BuildContext context) =>
      context.dependOnInheritedWidgetOfExactType<AppDetailPane>()?.hidesBack ??
      false;

  @override
  bool updateShouldNotify(AppDetailPane oldWidget) =>
      hidesBack != oldWidget.hidesBack;
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
