# 🌐 Plano de Implementação — Strings PT/EN por Módulo

> **Fonte de verdade**: `.pi/ARCHITECTURE.md` (Regra de Ouro #12 e seção 12 —
> "Criar strings de um módulo").
> **Objetivo**: nenhum texto visível ao usuário fica hardcoded em View,
> ViewModel, componente, modal **ou nos textos gerados do orçamento (PDF,
> mensagens do chat, recibo)**. Todo texto vive em
> `presenter/strings/{modulo}_pt_string.dart`, com versão **Português e Inglês**.
> **Execução**: **um módulo por vez**, sob comando do usuário. Ao terminar o
> módulo, o agente **PARA** (ver seção 2).

---

## 0. ⛔ REGRA ZERO — Trocar de idioma NUNCA quebra o app nem os dados

> Esta regra tem prioridade sobre **todas** as outras. Na dúvida entre
> traduzir e não quebrar, **não quebrar vence**.

Cenários que **têm** que funcionar, sempre:

| # | Cenário | Resultado esperado |
|---|---------|--------------------|
| C1 | Usuário cadastra e cria orçamentos com o app em **PT** → muda o celular para **EN** | Tudo abre, soma, filtra, gera PDF e aprova normalmente; só os **textos de tela** mudam para inglês |
| C2 | Usuário cadastra com o app em **EN** → muda para **PT** | Idem, ao contrário |
| C3 | **Usuário atual** (dados gravados antes desta migração, todos em PT) atualiza o app, em qualquer idioma | Nenhum dado perdido, nenhum total/status/categoria errado |
| C4 | Dono do orçamento em PT, cliente abre o **link Web** com navegador em EN (ou o contrário) e aprova/reprova | Status gravado é o mesmo valor fixo que o app do dono entende |
| C5 | Usuário troca de idioma várias vezes e **edita** um orçamento/item antigo | Ao salvar, o valor gravado continua o valor fixo, nunca o texto traduzido |

### 0.1 Regras

1. **Valor de controle ≠ texto de tela.** Tudo que é gravado no Firestore,
   `SharedPreferences`, URL, payload de Cloud Function **e depois lido/
   comparado pelo código** (status, categoria, tipo, chaves de ação, chaves de
   `Map`) é um **valor fixo, independente de idioma**. Só o `label` mostrado ao
   usuário é traduzido (padrão enum `value` + `label`, seção 1.4).
2. **Os valores fixos são os que já existem no banco hoje** (em PT:
   `'APROVADO'`, `'PENDENTE'`, `'REPROVADO'`, `'FINALIZADO'`, `'Serviços'`,
   `'Produtos'`, `'NO_PASS'`…). **Proibido** renomear, traduzir ou migrar
   esses valores — nenhum script de migração de dados nesta tarefa.
3. **Leitura tolerante** (`fromValue`): aceita o valor fixo **e** variantes
   legadas, sem diferenciar maiúscula/minúscula/espaços. Ex.: categoria aceita
   `'Serviços'`, `'Servicos'`, `'Services'`; status aceita `'aprovado'`.
4. **Valor desconhecido nunca é "corrigido" nem regravado.** Se `fromValue` não
   reconhece, a tela mostra o texto cru e o código **não** sobrescreve o campo
   ao salvar se o usuário não alterou aquele campo.
5. **Gravar sempre o valor fixo** (`BudgetStatus.pending.value`,
   `ItemCategory.services.value`), nunca o texto de um `TextEditingController`
   ou de uma opção de modal que mostra o label traduzido.
6. **Entrada do usuário interpretada pelo código** (ex.: chat que entende
   `'SIM'`/`'NÃO'` digitado) aceita **os dois idiomas** (`SIM`/`YES`,
   `NÃO`/`NAO`/`NO`), independentemente do idioma atual.
7. **Texto livre de conteúdo** (nome da empresa padrão `defaultCompanyName`,
   descrição de item, observações) pode ser gravado no idioma em que foi
   criado: é dado do usuário, editável, e **nenhum código compara** esse
   texto. Antes de traduzir um default gravado, confirmar com grep que nada
   faz `==`/`contains` sobre ele; se fizer, ele é valor de controle (regra 1).
8. **Chaves de `SharedPreferences`, rotas, nomes de coleção/campo do
   Firestore, keys de layout do PDF** — nunca mudam.

