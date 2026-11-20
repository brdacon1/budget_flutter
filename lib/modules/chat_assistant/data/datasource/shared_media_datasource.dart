import 'package:receive_sharing_intent/receive_sharing_intent.dart';

/// Arquivos recebidos pela folha de compartilhamento do sistema
/// (intent filters no Android, Share Extension no iOS).
class SharedMediaDatasource {
  ReceiveSharingIntent get _api => ReceiveSharingIntent.instance;

  List<({String path, String? mime})> _map(List<SharedMediaFile> files) => [
    for (final f in files)
      if (f.type == SharedMediaType.image || f.type == SharedMediaType.file)
        (path: f.path, mime: f.mimeType),
  ];

  Future<List<({String path, String? mime})>> initialMedia() async =>
      _map(await _api.getInitialMedia());

  Stream<List<({String path, String? mime})>> mediaStream() =>
      _api.getMediaStream().map(_map);

  Future<void> reset() async => _api.reset();
}
