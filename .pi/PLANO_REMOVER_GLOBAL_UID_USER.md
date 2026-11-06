# Plano de Implementação — Remoção do `global_uid_user.dart`

> **Objetivo:** Eliminar `lib/shared/common/constants/global_uid_user.dart` e centralizar o estado do usuário logado em `lib/modules/login/data/repository/user_repository_impl.dart`, seguindo o mesmo padrão `ValueNotifier` do `selectTableEntity`.
> **Regra de Ouro:** Ponytail — o menor diff completo que resolve o problema. Não criar novos models se `InfoUser` já cobre os campos.

---

## 0. Resumo da Mudança Arquitetural

| Antes (`global_uid_user`) | Depois (`UserRepositoryImpl`) |
|---------------------------|------------------------------|
| Variáveis globais soltas em arquivo `library` | `ValueNotifier<InfoUser?> selectUser` encapsulado no repositório |
| DataSources importam global para montar path Firestore | DataSources recebem `String userUid` por parâmetro |
| ViewModels acessam `UID.user`, `UID.autoRenewing`, etc. | ViewModels acessam `getIt<UserRepository>().selectUser.value?.USER`, etc. |
| LoginViewModel escreve direto no global | LoginViewModel atualiza `getIt<UserRepository>().selectUser.value = user` |

---

## 1. Fase 1 — Fundação (`login` module)

### 1.1 `lib/modules/login/domain/repository/user_repository.dart`

Adicionar ao `abstract class UserRepository`:

```dart
  ValueNotifier<InfoUser?> get selectUser;
  set selectUser(ValueNotifier<InfoUser?> value);
```

### 1.2 `lib/modules/login/data/repository/user_repository_impl.dart`

- **Remover** `import 'package:oflite/shared/common/constants/global_uid_user.dart' as uid;`
- Adicionar no corpo da classe:

```dart
  ValueNotifier<InfoUser?> _selectUser = ValueNotifier<InfoUser?>(null);

  @override
  ValueNotifier<InfoUser?> get selectUser => _selectUser;

  @override
  set selectUser(ValueNotifier<InfoUser?> value) {
    _selectUser.value = value.value;
  }
```

- Em `getUserInfo`, `saveUser`, `updateUser`, `createDefaultUserData`: após atualizar `_currentUser`, sincronizar `_selectUser.value = _currentUser`.

### 1.3 `lib/modules/login/presenter/login_view_model.dart`

- **Remover** todo import de `global_uid_user.dart`.
- Substituir **todas** atribuições `global_uid_user.xxx = yyy` por atribuições no `ValueNotifier` via `_userRepository.selectUser.value = ...`
- Como `InfoUser` já tem todos os campos (`USER`, `NOME`, `EMAIL`, `FONE`, `Id`, `IdPay`, `ProductId`, `PurchaseToken`, `AutoRenewing`, `googleAuth`, `TOKENS`), basta montar o objeto e atribuir.

**Exemplo de transformação:**

```dart
// ANTES
final prefs = await SharedPreferences.getInstance();
final storedPassword = prefs.getString('password');
final isGoogle = storedPassword == null || storedPassword == 'NO_PASS';
global_uid_user.user = uid;
global_uid_user.name = currentUser.displayName ?? 'User';
global_uid_user.password = isGoogle ? 'NO_PASS' : storedPassword;
global_uid_user.googleAuth = isGoogle;
global_uid_user.email = currentUser.email ?? prefs.getString('email') ?? '';

// DEPOIS
final prefs = await SharedPreferences.getInstance();
final storedPassword = prefs.getString('password');
final isGoogle = storedPassword == null || storedPassword == 'NO_PASS';
final session = InfoUser()
  ..USER = uid
  ..NOME = currentUser.displayName ?? 'User'
  ..Senha = isGoogle ? 'NO_PASS' : storedPassword
  ..googleAuth = isGoogle
  ..EMAIL = currentUser.email ?? prefs.getString('email') ?? '';
_userRepository.selectUser.value = session;
```

> **Nota:** O campo `password` no `InfoUser` é `Senha`. No `global_uid_user` é `password`. Usar `Senha` (modelo existente) ou manter consistência com o que já existe no `InfoUser`.

- Em `_getUserInfo()`: após carregar `InfoUser` do Firestore, atribuir `_userRepository.selectUser.value = user` (já será feito no repository, mas garantir sync).
- Em `_createUserWithGoogle`: após `createDefaultUserData`, o `selectUser` já deve estar populado pelo repository.

---

