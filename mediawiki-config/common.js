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

/* ===== Painel "Aparência" (tamanho de texto / largura) ===== */
( function () {
	'use strict';

	var TEXT_KEY = 'rw-textsize';
	var WIDTH_KEY = 'rw-width';
	var html = document.documentElement;

	function apply() {
		html.setAttribute( 'data-rw-textsize', localStorage.getItem( TEXT_KEY ) || 'standard' );
		html.setAttribute( 'data-rw-width', localStorage.getItem( WIDTH_KEY ) || 'standard' );
	}
	apply();

	function buildGroup( label, key, options, storageKey ) {
		var group = document.createElement( 'div' );
		group.className = 'rw-appearance-group';

		var span = document.createElement( 'span' );
		span.className = 'rw-appearance-group-label';
		span.textContent = label;
		group.appendChild( span );

		var row = document.createElement( 'div' );
		row.className = 'rw-appearance-options';
		var current = localStorage.getItem( storageKey ) || options[ 0 ].id;
		var buttons = {};

		options.forEach( function ( opt ) {
			var btn = document.createElement( 'button' );
			btn.type = 'button';
			btn.textContent = opt.label;
			btn.setAttribute( 'aria-pressed', String( opt.id === current ) );
			btn.addEventListener( 'click', function () {
				localStorage.setItem( storageKey, opt.id );
				html.setAttribute( key, opt.id );
				Object.keys( buttons ).forEach( function ( id ) {
					buttons[ id ].setAttribute( 'aria-pressed', String( id === opt.id ) );
				} );
			} );
			buttons[ opt.id ] = btn;
			row.appendChild( btn );
		} );

		group.appendChild( row );
		return group;
	}

	function mount() {
		// Só dentro de artigo (namespace principal) — em qualquer outra
		// página (Religio Wiki:Doar, Special:, etc.) isso não aparece.
		if ( typeof mw !== 'undefined' && mw.config && mw.config.get( 'wgNamespaceNumber' ) !== 0 ) {
			return;
		}
		var toc = document.getElementById( 'toc' );
		if ( !toc ) {
			return; // páginas sem índice (ex.: __NOTOC__ na principal/Doar) não têm isso
		}

		// "Neste artigo" e "Aparência" ficam fixos (sticky) juntos ao rolar a
		// tela — cria um wrapper flutuante, move o índice nativo pra dentro
		// dele e injeta o painel logo abaixo. common.css, seção 8.
		var wrapper = document.createElement( 'div' );
		wrapper.className = 'rw-toc-sticky';
		toc.parentNode.insertBefore( wrapper, toc );
		wrapper.appendChild( toc );

		var panel = document.createElement( 'div' );
		panel.className = 'rw-appearance-panel';

		var h2 = document.createElement( 'h2' );
		h2.textContent = 'Aparência';
		panel.appendChild( h2 );

		panel.appendChild( buildGroup( 'Texto', 'data-rw-textsize', [
			{ id: 'small', label: 'Pequeno' },
			{ id: 'standard', label: 'Padrão' },
			{ id: 'large', label: 'Grande' }
		], TEXT_KEY ) );

		panel.appendChild( buildGroup( 'Largura', 'data-rw-width', [
			{ id: 'standard', label: 'Padrão' },
			{ id: 'wide', label: 'Largo' }
		], WIDTH_KEY ) );

		wrapper.appendChild( panel );
	}

	if ( document.readyState === 'loading' ) {
		document.addEventListener( 'DOMContentLoaded', mount );
	} else {
		mount();
	}
}() );

