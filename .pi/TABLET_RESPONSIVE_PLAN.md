# Plano — Todas as telas responsivas (iPad/Tablet, pronto para Web)

> Segue `.pi/ARCHITECTURE.md` (MVVM + `ChangeNotifier` + `get_it`, ponytail) e
> **`.pi/DESIGN_SYSTEM.md`** (visual atual do app — única fonte de cor, tipografia,
> raio e espaçamento). Plano só de **apresentação**: nenhum dado persistido,
> repository ou datasource muda (Regra Zero do i18n / SSoT preservadas).

## 1. Objetivo

1. **iPad e tablet Android abrem sempre deitados** (landscape). Celular: igual a hoje.
2. **Todas as telas do app** (≈ 46 views, matriz na §5) passam a usar bem a
   tela larga, **com o visual que o app já tem** (dark, `secondaryColor`,
   ciano `buttonColor`, Heebo/Poppins, raios 16–18). Nada de paleta nova.
3. Layout decide por **largura da janela**, nunca por plataforma → o futuro
   Web reaproveita as mesmas telas.

### O que usamos dos prints (só estrutura)

Dos prints reaproveitamos **composição**, nunca cor/fonte: sidebar fixa à
esquerda, grid de cards, KPI + gráfico largo + painel lateral, master-detail.
Tudo desenhado com os tokens do `DESIGN_SYSTEM.md` (ex.: item selecionado da
sidebar = borda/ícone `buttonColor`, como o card selecionado da lista).

## 2. Decisões a confirmar

| # | Decisão | Proposta |
|---|---|---|
| D1 | Trava landscape no iPad | `UISupportedInterfaceOrientations~ipad` só `LandscapeLeft/Right` + `UIRequiresFullScreen`. ⚠️ O flag aparece como depreciado nas versões novas do iPadOS (não consegui confirmar aqui) → validar no simulador; se falhar, o layout fluido já cobre janela redimensionável. |
| D2 | Android tablet | `shortestSide >= 600` → `SystemChrome.setPreferredOrientations(landscape)` em runtime. |
| D3 | iPhone | Não muda. |
| D4 | §17.7 "não alterar a bottom navigation" | Mobile **idêntico**; em tela larga entra sidebar (componente novo). Confirmar. |
| D5 | Web | Fora do escopo; só garantir widgets sem `dart:io`/`Platform` (§16.7). |
| D6 | Tema claro | O código tem `ThemeData.light`, mas as telas usam cores escuras fixas. Fica **fora**: tablet = dark, como o app. |

## 3. Breakpoints (única fonte)

Evoluir `lib/shared/common/widgets/responsive_widget.dart` (hoje 850/1100 com
`MediaQuery.of(context).size`):

| Classe | Largura | Exemplos |
|---|---|---|
| `compact` | < 600 | iPhone, Android celular |
| `medium` | 600–1023 | tablet pequeno / janela estreita |
| `expanded` | ≥ 1024 | iPad deitado (1024 · 1133 · 1194 · 1366), web |

- `MediaQuery.sizeOf` (sem rebuild por teclado); `ResponsiveWidget.sizeOf(context)` devolve o enum.
- `isMobile/isTablet/isDesktop` ficam como alias dos novos limites (dashboard e `header.dart` usam).
- Largura **do espaço recebido** (painel, coluna) → `LayoutBuilder` no componente.

## 4. Fundação (`shared/common/widgets/adaptive/`) — Fase 1

Um widget público por arquivo (§2.1), **só tokens existentes** (cores de
`colors.dart`, raios/espaços do `DESIGN_SYSTEM.md` §4):

| Arquivo | Função |
|---|---|
| `app_page_container.dart` | Centraliza com `maxWidth` por tipo: **form 720 · leitura 820 · lista/grid 1200 · auth 480**; padding lateral 16/20/24 por classe |
| `app_adaptive_grid.dart` | `SliverGrid`/`GridView` com `MaxCrossAxisExtent` → cards de lista em 1 / 2 / 3 colunas |
| `app_master_detail.dart` | `expanded`: painel lista (~400) + detalhe com `Navigator` aninhado; senão fluxo atual |
| `app_two_column_form.dart` | Formulário (esq.) + card-resumo fixo (dir.) em `expanded` |
| `app_side_bar.dart` | Sidebar: fundo `secondaryColor`, raio 18 nos itens, selecionado `buttonColor` (ícone/borda) |
| `app_section_header.dart` | Título Heebo 26 bold (`letterSpacing 1`) + ação, **substitui `he*0.08`/`we*0.04`** |
| `app_kpi_card.dart` | Card de métrica no padrão `DashboardSection`/`BudgetMetricsCardBox` (opcional) |
| `show_app_modal.dart` | Helper único de `showModalBottomSheet` com `constraints: maxWidth 640` (sheet centralizado no iPad); `AppBottomModal` segue como visual |

