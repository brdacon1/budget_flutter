import 'dart:io' show Platform;

import 'package:map_launcher/map_launcher.dart';
import 'package:oflite/modules/core/map_launcher/domain/repository/map_launcher_repository.dart';

/// Resultado de [ResolveAddressMapsUsecase].
sealed class AddressMapsResult {
  const AddressMapsResult();
}

/// Android: o seletor nativo do sistema já abriu.
class AddressMapsOpenedBySystem extends AddressMapsResult {
  const AddressMapsOpenedBySystem();
}

/// iOS: apps de mapa que abrem o endereço; a View escolhe (ou abre o único).
class AddressMapsAvailable extends AddressMapsResult {
  final List<SupportedMap> maps;
  const AddressMapsAvailable(this.maps);
}

/// Nenhum app de mapa conseguiu abrir o endereço.
class AddressMapsUnavailable extends AddressMapsResult {
  const AddressMapsUnavailable();
}

/// Decide como abrir [address] no mapa conforme a plataforma.
/// Android: seletor nativo do sistema. iOS: lista para a action sheet nativa.
class ResolveAddressMapsUsecase {
  final MapLauncherRepository _repository;
  final bool _isAndroid;

  ResolveAddressMapsUsecase(this._repository, {bool? isAndroid})
    : _isAndroid = isAndroid ?? Platform.isAndroid;

  Future<AddressMapsResult> call(String address) async {
    if (address.trim().isEmpty) return const AddressMapsUnavailable();
    if (_isAndroid) {
      final ok = await _repository.openWithSystemChooser(address);
      return ok
          ? const AddressMapsOpenedBySystem()
          : const AddressMapsUnavailable();
    }
    final maps = await _repository.mapsForAddress(address);
    return maps.isEmpty
        ? const AddressMapsUnavailable()
        : AddressMapsAvailable(maps);
  }
}
