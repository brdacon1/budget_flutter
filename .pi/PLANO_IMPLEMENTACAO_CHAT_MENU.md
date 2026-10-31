# Plano de Implementação — Migração do Menu Principal para o Chat

> **Regra ponytail**: um prompt por vez. Nada de migrar tudo de uma vez.  
> **Regra de ouro**: não mexer no que já funciona (fluxo de orçamentos existente).

## Contexto

A aba **Menu** (`MainConfigMenuView`) da tab principal contém hoje 3 funções:
1. Lista de preço  
2. Editar PDF  
3. Trocar nome de usuário  

O objetivo é trazer **todas** essas funções para dentro do **Chat Assistente** (`ChatAssistantView`) e, no final, **remover a aba Menu** da `MainTabView`. O fluxo de orçamentos existente continua funcionando exatamente como está — ele será apenas mais uma das opções do menu inicial do chat.

A navegação no chat será **estilo bot do WhatsApp**: o usuário envia o **número** da opção desejada ("1", "2", etc.). O bot responde com texto numerado. Não usamos botões inline.

---

## Arquitetura do novo fluxo

O chat hoje é orientado a passos via `ChatFlowStep`. Vamos introduzir um **menu principal** como primeiro passo (`mainMenu`). A partir dele, o usuário escolhe qual "modo" quer operar enviando o número da opção:

```
mainMenu
├── 1. criar_orcamento  → cai no fluxo EXISTENTE (welcome → askClient → ...)
├── 2. lista_preco      → submenu: ver lista | adicionar produto
├── 3. editar_pdf       → submenu: nome | telefone | email | CNPJ | endereço | logo
└── 4. trocar_nome      → abre modal, depois confirma no chat
```

Seguindo a arquitetura do projeto (MVVM + Clean Architecture):
- **UseCases** contêm regras de negócio e orquestração de fluxos (configurar passos, enviar mensagens, validar, salvar dados).
- **ViewModel** apenas coordena a View, expõe estado observável e dispara Commands.
- **View** abre modais/páginas externas e notifica o ViewModel via métodos públicos quando o usuário volta.
- Reutilizamos as **views/modais já existentes** (`ProductPriceListView`, `PdfEditView`, `ChangeNameBottomModalWidget`, `ImageEditView`) — não recriamos telas.

---

## Resumo das mudanças por arquivo

| Arquivo | Prompts que tocam |
|---------|-------------------|
| `chat_message_entity.dart` | 1 |
| `chat_message_bubble.dart` | 1, 6 |
| `chat_assistant_view_model.dart` | 1, 2, 3, 4, 5, 7 |
| `chat_assistant_view.dart` | 2, 3, 4, 5, 6, 7 |
| `chat_budget_pt_string.dart` | 1, 2, 3, 4, 5, 7 |
| `product_price_creator_view.dart` | 2 |
| `product_price_creator_view_model.dart` | 2 |
| `main_tab_view.dart` | 8 |
| `main_tab_view_model.dart` | 8 |

---

## Prompt 1 — Infraestrutura: Menu Principal no Chat (fluxo numérico)

### O que faz
Plataforma para todo o resto. Adiciona o menu principal como primeiro passo e muda a interface para interpretar **números** ao invés de botões inline.

### Novos passos no `ChatFlowStep`
```dart
mainMenu,
priceListMenu, priceListAddResult,
pdfEditMenu, pdfEditFieldInput, pdfEditConfirm,
changeUsername, changeUsernameResult,
logoMenu, logoViewResult,
```

### Novo tipo de mensagem
```dart
enum ChatMessageType {
  text,
  action,
  productList,
  contactPicker,
  inlineButtons,
  image,
}
```

### Strings adicionadas em `chat_budget_pt_string.dart`
```
mainMenuQuestion        → "O que eu posso fazer por você?"
mainMenuOptions         → "1. Criar orçamentos\n2. Lista de preço\n3. Editar PDF\n4. Trocar nome de usuário"
menuInvalidOption       → "Opção inválida. Envie o número correspondente."
budgetTransition        → "Vamos lá! 💪"
```

