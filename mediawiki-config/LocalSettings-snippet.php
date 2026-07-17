<?php
/**
 * Religio Wiki — trechos para colar no final do LocalSettings.php gerado
 * pelo instalador (ver README.md da pasta "Religio Wiki").
 */

// ---------- Skin: força o Vector clássico (não o Vector 2022) ----------
// Todo o design da Religio Wiki (common.css/common.js) foi escrito em cima
// do DOM do Vector clássico (#mw-panel, #p-personal, #pt-login, #toc
// nativo etc.). Instalações novas do MediaWiki (1.36+) vêm com o Vector
// 2022 como padrão, cujo DOM é bem diferente — se essa configuração não
// estiver aqui, o wiki fica "parecido, mas não igual" ao projeto (cabeçalho,
// menus e fontes destoando), mesmo com o Common.css/Common.js corretos.
$wgDefaultSkin = 'vector';
$wgVectorDefaultSkinVersion = '1';
$wgVectorDefaultSkinVersionForNewAccounts = '1';
$wgVectorDefaultSkinVersionForExistingAccounts = '1';

// O padrão acima não é suficiente sozinho: preferência pessoal de skin salva
// numa conta (Special:Preferences → Aparência) sempre vence sobre o padrão
// do site, então uma conta antiga (ou alguém clicando sem querer) podia
// voltar pro Vector 2022. Solução definitiva: remove os outros skins da
// lista de opções — ninguém tem mais o que escolher além do Vector clássico,
// nem por preferência salva, nem por link direto (?useskin=...).
$wgSkipSkins = [ 'vector-2022', 'monobook', 'minerva', 'timeless' ];
// (não usar $wgHiddenPrefs aqui: foi removido do MediaWiki core há algumas
// versões — em instalações recentes referenciá-lo pode derrubar o site com
// um "DomainException" na inicialização. $wgSkipSkins sozinho já é
// suficiente: com só um skin na lista, não sobra nada pra "esconder".)

// ---------- Acesso: leitura pública/anônima, edição só por convite ----------
// Qualquer pessoa lê sem login ("modo anônimo") E pode criar a própria
// conta livremente — mas ter conta não dá direito de editar. Edição
// continua fechada: só quem for colocado manualmente no grupo "editor" por
// um admin consegue criar/editar página. Ver "Quem pode editar" no README.
//
// Por que reabrir a criação de conta: conta e permissão de editar são
// coisas separadas no MediaWiki. Deixar qualquer um criar conta não abre
// brecha nenhuma para edição — quem cria conta cai automaticamente no
// grupo "user", que continua com edit=false logo abaixo. Isso permite, por
// exemplo, guardar preferências de leitura (tema, idioma) por pessoa sem
// depender do admin cadastrar todo mundo manualmente.
$wgGroupPermissions['*']['read'] = true;
$wgGroupPermissions['*']['createaccount'] = true;
$wgGroupPermissions['*']['edit'] = false;
$wgGroupPermissions['user']['edit'] = false;

// Grupo novo: só quem for adicionado aqui manualmente cria/edita páginas e
// envia imagens. "sysop" (Admin) já pode editar por padrão do MediaWiki,
// sem precisar deste grupo.
$wgGroupPermissions['editor']['edit'] = true;
$wgGroupPermissions['editor']['createpage'] = true;
$wgGroupPermissions['editor']['createtalk'] = true;
$wgGroupPermissions['editor']['upload'] = true;
$wgGroupPermissions['editor']['reupload'] = true;

// Admin escolhe quem entra/sai do grupo "editor" em Special:UserRights.
$wgAddGroups['sysop'][] = 'editor';
$wgRemoveGroups['sysop'][] = 'editor';

// ---------- Ferramentas de edição, criação e citação (padrão Wikipédia) ----------
// As extensões abaixo não vêm no tarball/imagem padrão do MediaWiki — o
// Dockerfile desta pasta já baixa o código-fonte delas na branch REL1_41
// (mesma versão do MediaWiki instalado) para /var/www/html/extensions.
// Não verificado ao vivo neste sandbox (rede bloqueada) — confira
// Special:Version depois de subir o wiki de verdade.

// Cite: notas de rodapé com <ref>...</ref> e <references />, igual à Wikipédia.
wfLoadExtension( 'Cite' );

