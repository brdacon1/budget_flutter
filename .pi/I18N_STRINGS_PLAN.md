# 🌐 Plano de Implementação — Strings PT/EN por Módulo

> **Fonte de verdade**: `.pi/ARCHITECTURE.md` (Regra de Ouro #12 e seção 12 —
> "Criar strings de um módulo").
> **Objetivo**: nenhum texto visível ao usuário fica hardcoded em View,
> ViewModel, componente, modal **ou nos textos gerados do orçamento (PDF,
> mensagens do chat, recibo)**. Todo texto vive em
> `presenter/strings/{modulo}_pt_string.dart`, com versão **Português e Inglês**.
> **Execução**: **um módulo por vez**, sob comando do usuário. Ao terminar o
> módulo, o agente **PARA** (ver seção 2).

---

## 1. Padrão obrigatório (já usado no projeto)

Referência real: `lib/modules/auth/presenter/login/strings/login_pt_string.dart`.

```dart
import 'package:flutter/widgets.dart';

/// Textos do módulo {Modulo} (pt / en — fallback en).
class {Modulo}Strings {
  const {Modulo}Strings._();

  static Locale get _locale =>
      WidgetsBinding.instance.platformDispatcher.locale;

  static bool get _isPt => _locale.languageCode == 'pt';

  // --- {Tela}: {seção} ---
  static String get budgetCreateTitle =>
      _isPt ? 'Criar orçamento' : 'Create budget';

  // Texto com parâmetro → método estático
  static String itemPrice(String value) =>
      _isPt ? 'Preço: $value' : 'Price: $value';
}
```

Regras:

1. **Arquivo**: `lib/modules/{modulo}/presenter/strings/{modulo}_pt_string.dart`
   (nome mantido por convenção da arquitetura, mesmo contendo EN). Submódulos
   que já têm arquivo próprio (ex.: `auth/presenter/login/strings/`,
   `budget/.../comment_pt_string.dart`, `receipt/.../payment_pt_string.dart`)
   **continuam onde estão**.
2. **Toda** getter tem `pt` **e** `en`. `en` é o fallback para qualquer outra
   localidade. Getters só-PT existentes (ex.: `statusApproved => 'Aprovado'`)
   devem ganhar a versão EN.
3. Texto com interpolação → **método estático** com parâmetros
   (`static String totalBudget(String v)`), nunca concatenação na View.
4. Getters agrupados por tela com comentário `// --- Tela: seção ---`.
5. Ponytail: **sem** pacote novo (`flutter_localizations`, `arb`, `intl`
   gen) — seguimos o padrão estático existente. Sem classe base/abstração
   compartilhada.
6. Strings são **do módulo dono**. Se outro módulo precisa, importa a classe do
   módulo dono (seção 12 da arquitetura). Não criar `shared/common/strings/`.

### 1.1 O que NÃO traduzir (cuidado — quebra regra de negócio)

| Caso | Exemplo real | O que fazer |
|------|--------------|-------------|
| **Valor persistido no Firestore / comparado em lógica** | `item.category == 'Serviços'` (budget, pdf, product, web_budget, chat_assistant) | **Manter o valor gravado em PT**. Criar só um *label* de exibição: `static String categoryLabel(String stored)` que mapeia `'Serviços'`→`Services`, `'Produtos'`→`Products`. Comparações continuam com a constante original. |
| **Chave de ação usada em `switch`/`==`** | `case 'NÃO':`, `'actions': ['SIM','NÃO']`, `value == "Criar novo item"` | Separar **chave** (constante estável, não traduzida) de **label** (traduzido). Ex.: comparar por índice/enum ou contra o **mesmo getter** usado para montar a lista. Nunca comparar texto traduzido com literal. |
| **Logs e exceções técnicas** | `debugPrint(...)`, `Exception('User not authenticated')`, mensagens de `notification_repository_impl` | Não traduzir (não são visíveis ao usuário). |
| **Headers / chaves técnicas** | `'Authorization': 'Bearer $token'`, chaves de `Map` (`'label'`, `'action'`) | Não traduzir. |
| **Moeda / data** | `R$`, `convertFromDouble` | Fora do escopo deste plano. |

### 1.2 Textos do orçamento (PDF / recibo / chat) — "hardcoded"

