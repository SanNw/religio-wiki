-- Trust Gateway -- schema inicial (MVP: cadastro + trust básico).
-- Reduzido do §14 do documento de design (scratch/religio-antibot-trust-gateway.html):
-- a tabela "blocklist" (whitelist/blacklist manual de IP/ASN/fingerprint)
-- fica para a sub-fase do painel admin, que ainda não existe nesta entrega.

-- Uma linha por conta do MediaWiki que passou pelo Trust Gateway. O trust
-- score em si (marcos de e-mail confirmado, edições aprovadas etc.) fica
-- todo em 0 nesta entrega -- só "account_created_at" é preenchido; os demais
-- marcos exigem hooks de edição fora do escopo do MVP (ver plano).
CREATE TABLE IF NOT EXISTS accounts (
	id              BIGSERIAL PRIMARY KEY,
	username        TEXT NOT NULL UNIQUE,
	trust_score     SMALLINT NOT NULL DEFAULT 10,
	account_created_at   TIMESTAMPTZ NOT NULL DEFAULT now(),
	email_confirmed_at   TIMESTAMPTZ,
	created_at      TIMESTAMPTZ NOT NULL DEFAULT now()
);

-- Log auditável de toda decisão que o Trust Gateway tomou no cadastro
-- (allow/block, score, banda) -- não guarda os atributos brutos do
-- fingerprint (só o hash), conforme minimização de dados (LGPD).
CREATE TABLE IF NOT EXISTS risk_decisions (
	id                  BIGSERIAL PRIMARY KEY,
	username            TEXT NOT NULL,
	ip_address          INET,
	fingerprint_hash    TEXT,
	score               SMALLINT NOT NULL,
	band                TEXT NOT NULL,
	verdict             TEXT NOT NULL, -- 'allow' | 'block'
	created_at          TIMESTAMPTZ NOT NULL DEFAULT now()
);

CREATE INDEX IF NOT EXISTS idx_risk_decisions_created_at ON risk_decisions (created_at);
CREATE INDEX IF NOT EXISTS idx_risk_decisions_ip ON risk_decisions (ip_address);