### UseCases criados (todos em `domain/usecase/`)
| UseCase | Responsabilidade |
|---------|------------------|
| `StartBudgetFromMenuUsecase` | Envia mensagem de transição + boas-vindas + pergunta nome. Retorna step `askClient`. |
| `ShowPriceListMenuUsecase` | Envia submenu de lista de preço. Retorna step `priceListMenu`. |
| `ShowPdfEditMenuUsecase` | Envia submenu de edição de PDF. Retorna step `pdfEditMenu`. |
| `ShowChangeUsernameMenuUsecase` | Envia instruções + botão para abrir modal. Retorna step `changeUsername`. |
| `ResetChatToMenuUsecase` | Limpa estado e envia o menu principal. Retorna step `mainMenu`. |

### Comportamento
> Bot: "O que eu posso fazer por você?
> 1. Criar orçamentos
> 2. Lista de preço
> 3. Editar PDF
> 4. Trocar nome de usuário"

O usuário digita "1" → o chat envia "Vamos lá! 💪" e cai no fluxo `welcome` → `askClient` **existente**.

Se digitar opção inválida (ex: "5" ou "abc") → bot responde: "Opção inválida. Envie o número correspondente." e espera novamente no mesmo step.

Conversas em andamento (restauração de sessão salva) **não** mostram o menu — continuam no step correto.

### Arquivos alterados
- `lib/modules/chat_budget/domain/entity/chat_message_entity.dart` — adiciona `image`
- `lib/modules/chat_budget/presenter/chat_assistant/components/chat_message_bubble.dart` — renderiza `ChatMessageType.image`
- `lib/modules/chat_budget/presenter/chat_assistant/chat_assistant_view_model.dart` — injeta UseCases no construtor; `_initialize()` exibe menu principal; `handleAction()` e `_sendText()` interpretam números
- `lib/modules/chat_budget/presenter/strings/chat_budget_pt_string.dart` — strings do menu e submenus
- `lib/modules/chat_budget/chat_budget_binds.dart` — registra todos os novos UseCases
- `lib/modules/chat_budget/domain/usecase/` — 5 novos arquivos de UseCase

---

## Prompt 2 — Lista de Preço no Chat

### O que faz
Implementa o submenu "Lista de preço" a partir do `mainMenu`.

### Strings
```
priceListMenuQuestion   → "Legal, o que você quer fazer?"
priceListMenuOptions    → "1. Ver lista de produtos\n2. Adicionar um novo produto"
```

### Comportamento
Usuário digita "2" no menu principal → entra no step `priceListMenu`.

> Bot: "Legal, o que você quer fazer?
> 1. Ver lista de produtos
> 2. Adicionar um novo produto"

**1. Ver lista de produtos**
- Usuário digita "1" → a View abre `ProductPriceListView(fromMenu: true)` via `Navigator.push`.
- Quando o usuário volta (Navigator.pop), o chat permanece no step `priceListMenu` ou volta para `mainMenu`.

**2. Adicionar um novo produto**
- Usuário digita "2" → a View abre o modal `showProductPriceCreatorBottomModal` (exatamente como o menu faz).
- **Alteração mínima no creator**: o `Navigator.pop(context, true)` deve retornar o `ProductPriceModel` criado (`Navigator.pop(context, savedItem)`). O `showProductPriceCreatorBottomModal` passa a retornar `ProductPriceModel?`.
- Ao retornar com o item, o `ChatAssistantViewModel` recebe o produto via método público (ex: `onProductCreated(ProductPriceModel item)`) e envia mensagem de confirmação:
  > "Produto criado com sucesso! 🎉\nDescrição: {descricao}\nPreço: R$ {preco}\nCategoria: {categoria}"
- A mensagem de confilmação volta para o submenu de lista de preço.

### Arquivos alterados
- `lib/modules/chat_budget/presenter/chat_assistant/chat_assistant_view_model.dart` — método `_handlePriceListMenuOption()`; método público `onProductCreated()`
- `lib/modules/product/product_price_creator/presenter/product_price_creator_view.dart` — retorna `ProductPriceModel?` no pop
- `lib/modules/product/product_price_creator/presenter/product_price_creator_view_model.dart` — retorna o item salvo
- `lib/modules/chat_budget/presenter/chat_assistant/chat_assistant_view.dart` — cases para "priceList_view" e "priceList_add"
- `lib/modules/chat_budget/presenter/strings/chat_budget_pt_string.dart` — strings de confirmação de produto criado

