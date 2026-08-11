# Flutter Web — Fluxo Público de Orçamento

## Objetivo

Implementar, dentro do projeto Flutter existente, um **fluxo Web específico para compartilhamento de orçamentos**, sem modificar o comportamento ou as regras de negócio do aplicativo mobile.

O fluxo Web deverá permitir que um orçamento gerado pelo aplicativo seja disponibilizado através de uma URL compartilhável.

O cliente receberá essa URL, informará o número de telefone cadastrado no orçamento e, após as validações necessárias, poderá visualizar o orçamento completo.

A versão Web deverá ser **publicada separadamente das demais telas do aplicativo mobile**.

---

# Instruções obrigatórias

Antes de iniciar qualquer implementação, leia completamente e siga obrigatoriamente:

```text
@.pi/sdd_arquitetura_view_model.md
```

e:

```text
@.pi/web_projet_instruction/create_flutter_web_page.md
```

Esses dois arquivos são a fonte de verdade para:

- Arquitetura.
- Organização do código.
- ViewModel.
- View.
- Estado.
- Navegação.
- Entry point Web.
- Build Web.
- Padrões de implementação.
- Componentes.
- Estrutura do projeto.

Não criar uma arquitetura paralela ou incompatível com essas instruções.

---

# Regra principal

## NÃO alterar regras de negócio existentes

Esta implementação deve ser **aditiva**.

O objetivo é adicionar o fluxo Web sem modificar o funcionamento existente do aplicativo mobile.

Não alterar:

- Regras de negócio.
- Cálculo de orçamento.
- Cálculo de valores.
- Itens.
- Quantidades.
- Descontos.
- Dados do cliente.
- Status existentes.
- Regras de aprovação.
- Regras de geração do orçamento.
- Regras de geração do PDF.
- APIs existentes sem necessidade.
- Contratos existentes.
- Comportamentos das telas mobile.
- Fluxos existentes.
- Componentes existentes sem necessidade.

Sempre que uma regra ou funcionalidade já existir, **reutilizá-la**.

Não duplicar lógica de negócio apenas para implementar o Web.

---

# Objetivo arquitetural

A solução deve reutilizar o máximo possível do código existente.

A estrutura esperada conceitualmente é:

```text
                         PROJETO FLUTTER
                                │
                ┌───────────────┴───────────────┐
                │                               │
             MOBILE                            WEB
                │                               │
          App completo                   Fluxo orçamento
                │                               │
          Android / iOS                    Browser
                                                │
                                                ↓
                                    URL compartilhável
```

As camadas de negócio devem continuar compartilhadas:

```text
Models
Entities
Repositories
Services
API Clients
Use Cases
Validators
Rules
```

A diferença deve estar principalmente na camada de apresentação e no entry point utilizado pelo Web.

---

# 1. Fluxo de geração do orçamento

Sempre que um orçamento for gerado no aplicativo, deverá existir uma versão Web correspondente que possa ser compartilhada com o cliente.

Essa versão Web deve permitir ao cliente acessar os dados do orçamento através de uma URL.

Exemplo conceitual:

```text
https://dominio-web.com/orcamento/{numero-endereco}?token={firebase-token}
```

O formato final da URL deve seguir os padrões definidos em:

```text
@.pi/web_projet_instruction/create_flutter_web_page.md
```

---

# 2. Identificação do orçamento

A URL deve possuir o **número do endereço**.

Esse número será utilizado para localizar o orçamento no banco de dados.

Exemplo:

```text
https://dominio-web.com/orcamento/123
```

Nesse exemplo:

```text
123 = número do endereço
```

O número do endereço é o identificador utilizado para localizar o orçamento.

## Importante

O telefone **NÃO deve ser utilizado para localizar o orçamento**.

O telefone será utilizado somente como uma camada adicional de segurança.

---

# 3. Token provisório do Firebase

Além do número do endereço, a URL deverá conter um **token provisório do Firebase**.