Os usecases de geração em `pdf/domain/usecase/pdf_generate_budget/*` e
`pdf_generate_receipt/*` têm rótulos fixos (`'Número :'`, `'Cliente :'`,
`'LISTA DE ITENS DO ORÇAMENTO'`, `'Descrição dos produtos'`, `'Preço'`,
`'Valor total:'` …) e o modelo de demonstração em
`pdf_model_select_view_model.dart` (`'Cliente de Demonstração'`,
`'Produto exemplo'` …).

- Todos vão para `pdf/presenter/strings/pdf_pt_string.dart` (seção
  `// --- Documento PDF: orçamento ---` e `// --- Documento PDF: recibo ---`).
- O usecase importa `PdfStrings` diretamente (classe estática pura, sem
  widget/context) — menor diff, sem passar labels por parâmetro.
- O idioma do PDF segue o idioma do **dispositivo de quem gera**.
- Mensagens do bot do chat (`'Confirme os dados do cliente:'`,
  `'Itens do orçamento:'`, `'Total: …'`) vão para
  `chat_assistant/presenter/strings/chat_budget_pt_string.dart` como métodos
  com parâmetro.

---

## 2. Protocolo de execução por módulo (OBRIGATÓRIO)

**Comando do usuário**: `implemente o plano de linguas no modulo {modulo}`

O agente executa **somente** o módulo pedido, nesta ordem:

1. **Ler** esta seção e a linha do módulo na tabela da seção 3.
2. **Inventariar** os literais do módulo:
   ```bash
   grep -rn -E "['\"][A-ZÀ-Úa-zà-ú][^'\"]*[ À-ú][^'\"]*['\"]" lib/modules/{modulo} --include='*.dart' \
     | grep -v -E "/strings/|:\s*(import|export|//)|debugPrint|log\(|print\(|'package:"
   ```
   Revisar também literais de **uma palavra** (`'Salvar'`, `'Cancelar'`,
   `'Itens'`): `grep -rn -E "Text\(\s*['\"]|(title|label|hintText|labelText|message|tooltip|placeholder|buttonLabel|primaryText)\s*:\s*['\"]" lib/modules/{modulo}`.
3. **Classificar** cada literal: visível ao usuário → mover; caso da tabela 1.1
   → tratar como lá descrito.
4. **Criar/completar** o arquivo de strings do módulo (PT + EN em toda getter).
5. **Substituir** os literais em Views, ViewModels, componentes, modais,
   usecases (só o módulo `pdf`) e repositórios que exibem texto.
   Remover `const` de widgets que passaram a usar getter.
6. **Verificar**:
   - `flutter analyze lib/modules/{modulo}` sem erros novos;
   - repetir o grep do passo 2 → só sobram itens da tabela 1.1;
   - nenhuma comparação lógica passou a usar texto traduzido.
7. **Atualizar** a tabela da seção 3: status `✅ concluído` + observações
   (arquivos criados, valores persistidos mantidos).
8. **PARAR.** Reportar ao usuário em poucas linhas:
   - arquivos de strings criados/alterados;
   - nº de textos migrados;
   - itens deixados de fora de propósito (tabela 1.1);
   - próximo módulo sugerido.

> ⛔ **Regra de parada**: ao concluir o passo 8 o agente **encerra o turno**.
> **Não** inicia o próximo módulo, **não** mexe em arquivos de outros módulos
> (exceto o import da classe de strings quando um componente compartilhado do
> próprio módulo é usado fora dele), **não** faz commit. O próximo módulo só
> começa com um novo comando
> `implemente o plano de linguas no modulo {proximo}`.

---

## 3. Módulos — ordem de migração e status

Ordem: do mais isolado/menor para o mais acoplado/maior. A contagem é uma
estimativa de literais com espaço/acento fora de `strings/` (inventário de
2026-11-16) — o grep do passo 2 é a fonte real.