### 0.2 ✅ (corrigido em 2026-11-16) Bug em produção — categoria gravada traduzida

> **Status**: corrigido antes da etapa `product`. `ItemCategory` criado em
> `product/domain/entity/item_category.dart`; creator grava `value`;
> comparações em `budget_list_items_view_model`, `pdf_budget_view_model`,
> 3 usecases `pdf_generate_budget_*`, `budget_web_budget_view_model`,
> `budget_web_pdf_data_view_model` e `product_price_card` usam
> `ItemCategory.fromValue`. Pendente nas etapas: exibir `.label` nos cards
> que mostram a categoria crua (`items_list_bottom_modal_widget`,
> `delete_items_card`, `product_price_delete_item_card`, mensagem do chat).

Desde o commit `389430b` (2026-08-09, já no `main`),
`ProductPtString.categoryOptions` devolve `['Products', 'Services']` em
celular EN, e `product_price_creator_view_model.dart:96/166` grava esse texto
direto no campo `categoria`. Enquanto isso, `budget`, `pdf`, `web_budget` e
`chat_assistant` comparam com `== 'Serviços'`.

Consequência: **usuários com o celular em inglês podem já ter itens com
`'Services'`/`'Products'` no Firestore**, e esses serviços são somados como
produtos (totais e PDF errados) — e trocar o idioma hoje já muda o que é
gravado (viola C1/C2).

Correção (etapa `product`, nº 10): `ItemCategory.fromValue` reconhece
`'Serviços'`/`'Servicos'`/`'Services'` → `services` e
`'Produtos'`/`'Products'` → `products`; o creator grava sempre
`ItemCategory.x.value` (`'Serviços'`/`'Produtos'`) e mostra `.label`. Todas as
comparações `== 'Serviços'` nos outros módulos passam a usar
`ItemCategory.fromValue(item.category) == ItemCategory.services` nas suas
etapas. Dados antigos em EN **não** são regravados (regra 2) — só passam a
ser lidos corretamente.

### 0.3 Verificação obrigatória da Regra Zero (em toda etapa)

Antes de marcar o módulo como concluído:

- `grep` no módulo por `==`, `switch`, `case`, `contains`, `toUpperCase()`
  envolvendo qualquer getter de `*Strings` → **não pode existir** comparação
  lógica com texto traduzido.
- Nenhum getter de `*Strings` é passado para `save`/`update`/`set`/`toMap` de
  campo de controle.
- Rodar mentalmente C1–C5 para cada valor persistido que o módulo toca e
  registrar na observação da tabela (seção 3).
- Teste manual quando o módulo grava dados: criar em PT → trocar para EN →
  abrir/editar/salvar → voltar para PT e conferir.

---

## 1. Padrão obrigatório (já usado no projeto)

Referência real: `lib/modules/auth/presenter/login/strings/login_pt_string.dart`.

```dart
import 'package:flutter/widgets.dart';

/// Textos do módulo {Modulo} (pt / en — fallback en).
class {Modulo}Strings {
  const {Modulo}Strings._();

  static Locale get _locale =>
      WidgetsBinding.instance.platformDispatcher.locale;

  static bool get _isPt => _locale.languageCode == 'pt';

  // --- {Tela}: {seção} ---
  static String get budgetCreateTitle =>
      _isPt ? 'Criar orçamento' : 'Create budget';

  // Texto com parâmetro → método estático
  static String itemPrice(String value) =>
      _isPt ? 'Preço: $value' : 'Price: $value';
}
```

Regras:

1. **Arquivo**: `lib/modules/{modulo}/presenter/strings/{modulo}_pt_string.dart`
   (nome mantido por convenção da arquitetura, mesmo contendo EN). Submódulos
   que já têm arquivo próprio (ex.: `auth/presenter/login/strings/`,
   `budget/.../comment_pt_string.dart`, `receipt/.../payment_pt_string.dart`)
   **continuam onde estão**.
2. **Toda** getter tem `pt` **e** `en`. `en` é o fallback para qualquer outra
   localidade. Getters só-PT existentes (ex.: `statusApproved => 'Aprovado'`)
   devem ganhar a versão EN.
