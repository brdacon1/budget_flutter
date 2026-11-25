# Plano de Implementação — Menus numerados → Botões de opção

> **Módulo:** `lib/modules/chat_assistant`
> **Base:** `.pi/ARCHITECTURE.md` (MVVM + Clean, modo *ponytail*) e `.pi/CHAT_ASSISTANT_SPEC.md`
> **Objetivo:** todo menu que hoje pede "digite o número da opção" passa a exibir
> **botões empilhados verticalmente** (um embaixo do outro) dentro da bolha do bot,
> no mesmo visual dos botões `Sim` / `Não` já existentes, **sem os números** no texto.

---

## 1. Resultado esperado

**Hoje**

```
Qual informação do PDF você quer mudar?

1. Nome da empresa
2. Telefone
...
7. Modelo de PDF

0. Voltar ao menu
Digite o numero da opção desejada e envie
```

**Depois**

```
Qual informação do PDF você quer mudar?

[        Nome da empresa        ]
[           Telefone            ]
[            Email              ]
[            CNPJ               ]
[           Endereço            ]
[             Logo              ]
[        Modelo de PDF          ]
(        Voltar ao menu         )   ← outlined, separado das demais
Toque na opção desejada
```

- Botões com o mesmo estilo do `_InlineButtons` atual (`0xFF00BFA5`, texto preto
  negrito, `BorderRadius.circular(20)`), mas em **`Column` com
  `CrossAxisAlignment.stretch`** e `8px` entre eles. Nada de `Wrap`.
- "Voltar ao menu" é sempre o último botão, em `OutlinedButton` ciano (mesmo
  visual do "Editar seleção"), para não competir com as opções.
- Ao tocar, aparece a bolha do usuário com o **texto do botão** (ex: "Telefone"),
  não com o número.
- Digitar o número **continua funcionando** (fallback silencioso, sem custo) —
  nenhum `switch` dos UseCases muda.

---

## 2. Inventário — onde existem menus numerados hoje

| # | Local | Menu | Opções → valor |
|---|-------|------|----------------|
| 1 | `domain/usecase/reset_chat_to_menu_usecase.dart` | Menu principal | Criar orçamentos `1`, Cadastrar produtos e serviços `2`, Editar PDF `3`, Trocar nome de usuário `4` (sem voltar) |
| 2 | `domain/usecase/show_price_list_menu_usecase.dart` | Lista de preço | Ver lista `1`, Adicionar produto `2`, Voltar `0` |
| 3 | `domain/usecase/show_pdf_edit_menu_usecase.dart` | Editar PDF | Nome `1` … Modelo de PDF `7`, Voltar `0` |
| 4 | `domain/usecase/handle_pdf_edit_confirm_option_usecase.dart` (case `'1'`) | Editar PDF (cópia) | idem #3 |
| 5 | `domain/usecase/on_logo_updated_usecase.dart` | Editar PDF (cópia) | idem #3 |
| 6 | `presenter/.../chat_assistant_view_model.dart` → `onPdfModelSelected()` | Editar PDF (cópia) | idem #3 |
| 7 | `domain/usecase/handle_pdf_edit_menu_option_usecase.dart` (case `'5'`) | "Tem CEP?" (endereço do PDF) | Sim `1`, Não `2`, Voltar `0` |
| 8 | `domain/usecase/handle_pdf_edit_menu_option_usecase.dart` (case `'6'`) | Logo | Ver logo `1`, Inserir/Alterar logo `2`, Voltar `0` *(hoje não mostra o voltar)* |
| 9 | `domain/usecase/handle_pdf_field_input_usecase.dart` → `_save()` | Pós-edição PDF | Continuar editando PDF `1`, Voltar ao menu principal `2` |
| 10 | VM → `_finishPdfAddressFlow()` | Pós-edição PDF (endereço) | idem #9 |
| 11 | `domain/usecase/show_change_username_menu_usecase.dart` | Trocar nome | Alterar nome de usuário `1`, Voltar `0` |
| 12 | VM → `onUsernameChanged()` | Pós troca de nome | Trocar novamente `1`, Voltar ao menu principal `2` *(hoje duplica com "0. Voltar")* |

**Prompts de digitação livre que só exibem "0. Voltar ao menu"** (o usuário digita
o dado; o "0." vira um único botão "Voltar ao menu"):

