/*
 * Skin ReligioWiki — resources/skin.js
 * Comportamento portado de mediawiki-config/common.js (que ficava colado em
 * MediaWiki:Common.js) pra dentro do skin — mesma lógica, só retargetada
 * pros ids/classes que ReligioWikiTemplate.php realmente gera. Common.js
 * continua existindo, mas agora só com o que é conteúdo de página de
 * verdade (widget de doação) — ver docs/SKIN_STATUS.md.
 */

/* ===== seletor de tema (claro/escuro/personalizado) ===== */
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

	var savedTheme = localStorage.getItem( STORAGE_KEY ) || 'light';
	applyTheme( savedTheme );
	if ( savedTheme === 'custom' ) {
		applyCustomVars( loadCustomVars() );
	}

	function buildSwitcher() {
		// Dropdown "Tema ▾" (colapsado por padrão), no mesmo padrão visual do
		// dropdown "Admin" — fica na mesma linha que os outros controles
		// pessoais. As três opções (Claro/Escuro/Personalizado) e o painel de
		// cores do tema personalizado ficam dentro do menu, que abre no clique.
		var wrapper = document.createElement( 'div' );
		wrapper.className = 'rw-personal-dropdown rw-theme-dropdown';

		var toggle = document.createElement( 'button' );
		toggle.type = 'button';
		toggle.className = 'rw-personal-dropdown-toggle';
		toggle.setAttribute( 'aria-expanded', 'false' );
		toggle.innerHTML = 'Tema <span class="rw-collapse-chevron">▾</span>';
		wrapper.appendChild( toggle );

		var menu = document.createElement( 'div' );
		menu.className = 'rw-personal-dropdown-menu rw-theme-menu';
		wrapper.appendChild( menu );

		var themes = [
			{ id: 'light', label: 'Claro' },
			{ id: 'dark', label: 'Escuro' },
			{ id: 'custom', label: 'Personalizado' }
		];
		var buttons = {};

		var panel = document.createElement( 'div' );
		panel.id = 'rw-custom-theme-panel';
		panel.className = 'rw-custom-theme-panel';
		if ( savedTheme === 'custom' ) {
			panel.classList.add( 'open' );
		}

		themes.forEach( function ( t ) {
			var btn = document.createElement( 'button' );
			btn.type = 'button';
			btn.className = 'rw-theme-opt';
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
				} else {
					// escolha simples (claro/escuro): fecha o dropdown
					wrapper.classList.remove( 'open' );
					toggle.setAttribute( 'aria-expanded', 'false' );
				}
			} );
			buttons[ t.id ] = btn;
			menu.appendChild( btn );
		} );

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
		menu.appendChild( panel );

		toggle.addEventListener( 'click', function () {
			var isOpen = wrapper.classList.toggle( 'open' );
			toggle.setAttribute( 'aria-expanded', String( isOpen ) );
		} );
		document.addEventListener( 'click', function ( e ) {
			if ( !wrapper.contains( e.target ) ) {
				wrapper.classList.remove( 'open' );
				toggle.setAttribute( 'aria-expanded', 'false' );
			}
		} );

		return wrapper;
	}

	function mount() {
		var personalTools = document.getElementById( 'p-personal' );
		var target = personalTools || document.body;
		if ( target.querySelector( '.rw-theme-dropdown' ) ) {
			return; // idempotência: não monta o dropdown de tema duas vezes
		}
		target.appendChild( buildSwitcher() );
	}

	if ( document.readyState === 'loading' ) {
		document.addEventListener( 'DOMContentLoaded', mount );
	} else {
		mount();
	}
}() );

/* ===== agrupa a barra pessoal (logado) num dropdown "Fulano ▾", igual ao
   artefato — anônimo continua com os links soltos (Entrar/Criar conta). ===== */
