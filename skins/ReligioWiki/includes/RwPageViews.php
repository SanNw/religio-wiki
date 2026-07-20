<?php
/**
 * Religio Wiki — "Artigo em destaque" (mais lido do dia) e "Imagem do dia"
 * (rotação automática a cada 24h).
 *
 * Fica no skin (junto de ReligioWikiTemplate.php) só porque é onde este
 * projeto já tem um lugar copiado pro Docker image e autoload registrado
 * (ver skin.json) — não é lógica de aparência, é conteúdo dinâmico da home,
 * mas criar uma extensão própria só pra isso seria over-engineering. Os dois
 * parser functions abaixo ({{#artigoemdestaque:}} e {{#imagemdodia:}}) são
 * registrados em LocalSettings-snippet.php e usados nas sub-páginas
 * "Página principal/Artigo em destaque" e "Página principal/Imagem do dia"
 * (ver mediawiki-config/pagina-principal.wikitext).
 */

use MediaWiki\MediaWikiServices;

class RwPageViews {

	/**
	 * Registra uma visualização de HOJE (UTC) para a página, se ela for um
	 * artigo de verdade (espaço principal, existe, não é a própria Página
	 * principal) vista de forma "normal" (não editar/histórico/diff/POST).
	 * Chamado a cada requisição via hook BeforePageDisplay — o incremento em
	 * si roda como DeferredUpdate pra não atrasar a resposta da página.
	 */
	public static function recordView( OutputPage $out ) {
		$title = $out->getTitle();
		if ( !$title || !$title->exists() || !$title->inNamespace( NS_MAIN ) || $title->isMainPage() ) {
			return;
		}
		$request = $out->getRequest();
		if ( $request->wasPosted() ) {
			return;
		}
		$action = $request->getRawVal( 'action', 'view' );
		if ( $action !== 'view' ) {
			return;
		}
		if ( $request->getCheck( 'diff' ) || $request->getCheck( 'oldid' ) ) {
			return; // não conta diff/revisão antiga, só a versão atual
		}

		$dbKey = $title->getDBkey();
		DeferredUpdates::addCallableUpdate( static function () use ( $dbKey ) {
			$dbw = MediaWikiServices::getInstance()->getConnectionProvider()->getPrimaryDatabase();
			$date = gmdate( 'Y-m-d' );
			$dbw->upsert(
				'rw_pageviews',
				[
					'rwpv_title' => $dbKey,
					'rwpv_date' => $date,
					'rwpv_views' => 1,
				],
				[ [ 'rwpv_date', 'rwpv_title' ] ],
				[ 'rwpv_views = rwpv_views + 1' ],
				__METHOD__
			);
		} );
	}

	/** Cria a tabela rw_pageviews (idempotente — update.php já checa se existe). */
	public static function onLoadExtensionSchemaUpdates( $updater ) {
		$updater->addExtensionTable(
			'rw_pageviews',
			dirname( __DIR__ ) . '/sql/rw_pageviews.sql'
		);
	}

	/** Título (texto, sem namespace) do artigo mais visto HOJE, ou null. */
	private static function getTopArticleToday(): ?string {
		$dbr = MediaWikiServices::getInstance()->getConnectionProvider()->getReplicaDatabase();
		$row = $dbr->newSelectQueryBuilder()
			->select( [ 'rwpv_title' ] )
			->from( 'rw_pageviews' )
			->where( [ 'rwpv_date' => gmdate( 'Y-m-d' ) ] )
			->orderBy( 'rwpv_views', 'DESC' )
			->limit( 1 )
			->caller( __METHOD__ )
			->fetchRow();
		return $row ? $row->rwpv_title : null;
	}

	/**
	 * Reserva pra quando ainda não há NENHUMA visualização registrada hoje
	 * (site recém-publicado, ou madrugada logo após virar o dia UTC): o
	 * artigo publicado mais recente, nunca a Página principal.
	 */
	private static function getFallbackArticle(): ?string {
		$dbr = MediaWikiServices::getInstance()->getConnectionProvider()->getReplicaDatabase();
		$mainPage = Title::newMainPage();
		$conds = [
			'page_namespace' => NS_MAIN,
			'page_is_redirect' => 0,
		];
		if ( $mainPage ) {
			$conds[] = 'page_title != ' . $dbr->addQuotes( $mainPage->getDBkey() );
		}
		$row = $dbr->newSelectQueryBuilder()
			->select( [ 'page_title' ] )
			->from( 'page' )
			->where( $conds )
			->orderBy( 'page_id', 'DESC' )
			->limit( 1 )
			->caller( __METHOD__ )
			->fetchRow();
		return $row ? $row->page_title : null;
	}