/* ===== Seletor de idioma do artigo ===== */
( function () {
	'use strict';

	// Convenção de sub-página (Título/en, Título/es...), não o sistema de
	// interwiki multi-site da Wikipédia real (ver README). Lista base —
	// $wgReligioWikiLanguages no LocalSettings controla o mesmo conjunto
	// do lado do servidor; mantenha os dois sincronizados ao adicionar
	// idioma novo.
	var LANGUAGES = [
		{ code: 'en', label: 'English' },
		{ code: 'es', label: 'Español' },
		{ code: 'fr', label: 'Français' },
		{ code: 'it', label: 'Italiano' }
	];

	function baseTitle( pageName ) {
		var parts = pageName.split( '/' );
		var codes = LANGUAGES.map( function ( l ) { return l.code; } );
		if ( parts.length > 1 && codes.indexOf( parts[ parts.length - 1 ] ) !== -1 ) {
			parts.pop();
		}
		return parts.join( '/' );
	}

	function mount() {
		if ( typeof mw === 'undefined' || !mw.config || mw.config.get( 'wgNamespaceNumber' ) !== 0 ) {
			return; // só em artigos (namespace principal)
		}
		var toc = document.getElementById( 'toc' );
		if ( !toc ) {
			return;
		}

		var base = baseTitle( mw.config.get( 'wgPageName' ) );
		var currentCode = mw.config.get( 'wgPageName' ) === base ? 'pt' : mw.config.get( 'wgPageName' ).split( '/' ).pop();

		// Estilo collapse: fechado por padrão, some dos olhos até o leitor
		// pedir; abre com o próprio idioma atual sempre visível no rótulo.
		var box = document.createElement( 'div' );
		box.className = 'rw-lang-switcher';

		var toggle = document.createElement( 'button' );
		toggle.type = 'button';
		toggle.className = 'rw-lang-toggle';
		toggle.setAttribute( 'aria-expanded', 'false' );
		var toggleLabel = document.createElement( 'span' );
		toggleLabel.textContent = 'Idiomas';
		var chevron = document.createElement( 'span' );
		chevron.className = 'rw-lang-chevron';
		chevron.textContent = '▾';
		toggle.appendChild( toggleLabel );
		toggle.appendChild( chevron );
		toggle.addEventListener( 'click', function () {
			var isOpen = box.classList.toggle( 'open' );
			toggle.setAttribute( 'aria-expanded', String( isOpen ) );
		} );
		box.appendChild( toggle );

		var body = document.createElement( 'div' );
		body.className = 'rw-lang-body';
		box.appendChild( body );

		var list = document.createElement( 'ul' );
		list.className = 'rw-lang-list';

		var ptLi = document.createElement( 'li' );
		var ptLink = document.createElement( 'a' );
		ptLink.href = mw.util.getUrl( base );
		ptLink.textContent = 'Português (original)';
		if ( currentCode === 'pt' ) {
			ptLink.className = 'rw-lang-current';
		}
		ptLi.appendChild( ptLink );
		list.appendChild( ptLi );

		mw.loader.using( 'mediawiki.api' ).then( function () {
			var api = new mw.Api();
			var titles = LANGUAGES.map( function ( l ) { return base + '/' + l.code; } );
			api.get( {
				action: 'query',
				titles: titles.join( '|' ),
				format: 'json'
			} ).done( function ( data ) {
				var existing = {};
				if ( data.query && data.query.pages ) {
					Object.keys( data.query.pages ).forEach( function ( id ) {
						var page = data.query.pages[ id ];
						if ( !page.missing ) {
							existing[ page.title ] = true;
						}
					} );
				}
				LANGUAGES.forEach( function ( lang ) {
					var title = base + '/' + lang.code;
					var li = document.createElement( 'li' );
					var a = document.createElement( 'a' );
					a.href = mw.util.getUrl( title );
					a.textContent = lang.label;
					if ( lang.code === currentCode ) {
						a.className = 'rw-lang-current';
					} else if ( !existing[ title ] ) {
						a.className = 'rw-lang-missing';
						a.title = 'Ainda não existe — clique para criar a tradução';
					}
					li.appendChild( a );
					list.appendChild( li );
				} );

				var addLink = document.createElement( 'a' );
				addLink.className = 'rw-lang-add';
				addLink.href = mw.util.getUrl( 'Religio Wiki:Idiomas' );
				addLink.textContent = '+ Adicionar idioma';
				body.appendChild( list );
				body.appendChild( addLink );
			} );
		} );

		toc.parentNode.insertBefore( box, toc );
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

/* ===== Ícone de lápis ao lado do título (quem pode editar) ===== */
( function () {
	'use strict';

	function mount() {
		if ( !document.body.classList.contains( 'rw-can-edit' ) ) {
			return; // hook OutputPageBodyAttributes só marca isso pra quem tem edit
		}
		var heading = document.getElementById( 'firstHeading' );
		if ( !heading || typeof mw === 'undefined' ) {
			return;
		}
		var link = document.createElement( 'a' );
		link.className = 'rw-edit-pencil';
		link.href = mw.util.getUrl( mw.config.get( 'wgPageName' ), { action: 'edit' } );
		link.title = 'Editar esta página';
		link.textContent = '✏️';
		heading.appendChild( link );
	}

	if ( document.readyState === 'loading' ) {
		document.addEventListener( 'DOMContentLoaded', mount );
	} else {
		mount();
	}
}() );

/* ===== Menu hambúrguer (barra lateral em tela estreita) ===== */
( function () {
	'use strict';

	function mount() {
		var panel = document.getElementById( 'mw-panel' );
		if ( !panel ) {
			return;
		}

		var overlay = document.createElement( 'div' );
		overlay.id = 'rw-sidebar-overlay';
		document.body.appendChild( overlay );

		var btn = document.createElement( 'button' );
		btn.type = 'button';
		btn.id = 'rw-hamburger';
		btn.setAttribute( 'aria-label', 'Abrir menu de navegação' );
		btn.setAttribute( 'aria-expanded', 'false' );
		btn.textContent = '☰';
		document.body.appendChild( btn );

		function close() {
			panel.classList.remove( 'rw-sidebar-open' );
			overlay.classList.remove( 'rw-sidebar-open' );
			btn.setAttribute( 'aria-expanded', 'false' );
		}
		function toggle() {
			var isOpen = panel.classList.toggle( 'rw-sidebar-open' );
			overlay.classList.toggle( 'rw-sidebar-open', isOpen );
			btn.setAttribute( 'aria-expanded', String( isOpen ) );
		}
		btn.addEventListener( 'click', toggle );
		overlay.addEventListener( 'click', close );
		document.addEventListener( 'keydown', function ( e ) {
			if ( e.key === 'Escape' ) {
				close();
			}
		} );
		// Fecha ao navegar por um link do menu (evita ficar aberto na próxima página).
		panel.addEventListener( 'click', function ( e ) {
			if ( e.target.tagName === 'A' ) {
				close();
			}
		} );

		collapsePortlets( panel );
	}

	// Cada bloco da lateral (ex.: "Categorias", "Navegação") vira um
	// collapse/accordion fechado por padrão — é o que deixa o menu
	// compacto em vez de uma lista comprida exigindo rolar bastante.
	function collapsePortlets( panel ) {
		var portlets = panel.querySelectorAll( '.portal, .mw-portlet, [id^="p-"]' );
		portlets.forEach( function ( portlet ) {
			var heading = portlet.querySelector( 'h3, h2' );
			var body = portlet.querySelector( '.body' ) || portlet.querySelector( 'ul' );
			if ( !heading || !body || heading.dataset.rwCollapseDone ) {
				return;
			}
			heading.dataset.rwCollapseDone = '1';

			var toggle = document.createElement( 'button' );
			toggle.type = 'button';
			toggle.className = 'rw-collapse-toggle';
			toggle.setAttribute( 'aria-expanded', 'false' );

			var label = document.createElement( 'span' );
			label.textContent = heading.textContent;
			var chevron = document.createElement( 'span' );
			chevron.className = 'rw-collapse-chevron';
			chevron.textContent = '▾';
			toggle.appendChild( label );
			toggle.appendChild( chevron );

			heading.textContent = '';
			heading.appendChild( toggle );

			body.style.display = 'none';
			toggle.addEventListener( 'click', function () {
				var isOpen = body.style.display !== 'none';
				body.style.display = isOpen ? 'none' : '';
				toggle.setAttribute( 'aria-expanded', String( !isOpen ) );
			} );
		} );
	}

	if ( document.readyState === 'loading' ) {
		document.addEventListener( 'DOMContentLoaded', mount );
	} else {
		mount();
	}
}() );

/* ===== Marca no cabeçalho ===== */
( function () {
	'use strict';

	// #p-logo vive na barra lateral no Vector legado, não no cabeçalho, e
	// hoje não há arquivo de logo configurado ($wgLogo) — common.css (seção
	// 7) esconde o placeholder vazio. Em vez de mover o nó vazio, injeta o
	// mesmo círculo+texto do artefato de referência como primeiro filho de
	// #mw-head. Troque por um <img> de verdade quando houver logo.
	function mount() {
		var head = document.getElementById( 'mw-head' );
		if ( !head || document.querySelector( '.rw-brand' ) ) {
			return;
		}

		var link = document.createElement( 'a' );
		link.className = 'rw-brand';
		link.href = ( typeof mw !== 'undefined' && mw.util ) ? mw.util.getUrl( '' ) : '/';

		var mark = document.createElement( 'span' );
		mark.className = 'rw-brand-mark';
		mark.textContent = 'R';
		mark.setAttribute( 'aria-hidden', 'true' );
		link.appendChild( mark );

		var label = document.createElement( 'span' );
		label.textContent = ( typeof mw !== 'undefined' && mw.config ) ? mw.config.get( 'wgSiteName' ) : 'Religio Wiki';
		link.appendChild( label );

		head.insertBefore( link, head.firstChild );
	}

	if ( document.readyState === 'loading' ) {
		document.addEventListener( 'DOMContentLoaded', mount );
	} else {
		mount();
	}
}() );

/* ===== Ícones dos controles de página (Ler / Ver código-fonte / Ver histórico) ===== */
( function () {
	'use strict';

	// Só troca o texto por ícone — href e funcionamento nativo do MediaWiki
	// ficam intactos. O texto original vira tooltip (title=), sem perder
	// acessibilidade nem informação pra quem não vê o ícone. Contas com
	// permissão de editar veem "ca-edit" em vez de "ca-viewsource" (não
	// coberto aqui de propósito — fora do escopo pedido, e o link nativo
	// continua funcionando normalmente como texto).
	var ICONS = {
		'ca-view': [ '📖', 'Ler' ],
		'ca-viewsource': [ '</>', 'Ver código-fonte' ],
		'ca-history': [ '🕘', 'Ver histórico' ]
	};

	function mount() {
		Object.keys( ICONS ).forEach( function ( id ) {
			var li = document.getElementById( id );
			if ( !li ) {
				return;
			}
			var a = li.querySelector( 'a' );
			if ( !a || a.classList.contains( 'rw-icon-action' ) ) {
				return;
			}
			var icon = ICONS[ id ][ 0 ];
			var text = ICONS[ id ][ 1 ];
			a.title = a.title || text;
			a.setAttribute( 'aria-label', text );
			a.classList.add( 'rw-icon-action' );
			a.textContent = icon;
		} );
	}

	if ( document.readyState === 'loading' ) {
		document.addEventListener( 'DOMContentLoaded', mount );
	} else {
		mount();
	}
}() );

/* ===== Pop-up de login / criar conta ===== */
( function () {
	'use strict';

	// mw.config.get('wgRWSocialProviders') é exposto pelo hook
	// ResourceLoaderGetConfigVars em LocalSettings-snippet.php, conforme o
	// que estiver de fato configurado (PluggableAuth + conector de cada
	// provedor) — sem isso configurado, os botões ficam desabilitados.
	var SOCIAL_PROVIDERS = [
		{ id: 'google', label: 'Continuar com Google' },
		{ id: 'facebook', label: 'Continuar com Facebook' },
		{ id: 'github', label: 'Continuar com GitHub' }
	];

	var overlay = null;
	var loginPanel, createPanel, loginError, createError, loginSubmit, createSubmit;

	function apiCall( tokenType, action, extraParams ) {
		return mw.loader.using( 'mediawiki.api' ).then( function () {
			var api = new mw.Api();
			return api.getToken( tokenType ).then( function ( token ) {
				var params = Object.assign( {
					action: action,
					format: 'json'
				}, extraParams );
				params[ tokenType === 'login' ? 'logintoken' : 'createtoken' ] = token;
				return api.post( params );
			} );
		} );
	}

	function buildField( labelText, type, name ) {
		var label = document.createElement( 'label' );
		label.className = 'rw-auth-field';
		var span = document.createElement( 'span' );
		span.textContent = labelText;
		var input = document.createElement( 'input' );
		input.type = type;
		input.name = name;
		input.autocomplete = type === 'password' ? 'current-password' : 'username';
		label.appendChild( span );
		label.appendChild( input );
		return { label: label, input: input };
	}

	function buildSocialButtons() {
		var wrap = document.createElement( 'div' );
		wrap.className = 'rw-auth-social';
		var configured = ( typeof mw !== 'undefined' && mw.config.get( 'wgRWSocialProviders' ) ) || [];

		SOCIAL_PROVIDERS.forEach( function ( p ) {
			var btn = document.createElement( 'button' );
			btn.type = 'button';
			btn.textContent = p.label;
			if ( configured.indexOf( p.id ) === -1 ) {
				btn.disabled = true;
				btn.title = 'Não configurado ainda — ver PluggableAuth em LocalSettings.php';
			} else {
				btn.addEventListener( 'click', function () {
					location.href = mw.util.getUrl( 'Special:UserLogin', {
						returnto: mw.config.get( 'wgPageName' )
					} );
				} );
			}
			wrap.appendChild( btn );
		} );
		return wrap;
	}

	function buildLoginPanel() {
		var panel = document.createElement( 'div' );
		panel.id = 'rw-auth-login';

		panel.appendChild( buildSocialButtons() );
		var divider = document.createElement( 'div' );
		divider.className = 'rw-auth-divider';
		divider.textContent = 'ou com usuário e senha';
		panel.appendChild( divider );

		loginError = document.createElement( 'p' );
		loginError.className = 'rw-auth-error';
		loginError.style.display = 'none';
		panel.appendChild( loginError );

		var user = buildField( 'Nome de usuário', 'text', 'username' );
		var pass = buildField( 'Senha', 'password', 'password' );
		panel.appendChild( user.label );
		panel.appendChild( pass.label );

		loginSubmit = document.createElement( 'button' );
		loginSubmit.type = 'button';
		loginSubmit.className = 'rw-auth-submit';
		loginSubmit.textContent = 'Entrar';
		loginSubmit.addEventListener( 'click', function () {
			loginError.style.display = 'none';
			if ( !user.input.value || !pass.input.value ) {
				loginError.textContent = 'Preencha usuário e senha.';
				loginError.style.display = 'block';
				return;
			}
			loginSubmit.disabled = true;
			apiCall( 'login', 'clientlogin', {
				username: user.input.value,
				password: pass.input.value,
				loginreturnurl: location.href
			} ).done( function ( data ) {
				var status = data.clientlogin && data.clientlogin.status;
				if ( status === 'PASS' ) {
					location.reload();
				} else {
					loginSubmit.disabled = false;
					loginError.textContent = ( data.clientlogin && data.clientlogin.message ) ||
						'Não foi possível entrar. Confira usuário e senha, ou use Special:UserLogin diretamente.';
					loginError.style.display = 'block';
				}
			} ).fail( function () {
				loginSubmit.disabled = false;
				loginError.textContent = 'Erro de conexão com o servidor. Tente novamente.';
				loginError.style.display = 'block';
			} );
		} );
		panel.appendChild( loginSubmit );

		return panel;
	}

	function buildCreatePanel() {
		var panel = document.createElement( 'div' );
		panel.id = 'rw-auth-create';
		panel.style.display = 'none';

		panel.appendChild( buildSocialButtons() );
		var divider = document.createElement( 'div' );
		divider.className = 'rw-auth-divider';
		divider.textContent = 'ou crie com usuário e senha';
		panel.appendChild( divider );

		createError = document.createElement( 'p' );
		createError.className = 'rw-auth-error';
		createError.style.display = 'none';
		panel.appendChild( createError );

		var user = buildField( 'Nome de usuário', 'text', 'username' );
		var pass = buildField( 'Senha', 'password', 'password' );
		var retype = buildField( 'Confirme a senha', 'password', 'retype' );
		var email = buildField( 'E-mail (opcional)', 'email', 'email' );
		[ user, pass, retype, email ].forEach( function ( f ) { panel.appendChild( f.label ); } );

		createSubmit = document.createElement( 'button' );
		createSubmit.type = 'button';
		createSubmit.className = 'rw-auth-submit';
		createSubmit.textContent = 'Criar conta';
		createSubmit.addEventListener( 'click', function () {
			createError.style.display = 'none';
			if ( !user.input.value || !pass.input.value ) {
				createError.textContent = 'Preencha usuário e senha.';
				createError.style.display = 'block';
				return;
			}
			if ( pass.input.value !== retype.input.value ) {
				createError.textContent = 'As senhas não coincidem.';
				createError.style.display = 'block';
				return;
			}
			createSubmit.disabled = true;
			apiCall( 'createaccount', 'createaccount', {
				username: user.input.value,
				password: pass.input.value,
				retype: retype.input.value,
				email: email.input.value,
				createreturnurl: location.href
			} ).done( function ( data ) {
				var status = data.createaccount && data.createaccount.status;
				if ( status === 'PASS' ) {
					location.reload();
				} else {
					createSubmit.disabled = false;
					createError.textContent = ( data.createaccount && data.createaccount.message ) ||
						'Não foi possível criar a conta. Tente Special:CreateAccount diretamente.';
					createError.style.display = 'block';
				}
			} ).fail( function () {
				createSubmit.disabled = false;
				createError.textContent = 'Erro de conexão com o servidor. Tente novamente.';
				createError.style.display = 'block';
			} );
		} );
		panel.appendChild( createSubmit );

		return panel;
	}

	function setTab( tab, tabButtons ) {
		var isLogin = tab === 'login';
		loginPanel.style.display = isLogin ? 'block' : 'none';
		createPanel.style.display = isLogin ? 'none' : 'block';
		tabButtons.login.setAttribute( 'aria-selected', String( isLogin ) );
		tabButtons.create.setAttribute( 'aria-selected', String( !isLogin ) );
	}

	function buildOverlay() {
		var ov = document.createElement( 'div' );
		ov.id = 'rw-auth-overlay';

		var modal = document.createElement( 'div' );
		modal.className = 'rw-auth-modal';
		modal.setAttribute( 'role', 'dialog' );
		modal.setAttribute( 'aria-modal', 'true' );

		var closeBtn = document.createElement( 'button' );
		closeBtn.type = 'button';
		closeBtn.className = 'rw-auth-close';
		closeBtn.textContent = 'Fechar ✕';
		closeBtn.addEventListener( 'click', function () { close(); } );
		modal.appendChild( closeBtn );

		var tabs = document.createElement( 'div' );
		tabs.className = 'rw-auth-tabs';
		var loginTab = document.createElement( 'button' );
		loginTab.type = 'button';
		loginTab.textContent = 'Entrar';
		var createTab = document.createElement( 'button' );
		createTab.type = 'button';
		createTab.textContent = 'Criar conta';
		var tabButtons = { login: loginTab, create: createTab };
		loginTab.addEventListener( 'click', function () { setTab( 'login', tabButtons ); } );
		createTab.addEventListener( 'click', function () { setTab( 'create', tabButtons ); } );
		tabs.appendChild( loginTab );
		tabs.appendChild( createTab );
		modal.appendChild( tabs );

		loginPanel = buildLoginPanel();
		createPanel = buildCreatePanel();
		modal.appendChild( loginPanel );
		modal.appendChild( createPanel );

		var note = document.createElement( 'p' );
		note.className = 'rw-auth-note';
		note.textContent = 'Sua conta não dá direito de editar por padrão — só quem for ' +
			'adicionado ao grupo "editor" por um administrador consegue criar/editar página.';
		modal.appendChild( note );

		ov.appendChild( modal );

		function close() {
			ov.classList.remove( 'open' );
		}
		ov.addEventListener( 'click', function ( e ) {
			if ( e.target === ov ) { close(); }
		} );
		document.addEventListener( 'keydown', function ( e ) {
			if ( e.key === 'Escape' ) { close(); }
		} );

		ov.rwOpen = function ( tab ) {
			setTab( tab || 'login', tabButtons );
			ov.classList.add( 'open' );
		};

		return ov;
	}

	function openModal( tab ) {
		if ( !overlay ) {
			overlay = buildOverlay();
			document.body.appendChild( overlay );
		}
		overlay.rwOpen( tab );
	}

	function mount() {
		if ( typeof mw === 'undefined' ) {
			return;
		}
		var loginLi = document.getElementById( 'pt-login' );
		var createLi = document.getElementById( 'pt-createaccount' );
		[ [ loginLi, 'login' ], [ createLi, 'create' ] ].forEach( function ( pair ) {
			var li = pair[ 0 ];
			if ( !li ) {
				return;
			}
			var a = li.tagName === 'A' ? li : li.querySelector( 'a' );
			if ( a ) {
				a.addEventListener( 'click', function ( e ) {
					e.preventDefault();
					openModal( pair[ 1 ] );
				} );
			}
		} );
	}

	if ( document.readyState === 'loading' ) {
		document.addEventListener( 'DOMContentLoaded', mount );
	} else {
		mount();
	}
}() );
