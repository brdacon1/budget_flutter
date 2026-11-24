# Plano — Trial 2 dias, sem anúncios, cadastro social e crescimento

> Segue `ARCHITECTURE.md` (MVVM + Clean, ponytail: menor diff completo),
> regras de memória: regra de negócio = UseCase; chamada externa só no
> DataSource; i18n nunca quebra dado persistido; Android tem assinantes
> (mudança zero para eles); componentes em arquivo próprio.

## 0. Análise: por que cadastram e não geram orçamento

**Limite:** não tenho acesso ao Firebase daqui, então NÃO verifiquei o UID
`MBDLpFZWMoVG4pAQWStLU44VNzu1`. Abaixo estão as causas prováveis, achadas no
código. Para confirmar esse usuário: Auth (provedor, data de criação, último
login), Firestore `EMPRESAS/{uid}/USERS/{uid}` (doc existe? `autoRenewing`),
`.../ORCAMENTOS` (vazio?), `.../FCM` (token = abriu o app em algum device).
Doc ausente ou incompleto indica falha no cadastro; doc ok e sem orçamento
indica abandono.

Causas encontradas no código:

1. **O primeiro orçamento cai num pedágio.** `new_budget_gate.dart`: todo
   não-assinante vê o modal "Ver anúncio / Se tornar premium" a cada novo
   orçamento, inclusive o primeiro. É o maior atrito.
2. **IA e biblioteca de comentários bloqueadas** (`CheckAiAccessUsecase`,
   `CheckCommentLibraryAccessUsecase`): o diferencial do app só aparece
   para quem paga. O usuário novo nunca o vê.
3. **Cadastro lento e frágil** (`singup_view_model.dart`): 3 chamadas
   sequenciais depois do `createUser` (`createDefaultUserData`,
   `saveInformationEnterprise`, `CreateSampleProduct`). Se uma falhar, fica
   conta no Auth sem dados e o "tentar de novo" dá `email-already-in-use`.
4. **Cadastro com 4 campos, sem social na aba Cadastrar** (Apple/Google só
   no Login). Telefone fixo `15991111111` gravado para todos.
5. **Sem analytics de produto**: só Crashlytics. Não dá para saber onde o
   funil quebra (`pubspec.yaml` não tem `firebase_analytics`).
6. **Sem guia pós-cadastro**: cai em `/menu` sem CTA "crie seu 1º orçamento".
7. **Teclado**: a `AppKeyboardDismissBar` (44px) ocupa tela em formulários
   (§5 deste plano).

## 1. Trial de 2 dias com acesso total

### Modelo
- Campo `trialStartedAt` (Firestore Timestamp, **server timestamp**) no doc
  do usuário. Relógio do aparelho nunca é usado (evita burlar mudando data).
- Status derivado, nunca persistido: `premium | trial | expired`.
  - `premium` = `autoRenewing == true` (regra atual, intacta).
  - `trial` = não premium e `now_server < trialStartedAt + 2 dias`.
  - `expired` = o resto.
- Android assinantes: nada muda (premium vence o trial).

### Camadas
| Camada | Arquivo (novo/alterado) |
|---|---|
| DataSource | `user_remote_datasource.dart`: `getServerNow()` (via `FieldValue.serverTimestamp` gravado em doc auxiliar ou leitura de `trialStartedAt`), `setTrialStartedIfAbsent(uid)` |
| Repository | `user_repository(+impl)`: expõe `trialStartedAt` no `InfoUser` (novo campo `DateTime? trialStartedAt`) |
| UseCase | **novo** `GetAccessStatusUseCase` (enum `AccessStatus`) — única fonte da regra |
| UseCase | **novo** `StartTrialIfNeededUseCase`: chamado em `LoadUserSessionUseCase` e nos dois cadastros; se doc existe sem `trialStartedAt` e não é premium → grava agora (**migra quem já está no free ao abrir o app**) |
| Substituir | `CheckAiAccessUsecase`, `CheckCommentLibraryAccessUsecase`, `new_budget_gate`, `budget_options_view`, `main_tab_view_model`, demais ~23 usos de `autoRenewing` para decisão de acesso → `GetAccessStatusUseCase().hasFullAccess` (`premium || trial`) |
| Cloud Function / Rules | validar no servidor os recursos caros (IA/`firebase_ai`) com o mesmo cálculo; regras do Firestore impedem o cliente de **alterar** `trialStartedAt` depois de gravado |