| Local | Prompt |
|-------|--------|
| `handle_pdf_edit_menu_option_usecase.dart` → `_sendTextWithBackOption()` | Nome / Telefone / Email / CNPJ do PDF |
| VM → `_askForCep()` | "Qual o CEP?" |
| VM → `_goToManualAddress()` | "Informe a rua…" |

**Fora do escopo — NÃO MEXER em nada que já tem botão.** Só entram neste plano
as opções em que o usuário precisa **digitar um número e enviar**. Ficam
exatamente como estão (mensagem, payload, layout e roteamento):

- `SIM/NÃO` de endereço e de comentários (`inlineButtons`)
- `Confirmar dados / Editar nome / Editar telefone`
- `Sim/Não` do `pdfEditConfirmEntry`
- `Confirmar endereço / Corrigir endereço` do `confirmCepAddress` (inclusive o
  texto "0. Voltar ao menu" dessa mensagem — ela já tem botões, não é alterada)
- `Editar comentários / Finalizar e gerar link`, `Abrir lista de produtos`
- `contactPicker`, `action`, `productList`, `image`
- `_InlineButtons`, `handleAction` e `_handleAction` da View: sem alteração

---

## 3. Desenho da solução

### 3.1 Contrato da mensagem (Domain)

Novo tipo em `ChatMessageType`: **`optionList`**.

Payload:

```dart
{
  'options': [
    {'label': 'Nome da empresa', 'value': '1'},
    {'label': 'Telefone',        'value': '2'},
    // ...
    {'label': 'Voltar ao menu',  'value': '0'},
  ],
  'optionsStep': 'pdfEditMenu',   // step a que o menu pertence
}
```

- `value` é exatamente o que o usuário digitaria hoje → os `switch (option)` dos
  UseCases **não mudam**.
- `optionsStep` impede que um botão de um menu antigo (rolado para cima) dispare
  uma opção num step diferente.
- `List<Map<String,String>>` é serializável — `ChatBudgetRepositoryImpl` já
  persiste `payload` como está no Firestore, nada muda no Data.

Factory na própria entidade para eliminar as ~12 construções repetidas:

```dart
// domain/entity/chat_message_entity.dart
factory ChatMessageEntity.botOptions({
  required String content,
  required List<String> labels,   // value = posição (1..n)
  required String step,
  String? backLabel,              // se != null, adiciona {'label': backLabel, 'value': '0'}
}) {
  final now = DateTime.now();
  return ChatMessageEntity(
    id: now.millisecondsSinceEpoch.toString(),
    sender: ChatSender.bot,
    type: ChatMessageType.optionList,
    content: content,
    payload: {
      'options': [
        for (var i = 0; i < labels.length; i++)
          {'label': labels[i], 'value': '${i + 1}'},
        if (backLabel != null) {'label': backLabel, 'value': '0'},
      ],
      'optionsStep': step,
    },
    timestamp: now,
  );
}
```

> A factory recebe `backLabel` como parâmetro (não importa `ChatBudgetStrings`),
> então o domínio não ganha nova dependência de presenter.

### 3.2 Strings (`presenter/strings/chat_budget_pt_string.dart`)

Trocar as strings de opções numeradas por **listas de labels** (PT/EN):

| Remover | Adicionar |
|---------|-----------|
| `mainMenuOptions` (String) | `mainMenuOptionLabels` → `List<String>` |
| `priceListMenuOptions` | `priceListMenuOptionLabels` |
| `pdfEditMenuOptions` | `pdfEditMenuOptionLabels` |
| `logoMenuOptions` | `logoMenuOptionLabels` |
| `changeUsernameMenuOptions` | `changeUsernameMenuOptionLabels` (corrigir typo "Chance") |
| `changeUsernameRetryQuestion` | `changeUsernameRetryQuestion` (só a pergunta) + `changeUsernameRetryOptionLabels` |
| `menuBackOption` (`'0. Voltar ao menu'`) | `menuBackLabel` (`'Voltar ao menu'`) |
| texto inline `'1. Continuar editando PDF\n2. Voltar…'` | `pdfEditNextQuestion` + `pdfEditNextOptionLabels` |
| texto inline `'1. Sim\n2. Não'` | `yesNoOptionLabels` |

Ajustar textos de instrução:

