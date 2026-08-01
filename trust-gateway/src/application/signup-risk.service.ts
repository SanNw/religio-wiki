import { RiskScore, type SignupSignals } from '../domain/risk-score';
import type { SlidingWindowRateLimiter } from '../infrastructure/redis/sliding-window-rate-limiter';
import type { RedisFingerprintRepository } from '../infrastructure/redis/fingerprint.repository';
import type { AccountRepository } from '../infrastructure/postgres/account.repository';

export interface SignupRiskRequest {
	username: string;
	ip: string;
	fingerprintHash: string | null;
	/** Segundos entre o form ser renderizado e enviado (a Fase 1 já barra <3s; aqui só pondera o restante). */
	elapsedSeconds: number | null;
	honeypotHit: boolean;
}

export interface SignupRiskResult {
	verdict: 'allow' | 'block';
	score: number;
	band: string;
}

const SIGNUP_VELOCITY_WINDOW_SECONDS = 3600;
/** Acima disso por IP/hora já é sinal forte de automação -- normaliza pra 1.0. */
const SIGNUP_VELOCITY_SATURATION = 8;
/** Contas distintas usando o mesmo fingerprint na última hora antes de saturar o sinal em 1.0. */
const FINGERPRINT_REUSE_SATURATION = 5;

export class SignupRiskService {
	constructor(
		private readonly rateLimiter: SlidingWindowRateLimiter,
		private readonly fingerprintRepo: RedisFingerprintRepository,
		private readonly accountRepo: AccountRepository,
	) {}

	async evaluate(req: SignupRiskRequest): Promise<SignupRiskResult> {
		const signals: SignupSignals = {
			honeypotHit: req.honeypotHit,
		};

		if (!req.honeypotHit) {
			if (req.elapsedSeconds !== null) {
				// A Fase 1 (PHP) já rejeita <3s. Aqui só pondera a zona limítrofe
				// (3-5s) como moderadamente suspeita -- humano real raramente
				// preenche usuário+e-mail+senha tão rápido, mas não é impossível.
				signals.formTiming = req.elapsedSeconds < 5 ? 0.6 : 0;
			}

			const signupCount = await this.rateLimiter.currentCount(`signup:ip:${req.ip}`, SIGNUP_VELOCITY_WINDOW_SECONDS);
			signals.signupVelocity = Math.min(1, signupCount / SIGNUP_VELOCITY_SATURATION);

			if (req.fingerprintHash) {
				const reuseCount = await this.fingerprintRepo.reuseScore(req.fingerprintHash, req.username);
				signals.fingerprintReuse = Math.min(1, Math.max(0, reuseCount - 1) / FINGERPRINT_REUSE_SATURATION);
			}
		}

		// Registra esta tentativa na janela de velocidade, independente do
		// veredito -- inclusive tentativas bloqueadas contam pra detectar rajada.
		await this.rateLimiter.allow(`signup:ip:${req.ip}`, Number.MAX_SAFE_INTEGER, SIGNUP_VELOCITY_WINDOW_SECONDS);

		const score = RiskScore.fromSignals(signals);
		const verdict: 'allow' | 'block' = score.isBlocking() ? 'block' : 'allow';

		await this.accountRepo.logRiskDecision({
			username: req.username,
			ipAddress: req.ip,
			fingerprintHash: req.fingerprintHash,
			score: score.value,
			band: score.band(),
			verdict,
		});

		if (verdict === 'allow') {
			await this.accountRepo.recordAccountCreated(req.username);
		}

		return { verdict, score: score.value, band: score.band() };
	}
}
