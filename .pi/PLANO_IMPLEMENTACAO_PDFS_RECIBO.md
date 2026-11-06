# Plano de Implementação — Novos Layouts de PDF de Recibo (Executivo e Profissional)

> **Base**: `PLANO_IMPLEMENTACAO_NOVOS_PDFS.md` (mesmo padrão de arquitetura *ponytail*).  
> **Referência visual dos layouts**: `lib/modules/pdf/domain/usecase/pdf_generate_budget/pdf_generate_budget_executive_usecase.dart` e `pdf_generate_budget_professional_usecase.dart`.  
> **Modelo de dados**: `lib/modules/pdf/domain/usecase/pdf_generate_receipt/pdf_generate_receipt_simple_usecase.dart`.

---

## 1. Objetivo

Adicionar **2 novos tipos de layout** para o PDF de **recibo**, mantendo o layout simples existente inalterado.

| Tipo | Arquivo novo | Base visual (orçamento) |
|------|--------------|-------------------------|
| Executivo | `pdf_generate_receipt_executive_usecase.dart` | `pdf_generate_budget_executive_usecase.dart` |
| Profissional | `pdf_generate_receipt_professional_usecase.dart` | `pdf_generate_budget_professional_usecase.dart` |

**Regra de definição**: a mesma usada no orçamento. O campo `owner.pdfLayoutType` (`'standard'` \| `'executive'` \| `'professional'`) define o layout padrão do recibo. Se uma tela explicitar um `PdfLayoutType` diferente de `standard`, ele sobrescreve a configuração do owner.

Os **dados** exibidos (lista de pagamentos, dados do recibo, dados do cliente e do titular) são **idênticos** aos do recibo simples; apenas o **formato visual** muda.

---

## 2. Resumo das diferenças visuais

### 2.1 Layout Executivo (baseado no orçamento executivo)
- **Cabeçalho escuro** com cantos arredondados: logo + nome da empresa, CNPJ, telefone, e-mail à esquerda; título "RECIBO DE PAGAMENTO" + número do recibo à direita (ciano/branco).
- **Boxes lado a lado**:
  - Esquerda: "INFORMAÇÕES DO RECIBO" (Número, Data, Descrição).
  - Direita: "DADOS DO CLIENTE" (Nome, Telefone, Endereço, Localidade).
- **Tabela de pagamentos**: headers `DESCRIÇÃO | MÉTODO | VALOR PAGO`.
- **Totais**: "VALOR TOTAL PAGO:" alinhado à direita, com fundo escuro e texto branco.
- **Rodapé**: `{empresa} • Gestão de Recibos`.

### 2.2 Layout Profissional (baseado no orçamento profissional)
- **Cabeçalho claro**: logo + nome da empresa, CNPJ/CPF, e-mail, telefone, endereço completo (vertical), seguido de **linha azul escura**.
- **Boxes lado a lado**:
  - Esquerda: "DADOS DO RECIBO" (Número, Data, Descrição).
  - Direita: "DADOS DO CLIENTE" (Cliente, Telefone, Endereço, Cidade / CEP).
- **Tabela de pagamentos**: headers `Descrição dos pagamentos | Método | Valor pago`, com fundo azul escuro e texto branco.
- **Totais**: "VALOR TOTAL PAGO:" alinhado à direita, fundo azul escuro, texto branco.
- **Rodapé**: `{empresa} • Recibo Comercial` + linha cinza.

---

## 3. Alterações por camada

### 3.1. Domain — Novos UseCases de Recibo

**Criar**:
- `lib/modules/pdf/domain/usecase/pdf_generate_receipt/pdf_generate_receipt_executive_usecase.dart`
- `lib/modules/pdf/domain/usecase/pdf_generate_receipt/pdf_generate_receipt_professional_usecase.dart`

#### API pública (pares mobile + web)

Cada usecase deve expor exatamente os mesmos parâmetros de entrada que o recibo simples:

```dart
Future<String> executivePDF({
  required List<PaymentCustomer> paymentList,
  required Receipt recived,
  required String totalPriceBudget,
  required CustomerInfo customer,
  required OwnerPdf owner,
});

Future<Uint8List> executivePDFBytes({
  required List<PaymentCustomer> paymentList,
  required Receipt recived,
  required String totalPriceBudget,
  required CustomerInfo customer,
  required OwnerPdf owner,
});
```

(Análogo para `professionalPDF` / `professionalPDFBytes`.)

> **Ponytail**: não adicionar `authToken` externo. Seguir o padrão do recibo simples: o token é buscado internamente via `_getAuthToken()`, sem parâmetro público.

#### Estrutura interna do Executivo

```dart
PdfDocument _buildExecutiveDocument({ ... }) // monta o documento
Future<double> _drawDarkHeader(page, owner, customer)    // cabeçalho escuro
double _drawInfoBoxesRow(page, customer, recived, topY)  // dois boxes lado a lado
double _drawSectionHeader(page, title, topY)               // título + linha
_TableResult _drawPaymentsTable(...)                    // tabela de pagamentos
void _drawFooter(page, owner)                            // rodapé
void _addTotalRow(...)                                   // linha de total
void _drawRoundedRect(...)                               // helper de cantos arredondados
Future<String> _saveDocument(...)                       // salvar local
Future<String> _getAuthToken()                          // auth interna
```

