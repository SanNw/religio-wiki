<?php
/**
 * Marcação portada quase 1:1 do artefato de prévia (rw-topbar/rw-layout/
 * rw-sidebar/rw-page-tabs/rw-toc) pra dentro do contrato clássico
 * QuickTemplate::execute(). Ids nativos do MediaWiki (#mw-panel, #p-personal,
 * #firstHeading, #content, #toc, #footer) foram mantidos DE PROPÓSITO iguais
 * ao que o Vector clássico usa — é o que permite reaproveitar quase todo o
 * Common.js/Common.css existente (seletor de tema, hambúrguer, colapso de
 * categoria, pop-up de login, lápis de edição) sem reescrever a lógica,
 * só o wrapper visual muda. Ver docs/SKIN_STATUS.md pros pontos não
 * verificados ao vivo (nunca rodou contra um MediaWiki de verdade).
 */
class ReligioWikiTemplate extends BaseTemplate {

	/** @inheritDoc */
	public function execute() {
		$skin = $this->getSkin();
		$out = $skin->getOutput();
		$title = $skin->getTitle();
		// "Artigo" = página do namespace principal, que EXISTE e NÃO é a página
		// principal (a home não deve mostrar o índice "Neste artigo" nem os
		// catlinks "Categorias: ..." no rodapé).
		$isArticle = $title && $title->inNamespace( NS_MAIN ) && !$title->isMainPage() && $skin->getRelevantTitle()->exists();
		// Aparência (com ajuste de tamanho de fonte -- importante pra quem tem
		// dificuldade de leitura) e Idioma fazem sentido em QUALQUER página que
		// um leitor normal vê, incluindo a própria página principal. "Neste
		// artigo" (índice) simplesmente fica vazio ali se a página não tiver
		// cabeçalhos suficientes, igual já acontece em artigos curtos -- não
		// precisa de uma condição própria. Fica de fora só o que NÃO é
		// conteúdo que um leitor comum acessaria: Predefinição (Template,
		// técnico/só-editor), MediaWiki (mensagens de sistema) e páginas
		// especiais (Special:, que não são "página" no sentido de conteúdo).
		$showTocColumn = $title && $title->exists()
			&& !$title->inNamespace( NS_SPECIAL )
			&& !$title->inNamespace( NS_MEDIAWIKI )
			&& !$title->inNamespace( NS_TEMPLATE )
			&& !$title->inNamespace( NS_TEMPLATE_TALK );
		$isMainPage = $title && $title->isMainPage();
		// "Admin" = quem tem o direito editinterface (grupos Administradores /
		// Administradores da interface). Usado pra esconder itens só de admin
		// na lateral e a aba "Discussão" pra quem não é admin.
		$isAdmin = $skin->getAuthority()->isAllowed( 'editinterface' );
		// rw-ve-optin (2026-07-23): a aba do VisualEditor ("ve-edit") fica
		// escondida por padrão (só o editor de código-fonte, renomeado pra
		// "Editar"), MAS quem ligar a preferência pessoal "visualeditor-enable"
		// (Special:Preferências → Edição) volta a ver as duas abas separadas.
		// Ver também os hooks SkinTemplateNavigation::Universal/
		// SkinEditSectionLinks no LocalSettings-snippet.php (mesma condição).
		$veEnabled = MediaWiki\MediaWikiServices::getInstance()->getUserOptionsLookup()
			->getBoolOption( $skin->getUser(), 'visualeditor-enable' );
		// Itens da lateral (MediaWiki:Sidebar) que só admin deve ver — casados
		// pelo rótulo exato definido no wikitext da sidebar.
		// Comparação pelo 'id' (derivado da CHAVE crua do MediaWiki:Sidebar,
		// ex.: "n-rw-sidebar-management"), não pelo 'text' (resolvido/
		// traduzido pelo Skin::addToSidebarPlain -- mudaria por idioma via
		// EN/ES e o filtro pararia de esconder esses itens de quem não é
		// admin). Ver Skin.php::addToSidebarPlain(): 'id' vem de
		// strtr($line[1], ' ', '-'), sempre a chave original, nunca traduzida.
		$adminOnlySidebar = [ 'n-rw-sidebar-newarticle', 'n-recentchanges', 'n-rw-sidebar-management', 'n-rw-sidebar-adminlist', 'n-rw-sidebar-articles' ];
		// Link "Doar" renderizado direto aqui (e não via hook PersonalUrls, que
		// deixou de ser chamado no MediaWiki 1.43 — buildPersonalUrls() não o
		// dispara, então o botão nunca aparecia). Aponta para Religio Wiki:Doar.
		$donateTitle = Title::newFromText( 'Religio Wiki:Doar' );
		$donateHref = $donateTitle ? $donateTitle->getLocalURL() : '#';
		?>
<?php
	// MediaWiki 1.43: NÃO emitir headelement / <html><head><body> aqui. O head
	// completo já é prependido pelo Skin::outputPageFinal() via
	// OutputPage::headElement() em volta do que este execute() imprime — este
	// template gera só o conteúdo do <body>. (headelement deixou de ser chave
	// de dados do QuickTemplate no 1.43; $this->html('headelement') virava
	// no-op + um warning "Undefined array key" a cada página.)
?>
<div class="rw-topbar">
	<!-- Hambúrguer ANTES do logo (padrão Wikipédia) -- ver skin.css pro
	     posicionamento (position:absolute, ancorado à esquerda agora). -->
	<button type="button" id="rw-hamburger" aria-label="Abrir menu de navegação">☰</button>
	<a href="<?php echo htmlspecialchars( Title::newMainPage()->getLocalURL() ) ?>" class="rw-brand">
		<span class="mark">R</span> <?php echo htmlspecialchars( $this->data['sitename'] ) ?>
	</a>
	<form class="rw-search" action="<?php echo htmlspecialchars( $this->data['wgScript'] ?? '/index.php' ) ?>" method="get" role="search">
		<input type="hidden" name="title" value="Special:Search">
		<?php echo $this->makeSearchInput( [ 'placeholder' => 'Buscar na ' . htmlspecialchars( $this->data['sitename'] ), 'id' => 'searchInput' ] ) ?>
		<?php echo $this->makeSearchButton( 'go', [ 'id' => 'searchButton', 'class' => 'rw-search-go' ] ) ?>
	</form>
	<div id="p-personal" class="rw-personal">
		<a id="pt-donate" class="rw-donate" href="<?php echo htmlspecialchars( $donateHref ) ?>"><strong>Doar</strong></a>
		<ul>
<?php foreach ( $this->getPersonalTools() as $key => $item ) { ?>
			<?php echo $this->makeListItem( $key, $item ) ?>
<?php } ?>
		</ul>
	</div>
</div>

<div id="mw-page-base"></div>
<div id="rw-sidebar-overlay"></div>

<div class="rw-layout">
	<div id="mw-panel" class="rw-sidebar">
		<!-- Botão de fechar grudado na borda direita da gaveta (que agora abre
		     pela esquerda) -- o próprio #rw-hamburger já fecha também (vira
		     ✕), mas fica longe da gaveta uma vez que ela está aberta; ver
		     skin.js (mesma função close()) e skin.css. -->
		<button type="button" id="rw-sidebar-close" aria-label="Fechar menu de navegação">✕</button>
<?php foreach ( $this->getSidebar( [ 'search' => false ] ) as $boxName => $box ) { ?>
		<?php if ( is_array( $box ) ) { ?>
		<div class="portal" id="<?php echo Sanitizer::escapeIdForAttribute( "p-{$boxName}" ) ?>">
			<?php if ( isset( $box['header'] ) ) { ?>
			<h3><?php echo htmlspecialchars( $box['header'] ) ?></h3>
			<?php } ?>
			<div class="body">
				<?php if ( is_array( $box['content'] ) ) { ?>
				<ul>
					<?php foreach ( $box['content'] as $key => $link ) {
							if ( !$isAdmin && is_array( $link ) && in_array( $link['id'] ?? '', $adminOnlySidebar, true ) ) { continue; } // só admin: Criar novo artigo / Mudanças recentes / Gestão / Lista de administradores / Artigos
						echo $this->makeListItem( $key, $link );
					} ?>
				</ul>
				<?php } else {
					echo $box['content'];
				} ?>
			</div>
		</div>
		<?php } ?>
<?php } ?>
	</div>

