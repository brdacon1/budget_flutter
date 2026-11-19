# Plano — Login com Apple + melhorias da tela de login

> Segue `.pi/ARCHITECTURE.md` (ponytail, MVVM, chamada externa só no DataSource,
> regra de negócio = UseCase, nenhum widget privado na View).

## 0. Diagnóstico do código atual

| Ponto | Onde | Problema |
|---|---|---|
| `FirebaseAuth.instance` e `GoogleSignIn.instance` direto na VM | `login_view_model.dart` | Viola "chamada externa só no DataSource". O Apple entra já no lugar certo e aproveitamos para mover Google/email junto. |
| Vínculo do usuário social (`_signInWithCredential` + `_createUserWithGoogle`) | VM | Regra de negócio → vira UseCase reutilizado por Google **e** Apple. |
| Auto-login mostra a tela de login clicável | `_checkAutoLogin` espera `authStateChanges().first` (até 5s) **antes** de emitir `loading` | Usuário consegue tocar nos botões nesse intervalo. |
| Modal de loading preso ao cancelar Google | `_performLogin` → `_LoginCancelledException` → `state = idle`; `_onViewModelChanged` só fecha o loading em `success`/`error` | Em `idle` ninguém chama `closeLoading` → dialog fica eterno. |

## 1. Dependências e configuração nativa

1. `pubspec.yaml`: adicionar `sign_in_with_apple` (gera nonce/credencial Apple).
2. Xcode › Runner › Signing & Capabilities: **Sign in with Apple** em Debug e
   Release → confere `com.apple.developer.applesignin` em
   `ios/Runner/Runner.entitlements` e `RunnerRelease.entitlements`.
3. Apple Developer: habilitar a capability no App ID.
4. Firebase Console › Authentication › Sign-in method: habilitar **Apple**
   (no iOS nativo não precisa de Service ID/chave; só o bundle id).
5. Asset: `assets/png/apple_logo.png` (logo branco/preto conforme guideline) no `pubspec.yaml`.

## 2. Camada de dados (auth)

### 2.1 `data/datasource/auth_remote_datasource.dart` (novo)
Único lugar que conhece `FirebaseAuth`, `GoogleSignIn` e `SignInWithApple`.
Retorna `UserCredential`/primitivos, lança exceções técnicas.

```dart
class AuthRemoteDataSource {
  AuthRemoteDataSource({FirebaseAuth? auth}) : _auth = auth ?? FirebaseAuth.instance;
  final FirebaseAuth _auth;

  User? get currentUser => _auth.currentUser;
  Future<User?> restoreSession() => _auth.authStateChanges().first
      .timeout(const Duration(seconds: 5), onTimeout: () => null);

  Future<UserCredential> signInWithEmail(String email, String password);
  Future<UserCredential> signInWithGoogle();   // código atual de _signInWithGoogle
  Future<UserCredential> signInWithApple();    // ver abaixo
}
```

`signInWithApple()`:
```dart
final rawNonce = generateNonce();
final apple = await SignInWithApple.getAppleIDCredential(
  scopes: [AppleIDAuthorizationScopes.email, AppleIDAuthorizationScopes.fullName],
  nonce: sha256.convert(utf8.encode(rawNonce)).toString(),
);
final credential = OAuthProvider('apple.com').credential(
  idToken: apple.identityToken, rawNonce: rawNonce, accessToken: apple.authorizationCode,
);
final result = await _auth.signInWithCredential(credential);
// Apple só manda o nome na 1ª autorização → grava no perfil do Firebase
final name = [apple.givenName, apple.familyName].whereType<String>().join(' ');
if (name.isNotEmpty && (result.user?.displayName ?? '').isEmpty) {
  await result.user?.updateDisplayName(name);
}
return result;
```
Cancelamento: `SignInWithAppleAuthorizationException` com
`code == AuthorizationErrorCode.canceled` → relança como `AuthCancelledException`
(mesma exceção usada pelo Google `canceled`). Exceção pública em
`domain/exception/auth_cancelled_exception.dart`, substitui `_LoginCancelledException`.

