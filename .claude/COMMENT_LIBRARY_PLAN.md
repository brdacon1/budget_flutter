# Plano — Cadastro de Comentários com IA (somente assinantes)

> Segue `.pi/ARCHITECTURE.md` (MVVM + Clean, ponytail, §6 UseCases, §19 modal-tela,
> §20 IA). Formato espelhado na **lista de preço** (`modules/product`):
> lista de gestão + modal-tela de criar/editar + picker para levar ao orçamento.

---

## 0. Escopo e decisões

| # | Decisão |
|---|---------|
| D1 | Novo módulo `modules/comment_library/` — biblioteca de comentários reutilizáveis do usuário (igual à lista de preço é para itens). Os comentários **do orçamento** (`ORCAMENTOS/{id}/OBSERVACAO`) continuam como estão. |
| D2 | **Só assinantes** (`autoRenewing` ou `FORCE_PREMIUM` em dev). Hoje assinantes só existem no Android; no iOS a mesma regra vale (entitlement ativo), sem comportamento legado a preservar. Free vê a entrada com cadeado → tela de assinatura. |
| D3 | Cada comentário tem **nome** e **texto**. O nome **é gerado pela IA ao gravar**, a partir do assunto do texto (ex.: "Garantia de 90 dias"). O usuário pode editar o nome depois. |
| D4 | Botão **"Melhorar com IA"** dentro do modal: reescreve o texto no próprio campo, com **Desfazer**. Nada é gravado sem o usuário tocar em Salvar (P4 do §20). |
| D5 | IA nunca trava o cadastro (P8): se a geração do nome falhar → nome = primeiras palavras do texto (máx. 40 caracteres) e grava assim mesmo. Se "Melhorar" falhar → snackbar de aviso e texto intacto. |
| D6 | Valores persistidos fixos (Regra Zero i18n): campos `NOME`, `TEXTO`, `CRIADOEM`, `ATUALIZADOEM`. Só labels traduzem. |

---

## 1. Firestore

```
EMPRESAS/{uid}/USERS/{uid}/COMENTARIOS/{autoId}
  NOME:          string   # gerado pela IA (editável)
  TEXTO:         string
  CRIADOEM:      timestamp
  ATUALIZADOEM:  timestamp
```

- Regras: `match /EMPRESAS/{uid}/USERS/{uid}/COMENTARIOS/{id}` → `request.auth.uid == uid`.
- Ordenação da lista: `ATUALIZADOEM desc`.

---

## 2. IA — onde fica a chamada ao Gemini

Hoje `firebase_ai` só existe em `chat_assistant/data/datasource/chat_ai_remote_datasource.dart`
(P3). A biblioteca precisa de uma chamada de **texto simples** (sem tools, sem histórico).

**Proposta (menor diff correto):** criar `modules/core/ai_text/` com datasource próprio e
atualizar P3 do §20 para: *"`firebase_ai` só em DataSource (`ChatAiRemoteDatasource` e
`AiTextRemoteDatasource`)"*. Evita que `comment_library` importe o módulo do chat.

```
modules/core/ai_text/
├── ai_text_binds.dart
├── data/datasource/ai_text_remote_datasource.dart   # ÚNICO lugar novo com firebase_ai
├── data/datasource/ai_text_local_datasource.dart    # contador diário (SharedPreferences)
├── data/repository/ai_text_repository_impl.dart     # Map → String, log [AiText] tokens
└── domain/repository/ai_text_repository.dart
```

`AiTextRemoteDatasource.generate({system, prompt, maxOutputTokens, json})` →
`{text, inputTokens, outputTokens}`. Modelo `gemini-3.5-flash-lite`, `temperature 0.3`,
timeout 15 s. Para o nome, `responseMimeType: application/json` com schema `{name}`.

**Custo:** limite **30 chamadas/dia** por usuário (nome + melhorar somam), controlado
por usecase (§20.7). Ao atingir: nome cai no fallback D5 e "Melhorar" mostra aviso.

---

## 3. Estrutura do módulo

