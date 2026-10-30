# Plano de Refatoração — Módulos, Binds e Routes

> **Escopo:** Alinhar todos os módulos do projeto ao padrão definido em `ARQUITETURA.md`.  
> Corrigir o conceito de `core`, criar arquivos de `_binds.dart` e `_routes.dart` onde faltam, e registrar **ViewModels como Factory** em todo módulo que possui `presenter`.
> 
> **Restrição:** Não alterar código que já funciona (telas, regras de negócio, Firebase). A refatoração é estrutural e aditiva.

---

## 1. Diagnóstico Atual

### 1.1 Módulos por status

| Módulo | Tem Binds | Tem Routes | Tem View | Precisa Binds | Precisa Routes | Obs |
|--------|-----------|------------|----------|---------------|----------------|-----|
| `budget` | ✅ `budget_binds` | ✅ `budget_routes` | ✅ Múltiplas | ✅ OK | ⚠️ **Incompleto** | Só expõe `BudgetListView` como rota. Outras telas (creator, items, tab) navegam via `MaterialPageRoute`. |
| `chat_budget` | ✅ `chat_budget_binds` | ❌ | ✅ Assistente | ✅ OK (único com VM factory) | ✅ **Criar** | Navega para outras telas via `MaterialPageRoute`. |
| `comment` | ✅ `comment_binds` | ❌ | ✅ CommentListView | ✅ OK | ⚠️ **Criar** | Navega via `Navigator.push` direto. |
| `core` | ✅ `core_binds` | ❌ | ❌ Nenhuma | ⚠️ **Ver item 2** | ❌ N/A | **Usuário informou: não é módulo separado.** |
| `dashboard` | ❌ | ❌ | ✅ DashboardView | ✅ **Criar** | ❌ N/A (filho do MainTab) | É tela filha do `MainTab`; não precisa de rota nomeada, mas precisa de binds para o VM. |
| `image` | ❌ | ❌ | ✅ ImageEditView | ✅ **Criar** | ⚠️ **Criar** | Navega via `MaterialPageRoute`. |
| `login` | ✅ `login_binds` | ✅ `login_routes` | ✅ LoginView | ⚠️ **Incompleto** | ✅ OK | VM instanciado na view (`LoginViewModel()`). Deveria virar Factory. |
| `main_config_menu` | ❌ | ❌ | ✅ MainConfigMenuView | ✅ **Criar** | ❌ N/A (filho do MainTab) | Tela filha do `MainTab`. Navega via `MaterialPageRoute` para outras rotas. |
| `main_tab` | ❌ | ✅ `main_tab_routes` | ✅ MainTabView | ✅ **Criar** | ✅ OK | Não tem binds, mas tem VM instanciado na view (`MainTabViewModel()`). |
| `payment` | ✅ `payment_binds` | ❌ | ✅ Múltiplas | ✅ OK | ⚠️ **Criar** | Navega via `MaterialPageRoute`. |
| `pdf` | ✅ `pdf_binds` | ✅ `pdf_routes` | ✅ Múltiplas | ⚠️ **Incompleto** | ⚠️ **Incompleto** | Só expõe `PdfMenuView` na rota. Outras telas (pdf_budget, pdf_edit, pdf_receipt) navegam via `MaterialPageRoute`. |
| `product` | ✅ `product_binds` | ❌ | ✅ Múltiplas | ✅ OK | ⚠️ **Criar** | Navega via `MaterialPageRoute`. |
| `receipt` | ✅ `receipt_binds` | ❌ | ✅ Múltiplas | ✅ OK | ⚠️ **Criar** | Navega via `MaterialPageRoute`. |
| `singup` | ❌ | ❌ | ✅ SingUpView | ✅ **Criar** | ⚠️ **Criar** | Navega via `pushReplacementNamed('/menu')`. É modal/tela de entrada. |
| `subscription` | ❌ | ✅ `subscription_routes` | ✅ SubscriptionView | ✅ **Criar** | ✅ OK | VM instanciado na view. Deveria virar Factory. |
| `terms_conditions` | ❌ | ✅ `terms_conditions_routes` | ✅ TermsConditionsView | ✅ **Criar** | ✅ OK | Não tem binds (sem datasource/repository). Verificar se precisa de binds. |
| `web_budget` | ❌ | ❌ | ✅ Múltiplas | ✅ **Criar** | ⚠️ **Criar** | Navega via `MaterialPageRoute`. |