### 2.2 `domain/repository/auth_repository.dart` + `data/repository/auth_repository_impl.dart`
Repasse fino do datasource (`currentUser`, `restoreSession`, `signInWithEmail`,
`signInWithGoogle`, `signInWithApple`). Registrar em `auth_binds.dart`.

## 3. Regra de negócio (UseCases)

### 3.1 `domain/usecase/sign_in_social_usecase.dart`
Extrai `_signInWithCredential` + `_createUserWithGoogle` da VM, recebendo o
provider:

```dart
enum SocialProvider { google, apple }   // valor nunca persistido

Future<InfoUser> call(SocialProvider provider) async {
  final auth = provider == SocialProvider.apple
      ? await _authRepository.signInWithApple()
      : await _authRepository.signInWithGoogle();
  // salva prefs email + 'NO_PASS'; monta sessão googleAuth = true; busca getUserInfo;
  // se não existir doc → createDefaultUserData + saveInformationEnterprise (igual hoje)
}
```

**Vínculo com usuário existente — igual ao Google hoje:**
- Login é sempre por `uid` do Firebase. Se a conta Apple usa o mesmo e-mail de
  uma conta Google/e-mail já existente, o Firebase (config padrão *"uma conta
  por e-mail"*) retorna `account-exists-with-different-credential`; hoje esse
  caso cai em `loginErrorDefault` no Google também → **mantemos o mesmo
  comportamento** (mesma snack).
- Doc do Firestore inexistente para o `uid` → cria dados padrão (fluxo atual).
- Persistência: **não** criamos valor novo em prefs/Firestore. Apple usa
  `password = 'NO_PASS'` e `googleAuth = true` (flag significa "login social,
  sem senha" para o resto do app — auto-login, troca de senha, etc.). Regra
  Zero: nenhum dado persistido muda.
- "Ocultar meu e-mail" da Apple → e-mail `@privaterelay.appleid.com` é salvo
  como vem.

### 3.2 `domain/usecase/restore_session_usecase.dart`
Move a lógica de `_checkAutoLogin` (sessão Firebase → fallback e-mail/senha
salvos) e devolve `InfoUser?`. `_getUserInfo` (assinatura, FCM, crashlytics)
vira `load_user_session_usecase.dart`, reutilizado pelos 3 logins.

> Se quiser o menor diff possível, 3.2 pode ficar para depois — o essencial
> para o Apple é 2.1 + 3.1. Recomendo fazer junto porque a melhoria 1 mexe
> exatamente nesse código.

## 4. Presenter

### 4.1 `LoginViewModel`
- Remove `FirebaseAuth`/`GoogleSignIn`; injeta os usecases.
- `bool get showAppleLogin => !kIsWeb && (Platform.isIOS || Platform.isMacOS);`
- `loginWithApple()` → `_performLogin(() => _signInSocial(SocialProvider.apple))`.
- `_performLogin` trata `SignInWithAppleAuthorizationException` (≠ canceled) →
  `LoginStrings.loginErrorAppleDefault`; `AuthCancelledException` → `idle`.
- Novo estado `LoginState.checkingSession` (ver 5).

### 4.2 Botões lado a lado
- `components/login_apple_button.dart` (novo, público): mesmo estilo do
  `LoginGoogleButton` (fundo branco, raio 26, vertical 15, `heebo` bold 16),
  logo Apple + `LoginStrings.loginWithApple`.
- Em `login_tab.dart` trocar a linha 66:

```dart
viewModel.showAppleLogin
    ? Row(children: [
        Expanded(child: LoginAppleButton(onPressed: onAppleLogin)),
        const SizedBox(width: 10),
        Expanded(child: LoginGoogleButton(onPressed: onGoogleLogin)),
      ])
    : LoginGoogleButton(onPressed: onGoogleLogin),
```
- Android: exatamente como hoje. Padding lateral continua o do
  `SingleChildScrollView` (16).
- Ao dividir, o texto fica estreito → nos dois botões usar `Flexible` +
  `FittedBox(fit: BoxFit.scaleDown)` no texto, ou label curto ("Apple" /
  "Google"). Decidir no review visual.
- Strings novas em `login_pt_string.dart` (+ en se já houver i18n):
  `loginWithApple`, `loginErrorAppleDefault`.

### 4.3 Gestão de erro
Sem mudança: `state = error` + `errorMessage` →
`_displayAlert.notificationError(context, LoginStrings.errorTitle, message)`.

## 5. Melhoria 1 — tela "verificando sessão" sem cliques

Fluxo:
1. `init()` começa com `state = LoginState.checkingSession` **antes** de
   qualquer `await` (inclusive antes do `InAppPurchase.initConnection`).
2. `RestoreSessionUseCase`:
   - sessão Firebase **ou** e-mail/senha salvos → continua `checkingSession`
     até `success` (navega para `/menu`) ou falha (`idle`, tela normal).
   - nada salvo → `idle` imediatamente.
3. `LoginView.build`: se `state == checkingSession` renderiza
   `components/login_session_loading.dart` (novo): `Scaffold` full com
   `backgroundColor: secondaryColor` e `CircularProgressIndicator` centralizado.
   Nenhum botão existe na árvore → impossível clicar.
4. `_onViewModelChanged` **não** abre o dialog de loading para
   `checkingSession` (a tela já é o loading).

Otimização: se `currentUser == null` e não há e-mail/senha nas prefs, não
esperar os 5s do `authStateChanges` em Android (lá `currentUser` é síncrono);
manter o await só no iOS, onde o Keychain restaura de forma assíncrona.

## 6. Melhoria 2 — modal de loading preso ao cancelar

Causa: cancelamento vira `idle` e a View só fecha o loading em
`success`/`error`.

Correção em `login_view.dart` `_onViewModelChanged`:
```dart
if (state == LoginState.idle) {
  _loadingEvent.closeLoading(context);
  return;
}
```
- Garantir que `closeLoading` só faz `pop` se o dialog estiver aberto (conferir
  `LoadingEventRepository`; se não tiver flag, adicionar `bool _isOpen`) para
  não fazer `pop` da própria tela de login.
- Vale para Google e Apple (ambos lançam `AuthCancelledException`).
- Caso extra: Google no Android às vezes não retorna nada quando o usuário sai
  pelo back → `authenticate()` lança `canceled`/`interrupted`; mapear
  `interrupted` também para cancelado.

## 7. Ordem de implementação

1. Melhoria 2 (fix de 5 linhas, isolado, pode ir em PR separado).
2. `AuthRemoteDataSource` + `AuthRepository` movendo Google/e-mail (sem mudar comportamento).
3. `SignInSocialUseCase`, `LoadUserSessionUseCase`, `RestoreSessionUseCase`.
4. Melhoria 1 (`checkingSession` + `LoginSessionLoading`).
5. Config nativa Apple (Xcode, Developer, Firebase) + `sign_in_with_apple`.
6. `signInWithApple` no datasource + `LoginAppleButton` + Row no `LoginTab`.

## 8. Testes

- Unit: `SignInSocialUseCase` (doc existe → não cria; não existe → cria),
  `RestoreSessionUseCase` (sessão, e-mail salvo, nada salvo), mapeamento de
  cancelamento.
- Manual iOS: Apple 1º login (nome gravado), 2º login (sem nome, mantém),
  cancelar Apple, cancelar Google, "ocultar e-mail", app aberto já logado
  (só spinner, sem botões), erro de rede (snack atual).
- Manual Android: tela idêntica à atual, cancelar Google fecha o modal.
- Review: Apple exige o botão Apple com destaque igual ao Google (guideline
  4.8) — lado a lado com mesmo tamanho atende.
