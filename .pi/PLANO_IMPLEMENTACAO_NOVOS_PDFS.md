# Plano de Implementação — Novos Layouts de PDF (Executivo e Profissional)

> **Base**: `PROJECT_STRUCTURE.md` (MVVM + Clean Architecture simplificada, modo *ponytail*)  
> **Referência visual**: `/Users/davidelias/Downloads/Orçamento Executivo.pdf` e `Orçamento Profissional.pdf`  
> **Modelo de código**: `lib/modules/pdf/domain/usecase/pdf_generate_usecase.dart` (método existente `patternPDF`/`patternPDFBytes`)

---

## 1. Objetivo

Adicionar **2 novos tipos de layout** para o PDF do orçamento:

| Tipo | Nome no App | Arquivo de referência |
|------|-------------|-----------------------|
| Executivo | "PDF Executivo" | `Orçamento Executivo.pdf` |
| Profissional | "PDF Profissional" | `Orçamento Profissional.pdf` |

Manter o **layout padrão existente** inalterado.

---

## 2. Resumo das diferenças visuais (extraídas dos PDFs)

### 2.1 Layout Executivo
- **Cabeçalho**: logo + nome da empresa, CNPJ, telefone, e-mail (linhas simples, sem grid).
- **Destaque**: título grande "ORÇAMENTO COMERCIAL" + número do orçamento.
- **Seções**: "INFORMAÇÕES DO ORÇAMENTO" (Data de Emissão, Validade) e "DADOS DO CLIENTE" (Cliente, Telefone, Endereço, Localidade).
- **Tabelas**: colunas `DESCRIÇÃO | MEDIDA | QTD | PREÇO UNIT. | TOTAL`.
- **Totais**: "Subtotal Produtos:", "Subtotal Serviços:", "VALOR TOTAL:".
- **Observações**: título simples "OBSERVAÇÕES".
- **Rodapé**: `{empresa} • Gestão de Orçamentos`.

### 2.2 Layout Profissional
- **Cabeçalho**: logo + empresa + CNPJ/CPF + e-mail + telefone + endereço completo (tudo listado verticalmente).
- **Seções**: "DADOS DO ORÇAMENTO" (Número, Criado em) e "DADOS DO CLIENTE" (Cliente, Telefone, Endereço, Cidade / CEP).
- **Tabelas**: headers em português natural (`Descrição dos produtos`, `Medida`, `Qtd`, `Preço`, `Total`).
- **Totais**: "Valor de produtos:", "Valor de serviços:", "VALOR TOTAL:".
- **Observações**: título "OBSERVAÇÕES DO ORÇAMENTO".
- **Rodapé**: `{empresa} • Orçamento Comercial`.

---

## 3. Alterações por camada (ordem de execução)

### 3.1. Domain — Enum de seleção (novo)

**Arquivo**: `lib/modules/pdf/domain/entity/pdf_layout_type.dart` (criar)

```dart
enum PdfLayoutType {
  standard,   // padrão atual
  executive,  // novo
  professional, // novo
}
```

> *Ponytail*: enum puro, sem conversão de tipo ou abstração desnecessária.

---

### 3.2. Domain — `PdfGenerateUseCase` (modificar)

**Arquivo**: `lib/modules/pdf/domain/usecase/pdf_generate_usecase.dart`

#### 3.2.1 Novos métodos públicos

Adicionar os pares de métodos **mobile + web**, seguindo o **mesmo padrão** de `patternPDF`/`patternPDFBytes`:

```dart
Future<String> executivePDF({ ...mesmos parâmetros... });
Future<Uint8List> executivePDFBytes({ ...mesmos parâmetros + authToken... });

Future<String> professionalPDF({ ...mesmos parâmetros... });
Future<Uint8List> professionalPDFBytes({ ...mesmos parâmetros + authToken... });
```

Observações:
- Os parâmetros são **idênticos** aos de `patternPDF`: `countService`, `countProduct`, `totalPriceBudget`, `totalPriceProducts`, `totalPriceServices`, `items`, `customer`, `owner`, `observations`, `authToken`.
- Reaproveitar `_saveDocument`, `_drawLogo`, `_getAuthToken` e quaisquer outros helpers genéricos já existentes.

#### 3.2.2 Novos métodos privados de construção

```dart
Future<PdfDocument> _buildExecutiveDocument({ ... });
Future<PdfDocument> _buildProfessionalDocument({ ... });
```

Cada um conterá os helpers privados específicos de layout (títulos, grids, tabelas, rodapé).

#### 3.2.3 O que muda em cada layout (detalhes de implementação)