// ParserFunctions: lógica condicional em templates (#if, #switch etc.),
// usada pelos templates de citação (ex.: {{citar web}}).
wfLoadExtension( 'ParserFunctions' );
$wgPFEnableStringFunctions = true;

// WikiEditor: barra de ferramentas do editor de wikitexto (negrito, itálico,
// link, assinatura, etc.), a mesma barra clássica da Wikipédia.
wfLoadExtension( 'WikiEditor' );

// VisualEditor: edição em modo "o que você vê é o que tem", sem precisar
// saber wikitexto — como o editor visual da Wikipédia.
wfLoadExtension( 'VisualEditor' );
$wgDefaultUserOptions['visualeditor-enable'] = 1;
$wgVirtualRestConfig['modules']['parsoid'] = [
	'url' => 'http://localhost:80/rest.php',
	'domain' => 'localhost',
	'prefix' => 'localhost',
];

// TemplateData: documentação estruturada de templates, usada pelo
// VisualEditor para mostrar os campos de um template (ex.: template de
// citação) num formulário em vez de wikitexto cru.
wfLoadExtension( 'TemplateData' );

// Scribunto: módulos em Lua — é o que faz funcionar os templates de citação
// no estilo CS1 da Wikipédia (Module:Citation/CS1 e templates como
// {{citar web}}, {{citar livro}}), caso você importe esses templates depois.
wfLoadExtension( 'Scribunto' );
$wgScribuntoDefaultEngine = 'luastandalone';
$wgScribuntoEngineConf['luastandalone']['luaPath'] = '/usr/bin/lua5.1';

// ReligiowikiCustomizer: painel admin (Special:ReligiowikiCustomizer) que
// gera as variáveis de cor/tipografia/largura do tema a partir de
// configuração salva no banco, em vez de hardcoded — ver
// https://github.com/SanNw/religiowiki-customizer. Common.css continua
// igual: a extensão só passa a controlar de onde --rw-bg/--rw-link/etc.
// vêm, os aliases legados garantem compatibilidade total.
wfLoadExtension( 'ReligiowikiCustomizer' );

// Upload de imagens (para ilustrar/citar com mídia, com legenda via
// [[Arquivo:...|thumb|legenda]] ou <gallery>) + acesso direto ao acervo do
// Wikimedia Commons sem precisar reenviar os arquivos.
$wgEnableUploads = true;
$wgUseInstantCommons = true;
$wgFileExtensions = array_merge( $wgFileExtensions, [ 'pdf', 'svg', 'webp' ] );

// ImageMagick para gerar as miniaturas (thumbnails) das imagens nos
// artigos e na "Imagem do dia" da página principal — instalado no
// Dockerfile desta pasta.
$wgUseImageMagick = true;
$wgImageMagickConvertCommand = '/usr/bin/convert';

// ---------- Botão "Doar" ----------
// Aparece como o primeiro item da barra pessoal — ou seja, sempre à
// esquerda de "Entrar"/"Criar conta" — em todas as páginas. Leva para
// Religio Wiki:Doar (ver mediawiki-config/pagina-doar.wikitext).
$wgHooks['PersonalUrls'][] = static function ( array &$personal_urls, $title, $skin ) {
	$donateTitle = Title::newFromText( 'Religio Wiki:Doar' );
	$personal_urls = [
		'donate' => [
			'text' => 'Doar',
			'href' => $donateTitle ? $donateTitle->getLocalURL() : '#',
			'id' => 'pt-donate',
		],
	] + $personal_urls;
};

// ---------- Cor de cabeçalho por religião ----------
// Adiciona uma classe "religion-<slug>" ao <body> conforme as categorias
// do artigo, usada pelo Common.css para colorir o #firstHeading.
// Mapa explícito (não depende de transliteração automática, que varia
// entre sistemas) — mantenha sincronizado com os comentários em
// mediawiki-config/common.css conforme forem decidindo as cores.
$wgReligioWikiCategorySlugs = [
	'Taoismo' => 'taoismo',
	'Confucionismo' => 'confucionismo',
	'Xamanismo Siberiano' => 'xamanismo-siberiano',
	'Xintoísmo' => 'xintoismo',
	'Religião dos Povos Nativos Americanos' => 'religiao-dos-povos-nativos-americanos',
	'Bön' => 'boen',
	'Hinduísmo' => 'hinduismo',
	'Budismo' => 'budismo',
	'Religião Greco-Romana' => 'religiao-greco-romana',
	'Religião Germano-Céltica Antiga' => 'religiao-germano-celtica-antiga',
	'Jainismo' => 'jainismo',
	'Zoroastrismo' => 'zoroastrismo',
	'Judaísmo' => 'judaismo',
	'Cristianismo' => 'cristianismo',
	'Islã' => 'islam',
];

