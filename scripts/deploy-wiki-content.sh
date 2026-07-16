#!/usr/bin/env bash
# Aplica TODO o conteúdo de mediawiki-config/ dentro de um wiki já instalado —
# MediaWiki:Common.css, MediaWiki:Common.js, templates, categorias, página
# principal, página de doação, idiomas e sidebar — sem copiar/colar manual.
#
# Rode a partir da raiz do repositório clonado na VPS, com os containers no
# ar (docker compose up -d já executado pelo menos uma vez).
#
# Uso: ./scripts/deploy-wiki-content.sh [usuário-admin]

set -euo pipefail
cd "$(dirname "$0")/.."

ADMIN_USER="${1:-Admin}"
COMPOSE="docker compose"
SERVICE="mediawiki"

echo "== 1/3: LocalSettings.php =="
if [ ! -f LocalSettings.php ]; then
  echo "ERRO: LocalSettings.php não encontrado nesta pasta. Rode o instalador primeiro (ver README)." >&2
  exit 1
fi

MARKER="Religio Wiki — trechos para colar"
if grep -q "$MARKER" LocalSettings.php; then
  echo "  bloco principal já aplicado, pulando."
else
  echo "" >> LocalSettings.php
  cat mediawiki-config/LocalSettings-snippet.php >> LocalSettings.php
  echo "  bloco principal adicionado ao final do LocalSettings.php."
fi

# Checagem separada: mesmo quando o bloco principal já tinha sido colado antes
# (versão anterior do snippet, sem a config de skin), garante que a linha do
# Vector clássico entra de qualquer forma — é o que faz o common.css/common.js
# baterem com o DOM real da página.
SKIN_MARKER="wgVectorDefaultSkinVersion"
if grep -q "$SKIN_MARKER" LocalSettings.php; then
  echo "  config de skin (Vector clássico) já presente, pulando."
else
  {
    echo ""
    echo "// Religio Wiki — força Vector clássico (ver LocalSettings-snippet.php)"
    echo "\$wgDefaultSkin = 'vector';"
    echo "\$wgVectorDefaultSkinVersion = '1';"
    echo "\$wgVectorDefaultSkinVersionForNewAccounts = '1';"
    echo "\$wgVectorDefaultSkinVersionForExistingAccounts = '1';"
  } >> LocalSettings.php
  echo "  config de skin (Vector clássico) adicionada ao LocalSettings.php."
fi

echo "== 2/3: subindo/reiniciando o container =="
$COMPOSE up -d
$COMPOSE restart "$SERVICE"

edit_page() {
  local title="$1" file="$2"
  echo "  -> ${title}"
  $COMPOSE exec -T "$SERVICE" php maintenance/edit.php \
    --user="$ADMIN_USER" \
    --summary="Aplica conteúdo do projeto (script deploy-wiki-content.sh)" \
    --bot \
    "$title" < "$file"
}

echo "== 3/3: aplicando páginas =="
edit_page "MediaWiki:Common.css" mediawiki-config/common.css
edit_page "MediaWiki:Common.js" mediawiki-config/common.js

while IFS=$'\t' read -r file title; do
  [ -z "$file" ] && continue
  edit_page "$title" "mediawiki-config/pages/$file"
done < mediawiki-config/pages/manifest.tsv

echo
echo "Pronto. Dê um Ctrl+F5 (hard refresh) no navegador — o MediaWiki cacheia"
echo "Common.css/Common.js agressivamente via ResourceLoader."
echo
echo "Confira também 'Gerenciar editores' (Special:UserRights) para colocar seu"
echo "usuário no grupo 'editor' caso a aba 'Editar' ainda não apareça."
