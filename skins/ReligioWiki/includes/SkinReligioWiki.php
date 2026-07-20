<?php
/**
 * Skin da Religio Wiki — identidade visual "papel pólen" (retrô), portada
 * diretamente do artefato de prévia (HTML estático) pra um skin de verdade,
 * em vez de reconciliar via Common.css/Common.js em cima do Vector clássico
 * (abordagem anterior, que nunca bateu 100% com o artefato porque o DOM do
 * Vector legado é sutilmente diferente do rw-topbar/rw-layout do mockup).
 *
 * Baseado no contrato clássico SkinTemplate + QuickTemplate (o mesmo usado
 * pelo skin MonoBook, ainda presente no core) em vez de SkinMustache — essa
 * escolha é deliberada: o wiki já roda com sucesso um skin QuickTemplate
 * (Vector clássico, $wgVectorDefaultSkinVersion = '1') nesta mesma instalação
 * MediaWiki 1.43, então essa é a API com prova concreta de funcionar aqui,
 * ao contrário de arriscar detalhes da API mais nova (SkinMustache) sem like
 * ambiente real pra testar contra. Ver docs/SKIN_STATUS.md pros pontos ainda
 * não verificados ao vivo.
 */
class SkinReligioWiki extends SkinTemplate {

	/**
	 * Carrega o CSS/JS do skin em toda página, além do que o SkinTemplate
	 * já enfileira por padrão.
	 */
	public function initPage( OutputPage $out ) {
		parent::initPage( $out );
		// CSS num módulo SÓ de estilos → sai como <link> render-blocking no
		// <head> (não passa pelo carregador assíncrono junto com o JS, que era
		// a causa do "flash de HTML sem CSS"). O JS fica num módulo à parte.
		$out->addModuleStyles( [ 'skins.ReligioWiki.styles' ] );
		$out->addModules( [ 'skins.ReligioWiki' ] );

		// CSS crítico embutido no <head>: dá uma base já estilizada no primeiro
		// paint (fundo, cor de texto, fonte, topo), mesmo que o load.php demore
		// a responder. Elimina o flash de página branca/sem estilo (FOUC). O
		// CSS completo do skin sobrescreve isto assim que carrega.
		$out->addInlineStyle(
			':root{--rw-bg:#FBF3E1;--rw-bg-elevated:#FFFDF7;--rw-text:#241C15;' .
			'--rw-text-muted:#5C5142;--rw-border:#E2D5B8;--rw-link:#92400E}' .
			'html,body{background:var(--rw-bg);color:var(--rw-text)}' .
			'body{font-family:Georgia,"Times New Roman",serif;margin:0}' .
			'.rw-topbar{background:var(--rw-bg-elevated);border-bottom:1px solid var(--rw-border);' .
			'display:flex;align-items:center;gap:16px;padding:8px 20px}' .
			'.rw-layout{max-width:1200px;margin:0 auto}'
		);
	}
}
