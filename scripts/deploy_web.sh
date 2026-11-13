#!/usr/bin/env bash
set -euo pipefail

# Deploy web OfLite com entry point correto e também deploy das functions.
# Uso: ./scripts/deploy_web.sh

PROJECT_ROOT="$(cd "$(dirname "$0")/.." && pwd)"
cd "$PROJECT_ROOT"

# Garante que estamos usando a versão do Flutter gerenciada pelo FVM.
FLUTTER="./.fvm/flutter_sdk/bin/flutter"
if [ ! -x "$FLUTTER" ]; then
  echo "Erro: Flutter do FVM não encontrado em $FLUTTER"
  echo "Execute: fvm use stable"
  exit 1
fi

echo "==> Limpando builds antigos..."
"$FLUTTER" clean

echo "==> Build web (main_web.dart) com WASM + fallback JS..."
"$FLUTTER" build web --target lib/main_web.dart --wasm --release

echo "==> Deploy hosting + functions..."
firebase deploy --only hosting,functions

echo "==> Deploy concluído."
echo ""
echo "Importante:"
echo "  1. Acesse o site em uma aba anônima primeiro para validar."
echo "  2. Se ainda vir tela branca, force atualização com Ctrl+Shift+R (Windows/Linux) ou Cmd+Shift+R (Mac)."
echo "  3. Para exclusão de conta, a URL é /delete-account e a Cloud Function deleteAccount deve estar deployada."
