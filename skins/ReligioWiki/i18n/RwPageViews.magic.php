<?php
/**
 * Palavras mágicas (magic words) das parser functions de RwPageViews —
 * {{#artigoemdestaque:}} e {{#imagemdodia:}} (ver
 * skins/ReligioWiki/includes/RwPageViews.php e
 * mediawiki-config/LocalSettings-snippet.php).
 *
 * Formato legado ($wgExtensionMessagesFiles em vez do "MagicWords" do
 * extension.json moderno) porque isso não é uma extensão registrada de
 * verdade — é tudo ganchado direto em LocalSettings.php. Necessário porque
 * Parser::setFunctionHook() chama internamente
 * MagicWordFactory::get( $id ), que EXIGE que $id já exista como magic word
 * registrada — sem isso lança "Error: invalid magic word", e isso acontece
 * pra QUALQUER Parser novo criado no site (não só quando uma página usa de
 * fato {{#artigoemdestaque:}}), derrubando TODA página do wiki com erro
 * fatal. Já aconteceu uma vez em produção — não remover este arquivo nem o
 * registro em $wgExtensionMessagesFiles sem também remover os
 * setFunctionHook() correspondentes.
 */
$magicWords = [];
$magicWords['en'] = [
	'artigoemdestaque' => [ 0, 'artigoemdestaque' ],
	'imagemdodia' => [ 0, 'imagemdodia' ],
];
$magicWords['pt-br'] = [
	'artigoemdestaque' => [ 0, 'artigoemdestaque' ],
	'imagemdodia' => [ 0, 'imagemdodia' ],
];
