import 'package:flutter/foundation.dart';
import 'package:oflite/modules/auth/data/datasource/user_remote_datasource.dart';
import 'package:oflite/modules/auth/data/model/info_user.dart';
import 'package:oflite/modules/auth/data/model/owner_pdf.dart';
import 'package:oflite/modules/auth/domain/repository/user_repository.dart';
import 'package:oflite/shared/design_pattern/result.dart';

class UserRepositoryImpl extends UserRepository {
  final UserRemoteDataSource _remote;

  UserRepositoryImpl(this._remote);

  InfoUser? _currentUser;
  OwnerPdf? _defaultPdf;

  final ValueNotifier<InfoUser?> _selectUser = ValueNotifier<InfoUser?>(null);

  @override
  ValueNotifier<InfoUser?> get selectUser => _selectUser;

  @override
  set selectUser(ValueNotifier<InfoUser?> value) {
    _selectUser.value = value.value;
  }

  @override
  InfoUser? get currentUser => _currentUser;

  @override
  OwnerPdf? get defaultPdf => _defaultPdf;

  @override
  Future<Result<InfoUser?>> getUserInfo(String userUid) async {
    try {
      final raw = await _remote.getUserInfo(userUid);
      if (raw == null) {
        return const Result.ok(null);
      }
      final user =
          InfoUser()
            ..user = raw['USER']
            ..name = raw['NOME']
            ..email = raw['EMAIL']
            ..phone = raw['FONE']
            ..id = raw['Id']
            ..idPay = raw['IdPay']
            ..productId = raw['ProductId']
            ..purchaseToken = raw['PurchaseToken']
            ..autoRenewing = raw['AutoRenewing'] ?? false;
      final trial = raw['TrialStartedAt'];
      if (trial is int) {
        user.trialStartedAt = DateTime.fromMillisecondsSinceEpoch(trial);
      }

      _currentUser = user;
      _selectUser.value = user;
      notifyListeners();
      return Result.ok(user);
    } catch (e) {
      return Result.error(Exception(e.toString()));
    }
  }

  @override
  Future<Result<void>> saveUser(InfoUser user) async {
    try {
      await _remote.saveUser(user);
      _currentUser = user;
      _selectUser.value = user;
      notifyListeners();
      return const Result.ok(null);
    } catch (e) {
      return Result.error(Exception(e.toString()));
    }
  }

  @override
  Future<Result<void>> updateUser(InfoUser user) async {
    try {
      await _remote.updateUser(user);
      _currentUser = user;
      _selectUser.value = user;
      notifyListeners();
      return const Result.ok(null);
    } catch (e) {
      return Result.error(Exception(e.toString()));
    }
  }

  @override
  Future<Result<void>> createDefaultUserData(
    InfoUser user,
    OwnerPdf pdf,
  ) async {
    try {
      await _remote.saveUser(user);
      await _remote.savePdfInfo(pdf, user.user ?? '');
      _currentUser = user;
      _selectUser.value = user;
      _defaultPdf = pdf;
      await syncTrial(user.user ?? '');
      notifyListeners();
      return const Result.ok(null);
    } catch (e) {
      return Result.error(Exception(e.toString()));
    }
  }

  @override
  Future<void> syncTrial(String uid) async {
    try {
      final r = await _remote.syncTrial(uid);
      final user = _selectUser.value;
      if (r == null || user == null) return;
      user.trialStartedAt = DateTime.fromMillisecondsSinceEpoch(
        r.trialStartedAt,
      );
      user.serverClockOffset = DateTime.fromMillisecondsSinceEpoch(
        r.serverNow,
      ).difference(DateTime.now());
      notifyListeners();
    } catch (_) {
      // Offline/permissão: segue sem bloquear (fail-open).
    }
  }

  @override
  Future<Result<String>> getIdToken() async {
    try {
      final token = await _remote.getIdToken();
      return Result.ok(token);
    } catch (e) {
      return Result.error(Exception(e.toString()));
    }
  }
}
