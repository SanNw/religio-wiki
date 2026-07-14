# Religio Wiki — imagem mediawiki oficial + extensões de edição/citação
# equivalentes às usadas na Wikipédia (não vêm no tarball/imagem padrão).
FROM mediawiki:1.41

ARG MW_BRANCH=REL1_41

RUN apt-get update \
	&& apt-get install -y --no-install-recommends git lua5.1 imagemagick \
	&& rm -rf /var/lib/apt/lists/*

WORKDIR /var/www/html/extensions

RUN set -eux; \
	for ext in Cite ParserFunctions WikiEditor VisualEditor TemplateData Scribunto; do \
		git clone --depth 1 --branch "${MW_BRANCH}" \
			"https://github.com/wikimedia/mediawiki-extensions-${ext}.git" "${ext}"; \
		rm -rf "${ext}/.git"; \
	done

WORKDIR /var/www/html