- `typeOptionInstruction` → `'Toque na opção desejada'` / `'Tap the desired option'`
- `menuInvalidOption` → `'Opção inválida. Toque em uma das opções acima.'`
- VM linha `'Opção inválida. Digite 1 para Sim ou 2 para Não.'` → usar `menuInvalidOption`.

### 3.3 Componente de UI (Presenter)

Novo arquivo público (regra 2.1 da arquitetura — nada de classe privada):

`presenter/chat_assistant/components/chat_message_option_buttons.dart`

```dart
class ChatMessageOptionButtons extends StatelessWidget {
  const ChatMessageOptionButtons({
    super.key,
    required this.options,     // List<Map<String, String>>
    required this.enabled,     // false quando optionsStep != step atual
    required this.onSelect,    // (value, label)
  });
  // Column(stretch) → ElevatedButton por opção; value '0' → OutlinedButton ciano.
  // spacing 8; padding vertical 12; texto centralizado e negrito.
  // enabled == false → onPressed: null (botão fica apagado).
}
```

Em `chat_message_bubble.dart`:

- Novo callback `final void Function(String value, String label)? onOptionSelect;`
  e `final bool optionsEnabled;`.
- `_buildExtraContent()` → `case ChatMessageType.optionList:` retorna
  `ChatMessageOptionButtons(...)` lendo `payload['options']`.
- A dica em itálico passa a aparecer quando `type == optionList` (remove a flag
  `showMenuHint` do payload — um campo a menos).

### 3.4 Roteamento do toque (ViewModel)

Mudança mínima em `chat_assistant_view_model.dart`:

```dart
late final selectOptionCommand =
    Command1<void, ({String value, String label, String step})>(_selectOption);

bool isOptionsActive(ChatMessageEntity msg) =>
    msg.payload?['optionsStep'] == _step.name;

Future<Result<void>> _selectOption(
    ({String value, String label, String step}) o) async {
  if (o.step != _step.name) return Result.ok(null); // menu antigo
  return _sendText(o.value, displayText: o.label);
}
```

E em `_sendText`:

```dart
Future<Result<void>> _sendText(String text, {String? displayText}) async {
  ...
  if (clean == '0' && _step != ChatFlowStep.mainMenu) {
    if (displayText != null) {
      await _sendUserMessageWithId(_generateMessageId(), displayText);
    }
    await _backToMainMenu();
    return Result.ok(null);
  }
  ...
  await _sendUserMessageWithId(msgId, displayText ?? clean, payload: userPayload);
  // roteamento continua usando `clean` (o value)
```

> Assim todo menu numerado vai pelo mesmo caminho (`_sendText` → UseCase),
> seja digitado ou tocado. Zero lógica nova nos UseCases, e nenhum step novo
> no `if/else` de `_sendText`. `handleAction` (botões existentes) não muda.

### 3.5 View (`chat_assistant_view.dart`)

No `itemBuilder`:

```dart
return ChatMessageBubble(
  message: msg,
  onAction: (action) => _handleAction(action, msg),
  optionsEnabled: _vm.isOptionsActive(msg),
  onOptionSelect: (value, label) => _vm.selectOptionCommand.execute(
    (value: value, label: label, step: msg.payload!['optionsStep'] as String),
  ),
  onEditMessage: ...,
);
```

Navegações (`open_price_list`, `open_pdf_model_select`, `open_change_name`,
`open_logo_edit`…) continuam vindo de `pendingNavigation` — nenhuma mudança.

---

## 4. Passo a passo de implementação

> Ordem pensada para o app compilar a cada passo.

### Passo 1 — Domain: tipo + factory
- [ ] `chat_message_entity.dart`: adicionar `optionList` ao enum e a factory `botOptions`.

### Passo 2 — Strings
- [ ] Criar as listas de labels e `menuBackLabel` (tabela 3.2) em PT/EN.
- [ ] Ajustar `typeOptionInstruction` e `menuInvalidOption`.
- [ ] Manter as strings antigas até o passo 5 e removê-las no final.

### Passo 3 — Componente
- [ ] Criar `components/chat_message_option_buttons.dart`.
- [ ] `chat_message_bubble.dart`: novos parâmetros, `case optionList`, dica baseada no tipo.

