# Arquitetura de Módulos — Guia de Refatoração

> Este guia descreve a estrutura interna dos módulos **sem amarração a nenhuma biblioteca de roteamento/injeção específica**.  
> A ideia pode ser replicada com `get_it`, `injectable`, `provider` ou qualquer outro container de DI.

---

## 1. Visão Geral

O projeto é organizado em **módulos feature-first**. Cada módulo é uma caixa de areia com suas próprias camadas:

- **Domain** — regras de negócio puras
- **Data** — fontes de dados e implementações
- **Presenter** — telas, estado visual e widgets

Existem também módulos **`core`**: serviços compartilhados (HTTP, WebSocket, storage, estabelecimento, conectividade) que **não possuem** camada `presenter`.

---

## 2. Estrutura de Pastas de um Módulo

```
modules/<nome_modulo>/
├── <nome>_binds.dart          # Registro das dependências do módulo
├── <nome>_routes.dart         # Enum de rotas + mapa de navegação
├── domain/
│   ├── entity/                # Entidades de negócio (pura Dart)
│   ├── repository/            # Contratos abstratos (interfaces)
│   ├── usecase/               # Orquestração de regras de negócio
│   └── enum/                  # Enums do domínio
├── data/
│   ├── datasource/            # Fontes de dados (remoto, local, socket)
│   ├── model/
│   │   ├── request/           # Payloads de envio (JSON)
│   │   └── response/          # Payloads de retorno (JSON)
│   └── repository/            # Implementação dos contratos de domain
└── presenter/
    ├── <tela>/                # View + ViewModel (ex: login/login_view.dart)
    ├── controller/            # Controladores de input/formulário
    ├── enum/                  # Enums de UI
    └── widgets/               # Componentes visuais internos do módulo
```

> Módulos `core` omitem a pasta `presenter`.

---

## 3. Responsabilidade de cada Camada

### 3.1 Domain

#### Entity
- Representa um objeto do negócio.
- Sem dependência de frameworks externos (exceto, opcionalmente, `freezed`/`equatable`).
- Contém `copyWith`, igualdade e campos finais.
- **Não sabe de JSON, HTTP ou banco de dados.**

#### Repository (interface/contrato)
- Define o **contrato** que o domínio precisa para funcionar.
- Pode estender `ChangeNotifier` quando o estado interno do repositório precisa ser **reativo** (ex: usuário logado, mesa selecionada, lista carregada). Assim, ViewModels e outros repositories podem escutar mudanças.
- Retorna `Result<T>` em vez de lançar exceções.
- **Não sabe de HTTP ou JSON.**

#### Usecase
- Orquestra um ou mais repositories para executar uma operação de negócio.
- **Stateless**; geralmente expõe um método `call()` ou nome descritivo.
- Pode conter lógica de cálculo, montagem de entidades ou validações de negócio antes de repassar ao repository.
- **Não faz I/O diretamente.**

### 3.2 Data

#### Datasource
- Ponto de contato com o mundo externo:
  - Chamadas HTTP (`Dio`, `http`)
  - Leitura/escrita em storage local (`SecureStorage`, `SharedPreferences`, `Hive`)
  - Conexões WebSocket
  - Qualquer outro I/O (Bluetooth, NFC, etc.)
- Retorna um wrapper de resultado próprio (`DataState<T>` ou `Result<T>`).
- **Não conhece `Entity`**. Trabalha apenas com `Model` (parse de JSON).
- Idealmente, cada fonte distinta tem seu próprio datasource (`*_remote_datasource.dart`, `*_storage_datasource.dart`).

#### Model
- Estrutura de parse JSON (DTO).
- Pode **implementar** a `Entity` correspondente (`Model implements Entity`) ou possuir um mapper `toEntity()`.
- Contém `fromJson` / `toJson`.
- Separado em `request/` (body de POST/PUT) e `response/` (body de GET/POST).

#### Repository Implementation (`*_repository_impl.dart`)
- Implementa a interface definida em `domain/repository/`.
- Responsabilidades:
  1. Instanciar/consumir **Datasource(s)**.
  2. Converter `Model` → `Entity`.
  3. Manter **estado em memória** quando necessário (cache local, variáveis privadas, seleção atual).
  4. Notificar listeners (`notifyListeners()`) herdado do contrato quando o estado interno muda.
  5. Tratar erros de datasource e propagar como `Result<T>`.
- **É o único lugar que sabe de Model e Datasource.**