// Também marca body.rw-can-edit quando quem está vendo a página tem
// permissão de editar — o Common.css usa isso pra mostrar o ícone de lápis
// (✏) ao lado do título só pra quem realmente pode editar (grupo "editor"
// ou Admin), em vez de mostrar pra todo mundo.
$wgHooks['OutputPageBodyAttributes'][] = static function ( $out, $sk, &$bodyAttrs ) use ( $wgReligioWikiCategorySlugs ) {
	$classes = [];
	foreach ( $out->getCategories() as $cat ) {
		$catName = (string)$cat;
		if ( isset( $wgReligioWikiCategorySlugs[ $catName ] ) ) {
			$classes[] = 'religion-' . $wgReligioWikiCategorySlugs[ $catName ];
		}
	}
	if ( $out->getTitle() && $out->getTitle()->quickUserCan( 'edit', $sk->getUser() ) ) {
		$classes[] = 'rw-can-edit';
	}
	if ( $classes !== [] ) {
		$existing = $bodyAttrs['class'] ?? '';
		$bodyAttrs['class'] = trim( $existing . ' ' . implode( ' ', array_unique( $classes ) ) );
	}
};

// ---------- Quem editou por último ----------
// Mostra "Esta página foi editada pela última vez às [hora], em [data], por
// [usuário]" no rodapé de cada artigo — nativo do MediaWiki, só precisa
// desse número maior que zero. O histórico completo (todas as edições, com
// autor e data de cada uma) já é nativo à parte, na aba "Ver histórico".
$wgMaxCredits = 1;
$wgShowCreditsIfMax = true;

// ---------- Idiomas do artigo (convenção de sub-página) ----------
// A Wikipédia de verdade liga wikis SEPARADOS por idioma (pt.wikipedia.org,
// en.wikipedia.org...); aqui é um wiki só, então "trocar de idioma" é
// navegar para uma sub-página "Título/en", "Título/es" etc. — ver o
// seletor de idioma em common.js. Esta lista existe só como referência —
// mantenha sincronizada com o array LANGUAGES no topo do bloco "Seletor de
// idioma do artigo" em common.js ao adicionar um idioma novo.
$wgReligioWikiLanguages = [
	'en' => 'English',
	'es' => 'Español',
	'fr' => 'Français',
	'it' => 'Italiano',
];

// ---------- Login social (Google / Facebook / GitHub) ----------
// O framework (PluggableAuth) e os conectores de Google/GitHub já são
// baixados pelo Dockerfile — mas ficam DESATIVADOS até você preencher suas
// próprias credenciais OAuth abaixo, porque isso não é algo que dê pra
// gerar por aqui: cada provedor exige que você (o dono do projeto) crie um
// "app" OAuth na respectiva plataforma e gere um Client ID + Client Secret:
//   - Google:  https://console.cloud.google.com/apis/credentials
//   - GitHub:  https://github.com/settings/developers ("OAuth Apps")
//   - Facebook: precisa de um conector à parte (o Facebook não fala OpenID
//     Connect padrão como Google/GitHub) — mais trabalho, considere deixar
//     para depois; o botão já existe na interface, só não faz nada sem isso.
// Sem essas credenciais, os botões "Continuar com Google/GitHub/Facebook"
// no pop-up de login ficam visíveis, mas desabilitados — não é um bug, é a
// falta dessa configuração (ver $wgRWSocialProviders logo abaixo).
//
// Depois de ter as credenciais, descomente as linhas abaixo e preencha:
//
// IMPORTANTE: PluggableAuth_EnableLocalLogin tem padrão "false" na própria
// extensão -- sem essa linha, ativar PluggableAuth desliga o login por
// usuário/senha para TODO MUNDO, inclusive o Admin (o pop-up de login
// continua mostrando os campos, mas toda tentativa falha com "As
// credenciais fornecidas não puderam ser autenticadas", mesmo com a senha
// certa -- não é bug de senha, é o provedor local desabilitado). Descubro
// isso ao tentar logar como Admin depois do login social já configurado.
// $wgPluggableAuth_EnableLocalLogin = true;
// wfLoadExtension( 'PluggableAuth' );
// wfLoadExtension( 'OpenIDConnect' );
// $wgPluggableAuth_Config['Google'] = [
// 	'plugin' => 'OpenIDConnect',
// 	'data' => [
// 		'providerURL' => 'https://accounts.google.com',
// 		'clientID' => 'COLE_AQUI_O_CLIENT_ID_DO_GOOGLE',
// 		'clientsecret' => 'COLE_AQUI_O_CLIENT_SECRET_DO_GOOGLE',
// 	],
// ];
// $wgPluggableAuth_Config['GitHub'] = [
// 	'plugin' => 'OpenIDConnect',
// 	'data' => [
// 		'providerURL' => 'https://github.com',
// 		'clientID' => 'COLE_AQUI_O_CLIENT_ID_DO_GITHUB',
// 		'clientsecret' => 'COLE_AQUI_O_CLIENT_SECRET_DO_GITHUB',
// 	],
// ];