---

## Prompt 3 — Editar PDF no Chat (Parte 1: Campos simples)

### O que faz
Implementa o submenu "Editar PDF" e os fluxos para os campos simples: **Nome da empresa**, **Telefone**, **Email** e **CNPJ**.

### Strings
```
pdfEditMenuQuestion     → "Qual informação do PDF você quer mudar?"
pdfEditMenuOptions      → "1. Nome da empresa\n2. Telefone\n3. Email\n4. CNPJ\n5. Endereço\n6. Logo"
pdfEditAskName          → "Digite o novo nome da empresa:"
pdfEditAskPhone         → "Digite o novo telefone da empresa (com DDD):"
pdfEditAskEmail         → "Digite o novo email:"
pdfEditAskCnpj          → "Digite o novo CNPJ:"
pdfEditInvalidPhone     → "Telefone inválido. Informe apenas números com DDD."
pdfEditInvalidEmail     → "Email inválido. Informe um email válido."
pdfEditInvalidCnpj      → "CNPJ inválido. Informe 14 números."
pdfEditSuccessName      → "Nome da empresa atualizado com sucesso para:"
pdfEditSuccessPhone     → "Telefone atualizado com sucesso:"
pdfEditSuccessEmail     → "Email atualizado com sucesso:"
pdfEditSuccessCnpj      → "CNPJ atualizado com sucesso:"
```

### Comportamento
Usuário digita "3" no menu principal → entra no step `pdfEditMenu`.

> Bot: "Qual informação do PDF você quer mudar?
> 1. Nome da empresa
> 2. Telefone
> 3. Email
> 4. CNPJ
> 5. Endereço
> 6. Logo"

**1. Nome da empresa**
- Usuário digita "1" → bot pergunta: "Digite o novo nome da empresa:"
- Entra em `ChatFlowStep.pdfEditFieldInput` com contexto `field: 'name'`.
- Usuário digita o nome e envia → `PdfRepository.saveInformationEnterprise()` atualiza apenas o campo `empresa`.
- Bot confirma: "Nome da empresa atualizado com sucesso para: {nome}."
- Volta para o submenu `pdfEditMenu`.

**2. Telefone da empresa**
- Usuário digita "2" → bot pergunta: "Digite o novo telefone da empresa (com DDD):"
- Entra em `pdfEditFieldInput` com contexto `field: 'phone'`.
- Validação: aplica máscara `(##) #####-####`; mínimo 10 dígitos. Se inválido → bot repete a mensagem de erro e permanece no mesmo step.
- Salva via `PdfRepository` e confirma.

**3. Email**
- Usuário digita "3" → bot pergunta: "Digite o novo email:"
- Contexto `field: 'email'`. Validação básica: contém `@` e `.`.
- Salva via `PdfRepository` e confirma.

**4. CNPJ**
- Usuário digita "4" → bot pergunta: "Digite o novo CNPJ:"
- Contexto `field: 'cnpj'`. Aplica máscara `##.###.###/0001-##` e valida 14 dígitos.
- Salva via `PdfRepository` e confirma.

### UseCase criado
| UseCase | Responsabilidade |
|---------|------------------|
| `UpdatePdfFieldUsecase` | Recebe campo (`name`, `phone`, `email`, `cnpj`) e valor, aplica validação, chama `PdfRepository` e retorna sucesso/erro + mensagem de confirmação. |

### Arquivos alterados
- `lib/modules/chat_budget/presenter/chat_assistant/chat_assistant_view_model.dart` — `_handlePdfEditMenuOption()`, `_handlePdfFieldInput()`
- `lib/modules/chat_budget/presenter/chat_assistant/chat_assistant_view.dart` — mantém validação de input
- `lib/modules/chat_budget/presenter/strings/chat_budget_pt_string.dart` — strings de PDF
- `lib/modules/chat_budget/domain/usecase/update_pdf_field_usecase.dart` — NOVO
- `lib/modules/chat_budget/chat_budget_binds.dart` — registra UseCase

