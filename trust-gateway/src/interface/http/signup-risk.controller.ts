import type { Request, Response } from 'express';
import type { SignupRiskService } from '../../application/signup-risk.service';

interface SignupRiskBody {
	username?: unknown;
	ip?: unknown;
	fingerprintHash?: unknown;
	elapsedSeconds?: unknown;
	honeypotHit?: unknown;
}

function isNonEmptyString(v: unknown): v is string {
	return typeof v === 'string' && v.length > 0;
}

export function makeSignupRiskController(service: SignupRiskService) {
	return async function signupRiskController(req: Request, res: Response): Promise<void> {
		const body = req.body as SignupRiskBody;

		if (!isNonEmptyString(body.username) || !isNonEmptyString(body.ip)) {
			res.status(400).json({ error: 'username e ip são obrigatórios' });
			return;
		}

		const fingerprintHash = isNonEmptyString(body.fingerprintHash) ? body.fingerprintHash : null;
		const elapsedSeconds = typeof body.elapsedSeconds === 'number' ? body.elapsedSeconds : null;
		const honeypotHit = body.honeypotHit === true;

		try {
			const result = await service.evaluate({
				username: body.username,
				ip: body.ip,
				fingerprintHash,
				elapsedSeconds,
				honeypotHit,
			});
			res.status(200).json(result);
		} catch (err) {
			// Falha interna (Redis/Postgres fora do ar etc.): devolve 'allow' com
			// score neutro em vez de 500 -- o cliente (AntiBotPreAuthenticationProvider,
			// que já faz fail-open em qualquer erro de rede) não precisa distinguir
			// "serviço fora" de "veredito allow"; mas logamos pra investigar depois.
			console.error('signup-risk falhou:', err);
			res.status(200).json({ verdict: 'allow', score: 0, band: 'low' });
		}
	};
}
