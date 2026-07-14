<?php
/**
 * Religio Wiki — trechos para colar no final do LocalSettings.php gerado
 * pelo instalador (ver README.md da pasta "Religio Wiki").
 */

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
