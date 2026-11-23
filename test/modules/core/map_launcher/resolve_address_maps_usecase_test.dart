import 'package:flutter_test/flutter_test.dart';
import 'package:map_launcher/map_launcher.dart';
import 'package:oflite/modules/core/map_launcher/domain/repository/map_launcher_repository.dart';
import 'package:oflite/modules/core/map_launcher/domain/usecase/resolve_address_maps_usecase.dart';

class _FakeRepo implements MapLauncherRepository {
  bool chooserOk = true;
  List<SupportedMap> maps = const [];

  @override
  Future<List<SupportedMap>> mapsForAddress(String address) async => maps;

  @override
  Future<bool> openWithSystemChooser(String address) async => chooserOk;
}

void main() {
  test('endereço vazio → indisponível', () async {
    final r = await ResolveAddressMapsUsecase(_FakeRepo(), isAndroid: true)(
      '  ',
    );
    expect(r, isA<AddressMapsUnavailable>());
  });

  test('Android: seletor do sistema abriu', () async {
    final r = await ResolveAddressMapsUsecase(_FakeRepo(), isAndroid: true)(
      'Rua A',
    );
    expect(r, isA<AddressMapsOpenedBySystem>());
  });

  test('Android: nenhum app abriu → indisponível', () async {
    final repo = _FakeRepo()..chooserOk = false;
    final r = await ResolveAddressMapsUsecase(repo, isAndroid: true)('Rua A');
    expect(r, isA<AddressMapsUnavailable>());
  });

  test('iOS: sem apps → indisponível', () async {
    final r = await ResolveAddressMapsUsecase(_FakeRepo(), isAndroid: false)(
      'Rua A',
    );
    expect(r, isA<AddressMapsUnavailable>());
  });
}
