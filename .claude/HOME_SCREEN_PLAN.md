# 🏠 Plano — Tela Home (inspirada no layout "Bankify")

> Segue `ARCHITECTURE.md` (§0 ponytail, §2.1 componentes, §4.4 Command, §5 módulo,
> §6 usecase, §15 cores, §21 SSoT, §22 responsivo) e `DESIGN_SYSTEM.md`.
> **Escopo fechado:** só cria a Home e a pluga no `main_tab`. **Exceções
> pedidas explicitamente:** (a) o chat pode ser iniciado já no fluxo de criar
> orçamento; (b) o chat deixa de avançar quando nenhum item foi selecionado
> (§5.1). Dashboard, lista de orçamentos, produtos e PDF seguem como estão.

---

## 1. Referência → conteúdo do app

Layout, hierarquia e proporções do print; **cores do app** (dark: `bgColor` /
`secondaryColor` / ciano `buttonColor`, no lugar do verde do print).

| Bloco do print | Na Home do OFLite |
|---|---|
| Logo "Bankify / Digital Banking" + sino + avatar | Logo da empresa (`MainTabViewModel.companyLogo`) + nome do app/empresa + avatar do usuário (abre o menu já existente do `ProfileCard`: Premium / Excluir conta / Sair). **Sino e "…" removidos** (não há função no app para eles). |
| "Good Morning, Aitzaz 👋" | "Bom dia/Boa tarde/Boa noite, {primeiro nome} 👋" (en: Good morning/afternoon/evening) |
| Card verde "Total Balance $24,560.80" + cartão | **Card hero em gradiente ciano→escuro**: "Aprovados no mês" com o **valor total orçado dos aprovados** do mês + quantidade. Ilustração do cartão → ícone/selo de orçamento aprovado. |
| 5 ícones (Send, Receive, Pay Bills, Top Up, More) | **Atalhos rolando na horizontal** com os **ícones das tabs do app** (ver §3). |
| "Quick Overview — This Month" + 4 cards | **4 cards, um por status do mês**: Aprovados · Pendentes · Reprovados · Finalizados — cada um com **quantidade** e **valor orçado**. Rótulo "Este mês" = mês do filtro. |
| "Spending Analysis" (card escuro com barras) | **"Análise de recebimentos"**: barras com o comparativo de recebido por mês (dados que o dashboard já calcula). |
| (fim da tela) | **CTA "Criar orçamento"** (botão ciano, ação primária da tela) no final do scroll. |
| — | **FAB do chat** (canto inferior direito) → abre o Assistente. |

Decisões que adotei por interpretação (confirmar antes de codar):
1. "plano tipo criar orçamentos no final da tela" → CTA/banner **Criar orçamento** no fim.
2. Atalhos: **Criar orçamentos · Lista de orçamentos · Relatórios · Cadastrar itens** (4 itens → o 4º só aparece ao arrastar para a esquerda, como pedido). **Criar orçamentos** abre o chat já no fluxo de criação (§5); **Lista de orçamentos** abre a lista idêntica à da tab (§3).
3. "Relatórios" abre a tab **Dashboard** existente (é onde hoje ficam os relatórios).
4. Sem delta "+15.6%" dos cards (exigiria comparar com mês anterior = regra nova). Fica só quantidade + valor.

---

## 2. Estrutura (módulo novo `home`)

Só apresentação — **sem `data/` nem `domain/` próprios** (ponytail §0): consome
`GetDashboardMonthSummaryUsecase` e `GetReceiptsComparisonUsecase` do módulo
`dashboard` por construtor. Nada de regra duplicada (§21 SSoT).

```
lib/modules/home/
├── home_binds.dart          # HomeViewModel = registerFactory
├── home_routes.dart         # obrigatório (tem view) — enum HomeRoute { home } -> '/home'
└── presenter/
    ├── home_view.dart
    ├── home_view_model.dart
    ├── strings/home_pt_string.dart      # pt/en, padrão dos outros módulos
    └── components/                      # classes públicas, 1 por arquivo (§2.1)
        ├── home_header.dart             # logo + nome + avatar
        ├── home_greeting.dart           # "Bom dia, Fulano 👋"
        ├── home_hero_card.dart          # card gradiente "Aprovados no mês"
        ├── home_quick_actions.dart      # ListView horizontal
        ├── home_quick_action_item.dart  # ícone em caixa + rótulo
        ├── home_overview.dart           # título + filtro de mês + grade 2×2
        ├── home_overview_card.dart      # 1 status: ícone, qtd, valor
        ├── home_analysis_card.dart      # barras (fl_chart) de recebimentos
        ├── home_create_budget_cta.dart  # botão final
        └── home_chat_fab.dart           # FAB do chat
```

Registro: `injection.dart` → `registerHomeDependencies(getIt)`;
`app_routes.dart` → `...homeRoutes`.

---

## 3. Atalhos (ícones das tabs)

