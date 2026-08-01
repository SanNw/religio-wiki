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
 * Três checagens locais, todas de baixo custo e alta precisão (praticamente
 * impossível um humano real disparar qualquer uma por acidente):
 *   1. Honeypot preenchido      -> bot preencheu campo escondido por CSS.
 *   2. Timestamp ausente/forjado -> form adulterado (assinatura HMAC não bate).
 *   3. Preenchido rápido demais  -> submissão abaixo do piso humano plausível.
 * Essas três são stateless -- o timestamp assinado carrega a própria prova,
 * sem depender de nenhum serviço externo.
 *
 * Fase 2 (ver trust-gateway/ e scratch/religio-antibot-trust-gateway.html)
 * soma uma quarta checagem, com estado: uma chamada HTTP síncrona e curta ao
 * serviço trust-gateway (POST /trust/signup-risk), que pondera fingerprint,
 * IP e velocidade de cadastro num bot score. Só entra em jogo se as três
 * checagens locais já passaram. Fail-open por design: se o serviço estiver
 * fora do ar ou não configurado ($wgTrustGatewayUrl vazio), o cadastro segue
 * normalmente -- nunca trava um humano legítimo por uma falha interna nossa.
 *
 * Qualquer checagem que dispare aborta com uma mensagem GENÉRICA (não conta
 * ao bot qual regra pegou) e registra o motivo real no log religio-antibot
 * (mesmo canal/volume do religio-donate).
 */

use MediaWiki\Auth\AbstractPreAuthenticationProvider;
use MediaWiki\Auth\AuthenticationRequest;
use MediaWiki\Auth\AuthManager;
use MediaWiki\Language\RawMessage;
use MediaWiki\MediaWikiServices;
use RequestContext;
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
	 * Timeout, em segundos, pra chamada HTTP ao trust-gateway. Curto de
	 * propósito: essa checagem roda no caminho síncrono do cadastro, então um
	 * serviço lento não pode virar um cadastro lento (ou travado) pro usuário.
	 * Se estourar, cai no fail-open (ver chamada em testForAccountCreation()).
	 */
	private const TRUST_GATEWAY_TIMEOUT_SECONDS = 2;

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

		// 4. Trust Gateway (Fase 2): bot score com estado (fingerprint, IP,
		// velocidade de cadastro). Só chamado depois das checagens locais
		// passarem -- elas são de graça, esta tem custo de rede.
		if ( $this->trustGatewayBlocks( $req, $user ) ) {
			return $this->reject( 'trust-gateway-block', $user );
		}

		return StatusValue::newGood();
	}

	/**
	 * Consulta o serviço trust-gateway (POST /trust/signup-risk) e devolve
	 * true só quando ele responde explicitamente com veredito de bloqueio.
	 * Fail-open em qualquer outro caso -- config vazia, timeout, erro de
	 * rede, corpo malformado -- porque a indisponibilidade de um serviço
	 * interno auxiliar nunca deve impedir um cadastro humano legítimo (a
	 * Fase 1, já passada neste ponto, continua sendo a defesa de base).
	 * @param AntiBotAuthenticationRequest $req
	 * @param mixed $user
	 * @return bool
	 */
	private function trustGatewayBlocks( AntiBotAuthenticationRequest $req, $user ): bool {
		$baseUrl = (string)$this->config->get( 'TrustGatewayUrl' );
		if ( $baseUrl === '' ) {
			return false;
		}

		$elapsedSeconds = null;
		if ( strpos( (string)$req->rw_ts, ':' ) !== false ) {
			[ $tsPart ] = explode( ':', (string)$req->rw_ts, 2 );
			if ( ctype_digit( $tsPart ) ) {
				$elapsedSeconds = (int)wfTimestamp( TS_UNIX ) - (int)$tsPart;
			}
		}

		$name = is_object( $user ) && method_exists( $user, 'getName' )
			? $user->getName() : '?';
		$ip = RequestContext::getMain()->getRequest()->getIP();

		$payload = [
			'username' => $name,
			'ip' => $ip,
			// Chegou até aqui = honeypot vazio (já teria rejeitado antes).
			'honeypotHit' => false,
			'fingerprintHash' => $req->rw_fp !== null && $req->rw_fp !== ''
				? (string)$req->rw_fp : null,
			'elapsedSeconds' => $elapsedSeconds,
		];

		try {
			$httpFactory = MediaWikiServices::getInstance()->getHttpRequestFactory();
			$httpRequest = $httpFactory->create(
				rtrim( $baseUrl, '/' ) . '/trust/signup-risk',
				[
					'method' => 'POST',
					'postData' => json_encode( $payload ),
					'timeout' => self::TRUST_GATEWAY_TIMEOUT_SECONDS,
				],
				__METHOD__
			);
			$httpRequest->setHeader( 'Content-Type', 'application/json' );
			$status = $httpRequest->execute();

			if ( !$status->isOK() ) {
				// Serviço fora do ar, timeout, DNS etc. -- fail-open.
				wfDebugLog( 'religio-antibot',
					"trust-gateway indisponível usuario={$name}: " . (string)$status );
				return false;
			}

			$body = json_decode( $httpRequest->getContent(), true );
			if ( !is_array( $body ) || !isset( $body['verdict'] ) ) {
				// Corpo inesperado -- trata como indisponível, não como bloqueio.
				wfDebugLog( 'religio-antibot',
					"trust-gateway resposta malformada usuario={$name}" );
				return false;
			}

			wfDebugLog( 'religio-antibot',
				"trust-gateway veredito={$body['verdict']} score=" .
				( $body['score'] ?? '?' ) . " banda=" . ( $body['band'] ?? '?' ) .
				" usuario={$name}" );

			return $body['verdict'] === 'block';
		} catch ( \Throwable $e ) {
			// Qualquer exceção inesperada -- nunca deixa o cadastro travar
			// por um bug/instabilidade do serviço auxiliar.
			wfDebugLog( 'religio-antibot',
				"trust-gateway erro usuario={$name}: " . $e->getMessage() );
			return false;
		}
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
		$secret = (string)$this->config->get( 'SecretKey' );
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
