import 'package:map_launcher/map_launcher.dart';
import 'package:oflite/modules/core/map_launcher/data/datasource/map_launcher_datasource.dart';
import 'package:oflite/modules/core/map_launcher/domain/repository/map_launcher_repository.dart';

class MapLauncherRepositoryImpl implements MapLauncherRepository {
  final MapLauncherDataSource _dataSource;

  MapLauncherRepositoryImpl(this._dataSource);

  @override
  Future<List<SupportedMap>> mapsForAddress(String address) async {
    ({double lat, double lng})? coords;
    try {
      coords = await _dataSource.geocode(address);
    } catch (_) {
      // Sem coordenadas: segue só com Google/Apple (busca por texto).
    }
    return _dataSource.installedMaps(
      address,
      lat: coords?.lat,
      lng: coords?.lng,
    );
  }

  @override
  Future<bool> openWithSystemChooser(String address) async {
    try {
      return await _dataSource.openGeo(address);
    } catch (_) {
      return false;
    }
  }
}