// Lista de provedores REALMENTE configurados acima — mantenha em sincronia
// manualmente com o bloco comentado (ex.: ['google', 'github'] depois de
// descomentar os dois). O common.js lê isso via mw.config para saber quais
// botões sociais habilitar no pop-up de login.
$wgRWSocialProviders = [];
$wgHooks['ResourceLoaderGetConfigVars'][] = static function ( array &$vars ) {
	global $wgRWSocialProviders;
	$vars['wgRWSocialProviders'] = $wgRWSocialProviders;
};

// ---------- Idioma de conteúdo/interface ----------
$wgLanguageCode = 'pt-br';

// ---------- Nome do site ----------
$wgSitename = 'Religio Wiki';

// ================================================================
// Extensões adicionais (instaladas via git/Composer — ver Dockerfile e
// composer.local.json). Compatibilidade com MediaWiki 1.43 conferida
// direto no extension.json de cada extensão em 2026-07-17. Confira
// Special:Version depois do rebuild da imagem.
// ================================================================

// ---------- ConfirmEdit + QuestyCaptcha (anti-spam, perguntas em PT-BR) ----------
wfLoadExtension( 'ConfirmEdit' );
wfLoadExtension( 'ConfirmEdit/QuestyCaptcha' );
$wgCaptchaClass = 'QuestyCaptcha';
$wgCaptchaQuestions = [
	'Quantos dias tem uma semana?' => [ '7', 'sete' ],
	'Qual é a cor do céu num dia sem nuvens?' => 'azul',
	'Quanto é dois mais dois?' => [ '4', 'quatro' ],
	'Complete: Religio ______ (nome deste site, em latim)' => 'wiki',
	'Quantos continentes existem no mundo?' => [ '7', 'sete' ],
	'Em que idioma está escrito este texto? (uma palavra)' => [ 'português', 'portugues' ],
];
$wgCaptchaTriggers['edit'] = true;
$wgCaptchaTriggers['create'] = true;
$wgCaptchaTriggers['createaccount'] = true;
$wgCaptchaTriggers['addurl'] = true;

// ---------- ReplaceText: permissão só para sysop ----------
wfLoadExtension( 'ReplaceText' );
$wgGroupPermissions['sysop']['replacetext'] = true;
$wgGroupPermissions['editor']['replacetext'] = false;
$wgGroupPermissions['user']['replacetext'] = false;

// ---------- Gadgets ----------
// A lista de gadgets mora na página wiki MediaWiki:Gadgets-definition,
// criada automaticamente (se ainda não existir) depois do rebuild.
wfLoadExtension( 'Gadgets' );

// ---------- CategoryTree (árvore de categorias assíncrona) ----------
wfLoadExtension( 'CategoryTree' );
$wgCategoryTreeDynamicTag = true; // <categorytree> carrega via AJAX, não bloqueia o carregamento da página
$wgUseCategoryBrowser = true;