Ícones vêm do mesmo `TabItem` do `MainTabViewModel` (SSoT — não copiar
`Icons.*`):

| Atalho | Ícone | Ação |
|---|---|---|
| Criar orçamentos | `Icons.support_agent` (tab Assistente) | Abre o chat **direto no fluxo de criar orçamento** (§5) |
| Lista de orçamentos | `Icons.inventory_outlined` (tab Orçamentos) | Troca para a tab Orçamentos — a **mesma** `BudgetListView` de hoje, sem alteração |
| Relatórios | `Icons.dashboard` (tab Dashboard) | Troca para a tab Dashboard |
| Cadastrar itens | ícone da lista de preços | `ProductPriceListView` (mesma navegação do `chat_assistant`/`main_config_menu`) |

Layout: `ListView` horizontal, item largura fixa 84 (4 itens > largura de
celular → o 4º é revelado ao arrastar), caixa de ícone 46 raio 13 com
`buttonColor` alpha 0.15 (DESIGN_SYSTEM §2.2), rótulo 11–12 `mutedTextColor`.

---

## 4. Integração com o `main_tab` (único arquivo existente tocado)

- `main_tab_view_model.dart`: `startBudgetInChat()` (§5) e inserir `TabItem(icon: Icons.home_outlined, title: 'Início')` **na posição 0**, e extrair constantes de índice (`chatIndex`, `budgetsIndex`, `dashboardIndex`).
- `_onShared` hoje usa `_currentIndex = 0` para ir ao chat → passa a usar `chatIndex` (**comportamento idêntico**: arquivo compartilhado continua abrindo o chat).
- `main_tab_view.dart`: lista de tabs ganha `HomeView` no índice 0; recebe callbacks `onOpenChat`, `onOpenBudgets`, `onOpenReports` que chamam `onTabTapped(<índice>)`. Sidebar desktop e bottom nav herdam a nova tab sem mudança.
- Home passa a ser a tab inicial (`_currentIndex = 0`).

> Alternativa se preferir **não** mexer na ordem das tabs: Home como 4ª tab,
> mantendo o chat em 0. Menos invasivo, mas a Home deixa de ser a tela inicial.

---

## 5. "Criar orçamento" → chat direto no fluxo (e CTA do fim da tela)

Atalho e CTA final fazem o mesmo: **trocam para a tab Assistente e iniciam o
fluxo de criação** (equivale a tocar "📝 Criar orçamentos" no menu do chat).

- Reaproveita `StartBudgetFromMenuUsecase` (já manda a transição + pede o nome do cliente e devolve o step `askClient`). **Nenhuma regra nova.**
- Mecanismo (mesmo padrão do arquivo compartilhado): `MainTabViewModel` ganha `startBudgetInChat()` → `currentIndex = chatIndex`, `chatGeneration++` e uma flag `chatStartsBudget`; `ChatAssistantView` recebe `startBudget` (bool) e, no `initState`, chama um método público do `ChatAssistantViewModel` que executa o usecase acima uma vez.
- Se já houver fluxo em andamento no chat: passo de implementação verifica o estado; usar `ResetChatToMenuUsecase` antes de iniciar para não misturar fluxos.
- O FAB do chat continua só abrindo a tab Assistente (sem iniciar fluxo).
- Fora do escopo: `confirmNewBudgetAccess` (limite de acesso) continua sendo checado **no fluxo do chat como hoje**; conferir na implementação que o caminho do chat já o aplica — se não aplicar, é igual ao comportamento atual do menu (não alterar).

## 5.1 Ajuste no chat: seleção de itens do orçamento (bug)

Hoje (`chat_assistant_view.dart` `_openBudgetItems`): abre
`BudgetListItemsView`, e ao voltar **sempre** chama
`goToCommentsAfterProductEdit()` → segue para comentários mesmo sem item
selecionado ("Nenhum item no orçamento.").

Novo comportamento (mudança restrita ao chat):
- Ao voltar da lista de itens, o `ChatAssistantViewModel` consulta os itens do rascunho (`_chatRepo.fetchDraftItems()`, mesma fonte que `_showProductReviewAndComments` já usa — SSoT).
  - **Com itens** → segue como hoje (`refreshDraftTotal` + revisão + pergunta de comentário).
  - **Sem itens** → **permanece na conversa** (step continua `askProducts`), **não** avança; envia mensagem do bot **"Para seguir preciso que você selecione os itens do orçamento"** (i18n em `ChatAssistantStrings`, en equivalente) seguida do **mesmo botão** "Selecionar produtos" (`action: 'open_products'`), igual à mensagem original `askProducts`.
