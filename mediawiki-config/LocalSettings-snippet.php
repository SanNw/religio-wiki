<?php
/**
 * Religio Wiki — trechos para colar no final do LocalSettings.php gerado
 * pelo instalador (ver README.md da pasta "Religio Wiki").
 */

// ---------- Acesso: leitura pública/anônima, edição só por convite ----------
// Qualquer pessoa lê sem login ("modo anônimo"). Ninguém edita por padrão —
// nem anônimo, nem quem cria uma conta — só quem for colocado manualmente
// no grupo "editor" por um admin. Registro público fica desligado: só um
// admin cria conta pra alguém (ou a própria pessoa não consegue se cadastrar
// sozinha). Ver "Quem pode editar" no README para o passo a passo.
$wgGroupPermissions['*']['read'] = true;
$wgGroupPermissions['*']['createaccount'] = false;
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

// Upload de imagens (para ilustrar/citar com mídia) + acesso direto ao
// acervo do Wikimedia Commons sem precisar reenviar os arquivos.
$wgEnableUploads = true;
$wgUseInstantCommons = true;
$wgFileExtensions = array_merge( $wgFileExtensions, [ 'pdf', 'svg', 'webp' ] );

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

$wgHooks['OutputPageBodyAttributes'][] = static function ( $out, $sk, &$bodyAttrs ) use ( $wgReligioWikiCategorySlugs ) {
	$classes = [];
	foreach ( $out->getCategories() as $cat ) {
		$catName = (string)$cat;
		if ( isset( $wgReligioWikiCategorySlugs[ $catName ] ) ) {
			$classes[] = 'religion-' . $wgReligioWikiCategorySlugs[ $catName ];
		}
	}
	if ( $classes !== [] ) {
		$existing = $bodyAttrs['class'] ?? '';
		$bodyAttrs['class'] = trim( $existing . ' ' . implode( ' ', array_unique( $classes ) ) );
	}
};

// ---------- Idioma de conteúdo/interface ----------
$wgLanguageCode = 'pt-br';

// ---------- Nome do site ----------
$wgSitename = 'Religio Wiki';
