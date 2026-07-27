# Citoid -- serviço Node.js que o VisualEditor usa pra gerar citação (Cite)
# automaticamente a partir de uma URL/DOI/ISBN. Não é uma extensão do
# MediaWiki (essas ficam no Dockerfile principal) -- é um SERVIÇO à parte,
# chamado via HTTP pelo LocalSettings.php ($wgCitoidServiceUrl), rodando no
# próprio container do wiki depende do serviço "zotero" (translation-server,
# ver docker-compose.yml) pra extrair metadados de URLs de verdade.
#
# Sem Dockerfile/imagem oficial publicada -- clona o código-fonte (mirror
# GitHub do Gerrit da Wikimedia) e roda com Node direto, mesmo padrão dos
# outros serviços da Wikimedia sem container pronto.
#
# Fixado na tag v1.3.0 (não "master"): a partir da v2.0.0 o serviço REMOVEU
# o endpoint por query string ("/api?format=X&search=Y") e passou a exigir
# path params ("/formato/busca") -- mas a extensão Citoid do MediaWiki
# REL1_43 (ver Dockerfile principal) ainda manda a busca por query string
# (mw.Api().get({search,format}) contra a URL configurada em
# $wgCitoidServiceUrl, ver modules/ve/ve.ui.CitoidInspector.js na
# extensão). v1.3.0 é a última tag antes dessa mudança de contrato --
# testado ao vivo, "master" retornava
# {"error":"Api endpoint unavailable as of 2.0.0..."} pra toda consulta.
FROM node:20-slim

WORKDIR /srv/citoid

RUN apt-get update \
	&& apt-get install -y --no-install-recommends git ca-certificates \
	&& rm -rf /var/lib/apt/lists/*

RUN git clone --depth 1 --branch v1.3.0 https://github.com/wikimedia/mediawiki-services-citoid.git . \
	&& rm -rf .git

RUN npm install --omit=dev

# Config própria pro docker-compose deste projeto (aponta pro serviço
# "zotero" pelo nome, em vez de localhost -- ver comentários no arquivo).
COPY config.docker.yaml ./config.yaml

EXPOSE 1970

CMD [ "node", "server.js" ]
