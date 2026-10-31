import 'package:flutter/widgets.dart';

/// Textos do módulo Image internacionalizados.
class ImageStrings {
  const ImageStrings._();

  static Locale get _locale =>
      WidgetsBinding.instance.platformDispatcher.locale;

  static String get _code => _locale.languageCode;

  static bool get _isPt => _code == 'pt';

  static String get tooltipUpload =>
      _isPt ? 'Upload' : 'Upload';

  static String get tooltipSave => _isPt ? 'Salvar' : 'Save';

  static String get tooltipCrop =>
      _isPt ? 'Cortar' : 'Crop';

  static String get tooltipDelete =>
      _isPt ? 'Excluir' : 'Delete';

  static String get uploadPrompt => _isPt
      ? 'Selecione a imagem para fazer upload'
      : 'Select the image to upload';

  static String get selectPhotoButton =>
      _isPt ? 'Selecionar foto' : 'Select photo';

  static String get cropImageTitle =>
      _isPt ? 'Cortar imagem' : 'Crop image';

  static String get cropperTitle =>
      _isPt ? 'Cortador' : 'Cropper';
}
