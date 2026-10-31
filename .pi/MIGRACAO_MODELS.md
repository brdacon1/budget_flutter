# Plano de Migração — Models de `shared/models/` para Módulos

> **Regra: 1 módulo por vez. NUNCA o projeto todo.**  
> O agente deve pedir ao usuário qual módulo migrar, executar, validar, e só então partir para o próximo.

---

## 📋 Inventário Completo — Estado Atual

```
lib/shared/models/
├── address.dart              → core/cep (API ViaCep)
├── customer_info.dart        → budget (cliente do orçamento — MAIS ACOPLADO)
├── global_uid_budget.dart    → NÃO É MODEL (constantes Firestore)
├── global_uid_user.dart      → NÃO É MODEL (constantes Firestore)
├── info_user.dart            → login (usuário logado)
├── items_budget.dart         → budget (item de orçamento — ACOPLADO)
├── items_list_budget.dart    → budget (variante de item — ACOPLADO)
├── month_calculate.dart      → dashboard (cálculo mensal — ISOLADO)
├── my_budget_dashboard.dart  → dashboard (resumo dashboard — ISOLADO)
├── observation_budget.dart   → budget (observação — ACOPLADO)
├── observation_pdf.dart      → budget (observação PDF — ACOPLADO)
├── owner_info.dart           → DELETAR (nenhum import)
├── owner_pdf.dart            → login (dados titular — ACOPLADO)
├── payment_customer.dart     → payment (pagamento — ACOPLADO)
├── receipt.dart              → receipt (recibo — ACOPLADO)
└── recent_file.dart          → DELETAR (nenhum import — lixo de template)
```

---

## 🎯 Ordem de Migração (do mais isolado ao mais acoplado)

| Ordem | Módulo | Arquivos | Risco | Motivo |
|-------|--------|----------|-------|--------|
| 1 | `dashboard` | `month_calculate.dart`, `my_budget_dashboard.dart` | 🟢 Baixo | Só usados dentro do próprio módulo |
| 2 | `core/cep` | `address.dart` | 🟢 Baixo | Só usado dentro do core/cep |
| 3 | `login` | `info_user.dart`, `owner_pdf.dart` | 🟡 Médio | Usado por `singup`, `pdf`, `image` (importam de login) |
| 4 | `receipt` | `receipt.dart` | 🟡 Médio | Usado por `payment`, `pdf` (importam de receipt) |
| 5 | `payment` | `payment_customer.dart` | 🟡 Médio | Usado por `pdf`, `receipt` (importam de payment) |
| 6 | `budget` | `customer_info.dart`, `items_budget.dart`, `items_list_budget.dart`, `observation_budget.dart`, `observation_pdf.dart` | 🔴 Alto | Usado por QUASE TODO MUNDO (pdf, payment, web_budget, product, chat_budget, comment) |
| 7 | **Limpeza** | `global_uid_*.dart`, `owner_info.dart`, `recent_file.dart` | 🟢 Baixo | Mover constantes, deletar lixo |

---

## 📁 Destino de Cada Model — Estrutura Alvo

O padrão do projeto de referência define:
- **`data/model/`** → DTOs com `fromJson`/`toJson` (dados crus do Firestore/HTTP)
- **`domain/entity/`** → Entidades puras de negócio (imutáveis, sem JSON)
- **`presenter/`** → Estado local da UI (se aplicável)

