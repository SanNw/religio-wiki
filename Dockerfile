# Religio Wiki — imagem mediawiki oficial + extensões de edição/citação
# equivalentes às usadas na Wikipédia (não vêm no tarball/imagem padrão).
FROM mediawiki:1.43

ARG MW_BRANCH=REL1_43

RUN apt-get update \
	&& apt-get install -y --no-install-recommends git lua5.1 imagemagick \
	&& rm -rf /var/lib/apt/lists/*

WORKDIR /var/www/html/extensions

RUN set -eux; \
	for ext in Cite ParserFunctions WikiEditor VisualEditor TemplateData Scribunto PluggableAuth OpenIDConnect; do \
		rm -rf "${ext}"; \
		git clone --depth 1 --branch "${MW_BRANCH}" \
			"https://github.com/wikimedia/mediawiki-extensions-${ext}.git" "${ext}"; \
		rm -rf "${ext}/.git"; \
	done

# ReligiowikiCustomizer — extensão própria do projeto (repositório separado,
# não é um mirror do Wikimedia como as de cima), painel admin de tema/
# homepage/componentes. Ver mediawiki-config/LocalSettings-snippet.php.
RUN set -eux; \
	rm -rf ReligiowikiCustomizer; \
	git clone --depth 1 https://github.com/SanNw/religiowiki-customizer.git ReligiowikiCustomizer; \
	rm -rf ReligiowikiCustomizer/.git

WORKDIR /var/www/html
