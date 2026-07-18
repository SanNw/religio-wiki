/*
 * Religio Wiki — MediaWiki:Common.js
 * Cole em Special:MediaWiki:Common.js.
 *
 * A partir da introdução do skin próprio (skins/ReligioWiki), o seletor de
 * tema, o dropdown da barra pessoal, o menu hambúrguer + colapso de
 * categoria, o painel "Aparência", o índice fixo, o seletor de idioma, o
 * lápis de edição e o pop-up de login/cadastro viraram responsabilidade do
 * skin (skins/ReligioWiki/resources/skin.js) — são comportamento de
 * INTERFACE, acoplado ao DOM que o skin gera, não conteúdo de página.
 *
 * O que sobra aqui é só o widget de doação: comportamento específico da
 * página Religio Wiki:Doar (monta a UI dentro de #rw-donate-widget, que só
 * existe no wikitext dessa página) — continua fazendo sentido como
 * Common.js porque é conteúdo de UMA página, não do site inteiro.
 */

/* ===== Widget da página de doação (Religio Wiki:Doar) ===== */
( function () {
	'use strict';

	var PRESETS = [ 15, 20, 30, 70, 140, 200, 300 ];
	var METHODS = [ 'Pix', 'Cartão de débito', 'Cartão de crédito', 'Boleto', 'PayPal', 'Google Pay' ];

	function mount() {
		var host = document.getElementById( 'rw-donate-widget' );
		if ( !host ) {
			return;
		}

		var state = { frequency: 'unico', amount: 30, method: 'Pix' };

		host.innerHTML = '';

		var h2 = document.createElement( 'h2' );
		h2.textContent = 'Fazer uma doação';
		host.appendChild( h2 );

		var currency = document.createElement( 'p' );
		currency.className = 'rw-donate-currency';
		currency.textContent = 'Montante do donativo (BRL)';
		host.appendChild( currency );

		var tabs = document.createElement( 'div' );
		tabs.className = 'rw-donate-tabs';
		var freqButtons = {};
		[ [ 'unico', 'Único' ], [ 'mensal', 'Mensal' ], [ 'anual', 'Anualmente' ] ].forEach( function ( f ) {
			var btn = document.createElement( 'button' );
			btn.type = 'button';
			btn.textContent = f[ 1 ];
			btn.setAttribute( 'aria-pressed', String( f[ 0 ] === state.frequency ) );
			btn.addEventListener( 'click', function () {
				state.frequency = f[ 0 ];
				Object.keys( freqButtons ).forEach( function ( k ) {
					freqButtons[ k ].setAttribute( 'aria-pressed', String( k === f[ 0 ] ) );
				} );
			} );
			freqButtons[ f[ 0 ] ] = btn;
			tabs.appendChild( btn );
		} );
		host.appendChild( tabs );

		var amounts = document.createElement( 'div' );
		amounts.className = 'rw-donate-amounts';
		var amountButtons = {};
		PRESETS.forEach( function ( value ) {
			var btn = document.createElement( 'button' );
			btn.type = 'button';
			btn.textContent = 'R$ ' + value;
			btn.setAttribute( 'aria-pressed', String( value === state.amount ) );
			btn.addEventListener( 'click', function () {
				state.amount = value;
				customInput.value = '';
				Object.keys( amountButtons ).forEach( function ( k ) {
					amountButtons[ k ].setAttribute( 'aria-pressed', String( Number( k ) === value ) );
				} );
			} );
			amountButtons[ value ] = btn;
			amounts.appendChild( btn );
		} );
		host.appendChild( amounts );

		var customRow = document.createElement( 'div' );
		customRow.className = 'rw-donate-custom';
		var customLabel = document.createElement( 'span' );
		customLabel.textContent = 'Outro: R$';
		var customInput = document.createElement( 'input' );
		customInput.type = 'number';
		customInput.min = '1';
		customInput.placeholder = '0,00';
		customInput.addEventListener( 'input', function () {
			if ( customInput.value ) {
				state.amount = Number( customInput.value );
				Object.keys( amountButtons ).forEach( function ( k ) {
					amountButtons[ k ].setAttribute( 'aria-pressed', 'false' );
				} );
			}
		} );
		customRow.appendChild( customLabel );
		customRow.appendChild( customInput );
		host.appendChild( customRow );

		var methods = document.createElement( 'div' );
		methods.className = 'rw-donate-methods';
		var methodButtons = {};
		METHODS.forEach( function ( name ) {
			var btn = document.createElement( 'button' );
			btn.type = 'button';
			btn.textContent = name;
			btn.setAttribute( 'aria-pressed', String( name === state.method ) );
			btn.addEventListener( 'click', function () {
				state.method = name;
				Object.keys( methodButtons ).forEach( function ( k ) {
					methodButtons[ k ].setAttribute( 'aria-pressed', String( k === name ) );
				} );
			} );
			methodButtons[ name ] = btn;
			methods.appendChild( btn );
		} );
		host.appendChild( methods );

		var note = document.createElement( 'p' );
		note.className = 'rw-donate-note';
		note.textContent = 'Esta é uma prévia da interface de doação — a cobrança de verdade ' +
			'depende de conectar um meio de pagamento real (Pix, gateway de cartão/boleto, ' +
			'PayPal etc.) a esta página, o que ainda não foi feito.';
		host.appendChild( note );
	}

	if ( document.readyState === 'loading' ) {
		document.addEventListener( 'DOMContentLoaded', mount );
	} else {
		mount();
	}
}() );
