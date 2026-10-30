# Plano de Implementação — Padronização de Strings por Módulo

## Objetivo

Eliminar **todas as strings literais (hardcoded)** de Views, ViewModels e componentes. Criar arquivo `presenter/strings/{modulo}_pt_string.dart` em **cada módulo 100% completo** com todos os textos usados nele.

## Estado Atual

| Módulo | Strings Centralizadas? | Arquivo |
|--------|-----------------------|---------|
| ✅ login | Sim (completo) | `lib/modules/login/presenter/strings/login_pt_string.dart` |
| ✅ singup | Sim (completo) | `lib/modules/singup/presenter/strings/singup_pt_string.dart` |
| ✅ product | Sim (migrado de shared) | `lib/modules/product/presenter/strings/product_pt_string.dart` |
| ✅ receipt | Sim (migrado de shared) | `lib/modules/receipt/presenter/strings/receipt_pt_string.dart` |
| ✅ product | Sim (migrado de shared) | `lib/modules/product/presenter/strings/product_pt_string.dart` |
| ✅ receipt | Sim (migrado de shared) | `lib/modules/receipt/presenter/strings/receipt_pt_string.dart` |
| ❌ budget | Não | pendente |
| ❌ payment | Não | pendente |
| ❌ pdf | Não | pendente |
| ❌ dashboard | Não | pendente |
| ❌ chat_budget | Não | pendente |
| ❌ subscription | Não | pendente |
| ❌ comment | Não | pendente |
| ❌ image | Não | pendente |
| ❌ main_config_menu | Não | pendente |
| ❌ terms_conditions | Não | pendente |
| ❌ web_budget | Não | pendente |
| ❌ core/convert_coin | Não | pendente |
| ❌ core/cep | Não | pendente |
| ❌ core/in_app_purchase | Não | pendente |
| ❌ notification | Não | pendente |
| ❌ share_link | Não | pendente |

---

## Módulos Já Concluídos (exemplos de referência)

### 1. `login` ✅ (finalizado)


- [x] Criar `lib/modules/login/presenter/strings/login_pt_string.dart`
- [x] Mover strings do antigo `shared/common/strings/auth_strings.dart` (parte de login)
- [x] Atualizar imports em: `login_view.dart`, `login_view_model.dart`, `login_footer.dart`, `login_header.dart`
- [x] Substituir `AuthStrings` → `LoginStrings`
- [x] Apagar referências `AuthStrings` no módulo login

### 2. `singup` ✅ (finalizado)


- [x] Criar `lib/modules/singup/presenter/strings/singup_pt_string.dart`
- [x] Mover strings do antigo `shared/common/strings/auth_strings.dart` (parte de cadastro)
- [x] Atualizar imports em: `singup_view.dart`, `singup_view_model.dart`, `singup_login_link.dart`
- [x] Substituir `AuthStrings` → `SingUpStrings`
- [x] Apagar referências `AuthStrings` no módulo singup
- [x] Apagar `lib/shared/common/strings/auth_strings.dart` (não mais usado)

---

## Passo a Passo para Migrar um Módulo

### 1. Descobrir strings hardcoded no módulo

```bash
# Exemplo para o módulo budget
grep -rn "\".*\"" lib/modules/budget/presenter/ --include="*.dart" | grep -v "import\|comment\|Image.asset\|AssetImage\|TextStyle\|BoxDecoration\|Color(" | head -50
```

Ou usar o comando mais completo (detecta todos os textos literal com letras):

```bash
grep -rn "'[A-Za-zãÃõÕáÁéÉíÍóÓúÚàÀèÈìÌòÒùÙâÂêÊîÎôÔûÛäÄëËïÏöÖüÜçÇ ]\+'" lib/modules/{modulo}/presenter/ --include="*.dart"
```

### 2. Criar arquivo de strings

```bash
mkdir -p lib/modules/{modulo}/presenter/strings
touch lib/modules/{modulo}/presenter/strings/{modulo}_pt_string.dart
```

### 3. Implementar a classe de strings

