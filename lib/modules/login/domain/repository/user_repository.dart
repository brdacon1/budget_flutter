import 'package:flutter/foundation.dart';
import 'package:oflite/modules/login/data/model/info_user.dart';
import 'package:oflite/modules/login/data/model/owner_pdf.dart';
import 'package:oflite/shared/design_pattern/result.dart';

abstract class UserRepository extends ChangeNotifier {
  InfoUser? get currentUser;
  OwnerPdf? get defaultPdf;

  ValueNotifier<InfoUser?> get selectUser;
  set selectUser(ValueNotifier<InfoUser?> value);

  Future<Result<InfoUser?>> getUserInfo(String uid);
  Future<Result<void>> saveUser(InfoUser user);
  Future<Result<void>> updateUser(InfoUser user);
  Future<Result<void>> createDefaultUserData(InfoUser user, OwnerPdf pdf);
  Future<Result<String>> getIdToken();
}