### 1.2 Problemas estruturais encontrados

1. **`core` tratado como módulo de feature** — Na arquitetura, core são serviços transversais. O usuário confirmou: **"core não é um módulo separado, são módulos independentes que não possuem telas"**. Hoje `core/` mora dentro de `modules/` com um `core_binds.dart`. O correto é: manter os serviços, mas não tratá-los como módulo de feature.
2. **ViewModels instanciados manualmente na View** — Dashboard, Login, SingUp, MainTab, Subscription, TermsConditions, etc. instanciam o próprio VM: `_viewModel = DashboardViewModel()`. O padrão arquitetural diz que VM deve ser `registerFactory` no DI.
3. **Navegação via `MaterialPageRoute` ao invés de rotas nomeadas** — A maioria das telas abre outras com `Navigator.push(context, MaterialPageRoute(...))`. Isso não usa `onGenerateRoute`/`routes` do `MaterialApp`. O ideal é centralizar em `_routes.dart`.
4. **Módulos com presenter sem `_binds.dart`** — Dashboard, Image, MainConfigMenu, SingUp, WebBudget.
5. **Módulos com múltiplas telas mas apenas 1 rota** — Budget, Pdf.

---

## 2. Conceito Correto de `core`

> O `core` **não é um módulo de feature** e não segue a estrutura `domain/data/presenter`.  
> Ele é um agrupamento de **serviços transversais** (helpers, utilitários, conectores) que são consumidos por vários módulos.

### O que deve acontecer com `core`:

- **Manter** os arquivos de serviço onde estão (`modules/core/services/...` **ou** mover para `shared/services/` futuramente).
- **`core_binds.dart` continua existindo**, mas é entendido como **registro de serviços transversais**, não como binds de um módulo de feature.
- **Não deve ter** `core_routes.dart` (nunca terá View).
- **Não deve ter** `modules/core/domain/`, `modules/core/data/`.

> Nota: a reestruturação de `shared/` vs `modules/core/` é **baixa prioridade** e pode ser feita em etapa separada. Neste plano, focamos em binds/routes.

---

## 3. Matriz de Ações por Módulo

### 3.1 Ações — `_binds.dart`

| Módulo | Ação | Detalhes |
|--------|------|----------|
| `dashboard` | **Criar** `dashboard_binds.dart` | Registrar `DashboardViewModel` como Factory. O VM não depende de repository (usa dados locais/ads/firebase direto). Verificar se precisa de DI adicional. |
| `image` | **Criar** `image_binds.dart` | Registrar `ImageEditViewModel` como Factory. Depende de repository? Verificar. |
| `login` | **Alterar** `login_binds.dart` | Adicionar `registerFactory<LoginViewModel>(...)` aceitando `UserRepository`. |
| `main_config_menu` | **Criar** `main_config_menu_binds.dart` | Registrar `MainConfigMenuViewModel` como Factory. |
| `main_tab` | **Criar** `main_tab_binds.dart` | Registrar `MainTabViewModel` como Factory. Trocar instanciação manual por `getIt<MainTabViewModel>()`. |
| `payment` | **Alterar** `payment_binds.dart` | Verificar se PaymentViewModels (creator, list) precisam de Factory. Criar se necessário. |
| `pdf` | **Alterar** `pdf_binds.dart` | Registrar VMs de Pdf (pdf_budget, pdf_edit, pdf_menu, pdf_receipt) como Factory. |
| `product` | **Alterar** `product_binds.dart` | Registrar VMs de Product (product_price_creator, product_price_list) como Factory. |
| `receipt` | **Alterar** `receipt_binds.dart` | Registrar VMs de Receipt (receipt_creator, receipt_list, receipt_tab) como Factory. |
| `singup` | **Criar** `singup_binds.dart` | Registrar `SingUpViewModel` como Factory. Dependem de `UserRepository` (do módulo login)? Usar `sl<UserRepository>()`. |
| `subscription` | **Criar** `subscription_binds.dart` | Registrar `SubscriptionViewModel` como Factory. |
| `terms_conditions` | **Verificar** | Se não tem repository/datasource, não precisa de binds (só VM). Criar binds leve com Factory. |
| `web_budget` | **Criar** `web_budget_binds.dart` | Registrar todos os VMs de web_budget como Factory (`web_budget_app`, `web_budget_auth`, `web_budget_budget`, `web_budget_pdf`). |

