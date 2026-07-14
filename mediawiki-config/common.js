/*
 * Religio Wiki — MediaWiki:Common.js
 * Cole em Special:MediaWiki:Common.js. Adiciona um seletor de tema
 * (claro / escuro / personalizado) na barra pessoal do skin Vector,
 * persistido em localStorage — funciona também para leitores anônimos.
 */
( function () {
	'use strict';

	var STORAGE_KEY = 'rw-theme';
	var STORAGE_CUSTOM_KEY = 'rw-theme-custom';
	var root = document.documentElement;

	function applyTheme( theme ) {
		root.setAttribute( 'data-theme', theme );
	}

	function applyCustomVars( vars ) {
		Object.keys( vars ).forEach( function ( key ) {
			root.style.setProperty( '--rw-custom-' + key, vars[ key ] );
		} );
	}

	function loadCustomVars() {
		try {
			return JSON.parse( localStorage.getItem( STORAGE_CUSTOM_KEY ) ) || {};
		} catch ( e ) {
			return {};
		}
	}

	function saveCustomVars( vars ) {
		localStorage.setItem( STORAGE_CUSTOM_KEY, JSON.stringify( vars ) );
	}

	// Aplica o tema salvo o quanto antes (evita flash do tema errado).
	var savedTheme = localStorage.getItem( STORAGE_KEY ) || 'light';
	applyTheme( savedTheme );
	if ( savedTheme === 'custom' ) {
		applyCustomVars( loadCustomVars() );
	}

	function buildSwitcher() {
		var container = document.createElement( 'div' );
		container.id = 'rw-theme-switcher';

		var themes = [
			{ id: 'light', label: 'Claro' },
			{ id: 'dark', label: 'Escuro' },
			{ id: 'custom', label: 'Personalizado' }
		];

		var buttons = {};

		themes.forEach( function ( t ) {
			var btn = document.createElement( 'button' );
			btn.type = 'button';
			btn.textContent = t.label;
			btn.setAttribute( 'aria-pressed', String( t.id === savedTheme ) );
			btn.addEventListener( 'click', function () {
				savedTheme = t.id;
				localStorage.setItem( STORAGE_KEY, t.id );
				applyTheme( t.id );
				Object.keys( buttons ).forEach( function ( id ) {
					buttons[ id ].setAttribute( 'aria-pressed', String( id === t.id ) );
				} );
				panel.classList.toggle( 'open', t.id === 'custom' );
				if ( t.id === 'custom' ) {
					applyCustomVars( loadCustomVars() );
				}
			} );
			buttons[ t.id ] = btn;
			container.appendChild( btn );
		} );

		var panel = document.createElement( 'div' );
		panel.id = 'rw-custom-theme-panel';
		if ( savedTheme === 'custom' ) {
			panel.classList.add( 'open' );
		}

		var fields = [
			{ key: 'bg', label: 'Fundo', fallback: '#FBF3E1' },
			{ key: 'text', label: 'Texto', fallback: '#241C15' },
			{ key: 'link', label: 'Links', fallback: '#92400E' }
		];
		var currentCustom = loadCustomVars();

		fields.forEach( function ( f ) {
			var label = document.createElement( 'label' );
			var span = document.createElement( 'span' );
			span.textContent = f.label;
			var input = document.createElement( 'input' );
			input.type = 'color';
			input.value = currentCustom[ f.key ] || f.fallback;
			input.addEventListener( 'input', function () {
				var vars = loadCustomVars();
				vars[ f.key ] = input.value;
				saveCustomVars( vars );
				if ( savedTheme === 'custom' ) {
					applyCustomVars( vars );
				}
			} );
			label.appendChild( span );
			label.appendChild( input );
			panel.appendChild( label );
		} );

		var wrapper = document.createElement( 'div' );
		wrapper.appendChild( container );
		wrapper.appendChild( panel );
		return wrapper;
	}

	function mount() {
		var personalTools = document.getElementById( 'p-personal' );
		var target = personalTools || document.body;
		target.appendChild( buildSwitcher() );
	}

	if ( document.readyState === 'loading' ) {
		document.addEventListener( 'DOMContentLoaded', mount );
	} else {
		mount();
	}
}() );