### 3.3 Presenter

#### ViewModel
- Gerencia o **estado da tela** ou de um fluxo.
- Estende `ChangeNotifier` (ou usa outro mecanismo reativo).
- Obtém repositories e usecases via **injeção de dependência**.
- Expõe propriedades observáveis (notifica a View).
- Cria instâncias de **`Command`** para ações iniciadas pelo usuário (botões, pull-to-refresh).
- Contém **lógica de apresentação**: formatação de texto, validação visual, mensagens de erro amigáveis, flags de loading.
- **Não acessa datasource diretamente.**

#### Controller (opcional)
- Gerencia estado de **inputs de formulário** (textos, dropdowns, checkboxes, máscaras).
- Usado pelo ViewModel para desacoplar a lógica de UI pura do estado de tela.
- Pode ser uma classe simples com getters/setters ou `ValueNotifier`.

#### View
- Widget Flutter. Deve ser o mais **"burro"** possível.
- Recebe `ViewModel` via construtor ou provider.
- Escuta notificações e reconstrói.
- **Nunca chama datasource ou usecase diretamente.**

#### Widgets
- Componentes visuais reutilizáveis **dentro do módulo**.
- Para componentes globais, usar `app/shared/widgets/`.

---

## 4. Padrões de Comunicação entre Camadas

### 4.1 `Result<T>`

```dart
sealed class Result<T> {
  const factory Result.ok(T value) = Ok._;
  const factory Result.error(Exception error) = Error._;
}
```

- Usado por **Usecases** e **Repositories** para retornar sucesso ou falha.
- Evita `try/catch` espalhado nas ViewModels.
- ViewModel faz `switch (result)` para reagir.

### 4.2 `Command<T>`

Envolve uma ação assíncrona (`Future<Result<T>>`) e expõe:

- `running` — booleano de loading
- `completed` — booleano de sucesso
- `error` — booleano de erro
- `result` — instância de `Result<T>`

A View chama `command.execute()` e reage aos estados expostos.

```dart
class Command0<T> extends Command<T> { ... }
class Command1<T, A> extends Command<T> { ... } // com argumento
```

### 4.3 `DataState<T>`

Wrapper usado **apenas dentro do Datasource** para HTTP:

- `DataSuccess<T>`: resposta parseada
- `DataFailed`: exception de I/O ou HTTP

O `RepositoryImpl` converte `DataState` em `Result<T>` antes de devolver para camadas superiores.

---

## 5. Injeção de Dependências (DI)

Cada módulo possui um arquivo `<nome>_binds.dart` responsável por registrar:

| Tipo | Escopo | Motivo |
|------|--------|--------|
| **Datasource** | Singleton / LazySingleton | Conexão HTTP, socket ou storage reutilizado |
| **Repository (interface)** | Singleton | Mantém estado compartilhado entre telas (usuário, config, lista carregada) |
| **Usecase** | Factory / LazySingleton | Stateless; criado sob demanda se não guarda estado |
| **ViewModel** | Factory | Criado por rota/tela; evita vazar estado entre navegações |
| **Controller** | Factory ou dentro do ViewModel | Lifecycle amarrado à tela |

### Regras de Registro
- Sempre depender da **interface** (`domain/repository`) e injetar a **implementação** (`data/repository`).
- Módulos `core` são registrados no container **raiz** (global), pois são consumidos por múltiplos módulos de feature.
- Módulos de feature podem registrar dependências próprias **e** importar binds de módulos core quando necessário.

> Conceito aplicável em qualquer container: `GetIt`, `Injectable`, `Riverpod`, `Provider` com `MultiProvider`, etc.

---

## 6. Módulos Core (Serviços Compartilhados)

Módulos sem `presenter`. Fornecem capabilities transversais:

- `establishment` — configurações do negócio, cardápio, feature flags
- `connectivity` — status de rede
- `web_socket` — canal real-time
- `waiter` — dados do usuário logado
- `events` — bus de eventos internos (ex: `initWaiterApp`, `refreshTables`)
- `recaptcha`, `pix_payment`, `cashback`, `geolocation`

### Características
- Seguem a mesma estrutura **Domain / Data**.
- **Nunca** dependem de módulos que possuem `presenter`.
- Podem ser ouvidos por qualquer ViewModel da aplicação.

---

## 7. Regras de Ouro

