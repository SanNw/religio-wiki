<?php
/**
 * Religio Wiki — trechos para colar no final do LocalSettings.php gerado
 * pelo instalador (ver README.md da pasta "Religio Wiki").
 */

// ---------- Skin: ReligioWiki (identidade visual própria) ----------
// Substitui a abordagem anterior (Vector clássico + Common.css/Common.js
// tentando reconciliar visual por cima do DOM dele — nunca bateu 100% com
// o artefato de prévia do projeto). Agora o próprio skin já gera o DOM do
// jeito certo (skins/ReligioWiki), então não tem mais "quase igual".
wfLoadSkin( 'ReligioWiki' );
$wgDefaultSkin = 'religiowiki';

// Mesmo motivo de antes pro $wgSkipSkins: preferência pessoal de skin salva
// numa conta (Special:Preferences → Aparência) vence sobre o padrão do
// site. Com só um skin na lista, não sobra outra opção pra escolher, nem
// por preferência salva antiga nem por link direto (?useskin=...).
$wgSkipSkins = [ 'vector', 'vector-2022', 'monobook', 'minerva', 'timeless', 'cologneblue', 'modern' ];
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

// VisualEditor: REATIVADO. No MediaWiki 1.43 o VE usa o Parsoid embutido no
// core (via REST API interna), sem precisar de RESTBase ou de um serviço
// Parsoid à parte — por isso a aba "Editar" volta a funcionar sem config extra.
// É também pré-requisito do DiscussionTools (ver abaixo). O "Editar
// código-fonte" (wikitexto) continua disponível em paralelo.
wfLoadExtension( 'VisualEditor' );
// VE fica carregado (o DiscussionTools exige), mas DESLIGADO por padrão para o
// usuário — é isso que remove a aba "Editar" do VE, deixando só o "Editar"
// (editor de código-fonte). Não usar hook/CSS pra esconder a aba: desligar a
// preferência é a forma correta e não deixa a aba "vazar" em nenhum caminho.
$wgDefaultUserOptions['visualeditor-enable'] = 0;
// Editor de wikitexto 2017 (mesma engine do VE) — usado pela ferramenta de
// resposta do DiscussionTools.
$wgVisualEditorEnableWikitext = true;

// Linter: pré-requisito do DiscussionTools; marca erros de wikitexto
// (Special:LintErrors). Sem interface intrusiva no leitor.
wfLoadExtension( 'Linter' );

// DiscussionTools: sistema moderno de discussões (responder inline, iniciar
// tópico, assinar tópicos). Depende de VisualEditor + Linter, carregados acima.
wfLoadExtension( 'DiscussionTools' );

// A aba "Editar" do VisualEditor não é usada na Religio Wiki (a edição fica no
// editor de código-fonte, que funciona sempre); o VE fica carregado só como
// dependência do DiscussionTools. Este hook remove a aba do VE da navegação e
// deixa o único botão de edição como "Editar" (em vez de "Editar código-fonte").
$wgHooks['SkinTemplateNavigation::Universal'][] = static function ( $sktemplate, &$links ) {
	unset( $links['views']['ve-edit'] );
	if ( isset( $links['views']['edit']['text'] ) ) {
		$links['views']['edit']['text'] = 'Editar';
	}
};

// TemplateData: documentação estruturada de templates, usada pelo
// VisualEditor para mostrar os campos de um template (ex.: template de
// citação) num formulário em vez de wikitexto cru.
wfLoadExtension( 'TemplateData' );

// TemplateWizard: adiciona um botão (peça de quebra-cabeça) na barra do
// WikiEditor que abre um assistente para inserir predefinições (templates)
// preenchendo seus campos num formulário, em vez de digitar o wikitexto
// {{...|...}} à mão. Lê os campos/descrições do bloco <templatedata> de cada
// template (ver as predefinições em mediawiki-config/pages/Template_*.wikitext),
// então funciona melhor quanto mais templates tiverem esse bloco. Depende de
// WikiEditor e TemplateData, ambos já carregados acima.
wfLoadExtension( 'TemplateWizard' );

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

// ---------- Espaço nominal "Rascunho" (artigos não publicados) ----------
// Rascunhos ficam no espaço "Rascunho:", separados dos artigos publicados
// (espaço principal). O painel Special:Artigos (extensão ReligiowikiCustomizer)
// lista os dois em abas separadas e permite "Publicar" um rascunho — que nada
// mais é do que mover Rascunho:X → X (espaço principal). NÃO é espaço de
// conteúdo de propósito: rascunhos não entram na contagem de artigos
// ({{NUMBEROFARTICLES}}) nem na página principal, e não aparecem na busca
// padrão dos leitores (o admin acha tudo por Special:Artigos).
define( 'NS_RASCUNHO', 3000 );
define( 'NS_RASCUNHO_TALK', 3001 );
$wgExtraNamespaces[NS_RASCUNHO] = 'Rascunho';
$wgExtraNamespaces[NS_RASCUNHO_TALK] = 'Rascunho_Discussão';
$wgNamespacesWithSubpages[NS_RASCUNHO] = true;
$wgNamespacesToBeSearchedDefault[NS_RASCUNHO] = false;

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