### 3.2 Ações — `_routes.dart`

| Módulo | Ação | Rotas a adicionar |
|--------|------|-------------------|
| `budget` | **Alterar** `budget_routes.dart` | Adicionar `budgetCreator` (`/budget/create`), `budgetItems` (`/budget/items`), `budgetTab` (`/budget/tab`). |
| `chat_budget` | **Criar** `chat_budget_routes.dart` | `chatAssistant` (`/assistant`). |
| `comment` | **Criar** `comment_routes.dart` | `commentList` (`/budget/comments`). Depende do orçamento → rota com argumentos ou continua navegando via `MaterialPageRoute`? **Decisão:** se recebe `CustomerInfo` como parâmetro, manter navegação direta por enquanto. |
| `image` | **Criar** `image_routes.dart` | `imageEdit` (`/image/edit`). |
| `login` | ✅ OK | Só tem 1 rota. |
| `main_tab` | ✅ OK | Só tem 1 rota `/menu`. |
| `payment` | **Criar** `payment_routes.dart` | `paymentList` (`/payment/list`), `paymentCreator` (`/payment/create`). |
| `pdf` | **Alterar** `pdf_routes.dart` | Adicionar `pdfBudget`, `pdfEdit`, `pdfReceipt`, `pdfMenu` (já existe? Verificar). |
| `product` | **Criar** `product_routes.dart` | `productPriceList` (`/product/list`), `productPriceCreator` (`/product/create`). |
| `receipt` | **Criar** `receipt_routes.dart` | `receiptList` (`/receipt/list`), `receiptCreator` (`/receipt/create`), `receiptTab` (`/receipt/tab`). |
| `singup` | **Criar** `singup_routes.dart` | `singup` (`/singup`). Navega com `pushReplacementNamed`. |
| `subscription` | ✅ OK | Só tem 1 rota. |
| `terms_conditions` | ✅ OK | Só tem 1 rota. |
| `web_budget` | **Criar** `web_budget_routes.dart` | `webBudgetApp` (`/web/app`), `webBudgetAuth` (`/web/auth`), `webBudgetData` (`/web/data`). |

### 3.3 Ações — `injection.dart`

| Ação | Detalhes |
|------|----------|
| Importar e chamar todos os novos `register*Dependencies(getIt)` | Adicionar: `registerDashboard`, `registerImage`, `registerMainConfigMenu`, `registerMainTab`, `registerSingup`, `registerSubscription`, `registerTermsConditions`, `registerWebBudget`. |
| Verificar ordem de registros | Serviços core primeiro. Depois módulos de feature. |

### 3.4 Ações — `app_routes.dart`

| Ação | Detalhes |
|------|----------|
| Adicionar imports de todos os novos `*_routes.dart` | `chat_budget`, `comment`, `dashboard`, `image`, `payment`, `product`, `receipt`, `singup`, `web_budget`. |
| Adicionar entries no `enum AppRoute` | Só quando há navegação externa (fora do MainTab). Telas internas (filhas de MainTab) ficam no enum do módulo, mas não precisam de `AppRoute`. |
| Adicionar spread no `appRoutes` map | `...chatBudgetRoutes`, `...commentRoutes`, etc. |

---

## 4. Passo a Passo de Implementação

### FASE 1 — Módulos com presenter sem binds (prioridade alta)

#### 4.1.1 `dashboard_binds.dart`
```dart
void registerDashboardDependencies(GetIt sl) {
  sl.registerFactory<DashboardViewModel>(
    () => DashboardViewModel(
      // Se o VM depende de BudgetRepository ou outros, injetar aqui.
    ),
  );
}
```
#### 4.1.2 `main_tab_binds.dart`
```dart
void registerMainTabDependencies(GetIt sl) {
  sl.registerFactory<MainTabViewModel>(() => MainTabViewModel());
}
```
#### 4.1.3 `main_config_menu_binds.dart`
```dart
void registerMainConfigMenuDependencies(GetIt sl) {
  sl.registerFactory<MainConfigMenuViewModel>(() => MainConfigMenuViewModel());
}
```
#### 4.1.4 `singup_binds.dart`
```dart
void registerSingupDependencies(GetIt sl) {
  // Depende de UserRepository (já registrado pelo login)
  sl.registerFactory<SingUpViewModel>(
    () => SingUpViewModel(userRepository: sl<UserRepository>()),
  );
}
```
> Se `SingUpViewModel` não aceita `UserRepository` no construtor hoje, adicionar parâmetro opcional com fallback para `getIt<UserRepository>()`.

