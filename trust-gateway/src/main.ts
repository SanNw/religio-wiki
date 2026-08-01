import { readFileSync } from 'node:fs';
import { join } from 'node:path';
import express from 'express';
import Redis from 'ioredis';
import { Pool } from 'pg';

import { SlidingWindowRateLimiter } from './infrastructure/redis/sliding-window-rate-limiter';
import { RedisFingerprintRepository } from './infrastructure/redis/fingerprint.repository';
import { AccountRepository } from './infrastructure/postgres/account.repository';
import { SignupRiskService } from './application/signup-risk.service';
import { makeSignupRiskController } from './interface/http/signup-risk.controller';

const PORT = Number(process.env.PORT ?? 3001);
const REDIS_URL = process.env.REDIS_URL ?? 'redis://redis:6379';
const DATABASE_URL = process.env.DATABASE_URL;

if (!DATABASE_URL) {
	throw new Error('DATABASE_URL não definida (ver docker-compose.yml)');
}

const redis = new Redis(REDIS_URL);
const pool = new Pool({ connectionString: DATABASE_URL });

async function runMigrations(): Promise<void> {
	// Sem framework de migration (projeto pequeno, um arquivo só) -- aplica o
	// SQL direto no boot. Todo statement usa CREATE TABLE/INDEX IF NOT EXISTS,
	// então rodar de novo em todo restart do container é seguro (idempotente),
	// mesmo padrão de idempotência já usado em scripts/deploy-wiki-content.sh.
	const sql = readFileSync(join(__dirname, '../migrations/001_trust_gateway.sql'), 'utf8');
	await pool.query(sql);
}

const rateLimiter = new SlidingWindowRateLimiter(redis);
const fingerprintRepo = new RedisFingerprintRepository(redis);
const accountRepo = new AccountRepository(pool);
const signupRiskService = new SignupRiskService(rateLimiter, fingerprintRepo, accountRepo);

const app = express();
app.use(express.json());

app.get('/health', (_req, res) => {
	res.status(200).json({ ok: true });
});

app.post('/trust/signup-risk', makeSignupRiskController(signupRiskService));

runMigrations()
	.then(() => {
		app.listen(PORT, () => {
			console.log(`trust-gateway ouvindo na porta ${PORT}`);
		});
	})
	.catch((err) => {
		console.error('falha ao aplicar migrations:', err);
		process.exit(1);
	});
