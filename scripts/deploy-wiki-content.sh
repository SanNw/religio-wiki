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
# Deploys antigos (antes do skin ReligioWiki existir) tinham essas duas
# linhas forçando Vector clássico — se sobreviveram de uma aplicação
# anterior do snippet, removê-las evita conflito com wfLoadSkin('ReligioWiki').
if grep -qF "wgVectorDefaultSkinVersion" LocalSettings.php; then
  echo "  removendo config antiga do Vector clássico (substituída pelo skin ReligioWiki)..."
  grep -vE "wgDefaultSkin = 'vector'|wgVectorDefaultSkinVersion" LocalSettings.php > LocalSettings.php.tmp
  mv LocalSettings.php.tmp LocalSettings.php
fi

if grep -q "wfLoadSkin( 'ReligioWiki' )" LocalSettings.php; then
  echo "  skin ReligioWiki já registrado, pulando."
else
  {
    echo ""
    echo "// Religio Wiki — skin próprio (ver LocalSettings-snippet.php)"
    echo "wfLoadSkin( 'ReligioWiki' );"
    echo "\$wgDefaultSkin = 'religiowiki';"
  } >> LocalSettings.php
  echo "  skin ReligioWiki registrado no LocalSettings.php."
fi

if grep -q "wgSkipSkins" LocalSettings.php; then
  echo "  bloqueio dos outros skins já presente, pulando."