**Executivo** (`_buildExecutiveDocument`):
- `_drawExecutiveHeader(page, owner, sizeWithImage)` → nome da empresa em negrito + CNPJ + Tel + E-mail em texto corrido.
- `_drawExecutiveTitle(page, graphics, customer.id)` → retângulo com "ORÇAMENTO COMERCIAL" + número abaixo.
- `_drawExecutiveBudgetInfo(page, customer)` → grid 2 colunas: "Data de Emissão:" / data, "Validade:" / "Consultar" (ou data de validade).
- `_drawExecutiveCustomerInfo(page, customer)` → grid com Cliente, Telefone, Endereço, Localidade.
- `_drawExecutiveProductTable(...)` e `_drawExecutiveServiceTable(...)` → colunas `DESCRIÇÃO | MEDIDA | QTD | PREÇO UNIT. | TOTAL`.
- `_drawExecutiveTotals(...)` → Subtotal Produtos, Subtotal Serviços, VALOR TOTAL.
- `_drawExecutiveObservations(document, observations)` → nova página com título "OBSERVAÇÕES".
- `_drawExecutiveFooter(page, owner)` → `{empresa} • Gestão de Orçamentos`.

**Profissional** (`_buildProfessionalDocument`):
- `_drawProfessionalHeader(page, owner, sizeWithImage)` → empresa, CNPJ/CPF, e-mail, telefone, endereço completo.
- `_drawProfessionalBudgetInfo(page, customer)` → grid com Número e Criado em.
- `_drawProfessionalCustomerInfo(page, customer)` → grid com Cliente, Telefone, Endereço, Cidade / CEP.
- `_drawProfessionalProductTable(...)` e `_drawProfessionalServiceTable(...)` → headers capitalizados naturalmente.
- `_drawProfessionalTotals(...)` → Valor de produtos, Valor de serviços, VALOR TOTAL.
- `_drawProfessionalObservations(document, observations)` → título "OBSERVAÇÕES DO ORÇAMENTO".
- `_drawProfessionalFooter(page, owner)` → `{empresa} • Orçamento Comercial`.

> **Ponytail**: manter os helpers privados **dentro** do mesmo usecase se não forem reutilizados por outras classes. Não extrair para classes/mixins externos a menos que haja reutilização clara.

---

### 3.3. Presenter — Menu de seleção (`PdfMenuView`/`PdfMenuViewModel`)

**Arquivo**: `lib/modules/pdf/pdf_menu/presenter/pdf_menu_view_model.dart`

Adicionar 2 novos `MenuItem` na lista `menuItems`:

```dart
MenuItem(icon: Icons.business_center_outlined, title: PdfStrings.menuPdfExecutive),
MenuItem(icon: Icons.workspace_premium_outlined, title: PdfStrings.menuPdfProfessional),
```

Ajustar o `switch` de `openOption`:
- índice 3 → navegar para `PdfBudgetView(layoutType: PdfLayoutType.executive)`
- índice 4 → navegar para `PdfBudgetView(layoutType: PdfLayoutType.professional)`

**Arquivo**: `lib/modules/pdf/pdf_budget/presenter/pdf_budget_view.dart`

Modificar o construtor para aceitar o tipo:

```dart
class PdfBudgetView extends StatefulWidget {
  final PdfLayoutType layoutType;
  const PdfBudgetView({super.key, this.layoutType = PdfLayoutType.standard});
```

No `initState`, passar o tipo para o ViewModel antes de `initialData`.

---

### 3.4. Presenter — `PdfBudgetViewModel` (modificar)

**Arquivo**: `lib/modules/pdf/pdf_budget/presenter/pdf_budget_view_model.dart`

- Adicionar campo `PdfLayoutType _layoutType = PdfLayoutType.standard` com setter.
- Em `initialData`, após calcular os totais, usar um `switch` para chamar o método correto do usecase:

```dart
switch (_layoutType) {
  case PdfLayoutType.standard:
    generated = await _pdfGenerateUseCase.patternPDF(...);
  case PdfLayoutType.executive:
    generated = await _pdfGenerateUseCase.executivePDF(...);
  case PdfLayoutType.professional:
    generated = await _pdfGenerateUseCase.professionalPDF(...);
}
```

---

### 3.5. Presenter — Strings (`pdf_pt_string.dart`)

**Arquivo**: `lib/modules/pdf/presenter/strings/pdf_pt_string.dart`

Adicionar:

```dart
static String get menuPdfExecutive =>
    _isPt ? 'PDF Executivo' : 'Executive PDF';

static String get menuPdfProfessional =>
    _isPt ? 'PDF Profissional' : 'Professional PDF';
```