3. Texto com interpolação → **método estático** com parâmetros
   (`static String totalBudget(String v)`), nunca concatenação na View.
4. Getters agrupados por tela com comentário `// --- Tela: seção ---`.
5. Ponytail: **sem** pacote novo (`flutter_localizations`, `arb`, `intl`
   gen) — seguimos o padrão estático existente. Sem classe base/abstração
   compartilhada.
6. Strings são **do módulo dono**. Se outro módulo precisa, importa a classe do
   módulo dono (seção 12 da arquitetura). Não criar `shared/common/strings/`.

### 1.1 O que NÃO traduzir (cuidado — quebra regra de negócio)

| Caso | Exemplo real | O que fazer |
|------|--------------|-------------|
| **Valor persistido no Firestore / comparado em lógica** | `item.category == 'Serviços'` (budget, pdf, product, web_budget, chat_assistant) | **Manter o valor gravado em PT**. Criar só um *label* de exibição: `static String categoryLabel(String stored)` que mapeia `'Serviços'`→`Services`, `'Produtos'`→`Products`. Comparações continuam com a constante original. |
| **Chave de ação usada em `switch`/`==`** | `case 'NÃO':`, `'actions': ['SIM','NÃO']`, `value == "Criar novo item"` | Separar **chave** (constante estável, não traduzida) de **label** (traduzido). Ex.: comparar por índice/enum ou contra o **mesmo getter** usado para montar a lista. Nunca comparar texto traduzido com literal. |
| **Logs e exceções técnicas** | `debugPrint(...)`, `Exception('User not authenticated')`, mensagens de `notification_repository_impl` | Não traduzir (não são visíveis ao usuário). |
| **Headers / chaves técnicas** | `'Authorization': 'Bearer $token'`, chaves de `Map` (`'label'`, `'action'`) | Não traduzir. |
| **Moeda / data** | `R$`, `convertFromDouble` | Fora do escopo deste plano. |

### 1.2 Textos do orçamento (PDF / recibo / chat) — "hardcoded"

Os usecases de geração em `pdf/domain/usecase/pdf_generate_budget/*` e
`pdf_generate_receipt/*` têm rótulos fixos (`'Número :'`, `'Cliente :'`,
`'LISTA DE ITENS DO ORÇAMENTO'`, `'Descrição dos produtos'`, `'Preço'`,
`'Valor total:'` …) e o modelo de demonstração em
`pdf_model_select_view_model.dart` (`'Cliente de Demonstração'`,
`'Produto exemplo'` …).

- Todos vão para `pdf/presenter/strings/pdf_pt_string.dart` (seção
  `// --- Documento PDF: orçamento ---` e `// --- Documento PDF: recibo ---`).
- O usecase importa `PdfStrings` diretamente (classe estática pura, sem
  widget/context) — menor diff, sem passar labels por parâmetro.
- O idioma do PDF segue o idioma do **dispositivo de quem gera**.
- Mensagens do bot do chat (`'Confirme os dados do cliente:'`,
  `'Itens do orçamento:'`, `'Total: …'`) vão para
  `chat_assistant/presenter/strings/chat_budget_pt_string.dart` como métodos
  com parâmetro.

### 1.3 Avisos na tela — NUNCA na View/ViewModel/componente

> **Regra**: nenhum texto de aviso exibido ao usuário fica escrito na View,
> ViewModel, componente, modal ou repositório. **Somente** no arquivo de
> strings do módulo.

Inclui **todos** os tipos de aviso:

| Tipo de aviso | Exemplo real hoje (errado) | Correto |
|---------------|----------------------------|---------|
| Snackbar (`SnackBar`, `showSnackBar`) | `Text('Erro ao salvar modelo. Tente novamente.')` (pdf_model_select_view) | `Text(PdfStrings.modelSaveError)` |
| `DisplayAlertRepository` (`notification`, `notificationError`, `notificationWarning`, `notificationNotCloseScreen`) — **título e mensagem** | `"Feito!"`, `"Dados do PDF atualizados com sucesso!"` (pdf_edit_view_model) | `PdfStrings.successTitle`, `PdfStrings.editSaveSuccess` |
| Dialog / `AlertDialog` / modais de confirmação | `title: 'Lista de contatos'`, `message: 'Gostaria de buscar…'` (budget_creator_view_model) | getters do módulo |
| Estado vazio / erro de carregamento | `"O orçamento não possui comentários"` | getter do módulo |
| Tooltip, placeholder, hint, label de botão, texto de loading | `tooltip: 'Reiniciar conversa'`, `'Aguarde...'` | getter do módulo |
| `errorMessage` atribuído no ViewModel | `errorMessage = 'Erro no login com Google…'` | `errorMessage = LoginStrings.loginErrorGoogleDefault` |

