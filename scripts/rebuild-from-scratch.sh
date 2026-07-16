#!/usr/bin/env bash
# Derruba TUDO (banco de dados, imagens enviadas, LocalSettings.php) e reinstala
# a Religio Wiki do zero, já com o conteúdo/design do projeto aplicado.
#
# USE SÓ SE scripts/deploy-wiki-content.sh não resolveu e você prefere recomeçar
# a instalação do MediaWiki em vez de investigar o que já está torto no ar.
#
# DESTRUTIVO: apaga o banco de dados (todo artigo/edição feita direto no wiki)
# e as imagens enviadas. Se você já escreveu conteúdo real no wiki que quer
# manter, faça backup antes (docker compose exec db mysqldump ...) — este
# script não pergunta duas vezes.
#
# Uso: ./scripts/rebuild-from-scratch.sh

set -euo pipefail
cd "$(dirname "$0")/.."

echo "############################################################"
echo "# Isso vai apagar o banco de dados atual e as imagens enviadas."
echo "# Digite 'sim' para confirmar, qualquer outra coisa cancela."
echo "############################################################"
read -r CONFIRM
if [ "$CONFIRM" != "sim" ]; then
  echo "Cancelado."
  exit 1
fi

if [ ! -f .env ]; then
  echo "ERRO: .env não encontrado. Copie .env.example para .env e preencha as senhas primeiro." >&2
  exit 1
fi
source .env
: "${DB_PASSWORD:?defina DB_PASSWORD no .env}"

echo "== 1/6: derrubando containers e apagando volumes (db + imagens) =="
docker compose down -v

echo "== 2/6: buildando a imagem do zero =="
docker compose build --no-cache

echo "== 3/6: subindo o banco de dados =="
docker compose up -d db
echo "  aguardando o banco aceitar conexões..."
until docker compose exec -T db mariadb-admin ping -h 127.0.0.1 --silent 2>/dev/null; do
  sleep 2
done

echo "== 4/6: removendo LocalSettings.php antigo (se existir) =="
rm -f LocalSettings.php

echo "== 5/6: rodando o instalador do MediaWiki =="
echo "Digite a senha que o usuário 'Admin' vai usar para logar no wiki:"
read -rs ADMIN_PASS
echo
docker compose run --rm mediawiki php maintenance/install.php \
  --dbserver=db \
  --dbname=religiowiki \
  --dbuser=religiowiki \
  --dbpass="$DB_PASSWORD" \
  --server="http://localhost:8080" \
  --scriptpath="" \
  --lang=pt-br \
  --pass="$ADMIN_PASS" \
  "Religio Wiki" \
  Admin

echo "== 6/6: subindo o wiki e aplicando o conteúdo do projeto =="
docker compose up -d
sleep 5
./scripts/deploy-wiki-content.sh Admin

echo
echo "Pronto — instalação limpa concluída. Acesse http://SEU_IP_OU_DOMINIO:8080"
echo "e faça login como Admin com a senha que você acabou de digitar."
