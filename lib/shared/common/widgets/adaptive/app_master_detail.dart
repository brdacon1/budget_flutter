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
    this.aside,
    this.asideMinWidth = 1100,
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

  /// Terceiro painel (à direita do detalhe), ex.: opções do item aberto.
  /// Só aparece quando a largura é >= [asideMinWidth]; abaixo disso o layout
  /// volta a ser lista + detalhe, sem apertar nenhum painel.
  final Widget? aside;
  final double asideMinWidth;

  @override
  Widget build(BuildContext context) {
    const divider = VerticalDivider(
      width: 1,
      thickness: 1,
      color: cardBorderColor,
    );
    return LayoutBuilder(
      builder: (context, constraints) {
        final threePanes =
            aside != null && constraints.maxWidth >= asideMinWidth;
        return Row(
          children: [
            // 3 painéis: tamanhos iguais (cada um 1/3 da largura).
            if (threePanes)
              Expanded(child: master)
            else
              SizedBox(width: masterWidth, child: master),
            divider,
            Expanded(
              child: AppAsidePane(
                active: threePanes,
                child: AppDetailPane(
                  hidesBack: hideBackOnRootScreens,
                  child: Navigator(
                    key: detailNavigatorKey,
                    observers: [_DetailClosedObserver(onDetailClosed)],
                    onGenerateRoute:
                        (_) => MaterialPageRoute<void>(
                          builder: (_) => emptyDetail,
                        ),
                  ),
                ),
              ),
            ),
            if (threePanes) ...[
              divider,
              Expanded(child: AppDetailPane(hidesBack: true, child: aside!)),
            ],
          ],
        );
      },
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

/// Indica às telas do detalhe que existe um terceiro painel ao lado (ex.: a
/// aba "Mais" do orçamento vive nele, então a barra de abas a esconde).
class AppAsidePane extends InheritedWidget {
  const AppAsidePane({super.key, required this.active, required super.child});

  final bool active;

  static bool activeOf(BuildContext context) =>
      context.dependOnInheritedWidgetOfExactType<AppAsidePane>()?.active ??
      false;

  @override
  bool updateShouldNotify(AppAsidePane oldWidget) => active != oldWidget.active;
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