| Arquivo | Model ou Entity? | Destino Alvo |
|---------|-----------------|--------------|
| `address.dart` | Model/DTO | `modules/core/cep/data/model/address_model.dart` |
| `customer_info.dart` | Model/DTO | `modules/budget/data/model/customer_info_model.dart` |
| `info_user.dart` | Model/DTO | `modules/login/data/model/info_user_model.dart` |
| `items_budget.dart` | Model/DTO | `modules/budget/data/model/items_budget_model.dart` |
| `items_list_budget.dart` | Model/DTO | `modules/budget/data/model/items_list_budget_model.dart` |
| `month_calculate.dart` | Entity/Estado | `modules/dashboard/domain/entity/month_calculate_entity.dart` |
| `my_budget_dashboard.dart` | Entity/Estado | `modules/dashboard/domain/entity/my_budget_dashboard_entity.dart` |
| `observation_budget.dart` | Model/DTO | `modules/budget/data/model/observation_budget_model.dart` |
| `observation_pdf.dart` | Model/DTO | `modules/budget/data/model/observation_pdf_model.dart` |
| `owner_pdf.dart` | Model/DTO | `modules/login/data/model/owner_pdf_model.dart` |
| `payment_customer.dart` | Model/DTO | `modules/payment/data/model/payment_customer_model.dart` |
| `receipt.dart` | Model/DTO | `modules/receipt/data/model/receipt_model.dart` |
| `global_uid_budget.dart` | Constante | `shared/common/constants/global_uid_budget.dart` |
| `global_uid_user.dart` | Constante | `shared/common/constants/global_uid_user.dart` |
| `owner_info.dart` | — | 🗑️ DELETAR |
| `recent_file.dart` | — | 🗑️ DELETAR |

> **Nota sobre nomes:** O projeto atual não usa sufixo `_model` (ex: `CustomerInfo` ao invés de `CustomerInfoModel`). Para manter consistência com o código existente, manter os nomes de classe atuais. O **nome do arquivo** muda para seguir o padrão de arquitetura (ex: `customer_info_model.dart`).

---

## 🔗 Mapeamento Completo de Dependências

### `month_calculate.dart` → `dashboard`

**Imports atuais:**
```
lib/modules/dashboard/presenter/dashboard_view_model.dart
lib/modules/dashboard/presenter/components/chart_line.dart
lib/modules/dashboard/presenter/components/month_evolution.dart
```

**Ação:** Mover para `modules/dashboard/domain/entity/month_calculate.dart` e atualizar 3 imports.

---

### `my_budget_dashboard.dart` → `dashboard`

**Imports atuais:**
```
lib/modules/dashboard/presenter/dashboard_view_model.dart
lib/modules/dashboard/presenter/components/storage_details.dart
lib/modules/dashboard/presenter/components/chart.dart
```

**Ação:** Mover para `modules/dashboard/domain/entity/my_budget_dashboard.dart` e atualizar 3 imports.

---

### `address.dart` → `core/cep`

**Imports atuais:**
```
lib/modules/core/cep/data/datasource/cep_remote_datasource.dart
lib/modules/core/cep/data/repository/cep_repository_impl.dart
lib/modules/core/cep/domain/repository/cep_repository.dart
lib/modules/chat_budget/presenter/chat_assistant/chat_assistant_view_model.dart  ← OUTRO MÓDULO!
```

**Ação:**
1. Mover para `modules/core/cep/data/model/address.dart`
2. Atualizar 3 imports internos de `core/cep`
3. **Anotar:** `chat_budget` importa `Address` de `shared/models/` — isso é dependência cruzada. Anotar para futura refatoração.

---

### `info_user.dart` → `login`

**Imports atuais:**
```
lib/modules/core/display_alert/data/repository/display_alert_repository_impl.dart  ← OUTRO MÓDULO!
lib/modules/singup/presenter/singup_view_model.dart                              ← OUTRO MÓDULO!
lib/modules/login/presenter/login_view_model.dart                                  ← MESMO MÓDULO
lib/modules/login/data/datasource/user_remote_datasource.dart                      → MESMO MÓDULO
lib/modules/login/data/repository/user_repository_impl.dart                        → MESMO MÓDULO
lib/modules/login/domain/repository/user_repository.dart                           → MESMO MÓDULO
```