```
modules/comment_library/
├── comment_library_binds.dart
├── comment_library_routes.dart                    # /comment-library/list
├── data/
│   ├── datasource/comment_library_remote_datasource.dart   # Firestore COMENTARIOS (Map)
│   ├── model/comment_library_model.dart                    # id, name, text, createdAt, updatedAt (fromMap/toMap)
│   └── repository/comment_library_repository_impl.dart
├── domain/
│   ├── repository/comment_library_repository.dart          # fetch / add / update / delete(list)
│   └── usecase/
│       ├── check_comment_library_access_usecase.dart       # assinante || FORCE_PREMIUM
│       ├── save_library_comment_usecase.dart               # valida, gera nome (IA) c/ fallback, grava
│       ├── improve_comment_text_usecase.dart               # limite diário + prompt + validação da saída
│       ├── generate_comment_name_usecase.dart              # prompt + limpeza (máx 40, sem aspas) + fallback
│       └── add_library_comments_to_budget_usecase.dart     # picker → BudgetCommentRepository.addComment
└── presenter/
    ├── strings/comment_library_pt_string.dart              # labels + prompts da IA
    ├── comment_library_list/                               # = product_price_list
    │   ├── comment_library_list_view.dart
    │   ├── comment_library_list_view_model.dart
    │   └── components/
    │       ├── comment_library_list_header.dart            # busca + botão novo
    │       ├── comment_library_card.dart                   # nome (negrito) + 2 linhas do texto
    │       └── comment_library_selection_bar.dart          # excluir em lote
    ├── comment_library_creator/                            # modal-tela (§19) = product_price_creator
    │   ├── comment_library_creator_view.dart               # + showCommentLibraryCreatorBottomModal → bool?
    │   ├── comment_library_creator_view_model.dart
    │   └── components/
    │       ├── comment_library_name_field.dart             # só no modo editar (criar: nome vem da IA)
    │       ├── comment_library_text_field.dart             # multilinha, contador 1000
    │       └── comment_library_improve_button.dart         # "✨ Melhorar com IA" / loading / "Desfazer"
    └── comment_library_picker/                             # modal-tela = product_price_picker
        ├── comment_library_picker_view.dart
        ├── comment_library_picker_view_model.dart
        └── components/
            ├── comment_library_picker_header.dart          # = ProductPricePickerHeader sem categoria
            ├── comment_library_picker_card.dart            # = ProductPricePickerCard (nome + texto)
            └── comment_library_picker_footer.dart          # = ProductPricePickerFooter sem total
```

Regras aplicadas: nenhum `class _Widget` nas Views (§2.1); componentes recebem dados +
callbacks, nunca o VM; ações async via `Command` (§4.4); feedback via
`DisplayAlertRepository` (§18); cores de `colors.dart` (§15); regra de negócio só em
usecase; Firestore/firebase_ai só em DataSource.

---

## 4. Fluxos

### 4.1 Criar
1. Lista → "+" → `showCommentLibraryCreatorBottomModal(context, comment: null)`.
2. Usuário digita o texto. (Opcional) toca **Melhorar com IA** →
   `improveCommand` → `ImproveCommentTextUsecase` → campo recebe o texto novo,
   botão vira **Desfazer** até a próxima edição manual.
3. **Salvar** → `saveCommand` → `SaveLibraryCommentUsecase`:
   - texto vazio → erro inline no campo (§17.4), sem chamar IA;
   - `GenerateCommentNameUsecase(text)` → nome (ou fallback D5);
   - `repo.add({NOME, TEXTO, CRIADOEM, ATUALIZADOEM})`.
4. Sucesso → `pop(true)`; a lista recarrega + snackbar "Comentário salvo como *{nome}*".
   Erro → modal continua aberto com o texto preservado (§19.3 r5).

### 4.2 Editar
- Mesmo modal, título "Editar comentário", mostra `comment_library_name_field` preenchido.
- Texto alterado e nome **não** editado manualmente → regenera o nome ao salvar.
  Nome editado pelo usuário → respeita o nome dele (sem IA).
- Botão Salvar destaca só quando dirty (§17.5).

### 4.3 Usar no orçamento — fluxo idêntico ao de itens (produto/serviço)

Espelha exatamente `BudgetListItemsView._addItem()` (`budget_list_items_view.dart:93`):

```dart
// budget_comment_list_view.dart (assinante)
Future<void> _addComment() async {
  if (await _viewModel.getLibraryCount() > 0) {
    if (!mounted) return;
    final value = await _displayAlert.listNotification(
      context,
      createLabel: CommentLibraryStrings.optionCreate,   // "Criar novo comentário"
      selectLabel: CommentLibraryStrings.optionSelect,   // "Selecionar da lista de comentários"
    );
    if (value == CommentLibraryStrings.optionCreate) {
      await _showCreator();            // criar na hora
    } else if (value == CommentLibraryStrings.optionSelect) {
      await _openCommentList();        // modal-lista
    }
  } else {
    await _showCreator();              // biblioteca vazia → cria direto
  }
}
```

| Passo | Itens (hoje) | Comentários (novo) |
|---|---|---|
| Botão "+" do orçamento | `_addItem()` | `_addComment()` |
| Escolha | `ItemOptionBottomModalWidget` (via `listNotification`) | **mesmo widget**, com labels por parâmetro |
| Lista vazia | abre o creator direto | abre o creator direto |
| Criar na hora | `showProductPriceCreatorBottomModal(fromListItem: true)` → grava na lista de preço **e** no orçamento (§14) | `showCommentLibraryCreatorBottomModal(budgetId: …)` → grava na biblioteca (nome pela IA) **e** em `OBSERVACAO` do orçamento |
| Selecionar | `showProductPricePickerBottomModal(budgetId)` → `bool` | `showCommentLibraryPickerBottomModal(budgetId)` → `bool` |
| Depois | recarrega a lista + snackbar `cartAddSuccess` | recarrega comentários + snackbar "Comentários adicionados" |