/* ===== Pop-up do diagrama de categorias ===== */
( function () {
	'use strict';

	// Mesma estrutura de mediawiki-config/categorias.wikitext. Cores só
	// preenchidas para o que já foi decidido (ver common.css, seção 3);
	// o resto usa o ponto neutro até serem definidas.
	var GROUPS = [
		{
			title: 'I. Xamanismos Hiperbóreos',
			items: [
				{ label: 'Taoismo' },
				{ label: 'Confucionismo' },
				{ label: 'Xintoísmo' },
				{ label: 'Xamanismo Siberiano', related: true },
				{ label: 'Bön', related: true },
				{ label: 'Religião dos Povos Nativos Americanos', related: true }
			]
		},
		{
			title: 'II. Mitologias Arianas',
			items: [
				{ label: 'Hinduísmo' },
				{ label: 'Budismo' },
				{ label: 'Religião Greco-Romana (extinta)', related: true },
				{ label: 'Religião Germano-Céltica Antiga (extinta)', related: true },
				{ label: 'Jainismo', related: true },
				{ label: 'Zoroastrismo', related: true }
			]
		},
		{
			title: 'III. Monoteísmos Semíticos',
			items: [
				{ label: 'Judaísmo' },
				{ label: 'Cristianismo', color: '#DC2626' },
				{ label: 'Islã', color: '#15803D' }
			]
		}
	];

	function buildDiagram() {
		var wrap = document.createElement( 'div' );
		wrap.className = 'rw-diagram-groups';

		GROUPS.forEach( function ( group ) {
			var col = document.createElement( 'div' );
			col.className = 'rw-diagram-group';

			var h3 = document.createElement( 'h3' );
			h3.textContent = group.title;
			col.appendChild( h3 );

			var list = document.createElement( 'div' );
			list.className = 'rw-diagram-items';

			group.items.forEach( function ( item ) {
				var row = document.createElement( 'div' );
				row.className = 'rw-diagram-item' + ( item.related ? ' rw-diagram-related' : '' );

				var dot = document.createElement( 'span' );
				dot.className = 'rw-diagram-dot';
				if ( item.color ) {
					dot.style.background = item.color;
				}
				row.appendChild( dot );

				var label = document.createElement( 'span' );
				label.textContent = item.label;
				row.appendChild( label );

				list.appendChild( row );
			} );

			col.appendChild( list );
			wrap.appendChild( col );
		} );

		return wrap;
	}

	function buildOverlay() {
		var overlay = document.createElement( 'div' );
		overlay.id = 'rw-diagram-overlay';

		var modal = document.createElement( 'div' );
		modal.className = 'rw-diagram-modal';
		modal.setAttribute( 'role', 'dialog' );
		modal.setAttribute( 'aria-modal', 'true' );
		modal.setAttribute( 'aria-labelledby', 'rw-diagram-title' );

		var closeBtn = document.createElement( 'button' );
		closeBtn.type = 'button';
		closeBtn.className = 'rw-diagram-close';
		closeBtn.textContent = 'Fechar ✕';
		closeBtn.addEventListener( 'click', function () { close(); } );

		var h2 = document.createElement( 'h2' );
		h2.id = 'rw-diagram-title';
		h2.textContent = 'Classificação das religiões';

		var subtitle = document.createElement( 'p' );
		subtitle.className = 'rw-diagram-subtitle';
		subtitle.textContent = 'Estrutura de categorias da Religio Wiki, em três grandes grupos.';

		modal.appendChild( closeBtn );
		modal.appendChild( h2 );
		modal.appendChild( subtitle );
		modal.appendChild( buildDiagram() );
		overlay.appendChild( modal );

		function close() {
			overlay.classList.remove( 'open' );
			document.removeEventListener( 'keydown', onKeydown );
		}
		function onKeydown( e ) {
			if ( e.key === 'Escape' ) { close(); }
		}
		overlay.addEventListener( 'click', function ( e ) {
			if ( e.target === overlay ) { close(); }
		} );

		overlay.rwOpen = function () {
			overlay.classList.add( 'open' );
			document.addEventListener( 'keydown', onKeydown );
			closeBtn.focus();
		};

		return overlay;
	}

	function mount() {
		var sidebarPortlets = document.querySelectorAll( '.mw-portlet, #mw-panel .portal' );
		if ( sidebarPortlets.length === 0 ) {
			return;
		}
		var lastPortlet = sidebarPortlets[ sidebarPortlets.length - 1 ];

		var overlay = buildOverlay();
		document.body.appendChild( overlay );

		var button = document.createElement( 'button' );
		button.type = 'button';
		button.id = 'rw-diagram-button';
		button.textContent = 'Ver diagrama de categorias';
		button.addEventListener( 'click', function () { overlay.rwOpen(); } );

		lastPortlet.parentNode.insertBefore( button, lastPortlet.nextSibling );
	}

	if ( document.readyState === 'loading' ) {
		document.addEventListener( 'DOMContentLoaded', mount );
	} else {
		mount();
	}
}() );

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