**Ação:**
1. Mover para `modules/login/data/model/info_user.dart`
2. Atualizar 3 imports internos de `login`
3. Atualizar import de `singup` (consumidor) → `import 'package:oflite/modules/login/data/model/info_user.dart'`
4. Atualizar import de `core/display_alert` (consumidor) → `import 'package:oflite/modules/login/data/model/info_user.dart'`
5. **Anotar:** `display_alert` e `singup` dependem de `login` — isso é aceitável por hierarquia (login vem antes).

---

### `owner_pdf.dart` → `login`

**Imports atuais:**
```
lib/modules/pdf/pdf_receipt/presenter/pdf_receipt_view_model.dart        ← OUTRO MÓDULO!
lib/modules/pdf/pdf_budget/presenter/pdf_budget_view_model.dart          ← OUTRO MÓDULO!
lib/modules/pdf/data/repository/pdf_repository_impl.dart                  ← OUTRO MÓDULO!
lib/modules/pdf/domain/repository/pdf_repository.dart                     ← OUTRO MÓDULO!
lib/modules/pdf/domain/usecase/pdf_generate_usecase.dart                ← OUTRO MÓDULO!
lib/modules/pdf/domain/usecase/pdf_generate_receipt_usecase.dart        ← OUTRO MÓDULO!
lib/modules/pdf/pdf_edit/presenter/pdf_edit_view_model.dart             ← OUTRO MÓDULO!
lib/modules/web_budget/budget_web/budget_web_data/budget_web_data_view.dart              ← OUTRO MÓDULO!
lib/modules/web_budget/budget_web/budget_web_pdf/budget_web_pdf_view_model.dart          ← OUTRO MÓDULO!
lib/modules/web_budget/budget_web/budget_web_budget/budget_web_budget_view_model.dart    ← OUTRO MÓDULO!
lib/modules/image/presenter/image_edit_view.dart                           ← OUTRO MÓDULO!
lib/modules/singup/presenter/singup_view_model.dart                        ← OUTRO MÓDULO!
lib/modules/login/presenter/login_view_model.dart                          ← MESMO MÓDULO
lib/modules/login/data/datasource/user_remote_datasource.dart              ← MESMO MÓDULO
lib/modules/login/data/repository/user_repository_impl.dart                ← MESMO MÓDULO
lib/modules/login/domain/repository/user_repository.dart                   ← MESMO MÓDULO
```

**Ação:**
1. Mover para `modules/login/data/model/owner_pdf.dart`
2. Atualizar 4 imports internos de `login`
3. Atualizar TODOS os imports de outros módulos para apontar para `modules/login/data/model/owner_pdf.dart`
4. **Anotar:** `pdf`, `web_budget`, `image` e `singup` todos dependem de `login` por `OwnerPdf`. Isso é MUITO acoplamento — idealmente `OwnerPdf` deveria ser exposto via Repository/UseCase, não importado direto. Mas essa refatoração é FASE 2 (após a migração).

---

### `receipt.dart` → `receipt`

**Imports atuais:**
```
lib/modules/payment/data/repository/payment_repository_impl.dart       ← OUTRO MÓDULO!
lib/modules/payment/domain/repository/payment_repository.dart          ← OUTRO MÓDULO!
lib/modules/payment/payment_list/presenter/payment_list_view.dart      ← OUTRO MÓDULO!
lib/modules/payment/payment_list/presenter/payment_list_view_model.dart ← OUTRO MÓDULO!
lib/modules/pdf/pdf_receipt/presenter/pdf_receipt_view_model.dart      ← OUTRO MÓDULO!
lib/modules/pdf/pdf_receipt/presenter/pdf_receipt_view.dart            ← OUTRO MÓDULO!
lib/modules/pdf/domain/usecase/pdf_generate_receipt_usecase.dart       ← OUTRO MÓDULO!
lib/modules/receipt/receipt_tab/presenter/receipt_tab_view.dart        → MESMO MÓDULO
lib/modules/receipt/receipt_tab/presenter/receipt_tab_view_model.dart  → MESMO MÓDULO
lib/modules/receipt/receipt_creator/presenter/receipt_creator_view_model.dart → MESMO MÓDULO
lib/modules/receipt/receipt_creator/presenter/receipt_creator_view.dart → MESMO MÓDULO
lib/modules/receipt/receipt_list/presenter/components/receipt_card.dart → MESMO MÓDULO
lib/modules/receipt/receipt_list/presenter/receipt_list_view_model.dart → MESMO MÓDULO
lib/modules/receipt/data/repository/receipt_repository_impl.dart       → MESMO MÓDULO
lib/modules/receipt/domain/repository/receipt_repository.dart          → MESMO MÓDULO
```