- Cada tentativa vazia adiciona uma mensagem + botão novos; remover o botão da tentativa anterior (usar `_chatRepo.removeMessageById`, padrão já usado para `_reviewMsgId`) para não acumular botões ativos.
- Vale para os dois caminhos: `open_products` (1ª seleção) e `edit_products` (se o usuário apagar todos os itens ao editar).
- Implementação: trocar `goToCommentsAfterProductEdit()` por um método de VM que faz a checagem (a View só chama e não decide — §21); o texto novo fica em `chat_assistant_pt_string.dart`. Nada de `Platform`/lógica na View.
- Teste manual: Selecionar produtos → voltar sem marcar → mensagem + botão, sem comentários; abrir de novo, marcar → segue; voltar com itens já existentes → segue.

## 6. ViewModel e dados

`HomeViewModel extends ChangeNotifier` (espelha o `DashboardViewModel`, sem alterá-lo):
- `loadCommand = Command1<void,bool>` → `GetDashboardMonthSummaryUsecase` + `GetReceiptsComparisonUsecase` (§4.4).
- Estado: `month`, `summary`, `comparison`, `canGoNext`, `previousMonth()/nextMonth()` (mesmo contrato).
- Derivados só de leitura: valor/qtd aprovados = `summary.of(DashboardStatus.approved)`; demais cards idem. Moeda via `compactCurrency`/`ConvertCoinRepository` já usados no dashboard.
- Saudação por horário e primeiro nome = **formatação pura** no presenter (exceção permitida do §6.2). Nome vindo de `UserRepository.selectUser` via ViewModel (View nunca chama `getIt<Repository>()`, §21).
- i18n: apenas rótulos traduzem; `DashboardStatus.value` ('APROVADO'…) **nunca** muda (Regra Zero).
- Anúncios (§13): Home **não** exibe anúncio.

---

## 7. Visual e cores (§15 + §22.1)

Antes de codar, registrar no `DESIGN_SYSTEM.md` e em `colors.dart` (nada de
`Color(0x…)`/`Colors.*` na View):
- `homeHeroGradientStartColor` / `homeHeroGradientEndColor` (ciano `buttonColor` → teal escuro; fundo do hero).
- `homeAnalysisCardColor` (card escuro de barras) — se não for igual a `cartBarColor #161622`, reaproveitar esse.
- Reaproveitar: `bgColor` fundo, `secondaryColor` cards, `cardBorderColor` borda, `mutedTextColor`, `statusApprovedColor/PendingColor/RejectedColor`, `buttonColor` CTA e FAB (texto/ícone `blackColor`).

Medidas (escala §4): padding de tela 16, gap 16; cards raio 16–18; hero raio 20 (novo, registrar); caixa de ícone 46/raio 13; avatar 44; FAB padrão. Fontes: Heebo em títulos/saudação/valor do hero (30 bold), Poppins no resto. Sem tamanho por fração de tela.

Estrutura da tela: `Scaffold` (FAB `home_chat_fab`) → `SafeArea` → `RefreshIndicator` → `ListView` (padding inferior ~96 para o FAB não cobrir o CTA).

**Responsivo (§22):** `compact`: coluna única como o print. `medium`: mesma coluna centralizada com largura máx. (`AppPageContainer`). `expanded`: duas colunas — esquerda hero + atalhos + CTA; direita visão geral 2×2 + análise. Adicionar a linha da Home na matriz do `TABLET_RESPONSIVE_PLAN.md`.

---

## 8. Ordem de execução

1. Docs: `DESIGN_SYSTEM.md` (tokens/medidas da Home) + matriz do `TABLET_RESPONSIVE_PLAN.md`; tokens em `colors.dart`.
2. Módulo `home`: strings, `HomeViewModel` + binds + routes; registrar em `injection.dart`/`app_routes.dart`.
3. Componentes estáticos com dados fictícios → conferir contra o print (compact).
4. Ligar dados reais (summary/comparison), filtro de mês, estados loading/erro (LinearProgress 2px + texto `statusRejectedColor`, igual dashboard).
5. Atalhos + CTA (§5) + FAB do chat; integração no `main_tab` (§4).
5.1. Chat: fluxo iniciado pela Home (§5) e correção da seleção de itens (§5.1) — **única alteração em tela existente além do `main_tab`**, restrita ao chat.
6. Layouts `medium`/`expanded`.
7. Validação.

## 9. Validação

- `flutter analyze` limpo; sem `class _X extends Widget` na View; sem cor inline.
- Rodar no simulador (iPhone + tablet): visual vs. print; arrastar atalhos revela "Cadastrar itens"; FAB abre o chat; CTA cria orçamento e Home recarrega ao voltar.
- **Regressão (nada mudou):** tabs Orçamentos e Dashboard idênticas; chat idêntico exceto §5/§5.1; compartilhar arquivo → abre o chat; teste grátis expirado → abre assinatura; sidebar desktop com a nova tab.
- Estados: sem orçamentos no mês (zeros), erro de carga, mês anterior/seguinte, pt e en.

## 10. Fora de escopo

Notificações (sino), delta % vs. mês anterior, alterar Dashboard/Orçamentos/Chat, novas regras de negócio, anúncios na Home.