```dart
import 'package:flutter/widgets.dart';

/// Textos do módulo {Modulo} internacionalizados.
///
/// Resolve o idioma a partir da **localidade do dispositivo**
/// e devolve a string em `pt` ou `en` (fallback).
class {Modulo}Strings {
  const {Modulo}Strings._();

  static Locale get _locale =>
      WidgetsBinding.instance.platformDispatcher.locale;

  static String get _code => _locale.languageCode;

  static bool get _isPt => _code == 'pt';

  // --- Header / Títulos ---
  static String get title => _isPt ? 'Título em PT' : 'Title in EN';
  // ... demais strings
}
```

### 4. Importar nos arquivos do módulo

```dart
import 'package:oflite/modules/{modulo}/presenter/strings/{modulo}_pt_string.dart';
```

### 5. Substituir todas as strings literais no módulo

- View: todos os `Text('...')`, `hintText`, `label`, `title`, `content`
- ViewModel: todas as mensagens de erro, sucesso, validação
- Componentes: todos os labels, tooltips, textos de botões

### 6. Rodar `flutter analyze` no módulo

```bash
cd /Users/davidelias/StudioProjects/budget_flutter
flutter analyze
```

### 7. Verificar imports quebrados

```bash
grep -rn "shared/common/strings" lib/modules/{modulo}/ --include="*.dart"
# Se tiver resultado, migrar para o novo import do módulo
```

---

## Checklist por Módulo (processo repetitivo)

| # | Tarefa | Status |
|---|--------|--------|
| 1 | Criar pasta `presenter/strings/` | ⬜ |
| 2 | Criar `{modulo}_pt_string.dart` com classe de strings | ⬜ |
| 3 | Varredura de strings hardcoded no módulo | ⬜ |
| 4 | Migrar todas as strings para o arquivo novo | ⬜ |
| 5 | Atualizar imports em View, ViewModel e Components | ⬜ |
| 6 | Substituir referências (ex: `'Texto'` → `ModuloStrings.texto`) | ⬜ |
| 7 | Rodar `flutter analyze` | ⬜ |
| 8 | Verificar `flutter build` não quebra | ⬜ |

---

## Prioridade de Migração (sugestão)

1. **`terms_conditions`** — muito provavelmente tem textos longos hardcoded
2. **`dashboard`** — tem labels de gráficos/séries
3. **`budget`** — maior módulo, mais strings
4. **`payment`** — labels de formulários e status
5. **`receipt`** — status, labels
6. **`subscription`** — planos, preços, textos
7. **`product`** — labels de campos, mensagens
8. **`pdf`** — labels de botões/geração
9. **`chat_budget`** — mensagens do assistente
10. **`comment`** — labels e mensagens
11. **`image`** — labels de edição
12. **`main_config_menu`** — labels de configurações
13. **`web_budget`** — strings web
14. **`core/*` módulos** — ultimo, são serviços

---

## Convenção de Nomenclatura (Regra Nova do Projeto)

| Elemento | Padrão | Exemplo |
|----------|--------|---------|
| Arquivo de strings | `{modulo}_pt_string.dart` | `login_pt_string.dart` |
| Classe de strings | `{Modulo}Strings` | `LoginStrings` |
| Getter de string | `nomeDescritivo` | `loginButton`, `signUpErrorDefault` |
| Pasta dentro do presenter | `presenter/strings/` | `lib/modules/login/presenter/strings/` |

---

## Anti-padrões a EVITAR

1. ❌ Colocar strings em `shared/common/strings/` (arquivo monolítico)
2. ❌ Criar strings literais em qualquer View, ViewModel ou Componente
3. ❌ Usar `AuthStrings` (antigo nome) — foi deletado
4. ❌ Criar classe genérica sem prefixo do módulo (ex: `AppStrings` → usar `LoginStrings`)
5. ❌ Strings em português sem a condição `_isPt` (manter sempre pt/en)

---

> Documento gerado em `.pi/PLANO_MIGRACAO_STRINGS.md` — atualizar conforme módulos forem migrados.