**Ajuste no `DisplayAlertRepository.listNotification`:** hoje o
`ItemOptionBottomModalWidget` tem os textos fixos. Adicionar parâmetros opcionais
`createLabel`/`selectLabel` (default = textos atuais de itens) — itens não mudam.

**Creator com `budgetId`** (equivalente ao `fromListItem`): `SaveLibraryCommentUsecase`
recebe `budgetId?`; quando presente, depois de gravar na biblioteca grava o `TEXTO` em
`OBSERVACAO` via `BudgetCommentRepository`. Se a 2ª gravação falhar, o modal fica
aberto com erro (o comentário já está na biblioteca — mensagem diz isso).

**Modal-lista = cópia visual do `ProductPricePickerView`:**
- Mesmo container: altura 80% (`_heightFactor`), `bgColor`, cantos 20, respeita teclado.
- Header igual (`ProductPricePickerHeader`): título "Lista de comentários", busca
  (nome + texto), botão fechar → `pop(false)`. **Sem** filtro de categoria.
- Card igual ao `ProductPricePickerCard`, estado selecionado igual; mostra **nome** +
  2 linhas do texto. Toque **alterna** seleção direto (não há modal de quantidade).
- Footer igual ao `ProductPricePickerFooter`: aparece com ≥ 1 selecionado,
  "Adicionar (n)" com loading do `addAllCommand`; sem total em R$.
- `addAllCommand` → `AddLibraryCommentsToBudgetUsecase(budgetId, selecionados)`:
  completed → `pop(true)`; error → snackbar e continua aberto (mesmo `_onAddAllChanged`).
- O comentário do orçamento é **cópia**: editar a biblioteca depois não altera
  orçamentos antigos.

**Free (não-assinante):** `_addComment()` mantém o comportamento atual
(`showCommentFormDialog`), sem opção de lista e sem IA — mudança zero.

### 4.4 Entrada da tela
- Menu de configurações (`main_config_menu`) → item "Meus comentários", ao lado
  de "Lista de preço". Rota `/comment-library/list` registrada em `app_routes.dart`.

---

## 5. Prompts (em `comment_library_pt_string.dart`)

- **Nome:** "Você nomeia comentários de orçamentos de prestadores de serviço. Leia o
  texto e responda só JSON `{\"name\": \"...\"}` com 2 a 5 palavras que resumam o
  assunto (ex.: Garantia de 90 dias, Forma de pagamento). Sem pontuação final."
- **Melhorar:** "Reescreva o comentário de orçamento abaixo em português claro,
  profissional e cordial. Corrija ortografia e gramática. Mantenha todos os valores,
  prazos, datas e condições exatamente. Não invente informação. Responda só o texto."
- Validação no usecase: resposta vazia, > 1000 caracteres ou números diferentes do
  original (valores/prazos sumiram) → trata como falha (D5).

---

## 6. Binds / injeção

- `AiTextBinds` (core): datasource remoto/local, `AiTextRepository`.
- `CommentLibraryBinds`: datasource, repository, 5 usecases
  (`registerFactory` para usecases, `registerLazySingleton` para repo — padrão §6.8).
- Registrar ambos em `injection.dart`.

---

## 7. Fases e checklist

| Fase | Entrega | Pronto quando |
|------|---------|---------------|
| 1 | `core/ai_text` + testes do repo/limite diário | `generate` retorna texto e respeita 30/dia |
| 2 | Data + domain do `comment_library` + testes dos 5 usecases (IA mockada: sucesso, timeout, limite, saída inválida) | fallback do nome coberto; texto vazio não chama IA |
| 3 | Lista + modal-tela creator (criar/editar/excluir, Melhorar/Desfazer) | fluxo 4.1/4.2 no simulador Android e iOS |
| 4 | `_addComment()` igual ao `_addItem()` (escolha criar/selecionar), creator com `budgetId`, modal-lista igual ao picker de preço, labels no `listNotification` | criar na hora grava biblioteca + orçamento; selecionar copia para `OBSERVACAO`; itens sem regressão |
| 5 | Gate de assinante + entrada no menu + regras Firestore + atualizar ARCHITECTURE (§9 módulos, §20 P3/custo) | free vê cadeado; FORCE_PREMIUM libera em dev |

Testes manuais obrigatórios: sem internet (salva com nome fallback), IA lenta
(timeout 15 s não trava o botão), limite diário, assinante Android atualizando build
antigo → novo (nada muda no que já existe).

---

## 8. Fora do escopo
- Alterar o comportamento atual dos comentários do orçamento.
- IA para usuários free.
- Sincronizar biblioteca → orçamentos já criados.