---

### 3.6. DI — `pdf_binds.dart` (modificar)

**Arquivo**: `lib/modules/pdf/pdf_binds.dart`

Nenhum novo bind necessário para o usecase (ele já está registrado como `PdfGenerateUseCase`).

O `PdfBudgetViewModel` continua factory sem parâmetros no construtor; o tipo será setado pela View via setter antes de `initialData`, portanto o bind existente não precisa mudar.

---

### 3.7. Budget Tab View — nenhuma alteração obrigatória

**Arquivo**: `lib/modules/budget/budget_tab/presenter/budget_tab_view.dart`

A aba "PDF" continua apontando para `PdfBudgetView()` (layout padrão).
A aba "Mais" (`PdfMenuView`) já terá os 2 novos atalhos.

Se desejar permitir troca de tipo direto na aba PDF, pode-se adicionar um `PopupMenuButton` no `AppBar` do `PdfBudgetView`. Essa é uma melhoria UX opcional.

---

### 3.8. Web — `BudgetWebPdfViewModel` (modificar)

**Arquivo**: `../lib/modules/web_budget/budget_web/budget_web_data/budget_web_pdf_view_model.dart`

- Adicionar campo `PdfLayoutType layoutType` (com default `standard`).
- Em `inicialData`, usar `switch` para chamar o método de bytes correto (`executivePDFBytes`, `professionalPDFBytes`, `patternPDFBytes`).
- `BudgetWebBudgetView` passa o tipo selecionado para o ViewModel.

---

## 4. Fluxo de navegação (resumo)

```
BudgetTabView
├── Aba "Cliente" (BudgetCreatorView)
├── Aba "Itens" (BudgetListItemsView)
├── Aba "PDF" (PdfBudgetView → layout padrão)
└── Aba "Mais" (PdfMenuView)
    ├── Inserir comentários
    ├── Recibo de pagamentos
    ├── Compartilhar link do orçamento
    ├── PDF Executivo → PdfBudgetView(layoutType: executive)
    └── PDF Profissional → PdfBudgetView(layoutType: professional)
```

---

## 5. Checklist de arquivos

| # | Ação | Arquivo |
|---|------|---------|
| 1 | **Criar** | `lib/modules/pdf/domain/entity/pdf_layout_type.dart` |
| 2 | **Modificar** | `lib/modules/pdf/domain/usecase/pdf_generate_usecase.dart` |
| 3 | **Modificar** | `lib/modules/pdf/pdf_menu/presenter/pdf_menu_view_model.dart` |
| 4 | **Modificar** | `lib/modules/pdf/pdf_budget/presenter/pdf_budget_view.dart` |
| 5 | **Modificar** | `lib/modules/pdf/pdf_budget/presenter/pdf_budget_view_model.dart` |
| 6 | **Modificar** | `lib/modules/pdf/presenter/strings/pdf_pt_string.dart` |
| 7 | **Modificar** (web) | `../lib/modules/web_budget/budget_web/budget_web_data/budget_web_pdf_view_model.dart` |
| 8 | **Opcional** (web) | `lib/modules/web_budget/budget_web/budget_web_budget/budget_web_budget_view.dart` (seletor de layout) |

---

## 6. Regras de Ponytail aplicadas

- **Não** criar novos usecases ou repositórios — o `PdfGenerateUseCase` já existe e é o único responsável pela geração.
- **Não** criar datasource — PDF é geração local pura.
- **Não** extrair helpers para classes externas se só são usados dentro do usecase.
- **Não** alterar binds de ViewModel se o padrão continua factory.
- **Reaproveitar** `_saveDocument`, `_drawLogo`, `_getAuthToken`, `_createDocument` e os helpers de estilo (`_createItemRowStyle`, `_createTotalRowStyle`, etc.) sempre que possível.
- **Menor diff**: adicionar métodos no mesmo arquivo, modificar a View para aceitar parâmetro opcional, adicionar itens no menu existente.

---

## 7. Próximos passos recomendados

1. Criar o enum `PdfLayoutType`.
2. Implementar os métodos `executivePDF`/`executivePDFBytes` no usecase (com todos os helpers privados).
3. Implementar os métodos `professionalPDF`/`professionalPDFBytes` no usecase.
4. Ajustar `PdfBudgetView` e `PdfBudgetViewModel` para aceitar o tipo.
5. Ajustar `PdfMenuViewModel` para incluir os 2 novos itens e navegar com o tipo.
6. Atualizar as strings.
7. Testar os 3 layouts (padrão, executivo, profissional) no mobile.
8. Atualizar o fluxo Web se necessário.
