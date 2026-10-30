import 'package:flutter/material.dart';
import 'package:oflite/modules/receipt/presenter/strings/receipt_pt_string.dart';
import 'package:oflite/shared/models/receipt.dart';

/// Gerenciamento de estado da tela de **abas de recibo**.
///
/// `extends ChangeNotifier` → fornece `notifyListeners()` consumido pelo
/// `AnimatedBuilder` da View. Toda mutação de estado termina com
/// `notifyListeners()`. A View **nunca** chama `setState`.
///
/// Detém:
/// - o índice da aba atual ([currentIndex]) e o callback de troca
///   ([onTabTapped]) — a tela é um **contêiner** de abas que delega o
///   conteúdo a [ReceiptCreatorView], [PaymentListView] e [PdfReceiptView];
/// - o [receipt] atual (imutável, padrão canônico seção 10), que é
///   **atualizado** quando a aba de criação persiste um novo recibo
///   ([updateReceipt]) — assim as abas irmãs (Pagamentos/PDF) passam a
///   enxergar o recibo recém-criado, preservando o comportamento original de
///   propagação entre abas (antes feito por mutação do objeto compartilhado).
///
/// Regras seguidas (ver `.pi/sdd_arquitetura_view_model.md`):
/// - Toda mutação de estado termina com `notifyListeners()`.
/// - A View reconstrói via `AnimatedBuilder`, nunca `setState`.
/// - Sem mutação direta de campos do model — [receipt] é substituído por uma
///   nova instância (imutável).
class ReceiptTabViewModel extends ChangeNotifier {
  Receipt receipt;
  int currentIndex = 0;

  ReceiptTabViewModel({required this.receipt});

  /// Troca a aba ativa. Preserva o comportamento original (atribui o índice
  /// recebido, independentemente do valor).
  void onTabTapped(int index) {
    currentIndex = index;
    notifyListeners();
  }

  /// Atualiza o recibo corrente (chamado pela aba de criação ao salvar um
  /// novo recibo) e reconstrói as abas com o recibo atualizado.
  void updateReceipt(Receipt newReceipt) {
    receipt = newReceipt;
    notifyListeners();
  }

  /// Rótulos das abas, centralizados em [ReceiptPtString].
  List<String> get tabLabels => <String>[
        ReceiptPtString.tabReceipt,
        ReceiptPtString.tabPayments,
        ReceiptPtString.tabPdf,
      ];
}
