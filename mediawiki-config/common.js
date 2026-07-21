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

/* ===== Widget da página de doação (Religio Wiki:Doar) =====
 * Monta a UI de valor/frequência/método e, ao confirmar, chama
 * Special:DonateCheckout (ver mediawiki-config/includes/SpecialDonateCheckout.php)
 * que cria uma Stripe Checkout Session de verdade -- o navegador é
 * redirecionado pra página de pagamento hospedada pelo próprio Stripe
 * (cartão nunca passa pelo nosso servidor).
 *
 * Pix/Boleto são pagamento de ação única -- não têm "débito automático" no
 * Stripe -- então somem da lista de métodos quando a frequência é
 * Mensal/Anual (só cartão continua disponível nesse caso).
 */
( function () {
	'use strict';

	var PRESETS = [ 15, 20, 30, 70, 140, 200, 300 ];
	// key = chave ASCII enviada pro backend; label = texto do botão;
	// oneTimeOnly = some da lista quando a frequência não é "unico".
	var METHODS = [
		{ key: 'pix', label: 'Pix', oneTimeOnly: true },
		{ key: 'boleto', label: 'Boleto', oneTimeOnly: true },
		{ key: 'card', label: 'Cartão de crédito/débito', oneTimeOnly: false }
	];

	function mount() {
		var host = document.getElementById( 'rw-donate-widget' );
		if ( !host ) {
			return;
		}

		var state = { frequency: 'unico', amount: 30, method: 'pix' };

		host.innerHTML = '';

		// Mensagem de retorno do Stripe (?doacao=sucesso|cancelado na URL,
		// ver success_url/cancel_url no SpecialDonateCheckout.php).
		var params = new URLSearchParams( window.location.search );
		var doacaoStatus = params.get( 'doacao' );
		if ( doacaoStatus === 'sucesso' || doacaoStatus === 'cancelado' ) {
			var banner = document.createElement( 'p' );
			banner.className = 'rw-donate-banner rw-donate-banner-' + doacaoStatus;
			banner.textContent = doacaoStatus === 'sucesso' ?
				'Obrigado! Sua doação foi confirmada. 💛' :
				'Pagamento cancelado -- nenhum valor foi cobrado.';
			host.appendChild( banner );
		}

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
				updateMethodVisibility();
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
		METHODS.forEach( function ( m ) {
			var btn = document.createElement( 'button' );
			btn.type = 'button';
			btn.textContent = m.label;
			btn.setAttribute( 'aria-pressed', String( m.key === state.method ) );
			btn.addEventListener( 'click', function () {
				state.method = m.key;
				Object.keys( methodButtons ).forEach( function ( k ) {
					methodButtons[ k ].setAttribute( 'aria-pressed', String( k === m.key ) );
				} );
			} );
			methodButtons[ m.key ] = btn;
			methods.appendChild( btn );
		} );
		host.appendChild( methods );

		// Some Pix/Boleto quando a frequência não é "unico" (não têm cobrança
		// recorrente no Stripe); troca automaticamente pra "card" se o método
		// selecionado no momento deixar de estar disponível.
		function updateMethodVisibility() {
			var recurring = state.frequency !== 'unico';
			METHODS.forEach( function ( m ) {
				methodButtons[ m.key ].style.display = ( recurring && m.oneTimeOnly ) ? 'none' : '';
			} );
			if ( recurring && state.method !== 'card' ) {
				state.method = 'card';
				Object.keys( methodButtons ).forEach( function ( k ) {
					methodButtons[ k ].setAttribute( 'aria-pressed', String( k === 'card' ) );
				} );
			}
		}
		updateMethodVisibility();

		var errorMsg = document.createElement( 'p' );
		errorMsg.className = 'rw-donate-error';
		errorMsg.style.display = 'none';
		host.appendChild( errorMsg );

		var submitBtn = document.createElement( 'button' );
		submitBtn.type = 'button';
		submitBtn.className = 'rw-donate-submit';
		submitBtn.textContent = 'Confirmar doação';
		submitBtn.addEventListener( 'click', function () {
			if ( !state.amount || state.amount < 1 ) {
				errorMsg.textContent = 'Escolha um valor válido antes de continuar.';
				errorMsg.style.display = '';
				return;
			}
			errorMsg.style.display = 'none';
			submitBtn.disabled = true;
			submitBtn.textContent = 'Processando…';
			fetch( mw.util.getUrl( 'Special:DonateCheckout' ), {
				method: 'POST',
				headers: { 'Content-Type': 'application/json' },
				body: JSON.stringify( {
					amount: state.amount,
					frequency: state.frequency,
					method: state.method
				} )
			} )
				.then( function ( res ) {
					return res.json().then( function ( data ) {
						return { ok: res.ok, data: data };
					} );
				} )
				.then( function ( result ) {
					if ( result.ok && result.data.url ) {
						window.location.href = result.data.url;
					} else {
						throw new Error( result.data.error || 'erro_desconhecido' );
					}
				} )
				.catch( function () {
					errorMsg.textContent = 'Não foi possível iniciar o pagamento agora. ' +
						'Tente novamente em alguns instantes ou entre em contato: contato@religiowiki.com.';
					errorMsg.style.display = '';
					submitBtn.disabled = false;
					submitBtn.textContent = 'Confirmar doação';
				} );
		} );
		host.appendChild( submitBtn );

		var note = document.createElement( 'p' );
		note.className = 'rw-donate-note';
		note.textContent = 'Pagamento processado pelo Stripe -- seus dados de cartão nunca passam ' +
			'pelos nossos servidores.';
		host.appendChild( note );
	}

	if ( document.readyState === 'loading' ) {
		document.addEventListener( 'DOMContentLoaded', mount );
	} else {
		mount();
	}
}() );

