import 'package:get_it/get_it.dart';
import 'package:oflite/modules/chat_assistant/domain/usecase/receive_shared_proof_usecase.dart';
import 'package:oflite/modules/main_tab/presenter/main_tab_view_model.dart';
import 'package:oflite/modules/pdf/domain/repository/pdf_repository.dart';

/// Registra as dependências do módulo MainTab.
void registerMainTabDependencies(GetIt sl) {
  // ReceiveSharedProofUsecase resolvido na criação do VM (lazy).
  sl.registerFactory<MainTabViewModel>(
    () =>
        MainTabViewModel(sl<ReceiveSharedProofUsecase>(), sl<PdfRepository>()),
  );
}