// ---------- External Data (só HTTPS) ----------
// Whitelist de prefixo de URL, no mesmo estilo de $wgAllowExternalImagesFrom
// do core — qualquer fonte que não comece com "https://" é rejeitada.
wfLoadExtension( 'ExternalData' );
$wgExternalDataSources['*']['allowed urls'] = [ 'https://' ];

// ---------- TemplateStyles (CSS sanitizado por template) ----------
// Sanitização de propriedades é automática (Css-sanitizer) — não precisa
// de mais configuração para o uso básico com <templatestyles src="..." />.
wfLoadExtension( 'TemplateStyles' );

// ---------- CodeMirror (editor padrão com destaque de sintaxe) ----------
wfLoadExtension( 'CodeMirror' );
$wgDefaultUserOptions['usecodemirror'] = 1;

// ---------- Header Tabs ----------
// <headertabs /> no fim da página transforma cada ==Seção== em aba. Ativado
// automaticamente (sem precisar da tag) no namespace "Religio Wiki:",
// pensado para páginas de documentação/ajuda do projeto.
wfLoadExtension( 'HeaderTabs' );
$wgHeaderTabsAutomaticNamespaces = [ NS_PROJECT ];

// ---------- EmbedVideo (YouTube, Vimeo, MP4 local, com consentimento) ----------
wfLoadExtension( 'EmbedVideo' );
$wgEmbedVideoEnableVideoHandler = true; // <video> nativo para MP4 local
$wgEmbedVideoRequireConsent = true; // só carrega o player externo após clique explícito
$wgEmbedVideoShowPrivacyNotice = true;
$wgEmbedVideoDefaultWidth = 400;

// ---------- Semantic MediaWiki ----------
// Carregada como extensão normal (wfLoadExtension) — a função antiga
// enableSemantics() não existe mais nas versões 3.x+. Armazenamento:
// SQLStore padrão, nas mesmas tabelas do MariaDB já usado pelo wiki
// (nenhum banco separado). As tabelas são criadas pelo update.php.
wfLoadExtension( 'SemanticMediaWiki' );

// ---------- Page Forms ----------
// Carregada depois do SemanticMediaWiki de propósito: integra
// automaticamente com SMW quando a extensão já está habilitada (detecção
// própria do Page Forms, sem config extra necessária).
wfLoadExtension( 'PageForms' );

// ---------- Cargo ----------
// Backend de dados alternativo/complementar ao SMW, também com integração
// automática ao Page Forms (campos "Cargo table/field" nos formulários).
wfLoadExtension( 'Cargo' );

// ---------- Data Transfer ----------
// Import/export CSV e XML (Special:ImportCSV, Special:ImportXML,
// Special:ViewXML) — reconhece automaticamente templates ligados a
// tabelas Cargo/propriedades SMW, sem config extra além de carregar
// depois das duas extensões acima.
wfLoadExtension( 'DataTransfer' );

// ---------- SimpleBatchUpload ----------
// Restrito a quem já tem permissão de upload (grupo "editor" e sysop —
// mesma política do resto do wiki, ver bloco de permissões no topo deste
// arquivo). Tamanho máximo = limite padrão de upload do servidor
// ($wgMaxUploadSize / upload_max_filesize do PHP), não redefinido aqui.
wfLoadExtension( 'SimpleBatchUpload' );
$wgGroupPermissions['editor']['batchupload'] = true;
$wgGroupPermissions['sysop']['batchupload'] = true;
$wgGroupPermissions['user']['batchupload'] = false;
$wgGroupPermissions['*']['batchupload'] = false;

// ---------- Maps ----------
// Leaflet + OpenStreetMap como serviço padrão — único provedor que não
// exige chave de API (ao contrário do Google Maps). Já é o padrão da
// extensão desde a v9, fixado aqui de forma explícita para não depender
// do padrão de fábrica mudar numa atualização futura.
wfLoadExtension( 'Maps' );
$egMapsDefaultService = 'leaflet';
$egMapsLeafletLayer = 'OpenStreetMap';

// ---------- WikiSEO ----------
// Meta description e canonical URL são automáticos ao carregar a
// extensão; $wgMetadataGenerators liga os geradores de OpenGraph, Twitter
// Cards e Schema.org.
wfLoadExtension( 'WikiSEO' );
$wgMetadataGenerators = [ 'OpenGraph', 'Twitter', 'SchemaOrg' ];