( function () {
	'use strict';

	function mount() {
		if ( typeof mw === 'undefined' || !mw.config.get( 'wgUserName' ) ) {
			return; // anônimo: mantém os links soltos, sem dropdown
		}
		var personal = document.getElementById( 'p-personal' );
		var list = personal && personal.querySelector( 'ul' );
		if ( !list || list.dataset.rwGrouped ) {
			return;
		}
		list.dataset.rwGrouped = '1';

		// Sino de notificações (Echo): tira de dentro do dropdown "Fulano ▾"
		// (onde ficava escondido) e põe como ÍCONE no topo, antes do botão
		// "Tema", sem texto. O ícone/estilo vem do CSS (.rw-notif-icons).
		var notif = document.createElement( 'ul' );
		notif.className = 'rw-notif-icons';
		[ 'pt-notifications-alert', 'pt-notifications-notice' ].forEach( function ( id ) {
			var li = document.getElementById( id );
			if ( li ) { notif.appendChild( li ); }
		} );
		if ( notif.childNodes.length ) {
			var themeDd = personal.querySelector( '.rw-theme-dropdown' );
			if ( themeDd ) { personal.insertBefore( notif, themeDd ); } else { personal.appendChild( notif ); }
		}

		var wrapper = document.createElement( 'div' );
		wrapper.className = 'rw-personal-dropdown rw-admin-personal';

		var toggle = document.createElement( 'button' );
		toggle.type = 'button';
		toggle.className = 'rw-personal-dropdown-toggle';
		toggle.setAttribute( 'aria-expanded', 'false' );
		toggle.innerHTML = mw.html.escape( mw.config.get( 'wgUserName' ) ) + ' <span class="rw-collapse-chevron">▾</span>';

		list.parentNode.insertBefore( wrapper, list );
		wrapper.appendChild( toggle );
		wrapper.appendChild( list );

		toggle.addEventListener( 'click', function () {
			var isOpen = wrapper.classList.toggle( 'open' );
			toggle.setAttribute( 'aria-expanded', String( isOpen ) );
		} );
		document.addEventListener( 'click', function ( e ) {
			if ( !wrapper.contains( e.target ) ) {
				wrapper.classList.remove( 'open' );
				toggle.setAttribute( 'aria-expanded', 'false' );
			}
		} );
	}

	if ( document.readyState === 'loading' ) {
		document.addEventListener( 'DOMContentLoaded', mount );
	} else {
		mount();
	}
}() );

/* ===== dropdown "Mais" na barra de abas do artigo (Excluir/Mover/etc.) ===== */
( function () {
	'use strict';

	function mount() {
		document.querySelectorAll( '.rw-tab-more' ).forEach( function ( wrap ) {
			var toggle = wrap.querySelector( '.rw-personal-dropdown-toggle' );
			if ( !toggle || toggle.dataset.rwBound ) {
				return;
			}
			toggle.dataset.rwBound = '1';
			toggle.addEventListener( 'click', function () {
				var isOpen = wrap.classList.toggle( 'open' );
				toggle.setAttribute( 'aria-expanded', String( isOpen ) );
			} );
		} );
		document.addEventListener( 'click', function ( e ) {
			document.querySelectorAll( '.rw-tab-more.open' ).forEach( function ( wrap ) {
				if ( !wrap.contains( e.target ) ) {
					wrap.classList.remove( 'open' );
					var t = wrap.querySelector( '.rw-personal-dropdown-toggle' );
					if ( t ) {
						t.setAttribute( 'aria-expanded', 'false' );
					}
				}
			} );
		} );
	}

	if ( document.readyState === 'loading' ) {
		document.addEventListener( 'DOMContentLoaded', mount );
	} else {
		mount();
	}
}() );

/* ===== painel "Aparência" (tamanho de texto / largura) + realoca o índice
   nativo (#toc) e o seletor de idioma pra coluna .rw-toc de verdade (grid,
   não mais um float encaixado dentro do conteúdo). ===== */
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

	function buildGroup( label, attrKey, options, storageKey ) {
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
				html.setAttribute( attrKey, opt.id );
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
		var tocColumn = document.getElementById( 'rw-toc-column' );
		if ( !tocColumn ) {
			return; // só existe em página de artigo — ver ReligioWikiTemplate::execute()
		}

		var toc = document.getElementById( 'toc' );
		if ( toc ) {
			tocColumn.appendChild( toc );
		}

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
		tocColumn.appendChild( panel );
	}

	if ( document.readyState === 'loading' ) {
		document.addEventListener( 'DOMContentLoaded', mount );
	} else {
		mount();
	}
}() );