	/** Primeiro parágrafo "limpo" (sem templates/refs/categorias) de um wikitexto. */
	private static function firstParagraph( string $wikitext ): string {
		$text = preg_replace( '/<ref[^>]*\/>/is', '', $wikitext );
		$text = preg_replace( '/<ref[^>]*>.*?<\/ref>/is', '', $text );
		$text = preg_replace( '/\[\[[Cc]ategor[yi]a?:[^\]]*\]\]/', '', $text );
		$text = preg_replace( '/\{\{[^{}]*\}\}/s', '', $text ); // predefinições de uma camada (infocaixas, avisos)
		$paragraphs = preg_split( '/\n{2,}/', trim( (string)$text ) );
		foreach ( $paragraphs as $p ) {
			$p = trim( $p );
			if ( $p === '' || $p[0] === '=' || $p[0] === '{' || stripos( $p, '[[arquivo:' ) === 0 || stripos( $p, '[[file:' ) === 0 || stripos( $p, '[[imagem:' ) === 0 ) {
				continue;
			}
			return $p;
		}
		return '';
	}

	/**
	 * {{#artigoemdestaque:}} — usado em "Página principal/Artigo em
	 * destaque". Mostra o artigo (espaço principal, publicado) mais lido
	 * HOJE; sem dados ainda hoje, cai para o artigo mais recente. Nunca
	 * mostra a própria Página principal nem páginas de projeto/configuração
	 * (a consulta já é restrita a NS_MAIN via getTopArticleToday/
	 * getFallbackArticle).
	 */
	public static function renderFeaturedArticle( Parser $parser ) {
		$titleText = self::getTopArticleToday() ?? self::getFallbackArticle();
		if ( $titleText === null ) {
			return '';
		}
		$title = Title::newFromText( $titleText, NS_MAIN );
		if ( !$title || !$title->exists() || $title->isMainPage() ) {
			return '';
		}
		$page = MediaWikiServices::getInstance()->getWikiPageFactory()->newFromTitle( $title );
		$content = $page->getContent();
		$wikitext = ( $content instanceof WikitextContent ) ? $content->getText() : '';
		$snippet = self::firstParagraph( $wikitext );
		$link = $title->getPrefixedText();
		$out = "=== [[$link]] ===\n";
		if ( $snippet !== '' ) {
			$out .= $snippet . " '''[[$link|Continue lendo →]]'''";
		} else {
			$out .= "'''[[$link|Continue lendo →]]'''";
		}
		return [ $out, 'noparse' => false ];
	}

	/**
	 * {{#imagemdodia:}} — usado em "Página principal/Imagem do dia". Escolhe
	 * uma imagem de [[Categoria:Imagens do dia]] (curadoria manual: só
	 * pinturas, paisagens e objetos — NUNCA foto de pessoa, ver a própria
	 * página da categoria) de forma determinística pelo dia UTC, então troca
	 * sozinha a cada 24h e todo mundo vê a mesma imagem no mesmo dia. Sem
	 * nenhuma imagem curada ainda, não mostra nada (evita link vermelho).
	 */
	public static function renderImageOfDay( Parser $parser ) {
		$dbr = MediaWikiServices::getInstance()->getConnectionProvider()->getReplicaDatabase();
		$files = $dbr->newSelectQueryBuilder()
			->select( [ 'page_title' ] )
			->from( 'categorylinks' )
			->join( 'page', null, 'cl_from = page_id' )
			->where( [ 'cl_to' => 'Imagens_do_dia', 'page_namespace' => NS_FILE ] )
			->orderBy( 'page_title' ) // ordem estável — o índice do dia sempre cai na mesma imagem
			->caller( __METHOD__ )
			->fetchFieldValues();
		if ( !$files ) {
			return '';
		}
		$dayIndex = (int)floor( time() / 86400 );
		$chosen = $files[ $dayIndex % count( $files ) ];
		$fileTitle = Title::newFromText( $chosen, NS_FILE );
		if ( !$fileTitle ) {
			return '';
		}
		$fileName = $fileTitle->getPrefixedText();

		// Legenda: primeira linha de texto de verdade na página do arquivo
		// (o editor pode escrever a origem/contexto da imagem lá), sem os
		// marcadores de categoria.
		$filePage = MediaWikiServices::getInstance()->getWikiPageFactory()->newFromTitle( $fileTitle );
		$content = $filePage->getContent();
		$wikitext = ( $content instanceof WikitextContent ) ? $content->getText() : '';
		$caption = self::firstParagraph( $wikitext );

		$link = $caption !== ''
			? "[[$fileName|center|thumb|upright=2.2|$caption]]"
			: "[[$fileName|center|thumb|upright=2.2]]";
		return [ $link, 'noparse' => false ];
	}
}