// ---------- "Criar artigo" na caixa de ferramentas (só quem pode criar) ----------
// Aponta para o formulário guiado Religio Wiki:Criar artigo (Page Forms) —
// bem mais simples que o truque antigo de "busque um título inexistente e
// clique em criar". Some da lateral sozinho pra quem não tem o direito
// 'createpage' (leitor anônimo ou conta sem grupo "editor").
$wgHooks['SidebarBeforeOutput'][] = static function ( $sk, &$sidebar ) {
	if ( !$sk->getAuthority()->isAllowed( 'createpage' ) ) {
		return;
	}
	$criarTitle = Title::newFromText( 'Religio Wiki:Criar artigo' );
	$sidebar['TOOLBOX']['createarticle'] = [
		'text' => 'Criar artigo',
		'href' => $criarTitle ? $criarTitle->getLocalURL() : SpecialPage::getTitleFor( 'Search' )->getLocalURL(),
		'id' => 't-createarticle',
	];
};

// ---------- "Personalizar wiki" na caixa de ferramentas (só admin) ----------
// Atalho para o painel Special:ReligiowikiCustomizer na seção "Ferramentas".
// Condicionado ao direito 'editinterface' — a MESMA permissão que a própria
// página especial exige (grupos "Administradores" e "Administradores da
// interface") — então o link some sozinho pra quem não é admin, sem CSS e sem
// levar ninguém a uma tela de "Erro de permissão".
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

// ---------- CodeMirror (destaque de sintaxe, DESLIGADO por padrão) ----------
// O CodeMirror substitui o <textarea> nativo (wpTextbox1) pelo editor dele.
// A barra de edição da ReligiowikiCustomizer (botões Card/Alerta/Formatação)
// insere texto direto no textarea, e com o CodeMirror ativo isso não reflete
// no editor visível — os botões "não funcionam". Fica DESLIGADO por padrão
// (usecodemirror=0); quem quiser highlight liga em Preferências → Edição.
wfLoadExtension( 'CodeMirror' );
$wgDefaultUserOptions['usecodemirror'] = 0;

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

// ================================================================
// Lote de extensões estilo Wikipédia (rw-extensions-batch-3). Baixadas pelo
// Dockerfile (git clone REL1_43). JsonConfig é carregado ANTES do Kartographer
// (que o exige). CirrusSearch e Graph ficaram de fora; DiscussionTools é
// tratada à parte (depende do VisualEditor).
// ================================================================
wfLoadExtension( 'PageImages' );
wfLoadExtension( 'TextExtracts' );
wfLoadExtension( 'Popups' );
wfLoadExtension( 'Echo' );
// O skin próprio (ReligioWiki) não é um dos skins que o Echo estiliza
// automaticamente, então o "sino" de notificações aparecia como um número solto
// (sem ícone). Força o carregamento dos estilos e do JS do badge para quem está
// logado — aí o ícone e o popup de notificações voltam a funcionar no menu.
$wgHooks['BeforePageDisplay'][] = static function ( $out ) {
	if ( $out->getUser()->isRegistered() ) {
		$out->addModuleStyles( 'ext.echo.styles.badge' );
		$out->addModules( 'ext.echo.init' );
	}
};
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

// ---------- Busca: AdvancedSearch (interface com filtros) ----------
// Melhora Special:Search com um formulário de filtros (namespace, ordenação,
// tipo). Extensão leve, só frontend — funciona sobre a busca NATIVA do
// MediaWiki, sem exigir Elasticsearch/CirrusSearch. A busca de categoria
// profunda é desligada porque depende do CirrusSearch (que não usamos).
wfLoadExtension( 'AdvancedSearch' );
$wgAdvancedSearchDeepcategoryEnabled = false;

// ---------- E-mail e confirmação de conta ----------
// A criação de conta já é aberta (ver bloco de acesso no topo). Aqui liga a
// CONFIRMAÇÃO de e-mail: quem cria conta e informa e-mail recebe um link de
// confirmação (Special:ConfirmEmail / "confirmar endereço de e-mail"). O envio
// depende do SMTP abaixo. A biblioteca PEAR Mail (pear/mail), usada pelo
// $wgSMTP, já vem como dependência do MediaWiki core — não precisa adicionar.
$wgEnableEmail = true;
$wgEnableUserEmail = true;
$wgEmailAuthentication = true;   // ativa o fluxo de confirmação por link
$wgAllowHTMLEmail = false;
$rwMailFrom = getenv( 'RW_MAIL_FROM' ) ?: 'no-reply@religiowiki.com';
$wgPasswordSender = $rwMailFrom;
$wgEmergencyContact = $rwMailFrom;
$wgNoReplyAddress = $rwMailFrom;
// Credenciais SMTP lidas de variáveis de ambiente (definidas no .env da VPS,
// NUNCA no repositório, que é público). Enquanto RW_SMTP_HOST estiver vazio, o
// $wgSMTP não é configurado e a confirmação de e-mail não envia — preencha o
// .env (ver README) para ativar de verdade.
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
