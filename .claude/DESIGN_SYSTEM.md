# 🎨 Design System — OFLite (Budget Flutter)

> Fonte única dos detalhes visuais do app. **Levantado do código atual** — este
> documento descreve o que já existe, não propõe uma identidade nova. Toda tela
> nova (inclusive as de tablet/web) **segue estas regras**.
> Complementa `ARCHITECTURE.md` (§15 cores, §17 formulários, §18 snackbar,
> §19 modais) e é a base do `TABLET_RESPONSIVE_PLAN.md`.
>
> Onde o valor aparece como constante, ela está em
> `lib/shared/common/constants/colors.dart` (§15 — nunca `Color(0xFF…)`/`Colors.*`
> direto na View).

---

## 1. Princípios visuais

1. **Dark first**: o app inicia em modo escuro (`AdaptiveThemeMode.dark`).
2. **Superfícies em camadas**: fundo `bgColor` → card `secondaryColor` → campo
   `bgColor` de novo (afundado dentro do card).
3. **Um acento**: ciano `buttonColor` para ação primária, foco e ícones de
   seção. Cores de status só para status.
4. **Cards arredondados com borda sutil** (`cardBorderColor`), sem sombra.
5. **Texto secundário sempre `mutedTextColor`**; branco só no que importa.
6. **Feedback = snackbar padrão** (§18). **Modal = bottom sheet** (§19).

## 2. Cores (tokens)

### 2.1 Base

| Token | Hex | Uso |
|---|---|---|
| `bgColor` | `#1F1A30` | Fundo das telas; fundo de campo de input; trilho do anel de progresso |
| `secondaryColor` | `#2A2D3E` | Card padrão, bottom navigation, `canvasColor` do tema escuro |
| `cardBorderColor` | `#2A2640` | Borda do card; fundo do botão salvar "sem alterações" |
| `sheetHandleColor` | `#3A3654` | Borda de input; handle |
| `mutedTextColor` | `#8D89A6` | Texto secundário, labels, ícones neutros |
| `slateGray` | `#696D77` | Hint de input |
| `whiteColor` / `creamColor` | `#FFFFFF` | Texto principal; fundo do tema claro |
| `snowColor` | `#FFFAFA` | `canvasColor` do tema claro |
| `darkSlate` | `#292C36` | Superfície escura auxiliar |
| `blackColor` | `#000000` | Texto sobre botão ciano |
| `primaryColor` | `#2697FF` | Legado (ex.: botão de busca do dashboard) |

### 2.2 Ação e status

| Token | Hex | Uso |
|---|---|---|
| `buttonColor` | `#0DF5E4` | **Acento/ação primária**: botões, cursor, foco do input, ícone de seção, borda de card selecionado |
| `statusApprovedColor` | `#2ED573` | Aprovado / recebido |
| `statusRejectedColor` | `#FF6B6B` | Reprovado / erro inline |
| `statusPendingColor` | `#FFB800` | Pendente / "a receber" |
| `greenColor` / `redColor` | `#1B5E20` / `#B71C1C` | Fundos do snackbar sucesso / erro |
| `badgeColor` | `#E70F57` | Badge |
| `cartBarColor` | `#161622` | Barra inferior "Total dos itens" |
| `cartAccentColor` | `#00BFA5` | Ícone da barra / pílula Serviços |
| `productPillColor` | `#9C27B0` | Pílula Produtos |
| `priceTextColor` | `#B388FF` | Preço nos cards da lista de preço |
| `budgetOptionOrangeColor` / `budgetOptionPinkColor` | `#FF9F43` / `#FF6B9D` | Ícones da tela de opções |

**Chip de status** = cor do status com `alpha 0.15` no fundo + texto na cor cheia,
`radius 8`, padding `8×3`, fonte 11 / w700.
**Caixa de ícone** (opções, avatar do card) = cor com `alpha 0.15–0.16`, `radius 13`.

### 2.3 Chat (`chat_assistant`)

`chatBackgroundColor #12121A` (fundo) · `chatBarColor #1E1E2C` (app bar/barra de
digitação) · `chatSendButtonColor #00BFA5` · `chatUserBubbleColor #075E54`
(balão do usuário) · `chatBotAvatarColor` cyan · `chatHighlightColor`
cyanAccent · `chatOnlineColor` greenAccent · `chatDividerColor` white12 ·
`chatOptionBorderColor` white24 · `chatHintColor #9E9E9E`.

### 2.4 Premium (assinatura)