### Passo 4 — ViewModel + View
- [ ] `selectOptionCommand`, `isOptionsActive`, `displayText` em `_sendText`.
- [ ] Trocar `'Opção inválida. Digite 1…'` por `menuInvalidOption`.
- [ ] View passa `optionsEnabled` / `onOptionSelect` para a bolha.

### Passo 5 — Migrar cada menu para `ChatMessageEntity.botOptions`

| Arquivo | `labels` | `step` | `backLabel` |
|---------|----------|--------|-------------|
| `reset_chat_to_menu_usecase.dart` | `mainMenuOptionLabels` | `mainMenu` | — |
| `show_price_list_menu_usecase.dart` | `priceListMenuOptionLabels` | `priceListMenu` | `menuBackLabel` |
| `show_pdf_edit_menu_usecase.dart` | `pdfEditMenuOptionLabels` | `pdfEditMenu` | `menuBackLabel` |
| `handle_pdf_edit_menu_option_usecase.dart` case `'5'` | `yesNoOptionLabels` | `askHasCep` | `menuBackLabel` |
| `handle_pdf_edit_menu_option_usecase.dart` case `'6'` | `logoMenuOptionLabels` | `logoMenu` | `menuBackLabel` |
| `handle_pdf_edit_menu_option_usecase.dart` `_sendTextWithBackOption` | `[]` | `pdfEditFieldInput` | `menuBackLabel` |
| `handle_pdf_field_input_usecase.dart` `_save` | `pdfEditNextOptionLabels` | `pdfEditConfirm` | — |
| VM `_finishPdfAddressFlow` | `pdfEditNextOptionLabels` | `pdfEditConfirm` | — |
| `show_change_username_menu_usecase.dart` | `changeUsernameMenuOptionLabels` | `changeUsername` | `menuBackLabel` |
| VM `onUsernameChanged` | `changeUsernameRetryOptionLabels` | `changeUsernameResult` | — |
| VM `_askForCep` | `[]` | `askCep` | `menuBackLabel` |
| VM `_goToManualAddress` | `[]` | `askStreetManual` | `menuBackLabel` |

> `_submitCep` (`confirmCepAddress`) **não entra** — já tem botões.

> Nos UseCases que enviam via `_chatRepo.sendMessage(...)`, basta trocar o
> `ChatMessageEntity(...)` por `ChatMessageEntity.botOptions(...)`. Na VM, enviar
> com `_chatRepo.sendMessage(ChatMessageEntity.botOptions(...))`.