else
  {
    echo ""
    echo "// Religio Wiki — remove os outros skins da lista (ver LocalSettings-snippet.php)"
    echo "\$wgSkipSkins = [ 'vector', 'vector-2022', 'monobook', 'minerva', 'timeless', 'cologneblue', 'modern' ];"
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

# Link "Personalizar wiki" (Ferramentas -> Special:ReligiowikiCustomizer, só
# admin). Checagem própria porque o bloco principal do snippet só é colado uma
# vez (marcador acima), então instalações onde ele já existia não pegariam
# esse hook novo. Idempotente: só adiciona se o id do link ainda não estiver lá.
if ! grep -q "t-religiowikicustomizer" LocalSettings.php; then
  cat >> LocalSettings.php << 'PHPEOF'

// Religio Wiki — link "Personalizar wiki" na caixa de ferramentas (só admin,
// direito editinterface) -> Special:ReligiowikiCustomizer. Ver LocalSettings-snippet.php.
$wgHooks['SidebarBeforeOutput'][] = static function ( $sk, &$sidebar ) {
	if ( !$sk->getAuthority()->isAllowed( 'editinterface' ) ) {
		return;
	}
	$customizerTitle = SpecialPage::getTitleFor( 'ReligiowikiCustomizer' );
	$sidebar['TOOLBOX']['religiowikicustomizer'] = [
		'text' => 'Personalizar wiki',
		'href' => $customizerTitle->getLocalURL(),
		'id' => 't-religiowikicustomizer',
	];
};
PHPEOF
  echo "  link 'Personalizar wiki' (admin) adicionado ao LocalSettings.php."
fi

# Editor moderno (rw-editor-modern): reativa o VisualEditor e liga o
# DiscussionTools (que exige VisualEditor + Linter). No MediaWiki 1.43 o VE usa
# o Parsoid embutido no core (sem serviço externo), então a aba "Editar" volta
# a funcionar. Bloco idempotente porque o snippet principal só é colado uma vez.
# (Antes havia aqui um bloco que DESATIVAVA o VE — removido, senão re-comentaria
# a linha nova a cada deploy.)
if ! grep -q "rw-editor-modern" LocalSettings.php; then
  cat >> LocalSettings.php << 'PHPEOF'

// Religio Wiki — rw-editor-modern (VisualEditor + DiscussionTools).
// Ver mediawiki-config/LocalSettings-snippet.php.
wfLoadExtension( 'VisualEditor' );
$wgDefaultUserOptions['visualeditor-enable'] = 1;
$wgVisualEditorEnableWikitext = true;
wfLoadExtension( 'Linter' );
wfLoadExtension( 'DiscussionTools' );
PHPEOF
  echo "  VisualEditor + DiscussionTools (editor moderno) ativados no LocalSettings.php."
fi

# Esconde a aba "Editar" do VisualEditor (não usada — a edição fica no
# código-fonte), mantendo o VE só como dependência do DiscussionTools.
# Idempotente pelo marcador rw-hide-ve-tab.
if ! grep -q "rw-hide-ve-tab" LocalSettings.php; then
  cat >> LocalSettings.php << 'PHPEOF'

// Religio Wiki — rw-hide-ve-tab: remove a aba "Editar" do VisualEditor e
// renomeia o botão de código-fonte para "Editar". Ver LocalSettings-snippet.php.
$wgHooks['SkinTemplateNavigation::Universal'][] = static function ( $sktemplate, &$links ) {
	unset( $links['views']['ve-edit'] );
	if ( isset( $links['views']['edit']['text'] ) ) {
		$links['views']['edit']['text'] = 'Editar';
	}
};
PHPEOF
  echo "  aba do VisualEditor escondida (rw-hide-ve-tab)."
fi

# AdvancedSearch: interface de busca com filtros, sobre a busca nativa (sem
# CirrusSearch). Idempotente pelo marcador rw-advancedsearch.
if ! grep -q "rw-advancedsearch" LocalSettings.php; then
  cat >> LocalSettings.php << 'PHPEOF'

// Religio Wiki — rw-advancedsearch: interface de busca com filtros (busca nativa).
wfLoadExtension( 'AdvancedSearch' );
$wgAdvancedSearchDeepcategoryEnabled = false;
PHPEOF
  echo "  AdvancedSearch carregado no LocalSettings.php."
fi

# Desliga o VisualEditor por padrão do usuário (remove a aba "Editar" do VE,
# mantendo o VE só como dependência do DiscussionTools). Idempotente: só troca
# a linha ativa =1 por =0.
if grep -qF "\$wgDefaultUserOptions['visualeditor-enable'] = 1;" LocalSettings.php; then
  sed -i "s|\$wgDefaultUserOptions\['visualeditor-enable'\] = 1;|\$wgDefaultUserOptions['visualeditor-enable'] = 0; // desligado: some com a aba Editar do VE|" LocalSettings.php
  echo "  VisualEditor desligado por padrão (some a aba Editar do VE)."
fi

# Corrige o "sino" de notificações (Echo) no skin próprio: força os estilos/JS
# do badge para quem está logado. Idempotente pelo marcador rw-echo-badge-fix.
if ! grep -q "rw-echo-badge-fix" LocalSettings.php; then
  cat >> LocalSettings.php << 'PHPEOF'

// Religio Wiki — rw-echo-badge-fix: ícone de notificações (Echo) no skin próprio.
$wgHooks['BeforePageDisplay'][] = static function ( $out ) {
	if ( $out->getUser()->isRegistered() ) {
		$out->addModuleStyles( 'ext.echo.styles.badge' );
		$out->addModules( 'ext.echo.init' );
	}
};
PHPEOF
  echo "  ícone de notificações (Echo) corrigido no LocalSettings.php."
fi

# E-mail + confirmação de conta. SMTP lido de variáveis de ambiente (definidas
# no .env da VPS, não no repo). Idempotente pelo marcador rw-email-smtp.
if ! grep -q "rw-email-smtp" LocalSettings.php; then
  cat >> LocalSettings.php << 'PHPEOF'

// Religio Wiki — rw-email-smtp: e-mail e confirmação de conta (SMTP via ambiente).
$wgEnableEmail = true;
$wgEnableUserEmail = true;
$wgEmailAuthentication = true;
$wgAllowHTMLEmail = false;
$rwMailFrom = getenv( 'RW_MAIL_FROM' ) ?: 'no-reply@religiowiki.com';
$wgPasswordSender = $rwMailFrom;
$wgEmergencyContact = $rwMailFrom;
$wgNoReplyAddress = $rwMailFrom;
if ( getenv( 'RW_SMTP_HOST' ) ) {
	$wgSMTP = [
		'host' => getenv( 'RW_SMTP_HOST' ),
		'IDHost' => getenv( 'RW_SMTP_IDHOST' ) ?: 'religiowiki.com',
		'port' => (int)( getenv( 'RW_SMTP_PORT' ) ?: 587 ),
		'auth' => true,
		'username' => (string)getenv( 'RW_SMTP_USER' ),
		'password' => (string)getenv( 'RW_SMTP_PASS' ),
	];
}
PHPEOF
  echo "  e-mail/SMTP (confirmação de conta) configurado no LocalSettings.php."
fi

# CAPTCHA desligado na criação de conta (o pop-up próprio não renderiza a
# pergunta). Idempotente: só troca a linha ativa =true por =false.
if grep -qF "\$wgCaptchaTriggers['createaccount'] = true;" LocalSettings.php; then
  sed -i "s|\$wgCaptchaTriggers\['createaccount'\] = true;|\$wgCaptchaTriggers['createaccount'] = false; // desligado: pop-up de cadastro nao renderiza o captcha|" LocalSettings.php
  echo "  CAPTCHA desligado na criação de conta."
fi

# ULS fora da barra pessoal (posição interlanguage). Idempotente pelo marcador.
if ! grep -q "rw-uls-position" LocalSettings.php; then
  cat >> LocalSettings.php << 'PHPEOF'

// Religio Wiki — rw-uls-position: tira o gatilho de idioma do topo.
$wgULSPosition = 'interlanguage';
PHPEOF
  echo "  ULS movido para fora da barra pessoal."
fi

# Atalho "Imagens enviadas" (Special:ListFiles) na caixa de ferramentas, pra
# quem envia imagem. Idempotente pelo marcador rw-images-link.
if ! grep -q "rw-images-link" LocalSettings.php; then
  cat >> LocalSettings.php << 'PHPEOF'

// Religio Wiki — rw-images-link: atalho "Imagens enviadas" (Special:ListFiles).
$wgHooks['SidebarBeforeOutput'][] = static function ( $sk, &$sidebar ) {
	if ( !$sk->getAuthority()->isAllowed( 'upload' ) ) { return; }
	$sidebar['TOOLBOX']['rw-images'] = [
		'text' => 'Imagens enviadas',
		'href' => SpecialPage::getTitleFor( 'ListFiles' )->getLocalURL(),
		'id' => 't-rw-images',
	];
};
PHPEOF
  echo "  atalho 'Imagens enviadas' adicionado ao LocalSettings.php."
fi

# "Criar artigo" (Ferramentas) aponta pro formulário guiado Religio Wiki:Criar
# artigo (Page Forms). Hook adicional que roda DEPOIS do original (do bloco
# principal) e sobrescreve só o href do item t-createarticle na instalação já
# existente. Idempotente pelo marcador rw-createarticle-form.
if ! grep -q "rw-createarticle-form" LocalSettings.php; then
  cat >> LocalSettings.php << 'PHPEOF'

// Religio Wiki — "Criar artigo" aponta pro formulário guiado (rw-createarticle-form).
$wgHooks['SidebarBeforeOutput'][] = static function ( $sk, &$sidebar ) {
	if ( !$sk->getAuthority()->isAllowed( 'createpage' ) ) { return; }
	$t = Title::newFromText( 'Religio Wiki:Criar artigo' );
	if ( $t && isset( $sidebar['TOOLBOX']['createarticle'] ) ) {
		$sidebar['TOOLBOX']['createarticle']['href'] = $t->getLocalURL();
	}
};
PHPEOF
  echo "  'Criar artigo' (Ferramentas) apontado pro formulário guiado."
fi

# CodeMirror desligado por padrão: ele substitui o textarea nativo e quebra os
# botões de inserção da barra de edição da extensão. Idempotente: só troca a
# linha ativa =1 por =0.
if grep -qF "\$wgDefaultUserOptions['usecodemirror'] = 1;" LocalSettings.php; then
  sed -i "s|\$wgDefaultUserOptions\['usecodemirror'\] = 1;|\$wgDefaultUserOptions['usecodemirror'] = 0; // desligado: quebrava os botoes da barra de edicao|" LocalSettings.php
  echo "  CodeMirror desligado por padrão (usecodemirror=0)."
fi

# Espaço nominal "Rascunho" (artigos não publicados, usados pelo painel
# Special:Artigos da ReligiowikiCustomizer). Checagem própria porque o bloco
# principal do snippet só é colado uma vez (marcador no topo), então
# instalações onde ele já existia não pegariam essas linhas novas.
if ! grep -q "NS_RASCUNHO" LocalSettings.php; then
  cat >> LocalSettings.php << 'PHPEOF'

// Religio Wiki — espaço nominal "Rascunho" (Special:Artigos). Ver LocalSettings-snippet.php.
define( 'NS_RASCUNHO', 3000 );
define( 'NS_RASCUNHO_TALK', 3001 );
$wgExtraNamespaces[NS_RASCUNHO] = 'Rascunho';
$wgExtraNamespaces[NS_RASCUNHO_TALK] = 'Rascunho_Discussão';
$wgNamespacesWithSubpages[NS_RASCUNHO] = true;
$wgNamespacesToBeSearchedDefault[NS_RASCUNHO] = false;
PHPEOF
  echo "  espaço nominal Rascunho adicionado ao LocalSettings.php."
fi

# TemplateWizard: assistente de inserção de predefinições na barra do
# WikiEditor. Idempotente pelo próprio wfLoadExtension.
if ! grep -q "wfLoadExtension( 'TemplateWizard' )" LocalSettings.php; then
  cat >> LocalSettings.php << 'PHPEOF'

// Religio Wiki — TemplateWizard (assistente de predefinições). Ver LocalSettings-snippet.php.
wfLoadExtension( 'TemplateWizard' );
PHPEOF
  echo "  TemplateWizard carregado no LocalSettings.php."
fi

# RECUPERAÇÃO: o lote rw-extensions-batch-2 (carregado de uma vez) derrubou o
# site — uma das 21 extensões falha ao carregar e o MediaWiki entra em loop de
# erro. Remove o bloco quebrado do LocalSettings.php ao vivo (do marcador até o
# fim do arquivo, já que é o último bloco) pra restaurar o site. As extensões
# voltam depois, em sub-lotes verificados, para isolar a culpada. Os arquivos
# das extensões continuam na imagem (inofensivos enquanto não forem carregados).
if grep -q "rw-extensions-batch-2" LocalSettings.php; then
  sed -i '/rw-extensions-batch-2/,$d' LocalSettings.php
  echo "  bloco rw-extensions-batch-2 (quebrado) removido do LocalSettings.php."
fi

# Diagnóstico do 500 já concluído (era o AbuseFilter sem a lib Composer
# wikimedia/equivset). Remove o ShowExceptionDetails temporário do
# LocalSettings.php ao vivo — não deve ficar ligado em produção.
if grep -q "rw-show-exception-details" LocalSettings.php; then
  sed -i '/rw-show-exception-details/,+2d' LocalSettings.php
  echo "  diagnóstico de exceção (temporário) removido."
fi

# Lote de extensões estilo Wikipédia — reintroduzido (batch-3) com o JsonConfig,
# que faltava: o Kartographer o exige e sem ele o MediaWiki caía no carregamento
# (foi o que derrubou o batch-2). JsonConfig é carregado ANTES do Kartographer.
# Marcador novo (batch-3) pra não colidir com a remoção do batch-2 acima.
if ! grep -q "rw-extensions-batch-3" LocalSettings.php; then
  cat >> LocalSettings.php << 'PHPEOF'

// Religio Wiki — rw-extensions-batch-3 (lote de extensões estilo Wikipédia).
// Ver mediawiki-config/LocalSettings-snippet.php.
wfLoadExtension( 'PageImages' );
wfLoadExtension( 'TextExtracts' );
wfLoadExtension( 'Popups' );
wfLoadExtension( 'Echo' );
wfLoadExtension( 'UniversalLanguageSelector' );
wfLoadExtension( 'Interwiki' );
$wgGroupPermissions['sysop']['interwiki'] = true;
wfLoadExtension( 'MultimediaViewer' );
wfLoadExtension( 'ImageMap' );
wfLoadExtension( 'Poem' );
wfLoadExtension( 'CharInsert' );
wfLoadExtension( 'JsonConfig' );
wfLoadExtension( 'Kartographer' );
wfLoadExtension( 'TimedMediaHandler' );
$wgFFmpegLocation = '/usr/bin/ffmpeg';
$wgFileExtensions = array_merge( $wgFileExtensions, [ 'ogg', 'ogv', 'oga', 'webm', 'mp3', 'mp4', 'wav', 'flac' ] );
wfLoadExtension( 'PdfHandler' );
wfLoadExtension( 'AbuseFilter' );
$wgGroupPermissions['sysop']['abusefilter-modify'] = true;
$wgGroupPermissions['sysop']['abusefilter-view'] = true;
$wgGroupPermissions['sysop']['abusefilter-log'] = true;
$wgGroupPermissions['sysop']['abusefilter-log-detail'] = true;
wfLoadExtension( 'SpamBlacklist' );
wfLoadExtension( 'TitleBlacklist' );
wfLoadExtension( 'CheckUser' );
$wgGroupPermissions['sysop']['checkuser'] = true;
$wgGroupPermissions['sysop']['checkuser-log'] = true;
wfLoadExtension( 'SecurePoll' );
wfLoadExtension( 'Renameuser' );
$wgGroupPermissions['sysop']['renameuser'] = true;
wfLoadExtension( 'Nuke' );
wfLoadExtension( 'DeleteBatch' );
$wgGroupPermissions['sysop']['deletebatch'] = true;
PHPEOF
  echo "  lote de extensões (batch-3, com JsonConfig) carregado no LocalSettings.php."
fi

echo "== 2/4: rebuild da imagem + subindo/reiniciando o container =="
# Rebuild explícito: "up -d" sozinho NÃO reconstrói a imagem quando só o
# Dockerfile muda (ex.: skin novo copiado em skins/ReligioWiki, extensões
# via Composer) — sem isso, o container continuava rodando a imagem antiga
# depois do deploy.
$COMPOSE build "$SERVICE"
# Um deploy anterior interrompido (ex.: timeout de SSH no meio do "up") pode
# deixar um container renomeado/órfão do serviço mediawiki para trás — algo
# como "<hash>_religio-wiki-mediawiki-1". Nesse caso o "compose up" seguinte
# aborta com "container name already in use" e NADA sobe. Remover os containers
# do serviço mediawiki antes do "up" desfaz esse impasse (o "up" recria o
# container do zero com a imagem nova). O banco NÃO é tocado — fica no ar, então
# o update.php mais abaixo continua funcionando sem esperar o db reiniciar.
docker ps -a --filter "label=com.docker.compose.service=$SERVICE" -q \
  | xargs -r docker rm -f >/dev/null 2>&1 || true
$COMPOSE up -d --remove-orphans
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

# Reconstrói o índice de busca de texto (searchindex) depois de aplicar as
# páginas — garante que a busca de texto completo encontre artigos como
# "Cristianismo". A busca por prefixo/título (autocomplete) já funciona sem
# isso, mas o índice de texto pode ficar vazio em imports via edit.php.
echo "  reconstruindo índice de busca..."
$COMPOSE exec -T "$SERVICE" php maintenance/rebuildtextindex.php || \
  echo "  (rebuildtextindex falhou — provável backend de busca sem índice MySQL; segue sem travar)"

# Recalcula site_stats (contagem de "artigos publicados" usada por
# {{NUMBEROFARTICLES}} na Página principal) do zero, direto das páginas reais
# — necessário depois de mudar o critério de contagem (ex.: hook
# ArticleIsCountable que agora exclui a própria Página principal, ver
# LocalSettings-snippet.php) ou depois de aplicar/editar páginas em lote via
# edit.php, que não recalcula esses contadores incrementalmente sozinho.
# Seguro rodar sempre: --update sobrescreve com o valor correto atual.
echo "  recalculando contadores (artigos publicados)..."
$COMPOSE exec -T "$SERVICE" php maintenance/initSiteStats.php --update

echo "== 4/4: resetando skin fixado em contas já existentes =="
# $wgDefaultSkin só vale pra quem NUNCA salvou uma preferência própria de
# aparência. Contas criadas antes do skin ReligioWiki existir (ex.: o Admin
# do install.php) já têm algum outro skin gravado como escolha pessoal em
# user_properties, e isso sempre vence sobre o padrão do site — por isso o
# wiki continuaria "sem a identidade" mesmo logado como Admin. Limpa essa
# preferência pra todo mundo, fazendo cair de volta no padrão (ReligioWiki).
# Não apaga conta, senha nem nenhum outro dado — só essa escolha.
$COMPOSE exec -T "$SERVICE" php maintenance/sql.php --query \
  "DELETE FROM user_properties WHERE up_property = 'skin';"

echo
echo "Pronto. Dê um Ctrl+F5 (hard refresh) no navegador — o MediaWiki cacheia"
echo "CSS/JS do skin agressivamente via ResourceLoader."
echo
echo "Se \$wgSkipSkins não bastar pra alguma conta antiga (skin salvo direto"
echo "no banco por algum outro caminho), é só abrir Preferências → Aparência"
echo "e confirmar que só 'ReligioWiki' aparece como opção."
echo
echo "Confira também 'Gerenciar editores' (Special:UserRights) para colocar seu"
echo "usuário no grupo 'editor' caso a aba 'Editar' ainda não apareça."