`premiumCardColor #2A2540` · `premiumBorderColor #3A3454` ·
`premiumSelectedPlanColor #243238` · `premiumBarBorderColor #2F2A44` ·
`premiumGoldColor #FFCB2E` (coroa/selo) · `premiumGoldTextColor #3A2B00` ·
`premiumPurpleColor #8B7CF6` · `premiumPinkColor #FF6B8A` ·
`premiumSubtleTextColor #B9B4D0` · `premiumBodyTextColor #E6E3F5` ·
`premiumOnAccentColor #06201E`.

### 2.5 Modal (único trecho em tema claro)

Bottom sheet **fundo branco**, texto `AppBottomModal.grayColor #424242`, divisor
`#E0E0E0`, handle `#BDBDBD`, borda de campo `modalFieldBorderColor`, label
`modalLabelColor`. É de propósito: o modal contrasta com a tela escura.

> ⚠️ **Pendência de §15**: `app_bottom_modal_widget.dart` e `app_header*.dart`
> ainda têm `Color(0xFF…)`/`Colors.white` inline. Mover para `colors.dart` ao
> tocar nesses arquivos.

### 2.6 Home

`homeHeroStartColor` (= `buttonColor`) → `homeHeroEndColor #0B3B45`: gradiente do
card hero (raio 20, texto `blackColor`, valor Heebo 30 bold).
`homeAnalysisCardColor #161622` (= `cartBarColor`): card escuro de barras (raio 20).
Atalhos: caixa 56 raio 16 (`secondaryColor` + borda), rótulo 12 `mutedTextColor`,
largura 84. Cards de status: `secondaryColor`, raio 16, ponto na cor do status.

## 3. Tipografia

| Papel | Família | Onde |
|---|---|---|
| **Base do app** | **Poppins** (`poppinsTextTheme` no `ThemeData`) | Todo `Text` sem estilo explícito (cards da lista, chips, opções, métricas…) |
| **Títulos e formulários** | **Heebo** (`GoogleFonts.heebo`) | Título de tela, header de seção, label/valor de input, botões, snackbar, modal |

Escala em uso:

| Estilo | Tamanho / peso | Exemplo |
|---|---|---|
| Título de tela grande | 28 bold, `letterSpacing 2` | Config menu, "Premium" |
| Título de tela | 26 bold, `letterSpacing 1–2` | `AppHeader`, `Header` do dashboard |
| Título de seção dashboard | 17 bold, `letterSpacing 2`, centralizado | `DashboardSection` |
| Título de card de formulário | 15 bold (Heebo) | `AppFormSectionCard` |
| Valor de input | 15 w500 (Heebo) | `AppFormField` |
| Botão primário | 17 bold (Heebo) | `AppFormSaveButton` |
| Título de modal | 20 bold (Heebo) | `AppBottomModal` |
| Nome no card | 15 w600 | `BudgetListCard`, `BudgetOptionsCard` |
| Valor monetário no card | 14 w700 | `BudgetListCard` |
| Valor hero (métricas) | 30 bold (Heebo) | `BudgetMetricsHeroCard` |
| Corpo secundário | 12–13 `mutedTextColor` | subtítulos, datas, label de input (12) |
| Chip | 11 w700 | status |

Cores de texto: principal `whiteColor`; secundário `mutedTextColor`; erro
`statusRejectedColor`; sobre o acento `blackColor`.

## 4. Espaçamento, raios e dimensões

| Token / valor | Uso |
|---|---|
| `defaultPadding = 16` | Padding de tela do dashboard, gap entre blocos |
| Margem lateral de formulário/lista | 20 (cards de formulário), 16 (opções), 15 (config menu) |
| Gap vertical entre cards de lista | 10 (`vertical: 5` em cada) |
| Padding interno de card | 12–16 |
| Padding inferior com botão flutuante | **~96–120** (último campo não fica sob o botão) |

| Raio | Onde |
|---|---|
| 8 | `ActionButton`, chip de status |
| 10 | Cards do dashboard, `ProfileCard`, itens do config menu |
| 12 | Input, snackbar |
| 13 | Caixa de ícone / avatar |
| 14 | Campo do chat/busca |
| 16 | Card de formulário, card de opção, botão salvar |
| 18 | Card da lista de orçamentos |
| 20 | Topo do bottom sheet |

Alturas fixas: botão salvar **52**; `ActionButton` **48**; avatar/ícone
**44–46**; anel de progresso **92** (stroke 9); handle do sheet **48×5**.

## 5. Componentes base (existentes)

