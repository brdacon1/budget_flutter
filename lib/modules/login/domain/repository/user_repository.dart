import 'package:flutter/foundation.dart';
import 'package:oflite/shared/models/info_user.dart';
import 'package:oflite/shared/models/owner_pdf.dart';
import 'package:oflite/shared/design_pattern/result.dart';

abstract class UserRepository extends ChangeNotifier {
  InfoUser? get currentUser;
  OwnerPdf? get defaultPdf;

  Future<Result<InfoUser?>> getUserInfo(String uid);
  Future<Result<void>> saveUser(InfoUser user);
  Future<Result<void>> updateUser(InfoUser user);
  Future<Result<void>> createDefaultUserData(InfoUser user, OwnerPdf pdf);
  Future<Result<String>> getIdToken();
}