/* Predefinições disponíveis sem precisar buscar primeiro (TemplateWizard).
 * Editores novatos não sabiam que precisavam digitar algo pra ver a lista
 * de predefinições no diálogo 'Inserir predefinição' — agora, ao abrir o
 * diálogo com o campo vazio, já lista as predefinições existentes em ordem
 * alfabética; digitar volta a fazer a busca normal.
 *
 * Nota: o patch tem que ficar em SearchForm.prototype.focus (chamado de
 * novo TODA VEZ que o diálogo abre, via Dialog.getReadyProcess), não em
 * SearchField.prototype.onLookupInputFocus -- esse é vinculado ao evento
 * de foco ('.bind'/'.on') na CONSTRUÇÃO do diálogo (uma única vez, no
 * carregamento da página), então um patch feito depois desse momento não
 * pega mais pra essa instância já existente. */
( function () {
	mw.hook( 'wikiEditor.toolbarReady' ).add( function () {
		mw.loader.using( 'ext.TemplateWizard' ).then( function () {
			var SF = mw.TemplateWizard && mw.TemplateWizard.SearchField;
			var SFm = mw.TemplateWizard && mw.TemplateWizard.SearchForm;
			if ( !SF || !SFm || SFm.prototype.rwPatchedEmptyLookup ) {
				return;
			}
			SFm.prototype.rwPatchedEmptyLookup = true;

			// O OOUI LookupElement por padrão só considera termos com 1+
			// caractere como consulta válida.
			SF.prototype.isValidLookupTerm = function () {
				return true;
			};

			var originalGetApiParams = SF.prototype.getApiParams;
			SF.prototype.getApiParams = function ( query ) {
				if ( query ) {
					return originalGetApiParams.call( this, query );
				}
				// Campo vazio: lista as predefinições existentes (A-Z) em
				// vez de fazer uma prefixsearch vazia (que não retorna nada).
				return {
					action: 'templatedata',
					includeMissingTitles: 1,
					lang: mw.config.get( 'wgUserLanguage' ),
					generator: 'allpages',
					gapnamespace: mw.config.get( 'wgNamespaceIds' ).template,
					gapfilterredir: 'nonredirects',
					gaplimit: this.limit
				};
			};

			// Chamado toda vez que o diálogo abre (ver Dialog.js:
			// showSearch/getReadyProcess) -- ponto seguro pra disparar a
			// lista mesmo com o campo vazio, sem depender do handler de
			// foco já vinculado na construção do diálogo.
			//
			// Não dá pra usar searchWidget.populateLookupMenu() aqui: essa
			// função do OOUI tem um corte próprio pra valor vazio que não
			// passa por isValidLookupTerm (testado ao vivo -- mesmo com
			// isValidLookupTerm sempre true, populateLookupMenu() não faz
			// nenhuma requisição pra termo vazio). Por isso a lista é
			// montada manualmente aqui com as mesmas peças públicas que o
			// próprio SearchField usa (getLookupRequest +
			// getLookupCacheDataFromResponse + getLookupMenuOptionsFromData),
			// só que sem aquele corte.
			var originalFocus = SFm.prototype.focus;
			SFm.prototype.focus = function () {
				originalFocus.apply( this, arguments );
				var sw = this.searchWidget;
				if ( sw.getValue() ) {
					return;
				}
				sw.getLookupRequest().done( function ( response ) {
					// Se o editor já começou a digitar enquanto a lista
					// carregava, não sobrescreve o que o OOUI já esteja
					// mostrando pra consulta nova.
					if ( sw.getValue() ) {
						return;
					}
					var data = sw.getLookupCacheDataFromResponse( response );
					var menu = sw.getLookupMenu();
					menu.clearItems();
					menu.addItems( sw.getLookupMenuOptionsFromData( data ) );
					menu.toggle( true );
				} );
			};
		} );
	} );
}() );