### Fim do trial
- Ao logar/abrir o app com `expired`: `RestoreSessionUseCase` / login
  terminam abrindo `SubscriptionView` como tela cheia, com "Restaurar
  compras" e **sem fechar** (botão de sair/trocar conta permanece). Os dados
  do usuário continuam visíveis? Decisão em aberto (ver §7).
- Durante o trial: faixa discreta "Teste grátis: faltam 1d 4h" que abre a
  assinatura. Sem modal bloqueante.
- Uma vez expirado, não recomeça (chave = uid; reinstalar não reseta).

## 2. Remover anúncios mantendo o módulo `core/ads`

- Não apagar `core/ads`, `InterstitialAdService`, binds nem a inicialização
  em `main.dart`.
- Adicionar um flag único `adsEnabled = false` (ex.: `Environment.adMob`
  ou constante no `AdsRepository`) e fazer `showInterstitial()` virar no-op
  e `initialize()` pular o SDK enquanto desligado. Religar = um flag.
- Remover os **pontos de chamada**: `new_budget_gate.dart` (vira só checagem
  de acesso; expirado → assinatura direto), `budget_options_view.dart`,
  `chat_assistant_view_model`, `build_budget_final_actions_usecase`,
  `generate_budget_pdf_from_chat_usecase`, `budget_list_view`.
- Remover a opção "Ver anúncio" de `ads_option_bottom_modal_widget` /
  `DisplayAlert.adsNotification` (ou deixar sem uso; preferir deletar o que
  ficar morto, ponytail).
- Strings: textos de "ver anúncio" saem dos `*_pt_string.dart` e da tela de
  assinatura (benefício "sem anúncios" deixa de ser argumento).

## 3. Cadastro com Google/Apple na aba Cadastrar

- Em `login_signup_tab.dart`: abaixo do botão **Registrar**, a mesma linha
  de `LoginAppleButton` / `LoginGoogleButton` da aba Login, com rótulos
  **"Cadastrar com Apple"** / **"Cadastrar com Google"** (strings pt/en no
  `singup_pt_string.dart`; extrair a linha para componente compartilhado).
- Comportamento (novo `SignUpWithSocialUseCase`, reaproveitando
  `SignInSocialUseCase`):
  - Campos **vazios**: fluxo atual de login social (cria conta/doc se não
    existir).
  - Campos **preenchidos** (nome/e-mail/senha válidos): cria e-mail+senha no
    Firebase **e vincula** a credencial social à mesma conta
    (`linkWithCredential`), um único `uid`, os dois métodos de entrada
    funcionam.
