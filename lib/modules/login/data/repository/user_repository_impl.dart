import 'package:oflite/modules/login/data/datasource/user_remote_datasource.dart';
import 'package:oflite/modules/login/domain/repository/user_repository.dart';
import 'package:oflite/shared/models/info_user.dart';
import 'package:oflite/shared/models/owner_pdf.dart';
import 'package:oflite/shared/models/global_uid_user.dart' as uid;
import 'package:oflite/shared/design_pattern/result.dart';

class UserRepositoryImpl extends UserRepository {
  final UserRemoteDataSource _remote;
  UserRepositoryImpl(this._remote);

  InfoUser? _currentUser;
  OwnerPdf? _defaultPdf;

  @override
  InfoUser? get currentUser => _currentUser;

  @override
  OwnerPdf? get defaultPdf => _defaultPdf;

  @override
  Future<Result<InfoUser?>> getUserInfo(String userUid) async {
    try {
      final raw = await _remote.getUserInfo(userUid);
      if (raw == null) {
        return Result.ok(null);
      }
      final user = InfoUser()
        ..USER = raw['USER']
        ..NOME = raw['NOME']
        ..EMAIL = raw['EMAIL']
        ..FONE = raw['FONE']
        ..Id = raw['Id']
        ..IdPay = raw['IdPay']
        ..ProductId = raw['ProductId']
        ..PurchaseToken = raw['PurchaseToken']
        ..AutoRenewing = raw['AutoRenewing'] ?? false;

      _currentUser = user;
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
      notifyListeners();
      return Result.ok(null);
    } catch (e) {
      return Result.error(Exception(e.toString()));
    }
  }

  @override
  Future<Result<void>> updateUser(InfoUser user) async {
    try {
      await _remote.updateUser(user);
      _currentUser = user;
      notifyListeners();
      return Result.ok(null);
    } catch (e) {
      return Result.error(Exception(e.toString()));
    }
  }

  @override
  Future<Result<void>> createDefaultUserData(InfoUser user, OwnerPdf pdf) async {
    try {
      await _remote.saveUser(user);
      uid.user = user.USER ?? '';
      uid.name = user.NOME ?? '';
      uid.email = user.EMAIL;
      uid.phone = user.FONE;
      uid.id = user.Id;
      await _remote.savePdfInfo(pdf, uid.user ?? '');
      _currentUser = user;
      _defaultPdf = pdf;
      notifyListeners();
      return Result.ok(null);
    } catch (e) {
      return Result.error(Exception(e.toString()));
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
