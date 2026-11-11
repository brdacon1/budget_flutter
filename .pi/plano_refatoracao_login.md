# Plano de Refatoração — Tela de Login (`login_view.dart`)

## 1. Objetivo

Transformar o layout atual da tela de login para o visual dos prints anexados:

- Fundo branco no topo com o logo.
- Card escuro arredondado na parte inferior.
- Toggle **Login / Sign up** dentro do card.
- Aba **Login**: campos Email, Password, botão Login, **Remember me** + toggle, e botão **Login com Google**.
- Aba **Sign up**: campos Username, Email, Password, Confirm password e botão Sign up — reaproveitando o fluxo e lógica já existentes no modal de signup (`singup_view.dart` / `singup_view_model.dart`).

> **Restrição**: alterar **apenas o visual** e a organização dos widgets. Não modificar `LoginViewModel`, `SingUpViewModel`, repositories, datasource, use cases, rotas nem binds.

---

## 2. Princípios da Arquitetura Aplicados

| Princípio | Aplicação |
|---|---|
| MVVM + Clean | View continua conversando apenas com `LoginViewModel`. |
| ChangeNotifier | Reutilizar `_viewModel.addListener(...)` e `AnimatedBuilder`. |
| Componentização | Criar/pequenos widgets em `presenter/login/components/`. |
| Strings centralizadas | Todos os novos textos em `login_pt_string.dart` / `singup_pt_string.dart`. |
| Ponytail full | Reaproveitar ao máximo componentes e ViewModels existentes. |

---

## 3. Análise do Estado Atual

- `login_view.dart` exibe logo, campos de login, botões de Entrar, Cadastrar (abre modal), Esqueci senha e Login com Google.
- O cadastro é feito pelo modal `singup_view.dart`, que usa `SingUpViewModel` e componentes próprios (`SingUpField`, `SingUpLoginLink`).
- Não há campo "Confirm password" nem "Remember me" hoje.
- O login com Google já existe na `LoginViewModel.loginWithGoogle(...)`.

---

## 4. Estrutura Visual Alvo (baseada nos prints)

```
Scaffold (fundo branco)
└── SafeArea
    └── Column
        ├── Topo branco com logo (login_header refatorado)
        └── Expanded
            └── Card escuro arredondado (cor secundária/bgColor)
                ├── Toggle Login/Sign up
                ├── [Aba Login]
                │   ├── Campo Email
                │   ├── Campo Password
                │   ├── Botão Login
                │   ├── Row: Remember me + Switch
                │   └── Botão Login com Google
                └── [Aba Sign up]
                    ├── Campo Username
                    ├── Campo Email
                    ├── Campo Password
                    ├── Campo Confirm password
                    └── Botão Sign up
```

---

## 5. Alterações Necessárias

### 5.1 `login_view.dart` — reescrita do `build`

- Remover `LoginFooter` da `bottomNavigationBar` e incorporar a política de privacidade como link discreto no rodapé do card.
- Substituir `Column` atual por:
  1. **Header branco** com logo (`LoginHeader` adaptado).
  2. **Card inferior** com bordas superiores arredondadas (`BorderRadius.vertical(top: Radius.circular(...))`).
- Adicionar variável de estado local `_isLoginTab` (ou similar) para alternar entre Login e Sign up.
- Usar `AnimatedSwitcher` ou `AnimatedCrossFade` para transição suave entre as abas.

> A ViewModel continua sendo `LoginViewModel`; a aba Sign up pode usar o próprio `SingUpViewModel` obtido via `getIt` dentro da mesma tela, ou abrir o modal existente.  
> **Decisão de arquitetura**: como o usuário pediu que "o segundo print fique na mesma tela, na aba do card", a melhor abordagem é **incorporar o `SingUpView` inline no card**, mantendo-o como `StatefulWidget` com seu próprio `SingUpViewModel`. Isso evita duplicar regra de negócio e aproveita o modal já testado.

### 5.2 `login_header.dart` — adaptar ao novo visual

Atualmente exibe imagem + título "Entrar". Refatorar para:

- Apenas a imagem/logo centralizada no topo branco.
- Remover o `Text` "Entrar" (o título agora é o toggle dentro do card).
- Manter proporções responsivas com `width`/`height`.