| Componente | Arquivo | Visual |
|---|---|---|
| Card de lista | `budget_list_card.dart` | `secondaryColor`, raio 18, borda `cardBorderColor` (selecionado = `buttonColor`), avatar com inicial, valor + chip à direita, `more_vert` |
| Card de opção | `budget_options_card.dart` | `secondaryColor`, raio 16, borda, caixa de ícone 46 colorida, título + subtítulo, `chevron_right` |
| Seção de formulário | `app_form_section_card.dart` | `secondaryColor`, raio 16, margem `20,0,20,16`, ícone ciano 20 + título Heebo 15 |
| Campo | `app_form_field.dart` | label 12 muted acima; fill `bgColor`; raio 12; borda `sheetHandleColor`; foco `buttonColor` 1.5; erro `statusRejectedColor` |
| Botão salvar | `app_form_save_button.dart` | largura total, h52, raio 16; destaque = ciano/texto preto; sem alterações = `cardBorderColor`/texto muted; loading = spinner preto |
| Seção do dashboard | `dashboard_section.dart` | `canvasColor`, raio 10, padding 16, título centralizado 17 bold |
| Snackbar | `alert_snack_bar_widget.dart` | flutuante, margem 12, raio 12, ícone 26 + título 16 bold + msg 14; verde/vermelho/laranja, texto cinza-claro |
| Bottom modal | `app_bottom_modal_widget.dart` | branco, topo raio 20, handle, header com fechar, botão no rodapé, **altura máx 80%** |
| Bottom nav | `main_tab_view.dart` | fundo `secondaryColor`, selecionado `Colors.cyan[50]`, não selecionado cinza, rótulo 11 bold |
| Perfil | `header.dart` (`ProfileCard`) | `canvasColor`, raio 10, borda white10, `PopupMenu` |
| Anel de progresso | `budget_metrics_hero_card.dart` | 92×92, trilho `bgColor`, valor `statusApprovedColor` |

## 6. Padrões de tela

- **Lista**: título + lista de cards (raio 18) + FAB/botão de criação; filtro de
  status em chips; pull-to-refresh (`refreshIndicatorColor`).
- **Formulário**: `AppFormSectionCard`s empilhados, `AppFormField`s, botão
  salvar flutuante com fundo sólido (§17.7), teclado com barra de fechar
  (`AppKeyboardDismissBar`).
- **Dashboard**: `Header` + filtro de mês + seções (`DashboardSection`)
  com gráficos; `LinearProgressIndicator` de 2 px no carregamento.
- **Chat**: tema próprio (`chat*Color`), balões com `maxWidth` 75% da tela,
  barra de digitação fixa embaixo.
- **Premium**: tema próprio (`premium*Color`), planos selecionáveis, botão
  fixo com linha `premiumBarBorderColor` acima.
- **Estados**: loading `loadingIndicatorColor` (white70); vazio ícone
  `emptyStateIconColor` (white54) + texto `emptyTextColor`; erro inline
  `statusRejectedColor`.

## 7. Iconografia

Material Icons (`Icons.*`), variantes `outlined`/`rounded` conforme a tela.
Ícone de seção 20 (ciano); ícone de card 24 colorido sobre caixa 46; ícone de
ação 19–26. SVGs só em `assets/icons/` (legado do dashboard).

## 8. Regras de ouro

1. Cor **só** de `colors.dart` (§15). Adicionar lá antes de usar.
2. Raio, espaçamentos e fontes **somente** da escala acima; valor novo = entra
   aqui primeiro.
3. Card = `secondaryColor` + borda `cardBorderColor` + raio 16–18. Sem sombra.
4. Ação primária = ciano `buttonColor` com texto preto. **Uma** por tela.
5. Status = cor de status (chip 0.15 de alpha). Nunca usar essas cores para
   decoração.
6. Heebo em título/formulário/botão; Poppins (tema) no resto. Não misturar uma
   terceira família.
7. **Tamanho nunca por fração da tela** (`he * 0.08`, `we * 0.04`,
   `screenAwareSize`) nem margem mágica (`right: 285`). Usar a escala da §4 e
   os breakpoints do `TABLET_RESPONSIVE_PLAN.md`.

## 9. Dívidas visuais conhecidas (restantes)

Resolvidas (F2–F9): tamanhos por fração da tela (`he*`/`we*`), `right: 285`,
`screenAwareSize`, largura do balão do chat, bottom sheets esticados em tela
larga, snackbar esticado, cores inline do `AppBottomModal` e dos headers.

| Local | Pendência |
|---|---|
| `budget_tab_view.dart` | passa `MediaQuery.size.width` ao ViewModel (parâmetro sem uso visual) |
| `login_view.dart` | `LoginHeader` ainda recebe `width/height` da tela no layout estreito |
| `image_edit_view`, `pdf_edit_logo_section` | `maxWidth/maxHeight` em fração da tela (limites máximos, não quebram) |
| `payment_proof_list_view.dart` | sheet de ações com cor/shape próprios (só ganhou largura máxima) |
| `budget_options_view` | lista de seções segue em 1 coluna |