## 2. Fase 2 — DataSources (remover import `global_uid_user`)

Todos os DataSources abaixo usam `UID.user` para interpolar path do Firestore. A regra do projeto diz: **DataSource não conhece repository/domínio**. Portanto, recebem `userUid` via parâmetro de método (ou do construtor, se o path for usado em todos os métodos).

### 2.1 `lib/modules/budget/data/datasource/budget_remote_datasource.dart`

- **Remover** import de `global_uid_user.dart`.
- Adicionar `required String userUid` nos métodos que montam collection path.
- Exemplo:

```dart
CollectionReference _budgetsCollection(String userUid) =>
    _firestore.collection('EMPRESAS/$userUid/USERS/$userUid/ORCAMENTOS');
```

- Atualizar `getBudgets()`, `getBudgetById(String id)`, `saveBudget(...)` etc. para receber e repassar `userUid`.

### 2.2 `lib/modules/chat_assistant/data/datasource/chat_script_remote_datasource.dart`

- Remover import `UID`.
- Método que usa path recebe `String userUid`.

### 2.3 `lib/modules/chat_assistant/data/datasource/chat_budget_remote_datasource.dart`

- Remover import `UID`.
- Receber `String userUid` nos métodos de message/session.

### 2.4 `lib/modules/comment/data/datasource/comment_remote_datasource.dart`

- Remover import `UID`.
- Receber `String userUid` e `String budgetId`.

### 2.5 `lib/modules/payment/data/datasource/payment_remote_datasource.dart`

- Remover import `UID`.
- Receber `String userUid`, `String budgetId`, `String receiptId`.

### 2.6 `lib/modules/pdf/data/datasource/pdf_remote_datasource.dart`

- Remover import `UID`.
- Receber `String userUid`.

### 2.7 `lib/modules/product/data/datasource/product_price_remote_datasource.dart`

- Remover import `UID`.
- Receber `String userUid`.

### 2.8 `lib/modules/receipt/data/datasource/receipt_remote_datasource.dart`

- Remover import `UID`.
- Receber `String userUid` e `String budgetId`.

### 2.9 `lib/modules/core/notification/data/datasource/notification_remote_datasource.dart`

- Verificar se usa `UID.user`. Se sim, receber `String userUid` nos métodos afetados.

---

## 3. Fase 3 — Repositories que encapsulam os DataSources da Fase 2

Esses repositories precisam:
1. Pegar o `userUid` de `getIt<UserRepository>().selectUser.value?.USER` **ou** do parâmetro que recebem.
2. Passar para o DataSource.

> **Cuidado:** se o repository não tiver acesso ao `getIt` atualmente, avaliar injetar `UserRepository` ou receber o `userUid` do ViewModel/UseCase. A regra ponytail prefere **passar o `userUid` do ViewModel** quando já está disponível, evitando esconder dependência.

Arquivos a verificar (listados no grep):
- `budget/data/repository/budget_repository_impl.dart`
- `chat_assistant/...` (se houver repository)
- `comment/data/repository/...`
- `payment/data/repository/...`
- `pdf/data/repository/pdf_repository_impl.dart` ou usecases
- `product/data/repository/...`
- `receipt/data/repository/...`

---

## 4. Fase 4 — Módulos `core` e features diversas

### 4.1 `lib/modules/core/display_alert/data/repository/display_alert_repository_impl.dart`

- **Remover** import `global_uid_user.dart`.
- **Injetar** `UserRepository` no construtor (ou usar `getIt<UserRepository>()` se já usar `getIt` no arquivo).
- No `dialogChangeName`:

```dart
final session = _userRepository.selectUser.value;
if (session == null) return;
DADOS.AutoRenewing = session.AutoRenewing;
DADOS.EMAIL = session.EMAIL;
DADOS.FONE = session.FONE;
DADOS.Id = session.Id;
DADOS.IdPay = session.IdPay;
DADOS.NOME = name;
DADOS.ProductId = session.ProductId;
DADOS.PurchaseToken = session.PurchaseToken;
DADOS.USER = session.USER;

await getIt<UserRemoteDataSource>().updateUser(DADOS);
// Atualizar nome na sessão
final updated = InfoUser()..USER = session.USER /* ... copiar tudo e trocar NOME */;
_userRepository.selectUser.value = updated;
```

> **Débito técnico:** Este repository chama `UserRemoteDataSource` diretamente (deveria chamar `UserRepository`). Ponytail sugere **não** refatorar isso agora — manter `getIt<UserRemoteDataSource>()` e apenas trocar a origem dos dados de `global_uid_user` para `_userRepository.selectUser.value`.