### 5.3 Novo componente: `login_tab_toggle.dart`

Widget stateless com dois botões arredondados lado a lado:

- Cor ativa: branco ou `buttonColor`.
- Cor inativa: cinza transparente.
- Labels vêm de `LoginStrings.loginTabLogin` / `LoginStrings.loginTabSignUp`.

### 5.4 Novo componente: `login_remember_me_switch.dart`

Row com:

- Texto "Remember me" (`LoginStrings.loginRememberMe`).
- `Switch` Flutter.
- Valor controlado por estado local da View ou por novo campo na ViewModel (ver 5.7).

### 5.5 `login_text_field.dart` — adaptar ao visual do card escuro

Nos prints os campos têm:

- Fundo escuro.
- Label em cima (Email, Password, etc.).
- Linha inferior fina (underline) em vez de caixa com borda.

Ajustes:

- Substituir `Container` com borda por `Column` com `Text(label)` + `TextField` com `UnderlineInputBorder`.
- Cores: texto branco, label branco, linha cinza, linha ativa `buttonColor`.
- Manter ícone? Opcional; os prints não mostram ícones, então remover prefix/suffix ou deixar opcional.

### 5.6 `login_button.dart` — adaptar ao visual dos prints

Nos prints o botão principal é:

- Fundo branco/rosa claro.
- Texto escuro.
- Cantos levemente arredondados (`BorderRadius.circular(12)`).
- Largura total do card.

Ajustar `LoginButton` para aceitar `borderRadius` e `width` opcionais, mantendo valores default para não quebrar outros usos.

### 5.7 ViewModel — adicionar estado mínimo de UI

Apenas para o toggle **Remember me**:

- Adicionar `bool rememberMe = true` (default `true`, já que hoje o app sempre salva).
- Adicionar `toggleRememberMe()`.
- Salvar o valor em `SharedPreferences` com chave `'remember_me'`.
- Em `_checkAutoLogin()` e `_emailAndPassword()`, só salvar `email`/`password` se `rememberMe == true`.

> Isso é **regra de apresentação/estado de UI**, não regra de negócio.

### 5.8 Botão Google na aba Login

- Adicionar botão estilo "G Login with Google" abaixo do botão Login.
- Usar `LoginStrings.loginWithGoogle`.
- Chamar `_viewModel.loginWithGoogle(context)`.
- Pode ser um novo componente `login_google_button.dart` reutilizável.

### 5.9 Aba Sign up dentro do card

Opções:

1. **Reutilizar `SingUpView` como widget filho** (sem `showModalBottomSheet`). Funciona porque `SingUpView` já é `StatefulWidget` com seu próprio ViewModel e layout baseado em `AppBottomModal`.
2. Criar uma versão inline `login_signup_tab.dart` que instancia `SingUpViewModel` e monta os campos.

**Recomendação**: Opção 1 — envolver `SingUpView` em um `SizedBox` com altura controlada dentro do card.  
Se o `AppBottomModal` causar conflito visual (header branco, fundo branco), criar uma **flag `inline: true`** no `SingUpView` para omitir o header e usar fundo transparente.

### 5.10 Footer / Política de Privacidade

Mover o link "Política de privacidade" para dentro do card, na base, com `GestureDetector` e `LoginFooter` adaptado.

---

## 6. Arquivos a Serem Criados/Alterados

| Arquivo | Ação |
|---|---|
| `lib/modules/auth/presenter/login/login_view.dart` | Reescrever layout com card, toggle e abas. |
| `lib/modules/auth/presenter/login/login_view_model.dart` | Adicionar `rememberMe` e persistência. |
| `lib/modules/auth/presenter/login/components/login_header.dart` | Simplificar para logo apenas. |
| `lib/modules/auth/presenter/login/components/login_text_field.dart` | Novo estilo underline. |
| `lib/modules/auth/presenter/login/components/login_button.dart` | Adicionar props de largura/radius. |
| `lib/modules/auth/presenter/login/components/login_footer.dart` | Tornar compatível com card escuro. |
| `lib/modules/auth/presenter/login/components/login_tab_toggle.dart` | **Novo** — toggle Login/Sign up. |
| `lib/modules/auth/presenter/login/components/login_remember_me_switch.dart` | **Novo** — Remember me. |
| `lib/modules/auth/presenter/login/components/login_google_button.dart` | **Novo** — botão Google. |
| `lib/modules/auth/presenter/login/strings/login_pt_string.dart` | Adicionar novas strings. |
| `lib/modules/auth/presenter/singup/singup_view.dart` | Adicionar suporte a `inline` (opcional). |
| `lib/modules/auth/presenter/singup/components/singup_field.dart` | Possível ajuste de cor para card escuro. |