> **Copiar** a estética (cores, fontes, paddings, bordas) do `PdfGenerateBudgetExecutiveUsecase`, adaptando **apenas**:
> - Textos/labels (trocar "ORÇAMENTO COMERCIAL" por "RECIBO DE PAGAMENTO", etc.).
> - Lógica de linhas: ao invés de filtrar `CATEGORIA == 'Produtos'` / `Serviços`, iterar diretamente sobre `paymentList`.

#### Estrutura interno do Profissional

```dart
PdfDocument _buildDocument({ ... })
Future<double> _drawHeader(page, owner, pageW)            // logo + dados empresa + linha azul
double _drawInfoBoxes(page, customer, recived, pageW, topY)
double _drawSectionTitle(page, title, topY)               // barra azul + fundo claro
double _drawPaymentsTable(...)
void _drawFooter(page, owner, pageW)
Future<String> _saveDocument(...)
Future<String> _getAuthToken()
```

Auxiliares reutilizados do orçamento profissional:
- `_drawBox`, `_drawBoxTitle`, `_drawBoxRows`, `_BoxRow`
- `_itemRowStyle`, `_applyRowStyle`, `_addRightAlignedTotalRow`

> **Copiar** a estética do `PdfGenerateBudgetProfessionalUsecase`, adaptando **apenas** textos/labels e a fonte de dados (pagamentos ao invés de produtos/serviços).

> **Ponytail**: manter os helpers privados **dentro** de cada usecase. Não extrair para classes/mixins externos.

---

### 3.2. DI — `pdf_binds.dart` (modificar)

**Arquivo**: `lib/modules/pdf/pdf_binds.dart`

Registrar os dois novos usecases como `LazySingleton`:

```dart
sl.registerLazySingleton<PdfGenerateReceiptExecutiveUsecase>(
  () => PdfGenerateReceiptExecutiveUsecase(
    sl<ConvertCoinRepository>(),
    sl<UserRepository>(),
  ),
);
sl.registerLazySingleton<PdfGenerateReceiptProfessionalUsecase>(
  () => PdfGenerateReceiptProfessionalUsecase(
    sl<ConvertCoinRepository>(),
    sl<UserRepository>(),
  ),
);
```

> O `PdfReceiptViewModel` não é registrado no `GetIt` (é instanciado manualmente na `PdfReceiptView`), portanto **não é necessário** alterar o factory do ViewModel no binds.

---

### 3.3. Presenter — `PdfReceiptViewModel` (modificar)

**Arquivo**: `lib/modules/pdf/pdf_receipt/presenter/pdf_receipt_view_model.dart`

#### Mudanças:

1. Adicionar os novos usecases como dependências (instanciáveis via construtor ou via `getIt`, mantendo o padrão atual):

```dart
final PdfGenerateReceiptExecutiveUsecase _pdfGenerateReceiptExecutive;
final PdfGenerateReceiptProfessionalUsecase _pdfGenerateReceiptProfessional;
```

2. Adicionar campo de layout:

```dart
PdfLayoutType _layoutType = PdfLayoutType.standard;

void setLayoutType(PdfLayoutType type) {
  _layoutType = type;
}
```

3. Em `initialData`, após buscar `owner`, calcular o layout efetivo (mesma lógica do `PdfBudgetViewModel`):

```dart
final ownerLayout = owner.pdfLayoutType ?? 'standard';
final effectiveLayout =
    _layoutType != PdfLayoutType.standard
        ? _layoutType
        : PdfLayoutType.values.firstWhere(
            (e) => e.name == ownerLayout,
            orElse: () => PdfLayoutType.standard,
          );
```

4. No switch de geração, substituir a chamada única `patternPDF` por:

```dart
final String path;
switch (effectiveLayout) {
  case PdfLayoutType.executive:
    path = await _pdfGenerateReceiptExecutive.executivePDF(
      paymentList: paymentList,
      recived: receipt,
      totalPriceBudget: _moneyConvert.convertFromDouble(totalBudget),
      customer: item,
      owner: owner,
    );
  case PdfLayoutType.professional:
    path = await _pdfGenerateReceiptProfessional.professionalPDF(
      paymentList: paymentList,
      recived: receipt,
      totalPriceBudget: _moneyConvert.convertFromDouble(totalBudget),
      customer: item,
      owner: owner,
    );
  default:
    path = await _pdfGenerateReceiptUseCase.patternPDF(
      paymentList: paymentList,
      recived: receipt,
      totalPriceBudget: _moneyConvert.convertFromDouble(totalBudget),
      customer: item,
      owner: owner,
    );
}
```

> **Cuidado**: `paymentList` **não deve ser limpo** após a geração no recibo (ao contrário dos orçamentos que fazem `items.clear()`). Preservar o comportamento do recibo simples.