| # | Módulo | Arquivo(s) de strings | Literais restantes (≈) | Atenção | Status |
|---|--------|------------------------|------------------------|---------|--------|
| 1 | `auth` (login + singup) | `login/strings/login_pt_string.dart`, `singup/strings/singup_pt_string.dart` | 7 | Já bilíngue — revisar restos e uma-palavra | ⬜ pendente |
| 2 | `support` | `support_pt_string.dart` | 1 | — | ⬜ pendente |
| 3 | `subscription` | `subscription_pt_string.dart` | 2 | Nomes/preços de plano vindos da loja não traduzir | ⬜ pendente |
| 4 | `main_tab` | **criar** `main_tab_pt_string.dart` | 1+ | Labels das abas | ⬜ pendente |
| 5 | `main_config_menu` | `main_config_menu_pt_string.dart` | 0 (revisar uma-palavra) | — | ⬜ pendente |
| 6 | `image` | `image_pt_string.dart` | 0 (revisar) | `title: 'Editar Logo'` vem de pdf/chat → getter em `ImageStrings` | ⬜ pendente |
| 7 | `terms_conditions` | `terms_conditions_pt_string.dart` | 0 (revisar) | — | ⬜ pendente |
| 8 | `delete_account` | `delete_account_pt_string.dart` | 7 | Web | ⬜ pendente |
| 9 | `dashboard` | `dashboard_pt_string.dart` | 11 | Labels de gráfico/meses | ⬜ pendente |
| 10 | `product` | `product_pt_string.dart` | 11 | Categoria `'Serviços'/'Produtos'` persistida (tabela 1.1) | ⬜ pendente |
| 11 | `receipt` (+ payment) | `receipt_pt_string.dart`, `payment_pt_string.dart` | 11 | — | ⬜ pendente |
| 12 | `core` | **criar** `core/display_alert/presenter/strings/display_alert_pt_string.dart` | 4 visíveis (`display_alert`) | `notification` só tem logs → não traduzir; `_channelName` do Android pode ficar | ⬜ pendente |
| 13 | `budget` (+ comment) | `budget_pt_string.dart` (só 2 getters hoje), `comment_pt_string.dart` | 75 | **Maior lacuna**: creator, list_items, total bar, modais, tab. Categoria persistida; `"Criar novo item"`/`"Selecionar da lista de preço"` usados em `==` | ⬜ pendente |
| 14 | `web_budget` | `web_budget/strings/budget_web_strings.dart` (local mantido — seção 16.4) | 11 + getters só-PT | Completar EN de getters só-PT (`statusApproved` etc.); categoria persistida | ⬜ pendente |
| 15 | `pdf` | `pdf_pt_string.dart` | 133 | **Textos do orçamento/recibo** nos 6 usecases + demo do model select (seção 1.2). `PdfLayoutType` label `'Padrão'` | ⬜ pendente |
| 16 | `chat_assistant` | `chat_budget_pt_string.dart` | 99 | Mensagens do bot com parâmetro; ações `'SIM'/'NÃO'`, `'Confirmar endereço'`, `'Editar comentários'` são chaves de `switch` → separar chave × label (tabela 1.1) | ⬜ pendente |
| 17 | `shared` (`lib/shared/common/widgets/modals`) | sem arquivo próprio | ~12 | Defaults hardcoded (`'Não'`, `'Digite a quantidade'`, `'Trocar nome de usuário'`, `'Ver anuncio'`, `'Como você quer inserir o item?'`…). Tornar parâmetros **obrigatórios** e os chamadores passam o texto da classe de strings do módulo dono (ex.: `item_option` → `BudgetStrings`, `change_name`/`change_password` → `MainConfigMenuStrings`). Não criar `shared/common/strings/` | ⬜ pendente |
| 18 | Documentação | `.pi/ARCHITECTURE.md` | — | Atualizar seção 12 "Criar strings de um módulo": exigir PT+EN e citar a tabela 1.1 | ⬜ pendente |

---

## 4. Definição de pronto (por módulo)

- [ ] Grep do passo 2 sem textos visíveis ao usuário fora de `strings/`.
- [ ] Toda getter do arquivo de strings tem PT e EN.
- [ ] Valores persistidos e chaves de lógica intactos (tabela 1.1).
- [ ] `flutter analyze lib/modules/{modulo}` sem erros novos.
- [ ] Linha do módulo na seção 3 marcada `✅ concluído` com observações.
- [ ] Agente parou e reportou (seção 2, passo 8).

## 5. Teste manual (opcional, ao final de todos os módulos)

Trocar o idioma do simulador/dispositivo para **English** e para
**Português**, abrir as telas do módulo e gerar um PDF de orçamento e de
recibo; no Web: `flutter run -d chrome --target lib/main_web.dart` com o
navegador em `en`.