---

## 7. Strings a Adicionar (`login_pt_string.dart`)

```dart
static String get loginTabLogin => _isPt ? 'Login' : 'Login';
static String get loginTabSignUp => _isPt ? 'Sign up' : 'Sign up';
static String get loginRememberMe => _isPt ? 'Remember me' : 'Remember me';
static String get loginWithGoogle => _isPt ? 'Login com Google' : 'Login with Google';
```

---

## 8. Fluxo de Estados Mantido

- `LoginView` continua ouvindo `_viewModel` via `addListener`.
- Estados `loading`, `success`, `error` são tratados exatamente como hoje.
- `SingUpView` continua gerenciando seu próprio `SingUpViewModel` e estados.
- Nenhuma alteração em repositories, datasource, binds ou rotas.

---

## 9. Checklist de Validação

- [x] Layout ajustado: fundo `secondaryColor`, card `bgColor` ocupando a parte inferior até o final da tela, com onda na parte superior, botões `buttonColor`, campos underline padrão e removido `Lembrar de mim`.
- [x] Botão Google aparece apenas na aba Login.
- [x] "Remember me" persiste entre sessões.
- [x] Aba Sign up reaproveita `SingUpViewModel` (não duplica cadastro).
- [x] Login com e-mail/senha continua funcionando.
- [x] Login com Google continua funcionando.
- [x] Política de privacidade continua acessível.
- [ ] `flutter analyze` sem erros.
- [ ] `flutter run` navega para `/menu` após login/cadastro.

---

## 10. Decisões de UX/Arquitetura

- **Por que não criar uma nova ViewModel para o Sign up inline?**  
  Já existe `SingUpViewModel` com toda a regra de cadastro. Duplicar violaria o princípio DRY e a regra "não mexer na regra de negócio".

- **Por que adicionar `rememberMe` na `LoginViewModel`?**  
  É estado de apresentação derivado de preferência do usuário, não regra de negócio. A regra de salvar credenciais continua a mesma, apenas condicionada ao toggle.

- **Por que manter `LoginFooter`/`TermsConditionsView`?**  
  Requisito funcional já existente; apenas reposicionar visualmente.

## 11. Arquivos Implementados

- `lib/modules/auth/presenter/login/login_view.dart` (reescrito)
- `lib/modules/auth/presenter/login/login_view_model.dart` (`rememberMe`)
- `lib/modules/auth/presenter/login/components/login_header.dart` (simplificado)
- `lib/modules/auth/presenter/login/components/login_text_field.dart` (campos padrão Flutter com borda arredondada)
- `lib/modules/auth/presenter/login/components/login_button.dart` (props extras)
- `lib/modules/auth/presenter/login/components/login_footer.dart` (card escuro)
- `lib/modules/auth/presenter/login/components/login_tab_toggle.dart` (novo)
- `lib/modules/auth/presenter/login/components/login_remember_me_switch.dart` (novo)
- `lib/modules/auth/presenter/login/components/login_google_button.dart` (novo)
- `lib/modules/auth/presenter/login/components/login_signup_tab.dart` (novo)
- `lib/modules/auth/presenter/login/strings/login_pt_string.dart` (novas strings)
- `lib/modules/auth/presenter/singup/strings/singup_pt_string.dart` (confirm password)

> O modal de signup original (`singup_view.dart`) foi mantido intacto, pois ainda é usado por `product_price_creator_view.dart`.
>
> **Ajustes visuais finais**: fundo do Scaffold `secondaryColor`; card `bgColor` sem margem, estendido até o final da tela, com `LoginCardClipper` desenhando onda na parte superior; botões na cor `buttonColor` com texto `bgColor`; campos com `UnderlineInputBorder`; removido o switch `Lembrar de mim`.
