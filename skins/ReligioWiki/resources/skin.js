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
