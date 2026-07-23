<?php
/**
 * Religio Wiki — trechos para colar no final do LocalSettings.php gerado
 * pelo instalador (ver README.md da pasta "Religio Wiki").
 *
 * ⚠️ ARMADILHA (já mordeu uma vez): scripts/deploy-wiki-content.sh só cola
 * este arquivo INTEIRO no LocalSettings.php da VPS UMA VEZ — ele checa um
 * marcador fixo ("Religio Wiki — trechos para colar") e, se já existir,
 * PULA o resto da vida, mesmo que este arquivo mude depois. Em um wiki já
 * no ar (o caso normal, depois do primeiro deploy), editar algo aqui
 * NÃO tem efeito nenhum sozinho — o site continua rodando a versão colada
 * na primeira vez.
 *
 * Por isso: toda mudança feita AQUI que precise valer pra um deploy já
 * existente também precisa de um bloco PRÓPRIO e idempotente (com seu
 * próprio marcador único, tipo "rw-nome-da-coisa") em
 * scripts/deploy-wiki-content.sh, na seção de "Checagens separadas" —
 * mesmo padrão dos blocos rw-pageviews/rw-cache-db/rw-font-async etc. que
 * já estão lá. Sem isso, a mudança só chega em instalações NOVAS (que
 * ainda vão colar este arquivo pela primeira vez).
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

// ---------- Fonte: carregamento assíncrono (não bloqueia a renderização) ----------
// A fonte (Noto Sans + scripts não-latinos) ficava num @import DENTRO do
// skin.css — isso força o navegador a baixar e parsear o CSS do skin via
// load.php primeiro, só então descobrir a URL da fonte e disparar UM
// SEGUNDO request bloqueante pra fonts.googleapis.com, antes de qualquer
// texto aparecer. É a causa mais provável do "CSS demorando pra carregar":
// o load.php em si é rápido, o que demora é essa segunda ida ao Google
// encadeada depois dele. Em vez disso, o <link> da fonte entra direto no
// <head> (sem depender do skin.css terminar) e usa o truque
// media="print" → "all" no onload: o navegador busca o CSS da fonte em
// paralelo, SEM bloquear a primeira renderização da página (que usa a
// fonte de fallback do sistema até a real terminar de carregar).
$wgHooks['BeforePageDisplay'][] = static function ( $out ) {
	$href = 'https://fonts.googleapis.com/css2?family=Noto+Sans:wght@400;600;700' .
		'&family=Noto+Sans+Arabic:wght@400;600;700' .
		'&family=Noto+Sans+Hebrew:wght@400;600;700' .
		'&family=Noto+Sans+Greek:wght@400;600;700' .
		'&family=Noto+Sans+Devanagari:wght@400;600;700' .
		'&display=swap';
	$out->addHeadItem( 'rw-font-preconnect',
		'<link rel="preconnect" href="https://fonts.googleapis.com">' .
		'<link rel="preconnect" href="https://fonts.gstatic.com" crossorigin>'
	);
	$out->addHeadItem( 'rw-font-async',
		'<link rel="stylesheet" href="' . htmlspecialchars( $href ) . '" media="print" ' .
		'onload="this.media=\'all\'">' .
		'<noscript><link rel="stylesheet" href="' . htmlspecialchars( $href ) . '"></noscript>'
	);
};

// ---------- Performance: cache de objeto/parser (sem depender de serviço novo) ----------
// Sem isso, $wgMainCacheType/$wgParserCacheType ficam no padrão do MediaWiki
// (efetivamente SEM cache nenhum quando não há Memcached/Redis configurado
// — que é o caso aqui: docker-compose.yml só tem db + mediawiki, nenhum
// serviço de cache) — toda página reparseia do zero a cada visita e cada
// sessão bate no banco pra tudo. CACHE_DB usa a própria tabela objectcache
// (nativa, já criada por update.php) como backend — sem precisar adicionar
// container/extensão nova. Não é tão rápido quanto Memcached/Redis de
// verdade, mas é uma melhora real sobre "sem cache nenhum" com zero risco
// de infraestrutura a mais pra manter.
// ($wgSessionCacheType fica de fora de propósito: sessão/login é a parte
// mais sensível a regressão silenciosa — CACHE_DB nem sempre se comporta
// bem pra sessão dependendo da versão, e o ganho de performance aqui é
// pequeno perto do risco de deslogar todo mundo sem aviso.)
$wgMainCacheType = CACHE_DB;
$wgParserCacheType = CACHE_DB;

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

// A mesma limpeza acima só cobre a aba do TOPO da página. O VisualEditor
// adiciona seu PRÓPRIO link "editar" a cada seção (ao lado do "editar
// código-fonte" nativo, entre colchetes junto de cada ==Título==) por um
// caminho totalmente separado (hook 'SkinEditSectionLinks', chave
// 'veeditsection' no array de resultado) — por isso sobrevivia mesmo com o
// hook acima, aparecendo em dobro ("editar | editar código-fonte") em cada
// seção para quem tem o VE habilitado nas preferências pessoais.
$wgHooks['SkinEditSectionLinks'][] = static function ( $skin, $title, $section, $tooltip, &$result, $lang ) {
	unset( $result['veeditsection'] );
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

// ---------- Contador "N artigos publicados" (home) não conta a própria home ----------
// {{NUMBEROFARTICLES}}, usado na Página principal, já só conta o espaço
// principal (namespace 0) por padrão — Rascunho (acima), "Religio Wiki:"
// (Sobre, Doar, Criar artigo, Idiomas) e páginas de categoria/predefinição
// já ficam de fora sozinhos, por estarem em outros espaços nominais. A ÚNICA
// exceção é a própria "Página principal": ela mora no espaço principal (é
// assim que o MediaWiki identifica a home) e contém links, então por padrão
// o MediaWiki a contava como se fosse mais um artigo publicado — inflando o
// número em 1. Este hook tira especificamente ela da contagem, sem tocar em
// nenhum outro critério nativo (link method continua igual pros artigos de
// verdade).
$wgHooks['ArticleIsCountable'][] = static function ( $article, &$result ) {
	if ( $article->getTitle()->isMainPage() ) {
		$result = false;
	}
};

// {{NUMBEROFARTICLES}} muda no banco (site_stats) na hora, mas a Página
// principal em si só REPARSEIA (e portanto só mostra o número novo) quando o
// cache de parser dela expira sozinho (até 1 dia, $wgParserCacheExpireTime) ou
// quando alguém a edita — daí a sensação de "o contador não atualiza
// sozinho" mesmo depois de publicar um artigo novo. Este hook invalida o
// cache da Página principal toda vez que um artigo de verdade (espaço
// principal, publicado, não é ela mesma) é criado/editado/apagado, forçando
// reparse — e portanto o número certo — já na próxima visita à home, sem
// esperar o TTL do cache.
$wgHooks['PageSaveComplete'][] = static function ( $wikiPage, $user, $summary, $flags, $revisionRecord, $editResult ) {
	$title = $wikiPage->getTitle();
	if ( $title->inNamespace( NS_MAIN ) && !$title->isMainPage() ) {
		$mainPage = Title::newMainPage();
		if ( $mainPage ) {
			$mainPage->invalidateCache();
		}
	}
};
$wgHooks['ArticleDeleteComplete'][] = static function ( $article ) {
	$title = $article->getTitle();
	if ( $title->inNamespace( NS_MAIN ) && !$title->isMainPage() ) {
		$mainPage = Title::newMainPage();
		if ( $mainPage ) {
			$mainPage->invalidateCache();
		}
	}
};

// ---------- "Artigo em destaque" (mais lido do dia) e "Imagem do dia" (24h) ----------
// Lógica em skins/ReligioWiki/includes/RwPageViews.php (autoload via
// skin.json). Registra {{#artigoemdestaque:}} e {{#imagemdodia:}} — usados
// nas sub-páginas "Página principal/Artigo em destaque" e "Página
// principal/Imagem do dia" (ver mediawiki-config/pagina-principal.wikitext)
// — e conta visualizações diárias de artigo numa tabela própria
// (rw_pageviews) pra saber qual foi o mais lido hoje.
$wgHooks['LoadExtensionSchemaUpdates'][] = [ 'RwPageViews', 'onLoadExtensionSchemaUpdates' ];
$wgHooks['BeforePageDisplay'][] = static function ( $out ) {
	RwPageViews::recordView( $out );
};
// Parser::setFunctionHook() exige que o id já exista como magic word
// REGISTRADA antes de ganchar — sem isso, MagicWordFactory::get() lança
// "Error: invalid magic word" pra QUALQUER Parser novo criado no site
// inteiro (não só quando a página usa a função de verdade), o que derruba
// TODA página com erro 500. Arquivo legado porque isto não é uma extensão
// de verdade com extension.json (que teria a chave "MagicWords" moderna).
$wgExtensionMessagesFiles['ReligioWikiMagic'] = __DIR__ . '/skins/ReligioWiki/i18n/RwPageViews.magic.php';
$wgHooks['ParserFirstCallInit'][] = static function ( Parser $parser ) {
	$parser->setFunctionHook( 'artigoemdestaque', [ 'RwPageViews', 'renderFeaturedArticle' ] );
	$parser->setFunctionHook( 'imagemdodia', [ 'RwPageViews', 'renderImageOfDay' ] );
};

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

// ---------- "Imagens enviadas" na caixa de ferramentas (quem envia imagem) ----------
// Atalho para Special:ListFiles (Especial:ListaDeArquivos): lista TODAS as
// imagens já enviadas, com busca por nome e miniaturas — facilita achar o nome
// do arquivo pra inserir num artigo ou numa infocaixa. Aparece só pra quem tem
// direito de upload (grupo "editor" e admin).
$wgHooks['SidebarBeforeOutput'][] = static function ( $sk, &$sidebar ) {
	if ( !$sk->getAuthority()->isAllowed( 'upload' ) ) {
		return;
	}
	$sidebar['TOOLBOX']['rw-images'] = [
		'text' => 'Imagens enviadas',
		'href' => SpecialPage::getTitleFor( 'ListFiles' )->getLocalURL(),
		'id' => 't-rw-images',
	];
};

// ---------- Quem editou por último ----------
// Mostra só "Esta página foi editada pela última vez às [hora], em
// [data]" no rodapé de cada artigo, SEM o nome do usuário (privacidade --
// o histórico completo com autor de cada edição já é nativo à parte, na
// aba "Ver histórico"). $wgMaxCredits = 0 é o que faz o CreditsAction
// (núcleo do MediaWiki) cair no lastmod (só data) em vez do
// lastmodifiedatby (data + nome) -- ver includes/skins/components/
// SkinComponentFooter.php::getFooterInfoData().
$wgMaxCredits = 0;

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
// CAPTCHA DESLIGADO na criação de conta: o pop-up de cadastro próprio do skin
// não renderiza a pergunta do QuestyCaptcha, então o cadastro sempre falhava
// com "Código CAPTCHA incorreto ou não preenchido". Como a edição é só por
// convite (grupo "editor") e agora há confirmação de e-mail, o spam já está
// barrado sem depender do CAPTCHA aqui. Continua ligado em edit/create/addurl.
$wgCaptchaTriggers['createaccount'] = false;
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
// Tira o gatilho grande de idioma ("português do Brasil") da barra pessoal —
// fica fora do topo (posição "interlanguage"), deixando a interface mais limpa
// e só um controle de idioma. O ULS continua ativo (métodos de entrada etc.).
$wgULSPosition = 'interlanguage';
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

// ---------- LinkTitles (linka automaticamente títulos de outros artigos) ----------
// Ao salvar um artigo (namespace principal), procura ocorrências do TÍTULO de
// outras páginas existentes no texto e transforma a primeira ocorrência em
// link interno -- sem o editor precisar lembrar de linkar manualmente. Os
// padrões da extensão já são conservadores o bastante pra este wiki sem
// precisar sobrescrever nada: só processa NS_MAIN
// ($wgLinkTitlesSourceNamespaces = [] -> default é só o namespace principal),
// só a 1ª ocorrência por página-alvo ($wgLinkTitlesFirstOnly = true), e modo
// "smart" que ignora maiúsculas/minúsculas de sobra
// ($wgLinkTitlesSmartMode = true).
// Testado ao vivo: "Jesus Cristo" no texto virou "[[Jesus]] Cristo" em vez de
// "[[Jesus Cristo]]" inteiro -- a extensão trata redirecionamentos (como
// "Jesus", criado pelo hook rw-auto-redirect-synonyms) como alvo de link
// válido igual a um artigo de verdade, e não tem opção nativa pra excluir
// redirecionamentos da lista de candidatos (só blacklist manual por título).
// O link final ainda funciona certo (cai no artigo certo via redirect), só
// fica visualmente fragmentado. Mitigado listando os redirecionamentos de
// sinônimo conhecidos no blacklist abaixo -- NOVOS sinônimos criados pelo
// hook automático no futuro não entram aqui sozinhos, é um limite conhecido.
wfLoadExtension( 'LinkTitles' );
$wgLinkTitlesBlackList = [ 'Jesus', 'Jesus de Nazaré', 'Islã', 'Maomé' ];

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


// rw-donate-checkout: Special:DonateCheckout recebe o valor/frequência/
// método escolhidos no widget de Religio Wiki:Doar (ver MediaWiki:Common.js)
// e cria uma Stripe Checkout Session -- pagamento de verdade, hospedado
// pelo próprio Stripe (nenhum dado de cartão passa por aqui). Chave secreta
// só existe como variável de ambiente (RW_STRIPE_SECRET_KEY, ver
// docker-compose.yml / .env), nunca em código.
require_once __DIR__ . '/mediawiki-config/includes/SpecialDonateCheckout.php';
$wgSpecialPages['DonateCheckout'] = SpecialDonateCheckout::class;

// rw-donate-pix: Special:DonatePix cria e consulta pagamentos Pix via
// Mercado Pago (Boleto/Cartão continuam via Stripe -- ver
// SpecialDonateCheckout.php -- porque o Pix não estava ativado na conta
// Stripe atual). Chave só existe como variável de ambiente
// (RW_MERCADOPAGO_ACCESS_TOKEN), nunca em código.
require_once __DIR__ . '/mediawiki-config/includes/SpecialDonatePix.php';
$wgSpecialPages['DonatePix'] = SpecialDonatePix::class;


// rw-real-article-count: {{#artigosreais:}} conta só artigos DE VERDADE no
// namespace principal -- {{NUMBEROFARTICLES}} nativo (via
// $wgArticleCountMethod='any', ver rw-article-count-any) conta QUALQUER
// página não-redirecionamento nesse namespace, incluindo subpáginas de
// infraestrutura que moram lá por causa de transclusão (Página
// principal/Artigo em destaque, /Imagem do dia) e as traduções (/en, /es,
// etc.) -- nenhuma dessas é um "artigo publicado" de verdade. Mesmo
// filtro usado em rw-random-exclude-mainpage: exclui a própria página
// principal e qualquer página com "/" no título (subpágina) do namespace
// principal.
// setHook() (tag <artigosreais/>), não setFunctionHook() ({{#artigosreais:}})
// -- parser functions exigem uma "magic word" registrada via arquivo de
// i18n de extensão de verdade (MessagesXx.php/extension.json), que não
// existe pra um hook solto aqui no LocalSettings ("invalid magic word",
// confirmado testando ao vivo). Tag hook não tem esse requisito, só
// precisa do nome mesmo.
$wgHooks['ParserFirstCallInit'][] = static function ( Parser $parser ) {
	$parser->setHook( 'artigosreais', static function () {
		$dbr = MediaWiki\MediaWikiServices::getInstance()->getConnectionProvider()->getReplicaDatabase();
		$mainPage = Title::newMainPage();
		$conds = [
			'page_namespace' => NS_MAIN,
			'page_is_redirect' => 0,
		];
		if ( $mainPage ) {
			$dbKey = $mainPage->getDBkey();
			$conds[] = 'page_title != ' . $dbr->addQuotes( $dbKey );
		}
		$conds[] = 'page_title NOT ' . $dbr->buildLike( $dbr->anyString(), '/', $dbr->anyString() );
		$count = $dbr->newSelectQueryBuilder()
			->select( 'COUNT(*)' )
			->from( 'page' )
			->where( $conds )
			->caller( __METHOD__ )
			->fetchField();
		return (string)$count;
	} );
};
