import 'package:material_ui/material_ui.dart';
import 'package:oflite/injection.dart';
import 'package:oflite/modules/auth/domain/usecase/change_user_name_usecase.dart';
import 'package:oflite/shared/common/widgets/adaptive/show_app_modal.dart';
import 'package:oflite/shared/common/widgets/modals/change_name_bottom_modal_widget.dart';

/// Abre o modal de trocar o nome do usuário. Retorna o novo nome se salvo,
/// ou `null` se o usuário cancelou.
Future<String?> showChangeNameModal(BuildContext context) {
  final changeUserName = getIt<ChangeUserNameUseCase>();
  return showAppModal<String>(
    context,
    builder: (_) => ChangeNameBottomModalWidget(onSave: changeUserName.call),
  );
}
