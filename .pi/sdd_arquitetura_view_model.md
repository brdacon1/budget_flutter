# SDD — Padrão de Arquitetura ViewModel (Flutter Nativo)

> **Software Design Document — Padrão de construção de features**
> Como toda feature de apresentação deve ser estruturada no projeto, mantendo
> **regra de negócio**, **parte visual** e **gerenciamento de estado nativo do Flutter**
> separados e sem quebrar o que já funciona.

---

## 1. Visão Geral

A arquitetura adotada é uma variação enxuta de MVVM baseada **somente em recursos nativos do Flutter**:

| Camada        | Local                        | Responsabilidade                                              |
|---------------|------------------------------|---------------------------------------------------------------|
| **Model**     | `lib/models/*`              | POJOs com `fromMap`/`toMap`. Sem lógica de negócio.           |
| **Service**   | `lib/Services/*`             | I/O (Firebase, HTTP), formatação, alertas, loading.          |
| **ViewModel** | `lib/presentations/<feature>/...` | `extends ChangeNotifier`. Estado mutável + ações.       |
| **View**      | `lib/presentations/<feature>/...` | `StatefulWidget` que possui o VM e reconstrói via `AnimatedBuilder`. |
| **Component** | `lib/presentations/<feature>/components/` | `StatelessWidget` puros com dados + callbacks.   |

Não há injeção de dependência externa nem pacotes de estado (Provider/Riverpod/Bloc/GetX).
O estado é **local à tela** e descartado no `dispose()`.

> **Enums compartilhados** (ex.: `Gender`/`*FieldType`) que selecionam campo focado
> **não** ficam soltos dentro de cada View/ViewModel. São movidos para
> `lib/common/enums/` (`snake_case`), importados por quem precisar — View,
> ViewModel e components. Isso evita duplicação e colisão de nome entre o enum
> e o widget de campo reutilizável (ex.: `SingUpFieldType` x `SingUpField`).

---

## 2. Estrutura de Pastas (obrigatória)

Toda feature de listagem/formulário/tab segue exatamente:

```
lib/presentations/<feature>/<feature>_<context>/
├── <feature>_<context>_view.dart            # StatefulWidget (UI + instância do VM)
├── <feature>_<context>_view_model.dart       # extends ChangeNotifier (estado + ações)
└── components/                                # subwidgets Stateless
    ├── <feature>_<context>_header.dart
    ├── <feature>_card.dart
    ├── <feature>_total_bar.dart
    ├── <feature>_field.dart                   # campo de formulário reutilizável
    └── <feature>_<section>_card.dart          # card/seção repetida (ex.: endereço)
```

Enums de seleção de campo (quando existirem) vão em:

```
lib/common/enums/
└── <feature>_field_enum.dart                # ex.: enum SingUpFieldType { name, email, password, ... }
```

Strings internacionalizadas (texto visível ao usuário) vão em:

```
lib/common/strings/
└── <area>_strings.dart                       # ex.: auth_strings.dart (login + cadastro)
```

Nenhum texto visível ao usuário fica solto como literal na View/ViewModel —
todos passam por uma classe de strings em `lib/common/strings/`. A classe
resolve o idioma a partir da localidade do dispositivo
(`WidgetsBinding.instance.platformDispatcher.locale`) e expõe getters
`static` (ex.: `AuthStrings.loginButton`). Assim a tradução fica centralizada
num arquivo só por área, usável tanto pela View quanto pelo ViewModel (que só
precisa de `package:flutter/widgets.dart`).
`<context>` pode ser `list`, `creator`, `tab`, `items`, `list_items`, etc.

Regras de nomenclatura:
- Pasta e arquivos em **snake_case**.
- Sufixo `_view` para a tela, `_view_model` para o VM.
- Componentes com prefixo do feature.
- **Arquivos de `lib/common/`** devem levar como **sufixo o papel da pasta**
  (forma singular): `enums` → `_enum`, `models` → `_model`, `widgets` → `_widget`,
  `controllers` → `_controller`, `utils` → `_util`, `constants` → `_constant`.
  O nome do arquivo é `<feature>_<contexto>_<papel>.dart`.
  Ex.: `lib/common/enums/singup_field_enum.dart`,
  `lib/common/models/<feature>_model.dart`.
  Isso evita colisão de nome entre o enum e o widget de campo (ex.: `SingUpFieldType`
  x `SingUpField`) e deixa claro, só pelo nome do arquivo, qual o seu papel.
