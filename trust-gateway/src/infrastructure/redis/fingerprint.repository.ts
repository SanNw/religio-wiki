import type { Redis } from 'ioredis';

/**
 * Dedupe de fingerprint com TTL curto (1h -- ver §04 do design). O
 * fingerprint NUNCA é chave primária de identidade, só sinal de correlação:
 * quantas contas diferentes usaram esse mesmo hash de fingerprint na última
 * hora. Reuso alto = sinal de automação criando várias contas do mesmo
 * navegador/máquina.
 *
 * TTL curto de propósito (LGPD, minimização/retenção): não guardamos
 * histórico longo do fingerprint, só o suficiente pra pegar rajadas.
 */
const TTL_SECONDS = 60 * 60;

export class RedisFingerprintRepository {
	constructor(private readonly redis: Redis) {}

	/**
	 * Registra que `accountIdentifier` usou `fingerprintHash` agora, e devolve
	 * quantas contas distintas já usaram esse hash na última hora (incluindo
	 * esta).
	 */
	async reuseScore(fingerprintHash: string, accountIdentifier: string): Promise<number> {
		const key = `fp:${fingerprintHash}`;
		await this.redis.sadd(key, accountIdentifier);
		await this.redis.expire(key, TTL_SECONDS);
		return this.redis.scard(key);
	}
}
