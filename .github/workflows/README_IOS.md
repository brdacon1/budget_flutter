# Build iOS via GitHub Actions

Este documento explica como o workflow `.github/workflows/ios_build.yml` gera o arquivo `.ipa` do app Flutter na nuvem (macOS runner do GitHub Actions).

---

## O que foi configurado

- Runner: `macos-latest` (obrigatório para builds iOS)
- Flutter stable com cache
- Xcode 15.0.1
- Keychain temporário no runner
- Importação do certificado `.p12` e provisioning profile `.mobileprovision`
- Geração do `ExportOptions.plist` em tempo de execução
- Build: `flutter build ipa --release --export-options-plist=ios/ExportOptions.plist`
- Upload do `.ipa` como artefato do GitHub Actions

---

## Secrets necessários

Acesse no repositório: **Settings > Secrets and variables > Actions > Repository secrets**

| Secret | Descrição |
|--------|-----------|
| `IOS_P12_BASE64` | Certificado de distribuição iPhone/iOS `.p12` codificado em base64 |
| `IOS_P12_PASSWORD` | Senha do arquivo `.p12` |
| `IOS_MOBILEPROVISION_BASE64` | Provisioning profile `.mobileprovision` codificado em base64 |
| `IOS_KEYCHAIN_PASSWORD` | Senha temporária para o keychain no runner (qualquer valor forte) |
| `IOS_PROVISIONING_PROFILE_NAME` | Nome exato do provisioning profile (como aparece no Apple Developer) |
| `IOS_TEAM_ID` | Team ID da Apple (ex: `D7K399FRXY`) |
| `GOOGLE_SERVICE_INFO_PLIST_BASE64` | `ios/Runner/GoogleService-Info.plist` codificado em base64 |

### Gerando os valores base64 localmente

Use o script helper para certificado e provisioning profile:

```bash
chmod +x scripts/prepare_ios_secrets.sh
./scripts/prepare_ios_secrets.sh \
  /caminho/para/Distribution.p12 \
  /caminho/para/oflite.mobileprovision
```

Para o `GoogleService-Info.plist`:

```bash
base64 -i ios/Runner/GoogleService-Info.plist | tr -d '\n' | pbcopy
```

---

## Provisioning profile e certificado

Os certificados da Apple exigem:

1. **Apple Developer Program ativa** (US$ 99/ano) — necessário para distribuir `.ipa` via App Store/TestFlight.
2. **Certificado de Distribuição iOS** (`iOS Distribution`) exportado como `.p12`.
3. **Provisioning profile** do tipo:
   - **App Store**: para TestFlight / App Store (`method: app-store`)
   - **Ad Hoc**: para instalação em dispositivos registrados (`method: ad-hoc`)

### Descobrindo o nome do provisioning profile

Abra o arquivo `.mobileprovision` em um editor de texto. A primeira linha é XML. Procure por:

```xml
<key>Name</key>
<string>SEU PROVISIONING PROFILE NAME</string>
```

O valor do `<string>` deve ser usado no secret `IOS_PROVISIONING_PROFILE_NAME`.

---

## Disparo do workflow

O workflow roda automaticamente em pushes na branch `main`.

Também pode ser disparado manualmente via **Actions > Build iOS Release (IPA) > Run workflow**, com opção de escolher o método de exportação:

- `app-store` (padrão)
- `ad-hoc`
- `development`
- `enterprise`

---

## Onde baixar o IPA

Após o workflow completar com sucesso:

1. Acesse a execução do workflow no GitHub.
2. Role até a seção **Artifacts**.
3. Baixe o artefato `ios-release-ipa`.

---

## Próximos passos sugeridos

- **TestFlight/App Store**: adicione um passo com `fastlane pilot` ou `altool` (Xcode CLI) para upload automático do `.ipa`.
- **Tag-based release**: altere o trigger para `on: push: tags: ['v*']` e crie Releases automáticos com o `.ipa` anexado.
- **Cache do CocoaPods**: adicione cache de `ios/Pods` para acelerar builds subsequentes.

---

## Solução de problemas

### `errSecInternalComponent` ou falha ao importar o `.p12`

- Verifique se `IOS_P12_PASSWORD` está correta.
- Certifique-se de que o certificado não expirou.
- No macOS local, tente importar o `.p12` no Keychain Access para validar.

### `No profiles for '<bundle_id>' were found`

- O `IOS_PROVISIONING_PROFILE_NAME` deve ser exatamente igual ao nome no arquivo `.mobileprovision`.
- O Bundle ID do provisioning profile (`com.housestudio.oflite`) deve coincidir com o do `Info.plist` / `project.pbxproj`.

### `There are no accounts registered with Xcode`

- Este workflow usa certificados e provisioning profiles manuais em vez de contas Apple vinculadas ao Xcode. Não é necessário fazer login com a Apple ID no runner.