- **Arquivos de strings** (`lib/common/strings/`) levam o sufixo `_strings`
  (`<area>_strings.dart`, ex.: `auth_strings.dart`).

---

## 3. Responsabilidades de Cada Camada

### 3.1 View (`*_view.dart`)
- É um **`StatefulWidget`** (mesmo sem estado visível) — necessário para criar e descartar o VM.
- **Instancia o VM em `initState`**, passando apenas dados imutáveis recebidos por construtor.
- Dispara o carregamento inicial em `addPostFrameCallback` (evita `notifyListeners` no build).
- **Descarta o VM em `dispose`** com `_viewModel.dispose()` **antes** de `super.dispose()`.
- **Reconstrói a UI** com `AnimatedBuilder(animation: _viewModel, ...)` — **nunca `setState`**.
- Pode haver mais de um `AnimatedBuilder` (ex.: corpo e `bottomNavigationBar`).
- Lê o estado **direto do VM** (`_viewModel.foundPayment`, `_viewModel.totalPaid`).
- Passa **dados + callbacks** para os componentes — nunca o VM inteiro.
- Não contém lógica de negócio; delega ações ao VM (ex.: `_viewModel.delete(context, index)`).
- **Mantém o `build` enxuto**: a View só monta a estrutura (Scaffold/Column/AnimatedBuilder)
  e compõe components. Toda UI repetida (campos, cards, barras, botões, seções) vira
  um `StatelessWidget` em `components/`. Se a View passar de ~150–200 linhas, é sinal de
  que falta extrair component.

### 3.2 ViewModel (`*_view_model.dart`)
- **`extends ChangeNotifier`** → fornece `notifyListeners()` e o "animation" que o
  `AnimatedBuilder` escuta.
- Recebe por construtor apenas **dependências e dados necessários**.
- Instancia internamente os services necessários (`HttpRequest`, `DisplayAlert`,
  `LoadingEvent`, `ConvertCoin`). **Não guarda `BuildContext` como campo** — ele chega
  por parâmetro nos métodos que precisam de UI.
- Expõe o **estado público** (listas, totais) e métodos de **ação** (`inicialData`,
  `refresh`, `delete`, `edit`, `add`).
- Toda mutação de estado termina com `notifyListeners()`.
- Cálculos derivados ficam em métodos privados (`_calcTotal`) recalculados a partir da
  própria lista em memória — garantindo consistência imediata com a UI.
- Navegação (`Navigator.push`) fica aqui, recebendo `BuildContext` por parâmetro, e
  sempre **recarrega os dados** (`inicialData()`) ao retornar.
- Erro/feedback visual tratados com `DisplayAlert` + `LoadingEvent`
  (abrir/fechar loading, notificações).

### 3.3 Components (`components/*`)
- **`StatelessWidget`** puros. Sem estado, sem `ChangeNotifier`.
- Recebem tudo por construtor: dados (`item`, `totalPaid`), utilitários (`moneyConvert`)
  e callbacks (`VoidCallback`, `ValueChanged`).
- **Não acessam services nem Firebase**. São burros e reutilizáveis.
- Podem ter sub-widgets privados (ex.: `_ActionButton`) no mesmo arquivo.
- **Extração é obrigatória** para qualquer bloco visual que se repete ou que passa de
  poucas dezenas de linhas. Exemplos canônicos: `*_header` (voltar + título),
  `*_card` (item de lista), `*_total_bar` (rodapé de totais), `*_field` (TextField
  estilizado reutilizável) e `*_<section>_card` (card/seção de formulário repetido,
  como endereço/empresa).
- Um component **não recebe o ViewModel inteiro** — recebe apenas os campos/controllers
  e callbacks que precisa. Isso mantém o component desacoplado e testável.
- Métodos auxiliares de widget que precisam de `BuildContext` devem recebê-lo por
  parâmetro (ex.: `Widget _imageCard(BuildContext context)`); nunca usar `context`
  fora do `build`.

