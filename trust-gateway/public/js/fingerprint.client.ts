/**
 * Coleta de fingerprint client-side (Fase 2, §04 do documento de design).
 * Roda no NAVEGADOR do usuário -- fonte de referência em TypeScript. A
 * versão que de fato executa no wiki é a tradução direta pra JS puro
 * embutida em MediaWiki:Common.js (ver mediawiki-config/common.js, bloco
 * "rw-antibot-fingerprint"), porque o MediaWiki não compila TypeScript.
 * Mantenha as duas em sincronia se este arquivo mudar.
 *
 * Sinais combinados: canvas (anti-aliasing/subpixel varia por GPU/driver),
 * WebGL (fabricante/modelo via UNMASKED_RENDERER_WEBGL), resolução/pixel
 * ratio, timezone, idioma, hardwareConcurrency/deviceMemory, e impressão do
 * AudioContext. Só o HASH final (SHA-256) sai do navegador -- nenhum
 * atributo bruto é enviado ao servidor (LGPD, minimização de dados).
 */
export async function collectFingerprint(): Promise<string> {
	const parts: string[] = [];

	const canvas = document.createElement('canvas');
	const ctx = canvas.getContext('2d');
	if (ctx) {
		ctx.textBaseline = 'top';
		ctx.font = '14px Arial';
		ctx.fillText('Religio Wiki fingerprint', 2, 2);
		parts.push(canvas.toDataURL());
	}

	const gl = document.createElement('canvas').getContext('webgl');
	const dbg = gl?.getExtension('WEBGL_debug_renderer_info');
	if (gl && dbg) {
		parts.push(String(gl.getParameter(dbg.UNMASKED_RENDERER_WEBGL)));
	}

	parts.push(`${screen.width}x${screen.height}@${devicePixelRatio}`);
	parts.push(Intl.DateTimeFormat().resolvedOptions().timeZone);
	parts.push(navigator.language);
	parts.push(String(navigator.hardwareConcurrency ?? ''));
	parts.push(String((navigator as unknown as { deviceMemory?: number }).deviceMemory ?? ''));

	try {
		const AudioCtx = window.AudioContext || (window as unknown as { webkitAudioContext?: typeof AudioContext }).webkitAudioContext;
		if (AudioCtx) {
			const ac = new AudioCtx();
			const osc = ac.createOscillator();
			const comp = ac.createDynamicsCompressor();
			osc.connect(comp);
			comp.connect(ac.destination);
			osc.start(0);
			parts.push(String(ac.sampleRate));
			await ac.close();
		}
	} catch {
		// AudioContext indisponível -- só reduz precisão, não quebra o fluxo.
	}

	const enc = new TextEncoder().encode(parts.join('|'));
	const digest = await crypto.subtle.digest('SHA-256', enc);
	return [...new Uint8Array(digest)].map((b) => b.toString(16).padStart(2, '0')).join('');
}
