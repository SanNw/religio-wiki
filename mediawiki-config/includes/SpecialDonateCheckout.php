<?php
/**
 * Special:DonateCheckout -- recebe o valor/frequência/método escolhidos no
 * widget de MediaWiki:Common.js (página Religio Wiki:Doar) e cria uma
 * Stripe Checkout Session, devolvendo a URL de pagamento hospedada pelo
 * próprio Stripe (nenhum dado de cartão passa pelo nosso servidor).
 *
 * Pix e Boleto são métodos de ação única -- não existe "débito automático"
 * neles -- então só ficam disponíveis quando a frequência é "unico".
 * Mensal/anual são sempre forçados pra "card" aqui no servidor, mesmo que o
 * front-end já filtre isso na UI (defesa em profundidade).
 */
class SpecialDonateCheckout extends SpecialPage {

	public function __construct() {
		parent::__construct( 'DonateCheckout' );
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

		$secretKey = getenv( 'RW_STRIPE_SECRET_KEY' );
		if ( !$secretKey ) {
			http_response_code( 503 );
			echo json_encode( [ 'error' => 'stripe_not_configured' ] );
			return;
		}

		$body = json_decode( $request->getRawPostString(), true );
		if ( !is_array( $body ) ) {
			http_response_code( 400 );
			echo json_encode( [ 'error' => 'invalid_body' ] );
			return;
		}

		$amountReais = $body['amount'] ?? null;
		$frequency = $body['frequency'] ?? null;
		// Chave ASCII simples ('pix'|'boleto'|'card'), não o rótulo em
		// português do botão -- o rótulo fica só de responsabilidade da UI
		// (MediaWiki:Common.js), o protocolo entre JS e PHP não depende de
		// acentuação (bytes não-ASCII em querystring/JSON já causaram bug
		// de encoding nesta mesma sessão, então evita por completo aqui).
		$method = $body['method'] ?? null;

		if ( !is_numeric( $amountReais ) || $amountReais < 1 || $amountReais > 50000 ) {
			http_response_code( 400 );
			echo json_encode( [ 'error' => 'invalid_amount' ] );
			return;
		}
		if ( !in_array( $frequency, [ 'unico', 'mensal', 'anual' ], true ) ) {
			http_response_code( 400 );
			echo json_encode( [ 'error' => 'invalid_frequency' ] );
			return;
		}
		if ( !in_array( $method, [ 'pix', 'boleto', 'card' ], true ) ) {
			http_response_code( 400 );
			echo json_encode( [ 'error' => 'invalid_method' ] );
			return;
		}

		$isRecurring = $frequency !== 'unico';
		$amountCents = (int) round( $amountReais * 100 );

		// Recorrente força "card" sempre, não importa o que veio no body --
		// Pix/Boleto não têm cobrança automática recorrente no Stripe (defesa
		// em profundidade -- a UI já esconde essas opções nesse caso).
		$paymentMethodType = $isRecurring ? 'card' : $method;

		\Stripe\Stripe::setApiKey( $secretKey );

		$donatePage = Title::newFromText( 'Religio Wiki:Doar' );
		$baseUrl = $donatePage->getFullURL();
		$successUrl = wfAppendQuery( $baseUrl, [ 'doacao' => 'sucesso' ] );
		$cancelUrl = wfAppendQuery( $baseUrl, [ 'doacao' => 'cancelado' ] );

		$productData = [ 'name' => 'Doação — Religio Wiki' ];

		try {
			if ( $isRecurring ) {
				$interval = $frequency === 'mensal' ? 'month' : 'year';
				$session = \Stripe\Checkout\Session::create( [
					'mode' => 'subscription',
					'payment_method_types' => [ 'card' ],
					'line_items' => [ [
						'quantity' => 1,
						'price_data' => [
							'currency' => 'brl',
							'unit_amount' => $amountCents,
							'product_data' => $productData,
							'recurring' => [ 'interval' => $interval ],
						],
					] ],
					'success_url' => $successUrl,
					'cancel_url' => $cancelUrl,
				] );
			} else {
				$session = \Stripe\Checkout\Session::create( [
					'mode' => 'payment',
					'payment_method_types' => [ $paymentMethodType ],
					'line_items' => [ [
						'quantity' => 1,
						'price_data' => [
							'currency' => 'brl',
							'unit_amount' => $amountCents,
							'product_data' => $productData,
						],
					] ],
					'success_url' => $successUrl,
					'cancel_url' => $cancelUrl,
				] );
			}
			echo json_encode( [ 'url' => $session->url ] );
		} catch ( \Stripe\Exception\ApiErrorException $e ) {
			wfDebugLog( 'religio-donate', 'Stripe error: ' . $e->getMessage() );
			http_response_code( 502 );
			echo json_encode( [ 'error' => 'stripe_error' ] );
		}
	}

	protected function getGroupName() {
		return 'other';
	}
}