**Ação:**
1. Mover para `modules/receipt/data/model/receipt.dart`
2. Atualizar 8 imports internos de `receipt`
3. Atualizar 6 imports de `payment` e `pdf` (consumidores)
4. **Anotar:** Muitos módulos importam `Receipt` direto. Idealmente `payment` e `pdf` deveriam receber dados via Repository/UseCase.

---

### `payment_customer.dart` → `payment`

**Imports atuais:**
```
lib/modules/payment/data/repository/payment_repository_impl.dart        → MESMO MÓDULO
lib/modules/payment/domain/repository/payment_repository.dart           → MESMO MÓDULO
lib/modules/payment/payment_creator/presenter/payment_creator_view_model.dart → MESMO MÓDULO
lib/modules/payment/payment_creator/presenter/payment_creator_view.dart → MESMO MÓDULO
lib/modules/payment/payment_list/presenter/components/payment_card.dart → MESMO MÓDULO
lib/modules/payment/payment_list/presenter/payment_list_view_model.dart → MESMO MÓDULO
lib/modules/pdf/pdf_receipt/presenter/pdf_receipt_view_model.dart       ← OUTRO MÓDULO!
lib/modules/pdf/domain/usecase/pdf_generate_receipt_usecase.dart        ← OUTRO MÓDULO!
```

**Ação:**
1. Mover para `modules/payment/data/model/payment_customer.dart`
2. Atualizar 6 imports internos de `payment`
3. Atualizar 2 imports de `pdf` (consumidor)

---

### `customer_info.dart` → `budget`

**Imports atuais (parcial — ver lista completa acima):**
```
# Internos ao budget:
lib/modules/budget/budget_list_items/presenter/budget_list_items_view_model.dart
lib/modules/budget/budget_list_items/presenter/budget_list_items_view.dart
lib/modules/budget/budget_creator/presenter/budget_creator_view_model.dart
lib/modules/budget/budget_list/presenter/budget_list_view.dart
lib/modules/budget/budget_list/presenter/budget_list_view_model.dart
lib/modules/budget/data/repository/budget_repository_impl.dart

# Consumidores (OUTROS MÓDULOS):
lib/modules/core/notification/data/repository/notification_repository_impl.dart
lib/modules/comment/presenter/comment_list_view.dart
lib/modules/comment/presenter/comment_list_view_model.dart
lib/modules/payment/payment_list/presenter/payment_list_view.dart
lib/modules/payment/payment_list/presenter/payment_list_view_model.dart
lib/modules/pdf/pdf_receipt/presenter/pdf_receipt_view_model.dart
lib/modules/pdf/pdf_budget/presenter/pdf_budget_view_model.dart
lib/modules/pdf/pdf_menu/presenter/pdf_menu_view_model.dart
lib/modules/pdf/pdf_menu/presenter/pdf_menu_view.dart
lib/modules/pdf/data/repository/pdf_repository_impl.dart
lib/modules/pdf/domain/repository/pdf_repository.dart
lib/modules/pdf/domain/usecase/pdf_generate_usecase.dart
lib/modules/pdf/domain/usecase/pdf_generate_receipt_usecase.dart
lib/modules/web_budget/budget_web/budget_web_data/budget_web_data_view.dart
lib/modules/web_budget/budget_web/budget_web_pdf/budget_web_pdf_view_model.dart
lib/modules/web_budget/budget_web/budget_web_budget/budget_web_budget_view_model.dart
lib/modules/web_budget/services/web_budget_service.dart
lib/modules/product/product_price_list/presenter/product_price_list_view.dart
lib/modules/product/product_price_list/presenter/product_price_list_view_model.dart
```