### 3.4 Model (`lib/models/*` / `lib/presentations/<feature>/model/`)
- POJO **imutável** (`const`, campos `final`), campos nullable e o **padrão de
  model do Flutter**: `fromJson(Map<String, dynamic>)`, `toJson()` e `copyWith()`.
  Sem lógica de negócio (ver seção 10 para o porquê e como migrar os models
  antigos que ainda usam `fromMap`/`toJson` sem `copyWith`).

### 3.5 Services (`lib/Services/*`)
- Acesso a Firebase/HTTP, formatação de moeda, alertas, loading.
- **O ViewModel é o único que fala com os services**; a View nunca os toca diretamente.

---

## 4. Checklist de Implementação (para não quebrar)

Ao criar uma nova feature, validar item por item:

### Estado nativo
- [ ] `*_view.dart` é `StatefulWidget` com `createState`.
- [ ] ViewModel é `extends ChangeNotifier`.
- [ ] `initState` cria o VM e chama o carregamento em `addPostFrameCallback`.
- [ ] `dispose` chama `_viewModel.dispose()` **antes** de `super.dispose()`.
- [ ] Reconstrução via `AnimatedBuilder(animation: _viewModel, ...)`, nunca `setState`.
- [ ] Cada bloco reativo usa seu próprio `AnimatedBuilder` (corpo, bottom bar, etc.).
- [ ] Nenhum pacote externo de estado adicionado ao `pubspec.yaml`.

### Regra de negócio
- [ ] Toda mutação de lista/total acontece **no ViewModel**.
- [ ] Toda mutação termina com `notifyListeners()`.
- [ ] Valores derivados recalculados da própria lista em memória.
- [ ] Após navegação (push) ou mutação, chamar `inicialData()` para sincronizar.
- [ ] Erros capturados com `try/catch` e tratados via `DisplayAlert`.
- [ ] `BuildContext` recebido por parâmetro nos métodos (não guardado como campo).

### Parte visual
- [ ] UI quebrada em `components/` `StatelessWidget`.
- [ ] Componentes recebem dados + callbacks, não o VM.
- [ ] Componentes não importam services nem Firebase.
- [ ] Blocos repetidos (campos, cards, seções) extraídos em component próprio.
- [ ] `build` da View sem lógica de estilo/negócio — só estrutura + composição.
- [ ] Constantes visuais importadas de `common/constants/constants.dart`
      (`bgColor`, `buttonColor`, `whiteColor`, `secondaryColor`).
- [ ] Nenhum texto visível ao usuário como literal na View/ViewModel — todos
      via `common/strings/<area>_strings.dart` (ex.: `AuthStrings.loginButton`).
- [ ] `RefreshIndicator.onRefresh` aponta para `_viewModel.refresh`.
- [ ] `ListView.builder` com `itemCount`/`itemBuilder` lendo o VM.
- [ ] `FloatingActionButton` delega ação ao VM.

### Services / Model
- [ ] Novos campos de model usam `fromMap`/`toMap` (nullable).
- [ ] Novas operações de dados entram no `HttpRequest` (não criar repositórios paralelos).
- [ ] Caminhos do Firebase seguem a hierarquia existente
      `EMPRESAS/{uid}/USERS/{uid}/ORCAMENTOS/{id}/...`.
- [ ] Variáveis globais (`uid.user`, `budget.IDORCAMENTO`, `budget.IDRECIBO`)
      atualizadas conforme o fluxo existente.

### Enums compartilhados
- [ ] Enums de seleção de campo (`Gender`/`*FieldType`) em `lib/common/enums/`,
      não soltos na View/ViewModel.
- [ ] Nome do enum não colide com o nome do widget de campo reutilizável
      (ex.: `SingUpFieldType` + widget `SingUpField`).

### Strings / Internacionalização
- [ ] Texto visível ao usuário não fica como literal — vai para
      `lib/common/strings/<area>_strings.dart`.
- [ ] A classe resolve o idioma pela localidade do dispositivo
      (`WidgetsBinding.instance.platformDispatcher.locale`) e expõe getters
      `static`.
- [ ] Mensagens de erro/sucesso do ViewModel também usam as strings
      (nenhum literal em `_mapFirebaseAuthError`/`errorMessage`).
- [ ] Arquivo da classe segue `<area>_strings.dart`
      (ex.: `lib/common/strings/auth_strings.dart`).
