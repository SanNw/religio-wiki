# Religio Wiki

Wiki colaborativa dedicada a religiões, rodando em [MediaWiki](https://www.mediawiki.org)
— o mesmo software open-source (licença GPL) que roda a Wikipédia — via Docker.

O software (MediaWiki) é open-source. O conteúdo dos artigos, depois de
publicado, normalmente é licenciado como CC BY-SA (configurável).

## Pré-requisitos

- Docker e Docker Compose (`docker compose version`)

## Direção de design

Referência principal: a própria Wikipédia — **hipertexto em primeiro lugar**,
sem excessos, sem modernismo. Na prática, isso guia as próximas decisões de
identidade visual:

- Texto e links densos são o conteúdo principal; layout é pano de fundo, não
  protagonista.
- Sem cards, gradientes, sombras pesadas, animações decorativas ou UI "app
  moderno" — chrome mínimo (é o que o skin Vector do MediaWiki já entrega por
  padrão).
- Cor entra pontualmente (cabeçalho por religião, links, tema) — não como
  fundo de blocos ou elementos decorativos.
- Tipografia funcional antes de expressiva: a Noto Sans já escolhida serve
  bem esse propósito (neutra, legível, cobre as escritas necessárias) — não
  trocar por fontes de identidade/display quando a identidade visual for
  fechada, a menos que seja só para títulos.

## Identidade e configuração de conteúdo

Configuração já pronta em `mediawiki-config/` (aplicar depois do passo a
passo de instalação abaixo):

- **`categorias.wikitext`** — estrutura de categorias baseada na classificação
  de religiões enviada (I. Xamanismos Hiperbóreos, II. Mitologias Arianas,
  III. Monoteísmos Semíticos, com as religiões de cada grupo). Crie cada
  `Category:<nome>` listada no arquivo.
- **`common.css`** → colar em `Special:MediaWiki:Common.css`: fundo em tom de
  papel pólen (`#FBF3E1`) no tema claro, tema escuro, tema personalizado
  (leitor escolhe as cores), e fonte Noto Sans (+ variantes Arabic/Hebrew/
  Greek/Devanagari) para cobrir transliterações e outras escritas.
- **`common.js`** → colar em `Special:MediaWiki:Common.js`: seletor de tema
  (claro/escuro/personalizado) na barra do usuário, persistido por leitor via
  `localStorage` — funciona também no modo anônimo.
- **`LocalSettings-snippet.php`** → colar no final do `LocalSettings.php`:
  leitura anônima liberada + edição exige conta (login com usuário/senha já
  vem pronto de fábrica no MediaWiki), e o mapeamento categoria → classe CSS
  que colore o `#firstHeading` por religião.

### Cores por religião

Definidas: **Cristianismo = vermelho** (`#DC2626`), **Islã = verde**
(`#15803D`). As demais estão como pendência em `common.css` (bloco comentado
no final do arquivo) — baseado no diagrama, faltam: Taoismo, Confucionismo,
Xamanismo Siberiano, Xintoísmo, Religião dos Povos Nativos Americanos, Bön,
Hinduísmo, Budismo, Religião Greco-Romana, Religião Germano-Céltica Antiga,
Jainismo, Zoroastrismo, Judaísmo. Quando decidir, é só descomentar a linha
correspondente e preencher a cor.

### Pendências

- Identidade visual completa (logo, paleta fora das cores por religião já
  definidas) — ainda não decidida.
- Fonte da imagem parece seguir uma classificação específica (possivelmente
  de uma obra/autor de referência); a árvore de subcategorias mais fina
  (ex.: se Xamanismo Siberiano é subcategoria de Confucionismo, do grupo
  inteiro, ou de ambos) ficou ambígua num diagrama desenhado à mão — o
  `categorias.wikitext` documenta essa ambiguidade caso a caso; é só ajustar
  as categorias depois de o wiki estar no ar.
- Self-host da fonte Noto Sans em vez de carregar do Google Fonts, se
  preferir não depender de CDN externo (o `common.css` já indica onde trocar).

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