**Ação:**
1. Mover para `modules/budget/data/model/customer_info.dart`
2. Atualizar 6 imports internos de `budget`
3. Atualizar ~16 imports de outros módulos (comment, payment, pdf, web_budget, product, core/notification)
4. **Anotar:** Este é o model MAIS acoplado do projeto. Praticamente todos os módulos dependem dele.

---

### `items_budget.dart` → `budget`

**Imports atuais:**
```
# Consumidores:
lib/modules/pdf/pdf_budget/presenter/pdf_budget_view_model.dart
lib/modules/pdf/data/repository/pdf_repository_impl.dart
lib/modules/pdf/domain/repository/pdf_repository.dart
lib/modules/pdf/domain/usecase/pdf_generate_usecase.dart
lib/modules/web_budget/budget_web/budget_web_data/budget_web_data_view.dart
lib/modules/web_budget/budget_web/budget_web_data/components/budget_web_items_section.dart
lib/modules/web_budget/budget_web/budget_web_pdf/budget_web_pdf_view_model.dart
lib/modules/web_budget/budget_web/budget_web_budget/budget_web_budget_view_model.dart
lib/modules/web_budget/services/web_budget_service.dart
lib/modules/product/product_price/data/model/product_price_model.dart
lib/modules/product/product_price_list/presenter/product_price_list_view_model.dart
lib/modules/product/product_price_creator/presenter/product_price_creator_view_model.dart
lib/modules/chat_budget/presenter/chat_assistant/chat_assistant_view_model.dart
lib/modules/chat_budget/data/repository/chat_budget_repository_impl.dart
lib/modules/chat_budget/domain/repository/chat_budget_repository.dart
lib/modules/chat_budget/domain/usecase/create_budget_from_chat_usecase.dart

# Internos ao budget:
lib/modules/budget/budget_list_items/presenter/budget_list_items_view_model.dart
lib/modules/budget/budget_list_items/presenter/components/budget_list_items_card.dart
lib/modules/budget/budget_list_items/presenter/components/modals/budget_list_items_delete_bottom_modal_widget.dart
lib/modules/budget/data/repository/budget_repository_impl.dart
```

---

### `items_list_budget.dart` → `budget`

**Imports atuais:**
```
lib/modules/product/product_price/data/model/product_price_model.dart  ← OUTRO MÓDULO
lib/modules/budget/data/repository/budget_repository_impl.dart          → MESMO MÓDULO
```

---

### `observation_budget.dart` → `budget`

**Imports atuais:**
```
lib/modules/comment/presenter/comment_list_view.dart                    ← OUTRO MÓDULO
lib/modules/comment/presenter/components/comment_form_dialog.dart       ← OUTRO MÓDULO
lib/modules/comment/presenter/components/comment_list_item.dart         ← OUTRO MÓDULO
lib/modules/comment/presenter/comment_list_view_model.dart              ← OUTRO MÓDULO
lib/modules/comment/data/repository/comment_repository_impl.dart        ← OUTRO MÓDULO
lib/modules/comment/domain/repository/comment_repository.dart           ← OUTRO MÓDULO
lib/modules/budget/data/repository/budget_repository_impl.dart          → MESMO MÓDULO
lib/modules/budget/domain/repository/budget_repository.dart             → MESMO MÓDULO
```

---

### `observation_pdf.dart` → `budget`