#### 4.1.5 `subscription_binds.dart`
```dart
void registerSubscriptionDependencies(GetIt sl) {
  sl.registerFactory<SubscriptionViewModel>(() => SubscriptionViewModel());
}
```
#### 4.1.6 `image_binds.dart`
```dart
void registerImageDependencies(GetIt sl) {
  sl.registerFactory<ImageEditViewModel>(() => ImageEditViewModel());
}
```
#### 4.1.7 `web_budget_binds.dart`
```dart
void registerWebBudgetDependencies(GetIt sl) {
  sl.registerFactory<WebBudgetAuthViewModel>(() => WebBudgetAuthViewModel());
  sl.registerFactory<WebBudgetAppViewModel>(() => WebBudgetAppViewModel());
  sl.registerFactory<WebBudgetBudgetViewModel>(() => WebBudgetBudgetViewModel());
  sl.registerFactory<WebBudgetPdfViewModel>(() => WebBudgetPdfViewModel());
}
```

### FASE 2 — Módulos com binds incompletos (adicionar ViewModels)

#### 4.2.1 `budget_binds.dart` — Adicionar VMs
```dart
sl.registerFactory<BudgetCreatorViewModel>(
  () => BudgetCreatorViewModel(item: /* parâmetro da rota */),
);
sl.registerFactory<BudgetListViewModel>(() => BudgetListViewModel());
sl.registerFactory<BudgetListItemsViewModel>(
  () => BudgetListItemsViewModel(item: /* parâmetro */),
);
sl.registerFactory<BudgetTabViewModel>(
  () => BudgetTabViewModel(item: /* parâmetro */),
);
```
> **Nota:** VMs que recebem argumentos (ex: `CustomerInfo`) não funcionam com `getIt` simples. Precisam ser passados pelo construtor na rota ou continuar instanciados manualmente.  
> **Decisão:** VMs com argumentos **mantêm instanciação manual** por enquanto, pois requirem parâmetro de entrada. VMs sem argumentos (ex: `BudgetListViewModel`, `DashboardViewModel`) migram para Factory.

#### 4.2.2 `pdf_binds.dart`, `product_binds.dart`, `receipt_binds.dart`
- Avaliar quais VMs são "sem argumento" → Factory.
- VMs com `required CustomerInfo item` → **não registram** no DI (recebem via construtor na navegação).

### FASE 3 — Criar `_routes.dart` onde faltam

#### 4.3.1 Padrão de arquivo
```dart
import 'package:flutter/material.dart';
import 'presenter/<tela>_view.dart';

enum <NomeModulo>Route { <nomeRota> }

extension <NomeModulo>RouteExtension on <NomeModulo>Route {
  String get path {
    switch (this) {
      case <NomeModulo>Route.<nomeRota>:
        return '/<modulo>/<rota>';
    }
  }
}

final Map<String, WidgetBuilder> <modulo>Routes = {
  <NomeModulo>Route.<nomeRota>.path: (_) => const <TelaView>(),
};
```

#### 4.3.2 Módulos a criar routes
| Módulo | Rotas |
|--------|-------|
| `chat_budget` | `/assistant` |
| `comment` | `/budget/comments` |
| `image` | `/image/edit` |
| `payment` | `/payment/list`, `/payment/create` |
| `product` | `/product/list`, `/product/create` |
| `receipt` | `/receipt/list`, `/receipt/create`, `/receipt/tab` |
| `singup` | `/singup` |
| `web_budget` | `/web/auth`, `/web/app`, `/web/budget`, `/web/data` |