Nenhuma cor nova prevista. Se surgir necessidade, entra primeiro em
`colors.dart` **e** no `DESIGN_SYSTEM.md` §2.

## 5. Matriz — todas as telas (checklist de execução)

Padrões: **PC** = `AppPageContainer`, **G** = `AppAdaptiveGrid`, **2C** =
`AppTwoColumnForm`, **MD** = master-detail, **H** = trocar header por
`AppSectionHeader` (remove `he*/we*`).

### Navegação e shell
| Tela | `expanded` |
|---|---|
| `main_tab_view` | Sidebar (3 abas + Configurações + atalho Premium p/ não assinante) no lugar da bottom nav; mobile intacto |
| `main_config_menu_view` | **H** (hoje `right:285`) + lista em **G** 2 col, itens mantêm borda `secondaryColor` raio 10 |

### Auth
| Tela | `expanded` |
|---|---|
| `login_view` | **PC auth 480** centralizado (já usa `maxWidth`, validar) |
| `singup_view` | **PC auth 480** + remover frações de `MediaQuery` |

### Orçamento
| Tela | `expanded` |
|---|---|
| `budget_list_view` | **MD**: lista (cards raio 18) à esquerda, detalhe à direita; toque seleciona (`selectedBudgetId` no VM) |
| `budget_tab_view` | Vira o **painel de detalhe** do MD; abas internas inalteradas |
| `budget_creator_view` | **2C**: seções de info/endereço/contato + `budget_creator_summary_card` fixo |
| `budget_options_view` | **G** 2 col dos `BudgetOptionsCard` |
| `budget_list_items_view` | **G** 2 col de cards; `total_bar` fixa embaixo com largura do conteúdo |
| `budget_item_quantity_view` (modal-tela) | `showAppModal` (sheet 640) |
| `budget_metrics_view` | Hero ocupa a linha; demais cards em **G** 2 col |
| `budget_comment_list_view` | **G** 2 col |
| `budget_comment_detail_view` | **PC form 720** |

### Recibo
| Tela | `expanded` |
|---|---|
| `receipt_tab_view` | Segue o padrão do `budget_tab` (painel/aba) |
| `receipt_list_view` | **G** 2 col + **H** |
| `receipt_creator_view` | **PC form 720** (ou **2C** se houver resumo) |
| `receipt_payment_list_view` | **G** 2 col + **H** |
| `receipt_payment_creator_view` | **PC form 720**; `payment_data_form` e `payment_creator_header` sem frações |

### Produto e biblioteca de comentários
| Tela | `expanded` |
|---|---|
| `product_price_list_view` | **G** 2–3 col + **H** (`product_price_list_header`) |
| `product_price_creator_view` | **PC form 720** / `showAppModal`; remover 7 usos de `MediaQuery` |
| `product_price_picker_view` | **G** / sheet 640 |
| `comment_library_list_view` | **G** 2 col + **H** |
| `comment_library_creator_view` | **PC form 720** |
| `comment_library_picker_view` | sheet 640 / **G** |

### Chat (assistente)
| Tela | `expanded` |
|---|---|
| `chat_assistant_view` | **PC leitura 820** centralizada; fundo `chatBackgroundColor` full-bleed; barra de digitação com a mesma largura |
| `chat_message_bubble` | `maxWidth` = `min(75% da coluna, 560)` (hoje 75% da tela) |
| `chat_budget_picker_view` | **G** / sheet 640 |
| `chat_media_picker_view` | Grid com mais colunas por `MaxCrossAxisExtent` |
| `chat_proof_preview_view` | Imagem à esquerda, ações à direita (2 col) |

### Dashboard
| Tela | `expanded` |
|---|---|
| `dashboard_view` | Grid: KPIs (status overview) em linha, gráficos largos (progresso mensal + comparativo) e coluna direita (itens vendidos); `DashboardSection` mantém raio 10/título 17. `Header` com título sempre visível (hoje some em desktop) |