- DataSource: `AuthRemoteDataSource` ganha `linkWithCredential` e obter a
  credencial social sem logar. **Mover `FirebaseAuth` do `SingUpViewModel`
  para o DataSource** (hoje viola a regra "chamada externa só no
  DataSource") e criar `RegisterEmailUseCase`.
- Casos de borda: `credential-already-in-use` → entrar na conta existente
  com aviso; e-mail do Apple privado (relay) é aceito; falha após
  `createUser` → rollback ou **retomada**: se o doc não existe, o próximo
  login completa a criação (idempotente) em vez de erro
  `email-already-in-use`.

## 4. Experiência rápida e sem erro

1. Cadastro: `createUser` → grava doc do usuário (único `await` bloqueante)
   → entra. `saveInformationEnterprise` e `CreateSampleProduct` rodam em
   paralelo/pós-navegação, nunca bloqueiam nem derrubam o cadastro.
2. Pós-cadastro: tela inicial com CTA "Criar meu primeiro orçamento" e
   orçamento de exemplo opcional; teste grátis explicado em uma linha.
3. Remover o telefone fixo; pedir só se necessário (campo opcional depois).
4. Erros do Firebase mapeados para mensagens claras (senha fraca, e-mail
   em uso, sem internet) em `singup_pt_string.dart`; offline não trava.
5. Auditar pelo Crashlytics + analytics os 5 passos mais lentos
   (cold start, login, 1ª lista, abrir criador, gerar PDF) e medir com
   `Stopwatch` → evento `perf_*`.
6. Checklist de QA antes de lançar: cadastro e-mail, Google, Apple, com
   e sem rede, kill do app no meio, reinstalar, troca de conta.

## 5. Teclado nativo (iOS e Android)

Problema: `AppKeyboardDismissBar` (`shared/common/widgets/form/`, usada em
3 telas) ocupa 44px acima do teclado. Solução **global**, um ponto só:

- `MaterialApp.builder`: envolver o app num `GestureDetector(onTap:
  unfocus)` (toque fora do campo fecha o teclado).
- `keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag` em
  todo `ListView/SingleChildScrollView/CustomScrollView` de formulário
  (ou via `ScrollConfiguration`/helper único).
- `textInputAction: TextInputAction.done` nos campos finais (botão "ok"
  nativo do teclado iOS/Android); `next` nos intermediários.
- Android: o botão voltar já fecha o teclado; garantir que `PopScope` das
  telas de formulário não consome esse primeiro "voltar".
- Deletar `AppKeyboardDismissBar` e seus 3 usos + a regra §17.8 do
  `ARCHITECTURE.md` (atualizar o doc).
- Verificar no iOS: a barra de autofill do print 3 (chave/cartão/pin) é do
  sistema; para campos que não são senha, `autofillHints: null` /
  `enableSuggestions` ajustados para ela não aparecer onde não faz sentido.

## 6. Analytics (Firebase Analytics) — saber até onde o usuário vai

- Adicionar `firebase_analytics`. Novo módulo `core/analytics/`
  (SDK externo → tem `data/datasource/`, binds, domain repository),
  `AnalyticsRepository.log(name, params)`; chamado por UseCases/VMs,
  nunca o SDK direto.
- `setUserId(uid)` no login; user properties: `access_status`
  (`trial|premium|expired`), `auth_provider`, `platform`.
- Funil (eventos): `signup_started`, `signup_completed{method}`,
  `signup_failed{reason}`, `first_open_after_signup`,
  `budget_create_started`, `budget_item_added`, `budget_created` (marcar
  `is_first`), `pdf_generated`, `budget_shared`, `chat_ai_used`,
  `paywall_viewed{source}`, `trial_started`, `trial_expired`,
  `purchase_started`, `purchase_completed`, `purchase_cancelled`.
- `logScreenView` automático via `NavigatorObserver` no `app_routes`.
- No console: montar funil `signup_completed → budget_create_started →
  budget_created → pdf_generated` e coorte por `auth_provider`.
- Privacidade: sem e-mail/nome nos parâmetros; atualizar política de
  privacidade e o formulário de dados da App Store/Play.
- Complementos: Crashlytics (já existe), Remote Config para ajustar duração
  do trial e flag de ads sem publicar versão.

## 7. "Melhor preço do mercado"

- **Não vou inventar preços de concorrentes.** Preciso que você passe (ou eu
  pesquiso) os valores atuais de 3-4 apps concorrentes. Comparar marcas
  em publicidade exige dado verificável e atualizado (risco jurídico e de
  loja: Apple/Google rejeitam alegações falsas).
- Onde mostrar: (a) `SubscriptionView` — card "Quanto custa em outros apps"
  com tabela simples e preço por mês do OFLite destacado; (b) faixa curta do
  trial ("2 dias grátis, depois o menor preço do mercado"); (c) ficha das
  lojas. Preços vêm de `Remote Config` para atualizar sem release.
- Texto/strings pt+en, componente próprio em
  `subscription/presenter/components/`.

## 8. Ordem de execução (cada etapa publicável sozinha)

1. Analytics (§6) — **primeiro**, para medir o antes/depois.
2. Teclado nativo (§5) — baixo risco, ganho imediato.
3. Remover pontos de ads + flag (§2).
4. Trial: modelo, UseCases, troca dos gates, migração de free (§1).
5. Tela de assinatura ao expirar + faixa do trial.
6. Cadastro social + refatoração do signup (§3) e velocidade (§4).
7. Comparativo de preço (§7) quando houver dados.

## 9. Decisões em aberto (preciso de você)

1. ✅ **DECIDIDO: somente leitura.** Trial expirado: o usuário vê, abre e
   compartilha orçamentos já criados, mas criar/editar e IA abrem a
   assinatura. `GetAccessStatusUseCase` expõe `canRead` (sempre true) e
   `hasFullAccess` (premium || trial); gates de criação/edição/IA usam
   `hasFullAccess`.
2. Trial para usuários free atuais começa quando eles abrem a versão nova
   (recomendado) ou numa data fixa?
3. Preços dos concorrentes (§7) e se o app tem Remote Config.
4. Acesso ao Firebase para eu analisar o UID e o funil real (export ou
   print do console).
5. Apple exige o produto/oferta de trial configurado na App Store Connect
   se for usar **introductory offer** nativa; aqui o trial é server-side, sem
   cartão (mais conversão para cadastro, menos para assinatura). Confirmar a
   escolha.

## 10. Permanência (retenção)

Meta: usuário novo cria o 1º orçamento **na 1ª sessão** (ativação) e volta.

1. **Ativação:** pós-cadastro leva direto ao chat/criador com CTA único
   "Criar meu 1º orçamento"; checklist de 3 passos (dados da empresa →
   1º orçamento → enviar PDF) com progresso salvo no doc do usuário.
2. **Sequência de push (FCM já existe em `core/notification`)**, só se o
   evento ainda não ocorreu (Cloud Function agendada lê `budget_created`):
   - D0 +2h: "Seu 1º orçamento leva 2 minutos".
   - D1: "Faltam 24h do seu teste grátis — gere um orçamento com IA".
   - D2 (últimas horas): resumo do que ele criou + assinar.
   - Pós-expiração D+1 e D+7: win-back com preço.
   - Máx. 1 push/dia; opt-out nas configurações.
3. **Loop de valor:** push "cliente aprovou o orçamento" (já existe) vira
   gatilho de retorno; incentivar compartilhar o link do orçamento web.
4. **Menos digitação:** modelos/lista de preços e orçamento por IA em
   destaque durante o trial (é o diferencial).
5. **Firebase In-App Messaging** para banners de trial/novidades sem release.
6. **Medir:** D1/D7 retention e "% com 1º orçamento em 24h" como métricas
   principais (Analytics + coorte por `auth_provider` e plataforma).

## 11. Entender por que não geram orçamento

Hipóteses (H) e como cada uma é testada:

| H | Teste |
|---|---|
| H1 Pedágio de anúncio/paywall no 1º orçamento | Já removido; comparar `budget_created` antes/depois (mesmo funil) |
| H2 Cadastro falha/lento | `signup_failed{reason}`, `perf_signup_ms`, Crashlytics non-fatal no cadastro |
| H3 Não entende por onde começar | `screen_view` da 1ª sessão + tempo até 1º toque; A/B do CTA |
| H4 Abandona no meio do criador | Eventos por etapa: cliente → itens → totais → PDF; ver onde cai |
| H5 Só queria "olhar" o app | Entrevista curta (ver abaixo) |

- **Pesquisa de 1 pergunta** (in-app, no 2º dia sem orçamento): "O que te
  impediu?" (não entendi / falta recurso / só testando / outro) — grava em
  evento `survey_no_budget{reason}`.
- **Gravação de sessão/heatmap** para ver o usuário real: ver ferramentas.
- **Contato:** e-mail/WhatsApp (suporte já existe) para amostra de 10-20
  usuários que não criaram; costuma revelar mais que qualquer dashboard.
- **UID `MBDL…`:** conferir no console antes de tudo (§0).

## 12. Ferramentas de analytics

| Ferramenta | Para quê | Custo | Recomendação |
|---|---|---|---|
| **Firebase Analytics** | Eventos, funil, coorte, retenção | Grátis | **Base obrigatória** (§6) |
| **BigQuery export** (Firebase) | Consultas SQL livres em eventos brutos | Grátis até limites | Ligar já; histórico só vale a partir de ativar |
| **Crashlytics** | Crashes/erros | Grátis | Já usa; adicionar non-fatals no cadastro e no PDF |
| **Remote Config + A/B Testing** | Testar duração do trial, textos, preço do comparativo | Grátis | Usar nos experimentos de §1 e §7 |
| **In-App Messaging / FCM** | Campanhas e push | Grátis | §10 |
| **Microsoft Clarity** | Heatmap e replay de sessão | Grátis | Opcional, para H3/H4; confirmar suporte Flutter atual |
| **PostHog** | Funil, replay, feature flags, pesquisa in-app | Plano gratuito limitado | Alternativa única se quiser tudo em 1 lugar; avalia custo e LGPD |
| Mixpanel/Amplitude | Análise de produto avançada | Free tier | Só se Firebase não bastar |

Recomendação ponytail: **Firebase Analytics + BigQuery + Remote Config/A-B**
primeiro (sem novo SDK pesado). Só adicionar replay (Clarity/PostHog) se o
funil mostrar queda sem explicação. Qualquer ferramenta nova exige atualizar
política de privacidade, Data Safety (Play) e App Privacy (Apple); mascarar
campos sensíveis (CPF/CNPJ, senha) em replays.
