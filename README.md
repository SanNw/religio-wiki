# Religio Wiki

Wiki colaborativa dedicada a religiões, rodando em [MediaWiki](https://www.mediawiki.org)
— o mesmo software open-source (licença GPL) que roda a Wikipédia — via Docker.

O software (MediaWiki) é open-source. O conteúdo dos artigos, depois de
publicado, normalmente é licenciado como CC BY-SA (configurável).

## Pré-requisitos

- Docker e Docker Compose (`docker compose version`)

## Passo a passo (primeira instalação)

```bash
cd "Religio Wiki"

# 1. Copie o arquivo de ambiente e defina senhas fortes
cp .env.example .env
# edite DB_PASSWORD e DB_ROOT_PASSWORD em .env

# 2. Crie o arquivo LocalSettings.php vazio (necessário para o bind mount)
touch LocalSettings.php

# 3. Suba só o banco de dados primeiro
docker compose up -d db

# 4. Rode o instalador do MediaWiki via linha de comando
#    (troque SENHA_DO_ADMIN por uma senha forte; ela será a senha do usuário Admin)
source .env
docker compose run --rm mediawiki php maintenance/install.php \
  --dbserver=db \
  --dbname=religiowiki \
  --dbuser=religiowiki \
  --dbpass="$DB_PASSWORD" \
  --server="http://localhost:8080" \
  --scriptpath="" \
  --lang=pt-br \
  --pass="SENHA_DO_ADMIN" \
  "Religio Wiki" \
  Admin

# 5. Suba o MediaWiki
docker compose up -d

# 6. Acesse http://localhost:8080 e faça login como "Admin"
```

Nas próximas vezes, basta `docker compose up -d` (os passos 2 e 4 são só da
primeira instalação, pois geram o `LocalSettings.php`).

## Estrutura

- `docker-compose.yml` — serviços `db` (MariaDB) e `mediawiki` (imagem oficial).
- `.env` — senhas do banco (não versionado, veja `.env.example`).
- `LocalSettings.php` — configuração gerada pelo instalador (não versionado,
  contém chaves secretas; fica só na máquina onde a wiki roda).

## Nota sobre este ambiente

Este setup foi montado no sandbox do Claude Code, cuja política de rede
bloqueia o Docker Hub e os servidores do Wikimedia — por isso não foi
possível baixar as imagens e validar a subida completa aqui dentro. A
configuração segue o modelo oficial documentado pela imagem `mediawiki` do
Docker Hub; rode os passos acima na sua máquina ou servidor (onde o Docker
Hub não está bloqueado) para validar.

## Próximos passos sugeridos

- Definir extensões (ex.: `Cite` para referências, `ParserFunctions`) —
  já vêm junto na imagem oficial, é só habilitar em `LocalSettings.php`.
- Ajustar `$wgSitename`, logo e paleta em `LocalSettings.php`/skin para
  refletir a identidade do projeto.
- Definir categorias iniciais (ex.: por religião, período histórico, região).