### 4.2 `lib/modules/core/notification/data/repository/notification_repository_impl.dart`

- **Remover** import `global_uid_user.dart`.
- **Injetar** `UserRepository` no construtor.
- Substituir `uid.user` por `_userRepository.selectUser.value?.USER`.
- Em `tryOpenPendingBudget` e `_openBudget`.
- Verificar `loadFcmTokens` / `persistCurrentTokenToFirebase` — se precisam do ownerUid, receber do caller ou do `selectUser`.

### 4.3 `lib/modules/chat_assistant/presenter/chat_assistant/chat_assistant_view.dart`

- Remover import `UID`.
- Usar `ValueListenableBuilder` ou acessar `getIt<UserRepository>().selectUser.value?.AutoRenewing ?? false`.

### 4.4 `lib/modules/pdf/...` (vários arquivos)

- `pdf_menu/presenter/pdf_menu_view_model.dart`
- `pdf_edit/presenter/pdf_edit_view.dart`
- `pdf_edit/presenter/pdf_edit_view_model.dart`
- `domain/usecase/pdf_generate_professional_usecase.dart`
- `domain/usecase/pdf_generate_budget_usecase.dart`
- `domain/usecase/pdf_generate_receipt_usecase.dart`
- `domain/usecase/pdf_generate_executive_usecase.dart`

**Ações:**
- Remover todos imports `as uid` / `as user_global`.
- Quem precisar de `googleAuth`, `email`, `password`, `name`, `user`, etc., recebe via parâmetro do UseCase ou lê do `UserRepository`.
- **Sugestão ponytail:** adicionar `InfoUser? userSession` como parâmetro nos métodos `patternPDF`/`generatePDF` dos usecases, em vez de fazer os usecases dependerem de `UserRepository`. O ViewModel passa `getIt<UserRepository>().selectUser.value`.

### 4.5 `lib/modules/product/product_price_list/presenter/product_price_list_view_model.dart`

- Remover import `UID`.
- Ler `getIt<UserRepository>().selectUser.value?.AutoRenewing ?? false`.

### 4.6 `lib/modules/image/presenter/image_edit_view_model.dart`

- Remover import `UID`.
- Receber `String userId` via parâmetro no método ou obter do `UserRepository`.

### 4.7 `lib/modules/subscription/presenter/subscription_view_model.dart`

- Remover import `UID`.
- Em vez de `UID.autoRenewing = purchase.isAutoRenewing`, atualizar a sessão via `UserRepository`:

```dart
final session = _userRepository.selectUser.value ?? InfoUser();
session.AutoRenewing = purchase.isAutoRenewing;
session.PurchaseToken = purchase.purchaseToken ?? '';
session.ProductId = purchase.productId;
_userRepository.selectUser.value = session;
```

### 4.8 `lib/modules/dashboard/presenter/components/header.dart`

- Remover import `global_uid_user.dart`.
- Injetar `UserRepository` ou usar `getIt<UserRepository>().selectUser.value?.NOME ?? DashboardStrings.userFallback`.
- Como `ProfileCard` é `StatefulWidget` e lê no `initState`, pode usar `ValueListenableBuilder` no `build` para reagir a mudanças de nome.

### 4.9 `lib/modules/budget/budget_list/presenter/budget_list_view.dart`

- Remover import `UID`.
- Usar `getIt<UserRepository>().selectUser.value?.AutoRenewing ?? false` nos pontos que checam premium.

### 4.10 `lib/modules/main_tab/presenter/main_tab_view.dart`

- Remover import `uid`.
- Substituir `uid.user` por `getIt<UserRepository>().selectUser.value?.USER`.

### 4.11 `lib/modules/singup/presenter/singup_view_model.dart`

- Remover import `globalUIDUser`.
- Verificar se de fato usa alguma variável (o grep mostra apenas import). Se não usar, apenas remover import.

---

## 5. Fase 5 — Limpeza e Validação

### 5.1 Deletar arquivo morto

```bash
rm lib/shared/common/constants/global_uid_user.dart
```

### 5.2 Verificar imports órfãos

```bash
grep -r "global_uid_user\|oflite.globals\|UID\.user\|UID\.id\|UID\.email\|UID\.name\|UID\.phone\|UID\.purchaseToken\|UID\.autoRenewing\|UID\.idPay\|UID\.productId\|UID\.googleAuth\|UID\.tokens\|UID\.password" lib/ --include="*.dart"
```

