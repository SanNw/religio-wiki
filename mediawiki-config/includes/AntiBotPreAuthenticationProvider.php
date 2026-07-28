<?php
/**
 * AntiBotPreAuthenticationProvider -- Fase 1 do sistema anti-bot ("Trust
 * Gateway", ver scratch/religio-antibot-trust-gateway.html). Valida os campos
 * invisíveis declarados por AntiBotAuthenticationRequest e barra a criação de
 * conta quando os sinais indicam automação -- SEM captcha visível, sem atrito
 * pro humano.
 *
 * Mecanismo canônico do AuthManager (MW 1.43, REL1_43): registrado em
 * $wgAuthManagerAutoConfig['preauth'] (ver LocalSettings-snippet.php). É o
 * MESMO ponto de extensão que o ConfirmEdit usa internamente. Substitui o hook
 * AbortNewAccount, que foi REMOVIDO no MediaWiki 1.33.
 *
 * Três checagens, todas de baixo custo e alta precisão (praticamente impossível
 * um humano real disparar qualquer uma por acidente):
 *   1. Honeypot preenchido      -> bot preencheu campo escondido por CSS.
 *   2. Timestamp ausente/forjado -> form adulterado (assinatura HMAC não bate).
 *   3. Preenchido rápido demais  -> submissão abaixo do piso humano plausível.
 *
 * Qualquer uma que dispare aborta com uma mensagem GENÉRICA (não conta ao bot
 * qual regra pegou) e registra o motivo real no log religio-antibot (mesmo
 * canal/volume do religio-donate). Não há banco nem estado: é stateless, o
 * timestamp assinado carrega a própria prova.
 */

use MediaWiki\Auth\AbstractPreAuthenticationProvider;
use MediaWiki\Auth\AuthenticationRequest;
use MediaWiki\Auth\AuthManager;
use MediaWiki\Language\RawMessage;
use StatusValue;

class AntiBotPreAuthenticationProvider extends AbstractPreAuthenticationProvider {

	/**
	 * Piso de tempo, em segundos, entre renderizar o form e enviá-lo. Ninguém
	 * lê e preenche nome/e-mail/senha em menos que isto; um script preenche em
	 * milissegundos. Conservador de propósito (erra pro lado de deixar humano
	 * passar).
	 */
	private const MIN_FILL_SECONDS = 3;

	/**
	 * Janela máxima de validade do timestamp assinado, em segundos. Além disto
	 * o token é considerado velho (form deixado aberto por horas, ou replay de
	 * um valor capturado antes) e um novo é exigido. 1h é folgado pra um humano
	 * e ainda limita reuso.
	 */
	private const MAX_TOKEN_AGE_SECONDS = 3600;

	/**
	 * Injeta o request só na criação de conta, já com o timestamp assinado
	 * embutido pro render do formulário.
	 * @inheritDoc
	 */
	public function getAuthenticationRequests( $action, array $options ) {
		if ( $action !== AuthManager::ACTION_CREATE ) {
			return [];
		}
		$req = new AntiBotAuthenticationRequest();
		$req->tsToRender = $this->makeSignedTimestamp( (int)wfTimestamp( TS_UNIX ) );
		return [ $req ];
	}

	/**
	 * @inheritDoc
	 */
	public function testForAccountCreation( $user, $creator, array $reqs ) {
		/** @var AntiBotAuthenticationRequest|null $req */
		$req = AuthenticationRequest::getRequestByClass(
			$reqs, AntiBotAuthenticationRequest::class
		);

		// Sem o nosso request no POST = formulário que não passou pelo nosso
		// render (submissão direta a máquina, sem carregar a página primeiro).
		// Trata como bot, mas loga distinto pra diferenciar de um falso-positivo
		// de config (ex.: provider não registrado ainda num deploy pela metade).
		if ( !$req ) {
			return $this->reject( 'sem-request', $user );
		}

		// 1. Honeypot: qualquer valor não-vazio veio de automação.
		if ( $req->rw_hp !== null && trim( (string)$req->rw_hp ) !== '' ) {
			return $this->reject( 'honeypot', $user );
		}

		// 2/3. Timestamp assinado: valida assinatura e mede o tempo de preenchimento.
		$verdict = $this->checkTimestamp( (string)$req->rw_ts );
		if ( $verdict !== null ) {
			return $this->reject( $verdict, $user );
		}

		return StatusValue::newGood();
	}

	/**
	 * Valida o rw_ts ("{tempo}:{hmac}"). Retorna null se OK, ou uma string de
	 * motivo se deve rejeitar.
	 * @param string $value
	 * @return string|null
	 */
	private function checkTimestamp( string $value ) {
		if ( $value === '' || strpos( $value, ':' ) === false ) {
			return 'ts-ausente';
		}
		[ $tsPart, $sigPart ] = explode( ':', $value, 2 );
		if ( !ctype_digit( $tsPart ) ) {
			return 'ts-malformado';
		}
		// Assinatura confere? (defende contra forjar/adulterar o campo)
		$expected = $this->signTimestamp( (int)$tsPart );
		if ( !hash_equals( $expected, $sigPart ) ) {
			return 'ts-assinatura-invalida';
		}
		$age = (int)wfTimestamp( TS_UNIX ) - (int)$tsPart;
		if ( $age < 0 || $age > self::MAX_TOKEN_AGE_SECONDS ) {
			// Timestamp do futuro (relógio adulterado) ou velho demais (replay).
			return 'ts-fora-da-janela';
		}
		if ( $age < self::MIN_FILL_SECONDS ) {
			return 'rapido-demais';
		}
		return null;
	}

	/**
	 * Monta "{tempo}:{hmac}" pra embutir no formulário renderizado.
	 * @param int $now
	 * @return string
	 */
	private function makeSignedTimestamp( int $now ): string {
		return $now . ':' . $this->signTimestamp( $now );
	}

	/**
	 * HMAC-SHA256 do tempo com a chave secreta do wiki ($wgSecretKey). A chave
	 * nunca sai do servidor, então o cliente não consegue gerar um timestamp
	 * válido novo -- só devolver o que recebeu no render.
	 * @param int $ts
	 * @return string
	 */
	private function signTimestamp( int $ts ): string {
		$secret = (string)$this->getConfig()->get( 'SecretKey' );
		return hash_hmac( 'sha256', (string)$ts, $secret );
	}

	/**
	 * Registra o motivo real no log e devolve um erro GENÉRICO pro usuário (sem
	 * revelar qual checagem pegou -- não ensina o bot a contornar).
	 * @param string $reason
	 * @param mixed $user
	 * @return StatusValue
	 */
	private function reject( string $reason, $user ): StatusValue {
		$name = is_object( $user ) && method_exists( $user, 'getName' )
			? $user->getName() : '?';
		wfDebugLog( 'religio-antibot',
			"cadastro bloqueado motivo={$reason} usuario={$name}" );
		// Mensagem genérica e neutra (não denuncia o mecanismo ao bot). Usa
		// RawMessage pra não depender de nenhuma chave de i18n de extensão --
		// mesma decisão de outros pontos do projeto feitos só via snippet.
		return StatusValue::newFatal( new RawMessage(
			'Não foi possível concluir o cadastro. Tente novamente em alguns instantes.'
		) );
	}
}