- [ ] Arquivo do enum segue `<feature>_field_enum.dart`
      (ex.: `lib/common/enums/singup_field_enum.dart`).

---

## 5. Template de Código

### 5.1 View (`*_view.dart`)
```dart
class FeatureView extends StatefulWidget {
  final Model item;
  final Model parent;
  const FeatureView({super.key, required this.item, required this.parent});
  @override
  State<FeatureView> createState() => _FeatureView();
}

class _FeatureView extends State<FeatureView> {
  late final FeatureViewModel _viewModel;

  @override
  void initState() {
    super.initState();
    _viewModel = FeatureViewModel(item: widget.item, parent: widget.parent);
    WidgetsBinding.instance.addPostFrameCallback((_) => _viewModel.inicialData());
  }

  @override
  void dispose() {
    _viewModel.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: AnimatedBuilder(
        animation: _viewModel,
        builder: (context, _) {
          return Column(children: [
            FeatureHeader(onBack: () => Navigator.pop(context, true)),
            Expanded(child: RefreshIndicator(
              onRefresh: _viewModel.refresh,
              child: ListView.builder(
                itemCount: _viewModel.found.length,
                itemBuilder: (context, index) => FeatureCard(
                  item: _viewModel.found[index],
                  moneyConvert: _viewModel.moneyConvert,
                  onDelete: () => _viewModel.delete(context, index),
                  onEdit: () => _viewModel.edit(context, index),
                ),
              ),
            )),
          ]);
        },
      ),
      floatingActionButton: FloatingActionButton(onPressed: () => _viewModel.add(context)),
      bottomNavigationBar: AnimatedBuilder(
        animation: _viewModel,
        builder: (context, _) => FeatureTotalBar(
          total: _viewModel.total,
          moneyConvert: _viewModel.moneyConvert,
        ),
      ),
    );
  }
}
```

### 5.2 ViewModel (`*_view_model.dart`)
```dart
class FeatureViewModel extends ChangeNotifier {
  final HttpRequest db = HttpRequest();
  final DisplayAlert displayAlert = DisplayAlert();
  final LoadingEvent loadingEvent = LoadingEvent();
  final ConvertCoin moneyConvert = ConvertCoin();

  final Model item;
  final Model parent;

  List<Model> found = <Model>[];
  double total = 0;

  FeatureViewModel({required this.item, required this.parent});

  Future<void> inicialData() async {
    found = await db.getList(parent, item);
    _calcTotal();
    notifyListeners();            // <- único gatilho de rebuild
  }

  Future<void> refresh() => inicialData();

  void _calcTotal() {
    total = found.fold(0, (s, e) => s + (e.valor ?? 0));
  }

  Future<void> delete(BuildContext context, int index) async {
    loadingEvent.alertLoading(context);
    try {
      await db.delete(found[index].id!);
      loadingEvent.closeLoading(context);
      await displayAlert.notificationNotCloseScreen(context, "Feito!", "Removido com sucesso!");
    } catch (e) {
      loadingEvent.closeLoading(context);
      await displayAlert.notificationError(context, "Erro!", "Problemas ao remover");
    }
    await inicialData();
  }
}
```

---

## 6. Anti-padrões a Evitar

- ❌ Usar `setState` na View para dados que vivem no ViewModel.
- ❌ Guardar `BuildContext` como campo do ViewModel (vaza e quebra em hot reload).
- ❌ Componentes (`Stateless`) importando `HttpRequest`/Firebase ou chamando `notifyListeners`.
- ❌ Chamadas de `notifyListeners()` fora do VM.
- ❌ Recalcular totais/derivados na View (delegar ao VM via método privado).
- ❌ Navegar (`Navigator.push`) e **não** recarregar os dados ao voltar.
- ❌ Adicionar Provider/Riverpod/Bloc/GetX "só para essa tela" — quebra o padrão nativo.
- ❌ Criar dois repositórios para a mesma coleção do Firebase.
- ❌ Esquecer `_viewModel.dispose()` → vazamento de listeners do `ChangeNotifier`.
- ❌ View inchada (`build` com centenas de linhas, UI inline duplicada) — extraia em
  `components/` `StatelessWidget`.
- ❌ Passar o ViewModel inteiro para um component — passe só dados + callbacks.
- ❌ Usar `context` em métodos de widget fora do `build` sem recebê-lo por parâmetro.

