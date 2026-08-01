/**
 * RiskScore -- soma ponderada de sinais normalizados (0-1) em um score final
 * 0-100. Pesos e bandas conforme §02 do documento de design
 * (scratch/religio-antibot-trust-gateway.html). Pesos somam 100.
 *
 * Nem todo sinal do design está disponível no MVP (cadastro): keystrokeCadence,
 * mouseTrajectory, scrollFocus, jsEnabled e vpnOrTor dependem de coleta
 * comportamental/serviço de reputação de IP que ainda não existe nesta
 * entrega. Um sinal ausente (undefined) não contribui risco (tratado como 0)
 * -- em vez de puxar o score pra cima por falta de dado, o que penalizaria
 * incorretamente todo mundo enquanto os sinais futuros não forem
 * implementados.
 */

export interface SignupSignals {
	/** 0-1: quão suspeito o tempo de preenchimento do form foi (perto de 0 = normal). */
	formTiming?: number;
	keystrokeCadence?: number;
	mouseTrajectory?: number;
	scrollFocus?: number;
	jsEnabled?: number;
	/** 0-1: reputação ruim do IP (datacenter conhecido, blocklist etc.). */
	ipReputation?: number;
	vpnOrTor?: number;
	/** 0-1: quantos cadastros esse IP/rede fez recentemente, normalizado. */
	signupVelocity?: number;
	/** 0-1: quantas contas já usaram esse mesmo fingerprint recentemente. */
	fingerprintReuse?: number;
	/** Honeypot preenchido = certeza de bot; satura o score em 100. */
	honeypotHit?: boolean;
}

export type RiskBand = 'low' | 'medium' | 'high' | 'veryHigh' | 'extreme';

const SIGNAL_WEIGHTS: Record<keyof Omit<SignupSignals, 'honeypotHit'>, number> = {
	formTiming: 14,
	keystrokeCadence: 16,
	mouseTrajectory: 14,
	scrollFocus: 8,
	jsEnabled: 10,
	ipReputation: 14,
	vpnOrTor: 8,
	signupVelocity: 10,
	fingerprintReuse: 6,
};

export class RiskScore {
	private constructor(public readonly value: number) {}

	static fromSignals(signals: SignupSignals): RiskScore {
		if (signals.honeypotHit) {
			return new RiskScore(100);
		}

		let total = 0;
		for (const key of Object.keys(SIGNAL_WEIGHTS) as Array<keyof typeof SIGNAL_WEIGHTS>) {
			const raw = signals[key];
			if (raw === undefined) {
				continue;
			}
			const clamped = Math.min(1, Math.max(0, raw));
			total += clamped * SIGNAL_WEIGHTS[key];
		}

		return new RiskScore(Math.min(100, Math.round(total)));
	}

	band(): RiskBand {
		if (this.value < 20) return 'low';
		if (this.value < 45) return 'medium';
		if (this.value < 70) return 'high';
		if (this.value < 90) return 'veryHigh';
		return 'extreme';
	}

	/** MVP: só extreme/veryHigh bloqueiam no cadastro -- ver signup-risk.service.ts. */
	isBlocking(): boolean {
		const band = this.band();
		return band === 'veryHigh' || band === 'extreme';
	}
}