Exemplo conceitual:

```text
https://dominio-web.com/orcamento/123?token=ABC123
```

O formato exato deverá respeitar a arquitetura definida pelo projeto.

## Regras do token

O token deve:

- Ser gerado para o acesso ao orçamento.
- Ser provisório/temporário.
- Ser específico para o fluxo Web do orçamento.
- Ser validado antes da exibição dos dados.
- Ser utilizado como camada adicional de segurança.
- Não substituir a validação do telefone.
- Não ser tratado como dado de negócio.
- Não modificar regras de negócio existentes.

Caso o projeto já possua implementação de:

- Firebase.
- Authentication.
- Tokens.
- Guards.
- Middleware.
- Validação de acesso.
- Sessões.
- Segurança.

deve-se **reutilizar a implementação existente**.

Não criar uma segunda arquitetura de autenticação se já houver uma solução equivalente.

---

# 4. Fluxo de segurança

O fluxo completo deve ser:

```text
Cliente recebe o link
        ↓
URL contém:
    ├── Número do endereço
    └── Token Firebase
        ↓
Extrair número do endereço
        ↓
Localizar orçamento
        ↓
Validar token Firebase
        ↓
Token válido?
   ┌────┴────┐
  NÃO       SIM
   ↓          ↓
Bloqueia    Solicita telefone
               ↓
        Telefone obrigatório
               ↓
        Validar telefone
               ↓
       Telefone válido?
          ┌────┴────┐
         NÃO       SIM
          ↓          ↓
       Bloqueia   Exibe orçamento
```

O orçamento somente poderá ser exibido quando:

```text
Token válido
+
Telefone válido
=
Acesso liberado
```

## Regras importantes

### Token válido + telefone inválido

Não permitir acesso.

### Token inválido + telefone válido

Não permitir acesso.

### Token inválido + telefone inválido

Não permitir acesso.

### Token válido + telefone válido

Permitir acesso ao orçamento.

---

# 5. Tela inicial Web

Ao acessar a URL, o cliente deverá informar o número de telefone.

O telefone deve ser **obrigatório**.

A tela deve seguir os padrões visuais já existentes no projeto.

Não criar um padrão visual completamente novo se houver componentes equivalentes no projeto.

Após informar o telefone:

1. Utilizar o número do endereço da URL para localizar o orçamento.
2. Validar o token Firebase.
3. Validar o telefone informado.
4. Liberar o acesso somente após todas as validações.
5. Em caso de erro, utilizar o padrão de tratamento de erros existente no projeto.

---

# 6. Dados do cliente

Após a autenticação/validação, exibir os dados do cliente.

A seção/tab deve se chamar exatamente:

```text
Meus dados
```

Os dados devem ser:

**Somente leitura.**

O cliente não poderá editar:

- Nome.
- Telefone.
- Endereço.
- Dados cadastrais.
- Qualquer outro dado apresentado nessa seção.

Utilizar as mesmas:

- Labels.
- Nomenclaturas.
- Componentes.
- Tipografia.
- Espaçamentos.
- Formatação.

já utilizadas pelo projeto.

---

# 7. Itens do orçamento

Exibir a lista completa de itens do orçamento.

Utilizar a estrutura existente do projeto sempre que possível.

Devem ser mantidas as informações e labels já utilizadas no aplicativo.

A versão Web deve permitir somente a visualização dos itens.

O cliente não deverá adicionar novos itens através do Web.

---

# 8. Alteração do botão

No fluxo Web, o botão:

```text
Inserir mais itens
```

deve ser substituído por:

```text
Aprovar orçamento
```

Essa alteração é **exclusiva da versão Web**.

O aplicativo mobile não deve ser alterado.

No mobile, o botão existente deve continuar funcionando exatamente como antes.

---

# 9. Aprovação do orçamento

Ao clicar em:

```text
Aprovar orçamento
```

deve ser aberto um modal.

