import 'package:flutter/foundation.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:oflite/modules/auth/data/model/info_user.dart';
import 'package:oflite/modules/auth/domain/repository/user_repository.dart';
import 'package:oflite/modules/auth/domain/usecase/get_access_status_usecase.dart';

class _FakeUserRepo extends ChangeNotifier implements UserRepository {
  _FakeUserRepo(InfoUser? u) : selectUser = ValueNotifier(u);
  @override
  ValueNotifier<InfoUser?> selectUser;
  @override
  dynamic noSuchMethod(Invocation i) => super.noSuchMethod(i);
}

void main() {
  bool off() => false;
  GetAccessStatusUseCase build(InfoUser? u) =>
      GetAccessStatusUseCase(_FakeUserRepo(u), forcePremium: off);

  test('assinante é premium mesmo com trial vencido', () {
    final u =
        InfoUser()
          ..autoRenewing = true
          ..trialStartedAt = DateTime.now().subtract(const Duration(days: 9));
    expect(build(u)(), AccessStatus.premium);
  });

  test('dentro de 2 dias é trial com acesso total', () {
    final u =
        InfoUser()
          ..trialStartedAt = DateTime.now().subtract(const Duration(hours: 47));
    expect(build(u)(), AccessStatus.trial);
    expect(build(u).hasFullAccess, isTrue);
  });

  test('após 2 dias expira', () {
    final u =
        InfoUser()
          ..trialStartedAt = DateTime.now().subtract(const Duration(hours: 49));
    expect(build(u)(), AccessStatus.expired);
    expect(build(u).hasFullAccess, isFalse);
  });

  test('offset do servidor vale mais que o relógio do aparelho', () {
    // Aparelho adiantado 3 dias, mas o servidor diz que ainda é o início.
    final u =
        InfoUser()
          ..trialStartedAt = DateTime.now().subtract(const Duration(days: 3))
          ..serverClockOffset = const Duration(days: -3);
    expect(build(u)(), AccessStatus.trial);
  });

  test('sem sync (offline) nunca bloqueia', () {
    expect(build(InfoUser())(), AccessStatus.trial);
    expect(build(null)(), AccessStatus.trial);
  });

  test('FORCE_PREMIUM libera', () {
    final u =
        InfoUser()
          ..trialStartedAt = DateTime.now().subtract(const Duration(days: 9));
    expect(
      GetAccessStatusUseCase(_FakeUserRepo(u), forcePremium: () => true)(),
      AccessStatus.premium,
    );
  });
}