---

## 7. Fluxo de Dados (unidirecional)

```
 [User action]
      │
      ▼
 [View] ──chama método──▶ [ViewModel] ──muta estado──▶ notifyListeners()
      ▲                        │
      │ rebuild                ▼
      │                  [Services / HttpRequest] ──▶ Firebase
      │                        │
      └── AnimatedBuilder ◀────┘ (lista/total atualizados)
```

1. A View chama um método do VM (ex.: `add`).
2. O VM aciona o service (`HttpRequest`), atualiza suas variáveis internas.
3. O VM chama `notifyListeners()`.
4. Os `AnimatedBuilder`s da View reconstrõem a UI com o novo estado.
5. Componentes recebem os novos dados via construtor.

---

## 8. Modais complexos (view + view model)

**Modais complexos** — bottom sheets com vários campos, seleção de campo
focado, fluxo loading/success/error, validação, etc. — **continuam seguindo o
padrão View + ViewModel**, mesmo sendo exibidos como `showModalBottomSheet`.

A regra é simples: o **tamanho da UI** (tela cheia x modal) **não muda a
arquitetura**. O que define se uma feature precisa das duas camadas é a
**complexidade do estado**, não o recipiente visual.

- A **View** é um `StatefulWidget` cujo `build` retorna a base visual do modal
  (`AppBottomModal` em `lib/common/widgets/modals/`) envolvida num
  `AnimatedBuilder(animation: _viewModel, ...)`. Cria/descarta o VM em
  `initState`/`dispose` e trata estados terminais de forma *one-shot*
  (loading/success/error), igual faria numa tela cheia.
- O **ViewModel** (`extends ChangeNotifier`) fica **idêntico ao de uma tela**:
  detém controllers, estado reativo, ações e fala com os services. **Não**
  guarda `BuildContext`.
- Os **components** (`components/*` `StatelessWidget`) continuam recebendo
  dados + callbacks — nunca o VM inteiro.
- A abertura/fechamento do modal fica num helper ao final do `*_view.dart`
  (`show<Feature>BottomModal(context)`), no mesmo formato dos demais helpers
  de modal do app (`showOptionBottomModal`, `showAppBottomModal`).
- Modais **simples** (confirmação, seleção de opção, input único) continuam
  sendo `StatelessWidget` puros sobre `AppBottomModal`, sem ViewModel — só
  precisam de VM quando há estado a gerenciar.

> **Referência canônica de modal complexo:** `lib/presentations/singup/`
> (`SingUpView` é um bottom modal que mantém `SingUpViewModel`). Antes era uma
> tela cheia; virou modal **sem perder** a separação View/ViewModel.

---

## 9. Quando ESTE padrão NÃO se aplica

- Telas com estado compartilhado entre múltiplas rotas (precisaria elevar o VM ou usar
  Provider) — discutir antes de mudar a abordagem.
- Streams contínuas do Firebase — prefira `StreamBuilder` pontual; se o estado precisar
  ser reativo global, revisar arquitetura antes de introduzir pacotes.

> **Regra de ouro:** em dúvida, replique o formato de `lib/presentations/payment/payment_list/`
> (referência de **listagem**) ou `lib/presentations/pdf/pdf_edit/` (referência de
> **formulário** com components desacoplados). Para **tela de cadastro/autenticação**
> use `lib/presentations/singup/` (referência de **signup** com enum em `common/enums`,
> campo reutilizável e link de login desacoplados) — hoje um **bottom modal complexo**
> que mantém View + ViewModel (ver seção 8). Esses diretórios são o **contrato de
> referência** do padrão.

---

## 10. Recomendação: padronizar TODOS os Models (`fromJson`/`toJson`/`copyWith`)

Ao longo do projeto, vários models de tela foram criados **sem seguir o padrão
 de model do Flutter**. É comum encontrar classes que:

- têm `fromMap(dynamic json)` (em vez de `fromJson(Map<String, dynamic>)`);
- têm `toJson()` mas **nenhum `copyWith()`**;
- expõem **campos públicos mutáveis** (sem `final`), o que leva a reatribuições
  espalhadas pela View/ViewModel (`item.QTD = ...`, `item.indice = ...`) em vez
  de cópias imutáveis;