### PDF e imagem
| Tela | `expanded` |
|---|---|
| `pdf_budget_view` / `pdf_receipt_view` | Preview ocupa a área central; ações em coluna lateral |
| `pdf_model_select_view` | **G** 2–3 col de modelos |
| `pdf_edit_view` | **2C** (campos + seção do logo); trocar `pdf_edit_header` (**H**) e `pdf_edit_logo_section` |
| `image_edit_view` | Imagem grande à esquerda, controles à direita |
| `payment_proof_list_view` | **G** 3 col; `payment_proof_detail_sheet` → `showAppModal` |
| `payment_proof_viewer_view` | Imagem `contain` em tela cheia, sem larguras fixas |

### Assinatura e conta
| Tela | `expanded` |
|---|---|
| `subscription_view` | Planos **lado a lado** (mensal/anual) em **PC 820**; benefícios em 2 col; barra fixa mantém `premiumBarBorderColor`; remover `screenAwareSize` |
| `delete_account_in_app_view`, `delete_account_view` | **PC 560** |

### Texto/página
| Tela | `expanded` |
|---|---|
| `terms_conditions_view`, `legal_view`, `support_view` | **PC leitura 820** (legal/support já têm `maxWidth`, validar) |

### Web (`web_budget/*`, 6 views)
Fora do escopo (já é web). Só regressão visual: nada pode quebrar com a mudança
de `ResponsiveWidget`.

### Transversais
| Item | Ação |
|---|---|
| Headers `app_header`, `app_header_second_title` | Reescritos com **H**; chamadas existentes mantêm a API |
| `height_calculate_utils.dart` (`screenAwareSize`) | Parar de usar em tela larga; remover quando zerar usos |
| 30 × `showModalBottomSheet` | Migrar para `showAppModal` (sheet 640) |
| Snackbar (`AlertSnackBar`) | `margin` lateral maior em `expanded` para não esticar (largura máx ~560, alinhado ao centro) |
| `AppKeyboardDismissBar` / teclado em landscape | Formulários sempre roláveis; altura útil ~400 px com teclado |
| Anúncios (§13) | Reposicionar banner sem mudar a decisão do `core/ads` |

## 6. Fases

Cada fase = PR pequeno; **mobile 390×844 sem regressão**.

