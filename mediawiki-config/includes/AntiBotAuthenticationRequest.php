<?php
/**
 * AntiBotAuthenticationRequest -- Fase 1 do sistema anti-bot ("Trust Gateway",
 * ver scratch/religio-antibot-trust-gateway.html). Declara dois campos extras
 * no formulário de CRIAÇÃO DE CONTA (Special:CreateAccount), usados de forma
 * INVISÍVEL pra distinguir humano de bot sem adicionar atrito nenhum ao
 * usuário legítimo:
 *
 *   - rw_hp  (honeypot): um campo que humano nunca vê nem preenche (escondido
 *            via CSS em MediaWiki:Common.css). Se vier preenchido, foi um bot
 *            que preencheu o formulário inteiro sem renderizar o CSS.
 *   - rw_ts  (timestamp assinado): "{tempo}:{hmac}" gerado no render do form.
 *            O HMAC (chave = $wgSecretKey) impede forjar/reusar o valor. Serve
 *            pra medir quanto tempo o preenchimento levou -- submissão quase
 *            instantânea nunca é humana.
 *
 * A VALIDAÇÃO fica em AntiBotPreAuthenticationProvider::testForAccountCreation()
 * -- esta classe só carrega os campos do formulário. Ambos os campos são
 * 'optional' de propósito: assim, um form sem eles (JS/CSS à parte) ainda
 * carrega o request, e o provider decide o que fazer com a ausência do valor
 * (em vez de o request inteiro ser descartado silenciosamente por
 * loadFromSubmission, o que apagaria o sinal).
 *
 * Padrão canônico do AuthManager (MW 1.43, REL1_43) -- o mesmo mecanismo que a
 * extensão ConfirmEdit (já presente no projeto) usa pra injetar o captcha.
 * NÃO usa o hook AbortNewAccount, que foi REMOVIDO no MediaWiki 1.33.
 */

use MediaWiki\Auth\AuthenticationRequest;
use MediaWiki\Auth\AuthManager;
use MediaWiki\Language\RawMessage;

class AntiBotAuthenticationRequest extends AuthenticationRequest {

	/** @var string|null Valor do campo honeypot (deve chegar vazio de um humano). */
	public $rw_hp = null;

	/** @var string|null Timestamp assinado "{tempo}:{hmac}" gerado no render. */
	public $rw_ts = null;

	/**
	 * Valor a injetar no campo rw_ts quando o formulário é RENDERIZADO. O
	 * provider seta isto (via nova instância) antes de devolver o request em
	 * getAuthenticationRequests(); no POST de volta ele fica vazio e o valor
	 * real vem de $this->rw_ts (carregado por loadFromSubmission).
	 * @var string
	 */
	public $tsToRender = '';

	/**
	 * Rótulo neutro e genérico pro honeypot -- de propósito NÃO parece uma
	 * armadilha (nada de "não preencha"), pra um bot que porventura leia o
	 * label não o identificar como honeypot. O humano nunca vê isto: o CSS de
	 * MediaWiki:Common.css tira o campo da viewport.
	 * @inheritDoc
	 */
	public function getFieldInfo() {
		if ( $this->action !== AuthManager::ACTION_CREATE ) {
			return [];
		}

		return [
			// Honeypot. type 'string' (renderiza um <input type=text>), NUNCA
			// type 'hidden' sozinho -- scrapers procuram e pulam hidden. É o CSS
			// de Common.css que o esconde do humano; pro bot que ignora CSS ele
			// parece um campo normal preenchível. 'optional' pra nunca barrar
			// quem legitimamente deixa vazio (ou seja, todo humano).
			'rw_hp' => [
				'type' => 'string',
				'label' => new RawMessage( 'Website' ),
				'optional' => true,
			],
			// Timestamp assinado, injetado com 'value' no render. No POST de
			// volta o navegador devolve esse mesmo valor, que loadFromSubmission
			// carrega em $this->rw_ts.
			'rw_ts' => [
				'type' => 'hidden',
				'value' => $this->tsToRender,
				'optional' => true,
			],
		];
	}
}