	<main id="content" class="mw-body<?php echo $isMainPage ? ' rw-mainpage' : '' ?>" role="main">
		<?php if ( $out->getIndicators() ) {
			foreach ( $out->getIndicators() as $indicatorId => $indicatorContent ) {
				echo Html::rawElement( 'div', [ 'class' => 'mw-indicator', 'id' => "mw-indicator-$indicatorId" ], $indicatorContent );
			}
		} ?>
		<nav class="rw-page-tabs">
<?php
		$contentNav = $this->data['content_navigation'] ?? [];
		foreach ( ( $contentNav['namespaces'] ?? [] ) as $key => $tab ) {
			if ( !$isAdmin && ( $key === 'talk' || substr( (string)$key, -5 ) === '_talk' ) ) { continue; } // aba "Discussão" só para admin
			$class = 'rw-tab' . ( ( $tab['class'] ?? '' ) === 'selected' ? ' rw-tab-current' : '' );
			// id="ca-$key" -- convenção nativa do MediaWiki (BaseTemplate::
			// makeListItem). Sem isso, scripts do core/extensões que procuram a
			// aba pelo id padrão (ex.: #ca-ve-edit) nunca encontram nada.
			printf( '<a id="ca-%s" href="%s" class="%s">%s</a>' . "\n",
				htmlspecialchars( $key ), htmlspecialchars( $tab['href'] ), $class, htmlspecialchars( $tab['text'] ) );
		}
		$views = $contentNav['views'] ?? [];
		$actions = $contentNav['actions'] ?? [];
		if ( $views || $actions ) {
			echo '<span class="rw-tab-group">' . "\n";
			foreach ( $views as $key => $tab ) {
				// rw-ve-optin: some com a aba "ve-edit" só pra quem NÃO ligou a
				// preferência pessoal (ver $veEnabled acima). Quem ligou vê as
				// duas abas ("Editar" = visual, "Editar código-fonte" = normal).
				if ( $key === 've-edit' && !$veEnabled ) { continue; }
				$extraClass = $key === 'edit' ? ' rw-tab-edit' : '';
				// Só força o rótulo "Editar" na aba de código-fonte quando a aba
				// do VE está escondida (senão as duas ficariam com o mesmo
				// texto) -- com o VE visível, cada aba usa o rótulo natural que
				// o MediaWiki já dá ("Editar" pro VE, "Editar código-fonte" pro
				// resto).
				$text = ( $key === 'edit' && !$veEnabled ) ? 'Editar' : ( $tab['text'] ?? '' );
				// id="ca-$key" -- mesma convenção nativa acima. É esse id
				// (ca-ve-edit / ca-edit) que o JS do VisualEditor procura no DOM
				// pra saber que a aba existe e ligar o clique nela / decidir se
				// auto-ativa ao carregar com ?veaction=edit na URL. Sem ele, o
				// VE nunca ativava -- nem clicando na aba, nem via URL direta.
				printf( '<a id="ca-%s" href="%s" class="rw-tab%s">%s</a>' . "\n",
					htmlspecialchars( $key ), htmlspecialchars( $tab['href'] ), $extraClass, htmlspecialchars( $text ) );
			}
			if ( $actions ) {
				echo '<div class="rw-personal-dropdown rw-tab-more">' . "\n";
				echo '<button type="button" class="rw-personal-dropdown-toggle rw-tab" aria-expanded="false">Mais <span class="rw-collapse-chevron">▾</span></button>' . "\n";
				echo '<ul class="rw-personal-dropdown-menu">' . "\n";
				foreach ( $actions as $key => $tab ) {
					printf( '<li id="ca-%s"><a href="%s">%s</a></li>' . "\n",
						htmlspecialchars( $key ), htmlspecialchars( $tab['href'] ), htmlspecialchars( $tab['text'] ) );
				}
				echo '</ul></div>' . "\n";
			}
			echo '</span>' . "\n";
		}
?>
		</nav>

