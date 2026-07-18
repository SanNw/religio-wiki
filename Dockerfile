# Religio Wiki — imagem mediawiki oficial + extensões de edição/citação
# equivalentes às usadas na Wikipédia (não vêm no tarball/imagem padrão).
FROM composer:2 AS composer

FROM mediawiki:1.43

ARG MW_BRANCH=REL1_43

RUN apt-get update \
	&& apt-get install -y --no-install-recommends git lua5.1 imagemagick unzip \
	&& rm -rf /var/lib/apt/lists/*

# Extensões PHP "gd" e "zip" — necessárias pelo phpoffice/phpspreadsheet
# (dependência do Data Transfer para ler/gerar planilhas). Não vêm
# habilitadas na imagem oficial mediawiki:1.43 (thumbnails de artigo usam
# ImageMagick, não gd; e não há necessidade de zip no core do MediaWiki).
RUN apt-get update \
	&& apt-get install -y --no-install-recommends libpng-dev libjpeg62-turbo-dev libwebp-dev libfreetype6-dev libzip-dev \
	&& docker-php-ext-configure gd --with-jpeg --with-webp --with-freetype \
	&& docker-php-ext-install -j"$(nproc)" gd zip \
	&& rm -rf /var/lib/apt/lists/*

COPY --from=composer /usr/bin/composer /usr/bin/composer

WORKDIR /var/www/html/extensions

RUN set -eux; \
	for ext in Cite ParserFunctions WikiEditor VisualEditor TemplateData TemplateWizard Scribunto PluggableAuth OpenIDConnect; do \
		rm -rf "${ext}"; \
		git clone --depth 1 --branch "${MW_BRANCH}" \
			"https://github.com/wikimedia/mediawiki-extensions-${ext}.git" "${ext}"; \
		rm -rf "${ext}/.git"; \
	done

# ReligiowikiCustomizer — extensão própria do projeto (repositório separado,
# não é um mirror do Wikimedia como as de cima), painel admin de tema/
# homepage/componentes. Ver mediawiki-config/LocalSettings-snippet.php.
#
# Cache-bust automático: ao contrário das extensões acima (presas a REL1_43),
# esta é clonada da branch `main` e muda com frequência. Sem isso, o Docker
# cacheia a layer do "git clone" pra sempre (o cache é pelo TEXTO da
# instrução, não pelo conteúdo do remoto), e um `docker compose build` normal
# NUNCA traz o código novo da extensão. O ADD da API de refs do GitHub baixa
# o SHA atual da main; quando a extensão recebe um commit novo, o conteúdo
# baixado muda e invalida o cache daqui pra baixo, forçando o re-clone.
ADD https://api.github.com/repos/SanNw/religiowiki-customizer/git/refs/heads/main /tmp/rwc-ref.json
RUN set -eux; \
	rm -rf ReligiowikiCustomizer; \
	git clone --depth 1 https://github.com/SanNw/religiowiki-customizer.git ReligiowikiCustomizer; \
	rm -rf ReligiowikiCustomizer/.git

# Extensões adicionais sem pacote Composer oficial (instalação via git,
# mesmo padrão acima) — ExternalData, HeaderTabs, TemplateStyles e
# CodeMirror não têm pacote no Packagist, então são baixadas direto do
# mirror oficial do Wikimedia na branch do MediaWiki instalado. TemplateStyles
# e ExternalData têm dependências PHP próprias (composer.json dentro da
# pasta da extensão) resolvidas via merge-plugin a partir de
# composer.local.json, então precisam já estar clonadas antes do
# "composer update" abaixo.
RUN set -eux; \
	for ext in ExternalData HeaderTabs TemplateStyles CodeMirror; do \
		rm -rf "${ext}"; \
		git clone --depth 1 --branch "${MW_BRANCH}" \
			"https://github.com/wikimedia/mediawiki-extensions-${ext}.git" "${ext}"; \
		rm -rf "${ext}/.git"; \
	done

WORKDIR /var/www/html

# Extensões instaladas via Composer (Semantic MediaWiki, Page Forms, Cargo,
# Data Transfer, SimpleBatchUpload, Maps, WikiSEO, EmbedVideo) — versões
# fixadas em composer.local.json (confirmadas compatíveis com MediaWiki
# 1.43 via extension.json de cada uma, não "*", para não puxar sozinho uma
# versão futura que exija um core mais novo). O composer.json raiz do
# MediaWiki já vem com o merge-plugin configurado para ler
# composer.local.json automaticamente.
COPY composer.local.json /var/www/html/composer.local.json
RUN set -eux; \
	composer update --no-dev --no-interaction --optimize-autoloader -d /var/www/html; \
	rm -rf /root/.cache/composer /root/.composer/cache

# Skin ReligioWiki — identidade visual retrô ("papel pólen") portada do
# artefato de prévia do projeto, mora NESTE repositório (skins/ReligioWiki),
# então é uma cópia do contexto de build, não um git clone. Substitui o
# Vector clássico + Common.css/Common.js como forma de reconciliar visual —
# ver skins/ReligioWiki/docs/SKIN_STATUS.md.
COPY skins/ReligioWiki /var/www/html/skins/ReligioWiki