| Fase | Conteúdo |
|---|---|
| **F0 ✅** | Trava de orientação: Info.plist (iPad), `main.dart` e `MainActivity.kt` (tablet Android) |
| **F1 ✅** | Breakpoints (`WindowSize`) + `AppPageContainer`, `AppAdaptiveGrid`, `AppSectionHeader`, `showAppModal` (já usado pelos 4 modais compartilhados) + testes + `DESIGN_SYSTEM.md`/§22. **Adiados para a fase que os usa** (evita código sem uso): `app_side_bar` (F3), `app_master_detail` (F5), `app_two_column_form` (F6), `app_kpi_card` (F4, se necessário) |
| **F2 ✅** | Removidos `he*`/`we*`/`right:285`/`screenAwareSize` (exceto o que é de fase própria: `chat_message_bubble` e `budget_tab` → F5/F8; `login_view` → F6; `image_edit`/logo `maxWidth` 0.8 → F8). Topo = `paddingOf(context).top + 16`, margens 16/20, alturas de campo fixas, campos em largura total com margem 16. `height_calculate_utils.dart` removido |
| **F3 ✅** | `main_tab`: `MainTabSideBar` (220 px, logo + 3 abas) em `expanded`; bottom nav intacta abaixo disso. Atalho Premium/Configurações **não entrou** (hoje não existem como aba; Premium/Excluir conta/Sair seguem no `ProfileCard` do Dashboard) |
| **F4 ✅** | Dashboard: em `expanded` duas linhas de 2 cards 3:2 com a mesma altura por linha (resumo por status | progresso mensal; vendidos | recebimentos — resumo e vendidos à esquerda; filtro de mês na largura da coluna da esquerda), topo e base alinhados; abaixo de 1024 uma coluna; título do `Header` sempre visível. **Não entraram**: chip de variação % (exige UseCase novo) e tooltip nos gráficos |
| **F5 ✅** | `AppMasterDetail` (Navigator aninhado, rota-base = estado vazio; voltar na tela do orçamento "fecha" o detalhe) + `BudgetListEmptyDetail`; `BudgetListView` em `expanded` (lista principal, não a de cliente) abre/troca orçamento no painel, realça o card ativo (`active`), cria novo orçamento no painel, fecha o detalhe se o aberto for excluído e atualiza a lista ao fechar. Notificação e chat continuam abrindo `BudgetTabView` em tela cheia pelo navigator raiz. **Validado no simulador iPad Pro 13"** (abrir, trocar de orçamento, aba Itens no painel, voltar fecha o detalhe). **Não validado**: novo orçamento no painel, exclusão do orçamento aberto, abertura por notificação |
| **F6 ✅** | `budget_creator`, `receipt_creator` e `delete_account_in_app` em `AppPageContainer(form 720)`; `login_view` em tela larga vira logo à esquerda + formulário (auth 480) à direita. **Ajuste do plano**: `AppTwoColumnForm` não foi criado (o formulário abre num painel de ~750 px, não cabe 2 colunas); `singup`, `product_price_creator`, `comment_library_creator`, `receipt_payment_creator`, `budget_comment_detail` são bottom sheets → F9 (`showAppModal`). Validado no iPad: formulário no painel. **Não visto**: login lado a lado (exigiria sair da conta) |
| **F7 ✅** | `AppAdaptiveGrid` agora aceita cards de altura variável (linhas pelo maior card; 1–3 colunas, `minItemWidth` 320). Aplicado em `product_price_list`, `comment_library_list`, `receipt_list`, `receipt_payment_list`, `payment_proof_list`, `budget_list_items`, `budget_comment_list`. **Fora**: `budget_metrics` (já é em pares/cards) e `budget_options` (lista de seções com título; segue em coluna). Validado no iPad só na aba Itens (2 colunas no painel); demais listas só por teste do widget |
| **F8 ✅** | Chat: mensagens em coluna central 820, barra de digitação de ponta a ponta com conteúdo centralizado, balão limitado a 560 e opções do bot em 2 colunas de mesma altura (`ChatMessageOptionButtons`, balão ≥ 440 px); Premium (`subscription_view`), menu de configurações e `pdf_edit` em container centralizado. **Sem mudança (já adequados)**: `terms_conditions` (WebView), `pdf_budget`/`pdf_receipt` (visualizador de PDF), `pdf_model_select` (carrossel), `image_edit`, `payment_proof_viewer`. Os pickers do chat (`chat_budget_picker`, `chat_media_picker`) são bottom sheets → F9. Validado no iPad: chat (coluna central, balão). **Não visto**: Premium, config, pdf_edit |
| **F9 ✅** | 20 chamadas de `showModalBottomSheet` migradas para `showAppModal` (sheet centralizado, máx. 640; `useRootNavigator` suportado) e 1 com `constraints` direto (`payment_proof_list`, cor/shape próprios); `web_budget` fora. Snackbar centralizado com máx. 560. Cores inline do `AppBottomModal` e dos headers movidas para `colors.dart` (`modalTextColor`, `modalDividerColor`, `modalHandleColor`). Busca final: 0 usos de `he*`/`we*`/`screenAwareSize`/`right: 285` fora do web. Validado no iPad: sheet de ações do orçamento centralizado. **Não visto**: demais sheets e o snackbar |

## 7. Regras para todas as fases

- Layout por `ResponsiveWidget`/`LayoutBuilder`; **proibido** `Platform.is*` e `dart:io` em widget adaptativo.
- View só monta; widget novo = `components/`, público, um por arquivo (§2.1).
- Cor/raio/fonte/espaço **somente** do `DESIGN_SYSTEM.md`. Valor novo entra lá primeiro.
- Texto novo em `presenter/strings/` do módulo (plano de i18n; nunca alterar valor persistido).
- Regra de negócio nova = UseCase (§6). Chamada externa só no DataSource.
- Assinantes: sidebar só **lê** o estado existente (Android com assinantes intocado; iOS segue suas regras).

## 8. Verificação

- Widget tests por tela principal em `390×844` (compact), `1024×768`, `1194×834`, `1366×1024` (expanded): sem overflow; sidebar só em expanded; bottom nav só abaixo.
- Simulador iPad (10ª/11"/13"): abre deitado, navega por **todas** as telas da matriz, abre teclado nos formulários, abre cada modal.
- Android tablet 10": abre deitado; celular inalterado.
- `flutter analyze` e testes existentes sem regressão.
- Busca final: `grep` de `he \*`, `we \*`, `screenAwareSize`, `right: 285` = 0 resultados nas views.

## 9. Riscos

| Risco | Mitigação |
|---|---|
| Altura útil pequena em landscape com teclado | Forms roláveis + padding inferior 96–120; modais com `maxHeightFactor 0.8` |
| Navigator aninhado (F5) quebra `pop`/abertura por notificação | Notificação seleciona o orçamento via VM no expanded; teste dedicado |
| `UIRequiresFullScreen` depreciado | Ver D1 |
| Telas que não li em detalhe (pdf, image, payment proof, receipt) | Primeiro passo de cada fase = abrir o arquivo e confirmar o padrão da matriz; ajustar a matriz se divergir |
