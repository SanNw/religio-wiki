<?php
/**
 * Special:DonatePix -- cria um pagamento Pix via Mercado Pago pra doações
 * únicas. Diferente do Special:DonateCheckout (Stripe, cartão/boleto), aqui
 * não há redirecionamento: o QR code + código "copia e cola" são devolvidos
 * como JSON e mostrados na PRÓPRIA página (ver MediaWiki:Common.js), e o
 * front-end consulta Special:DonatePix/status periodicamente até o
 * pagamento ser confirmado.
 *
 * Usa a API CLÁSSICA de Payments (PaymentClient, endpoint /v1/payments),
 * não a Orders API mais nova -- testado ao vivo e confirmado que a Orders
 * API rejeita credenciais TEST- ("Test credentials are not supported, use
 * test users with production credentials..."), mas a API de Payments
 * aceita TEST- diretamente, do jeito tradicional de sandbox do Mercado
 * Pago.
 *
 * Sem subpágina (POST comum) = cria o pagamento.
 * Subpágina "status" (POST com order_id = id do pagamento) = consulta o
 * status atual.
 *
 * Chave de API só existe como variável de ambiente
 * (RW_MERCADOPAGO_ACCESS_TOKEN, ver docker-compose.yml / .env), nunca em
 * código -- mesmo padrão do Stripe.
 */
class SpecialDonatePix extends SpecialPage {

	public function __construct() {
		parent::__construct( 'DonatePix' );
	}

	public function doesWrites() {
		return false;
	}

	private function configure() {
		$accessToken = getenv( 'RW_MERCADOPAGO_ACCESS_TOKEN' );
		if ( !$accessToken ) {
			return false;
		}
		\MercadoPago\MercadoPagoConfig::setAccessToken( $accessToken );
		return true;
	}

	public function execute( $subPage ) {
		$out = $this->getOutput();
		$out->disable(); // resposta é JSON puro, não uma página wiki

		header( 'Content-Type: application/json; charset=utf-8' );

		$request = $this->getRequest();
		if ( !$request->wasPosted() ) {
			http_response_code( 400 );
			echo json_encode( [ 'error' => 'method_not_allowed' ] );
			return;
		}

		if ( !$this->configure() ) {
			http_response_code( 400 );
			echo json_encode( [ 'error' => 'mercadopago_not_configured' ] );
			return;
		}

		$body = json_decode( $request->getRawPostString(), true );
		if ( !is_array( $body ) ) {
			http_response_code( 400 );
			echo json_encode( [ 'error' => 'invalid_body' ] );
			return;
		}

		if ( $subPage === 'status' ) {
			$this->checkStatus( $body );
			return;
		}

		$this->createPayment( $body );
	}

	private function createPayment( array $body ) {
		$amountReais = $body['amount'] ?? null;
		$email = $body['email'] ?? null;

		if ( !is_numeric( $amountReais ) || $amountReais < 1 || $amountReais > 50000 ) {
			http_response_code( 400 );
			echo json_encode( [ 'error' => 'invalid_amount' ] );
			return;
		}
		if ( !$email || !filter_var( $email, FILTER_VALIDATE_EMAIL ) ) {
			http_response_code( 400 );
			echo json_encode( [ 'error' => 'invalid_email' ] );
			return;
		}

		$client = new \MercadoPago\Client\Payment\PaymentClient();
		$requestOptions = new \MercadoPago\Client\Common\RequestOptions();
		// Chave em MINÚSCULO -- bug confirmado no SDK: ele verifica a
		// existência via array_change_key_case() (case-insensitive) mas
		// depois acessa o array ORIGINAL com a chave em minúsculo, então
		// uma chave passada com maiúsculas nunca é encontrada de verdade.
		$requestOptions->setCustomHeaders( [ 'x-idempotency-key' => bin2hex( random_bytes( 16 ) ) ] );

		$paymentData = [
			'transaction_amount' => (float) $amountReais,
			'description' => 'Doação — Religio Wiki',
			'payment_method_id' => 'pix',
			'payer' => [
				'email' => $email,
			],
		];

		try {
			$payment = $client->create( $paymentData, $requestOptions );
			$txData = $payment->point_of_interaction->transaction_data ?? null;
			$qrCode = $txData->qr_code ?? null;
			$qrCodeBase64 = $txData->qr_code_base64 ?? null;

			if ( !$qrCode ) {
				// Formato de resposta inesperado -- loga a resposta crua pra
				// depuração em vez de falhar silenciosamente com dado pela metade.
				wfDebugLog( 'religio-donate', 'MP Pix: qr_code ausente. Resposta: ' . json_encode( $payment ) );
				http_response_code( 400 );
				echo json_encode( [ 'error' => 'unexpected_response' ] );
				return;
			}

			echo json_encode( [
				'order_id' => (string) $payment->id,
				'qr_code' => $qrCode,
				'qr_code_base64' => $qrCodeBase64,
			] );
		} catch ( \MercadoPago\Exceptions\MPApiException $e ) {
			wfDebugLog( 'religio-donate', 'MP error: ' . $e->getMessage() . ' | ' . ( $e->getApiResponse() ? json_encode( $e->getApiResponse()->getContent() ) : '' ) );
			http_response_code( 400 );
			echo json_encode( [ 'error' => 'mercadopago_error' ] );
		}
	}

	private function checkStatus( array $body ) {
		$paymentId = $body['order_id'] ?? null;
		if ( !$paymentId || !ctype_digit( (string) $paymentId ) ) {
			http_response_code( 400 );
			echo json_encode( [ 'error' => 'invalid_payment_id' ] );
			return;
		}

		$client = new \MercadoPago\Client\Payment\PaymentClient();
		try {
			$payment = $client->get( (int) $paymentId );
			// status da API clássica de Payments: 'approved' (pago),
			// 'pending' (aguardando), 'rejected'/'cancelled' (falhou).
			// Front-end (Common.js) espera 'processed' pra sucesso -- traduz
			// aqui pra manter o mesmo contrato entre Stripe e Mercado Pago.
			$status = $payment->status === 'approved' ? 'processed' : $payment->status;
			echo json_encode( [ 'status' => $status ] );
		} catch ( \MercadoPago\Exceptions\MPApiException $e ) {
			wfDebugLog( 'religio-donate', 'MP status error: ' . $e->getMessage() );
			http_response_code( 400 );
			echo json_encode( [ 'error' => 'mercadopago_error' ] );
		}
	}

	protected function getGroupName() {
		return 'other';
	}
}