/* Sanfona (accordion) nos grupos "Formatação"/"Componentes"/"Ajuda" da
 * barra de ferramentas da ReligiowikiCustomizer (#rwc-editor-toolbar) --
 * clique no rótulo do grupo recolhe/expande os botões, pra não ocupar
 * tanto espaço na tela do editor (sobretudo no mobile). Progressive
 * enhancement puro: a extensão continua funcionando normalmente se isso
 * não rodar (ex.: markup mudar numa versão futura). */
( function () {
	function setupAccordion() {
		var toolbar = document.getElementById( 'rwc-editor-toolbar' );
		if ( !toolbar || toolbar.rwAccordionDone ) {
			return;
		}
		toolbar.rwAccordionDone = true;
		var isMobile = window.matchMedia( '(max-width: 851px)' ).matches;
		Array.prototype.forEach.call( toolbar.querySelectorAll( '.rwc-editor-group' ), function ( group ) {
			var label = group.querySelector( '.rwc-editor-group-label' );
			if ( !label ) {
				return;
			}
			// Junta todo o resto do grupo (os botões) num wrapper próprio,
			// pra poder recolher só eles -- o rótulo continua sempre visível.
			var buttons = Array.prototype.filter.call( group.children, function ( el ) {
				return el !== label;
			} );
			var wrapper = document.createElement( 'div' );
			wrapper.className = 'rwc-editor-group-buttons';
			buttons.forEach( function ( btn ) {
				wrapper.appendChild( btn );
			} );
			group.appendChild( wrapper );

			label.setAttribute( 'role', 'button' );
			label.setAttribute( 'tabindex', '0' );
			group.setAttribute( 'aria-expanded', isMobile ? 'false' : 'true' );

			function toggle() {
				var expanded = group.getAttribute( 'aria-expanded' ) === 'true';
				group.setAttribute( 'aria-expanded', expanded ? 'false' : 'true' );
			}
			label.addEventListener( 'click', toggle );
			label.addEventListener( 'keydown', function ( e ) {
				if ( e.key === 'Enter' || e.key === ' ' ) {
					e.preventDefault();
					toggle();
				}
			} );
		} );
	}

	if ( document.readyState === 'loading' ) {
		document.addEventListener( 'DOMContentLoaded', setupAccordion );
	} else {
		setupAccordion();
	}
	// Cobre o caso do toolbar ser inserido depois (associado ao WikiEditor).
	mw.hook( 'wikiEditor.toolbarReady' ).add( setupAccordion );
}() );

/* Adiciona setas de expandir/colapsar por SEÇÃO ao índice nativo do
 * MediaWiki (#toc, já realocado pra dentro de .rw-toc por skin.js),
 * completando o redesign visual feito em Common.css (que remove a
 * numeração decimal e reestiliza a caixa/cabeçalho -- o toggle GERAL de
 * ocultar/mostrar reaproveita o checkbox nativo do MediaWiki, puro CSS,
 * sem precisar de JS nenhum).
 *
 * Escrito de propósito sem depender de nada específico do skin.js desta
 * skin (só do #toc nativo, padrão em qualquer instalação do MediaWiki) --
 * pra poder ser portado sem ajuste pra dentro da extensão
 * ReligiowikiCustomizer no futuro (fase 2, editor CSS/JS), sem reescrever
 * a lógica.
 *
 * Persistência via localStorage: cada seção colapsada é lembrada por
 * PÁGINA (a chave inclui o nome da página + o href da seção), então
 * artigos diferentes não interferem uns nos outros. */
