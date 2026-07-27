# Zotero translation-server -- extrai metadados de citação de uma URL de
# verdade (usa os "tradutores" específicos por site do próprio Zotero). O
# Citoid (ver ../citoid/) chama este serviço internamente; nada aqui é
# exposto pra internet.
#
# NÃO usa a imagem pronta "zotero/translation-server" do Docker Hub: ela só
# tem build pra linux/arm64, e a VPS deste projeto é amd64 ("exec format
# error" ao tentar rodar) -- build a partir do código-fonte em vez disso,
# mesmo Dockerfile/entrypoint do próprio repositório oficial (só adiciona
# "git" na imagem final, que o entrypoint deles usa pra atualizar os
# tradutores toda vez que o container inicia).
FROM node:lts

RUN apt-get update \
	&& apt-get install -y --no-install-recommends git ca-certificates \
	&& rm -rf /var/lib/apt/lists/*

WORKDIR /app

RUN git clone --depth 1 https://github.com/zotero/translation-server.git /app

RUN npm install

# translation-server usa 4 submódulos git (modules/*) -- clonados direto em
# vez de "git submodule update" porque o repositório principal foi clonado
# com --depth 1 (raso, sem histórico de submódulo pra resolver).
RUN git clone --depth 1 https://github.com/zotero/translators.git /app/modules/translators/ \
	&& git clone --depth 1 https://github.com/zotero/utilities.git /app/modules/utilities/ \
	&& git clone --depth 1 https://github.com/zotero/translate.git /app/modules/translate/ \
	&& git clone --depth 1 https://github.com/zotero/zotero-schema.git /app/modules/zotero-schema/

EXPOSE 1969

ENTRYPOINT [ "./docker-entrypoint.sh" ]