**Imports atuais:**
```
lib/modules/pdf/pdf_budget/presenter/pdf_budget_view_model.dart         ← OUTRO MÓDULO
lib/modules/pdf/data/repository/pdf_repository_impl.dart                ← OUTRO MÓDULO
lib/modules/pdf/domain/repository/pdf_repository.dart                   ← OUTRO MÓDULO
lib/modules/pdf/domain/usecase/pdf_generate_usecase.dart               ← OUTRO MÓDULO
lib/modules/web_budget/budget_web/budget_web_data/budget_web_data_view.dart              ← OUTRO MÓDULO
lib/modules/web_budget/budget_web/budget_web_data/components/budget_web_comments_section.dart ← OUTRO MÓDULO
lib/modules/web_budget/budget_web/budget_web_pdf/budget_web_pdf_view_model.dart          ← OUTRO MÓDULO
lib/modules/web_budget/budget_web/budget_web_budget/budget_web_budget_view_model.dart    ← OUTRO MÓDULO
lib/modules/web_budget/services/web_budget_service.dart                 ← OUTRO MÓDULO
lib/modules/budget/data/repository/budget_repository_impl.dart          → MESMO MÓDULO
lib/modules/budget/domain/repository/budget_repository.dart             → MESMO MÓDULO
```

---

## ✅ Checklist de Execução — Por Módulo

### Para CADA migração:

- [ ] **1. Perguntar ao usuário:** "Qual módulo migrar agora?"
- [ ] **2. Validar:** O módulo está funcionando antes da migração? (`flutter analyze` limpo)
- [ ] **3. Criar pasta** `modules/{modulo}/data/model/` (se não existir)
- [ ] **4. Mover arquivo:** Copiar `.dart` para destino, NÃO apagar ainda
- [ ] **5. Atualizar import interno** do próprio módulo
- [ ] **6. Atualizar imports de consumidores** (outros módulos que importavam de `shared/models/`)
- [ ] **7. Rodar `flutter analyze`** — corrigir erros de import
- [ ] **8. Compilar/testar** o módulo dono
- [ ] **9. Compilar/testar** os módulos consumidores
- [ ] **10. Só então** apagar o arquivo antigo de `shared/models/`
- [ ] **11. Commit** na branch de migração

---

## 🚨 Regras Duras para o Agente

1. **SEMPRE perguntar o módulo primeiro.** Nunca assumir. Nunca criar em `shared/models/`.
2. **Um módulo por vez.** NUNCA migrar tudo de uma vez.
3. **Nunca apagar o original antes de validar.** Ter os dois arquivos coexistindo por uns minutos é aceitável.
4. **Se um model é importado por 10 módulos,** atualizar os 10 imports. Não deixar import quebrado.
5. **Se houver dúvida sobre o módulo dono** (ex: `Receipt` usado por payment e receipt), usar a heurística: **quem define o conceito?** Quem tem o Firestore collection? Quem CRUD? → Esse é o dono.
6. **Constantes globais** (`global_uid_*.dart`) NÃO são models. São variáveis globais de path. Movê-las para `shared/common/constants/`.
7. **Arquivos sem import** → perguntar ao usuário se pode deletar. Se ele confirmar, deletar.

---

## 📌 Exemplo de Conversação Esperada

**Usuário:** "Cria a entidade de orçamento."  
**Agente:** "Qual módulo dono? Budget?"  
**Usuário:** "Sim."  
**Agente:** → Cria em `modules/budget/domain/entity/budget_entity.dart`

**Usuário:** "Cria o model de endereço para o CEP."  
**Agente:** "O módulo dono é `core/cep`?"  
**Usuário:** "Sim."  
**Agente:** → Cria em `modules/core/cep/data/model/address_model.dart`

**Usuário:** "Adiciona o campo `complemento` no CustomerInfo."  
**Agente:** "CustomerInfo é do módulo `budget`. Vou atualizar em `modules/budget/data/model/customer_info.dart`. Os módulos que consomem (pdf, payment, etc.) não precisam mudar o import — já apontam para o novo local."  
**Agente:** → Edita `modules/budget/data/model/customer_info.dart`
