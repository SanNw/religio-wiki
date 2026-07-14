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
