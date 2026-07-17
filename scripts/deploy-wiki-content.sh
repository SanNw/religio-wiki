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

echo "== 1/4: LocalSettings.php =="
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

# Checagens separadas: mesmo quando o bloco principal já tinha sido colado
# antes (versões anteriores do snippet, sem alguma dessas configs), garante
# que cada uma entra de qualquer forma — é o que faz o common.css/common.js
# baterem com o DOM real da página.
if grep -q "wgVectorDefaultSkinVersion" LocalSettings.php; then
  echo "  padrão de skin (Vector clássico) já presente, pulando."
else
  {
    echo ""
    echo "// Religio Wiki — força Vector clássico (ver LocalSettings-snippet.php)"
    echo "\$wgDefaultSkin = 'vector';"
    echo "\$wgVectorDefaultSkinVersion = '1';"
    echo "\$wgVectorDefaultSkinVersionForNewAccounts = '1';"
    echo "\$wgVectorDefaultSkinVersionForExistingAccounts = '1';"
  } >> LocalSettings.php
  echo "  padrão de skin (Vector clássico) adicionado ao LocalSettings.php."
fi

if grep -q "wgSkipSkins" LocalSettings.php; then
  echo "  bloqueio dos outros skins já presente, pulando."
else
  {
    echo ""
    echo "// Religio Wiki — remove os outros skins da lista (ver LocalSettings-snippet.php)"
    echo "\$wgSkipSkins = [ 'vector-2022', 'monobook', 'minerva', 'timeless' ];"
  } >> LocalSettings.php
  echo "  bloqueio dos outros skins adicionado ao LocalSettings.php."
fi

# Corrige um deploy anterior que adicionou $wgHiddenPrefs — esse global foi
# removido do MediaWiki core há algumas versões e derruba o site com um
# "DomainException" na inicialização em instalações recentes (1.4x).
if grep -qF "wgHiddenPrefs[] = 'skin';" LocalSettings.php; then
  echo "  removendo \$wgHiddenPrefs['skin'] (causava DomainException/site fora do ar)..."
  grep -vF "wgHiddenPrefs[] = 'skin';" LocalSettings.php > LocalSettings.php.tmp
  mv LocalSettings.php.tmp LocalSettings.php
fi

# PluggableAuth_EnableLocalLogin tem padrão "false" na própria extensão --
# se o login social (PluggableAuth) estiver configurado sem essa linha,
# ninguém consegue mais logar com usuário/senha, nem o Admin (toda
# tentativa falha com "As credenciais fornecidas não puderam ser
# autenticadas", mesmo com a senha certa -- não é bug de senha). Descoberto
# ao validar a extensão ReligiowikiCustomizer e não conseguir logar como
# Admin depois do login social já estar configurado.
if grep -qF "wfLoadExtension( 'PluggableAuth' )" LocalSettings.php && ! grep -q "wgPluggableAuth_EnableLocalLogin" LocalSettings.php; then
  {
    echo ""
    echo "// Religio Wiki — reativa login local (ver LocalSettings-snippet.php)"
    echo "\$wgPluggableAuth_EnableLocalLogin = true;"
  } >> LocalSettings.php
  echo "  login local reativado (PluggableAuth_EnableLocalLogin) no LocalSettings.php."
fi

# WikiSEO (nativa, instalada junto com as outras 17 extensões) e a
# ReligiowikiCustomizer (Fase 6) geravam meta tags de SEO ao mesmo tempo,
# sem coordenação -- og:title/twitter:card/JSON-LD apareciam duplicados e
# às vezes conflitantes (ex.: home com schema WebSite E Article ao mesmo
# tempo). A ReligiowikiCustomizer cobre isso de forma mais integrada ao
# projeto ({{#rwseo:}}, breadcrumbs, sitemap), então desativa os geradores
# nativos em vez de manter os dois sistemas ativos. Script sed escrito num
# arquivo à parte (em vez de inline) pra não brigar com o escape de "$" do
# bash dentro de aspas duplas.
if grep -q "^wfLoadExtension( 'WikiSEO' );" LocalSettings.php; then
  cat > /tmp/disable_wikiseo.sed << 'SEDEOF'
s/^wfLoadExtension( 'WikiSEO' );/\/\/ Desativado -- ReligiowikiCustomizer (Fase 6) ja cobre SEO, evita meta tags duplicadas.\n\/\/ wfLoadExtension( 'WikiSEO' );/
s/^\$wgMetadataGenerators = \[.*\];/\/\/ $wgMetadataGenerators = [ 'OpenGraph', 'Twitter', 'SchemaOrg' ];/
SEDEOF
  sed -i -f /tmp/disable_wikiseo.sed LocalSettings.php
  rm -f /tmp/disable_wikiseo.sed
  echo "  WikiSEO desativada (geradores redundantes com a Fase 6 da ReligiowikiCustomizer)."
fi

echo "== 2/4: subindo/reiniciando o container =="
$COMPOSE up -d
$COMPOSE restart "$SERVICE"

# Cria/atualiza a tabela do ReligiowikiCustomizer (e qualquer outra pendência
# de schema de extensão) — seguro rodar sempre, update.php é idempotente.
$COMPOSE exec -T "$SERVICE" php maintenance/update.php --quiet --skip-external-dependencies

edit_page() {
  local title="$1" file="$2"
  echo "  -> ${title}"
  $COMPOSE exec -T "$SERVICE" php maintenance/edit.php \
    --user="$ADMIN_USER" \
    --summary="Aplica conteúdo do projeto (script deploy-wiki-content.sh)" \
    --bot \
    "$title" < "$file"
}

echo "== 3/4: aplicando páginas =="
edit_page "MediaWiki:Common.css" mediawiki-config/common.css
edit_page "MediaWiki:Common.js" mediawiki-config/common.js

while IFS=$'\t' read -r file title; do
  [ -z "$file" ] && continue
  edit_page "$title" "mediawiki-config/pages/$file"
done < mediawiki-config/pages/manifest.tsv

echo "== 4/4: resetando skin fixado em contas já existentes =="
# $wgDefaultSkin/$wgVectorDefaultSkinVersion só valem pra quem NUNCA salvou uma
# preferência própria de aparência. Contas criadas antes dessa configuração
# (ex.: o Admin do install.php) já têm "Vector (2022)" gravado como escolha
# pessoal em user_properties, e isso sempre vence sobre o padrão do site —
# por isso o wiki continua "sem a identidade" mesmo logado como Admin. Limpa
# essa preferência pra todo mundo, fazendo cair de volta no padrão (Vector
# clássico). Não apaga conta, senha nem nenhum outro dado — só essa escolha.
$COMPOSE exec -T "$SERVICE" php maintenance/sql.php --query \
  "DELETE FROM user_properties WHERE up_property = 'skin';"

echo
echo "Pronto. Dê um Ctrl+F5 (hard refresh) no navegador — o MediaWiki cacheia"
echo "Common.css/Common.js agressivamente via ResourceLoader."
echo
echo "Se ainda aparecer 'Vector (2022)' marcado em Preferências → Aparência pra"
echo "alguma conta, é porque ela mudou isso de novo manualmente depois deste"
echo "script rodar — é só marcar 'Vector legado (2010)' e Salvar ali mesmo."
echo
echo "Confira também 'Gerenciar editores' (Special:UserRights) para colocar seu"
echo "usuário no grupo 'editor' caso a aba 'Editar' ainda não apareça."
