/*!
 * Religio Wiki — blinda mw.widgets.visibleByteLimit/visibleCodePointLimit
 * (e variantes com dropdown) contra um TextInputWidget inválido.
 *
 * Causa raiz: o campo "Assinatura" (wpnickname) de Special:Preferences, para
 * contas sem e-mail confirmado, renderiza como um <label> informativo em vez
 * de um TextInputWidget de verdade -- mas resources/src/mediawiki.special.
 * preferences.ooui/signature.js (núcleo do MediaWiki) chama
 * mw.widgets.visibleCodePointLimit() nesse elemento de qualquer forma.
 * OO.ui.infuse() retorna undefined pra esse <label>, e a função interna
 * (internalVisibleLimit) quebra em "Cannot read properties of undefined
 * (reading 'attr')" -- exceção que não é capturada pelo mw.hook, então
 * aborta TODO o resto de enhancePanel()/setSection(), deixando a página de
 * Preferências inteira sem as abas/painéis do OOUI funcionando (cai pro
 * HTML cru, sem estilo, em QUALQUER aba).
 *
 * Este módulo declara 'mediawiki.widgets.visibleLengthLimit' como
 * dependência (ver $wgResourceModules em LocalSettings.php) -- o
 * ResourceLoader GARANTE que essa dependência execute antes deste código,
 * ao contrário de um mw.loader.using(...).then(...) chamado de fora, que é
 * assíncrono demais e perde a corrida (testado ao vivo).
 */
( function () {
	'use strict';
	[
		'visibleByteLimit', 'visibleCodePointLimit',
		'visibleByteLimitWithDropdown', 'visibleCodePointLimitWithDropdown'
	].forEach( function ( name ) {
		var original = mw.widgets[ name ];
		if ( typeof original !== 'function' ) {
			return;
		}
		mw.widgets[ name ] = function ( textInputWidget ) {
			if ( !textInputWidget || !textInputWidget.$input ) {
				return;
			}
			return original.apply( this, arguments );
		};
	} );
}() );
