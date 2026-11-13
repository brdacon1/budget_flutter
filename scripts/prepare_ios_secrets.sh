#!/usr/bin/env bash
# =============================================================================
# Helper para preparar os secrets do GitHub Actions para build de iOS.
#
# Uso:
#   ./scripts/prepare_ios_secrets.sh \
#       /caminho/certificado.p12 \
#       /caminho/perfil.mobileprovision
#
# O script imprime os valores base64 que devem ser adicionados nos secrets do
# GitHub Actions:
#   - IOS_P12_BASE64
#   - IOS_MOBILEPROVISION_BASE64
#
# Além desses, configure também os seguintes secrets manualmente:
#   - IOS_P12_PASSWORD           (senha do arquivo .p12)
#   - IOS_KEYCHAIN_PASSWORD      (senha temporária do keychain no runner)
#   - IOS_PROVISIONING_PROFILE_NAME (nome exato do provisioning profile)
#   - IOS_TEAM_ID                (Team ID da Apple, ex: D7K399FRXY)
# =============================================================================

set -e

P12_PATH="${1:-}"
PP_PATH="${2:-}"

if [ -z "$P12_PATH" ] || [ -z "$PP_PATH" ]; then
  echo "Uso: $0 <caminho/certificado.p12> <caminho/perfil.mobileprovision>"
  exit 1
fi

if [ ! -f "$P12_PATH" ]; then
  echo "ERRO: arquivo .p12 não encontrado: $P12_PATH"
  exit 1
fi

if [ ! -f "$PP_PATH" ]; then
  echo "ERRO: arquivo .mobileprovision não encontrado: $PP_PATH"
  exit 1
fi

echo ""
echo "============================================================================="
echo "Valores base64 para os secrets do GitHub Actions"
echo "============================================================================="
echo ""

P12_B64=$(base64 -i "$P12_PATH" | tr -d '\n')
PP_B64=$(base64 -i "$PP_PATH" | tr -d '\n')

echo "IOS_P12_BASE64:"
echo "$P12_B64"
echo ""
echo "IOS_MOBILEPROVISION_BASE64:"
echo "$PP_B64"
echo ""
echo "============================================================================="
echo ""
echo "Agora acesse: Settings > Secrets and variables > Actions > Repository secrets"
echo "e adicione/atualize os secrets:"
echo ""
echo "  IOS_P12_BASE64=$P12_B64"
echo "  IOS_MOBILEPROVISION_BASE64=$PP_B64"
echo "  IOS_P12_PASSWORD=<senha do .p12>"
echo "  IOS_KEYCHAIN_PASSWORD=<qualquer senha forte>"
echo "  IOS_PROVISIONING_PROFILE_NAME=<nome exato do provisioning profile>"
echo "  IOS_TEAM_ID=<Team ID da Apple>"
echo ""