Títulos genéricos (`'Erro!'`, `'Feito!'`, `'Tudo Certo!'`, `'Ainda não!'`,
`'Atenção!'`) também vão para o arquivo de strings do módulo (sem arquivo
global — seção 12 da arquitetura).

### 1.4 Enums com texto — label sempre via arquivo de strings

> **Regra**: enum **nunca** carrega texto de tela escrito no próprio arquivo
> (`return 'Padrão';`). O texto de exibição vem do arquivo de strings do
> módulo dono. Quando o valor é **gravado no Firestore como texto**, ele vira
> um enum com **valor persistido fixo** (não traduzido) + **label traduzido**.

Padrão (enum no módulo dono, `domain/entity/` — Regra de Ouro #13):

```dart
// lib/modules/budget/domain/entity/budget_status.dart
import 'package:oflite/modules/budget/presenter/strings/budget_pt_string.dart';

enum BudgetStatus {
  approved('APROVADO'),
  pending('PENDENTE'),
  rejected('REPROVADO'),
  finished('FINALIZADO');

  /// Valor gravado no Firestore. NUNCA traduzir nem alterar.
  final String value;
  const BudgetStatus(this.value);

  /// Texto exibido na tela (pt/en).
  String get label => switch (this) {
        BudgetStatus.approved => BudgetStrings.statusApproved,
        BudgetStatus.pending => BudgetStrings.statusPending,
        BudgetStatus.rejected => BudgetStrings.statusRejected,
        BudgetStatus.finished => BudgetStrings.statusFinished,
      };

  /// Converte o texto do Firestore (case-insensitive, sem espaços).
  /// Desconhecido → `null`: a tela mostra o texto cru e NADA é regravado
  /// (Regra Zero, 0.1 item 4).
  static BudgetStatus? fromValue(String? v) {
    final n = v?.trim().toUpperCase();
    for (final s in BudgetStatus.values) {
      if (s.value == n) return s;
    }
    return null;
  }
}

// Exibição: BudgetStatus.fromValue(raw)?.label ?? raw
```

Regras:

1. Gravar/comparar **sempre** por `BudgetStatus.x.value` (ou pelo enum), nunca
   pelo literal `'APROVADO'` espalhado no código.
2. Exibir **sempre** por `.label` — nunca mostrar o `status` cru do Firestore.
3. Dados antigos do Firestore não mudam (o `value` é o mesmo texto de hoje).
4. Mesma regra para **categoria do item** (`'Serviços'` / `'Produtos'`,
   gravada no Firestore): enum `ItemCategory` no módulo `product` (dono do
   cadastro de preço) com `value` fixo + `label` via `ProductStrings`.
   `fromValue` **também** reconhece os valores legados em inglês
   `'Services'`/`'Products'` (bug 0.2).
5. Enums sem persistência que só têm texto de exibição (ex.:
   `PdfLayoutType.displayName`) → só trocar o `return 'Padrão'` pelo getter
   (`PdfStrings.layoutStandard`).
6. Ponytail: não criar enum para valores que não têm texto de tela nem são
   comparados em mais de um lugar.

#### Inventário de enums/valores com texto (2026-11-16)

| Item | Onde está hoje | Valor persistido? | Módulo dono / etapa |
|------|----------------|-------------------|---------------------|
| **Status do orçamento** `APROVADO` / `PENDENTE` / `REPROVADO` / `FINALIZADO` | literais em `budget_creator_view.dart:114` (lista do dropdown), `budget_list_view_model.dart:180`, `chat_budget_repository_impl.dart:75,264`, `budget_web_approval_modal_widget.dart:39,47`, `budget_web_budget_view_model.dart:155`, `budget_web_approve_button.dart:37,42`, `shared/common/utils/get_budget_status_color.dart` (switch); `BudgetWebStrings.statusApproved` só-PT | ✅ Sim (Firestore) | **`budget`** cria `BudgetStatus` (etapa 13); `web_budget`, `chat_assistant` e `shared` passam a usá-lo nas suas etapas. Na etapa `budget`, `get_budget_status_color.dart` já passa a fazer `switch` no enum |
| **Categoria do item** `Serviços` / `Produtos` | `budget_list_items_view_model`, `pdf_budget_view_model`, 3 usecases de PDF, `pdf_model_select_view_model`, `product_price_creator_view_model`, `web_budget` (2 VMs), `chat_assistant_view_model` | ✅ Sim (Firestore) | **`product`** cria `ItemCategory` (etapa 10); demais módulos usam nas suas etapas |
| `PdfLayoutType.displayName` (`Padrão`/`Executivo`/`Profissional`) | `pdf/domain/entity/pdf_layout_type.dart` | ❌ (persiste a `key`) | `pdf` (etapa 15) |
| Ações do chat `SIM` / `NÃO` / `Confirmar endereço` / `Editar comentários` … | `chat_assistant_view(_model).dart` | ❌ (chave de `switch`) | `chat_assistant` (etapa 16) — enum de ação com `label` traduzido |
| Opções `'Criar novo item'` / `'Selecionar da lista de preço'`, `'Ver anuncio'` / `'Se tornar premium'` | `shared/common/widgets/modals/*` + `==` em `budget_list_items_view.dart` | ❌ | `shared` (etapa 17) — comparar por índice/enum, label vindo do chamador |
| `AlertType`, `CustomerInfoEnum`, `ProductPriceFieldEnum`, `ReceiptFieldEnum`, `SingupFieldEnum` | `shared/common/enums`, `budget/presenter/enum` | — | Sem texto de tela hoje → nada a fazer (revalidar na etapa do módulo) |

---

## 2. Protocolo de execução por módulo (OBRIGATÓRIO)

**Comando do usuário**: `implemente o plano de linguas no modulo {modulo}`

O agente executa **somente** o módulo pedido, nesta ordem:

1. **Ler** esta seção e a linha do módulo na tabela da seção 3.
2. **Inventariar** os literais do módulo:
   ```bash
   grep -rn -E "['\"][A-ZÀ-Úa-zà-ú][^'\"]*[ À-ú][^'\"]*['\"]" lib/modules/{modulo} --include='*.dart' \
     | grep -v -E "/strings/|:\s*(import|export|//)|debugPrint|log\(|print\(|'package:"
   ```
   Revisar também literais de **uma palavra** (`'Salvar'`, `'Cancelar'`,
   `'Itens'`): `grep -rn -E "Text\(\s*['\"]|(title|label|hintText|labelText|message|tooltip|placeholder|buttonLabel|primaryText)\s*:\s*['\"]" lib/modules/{modulo}`.
   **Avisos** (seção 1.3) — chamadas de alerta com literal:
   `grep -rn -E -A3 "SnackBar\(|showDialog\(|AlertDialog\(|notification(Error|Warning|NotCloseScreen)?\(|errorMessage\s*=" lib/modules/{modulo} | grep -E "['\"][A-Za-zÀ-ú]"`.
   **Enums / status** (seção 1.4):
   `grep -rn -E "^enum |'(APROVADO|PENDENTE|REPROVADO|FINALIZADO|Serviços|Produtos)'" lib/modules/{modulo}`
   e conferir a linha do módulo no inventário 1.4.
3. **Classificar** cada literal: visível ao usuário → mover; aviso (1.3) →
   mover; enum/valor persistido (1.4) → enum com `value` + `label`; caso da
   tabela 1.1 → tratar como lá descrito.
4. **Criar/completar** o arquivo de strings do módulo (PT + EN em toda getter).
5. **Substituir** os literais em Views, ViewModels, componentes, modais,
   usecases (só o módulo `pdf`) e repositórios que exibem texto.
   Remover `const` de widgets que passaram a usar getter.
6. **Verificar**:
   - `flutter analyze lib/modules/{modulo}` sem erros novos;
   - repetir o grep do passo 2 → só sobram itens da tabela 1.1;
   - nenhuma comparação lógica passou a usar texto traduzido;
   - **Regra Zero (seção 0.3)**: cenários C1–C5 conferidos para os valores
     persistidos do módulo.
7. **Atualizar** a tabela da seção 3: status `✅ concluído` + observações
   (arquivos criados, valores persistidos mantidos).
8. **PARAR.** Reportar ao usuário em poucas linhas:
   - arquivos de strings criados/alterados;
   - nº de textos migrados;
   - itens deixados de fora de propósito (tabela 1.1);
   - próximo módulo sugerido.

> ⛔ **Regra de parada**: ao concluir o passo 8 o agente **encerra o turno**.
> **Não** inicia o próximo módulo, **não** mexe em arquivos de outros módulos
> (exceto o import da classe de strings quando um componente compartilhado do
> próprio módulo é usado fora dele), **não** faz commit. O próximo módulo só
> começa com um novo comando
> `implemente o plano de linguas no modulo {proximo}`.

---

## 3. Módulos — ordem de migração e status

Ordem: do mais isolado/menor para o mais acoplado/maior. A contagem é uma
estimativa de literais com espaço/acento fora de `strings/` (inventário de
2026-11-16) — o grep do passo 2 é a fonte real.

| # | Módulo | Arquivo(s) de strings | Literais restantes (≈) | Atenção | Status |
|---|--------|------------------------|------------------------|---------|--------|
| 1 | `auth` (login + singup) | `login/strings/login_pt_string.dart`, `singup/strings/singup_pt_string.dart` | 7 | Já bilíngue — revisar restos e uma-palavra | ✅ concluído (2026-11-16) — +6 getters: 3 erros Google Sign-In, `defaultCompanyName` (login e singup), `userFallback`. Mantidos: `debugPrint` e `Exception` técnica do idToken. Obs.: `defaultCompanyName`/`userFallback` são gravados no Firestore no idioma do dispositivo na criação (editável pelo usuário). Regra Zero conferida: nada compara `empresa`/`name` com esses textos (texto livre, 0.1 item 7) |
| 2 | `support` | `support_pt_string.dart` | 1 | — | ⬜ pendente |
| 3 | `subscription` | `subscription_pt_string.dart` | 2 | Nomes/preços de plano vindos da loja não traduzir | ⬜ pendente |
| 4 | `main_tab` | **criar** `main_tab_pt_string.dart` | 1+ | Labels das abas | ⬜ pendente |
| 5 | `main_config_menu` | `main_config_menu_pt_string.dart` | 0 (revisar uma-palavra) | — | ⬜ pendente |
| 6 | `image` | `image_pt_string.dart` | 0 (revisar) | `title: 'Editar Logo'` vem de pdf/chat → getter em `ImageStrings` | ⬜ pendente |
| 7 | `terms_conditions` | `terms_conditions_pt_string.dart` | 0 (revisar) | — | ⬜ pendente |
| 8 | `delete_account` | `delete_account_pt_string.dart` | 7 | Web | ⬜ pendente |
| 9 | `dashboard` | `dashboard_pt_string.dart` | 11 | Labels de gráfico/meses | ⬜ pendente |
| 10 | `product` | `product_pt_string.dart` | 11 | **Criar enum `ItemCategory`** (`product/domain/entity/item_category.dart`, `value` `'Serviços'`/`'Produtos'` + `label` via `ProductStrings`) e usar no `product_price_creator` (1.4). Bug 0.2 **já corrigido** (`ItemCategory` existe) — na etapa, só exibir `.label` onde a categoria aparece crua | ⬜ pendente |
| 11 | `receipt` (+ payment) | `receipt_pt_string.dart`, `payment_pt_string.dart` | 11 | — | ⬜ pendente |
| 12 | `core` | **criar** `core/display_alert/presenter/strings/display_alert_pt_string.dart` | 4 visíveis (`display_alert`) | `notification` só tem logs → não traduzir; `_channelName` do Android pode ficar | ⬜ pendente |
| 13 | `budget` (+ comment) | `budget_pt_string.dart` (só 2 getters hoje), `comment_pt_string.dart` | 75 | **Maior lacuna**: creator, list_items, total bar, modais, tab. **Criar enum `BudgetStatus`** (`budget/domain/entity/budget_status.dart`, 1.4): dropdown do `budget_creator_view.dart:114` usa `BudgetStatus.values` + `.label`; `budget_list_view_model` grava `BudgetStatus.pending.value`; card/lista exibem `.label`; `shared/common/utils/get_budget_status_color.dart` faz `switch` no enum. Avisos (`'Ainda não!'`, `'Tudo Certo!'`, `'Orçamento criado com sucesso!'`…) → strings (1.3). Categoria via `ItemCategory`; `"Criar novo item"`/`"Selecionar da lista de preço"` usados em `==` | ⬜ pendente |
| 14 | `web_budget` | `web_budget/strings/budget_web_strings.dart` (local mantido — seção 16.4) | 11 + getters só-PT | Completar EN de getters só-PT; **trocar `'APROVADO'`/`'REPROVADO'` por `BudgetStatus`** (approval modal, approve button, budget VM) e remover `BudgetWebStrings.statusApproved` em favor de `BudgetStatus.approved.label`; categoria via `ItemCategory` | ⬜ pendente |
| 15 | `pdf` | `pdf_pt_string.dart` | 133 | **Textos do orçamento/recibo** nos 6 usecases + demo do model select (seção 1.2). `PdfLayoutType.displayName` → getters `PdfStrings` (1.4). Avisos `"Feito!"`/`"Erro!"`/snackbar do model select (1.3). Categoria via `ItemCategory` | ⬜ pendente |
| 16 | `chat_assistant` | `chat_budget_pt_string.dart` | 99 | Mensagens do bot com parâmetro; ações `'SIM'/'NÃO'`, `'Confirmar endereço'`, `'Editar comentários'` são chaves de `switch` → enum de ação com `label` (1.4); `chat_budget_repository_impl` grava `BudgetStatus.pending.value` | ⬜ pendente |
| 17 | `shared` (`lib/shared/common/widgets/modals`) | sem arquivo próprio | ~12 | Defaults hardcoded (`'Não'`, `'Digite a quantidade'`, `'Trocar nome de usuário'`, `'Ver anuncio'`, `'Como você quer inserir o item?'`…). Tornar parâmetros **obrigatórios** e os chamadores passam o texto da classe de strings do módulo dono (ex.: `item_option` → `BudgetStrings`, `change_name`/`change_password` → `MainConfigMenuStrings`). Não criar `shared/common/strings/`. `get_budget_status_color.dart` já migrado na etapa `budget` — conferir | ⬜ pendente |
| 18 | Documentação | `.pi/ARCHITECTURE.md` | — | Atualizar seção 12 "Criar strings de um módulo": exigir PT+EN, citar a tabela 1.1, a regra de avisos (1.3) e a regra de enums `value` + `label` (1.4); adicionar Regra de Ouro na seção 8 | ⬜ pendente |

---

> Etapas com dependência: `web_budget` (14), `pdf` (15), `chat_assistant` (16)
> e `shared` (17) usam `BudgetStatus`/`ItemCategory` criados em `product` (10)
> e `budget` (13) — manter a ordem.

## 4. Definição de pronto (por módulo)

- [ ] **Regra Zero (seção 0) verificada**: cenários C1–C5 ok para todo valor
      persistido que o módulo toca; nenhuma comparação/gravação usa texto
      traduzido; valores legados continuam sendo lidos.
- [ ] Grep do passo 2 sem textos visíveis ao usuário fora de `strings/`.
- [ ] Toda getter do arquivo de strings tem PT e EN.
- [ ] Nenhum aviso (snackbar, alerta, dialog, modal, estado vazio, tooltip,
      `errorMessage`) com texto escrito fora do arquivo de strings (1.3).
- [ ] Enums do módulo sem texto de tela no próprio arquivo; status/categoria
      usando `value` (persistido) + `label` (traduzido) (1.4).
- [ ] Valores persistidos e chaves de lógica intactos (tabela 1.1).
- [ ] `flutter analyze lib/modules/{modulo}` sem erros novos.
- [ ] Linha do módulo na seção 3 marcada `✅ concluído` com observações.
- [ ] Agente parou e reportou (seção 2, passo 8).

## 5. Teste manual (opcional, ao final de todos os módulos)

Trocar o idioma do simulador/dispositivo para **English** e para
**Português**, abrir as telas do módulo e gerar um PDF de orçamento e de
recibo; no Web: `flutter run -d chrome --target lib/main_web.dart` com o
navegador em `en`.