O modal deve seguir o padrão visual já existente no projeto.

Não criar um novo padrão de modal caso exista um componente reutilizável.

O modal deve permitir as opções:

```text
Aprovado
Reprovado
```

A ação selecionada deve utilizar as regras de negócio existentes para alteração do status do orçamento.

Não criar uma regra de aprovação paralela.

---

# 10. Status do orçamento

Antes de implementar a aprovação:

1. Localizar como o projeto atualmente representa o status do orçamento.
2. Localizar como o status é alterado.
3. Localizar qual API/service/repository executa essa alteração.
4. Reutilizar essa implementação.

Não duplicar:

```text
Status
Repository
Service
API
Use Case
```

sem necessidade.

Caso já exista um fluxo de aprovação, o Web deverá consumi-lo.

---

# 11. PDF

O orçamento também deverá possuir a funcionalidade de PDF.

O cliente deverá conseguir:

1. Gerar o PDF.
2. Processar o PDF no navegador.
3. Baixar o PDF.

Sempre reutilizar a implementação existente.

Se a geração atual do PDF for exclusiva para mobile, adaptar somente o necessário para suportar Web.

Não modificar a regra de negócio que determina os dados do PDF.

A versão Web deve apresentar o mesmo conteúdo do orçamento utilizado na versão atual.

---

# 12. Arquitetura ViewModel

A implementação deve seguir integralmente:

```text
@.pi/sdd_arquitetura_view_model.md
```

Respeitar os padrões existentes de:

- View.
- ViewModel.
- State.
- Repository.
- Service.
- Entity.
- Model.
- Dependency Injection.
- Navigation.
- Result.
- Error handling.

Antes de criar novos arquivos ou classes, procurar estruturas equivalentes no projeto.

Não criar uma arquitetura alternativa apenas para o Web.

---

# 13. Arquitetura Web

A implementação deve seguir integralmente:

```text
@.pi/web_projet_instruction/create_flutter_web_page.md
```

O fluxo Web deve possuir o entry point e estrutura recomendados pelo documento.

A aplicação Web deve ser capaz de disponibilizar **somente o fluxo de orçamento**, sem expor as demais telas do aplicativo.

Conceitualmente:

```text
Mobile
main.dart
    ↓
Aplicativo completo


Web
main_web.dart
    ↓
Fluxo de orçamento
    ↓
Tela de autenticação
    ↓
Orçamento
```

---

# 14. Reutilização obrigatória

Antes de implementar qualquer código novo, procurar no projeto por:

### Orçamento

- Tela de orçamento.
- Tab de orçamento.
- ViewModel.
- Entity.
- Model.
- Repository.
- Service.

### Cliente

- Dados do cliente.
- Labels.
- Componentes.
- Validators.

### Itens

- Lista de itens.
- Componentes de item.
- Quantidade.
- Valores.

### Aprovação

- Status.
- Aprovação.
- Reprovação.
- Modal.
- API.

### PDF

- Geração.
- Download.
- Services.
- Helpers.
- Packages.

### Segurança

- Firebase.
- Authentication.
- Token.
- Guards.
- Middleware.
- Validação.

Sempre reutilizar o que já existe.

---

# 15. Responsividade

A Web deve ser responsiva.

Considerar:

- Desktop.
- Tablet.
- Celular através do navegador.

A implementação deve utilizar os padrões responsivos existentes no projeto.

Não assumir que a resolução do navegador será igual à resolução do aplicativo mobile.

---

# 16. Segurança

A URL possui três informações importantes no fluxo:

```text
Número do endereço
        +
Token Firebase provisório
        +
Telefone
```

Cada um possui uma responsabilidade diferente.

### Número do endereço

Responsável por localizar o orçamento.

### Token Firebase

Responsável por validar o acesso ao link.

### Telefone

Responsável por uma segunda camada de validação do cliente.

Não utilizar um desses mecanismos para substituir outro.

