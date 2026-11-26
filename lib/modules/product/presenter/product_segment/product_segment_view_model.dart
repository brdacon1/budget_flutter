import 'package:material_ui/material_ui.dart';
import 'package:oflite/injection.dart';
import 'package:oflite/modules/core/convert_coin/domain/repository/convert_coin_repository.dart';
import 'package:oflite/modules/product/data/model/product_price_model.dart';
import 'package:oflite/modules/product/domain/entity/business_segment.dart';
import 'package:oflite/modules/product/domain/usecase/generate_product_catalog_usecase.dart';
import 'package:oflite/modules/product/domain/usecase/save_product_catalog_usecase.dart';
import 'package:oflite/modules/product/presenter/strings/product_pt_string.dart';
import 'package:oflite/shared/design_pattern/command.dart';
import 'package:oflite/shared/design_pattern/result.dart';

/// Estado do modal "ramo de atuação": passo 1 escolhe o ramo e gera a lista
/// com IA; passo 2 revisa e salva. Regra de negócio fica nos UseCases.
class ProductSegmentViewModel extends ChangeNotifier {
  final GenerateProductCatalogUsecase _generate =
      getIt<GenerateProductCatalogUsecase>();
  final SaveProductCatalogUsecase _save = getIt<SaveProductCatalogUsecase>();
  final ConvertCoinRepository _moneyConvert = getIt<ConvertCoinRepository>();

  final TextEditingController customController = TextEditingController();

  BusinessSegment? segment;

  /// Erro inline do passo 1 (§17.4); `null` = sem erro.
  String? validationError;

  /// Lista gerada, em revisão. Vazia = ainda no passo 1.
  List<ProductPriceModel> items = [];

  late final Command0<void> generateCommand = Command0(_executeGenerate);
  late final Command0<void> saveCommand = Command0(_executeSave);
  late final Command0<void> skipCommand = Command0(_save.skip);

  bool get reviewing => items.isNotEmpty;

  bool get busy =>
      generateCommand.running || saveCommand.running || skipCommand.running;

  String get title =>
      reviewing
          ? ProductPtString.segmentReviewTitle
          : ProductPtString.segmentTitle;

  String get buttonLabel =>
      reviewing
          ? ProductPtString.segmentSaveButton(items.length)
          : ProductPtString.segmentGenerateButton;

  String formatPrice(double value) => _moneyConvert.convertFromDouble(value);

  void selectSegment(BusinessSegment value) {
    segment = value;
    validationError = null;
    notifyListeners();
  }

  void removeItem(int index) {
    items = [...items]..removeAt(index);
    notifyListeners();
  }

  /// Botão principal do modal: gera (passo 1) ou salva (passo 2).
  void onPrimaryPressed() {
    if (reviewing) {
      saveCommand.execute();
      return;
    }
    validationError = _validate();
    notifyListeners();
    if (validationError == null) generateCommand.execute();
  }

  String? _validate() {
    if (segment == null) return ProductPtString.segmentRequiredError;
    if (segment == BusinessSegment.other &&
        customController.text.trim().isEmpty) {
      return ProductPtString.segmentCustomRequiredError;
    }
    return null;
  }

  Future<Result<void>> _executeGenerate() async {
    final result = await _generate(
      segment: segment!,
      customName: customController.text,
      languageCode:
          WidgetsBinding.instance.platformDispatcher.locale.languageCode,
    );
    if (result is Ok<List<ProductPriceModel>>) {
      items = result.value;
      notifyListeners();
      return const Result.ok(null);
    }
    return Result.error((result as Error<List<ProductPriceModel>>).error);
  }

  Future<Result<void>> _executeSave() => _save(segment!, items);

  @override
  void dispose() {
    customController.dispose();
    generateCommand.dispose();
    saveCommand.dispose();
    skipCommand.dispose();
    super.dispose();
  }
}
