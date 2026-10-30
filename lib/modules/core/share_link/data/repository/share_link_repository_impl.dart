import 'package:oflite/modules/core/share_link/domain/repository/share_link_repository.dart';
import 'package:oflite/modules/core/share_link/data/datasource/share_link_datasource.dart';

/// Implementação do repositório de link de compartilhamento.
class ShareLinkRepositoryImpl implements ShareLinkRepository {
  static const String webBaseUrl = String.fromEnvironment(
    'BUDGET_WEB_BASE_URL',
    defaultValue: 'https://orcamentofacil-lite.web.app',
  );

  final ShareLinkDataSource _dataSource;

  ShareLinkRepositoryImpl(this._dataSource);

  @override
  Future<String?> buildShareUrl({required String enderecoNumero}) async {
    final token = await _dataSource.getCurrentUserToken();
    if (token == null || token.isEmpty) return null;

    final base = webBaseUrl.replaceAll(RegExp(r'/+$'), '');
    return '$base/orcamento/$enderecoNumero?token=$token';
  }
}
