import 'package:flutter/widgets.dart';

/// Textos dos comprovantes de pagamento (chat + lista), pt/en.
class PaymentProofStrings {
  const PaymentProofStrings._();

  static bool get _isPt =>
      WidgetsBinding.instance.platformDispatcher.locale.languageCode == 'pt';

  // --- Painel de anexos / seletor ---
  static String get attachPhotos => _isPt ? 'Fotos' : 'Photos';
  static String get attachCamera => _isPt ? 'Câmera' : 'Camera';
  static String get attachDocument => _isPt ? 'Documento' : 'Document';
  static String get albums => _isPt ? 'Álbuns' : 'Albums';
  static String get captionHint =>
      _isPt ? 'Adicione uma legenda…' : 'Add a caption…';
  static String get galleryPermission =>
      _isPt
          ? 'Permita o acesso às fotos para anexar comprovantes.'
          : 'Allow photo access to attach receipts.';
  static String get openSettings => _isPt ? 'Abrir ajustes' : 'Open settings';
  static String get emptyGallery =>
      _isPt ? 'Nenhuma foto encontrada.' : 'No photos found.';
  static String get maxPhotos =>
      _isPt ? 'Você pode enviar até 2 fotos.' : 'You can send up to 2 photos.';
  static String get tooBig =>
      _isPt ? 'Arquivo maior que 10 MB.' : 'File larger than 10 MB.';
  static String get invalidType =>
      _isPt
          ? 'Envie uma imagem (JPG/PNG) ou um PDF.'
          : 'Send an image (JPG/PNG) or a PDF.';
  static String get mixedTypes =>
      _isPt
          ? 'Envie até 2 fotos ou 1 PDF, não os dois juntos.'
          : 'Send up to 2 photos or 1 PDF, not both.';
  static String get onlyFirstFiles =>
      _isPt
          ? 'Só os 2 primeiros arquivos foram mantidos.'
          : 'Only the first 2 files were kept.';

  // --- Fluxo no chat ---
  static String get askBudget =>
      _isPt
          ? 'A qual orçamento você quer vincular este comprovante?'
          : 'Which budget should this receipt be linked to?';
  static String get selectBudgetLabel =>
      _isPt ? 'Selecionar orçamento' : 'Select budget';
  static String budgetChosen(String name) =>
      _isPt ? 'Orçamento: $name' : 'Budget: $name';
  static String get limitReached =>
      _isPt
          ? 'Esse orçamento já tem 15 comprovantes. Escolha outro orçamento.'
          : 'This budget already has 15 receipts. Choose another budget.';
  static String limitWouldExceed(int count) =>
      _isPt
          ? 'Esse orçamento já tem $count de 15 comprovantes e não cabem estes arquivos. Escolha outro orçamento.'
          : 'This budget already has $count of 15 receipts and these files do not fit. Choose another budget.';
  static String get chooseAnother =>
      _isPt ? 'Escolher outro orçamento' : 'Choose another budget';
  static String get askName =>
      _isPt ? 'Qual o nome do comprovante?' : 'What is the receipt name?';
  static String get nameRequired =>
      _isPt
          ? 'O nome é obrigatório. Qual o nome do comprovante?'
          : 'The name is required. What is the receipt name?';
  static String get askValue =>
      _isPt ? 'Qual o valor do comprovante?' : 'What is the receipt amount?';
  static String get invalidValue =>
      _isPt
          ? 'Não entendi o valor. Ex.: 150,00'
          : "I didn't understand the amount. E.g.: 150.00";
  static String get saved =>
      _isPt ? 'Comprovante salvo com sucesso ✅' : 'Receipt saved successfully ✅';
  static String get seeProofs => _isPt ? 'Ver comprovantes' : 'See receipts';
  static String get saveError =>
      _isPt
          ? 'Não consegui salvar o comprovante. Tente de novo.'
          : "Couldn't save the receipt. Try again.";
  static String get tryAgain => _isPt ? 'Tentar de novo' : 'Try again';
  static String get attachmentsUnavailable =>
      _isPt
          ? 'Termine a etapa atual ou volte ao menu para anexar comprovantes.'
          : 'Finish the current step or go back to the menu to attach receipts.';

  static String get cropTitle => _isPt ? 'Recortar imagem' : 'Crop image';
  static String get permissionDenied =>
      _isPt
          ? 'Não consigo seguir sem liberação da permissão.'
          : "I can't continue without the permission.";
  static String get attach => _isPt ? 'Anexar' : 'Attach';

  // --- Detalhe ---
  static String get detailName => _isPt ? 'Nome' : 'Name';
  static String get detailValue => _isPt ? 'Valor' : 'Amount';
  static String get detailDate => _isPt ? 'Salvo em' : 'Saved on';
  static String get detailComment => _isPt ? 'Comentário' : 'Comment';
  static String get detailType => _isPt ? 'Tipo' : 'Type';
  static String get openPdf => _isPt ? 'Abrir PDF' : 'Open PDF';
  static String get totalLabel => 'Total';
  static String proofsCount(int n) =>
      _isPt
          ? '$n ${n == 1 ? 'comprovante' : 'comprovantes'}'
          : '$n ${n == 1 ? 'receipt' : 'receipts'}';

  // --- Lista ---
  static String get listTitle => _isPt ? 'Comprovantes' : 'Payment proofs';
  static String listCounter(int n) =>
      _isPt ? '$n de 15 comprovantes' : '$n of 15 receipts';
  static String get empty =>
      _isPt
          ? 'Nenhum comprovante ainda. Envie pelo chat 📎'
          : 'No receipts yet. Send one through the chat 📎';
  static String get noValue => _isPt ? 'Sem valor' : 'No amount';
  static String dateTime(String date, String time) =>
      _isPt ? '$date às $time' : '$date at $time';
  static String get typeImage => _isPt ? 'Imagem' : 'Image';
  static String get typePdf => 'PDF';
  static String get share => _isPt ? 'Compartilhar' : 'Share';
  static String get delete => _isPt ? 'Excluir' : 'Delete';
  static String get deleteConfirm =>
      _isPt ? 'Excluir este comprovante?' : 'Delete this receipt?';
  static String get cancel => _isPt ? 'Cancelar' : 'Cancel';
  static String get loadError =>
      _isPt
          ? 'Não foi possível carregar os comprovantes.'
          : 'Could not load the receipts.';
  static String get deleteError =>
      _isPt
          ? 'Não foi possível excluir o comprovante.'
          : 'Could not delete the receipt.';
  static String get menuLabel => _isPt ? 'Comprovantes' : 'Payment proofs';
}