O acesso somente deve ser permitido após:

```text
Número do endereço válido
+
Token válido
+
Telefone válido
```

---

# 17. Não expor dados antes da validação

Nenhum dado sensível ou informação do orçamento deve ser exibido antes da conclusão das validações.

Antes de validar:

- Não exibir nome do cliente.
- Não exibir telefone.
- Não exibir endereço completo.
- Não exibir itens.
- Não exibir valores.
- Não exibir PDF.
- Não exibir dados do orçamento.

A tela inicial deve solicitar a validação necessária.

---

# 18. Não alterar o aplicativo mobile

A implementação Web não deve causar mudanças de comportamento no aplicativo.

Após a implementação:

```text
Android
→ deve continuar funcionando como antes.

iOS
→ deve continuar funcionando como antes.

Web
→ deve possuir o novo fluxo de orçamento.
```

Se uma alteração compartilhada for realmente necessária, avaliar primeiro se é possível criar uma implementação específica para Web.

Não modificar código compartilhado sem necessidade.

---

# 19. Processo obrigatório antes de codificar

Antes de escrever código:

## Passo 1

Leia completamente:

```text
@.pi/sdd_arquitetura_view_model.md
```

## Passo 2

Leia completamente:

```text
@.pi/web_projet_instruction/create_flutter_web_page.md
```

## Passo 3

Analise a estrutura atual do projeto.

## Passo 4

Localize a implementação atual do orçamento.

## Passo 5

Localize:

- View.
- ViewModel.
- State.
- Repository.
- Service.
- API.
- Entity.
- Model.

## Passo 6

Localize a implementação atual de:

- Aprovação.
- Reprovação.
- Status.
- Modal.
- PDF.
- Firebase.
- Authentication.
- Token.

## Passo 7

Identifique quais componentes podem ser reutilizados.

## Passo 8

Defina a arquitetura da solução.

## Passo 9

Apresente um plano curto da implementação.

## Passo 10

Somente depois implemente.

---

# 20. Não fazer

Não:

- Refatorar o projeto inteiro.
- Alterar arquitetura existente sem necessidade.
- Criar novas regras de negócio.
- Duplicar regras de negócio.
- Duplicar repositories sem necessidade.
- Duplicar services sem necessidade.
- Duplicar APIs sem necessidade.
- Alterar comportamento mobile.
- Alterar cálculo de orçamento.
- Alterar cálculo de preços.
- Alterar itens.
- Alterar descontos.
- Alterar dados do cliente.
- Criar novo sistema de aprovação se já existir.
- Criar novo sistema de PDF se já existir.
- Criar novo sistema de autenticação se já existir.
- Usar telefone como identificador do orçamento.
- Liberar orçamento apenas com telefone.
- Liberar orçamento apenas com token.
- Exibir dados antes da validação.
- Expor as demais telas mobile através do Web.

---

# 21. Critérios de aceite

A implementação somente será considerada concluída quando todos os itens abaixo forem atendidos.

## Web

- [ ] Existe um fluxo Web específico para orçamento.
- [ ] O Web possui entry point/estrutura conforme `create_flutter_web_page.md`.
- [ ] Somente o fluxo Web necessário é publicado.
- [ ] As demais telas do aplicativo não ficam expostas no Web.
- [ ] O layout é responsivo.

## URL

- [ ] A URL possui o número do endereço.
- [ ] O número do endereço é utilizado para localizar o orçamento.
- [ ] A URL possui um token provisório do Firebase.
- [ ] O token é validado antes da exibição do orçamento.
- [ ] Token inválido impede o acesso.
- [ ] Token expirado/provisório inválido impede o acesso.
- [ ] O telefone não é utilizado para localizar o orçamento.

## Segurança