( function () {
	'use strict';

	var SECTION_KEY_PREFIX = 'rw-toc-section-collapsed:';

	function pageKey() {
		return ( typeof mw !== 'undefined' && mw.config ) ?
			mw.config.get( 'wgPageName' ) :
			window.location.pathname;
	}

	function setupSectionArrows() {
		var toc = document.getElementById( 'toc' );
		if ( !toc || toc.dataset.rwTocArrowsDone ) {
			return;
		}
		var topList = toc.querySelector( 'ul' );
		if ( !topList ) {
			return;
		}
		toc.dataset.rwTocArrowsDone = '1';

		var key = pageKey();
		var items = toc.querySelectorAll( 'li' );

		Array.prototype.forEach.call( items, function ( li ) {
			// Só o <ul> filho DIRETO conta como "tem subseções" -- não
			// os <ul> de netos, que já pertencem ao item filho.
			var childList = null;
			for ( var i = 0; i < li.children.length; i++ ) {
				if ( li.children[ i ].tagName === 'UL' ) {
					childList = li.children[ i ];
					break;
				}
			}
			if ( !childList ) {
				return;
			}
			li.classList.add( 'rw-toc-has-children' );

			var arrow = document.createElement( 'span' );
			arrow.className = 'rw-toc-arrow';
			arrow.textContent = '▾';
			arrow.setAttribute( 'role', 'button' );
			arrow.setAttribute( 'tabindex', '0' );
			arrow.setAttribute( 'aria-label', 'Expandir ou recolher esta seção do índice' );

			li.insertBefore( arrow, li.firstChild );

			var firstLink = li.querySelector( 'a' );
			var sectionKey = SECTION_KEY_PREFIX + key + ':' + ( firstLink ? firstLink.getAttribute( 'href' ) : String( Array.prototype.indexOf.call( items, li ) ) );

			function toggleSection() {
				var collapsed = li.classList.toggle( 'rw-toc-item-collapsed' );
				try {
					localStorage.setItem( sectionKey, collapsed ? '1' : '0' );
				} catch ( e ) { /* localStorage indisponível (modo privado etc.) -- ignora, só não persiste */ }
			}

			arrow.addEventListener( 'click', function ( e ) {
				e.preventDefault();
				e.stopPropagation();
				toggleSection();
			} );
			arrow.addEventListener( 'keydown', function ( e ) {
				if ( e.key === 'Enter' || e.key === ' ' ) {
					e.preventDefault();
					toggleSection();
				}
			} );

			var savedSection = null;
			try {
				savedSection = localStorage.getItem( sectionKey );
			} catch ( e ) { /* ignora */ }
			if ( savedSection === '1' ) {
				li.classList.add( 'rw-toc-item-collapsed' );
			}
		} );
	}

	if ( document.readyState === 'loading' ) {
		document.addEventListener( 'DOMContentLoaded', setupSectionArrows );
	} else {
		setupSectionArrows();
	}
	// O #toc pode ser movido/inserido de forma assíncrona (skin.js realoca
	// o #toc nativo pra dentro de .rw-toc) -- reforça a checagem um pouco
	// depois, sem custo (a função já é idempotente via data-attribute).
	setTimeout( setupSectionArrows, 300 );
	setTimeout( setupSectionArrows, 1000 );
}() );

/* Mobile: Idiomas + Neste artigo + Aparência (dentro de #rw-toc-column)
 * viram um painel flutuante no canto inferior direito -- só um botão
 * (FAB, "☰") aparece por padrão, expandindo o painel completo ao clicar
 * (sanfona), sem atrapalhar a leitura do artigo. O CSS (Common.css) só
 * ativa esse comportamento dentro do breakpoint mobile; em telas
 * maiores o FAB fica escondido e a coluna volta ao normal (grid, tudo
 * sempre visível). */
( function () {
	'use strict';

	var STORAGE_KEY = 'rw-toc-mobile-expanded';

	function setup() {
		var tocColumn = document.getElementById( 'rw-toc-column' );
		if ( !tocColumn || tocColumn.dataset.rwFabDone || !tocColumn.children.length ) {
			return;
		}
		tocColumn.dataset.rwFabDone = '1';

		var fab = document.createElement( 'button' );
		fab.type = 'button';
		fab.className = 'rw-toc-fab';
		fab.setAttribute( 'aria-label', 'Mostrar ou ocultar índice, idiomas e aparência' );
		fab.textContent = '☰';
		fab.setAttribute( 'aria-expanded', 'false' );

		fab.addEventListener( 'click', function () {
			var expanded = tocColumn.classList.toggle( 'rw-toc-expanded' );
			fab.setAttribute( 'aria-expanded', String( expanded ) );
			try {
				localStorage.setItem( STORAGE_KEY, expanded ? '1' : '0' );
			} catch ( e ) { /* ignora */ }
		} );

		tocColumn.insertBefore( fab, tocColumn.firstChild );

		var saved = null;
		try {
			saved = localStorage.getItem( STORAGE_KEY );
		} catch ( e ) { /* ignora */ }
		if ( saved === '1' ) {
			tocColumn.classList.add( 'rw-toc-expanded' );
			fab.setAttribute( 'aria-expanded', 'true' );
		}
	}

	if ( document.readyState === 'loading' ) {
		document.addEventListener( 'DOMContentLoaded', setup );
	} else {
		setup();
	}
	// #rw-toc-column só ganha conteúdo depois que skin.js monta os
	// painéis (Aparência/Idiomas) -- reforça um pouco depois.
	setTimeout( setup, 300 );
	setTimeout( setup, 1000 );
}() );
