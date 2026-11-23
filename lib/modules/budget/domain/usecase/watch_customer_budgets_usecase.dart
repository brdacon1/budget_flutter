import 'package:oflite/modules/budget/data/model/customer_info_model.dart';
import 'package:oflite/modules/budget/domain/repository/budget_repository.dart';
import 'package:oflite/shared/design_pattern/result.dart';

/// Orçamentos do mesmo cliente (mesmo telefone), em tempo real e do mais
/// novo para o mais antigo.
///
/// FONE é salvo com máscara `(##) #####-####`, mas pode vir só com dígitos
/// (chat) ou ser fixo: consulta todos os formatos e confere pelos dígitos.
class WatchCustomerBudgetsUsecase {
  final BudgetRepository _repo;

  const WatchCustomerBudgetsUsecase(this._repo);

  Stream<Result<List<CustomerInfo>>> call(String phone) {
    final digits = _digits(phone);
    return _repo
        .watchBudgetsByPhone(_variants(phone.trim(), digits))
        .map(
          (result) => switch (result) {
            Ok(:final value) => Result.ok(
              value.where((b) => _digits(b.phone ?? '') == digits).toList()
                ..sort((a, b) => (b.id ?? '').compareTo(a.id ?? '')),
            ),
            Error() => result,
          },
        );
  }

  /// Só os dígitos, sem DDI 55 (quando vem com DDI).
  static String _digits(String s) {
    final d = s.replaceAll(RegExp(r'[^0-9]'), '');
    return d.length > 11 && d.startsWith('55') ? d.substring(2) : d;
  }

  /// Formatos em que o mesmo telefone pode estar gravado. O texto exato do
  /// orçamento de origem entra sempre. `whereIn` aceita até 30 valores.
  static List<String> _variants(String raw, String d) {
    final out = <String>{raw, d, '55$d', '+55$d'};
    if (d.length == 11 || d.length == 10) {
      final ddd = d.substring(0, 2);
      final split = d.length == 11 ? 7 : 6;
      final a = d.substring(2, split);
      final b = d.substring(split);
      for (final local in ['$a-$b', '$a$b', '$a $b']) {
        out.addAll([
          '($ddd) $local',
          '($ddd)$local',
          '$ddd $local',
          '+55 ($ddd) $local',
          '+55 $ddd $local',
        ]);
      }
      if (d.length == 11) {
        out.add('($ddd) ${a[0]} ${a.substring(1)}-$b');
        out.add('+55 $ddd ${a[0]} ${a.substring(1)}-$b');
      }
    }
    return out.take(30).toList();
  }
}
