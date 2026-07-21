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
		// CSS num módulo SEPARADO (skins.ReligioWiki.styles, só "styles", sem
		// "scripts") carregado via addModuleStyles() -- isso sim vira um
		// <link rel="stylesheet"> de verdade no <head>, bloqueante/síncrono.
		// Antes, com styles+scripts no MESMO módulo "skins.ReligioWiki" e
		// addModuleStyles()+addModules() chamados pra ele, o ResourceLoader
		// tratava o módulo inteiro como "precisa de JS" e MOVIA o CSS junto
		// pro carregamento assíncrono via mw.loader (RLPAGEMODULES) -- a
		// página inteira renderizava SEM estilo nenhum até o JS rodar
		// ("flash of unstyled content", reportado como "CSS demora pra
		// carregar"). O JS (skin.js, com toda a lógica de hambúrguer/tema/
		// Aparência/etc.) continua no módulo "skins.ReligioWiki" original,
		// carregado async como sempre -- só o CSS que precisava virar síncrono.
		$out->addModuleStyles( [ 'skins.ReligioWiki.styles' ] );
		$out->addModules( [ 'skins.ReligioWiki' ] );
	}
}
