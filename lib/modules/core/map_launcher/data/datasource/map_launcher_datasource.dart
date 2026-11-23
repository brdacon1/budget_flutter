import 'package:geocoding/geocoding.dart' as geo;
import 'package:map_launcher/map_launcher.dart';
import 'package:url_launcher/url_launcher.dart';

/// Fala com os apps de mapa do aparelho e com o geocoder nativo.
class MapLauncherDataSource {
  /// Só Google Maps e Apple Maps aceitam busca por texto.
  static const List<MapApp> _searchMaps = [MapApp.google, MapApp.apple];

  /// Apps de mapa do iOS que só abrem por coordenadas.
  static const List<MapApp> _coordsMaps = [
    MapApp.waze,
    MapApp.here,
    MapApp.citymapper,
    MapApp.moovit,
    MapApp.magicEarth,
    MapApp.tomtomgo,
    MapApp.osmand,
    MapApp.mapswithme,
    MapApp.yandexMaps,
    MapApp.yandexNavi,
    MapApp.doubleGis,
    MapApp.copilot,
    MapApp.sygicTruck,
  ];

  /// Geocoder nativo (CLGeocoder no iOS). `null` se não achar o endereço.
  Future<({double lat, double lng})?> geocode(String address) async {
    final found = await geo.Geocoding().locationFromAddress(address);
    if (found.isEmpty) return null;
    return (lat: found.first.latitude, lng: found.first.longitude);
  }

  /// iOS: Google/Apple por texto; demais apps instalados por coordenadas.
  Future<List<SupportedMap>> installedMaps(
    String query, {
    double? lat,
    double? lng,
  }) async {
    final bySearch = await MapLauncher.marker(
      Location.search(query),
    ).getSupportedMaps(_searchMaps);
    final byCoords =
        lat == null || lng == null
            ? <SupportedMap>[]
            : await MapLauncher.directions(
              Location.coords(lat, lng, title: query),
            ).getSupportedMaps(_coordsMaps);
    // Apple Maps sempre existe no iOS; os demais só se estiverem instalados.
    return [
      ...bySearch,
      ...byCoords,
    ].where((m) => m.isInstalled || m.map == MapApp.apple).toList();
  }

  /// Android: intent `geo:` — o sistema mostra o seletor nativo de apps.
  Future<bool> openGeo(String query) => launchUrl(
    Uri.parse('geo:0,0?q=${Uri.encodeComponent(query)}'),
    mode: LaunchMode.externalApplication,
  );
}