- usam nomes de campos em `UPPER_CASE` direto no Dart (misturando a chave do
  Firebase com o nome do atributo).

Isso dificulta testes, gera mutação imprevisível de estado e impede o uso de
`const`/`copyWith` (base do data-class no Flutter). **Recomenda-se migrar cada
model de tela para o padrão canônico** e, enquanto a migração não cobre o app
inteiro, conviver com os models legados via **adapters de fronteira**.

### 10.1 Padrão canônico de Model

```dart
class FeatureModel {
  final String? id;
  final String? nome;
  final double? valor;

  const FeatureModel({this.id, this.nome, this.valor});

  factory FeatureModel.fromJson(Map<String, dynamic> json) => FeatureModel(
        id: json['id'] as String?,
        nome: json['NOME'] as String?,
        valor: (json['VALOR'] as num?)?.toDouble(),
      );

  Map<String, dynamic> toJson() => <String, dynamic>{
        'id': id,
        'NOME': nome,
        'VALOR': valor,
      };

  FeatureModel copyWith({String? id, String? nome, double? valor}) =>
      FeatureModel(
        id: id ?? this.id,
        nome: nome ?? this.nome,
        valor: valor ?? this.valor,
      );
}
```

Regras:
- Campos `final`, construtor `const`.
- `factory fromJson(Map<String, dynamic>)` (não `fromMap(dynamic)`).
- `toJson()` retorna `Map<String, dynamic>`.
- `copyWith({...})` sempre presente.
- As **chaves do Firebase** podem continuar maiúsculas (`NOME`, `VALOR`) para
  não quebrar documentos já gravados — o que muda é só a nomenclatura Dart
  (`camelCase`).

### 10.2 Onde o model mora

- Models **compartilhados entre várias features** (orçamento, recibo, usuário):
  continuam em `lib/models/*` (camada global).
- Models **específicos de uma feature** (ex.: item de lista de preço):
  ficam em `lib/presentations/<feature>/model/`, junto da tela que os usa. Isso
  evita que um model de uma tela vire dependência global e incentiva o uso do
  padrão canônico desde a criação.

### 10.3 Convivendo com models legados (adapters de fronteira)

Enquanto os models antigos (`ItemsBudget`, `ItemsListBudget`, ...) ainda são
usados por services compartilhados e por outras telas, **não se reescreve o
mundo de uma vez**. O novo model feature-scoped expõe **adapters** que
convertem só na borda:

```dart
class ProductPriceModel {
  // ... padrão canônico ...

  factory ProductPriceModel.fromItemsBudget(ItemsBudget item) => ...;
  ItemsBudget toItemsBudget() => ...;
  ItemsListBudget toItemsListBudget() => ...;
}
```

Assim a View/ViewModel só manipula o model novo; a conversão para o legado
acontece ao chamar um service compartilhado (`db.salvaItensList(...)`) ou ao
receber um item de outra tela. Quando os models legados forem migrados de
fato, basta **remover os adapters**.

### 10.4 Referência canônica da migração

> **Referência:** `lib/presentations/product/` é o **contrato de referência**
> da migração de models. O `product_price_creator` foi migrado para
> `ProductPriceModel` (`lib/presentations/product/model/product_price_model.dart`)
> com `fromJson`/`toJson`/`copyWith` + adapters, e passou a ter
> `ProductPriceCreatorViewModel` (`extends ChangeNotifier`) + components
> (`ProductPriceCreatorHeader`, `ProductPriceField`) seguindo este SDD. Ao
> migrar as demais telas, replique esse formato.

### 10.5 Checklist de migração de Model

- [ ] Campos `final`, construtor `const`.
- [ ] `factory fromJson(Map<String, dynamic>)`.
- [ ] `toJson()` retorna `Map<String, dynamic>`.
- [ ] `copyWith({...})` implementado.
- [ ] Sem mutação direta de campos na View/ViewModel — usar `copyWith`.
- [ ] Chaves do Firebase preservadas (para não quebrar dados existentes).
- [ ] Model feature-scoped em `lib/presentations/<feature>/model/`; global em
      `lib/models/`.
- [ ] Adapters de fronteira com models legados, removíveis quando o legado for
      migrado.
- [ ] Ajustar todos os call sites que instanciam o model antigo para usar o
      novo (ou o adapter de entrada).