---

### 3.4. Presenter — `PdfReceiptView` (modificar)

**Arquivo**: `lib/modules/pdf/pdf_receipt/presenter/pdf_receipt_view.dart`

Adicionar parâmetro opcional `layoutType` ao construtor:

```dart
class PdfReceiptView extends StatefulWidget {
  final Receipt receipt;
  final CustomerInfo item;
  final PdfLayoutType layoutType;

  const PdfReceiptView({
    super.key,
    required this.receipt,
    required this.item,
    this.layoutType = PdfLayoutType.standard,
  });
```

Em `initState`, informar o layout ao ViewModel antes de chamar `initialData`:

```dart
@override
void initState() {
  super.initState();
  _viewModel = PdfReceiptViewModel(
    receipt: widget.receipt,
    item: widget.item,
  );
  _viewModel.setLayoutType(widget.layoutType);
  WidgetsBinding.instance.addPostFrameCallback(
    (_) => _viewModel.initialData(context),
  );
}
```

---

### 3.5. Presenter — `ReceiptTabView` e `ReceiptListView`

**Arquivos**:
- `lib/modules/receipt/receipt_tab/presenter/receipt_tab_view.dart`
- `lib/modules/receipt/receipt_list/presenter/receipt_list_view.dart` / `receipt_list_view_model.dart`

> **Ação**: nenhuma alteração **obrigatória** aqui. Como o `PdfReceiptView` já tem `layoutType = PdfLayoutType.standard` por default, o fluxo atual continua funcionando exatamente igual.
>
> A configuração de layout do recibo é herdada automaticamente de `owner.pdfLayoutType` pelo `PdfReceiptViewModel`. Se o usuário desejar, poderá expandir no futuro (ex.: adicionar um `PopupMenuButton` no `AppBar` do `ReceiptTabView` ou do `PdfReceiptView` para forçar um layout específico), mas isso foge do escopo mínimo solicitado.

---

### 3.6. Strings (`pdf_pt_string.dart`)

**Verificação**: as strings já existentes `menuPdfExecutive` e `menuPdfProfessional` cobrem os nomes dos layouts. Nenhuma nova string é necessária para o recibo a menos que se crie um menu de seleção dedicado (fora do escopo mínimo).

---

## 4. Fluxo de navegação (resumo)

```
ReceiptListView
└── ReceiptTabView (abas: Recibo / Pagamentos / PDF)
    └── PdfReceiptView(layoutType: standard por padrão)
        └── PdfReceiptViewModel
            └── lê owner.pdfLayoutType
                ├── 'standard'    → PdfGenerateReceiptUseCase.patternPDF(...)
                ├── 'executive'   → PdfGenerateReceiptExecutiveUsecase.executivePDF(...)
                └── 'professional'→ PdfGenerateReceiptProfessionalUsecase.professionalPDF(...)
```

---

## 5. Checklist de arquivos

| # | Ação | Arquivo |
|---|------|---------|
| 1 | **Criar** | `lib/modules/pdf/domain/usecase/pdf_generate_receipt/pdf_generate_receipt_executive_usecase.dart` |
| 2 | **Criar** | `lib/modules/pdf/domain/usecase/pdf_generate_receipt/pdf_generate_receipt_professional_usecase.dart` |
| 3 | **Modificar** | `lib/modules/pdf/pdf_binds.dart` |
| 4 | **Modificar** | `lib/modules/pdf/pdf_receipt/presenter/pdf_receipt_view_model.dart` |
| 5 | **Modificar** | `lib/modules/pdf/pdf_receipt/presenter/pdf_receipt_view.dart` |

---

## 6. Regras de Ponytail aplicadas

- **Não** criar novos enums de layout — reaproveitar `PdfLayoutType` existente.
- **Não** criar datasource ou repositório novo — PDF é geração local pura.
- **Não** extrair helpers visuais para classes/mixins externos — cada usecase mantém seus próprios helpers privados.
- **Reaproveitar** `_drawLogo`, `_getAuthToken`, `_saveDocument` e estilos copiando e adaptando dos usecases de orçamento.
- **Menor diff**: criar apenas os dois arquivos de usecase e o mínimo de fios nos presenters/DI para conectá-los.

---

## 7. Status da Implementação

✅ **Implementado em:** sessão atual  
✅ **Total de arquivos alterados:** 5 (2 criados + 3 modificados)

---

## 8. Próximos passos recomendados

1. **Testar** os 3 layouts (`standard`, `executive`, `professional`) alterando o campo `owner.pdfLayoutType` no banco / emulador.
2. Verificar se o header dos PDFs de recibo executivo/profissional renderiza corretamente a logo (mesmo fluxo de autenticação dos orçamentos).
3. Ajustar larguras das colunas da tabela de pagamentos caso o conteúdo quebre em casos extremos (nomes longos, métodos longos).
4. **Opcional futuro:** adicionar seleção de layout na tela de recibo (ex.: `PopupMenuButton` no `AppBar` do `ReceiptTabView`).
