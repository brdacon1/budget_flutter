# Plano — Documento da Empresa: CNPJ **ou** CPF (com validação)

> Segue `.pi/ARCHITECTURE.md` (regra de negócio = UseCase, models no módulo dono, strings no módulo, View sem lógica).

## 0. Regra Zero — não quebrar dados persistidos

- O campo continua **`OwnerPdf.cnpj`** e a chave no backend continua **`'CNPJ'`** (`lib/modules/auth/data/model/owner_pdf.dart:33,48`). Nada de renomear/migrar.
- O valor salvo passa a ser **CPF mascarado** (`000.000.000-00`) **ou CNPJ mascarado** (`00.000.000/0000-00`, inclusive alfanumérico). Os geradores de PDF (`addRow(owner.cnpj)`) já imprimem a string como está → mudança zero no PDF.
- Só os **labels** mudam para "CNPJ / CPF".

## 1. Validação — `DocumentValidator` vira UseCase(s) no domínio

Validar CPF/CNPJ é regra de negócio → **não** criar `utils/document_validator.dart` estático. É usado por `pdf` (tela Editar PDF) e `chat_assistant`, e o dono do dado é o `pdf`/`OwnerPdf`.

Criar em `lib/modules/pdf/domain/usecase/document/`:

| Arquivo | Responsabilidade |
|---|---|
| `document_type_enum.dart` | `enum DocumentType { cpf, cnpj }` |
| `validate_document_usecase.dart` | `ValidateDocumentUsecase.call(String? value) → DocumentValidationResult` — limpa (`[.\/\-\s]`, upper), decide CPF (11 dígitos) / CNPJ (14, alfanumérico) e roda os algoritmos do validator colado (`_validateCpf`, `_validateCnpj`, `_cnpjCharValue`) como métodos privados. |
| `document_validation_result.dart` | `{ bool isValid; DocumentType? type; String? cleaned; DocumentValidationError? error }` com `enum DocumentValidationError { empty, invalidCpf, invalidCnpj, invalidLength }` — **sem strings de UI no domínio**; a camada presenter traduz o erro. |
| `format_document_usecase.dart` | Conversão pura: recebe `cleaned` + `type` e devolve a máscara (`###.###.###-##` ou `AA.AAA.AAA/AAAA-##`). Substitui a máscara montada à mão em `handle_pdf_field_input_usecase.dart:82`. |

Registrar ambos em `lib/modules/pdf/binds` (e expor no `chat_assistant/binds` via `getIt`).

Testes unitários (`test/modules/pdf/domain/usecase/document/`): CPF válido/inválido/repetido (`111.111.111-11`), CNPJ numérico válido/inválido, CNPJ alfanumérico válido (ex.: `12.ABC.345/01DE-35`), vazio, tamanho errado, com/sem máscara.

## 2. Strings (i18n — só labels)

`chat_assistant_pt_string.dart`:
- `pdfEditMenuOptionLabels[3]`: `'CNPJ'` → `'CNPJ / CPF'` (en: `'CNPJ / CPF'` ou `'Tax ID (CNPJ / CPF)'`).
- `pdfEditAskCnpj` → "Digite o CNPJ ou CPF da empresa:".
- `pdfEditCurrentDocument(String v)` → `'O CNPJ / CPF atual é "$v".'` (tira o texto fixo de `handle_pdf_edit_menu_option_usecase.dart:52`).
- Novos: `documentEmpty`, `documentInvalidCpf` ("CPF inválido."), `documentInvalidCnpj` ("CNPJ inválido."), `documentInvalidLength` ("Digite um CPF ou CNPJ válido."), `documentFormTitle`, `documentFormHint`, `documentFormSave`.
- `pdfEditSuccessCnpj` → `pdfEditSuccessDocument(DocumentType t)` ("CPF atualizado…" / "CNPJ atualizado…").
- Helper no presenter: `ChatAssistantStrings.documentError(DocumentValidationError e)`.

`pdf_pt_string.dart`: `cnpjHint` → `'CNPJ / CPF'` + mesmas mensagens de erro (`PdfStrings.documentError(...)`).

## 3. Chat Assistant — campo igual ao fluxo de endereço

Hoje a opção 4 só pede texto livre no `ChatEditAwareInputBar`. Passa a abrir um **formulário dedicado no input area**, como `ChatManualAddressForm`.

### 3.1 Step novo
- `chat_flow_step_enum.dart`: adicionar `pdfEditDocumentForm`.
- `HandlePdfEditMenuOptionUsecase` case `'4'`: envia a mensagem (valor atual em `highlight` + `pdfEditAskCnpj`) com back option e retorna `ChatMenuResult('pdfEditDocumentForm', pdfField: 'cnpj')`.

### 3.2 Componente
`chat_assistant/presenter/chat_assistant/components/chat_document_form.dart` — `StatelessWidget` (modal simples, sem VM própria):
- `TextFormField` com `controller`, `inputFormatters: [mask]`, `errorText`, teclado `TextInputType.text` (CNPJ alfanumérico) com `textCapitalization.characters`.
- Botões **Salvar** (`onSubmit`) e **Voltar** (`onCancel`) — mesmo visual (`chatBarColor`, `chatDividerColor`) do `ChatManualAddressForm`.
- Recebe tudo por parâmetro; nenhuma lógica.

