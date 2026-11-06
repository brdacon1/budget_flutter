# Plano de Implementação — GitHub Actions Android (branch `main`)

> **Contexto**: Workflow já existe em `.github/workflows/github_actions.yml` mas está incompleto.  
> **Objetivo**: Toda vez que houver push na `main`, rodar build Android release (AAB) com keystore via secrets e envs de produção.

---

## 1. Estado Atual (problemas)

O workflow existente tem os seguintes gaps:
- **Não gera `key.properties`** — o arquivo está `.gitignore`d e o `build.gradle` espera ler dele; no CI ele não existe.
- **Não seta `KEYSTORE_PATH`** — o `build.gradle` usa `System.getenv("KEYSTORE_PATH")` como primeira opção; o workflow decodifica o keystore mas não informa o path ao Gradle.
- **Não executa `flutter pub get`** — o build vai falhar faltando dependências.
- **Não usa as envs de produção** — falta `--dart-define-from-file=env/production_environment.json`.
- **`flutter-version: '3.x'`** — genérico demais; sem cache; build lento e não-reprodutível.

---

## 2. Secrets já configuradas (preservar nomes)

| Secret | Uso |
|--------|-----|
| `KEYSTORE_BASE_64` | Keystore codificado em base64 |
| `KEYSTORE_PASSWORD` | Senha do keystore |
| `KEY_ALIAS` | Alias da chave |
| `KEY_PASSWORD` | Senha da chave |

---

## 3. Alterações necessárias

### 3.1. Workflow — `.github/workflows/github_actions.yml`

#### Passos a adicionar/corrigir:

1. **Trigger**: manter `push` em `branches: [main]`
2. **Java**: `zulu`, `17`
3. **Flutter**: pinar versão `3.24.5` (última stable conhecida) + `cache: true`
4. **`flutter pub get`**: antes do build
5. **Decode Keystore**:
   - Criar pasta `android/app/Key`
   - Decodificar `secrets.KEYSTORE_BASE_64` para `android/app/Key/release.keystore`
6. **Gerar `key.properties`**:
   - Criar `android/key.properties` com `storePassword`, `keyPassword`, `keyAlias`, `storeFile`
7. **Build**:
   - `flutter build appbundle --release --dart-define-from-file=env/production_environment.json`
8. **Upload**: manter `upload-artifact@v4` apontando para `build/app/outputs/bundle/release/*.aab`

#### Estrutura do `key.properties` a ser gerado no CI:

```properties
storePassword=<KEYSTORE_PASSWORD>
keyPassword=<KEY_PASSWORD>
keyAlias=<KEY_ALIAS>
storeFile=Key/release.keystore
```

> O `storeFile` usa path relativo a `android/app/` (padrão do Flutter). Alternativamente, podemos usar `KEYSTORE_PATH` via env, mas gerar o `key.properties` é mais idiomático e alinha com o `build.gradle` (que já tenta ler `key.properties`).

### 3.2. Nenhuma alteração no `build.gradle`

O `build.gradle` já está preparado para ler do `key.properties` **ou** das env vars. Gerar o `key.properties` no CI é suficiente — não precisa mexer no código nativo.

---

## 4. Checklist

| # | Arquivo | Ação |
|---|---------|------|
| 1 | `.github/workflows/github_actions.yml` | **Reescrever** com todos os passos corretos |

---

## 5. Regras de Ponytail

- **Mínimo diff**: apenas o arquivo de workflow muda.
- **Não** alterar `build.gradle`, AndroidManifest, ou código Dart.
- **Reaproveitar** secrets existentes com os mesmos nomes.
- **Reproduzível**: pinar versão do Flutter, usar cache.
