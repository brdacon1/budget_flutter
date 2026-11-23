import 'package:map_launcher/map_launcher.dart';

/// Contrato para abrir um endereço nos apps de mapa do aparelho.
abstract class MapLauncherRepository {
  /// iOS: apps de mapa instalados prontos para abrir [address];
  /// chame `show()` no escolhido.
  Future<List<SupportedMap>> mapsForAddress(String address);

  /// Android: abre o seletor nativo do sistema. `false` se nenhum app abriu.
  Future<bool> openWithSystemChooser(String address);
}