### Passo 6 — Deduplicar o menu de "Editar PDF" (deletar > adicionar)
O mesmo texto do menu PDF está copiado em 4 lugares (#3–#6 do inventário).
- [ ] `HandlePdfEditConfirmOptionUsecase` e `OnLogoUpdatedUsecase` passam a receber
  `ShowPdfEditMenuUsecase` no construtor e chamá-lo.
- [ ] `onPdfModelSelected()` na VM usa o `_showPdfEditUsecase` que já está injetado.
- [ ] Atualizar `chat_assistant_binds.dart` com a nova dependência.

### Passo 7 — Limpeza
- [ ] Remover `mainMenuOptions`, `priceListMenuOptions`, `pdfEditMenuOptions`,
  `logoMenuOptions`, `changeUsernameMenuOptions`, `menuBackOption` e a flag
  `showMenuHint`.
- [ ] `flutter analyze` sem warnings novos.

### Passo 8 — Documentação
- [ ] `CHAT_ASSISTANT_SPEC.md`: adicionar `optionList` à tabela 4.1, atualizar 4.2
  (menu principal sem números, escape global = botão "Voltar ao menu" ou `0`),
  e a seção 2.1 (payload `options` / `optionsStep`).

---

## 5. Arquivos afetados (resumo)

| Camada | Arquivo | Tipo de mudança |
|--------|---------|-----------------|
| Domain | `entity/chat_message_entity.dart` | enum + factory |
| Domain | `usecase/reset_chat_to_menu_usecase.dart` | usa `botOptions` |
| Domain | `usecase/show_price_list_menu_usecase.dart` | usa `botOptions` |
| Domain | `usecase/show_pdf_edit_menu_usecase.dart` | usa `botOptions` |
| Domain | `usecase/show_change_username_menu_usecase.dart` | usa `botOptions` |
| Domain | `usecase/handle_pdf_edit_menu_option_usecase.dart` | usa `botOptions` (3 pontos) |
| Domain | `usecase/handle_pdf_field_input_usecase.dart` | usa `botOptions` |
| Domain | `usecase/handle_pdf_edit_confirm_option_usecase.dart` | reaproveita `ShowPdfEditMenuUsecase` |
| Domain | `usecase/on_logo_updated_usecase.dart` | reaproveita `ShowPdfEditMenuUsecase` |
| — | `chat_assistant_binds.dart` | nova dependência nos 2 UseCases acima |
| Presenter | `strings/chat_budget_pt_string.dart` | labels em lista |
| Presenter | `chat_assistant/chat_assistant_view_model.dart` | `selectOptionCommand`, `displayText`, 6 mensagens migradas |
| Presenter | `chat_assistant/chat_assistant_view.dart` | passa callbacks para a bolha |
| Presenter | `chat_assistant/components/chat_message_bubble.dart` | `case optionList` |
| Presenter | `chat_assistant/components/chat_message_option_buttons.dart` | **novo** |

**Data:** nenhuma mudança.
**Firestore (`CHAT_SCRIPT`):** nenhuma mudança — nenhum menu numerado vem do script.

---

## 6. Riscos e decisões

| Ponto | Decisão |
|-------|---------|
| Botões de menus antigos no histórico | Desabilitados visualmente (`optionsEnabled`) e ignorados na VM se `optionsStep != step`. Mesmo step repetido (ex: `pdfEditMenu` exibido 2×) mantém ambos ativos — semântica idêntica, sem risco. |
| Digitar número ainda funciona? | Sim. Os `value`s são os números de hoje; nada muda nos UseCases. Útil também para a Fase 1 do roadmap LLM (o `IntentClassifier` só precisa produzir o `value`). |
| Voltar com `0` não exibia bolha do usuário | Ao tocar "Voltar ao menu", a bolha "Voltar ao menu" é exibida antes do menu principal. Digitar `0` mantém o comportamento atual. |
| Mensagens que já têm botão | Não são alteradas (decisão do produto). O plano mexe apenas em opções que hoje exigem digitar um número e enviar. |
| Largura dos botões | Esticam até a largura da bolha (máx. 75% da tela), garantindo alinhamento uniforme. |
| `askStreetManual` | Input é o formulário de endereço; o botão "Voltar ao menu" na bolha funciona porque `0` é tratado globalmente em `_sendText`. |

---

## 7. Roteiro de testes manuais

1. Abrir o chat → menu principal mostra 4 botões empilhados, sem números, sem "Voltar".
2. Tocar **Criar orçamentos** → bolha do usuário "Criar orçamentos" → fluxo `askClient`.
3. Reiniciar → **Cadastrar produtos e serviços** → 2 botões + Voltar; testar **Ver lista** e **Adicionar** (navegação abre).
4. **Editar PDF** → Sim → 7 botões + Voltar. Testar cada opção:
   - Nome/Telefone/Email/CNPJ → prompt com botão "Voltar ao menu"; digitar valor → pós-edição com 2 botões.
   - Endereço → Sim/Não/Voltar empilhados → Sim → CEP (botão Voltar) → Confirmar/Corrigir **inalterado**.
   - Logo → Ver logo / Inserir-Alterar / Voltar.
   - Modelo de PDF → abre seleção → ao voltar, menu PDF com botões.
5. **Trocar nome de usuário** → Alterar / Voltar → após o modal, Trocar novamente / Voltar ao menu principal (sem duplicar o voltar).
6. Rolar para um menu antigo e tocar um botão → nada acontece (botão apagado).
7. Digitar `3` no menu principal → continua funcionando (fallback).
8. Digitar `9` → mensagem "Opção inválida. Toque em uma das opções acima."
9. Trocar idioma do aparelho para EN → labels em inglês.
10. Regressão: todos os botões que já existiam (Sim/Não, Confirmar dados, Confirmar/Corrigir endereço, Finalizar e gerar link…) continuam idênticos e funcionando.

**Testes automatizados sugeridos** (não existem testes para o módulo hoje):
- Unit: `ChatMessageEntity.botOptions` gera `value`s `1..n` e `0` para o voltar.
- Widget: `ChatMessageOptionButtons` renderiza N botões em coluna e chama `onSelect(value, label)`; com `enabled: false` não chama.
