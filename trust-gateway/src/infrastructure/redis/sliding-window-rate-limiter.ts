import type { Redis } from 'ioredis';

/**
 * Rate limiting via sliding window (ZADD/ZREMRANGEBYSCORE), não token bucket
 * simples -- token bucket permite explosão no início da janela; sliding
 * window conta exatamente quantos eventos caíram nos últimos N segundos.
 * Ver §05 do documento de design.
 */
export class SlidingWindowRateLimiter {
	constructor(private readonly redis: Redis) {}

	/**
	 * Registra uma tentativa para `key` e devolve se ela está dentro do
	 * limite (`count` eventos por `windowSeconds`).
	 */
	async allow(key: string, count: number, windowSeconds: number): Promise<boolean> {
		const now = Date.now();
		const windowStart = now - windowSeconds * 1000;
		const redisKey = `ratelimit:${key}`;

		const pipeline = this.redis.pipeline();
		pipeline.zremrangebyscore(redisKey, 0, windowStart);
		pipeline.zadd(redisKey, now, `${now}:${Math.random()}`);
		pipeline.zcard(redisKey);
		pipeline.expire(redisKey, windowSeconds);
		const results = await pipeline.exec();

		const cardResult = results?.[2];
		const total = (cardResult?.[1] as number) ?? 0;
		return total <= count;
	}

	/** Quantos eventos essa chave já teve na janela atual (sem registrar um novo). */
	async currentCount(key: string, windowSeconds: number): Promise<number> {
		const now = Date.now();
		const windowStart = now - windowSeconds * 1000;
		const redisKey = `ratelimit:${key}`;
		await this.redis.zremrangebyscore(redisKey, 0, windowStart);
		return this.redis.zcard(redisKey);
	}
}
