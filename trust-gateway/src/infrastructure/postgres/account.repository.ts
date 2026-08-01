import type { Pool } from 'pg';

/**
 * Grava/consulta o marco "conta criada" -- único marco de trust que este MVP
 * gerencia. Os demais marcos (e-mail confirmado, edições aprovadas) exigem
 * hooks de edição fora do escopo desta entrega (ver plano da Fase 2).
 */
export class AccountRepository {
	constructor(private readonly pool: Pool) {}

	async recordAccountCreated(username: string): Promise<void> {
		await this.pool.query(
			`INSERT INTO accounts (username, trust_score, account_created_at)
			 VALUES ($1, 10, now())
			 ON CONFLICT (username) DO NOTHING`,
			[username],
		);
	}

	async logRiskDecision(params: {
		username: string;
		ipAddress: string | null;
		fingerprintHash: string | null;
		score: number;
		band: string;
		verdict: 'allow' | 'block';
	}): Promise<void> {
		await this.pool.query(
			`INSERT INTO risk_decisions (username, ip_address, fingerprint_hash, score, band, verdict)
			 VALUES ($1, $2, $3, $4, $5, $6)`,
			[
				params.username,
				params.ipAddress,
				params.fingerprintHash,
				params.score,
				params.band,
				params.verdict,
			],
		);
	}
}