/* ===== seletor de idioma do artigo (convenção de sub-página) ===== */
( function () {
	'use strict';

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
			return;
		}
		var tocColumn = document.getElementById( 'rw-toc-column' );
		if ( !tocColumn ) {
			return;
		}

		var base = baseTitle( mw.config.get( 'wgPageName' ) );
		var currentCode = mw.config.get( 'wgPageName' ) === base ? 'pt' : mw.config.get( 'wgPageName' ).split( '/' ).pop();

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

		tocColumn.insertBefore( box, tocColumn.firstChild );
	}

	if ( document.readyState === 'loading' ) {
		document.addEventListener( 'DOMContentLoaded', mount );
	} else {
		mount();
	}
}() );

/* ===== ícone de lápis ao lado do título ===== */
( function () {
	'use strict';

	function mount() {
		// Lápis só em artigos (namespace principal, fora da home) — não em
		// páginas de projeto/especiais como "Religio Wiki:Doar".
		if ( !document.body.classList.contains( 'rw-can-edit' ) || typeof mw === 'undefined' || mw.config.get( 'wgNamespaceNumber' ) !== 0 || mw.config.get( 'wgIsMainPage' ) ) {
			return;
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

/* ===== menu hambúrguer (barra lateral em tela estreita) ===== */
( function () {
	'use strict';

	function mount() {
		var panel = document.getElementById( 'mw-panel' );
		var btn = document.getElementById( 'rw-hamburger' );
		var overlay = document.getElementById( 'rw-sidebar-overlay' );
		if ( !panel || !btn || !overlay ) {
			return;
		}

		function setOpen( isOpen ) {
			panel.classList.toggle( 'rw-sidebar-open', isOpen );
			overlay.classList.toggle( 'rw-sidebar-open', isOpen );
			btn.setAttribute( 'aria-expanded', String( isOpen ) );
			// ☰ vira ✕ enquanto o menu está aberto — deixa claro que o mesmo
			// botão fecha (sem isso, o ícone não mudava e não dava pra saber
			// só de olhar que apertar de novo fecha o menu).
			btn.textContent = isOpen ? '✕' : '☰';
			// Trava o scroll do <body> por trás do menu aberto — sem isso, um
			// arraste vertical sobre a área do overlay ainda rolava a página de
			// baixo (o painel tem overflow-y próprio, mas o body continuava
			// rolável ao mesmo tempo), um problema clássico de "menu gaveta"
			// mal implementado no mobile.
			document.body.classList.toggle( 'rw-noscroll', isOpen );
		}
		function close() {
			setOpen( false );
		}
		function toggle() {
			setOpen( !panel.classList.contains( 'rw-sidebar-open' ) );
		}
		btn.addEventListener( 'click', toggle );
		overlay.addEventListener( 'click', close );
		document.addEventListener( 'keydown', function ( e ) {
			if ( e.key === 'Escape' ) {
				close();
			}
		} );
		panel.addEventListener( 'click', function ( e ) {
			if ( e.target.tagName === 'A' ) {
				close();
			}
		} );

		collapsePortlets( panel );
	}

	// Cada portlet da lateral vira collapse/accordion fechado por padrão.
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
			// Abre por padrão (fica mais bonito): a lateral já vem expandida,
			// o chevron aponta pra cima e o clique continua colapsando/reabrindo.
			toggle.setAttribute( 'aria-expanded', 'true' );

			var label = document.createElement( 'span' );
			label.textContent = heading.textContent;
			var chevron = document.createElement( 'span' );
			chevron.className = 'rw-collapse-chevron';
			chevron.textContent = '▾';
			toggle.appendChild( label );
			toggle.appendChild( chevron );

			heading.textContent = '';
			heading.appendChild( toggle );

			body.style.display = ''; // aberto por padrão
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

/* ===== pop-up de login / criar conta (API real: action=clientlogin/createaccount) ===== */
( function () {
	'use strict';

	var SOCIAL_PROVIDERS = [
		{ id: 'google', label: 'Continuar com Google' },
		{ id: 'facebook', label: 'Continuar com Facebook' },
		{ id: 'github', label: 'Continuar com GitHub' }
	];

	var overlay = null;
	var loginPanel, createPanel;

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
		// wgRWSocialProviders é exposto pelo hook ResourceLoaderGetConfigVars
		// já existente em LocalSettings-snippet.php — mantido sem mudança.
		var configured = ( typeof mw !== 'undefined' && mw.config.get( 'wgRWSocialProviders' ) ) || [];

		SOCIAL_PROVIDERS.forEach( function ( p ) {
			// Só mostra o botão do provedor se ele estiver REALMENTE configurado
			// (wgRWSocialProviders). Sem isso, botões desativados de Google/GitHub
			// só confundiam e levavam à página Especial:Autenticar-se sem efeito.
			if ( configured.indexOf( p.id ) === -1 ) {
				return;
			}
			var btn = document.createElement( 'button' );
			btn.type = 'button';
			btn.textContent = p.label;
			btn.addEventListener( 'click', function () {
				location.href = mw.util.getUrl( 'Special:UserLogin', {
					returnto: mw.config.get( 'wgPageName' )
				} );
			} );
			wrap.appendChild( btn );
		} );
		return wrap;
	}

	function buildLoginPanel() {
		var panel = document.createElement( 'div' );
		panel.appendChild( buildSocialButtons() );
		var divider = document.createElement( 'div' );
		divider.className = 'rw-auth-divider';
		divider.textContent = 'ou com usuário e senha';
		panel.appendChild( divider );

		var loginError = document.createElement( 'p' );
		loginError.className = 'rw-auth-error';
		loginError.style.display = 'none';
		panel.appendChild( loginError );

		var user = buildField( 'Nome de usuário', 'text', 'username' );
		var pass = buildField( 'Senha', 'password', 'password' );
		panel.appendChild( user.label );
		panel.appendChild( pass.label );

		var loginSubmit = document.createElement( 'button' );
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
		panel.style.display = 'none';
		panel.appendChild( buildSocialButtons() );
		var divider = document.createElement( 'div' );
		divider.className = 'rw-auth-divider';
		divider.textContent = 'ou crie com usuário e senha';
		panel.appendChild( divider );

		var createError = document.createElement( 'p' );
		createError.className = 'rw-auth-error';
		createError.style.display = 'none';
		panel.appendChild( createError );

		var user = buildField( 'Nome de usuário', 'text', 'username' );
		var pass = buildField( 'Senha', 'password', 'password' );
		var retype = buildField( 'Confirme a senha', 'password', 'retype' );
		var email = buildField( 'E-mail (opcional)', 'email', 'email' );
		[ user, pass, retype, email ].forEach( function ( f ) { panel.appendChild( f.label ); } );

		var createSubmit = document.createElement( 'button' );
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
		var loginLi = document.getElementById( 'pt-login' ) || document.getElementById( 'pt-anonlogin' );
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

/* ===== seletor de imagens já enviadas (Special:AllImages via API), pra inserir
   no wikitexto sem precisar saber o nome do arquivo de cor ===== */
( function () {
	'use strict';

	var overlay = null;
	var currentTextarea = null;
	var searchInput, statusEl, gridEl, detailEl, listStepEl;
	var allImagesCache = null;
	var canDeleteCache = null;

	function insertAtCursor( textarea, text ) {
		var start = textarea.selectionStart;
		var end = textarea.selectionEnd;
		var value = textarea.value;
		textarea.value = value.slice( 0, start ) + text + value.slice( end );
		var pos = start + text.length;
		textarea.selectionStart = textarea.selectionEnd = pos;
		textarea.focus();
	}

	function formatDate( timestamp ) {
		var d = new Date( timestamp );
		if ( isNaN( d.getTime() ) ) {
			return '';
		}
		var pad = function ( n ) { return n < 10 ? '0' + n : String( n ); };
		return pad( d.getDate() ) + '/' + pad( d.getMonth() + 1 ) + '/' + d.getFullYear();
	}

	function ensureCanDelete() {
		if ( canDeleteCache !== null ) {
			return $.Deferred().resolve( canDeleteCache ).promise();
		}
		return mw.user.getRights().then( function ( rights ) {
			canDeleteCache = rights.indexOf( 'delete' ) !== -1;
			return canDeleteCache;
		} );
	}

	function fetchAllImages() {
		if ( allImagesCache ) {
			return $.Deferred().resolve( allImagesCache ).promise();
		}
		return mw.loader.using( 'mediawiki.api' ).then( function () {
			var api = new mw.Api();
			return api.get( {
				action: 'query',
				format: 'json',
				list: 'allimages',
				aiprop: 'url|size|timestamp|user',
				aisort: 'timestamp',
				aidir: 'descending',
				ailimit: 200
			} ).then( function ( data ) {
				allImagesCache = ( data.query && data.query.allimages ) || [];
				return allImagesCache;
			} );
		} );
	}

	function fetchFileUsage( name ) {
		return mw.loader.using( 'mediawiki.api' ).then( function () {
			var api = new mw.Api();
			return api.get( {
				action: 'query',
				format: 'json',
				titles: 'Arquivo:' + name,
				prop: 'fileusage',
				fulimit: 50
			} ).then( function ( data ) {
				var pages = ( data.query && data.query.pages ) || {};
				var page = pages[ Object.keys( pages )[ 0 ] ];
				return ( page && page.fileusage ) || [];
			} );
		} );
	}

	function renderGrid( images ) {
		gridEl.innerHTML = '';
		if ( !images.length ) {
			statusEl.textContent = 'Nenhuma imagem encontrada.';
			return;
		}
		statusEl.textContent = images.length + ' imagem(ns).';
		images.forEach( function ( img ) {
			var item = document.createElement( 'button' );
			item.type = 'button';
			item.className = 'rw-imgpicker-item';

			var thumb = document.createElement( 'img' );
			thumb.src = img.url;
			thumb.alt = img.name;
			thumb.loading = 'lazy';

			var name = document.createElement( 'span' );
			name.textContent = img.name;

			var date = document.createElement( 'small' );
			date.className = 'rw-imgpicker-date';
			date.textContent = formatDate( img.timestamp );

			item.appendChild( thumb );
			item.appendChild( name );
			item.appendChild( date );
			item.addEventListener( 'click', function () {
				showDetail( img );
			} );
			gridEl.appendChild( item );
		} );
	}

	function applyFilter() {
		var q = searchInput.value.trim().toLowerCase();
		if ( !allImagesCache ) {
			return;
		}
		var filtered = !q ? allImagesCache : allImagesCache.filter( function ( img ) {
			return img.name.toLowerCase().indexOf( q ) !== -1;
		} );
		renderGrid( filtered );
	}

	function showDetail( img ) {
		listStepEl.style.display = 'none';
		detailEl.style.display = 'block';
		detailEl.innerHTML = '';

		var back = document.createElement( 'button' );
		back.type = 'button';
		back.className = 'rw-imgpicker-back';
		back.textContent = '← Voltar pra lista';
		back.addEventListener( 'click', function () {
			detailEl.style.display = 'none';
			listStepEl.style.display = 'block';
		} );
		detailEl.appendChild( back );

		var row = document.createElement( 'div' );
		row.className = 'rw-imgpicker-detail';

		var preview = document.createElement( 'img' );
		preview.src = img.url;
		preview.alt = img.name;
		row.appendChild( preview );

		var fields = document.createElement( 'div' );
		fields.className = 'rw-imgpicker-detail-fields';

		var nameP = document.createElement( 'p' );
		nameP.className = 'rw-auth-note';
		nameP.textContent = img.name;
		fields.appendChild( nameP );

		var metaP = document.createElement( 'p' );
		metaP.className = 'rw-auth-note';
		metaP.textContent = 'Enviada em ' + formatDate( img.timestamp ) +
			( img.user ? ' por ' + img.user : '' );
		fields.appendChild( metaP );

		var usageP = document.createElement( 'p' );
		usageP.className = 'rw-auth-note';
		usageP.textContent = 'Verificando uso em artigos…';
		fields.appendChild( usageP );
		fetchFileUsage( img.name ).done( function ( usage ) {
			if ( !usage.length ) {
				usageP.textContent = 'Não é usada em nenhum artigo.';
				return;
			}
			var titles = usage.slice( 0, 5 ).map( function ( p ) { return p.title; } ).join( ', ' );
			usageP.textContent = 'Usada em ' + usage.length + ' artigo(s): ' + titles +
				( usage.length > 5 ? '…' : '' );
		} );

		var captionLabel = document.createElement( 'label' );
		captionLabel.className = 'rw-auth-field';
		var captionSpan = document.createElement( 'span' );
		captionSpan.textContent = 'Legenda (opcional)';
		var captionInput = document.createElement( 'input' );
		captionInput.type = 'text';
		captionLabel.appendChild( captionSpan );
		captionLabel.appendChild( captionInput );
		fields.appendChild( captionLabel );

		var insertBtn = document.createElement( 'button' );
		insertBtn.type = 'button';
		insertBtn.className = 'rw-auth-submit';
		insertBtn.textContent = 'Inserir no artigo';
		insertBtn.addEventListener( 'click', function () {
			var caption = captionInput.value.trim();
			var wikitext = '[[Arquivo:' + img.name + '|thumb' +
				( caption ? '|' + caption : '' ) + ']]';
			insertAtCursor( currentTextarea, wikitext );
			close();
		} );
		fields.appendChild( insertBtn );

		var deleteZone = document.createElement( 'div' );
		fields.appendChild( deleteZone );
		ensureCanDelete().done( function ( canDelete ) {
			if ( canDelete ) {
				renderDeleteZone( deleteZone, img );
			}
		} );

		row.appendChild( fields );
		detailEl.appendChild( row );
	}

	function renderDeleteZone( zone, img ) {
		zone.innerHTML = '';
		var deleteBtn = document.createElement( 'button' );
		deleteBtn.type = 'button';
		deleteBtn.className = 'rw-imgpicker-delete';
		deleteBtn.textContent = '🗑️ Apagar arquivo';
		deleteBtn.addEventListener( 'click', function () {
			renderDeleteConfirm( zone, img );
		} );
		zone.appendChild( deleteBtn );
	}

	function renderDeleteConfirm( zone, img ) {
		zone.innerHTML = '';

		var warn = document.createElement( 'p' );
		warn.className = 'rw-auth-error';
		warn.textContent = 'Apagar "' + img.name + '"? Fica no registro de eliminações e pode ser restaurada depois, mas some do artigo onde for usada.';
		zone.appendChild( warn );

		var reasonLabel = document.createElement( 'label' );
		reasonLabel.className = 'rw-auth-field';
		var reasonSpan = document.createElement( 'span' );
		reasonSpan.textContent = 'Motivo (opcional)';
		var reasonInput = document.createElement( 'input' );
		reasonInput.type = 'text';
		reasonLabel.appendChild( reasonSpan );
		reasonLabel.appendChild( reasonInput );
		zone.appendChild( reasonLabel );

		var confirmBtn = document.createElement( 'button' );
		confirmBtn.type = 'button';
		confirmBtn.className = 'rw-imgpicker-delete-confirm';
		confirmBtn.textContent = 'Confirmar exclusão';

		var cancelBtn = document.createElement( 'button' );
		cancelBtn.type = 'button';
		cancelBtn.className = 'rw-imgpicker-back';
		cancelBtn.textContent = 'Cancelar';
		cancelBtn.addEventListener( 'click', function () {
			renderDeleteZone( zone, img );
		} );

		confirmBtn.addEventListener( 'click', function () {
			confirmBtn.disabled = true;
			confirmBtn.textContent = 'Apagando…';
			mw.loader.using( 'mediawiki.api' ).then( function () {
				var api = new mw.Api();
				return api.postWithToken( 'csrf', {
					action: 'delete',
					title: 'Arquivo:' + img.name,
					reason: reasonInput.value.trim()
				} );
			} ).done( function () {
				allImagesCache = allImagesCache.filter( function ( i ) { return i.name !== img.name; } );
				detailEl.style.display = 'none';
				listStepEl.style.display = 'block';
				applyFilter();
				statusEl.textContent = 'Imagem apagada. ' + statusEl.textContent;
			} ).fail( function ( code, err ) {
				warn.textContent = 'Erro ao apagar: ' + ( ( err && err.error && err.error.info ) || code );
				confirmBtn.disabled = false;
				confirmBtn.textContent = 'Confirmar exclusão';
			} );
		} );

		zone.appendChild( confirmBtn );
		zone.appendChild( cancelBtn );
	}

	function close() {
		overlay.classList.remove( 'open' );
	}

	function buildOverlay() {
		var ov = document.createElement( 'div' );
		ov.id = 'rw-imgpicker-overlay';

		var modal = document.createElement( 'div' );
		modal.className = 'rw-imgpicker-modal';
		modal.setAttribute( 'role', 'dialog' );
		modal.setAttribute( 'aria-modal', 'true' );

		var closeBtn = document.createElement( 'button' );
		closeBtn.type = 'button';
		closeBtn.className = 'rw-imgpicker-close';
		closeBtn.textContent = 'Fechar ✕';
		closeBtn.addEventListener( 'click', close );
		modal.appendChild( closeBtn );

		var title = document.createElement( 'h3' );
		title.className = 'rw-imgpicker-title';
		title.textContent = 'Inserir imagem já enviada';
		modal.appendChild( title );

		listStepEl = document.createElement( 'div' );

		searchInput = document.createElement( 'input' );
		searchInput.type = 'search';
		searchInput.className = 'rw-imgpicker-search';
		searchInput.placeholder = 'Buscar por nome do arquivo…';
		searchInput.addEventListener( 'input', applyFilter );
		listStepEl.appendChild( searchInput );

		statusEl = document.createElement( 'p' );
		statusEl.className = 'rw-imgpicker-status';
		statusEl.textContent = 'Carregando…';
		listStepEl.appendChild( statusEl );

		gridEl = document.createElement( 'div' );
		gridEl.className = 'rw-imgpicker-grid';
		listStepEl.appendChild( gridEl );

		modal.appendChild( listStepEl );

		detailEl = document.createElement( 'div' );
		detailEl.style.display = 'none';
		modal.appendChild( detailEl );

		ov.appendChild( modal );

		ov.addEventListener( 'click', function ( e ) {
			if ( e.target === ov ) {
				close();
			}
		} );
		document.addEventListener( 'keydown', function ( e ) {
			if ( e.key === 'Escape' && ov.classList.contains( 'open' ) ) {
				close();
			}
		} );

		return ov;
	}

	function openPicker( textarea ) {
		currentTextarea = textarea;
		if ( !overlay ) {
			overlay = buildOverlay();
			document.body.appendChild( overlay );
		}
		detailEl.style.display = 'none';
		listStepEl.style.display = 'block';
		searchInput.value = '';
		overlay.classList.add( 'open' );
		statusEl.textContent = 'Carregando…';
		gridEl.innerHTML = '';
		fetchAllImages().then( renderGrid, function () {
			statusEl.textContent = 'Erro ao buscar imagens enviadas.';
		} );
	}

	function mount() {
		var textarea = document.getElementById( 'wpTextbox1' );
		if ( !textarea || typeof mw === 'undefined' ) {
			return;
		}

		function insertTrigger() {
			// Evita duplicar se o hook do WikiEditor e o setTimeout de segurança
			// (abaixo) dispararem os dois.
			if ( document.querySelector( '.rw-imgpicker-trigger-row' ) ) {
				return;
			}
			var row = document.createElement( 'div' );
			row.className = 'rw-imgpicker-trigger-row';
			var btn = document.createElement( 'button' );
			btn.type = 'button';
			btn.className = 'rw-imgpicker-trigger';
			btn.textContent = '🖼️ Inserir imagem já enviada';
			btn.addEventListener( 'click', function () {
				openPicker( textarea );
			} );
			row.appendChild( btn );
			// O WikiEditor envolve o <textarea> numa estrutura nova (.wikiEditor-ui)
			// de forma assíncrona, depois do nosso DOMContentLoaded. Inserir antes
			// do <textarea> cedo demais deixava o botão preso na posição antiga,
			// sobrepondo visualmente a barra de ferramentas real do WikiEditor.
			// Por isso espera o hook wikiEditor.toolbarReady (que dispara mesmo
			// se o listener for adicionado depois, via mw.hook) e insere relativo
			// ao wrapper .wikiEditor-ui já pronto.
			var target = textarea.closest( '.wikiEditor-ui' ) || textarea;
			target.parentNode.insertBefore( row, target );
		}

		if ( mw.hook ) {
			mw.hook( 'wikiEditor.toolbarReady' ).add( insertTrigger );
		}
		// Nem toda página de edição tem WikiEditor ativo; garante o botão de
		// qualquer jeito depois de um tempo se o hook nunca disparar.
		setTimeout( insertTrigger, 1500 );
	}

	if ( document.readyState === 'loading' ) {
		document.addEventListener( 'DOMContentLoaded', mount );
	} else {
		mount();
	}
}() );