**Esperado:** zero ocorrências.

### 5.3 Compilação

```bash
flutter analyze
```

### 5.4 Testes manuais críticos

| Fluxo | Validação |
|-------|-----------|
| Login com email/senha | `selectUser` preenchido com dados do Firestore |
| Login com Google | `selectUser` preenchido; `_createUserWithGoogle` popula corretamente |
| Auto-login | `selectUser` restaurado ao abrir app |
| Abrir orçamento (budget) | Path Firestore usa `userUid` do `selectUser` |
| Gerar PDF | Dados do titular lidos do `selectUser` |
| Alterar nome no perfil | `selectUser` atualizado; nome refletido no Header |
| Assinar/Restaurar compra | `AutoRenewing`/`PurchaseToken`/`ProductId` atualizados no `selectUser` |
| Receber notificação push | `tryOpenPendingBudget` lê `USER` do `selectUser` corretamente |
| Logout | `selectUser.value = null` (adicional no `Dashboard/header.dart` ou `LoginViewModel`) |

---

## 6. Detalhe do Padrão `selectUser` no `UserRepositoryImpl`

```dart
class UserRepositoryImpl extends UserRepository {
  final UserRemoteDataSource _remote;
  UserRepositoryImpl(this._remote);

  InfoUser? _currentUser;
  OwnerPdf? _defaultPdf;

  ValueNotifier<InfoUser?> _selectUser = ValueNotifier<InfoUser?>(null);

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
      if (raw == null) return Result.ok(null);
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
      _selectUser.value = user;  // <<< SINCRONIZA
      notifyListeners();
      return Result.ok(user);
    } catch (e) {
      return Result.error(Exception(e.toString()));
    }
  }

  // ... demais métodos seguem mesmo padrão: _selectUser.value = _currentUser;
}
```

---

## 7. Riscos & Mitigações

| Risco | Mitigação |
|-------|-----------|
| `ValueNotifier` não notifica widgets que usavam variável global diretamente | Substituir leituras diretas por `ValueListenableBuilder` ou acessar `.value` no `build`/`didChangeDependencies` |
| DataSources quebram ao perder `UID.user` | Passar `userUid` em **todos** os métodos afetados; compilar com `flutter analyze` |
| UseCases de PDF que leem `uid.googleAuth` e `user_global.name` | Receber `InfoUser? session` como parâmetro no método público do usecase; ViewModel passa `getIt<UserRepository>().selectUser.value` |
| `NotificationRepository` lê `uid.user` em background handler | `firebaseBackgroundHandler` é top-level e não pode usar `getIt`. Manter `pendingBudgetId` e resolver `userUid` no `tryOpenPendingBudget` (que roda em foreground) via `selectUser` |
| `LoginViewModel` muito grande | Não refatorar estrutura do ViewModel agora; apenas trocar atribuições globais por atribuições ao `selectUser` |

---

## 8. Ordem de Execução Recomendada (menor risco)

1. **Criar** `selectUser` no `UserRepository` + `UserRepositoryImpl`.
2. **Adaptar** `LoginViewModel` para popular `selectUser` (único escritor).
3. **Adaptar** `UserRepositoryImpl.createDefaultUserData` para setar `selectUser`.
4. **Adaptar** DataSources que precisam de `userUid` (passar por parâmetro).
5. **Adaptar** Repositories/ViewModels que leem `global_uid_user` em features leaf (dashboard header, pdf edit, subscription, etc.).
6. **Adaptar** `DisplayAlertRepositoryImpl` (cuidado com `UserRemoteDataSource` direto).
7. **Adaptar** `NotificationRepositoryImpl`.
8. **Deletar** `global_uid_user.dart`.
9. **Rodar** `flutter analyze` e corrigir restos.
10. **Testar** login, auto-login, PDF, notificação, alteração de nome.

---

## 9. Checklist Final

- [ ] `global_uid_user.dart` deletado.
- [ ] `flutter analyze` sem erros.
- [ ] Nenhum `grep` por `global_uid_user`, `oflite.globals`, `UID.user`, etc.
- [ ] `selectUser` funciona como `ValueNotifier<InfoUser?>`.
- [ ] Login com email e Google popula `selectUser`.
- [ ] Auto-login restaura `selectUser`.
- [ ] Logout limpa `selectUser.value = null`.
- [ ] DataSources não importam `global_uid_user`.
- [ ] Dashboard mostra nome do usuário.
- [ ] PDFs geram com dados do titular.
- [ ] Notificações abrem orçamento correto.