1. **A View nunca acessa Datasource diretamente.** Sempre via `ViewModel → RepositoryImpl → Datasource`.
2. **Datasource nunca retorna Entity.** Sempre `Model`. A conversão acontece no `RepositoryImpl`.
3. **Usecase não faz I/O.** Apenas orquestra repositories e entidades.
4. **Repositories podem ser reativos.** Como o contrato pode estender `ChangeNotifier`, mudanças de estado interno (ex: mesa selecionada) notificam todos os ouvintes.
5. **ViewModel cuida de apresentação; Usecase cuida de negócio.** Não inverta essas responsabilidades.
6. **Compartilhamento via módulos core.** Se dois módulos de feature precisam do mesmo dado, ele provavelmente deve morar em um módulo `core`.
7. **Mantenha Models isolados.** Models de request/response não devem vazar para a camada de domain sem passar por um mapper.

---

## 8. Exemplo de Fluxo Completo

### Cenário: Autenticação

1. **View** (`LoginView`) recebe `LoginViewModel` via DI.
2. Usuário preenche e-mail/senha e toca em "Entrar".
3. **ViewModel** executa `Command0` (`genericLogin`).
4. O Command chama `AuthRepository.genericLogin(...)`.
5. `AuthRepositoryImpl`:
   - Chama `AuthRemoteDatasource.genericLogin(...)` → retorna `DataState<String>` (token).
   - Salva token via `AuthStorageDatasource`.
   - Decodifica JWT e monta `AuthUserEntity`.
   - Atualiza flag interna `_isAuthenticated` e chama `notifyListeners()`.
6. **ViewModel** observa o `Result<AuthUserEntity>` e atualiza flags de erro/sucesso.
7. Um **ViewModel raiz** (`AppViewModel`) também escuta `AuthRepository`; ao detectar autenticação, inicia polling e navega para a home.

### Cenário: Mesas

1. **View** (`TablesView`) possui `TablesViewModel`.
2. ViewModel executa `Command0` para carregar mesas.
3. Chama `TablesRepository.fetchTables()`.
4. `TablesRepositoryImpl` chama `TablesRemoteDatasource.getTables()`.
5. Datasource retorna `DataState<TablesResponseModel>`.
6. RepositoryImpl converte para `List<TableEntity>`, armazena em memória e notifica.
7. ViewModel expõe a lista para a View.
8. Outras telas (ex: Checkout) injetam o **mesmo** `TablesRepository` singleton e acessam a mesa selecionada sem recarregar tudo.

---

## 9. Adaptação para GetIt (referência mental)

```dart
// auth_binds.dart
void registerAuthDependencies(GetIt sl) {
  // Data sources
  sl.registerLazySingleton<AuthRemoteDataSource>(AuthRemoteDataSource.new);
  sl.registerLazySingleton<AuthStorageDataSource>(AuthStorageDataSource.new);

  // Repository: interface -> implementation
  sl.registerLazySingleton<AuthRepository>(AuthRepositoryImpl.new);

  // Usecase / ViewModel
  sl.registerFactory<LoginViewModel>(LoginViewModel.new);
}
```

A lógica é idêntica:
- Registre datasource → repository impl exposta como interface → viewmodel consumindo a interface.
- Repositories de estado compartilhado vivem como singleton.
- ViewModels vivem como factory (ou `registerFactory` no get_it).

---

## 10. Checklist para Novos Módulos

- [ ] Criar pasta `modules/<nome>/` com `domain/`, `data/` e `presenter/`.
- [ ] Criar `*_binds.dart` e registrar datasource → repository (impl como interface).
- [ ] Criar `*_routes.dart` com enum de rotas e mapa de páginas.
- [ ] Definir `Entity` pura em `domain/entity/`.
- [ ] Definir contrato `Repository` em `domain/repository/` (extender `ChangeNotifier` se reativo).
- [ ] Criar `Model` em `data/model/` (request/response).
- [ ] Criar `Datasource` em `data/datasource/` (retornar `DataState`).
- [ ] Criar `RepositoryImpl` em `data/repository/` (converter Model → Entity, notificar listeners).
- [ ] Criar `Usecase` em `domain/usecase/` se houver orquestração complexa.
- [ ] Criar `ViewModel` em `presenter/<tela>/` com `Command` para cada ação do usuário.
- [ ] Criar `View` em `presenter/<tela>/` consumindo a ViewModel.
- [ ] Se o módulo for compartilhado (sem UI), omitir `presenter/` e registrar no DI global.