---

## Prompt 4 — Editar PDF no Chat (Parte 2: Endereço)

### O que faz
Implementa **Endereço** dentro do submenu Editar PDF.

### Comportamento
Usuário digita "5" no `pdfEditMenu` → entra no fluxo de endereço.

> Bot: "Vamos atualizar o endereço da sua empresa. Você tem o CEP?"
> 1. Sim
> 2. Não

Usuário digita "1" → pede CEP → busca ViaCep → confirma → salva.
Usuário digita "2" → pede rua, número, cidade manualmente → salva.

- Reutiliza os mesmos controllers (`cepController`, `streetController`, etc.) já existentes na ViewModel.
- Quando salva, grava no `OwnerPdf` em vez de no `CustomerInfo` (orçamento). Usa o mesmo `_usecase.updateAddress()` pois internamente o `PdfRepository` mantém os dados do OwnerPdf.
- Bot confirma: "Endereço atualizado com sucesso."
- Retorna para o `pdfEditMenu`.

### Arquivos alterados
- `lib/modules/chat_budget/presenter/chat_assistant/chat_assistant_view_model.dart` — lógica de endereço gravando em OwnerPdf
- `lib/modules/chat_budget/presenter/strings/chat_budget_pt_string.dart` — `pdfEditSuccessAddress`

---

## Prompt 5 — Editar PDF no Chat (Parte 3: Logo) + Trocar Nome

### O que faz
Implementa **Logo** (submenu) e **Trocar Nome de Usuário**.

### Logo — submenu
Ao digitar "6" no `pdfEditMenu`:

> Bot: "O que você quer fazer com a logo?
> 1. Ver logo da empresa
> 2. Inserir/Alterar logo"

**1. Ver logo**
- Usuário digita "1" → o ViewModel busca o `OwnerPdf` via `PdfRepository.fetchInformationEnterprise()`.
- Se tiver logo → envia mensagem `ChatMessageType.image` com dados base64/bytes + botão `[Alterar]`.
- Se não tiver → "Você ainda não tem uma logo cadastrada."

**2. Inserir/Alterar**
- Usuário digita "2" → a View abre `ImageEditView` via `PdfEditViewModel.editLogo()`.
- Antes de abrir, verifica assinatura (`UID.autoRenewing`) exatamente como o `PdfEditLogoSection` já faz.
- Ao voltar: "Logo atualizada com sucesso." → volta para `pdfEditMenu`.

### UseCase criado
| UseCase | Responsabilidade |
|---------|------------------|
| `ShowLogoMenuUsecase` | Configura o submenu de logo. Retorna step `logoMenu`. |

### Trocar Nome de Usuário
- No `mainMenu`, usuário digita "4" → entra no step `changeUsername`.
- O chat mostra: "Vou abrir o modal para você alterar o nome de usuário.\n1. Abrir modal"
- A View abre `ChangeNameBottomModalWidget` via `DisplayAlertRepository.dialogChangeName(context)` — **exatamente o mesmo modal**.
- Ao fechar, a View notifica o ViewModel via método público `onUsernameChanged(String? name)`.
- Se sucesso → bot: "Nome de usuário atualizado com sucesso para: {nome}."
- Se cancelado → nada é enviado (ou "Ok, deixei como está.")

### Arquivos alterados
- `lib/modules/chat_budget/presenter/chat_assistant/chat_assistant_view_model.dart` — `_handleLogoMenuOption()`, `_handleChangeUsernameOption()`, `onUsernameChanged()`
- `lib/modules/chat_budget/presenter/chat_assistant/chat_assistant_view.dart` — cases para logo e changeUsername
- `lib/modules/chat_budget/presenter/chat_assistant/components/chat_message_bubble.dart` — renderiza imagem
- `lib/modules/chat_budget/presenter/strings/chat_budget_pt_string.dart` — strings de logo e nome
- `lib/modules/chat_budget/domain/usecase/show_logo_menu_usecase.dart` — NOVO
- `lib/modules/chat_budget/chat_budget_binds.dart` — regista novo UseCase

---

## Prompt 6 — Botão "Voltar" nos Submenus