#### 4.3.3 Módulos que NÃO precisam de routes
| Módulo | Motivo |
|--------|--------|
| `dashboard` | É filho do `MainTab`; não tem navegação externa. |
| `main_config_menu` | É filho do `MainTab`; não tem navegação externa. |
| `main_tab` | Só existe como rota central `/menu`. |
| `budget_creator` | Recebe `CustomerInfo`; navegação via `MaterialPageRoute`. |
| `budget_list_items` | Recebe `CustomerInfo`; navegação via `MaterialPageRoute`. |
| `budget_tab` | Recebe `CustomerInfo`; navegação via `MaterialPageRoute`. |

### FASE 4 — Ajustar `injection.dart`

```dart
import 'package:oflite/modules/dashboard/dashboard_binds.dart';
import 'package:oflite/modules/image/image_binds.dart';
import 'package:oflite/modules/main_config_menu/main_config_menu_binds.dart';
import 'package:oflite/modules/main_tab/main_tab_binds.dart';
import 'package:oflite/modules/singup/singup_binds.dart';
import 'package:oflite/modules/subscription/subscription_binds.dart';
import 'package:oflite/modules/terms_conditions/terms_conditions_binds.dart';
import 'package:oflite/modules/web_budget/web_budget_binds.dart';
```

Adicionar no corpo de `setupDependencyInjection()`:
```dart
registerDashboardDependencies(getIt);
registerImageDependencies(getIt);
registerMainConfigMenuDependencies(getIt);
registerMainTabDependencies(getIt);
registerSingupDependencies(getIt);
registerSubscriptionDependencies(getIt);
registerTermsConditionsDependencies(getIt);
registerWebBudgetDependencies(getIt);
```

### FASE 5 — Ajustar `app_routes.dart`

Adicionar imports e spreads dos novos módulos que possuem rotas:
```dart
import 'modules/chat_budget/chat_budget_routes.dart';
import 'modules/comment/comment_routes.dart';
import 'modules/image/image_routes.dart';
import 'modules/payment/payment_routes.dart';
import 'modules/product/product_routes.dart';
import 'modules/receipt/receipt_routes.dart';
import 'modules/singup/singup_routes.dart';
import 'modules/web_budget/web_budget_routes.dart';

final Map<String, WidgetBuilder> appRoutes = {
  ...loginRoutes,
  ...budgetRoutes,
  ...subscriptionRoutes,
  ...mainTabRoutes,
  ...pdfRoutes,
  ...termsConditionsRoutes,
  ...chatBudgetRoutes,
  ...commentRoutes,
  ...imageRoutes,
  ...paymentRoutes,
  ...productRoutes,
  ...receiptRoutes,
  ...singupRoutes,
  ...webBudgetRoutes,
};
```

### FASE 6 — Refatorar Views para usar DI nos VMs sem argumentos

Conjunto de Views que instanciam o VM manualmente e devem trocar por `getIt<...ViewModel>()`:
- `DashboardView` → `getIt<DashboardViewModel>()`
- `MainTabView` → `getIt<MainTabViewModel>()`
- `LoginView` → `getIt<LoginViewModel>()` (ou manter manual se não houver DI no construtor)
- `SingUpView` → `getIt<SingUpViewModel>()`
- `SubscriptionView` → `getIt<SubscriptionViewModel>()`
- `TermsConditionsView` → `getIt<TermsConditionsViewModel>()`
- `MainConfigMenuView` → `getIt<MainConfigMenuViewModel>()`

> VMs que recebem `CustomerInfo item` **não são alterados** nesta fase.

---

## 5. Checklist Final de Aceitação

- [ ] O módulo `core` não é considerado um módulo de feature; `core_binds` é mantido como registro de serviços transversais.
- [ ] Todo módulo que possui `presenter` possui um `<nome>_binds.dart`.
- [ ] Todos os ViewModels **sem argumentos de construtor** estão registrados como `registerFactory` no DI.
- [ ] VMs com argumentos (`CustomerInfo`, etc.) mantêm instanciação manual **ou** recebem argumentos via rota nomeada.
- [ ] Toda navegação de entrada (telas acessíveis de fora do `MainTab`) possui rota nomeada em `<nome>_routes.dart`.
- [ ] Nenhuma rota nomeada quebra; telas filhas de `MainTab` continuam acessíveis via tabs.
- [ ] `injection.dart` chama todos os `registerXxxDependencies`.
- [ ] `app_routes.dart` agrega todos os mapas de rotas.
- [ ] Nenhuma funcionalidade existente quebrou.