		<h1 id="firstHeading" class="firstHeading"><?php $this->html( 'title' ) ?></h1>

		<?php if ( $this->data['subtitle'] ?? '' ) { ?>
		<p class="rw-subtitle" id="contentSub"><?php $this->html( 'subtitle' ) ?></p>
		<?php } ?>

		<?php if ( $this->data['undelete'] ?? '' ) { ?>
		<div id="contentSub2"><?php $this->html( 'undelete' ) ?></div>
		<?php } ?>

		<?php if ( $this->data['newtalk'] ?? '' ) { ?>
		<div class="usermessage"><?php $this->html( 'newtalk' ) ?></div>
		<?php } ?>

		<?php if ( $this->data['sitenotice'] ?? '' ) { ?>
		<div id="siteNotice"><?php $this->html( 'sitenotice' ) ?></div>
		<?php } ?>

		<div id="bodyContent" class="rw-article">
			<?php $this->html( 'bodytext' ) ?>
			<?php if ( $isArticle ) { $this->html( 'catlinks' ); } // "Categorias: ..." só nos artigos ?>
			<?php $this->html( 'dataAfterContent' ) ?>
		</div>
	</main>

	<?php if ( $showTocColumn ) { ?>
	<div class="rw-toc" id="rw-toc-column"></div>
	<?php } ?>
</div>


<div id="footer">
<?php foreach ( $this->getFooterLinks() as $category => $links ) { ?>
	<ul id="footer-<?php echo htmlspecialchars( $category ) ?>">
		<?php foreach ( $links as $key ) { ?>
		<li id="footer-<?php echo htmlspecialchars( $category . '-' . $key ) ?>"><?php echo $this->get( $key ) ?></li>
		<?php } ?>
	</ul>
<?php } ?>
</div>
<?php
	// MediaWiki 1.43: este template gera SÓ o conteúdo do <body>. NÃO chamar
	// printTrail() (foi removido do BaseTemplate -> "Call to undefined method
	// ReligioWikiTemplate::printTrail()", a causa do erro 500 em TODA página)
	// nem fechar </body></html> aqui: o Skin::outputPageFinal() já envolve a
	// saída deste execute() com OutputPage::headElement() (topo, incl.
	// <html><head><body>) e OutputPage::tailElement() (scripts do rodapé via
	// getBottomScripts() + </body></html>). Fechar aqui duplicaria as tags e
	// jogaria os scripts do rodapé pra fora do <html>.
	}
}
