# Flutter Web — Publicação de Tela Específica

## Objetivo

Permitir que um projeto Flutter existente, originalmente desenvolvido para Android/iOS, disponibilize **uma tela específica via Flutter Web**, sem precisar expor o restante do aplicativo.

Exemplo:

```text
Projeto Flutter
│
├── Android
│   └── Aplicativo completo
│
├── iOS
│   └── Aplicativo completo
│
└── Web
    └── Formulário público
```

A tela Web pode ser acessada por um domínio como:

```text
https://formulario.minhaempresa.com.br
```

ou por uma rota:

```text
https://app.minhaempresa.com.br/formulario
```

---

## Objetivo arquitetural

A solução deve priorizar **reutilização de código**.

O formulário Web deve poder reutilizar:

- Models
- Entities
- DTOs
- Repositories
- Services
- API clients
- Use cases
- Validators
- Regras de negócio
- Tratamento de erros

Não duplicar regras de negócio apenas para criar a versão Web.

Arquitetura recomendada:

```text
                    ┌─────────────────┐
                    │    Backend/API  │
                    └────────┬────────┘
                             │
              ┌──────────────┴──────────────┐
              │                             │
       Flutter Mobile                  Flutter Web
       Android / iOS                   Formulário
              │                             │
       App completo                   Tela pública
```

---

# Estrutura recomendada

Para projetos maiores, separar o entry point do aplicativo mobile do entry point Web.

```text
lib/
├── main.dart
├── main_web.dart
│
├── app/
│   ├── app.dart
│   └── routes.dart
│
├── core/
│   ├── network/
│   ├── errors/
│   └── utils/
│
├── features/
│   └── formulario/
│       ├── data/
│       ├── domain/
│       └── presentation/
│           └── formulario_page.dart
│
└── shared/
    ├── models/
    ├── services/
    └── validators/
```

---

# Entry point Mobile

O `main.dart` continua sendo responsável pelo aplicativo completo:

```dart
void main() {
  runApp(const App());
}
```

O aplicativo mobile pode manter todas as suas rotas normalmente.

---

# Entry point Web

Criar um entry point específico:

```dart
import 'package:flutter/material.dart';

import 'features/formulario/presentation/formulario_page.dart';

void main() {
  runApp(
    MaterialApp(
      debugShowCheckedModeBanner: false,
      home: const FormularioPage(),
    ),
  );
}
```

Esse entry point deve carregar somente a experiência Web necessária.

---

# Quando utilizar uma rota Web

Se o projeto precisar manter várias páginas Web, utilizar roteamento:

```dart
MaterialApp(
  initialRoute: '/formulario',
  routes: {
    '/formulario': (_) => const FormularioPage(),
  },
);
```

Nesse cenário, a URL pode ser:

```text
https://app.minhaempresa.com.br/formulario
```

---

# Quando utilizar um entry point separado

Preferir `main_web.dart` quando:

- Apenas uma tela será publicada;
- O Web possui uma finalidade diferente do aplicativo;
- Não existe necessidade de disponibilizar o restante do aplicativo;
- O formulário deve possuir uma experiência independente;
- Deseja-se reduzir o acoplamento com a navegação mobile.

Exemplo:

```text
Mobile
main.dart
    ↓
App completo

Web
main_web.dart
    ↓
FormularioPage
```

---

# Reutilização de código

A tela Web não deve duplicar chamadas de API ou regras de negócio.

Exemplo:

```dart
class FormularioPage extends StatefulWidget {
  const FormularioPage({super.key});

  @override
  State<FormularioPage> createState() => _FormularioPageState();
}
```

O formulário pode utilizar o mesmo repository:

```dart
final repository = FormularioRepository();
```

E o mesmo service:

```dart
final service = FormularioService();
```

Dessa forma:

```text
Flutter Mobile ──┐
                 ├── Repository ── API
Flutter Web ─────┘
```

---

# Domínio

O Flutter Web pode ser publicado em um domínio próprio.

Exemplo:

```text
https://formulario.minhaempresa.com.br
```

Ou como uma rota:

```text
https://app.minhaempresa.com.br/formulario
```

O domínio/subdomínio deve apontar para a infraestrutura onde o Flutter Web está hospedado.

---

# Build

O projeto pode continuar utilizando Flutter Web normalmente:

```bash
flutter build web
```

Se houver um entry point específico, utilizar o entry point correspondente conforme a estratégia de build adotada pelo projeto.

O resultado final será uma aplicação Web estática que pode ser hospedada em serviços como:

- Firebase Hosting
- Vercel
- Netlify
- AWS
- Google Cloud
- Azure
- Nginx
- CDN
- Servidor próprio

---

# Cuidados importantes

## 1. Não publicar o aplicativo inteiro desnecessariamente

Se a necessidade é apenas um formulário público, evitar disponibilizar navegação para as demais funcionalidades do aplicativo.

## 2. Segurança

Nunca considerar o fato de uma funcionalidade estar escondida no Flutter Web como mecanismo de segurança.

A API deve validar:

- Autenticação
- Autorização
- Permissões
- Dados recebidos
- Rate limiting
- Regras de negócio

O código Flutter Web é executado no navegador e pode ser inspecionado.

## 3. Responsividade

A tela Web deve ser responsiva para:

- Desktop
- Tablet
- Mobile browser

Não assumir que o usuário acessará pelo mesmo tamanho de tela do aplicativo.

## 4. SEO

Se o formulário precisar de SEO, considerar que Flutter Web não possui a mesma abordagem de uma aplicação HTML tradicional.

Para formulários privados ou acessados diretamente por URL, isso normalmente não é um problema.

## 5. Deep linking

Caso seja utilizada uma rota como:

```text
/formulario
```

a infraestrutura de hospedagem deve estar configurada para redirecionar as URLs para o `index.html` do Flutter Web.

Caso contrário, acessar diretamente:

```text
https://app.minhaempresa.com.br/formulario
```

pode retornar `404`.

---

# Recomendação

Para um projeto Flutter mobile existente que precisa disponibilizar **somente um formulário público na Web**, utilizar:

```text
lib/
├── main.dart
├── main_web.dart
│
├── features/
│   └── formulario/
│       ├── data/
│       ├── domain/
│       └── presentation/
│           └── formulario_page.dart
│
└── shared/
    ├── services/
    ├── repositories/
    ├── models/
    └── validators/
```

O `main.dart` continua sendo o aplicativo Android/iOS.

O `main_web.dart` inicia somente o formulário.

As regras de negócio e integrações devem permanecer compartilhadas.

---

# Resultado esperado

```text
                    PROJETO FLUTTER
                          │
              ┌───────────┴───────────┐
              │                       │
          MOBILE                      WEB
              │                       │
        main.dart                main_web.dart
              │                       │
        App completo             FormularioPage
              │                       │
        Android / iOS             Browser
                                      │
                                      ↓
                         formulario.empresa.com.br
```

Essa abordagem permite utilizar **um único projeto Flutter**, compartilhando a camada de negócio, enquanto a Web oferece uma experiência específica e independente do aplicativo mobile.