### 3.3 Máscara dinâmica
No VM, `documentController` + `MaskTextInputFormatter` cuja máscara troca por tamanho do texto limpo: ≤11 → `###.###.###-##`; >11 → `AA.AAA.AAA/AAAA-##` (filtro `A: [A-Za-z0-9]`, `#: [0-9]`). Usar `updateMask` no `onChanged`. (Alternativa simples se a troca de máscara ficar instável: sem máscara durante digitação e formatar no submit via `FormatDocumentUsecase`.)

### 3.4 ViewModel (`chat_assistant_view_model.dart`)
- `final documentController = TextEditingController();` + `dispose`.
- `bool get showDocumentForm => _step == ChatFlowStep.pdfEditDocumentForm;`
- `String? _documentError; String? get documentError` (já traduzido via strings).
- Ao entrar no step: pré-preencher `documentController` com `owner.cnpj` atual (o usecase do menu pode devolver o valor atual no `ChatMenuResult`).
- `late final Command0<void> submitDocumentCommand = Command0(_submitDocument);`
  - chama `HandlePdfDocumentInputUsecase` (abaixo); se inválido → seta `_documentError`, `notifyListeners`, mantém step; se ok → limpa controller/erro, `_setStepFromName(result.nextStep)` (vai pro `pdfEditConfirm`, igual aos demais campos).
- `cancelDocumentForm()` → volta ao `pdfEditMenu` (mesmo comportamento do back label).
- Reset em `_resetState` (junto de `_isPdfEditAddressMode = false`, ~linha 355).

### 3.5 UseCase do chat
Refatorar o case `'cnpj'` de `HandlePdfFieldInputUsecase` (ou extrair `HandlePdfDocumentInputUsecase`, preferível por SRP):
```
validate = _validateDocument(value)
if (!valid) → return ChatMenuResult('pdfEditDocumentForm', pdfField: 'cnpj', error: validate.error)
masked = _formatDocument(validate.cleaned!, validate.type!)
_save('cnpj', masked, successMsg: ChatAssistantStrings.pdfEditSuccessDocument(type) + ' $masked')
```
- Adicionar `DocumentValidationError? error` em `ChatMenuResult`.
- Não mandar bolha de erro no chat — o erro aparece no próprio campo (como validação de formulário). Opcional: também mandar a bolha se o usuário digitar no input livre.

### 3.6 View (`chat_assistant_view.dart` → `_buildInputArea`, ~linha 516)
```dart
if (_vm.showDocumentForm) {
  return ChatDocumentForm(
    controller: _vm.documentController,
    mask: _vm.documentMask,
    errorText: _vm.documentError,
    onChanged: _vm.onDocumentChanged,
    onSubmit: () => _vm.submitDocumentCommand.execute(),
    onCancel: _vm.cancelDocumentForm,
  );
}
```
`ListenableBuilder` no `submitDocumentCommand.running` para desabilitar o botão.

### 3.7 IA do chat
Verificar `chat_script_repository_impl.dart` / prompts do agente que citam "CNPJ" para aceitar "CPF" como intenção de editar esse mesmo campo (`grep -rni cnpj lib/modules/chat_assistant`).

## 4. Tela Editar PDF (`lib/modules/pdf/presenter/pdf_edit/`)

- `pdf_edit_view_model.dart:47`: `maskCnpj` fixo `##.###.###/0001-##` (bug: força 0001) → máscara dinâmica CPF/CNPJ igual à do chat; renomear para `maskDocument`, `cpfText` → `documentText`.
- `validator` do campo → `ValidateDocumentUsecase` injetado no VM (`String? validateDocument(String?)` traduzindo o erro). Campo **opcional**: vazio é válido nessa tela (empresa pode não ter documento); só valida se preenchido. Confirmar com produto se no chat também é opcional (sugestão: no chat obrigatório, pois o usuário entrou para editar; botão Voltar cobre a desistência).
- No `save` (~linha 123): salvar `FormatDocumentUsecase(...)`.
- `pdf_edit_enterprise_card.dart`: hint `PdfStrings.cnpjHint` ("CNPJ / CPF"), receber `validator` e `onChanged`.

## 5. Ordem de implementação

1. UseCases de validação/formatação + testes unitários.
2. Strings (pt/en).
3. Chat: enum step → `ChatMenuResult.error` → usecase do menu (case 4) → `HandlePdfDocumentInputUsecase` → binds → VM → `ChatDocumentForm` → View.
4. Tela Editar PDF.
5. Revisar prompts/IA.
6. QA manual.

## 6. Checklist de QA

- [ ] Menu "Editar PDF" mostra **CNPJ / CPF**.
- [ ] Opção abre o formulário no lugar do input bar, pré-preenchido com o valor atual.
- [ ] CPF válido salva como `000.000.000-00`; CNPJ válido como `00.000.000/0000-00`; CNPJ alfanumérico aceito.
- [ ] CPF inválido / CNPJ inválido / tamanho errado mostram o erro certo no campo e não salvam.
- [ ] Voltar retorna ao menu sem salvar.
- [ ] PDFs (simple/professional/executive, orçamento e recibo) mostram o CPF corretamente.
- [ ] Registros antigos com CNPJ continuam aparecendo e editáveis.
- [ ] Tela Editar PDF: máscara alterna CPF↔CNPJ; não força mais `0001`.
- [ ] Inglês: labels traduzidos, valor salvo idêntico.
