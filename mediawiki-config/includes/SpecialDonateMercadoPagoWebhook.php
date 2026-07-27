<?php
/**
 * Special:DonateMercadoPagoWebhook -- recebe a notificação assíncrona que o
 * Mercado Pago envia quando o status de um pagamento muda (configurado como
 * "notification_url" na criação do pagamento em SpecialDonatePix.php, e/ou
 * cadastrado direto no painel Webhooks do Mercado Pago).
 *
 * Existe pra cobrir o caso em que o doador fecha a aba antes do polling do
 * front-end (Special:DonatePix/status) confirmar o Pix -- sem isso, um
 * pagamento aprovado nunca fica registrado em lugar nenhum. Não substitui o
 * polling (que continua dando o feedback instantâneo na própria página);
 * só garante um registro server-side independente do navegador do doador.
 *
 * Não existe tabela de doações no banco (todo o fluxo é stateless via
 * polling) -- este webhook só REGISTRA em log (mesmo canal 'religio-donate'
 * usado pelos erros do Stripe/Pix), não persiste nada. Se no futuro
 * precisar de uma lista de doações de verdade, é aqui que entraria a
 * gravação em banco.
 *
 * Suporta só o formato atual de Webhooks (POST com JSON + headers
 * X-Signature/X-Request-Id) -- não o IPN legado (GET com ?topic=&id=), que
 * o Mercado Pago já não recomenda pra integrações novas.
 */
class SpecialDonateMercadoPagoWebhook extends SpecialPage {

	public function __construct() {
		// listed=false: é um endpoint de máquina (webhook), não faz sentido
		// aparecer em Special:SpecialPages pra usuário nenhum.
		parent::__construct( 'DonateMercadoPagoWebhook', '', false );
	}

	public function doesWrites() {
		return false;
	}

	public function execute( $subPage ) {
		$out = $this->getOutput();
		$out->disable(); // resposta é JSON puro, não uma página wiki

		header( 'Content-Type: application/json; charset=utf-8' );

		$request = $this->getRequest();
		if ( !$request->wasPosted() ) {
			http_response_code( 405 );
			echo json_encode( [ 'error' => 'method_not_allowed' ] );
			return;
		}

		$accessToken = getenv( 'RW_MERCADOPAGO_ACCESS_TOKEN' );
		if ( !$accessToken ) {
			http_response_code( 503 );
			echo json_encode( [ 'error' => 'mercadopago_not_configured' ] );
			return;
		}

		$body = json_decode( $request->getRawPostString(), true );
		if ( !is_array( $body ) ) {
			http_response_code( 400 );
			echo json_encode( [ 'error' => 'invalid_body' ] );
			return;
		}

		// Formato de Webhooks v2: { "type": "payment", "data": { "id": "..." } }.
		// Notificações de outros tipos (ex.: "merchant_order") são só
		// confirmadas com 200 e ignoradas -- não é erro, só não interessa
		// aqui, e devolver erro faria o Mercado Pago ficar retentando à toa.
		$type = $body['type'] ?? null;
		$paymentId = $body['data']['id'] ?? null;
		if ( $type !== 'payment' || !$paymentId ) {
			http_response_code( 200 );
			echo json_encode( [ 'ok' => true, 'ignored' => true ] );
			return;
		}
		$paymentId = (string)$paymentId;

		if ( !$this->verifySignature( $request, $paymentId ) ) {
			wfDebugLog( 'religio-donate', "MP webhook: assinatura inválida pro pagamento {$paymentId}, ignorando" );
			http_response_code( 401 );
			echo json_encode( [ 'error' => 'invalid_signature' ] );
			return;
		}

		// Nunca confia no status vindo do corpo da notificação (o Mercado
		// Pago nem manda o status ali de qualquer forma) -- sempre busca o
		// pagamento de novo na API pra ter o status de verdade, mesmo padrão
		// já usado em SpecialDonatePix::checkStatus().
		\MercadoPago\MercadoPagoConfig::setAccessToken( $accessToken );
		$client = new \MercadoPago\Client\Payment\PaymentClient();
		try {
			$payment = $client->get( (int)$paymentId );
			wfDebugLog( 'religio-donate', sprintf(
				'MP webhook: pagamento %s status=%s valor=%s email=%s',
				$payment->id,
				$payment->status,
				$payment->transaction_amount ?? '?',
				$payment->payer->email ?? '?'
			) );
		} catch ( \MercadoPago\Exceptions\MPApiException $e ) {
			wfDebugLog( 'religio-donate', "MP webhook: erro ao consultar pagamento {$paymentId}: " . $e->getMessage() );
		}

		http_response_code( 200 );
		echo json_encode( [ 'ok' => true ] );
	}

	/**
	 * Valida o header X-Signature conforme a documentação do Mercado Pago
	 * ("Como validar a origem de uma notificação"): HMAC-SHA256 do manifesto
	 * "id:{data.id};request-id:{x-request-id};ts:{ts};" usando o segredo do
	 * webhook (RW_MERCADOPAGO_WEBHOOK_SECRET, cadastrado no painel Webhooks
	 * do Mercado Pago -- diferente do access token).
	 */
	private function verifySignature( WebRequest $request, string $paymentId ): bool {
		$secret = getenv( 'RW_MERCADOPAGO_WEBHOOK_SECRET' );
		if ( !$secret ) {
			// Sem o segredo configurado ainda (precisa ser criado no painel
			// Webhooks do Mercado Pago e colado no .env da VPS) -- deixa
			// passar sem validar, só logando, pra não quebrar o webhook
			// inteiro antes desse passo manual ser feito. Não é uma falha
			// crítica: o pior caso é uma entrada de log falsa, nada é escrito
			// em banco nem afeta o pagamento de verdade.
			wfDebugLog( 'religio-donate', 'MP webhook: RW_MERCADOPAGO_WEBHOOK_SECRET não configurado, pulando verificação de assinatura' );
			return true;
		}

		$signatureHeader = $request->getHeader( 'X-Signature' );
		$requestId = $request->getHeader( 'X-Request-Id' );
		if ( !$signatureHeader || !$requestId ) {
			return false;
		}

		$parts = [];
		foreach ( explode( ',', $signatureHeader ) as $pair ) {
			$kv = array_pad( explode( '=', $pair, 2 ), 2, null );
			$parts[trim( (string)$kv[0] )] = trim( (string)$kv[1] );
		}
		$ts = $parts['ts'] ?? null;
		$v1 = $parts['v1'] ?? null;
		if ( !$ts || !$v1 ) {
			return false;
		}

		$manifest = "id:{$paymentId};request-id:{$requestId};ts:{$ts};";
		$expected = hash_hmac( 'sha256', $manifest, $secret );

		return hash_equals( $expected, $v1 );
	}

	protected function getGroupName() {
		return 'other';
	}
}