- [ ] O telefone é obrigatório.
- [ ] O telefone é utilizado como segunda camada de segurança.
- [ ] Telefone inválido impede o acesso.
- [ ] Token válido sozinho não libera acesso.
- [ ] Telefone válido sozinho não libera acesso através da URL.
- [ ] Número do endereço + token + telefone são necessários para liberar o orçamento.
- [ ] Nenhum dado do orçamento é exibido antes da validação.

## Dados do cliente

- [ ] Existe a aba/seção `Meus dados`.
- [ ] Os dados são somente leitura.
- [ ] Não é possível editar os dados.
- [ ] As labels seguem o padrão existente do projeto.

## Itens

- [ ] Todos os itens do orçamento são exibidos.
- [ ] As informações seguem o padrão existente.
- [ ] `Inserir mais itens` não aparece no Web.
- [ ] O botão `Aprovar orçamento` aparece no Web.

## Aprovação

- [ ] `Aprovar orçamento` abre um modal.
- [ ] O modal segue o padrão existente do projeto.
- [ ] Existe a opção `Aprovado`.
- [ ] Existe a opção `Reprovado`.
- [ ] O status utiliza a regra de negócio existente.
- [ ] Não existe uma regra paralela de aprovação.

## PDF

- [ ] O PDF pode ser gerado no Web.
- [ ] O PDF pode ser baixado pelo navegador.
- [ ] O conteúdo segue o orçamento existente.
- [ ] A regra de negócio do PDF não foi alterada.

## Mobile

- [ ] Android continua funcionando.
- [ ] iOS continua funcionando.
- [ ] Nenhum fluxo mobile existente foi alterado.
- [ ] Nenhuma regra de negócio existente foi modificada.

## Arquitetura

- [ ] `sdd_arquitetura_view_model.md` foi seguido.
- [ ] `create_flutter_web_page.md` foi seguido.
- [ ] Código existente foi reutilizado quando possível.
- [ ] Não foram criadas abstrações duplicadas sem necessidade.
- [ ] Não foram criadas novas regras de negócio desnecessárias.

---

# 22. Resultado esperado

A solução final deve funcionar conceitualmente desta forma:

```text
                 ORÇAMENTO GERADO
                        │
                        ↓
             Link Web compartilhável
                        │
                        ↓
        https://dominio/orcamento/123
                    ?token=ABC
                        │
                        ↓
             Número do endereço
                        │
                        ↓
             Localiza orçamento
                        │
                        ↓
            Valida token Firebase
                        │
                        ↓
              Solicita telefone
                        │
                        ↓
             Valida telefone
                        │
                        ↓
                Acesso liberado
                        │
          ┌─────────────┴─────────────┐
          │                           │
          ↓                           ↓
      Meus dados                 Orçamento
     Somente leitura              Completo
                                      │
                          ┌───────────┼───────────┐
                          │           │           │
                          ↓           ↓           ↓
                        Itens     Aprovação      PDF
                                      │           │
                                ┌─────┴─────┐     ↓
                                ↓           ↓   Download
                            Aprovado    Reprovado
```

---

# 23. Regra final para a implementação

O objetivo desta tarefa é **criar uma experiência Web para compartilhamento de orçamento**, e não refatorar o aplicativo.

A implementação deve:

1. Seguir as instruções dos dois arquivos de arquitetura fornecidos.
2. Reutilizar a implementação existente.
3. Criar somente o código necessário.
4. Manter o aplicativo mobile intacto.
5. Não alterar regras de negócio.
6. Utilizar o número do endereço para localizar o orçamento.
7. Utilizar o token provisório do Firebase para proteger o link.
8. Exigir obrigatoriamente o telefone como segunda validação.
9. Exibir o orçamento somente após as validações.
10. Permitir aprovação/reprovação.
11. Permitir geração e download do PDF.
12. Manter o padrão visual e arquitetural existente.

**Se houver conflito entre uma implementação sugerida neste documento e uma implementação já existente no projeto, priorize a arquitetura e os padrões existentes do projeto, desde que os requisitos funcionais e de segurança desta especificação sejam preservados.**