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
		$isMainPage = $title && $title->isMainPage();
		// "Admin" = quem tem o direito editinterface (grupos Administradores /
		// Administradores da interface). Usado pra esconder itens só de admin
		// na lateral e a aba "Discussão" pra quem não é admin.
		$isAdmin = $skin->getAuthority()->isAllowed( 'editinterface' );
		// Itens da lateral (MediaWiki:Sidebar) que só admin deve ver — casados
		// pelo rótulo exato definido no wikitext da sidebar.
		$adminOnlySidebar = [ 'Criar novo artigo', 'Mudanças recentes', 'Gerenciar editores' ];
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
							if ( !$isAdmin && is_array( $link ) && in_array( $link['text'] ?? '', $adminOnlySidebar, true ) ) { continue; } // só admin: Criar novo artigo / Mudanças recentes / Gerenciar editores
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
			printf( '<a href="%s" class="%s">%s</a>' . "\n",
				htmlspecialchars( $tab['href'] ), $class, htmlspecialchars( $tab['text'] ) );
		}
		$views = $contentNav['views'] ?? [];
		$actions = $contentNav['actions'] ?? [];
		if ( $views || $actions ) {
			echo '<span class="rw-tab-group">' . "\n";
			foreach ( $views as $key => $tab ) {
				$extraClass = $key === 'edit' ? ' rw-tab-edit' : '';
				printf( '<a href="%s" class="rw-tab%s">%s</a>' . "\n",
					htmlspecialchars( $tab['href'] ), $extraClass, htmlspecialchars( $tab['text'] ) );
			}
			if ( $actions ) {
				echo '<div class="rw-personal-dropdown rw-tab-more">' . "\n";
				echo '<button type="button" class="rw-personal-dropdown-toggle rw-tab" aria-expanded="false">Mais <span class="rw-collapse-chevron">▾</span></button>' . "\n";
				echo '<ul class="rw-personal-dropdown-menu">' . "\n";
				foreach ( $actions as $key => $tab ) {
					printf( '<li><a href="%s">%s</a></li>' . "\n",
						htmlspecialchars( $tab['href'] ), htmlspecialchars( $tab['text'] ) );
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

	<?php if ( $isArticle ) { ?>
	<div class="rw-toc" id="rw-toc-column"></div>
	<?php } ?>
</div>

<button type="button" id="rw-hamburger" aria-label="Abrir menu de navegação">☰</button>

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