### O que faz
Adiciona a opção "Voltar" em todos os submenus para que o usuário possa retornar ao menu principal.

### Comportamento
Em qualquer submenu (`priceListMenu`, `pdfEditMenu`, `changeUsername`, `logoMenu`), o usuário pode digitar "0" para voltar ao menu principal.

> "0. Voltar"

O `handleAction()` detecta "Voltar" (ou número "0") e chama `ResetChatToMenuUsecase`.

### Arquivos alterados
- `lib/modules/chat_budget/presenter/chat_assistant/chat_assistant_view_model.dart` — `_handleBackToMainMenu()`; lógica de "0" em todos os submenus
- `lib/modules/chat_budget/presenter/strings/chat_budget_pt_string.dart` — string `menuBackOption`

---

## Prompt 7 — Polimento, Reset e Testes de Fluxo

### O que faz
- Revisar todas as strings e centralizar em `chat_budget_pt_string.dart`.
- Garantir que o botão de **reiniciar conversa** (ícone de refresh na AppBar) volta para o `mainMenu`.
- Garantir que sessões salvas no meio de um fluxo (ex: orçamento em andamento) são restauradas corretamente — o menu **não aparece**.
- Testar fluxos completos:
  1. Abrir app → menu → "1" → fluxo de orçamento funciona até o final.
  2. Abrir app → menu → "2" → "1" → abre lista → volta → "2" → adiciona produto → confirmação.
  3. Abrir app → menu → "3" → "1" → digita nome → salva → confirma.
  4. Abrir app → menu → "3" → "5" → endereço → salva → confirma.
  5. Abrir app → menu → "4" → modal → confirma.
  6. Reiniciar conversa → volta para o menu principal.
  7. Digitar opção inválida → mensagem de erro, aguarda novamente.

### Arquivos alterados
- `lib/modules/chat_budget/presenter/strings/chat_budget_pt_string.dart`
- `lib/modules/chat_budget/presenter/chat_assistant/chat_assistant_view_model.dart` — ajustes no `_resetChat()`

---

## Prompt 8 — Remover a aba Menu da Tab Principal

### O que faz
Remove a aba **Menu** (`MainConfigMenuView`) da `MainTabView` e do `MainTabViewModel`.

### Comportamento
- `MainTabViewModel._tabItems` perde o item `TabItem(icon: Icons.menu, title: 'Menu')`.
- `MainTabView.children` perde `const MainConfigMenuView()`.
- Todas as navegações que antes partiam do menu agora só existem no chat.

### Arquivos alterados
- `lib/modules/main_tab/presenter/main_tab_view_model.dart`
- `lib/modules/main_tab/presenter/main_tab_view.dart`

---

## Notas de Arquitetura

1. **Nenhum novo módulo é criado**. Toda a lógica vive dentro de `chat_budget/presenter/chat_assistant/`.
2. **Nenhum novo repositório é criado**. Reutilizamos `PdfRepository`, `ProductPriceRepository`, `UserRepository` e `BudgetRepository` via `get_it`.
3. **Nenhum novo datasource é criado**. Os mesmos datasources já atendem.
4. **As views existentes são abertas por navegação padrão** (`Navigator.push` / `showModalBottomSheet`), igual ao menu antigo fazia.
5. **O fluxo de orçamento não é alterado** — ele simplesmente passa a ser chamado a partir do `mainMenu` em vez de ser o ponto de entrada padrão.
6. **Commands** são usados para ações assíncronas que disparam do chat (salvar PDF, salvar produto, etc.), mantendo o padrão do projeto.
7. **UseCases contêm as regras de negócio** do menu: configuração de steps, envio de mensagens, validação de dados, persistência via repositories.
8. **A ViewModel deve ser enxuta** — apenas coordena a View, expõe estado observável e dispara Commands. As mensagens do bot são montadas e enviadas pelos UseCases.
9. **Fluxo numérico**: o usuário sempre digita números ("1", "2", etc.). O bot nunca exibe botões inline no menu — apenas texto numerado.
10. **Validação**: erro de digitação (número inválido) mostra mensagem de erro e repete o menu/submenu atual — não quebra o fluxo.
