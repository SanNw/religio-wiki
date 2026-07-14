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
  carrega as extensões de edição/citação, configura leitura anônima + edição
  só por convite (ver "Quem pode editar" abaixo), o botão "Doar" na barra
  pessoal, o ImageMagick (thumbnails), e o mapeamento categoria → classe CSS
  que colore o `#firstHeading` por religião.
- **`pagina-principal.wikitext`** → conteúdo da página inicial (boas-vindas,
  contador de artigos, artigo em destaque, imagem do dia, "Sobre a Religio
  Wiki").
- **`pagina-doar.wikitext`** → conteúdo de `Religio Wiki:Doar`.
- **`sidebar.wikitext`** → conteúdo de `MediaWiki:Sidebar` (navegação +
  categorias na lateral).
- **`templates.wikitext`** → templates iniciais de artigo (infobox, ver
  também, citação necessária, desambiguação).

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

## Ferramentas de edição, criação e citação

O tarball/imagem padrão do MediaWiki vem "pelado" — sem as extensões que a
Wikipédia usa no dia a dia. O `Dockerfile` desta pasta builda uma imagem
própria (`mediawiki:1.41` + extensões oficiais na mesma branch `REL1_41`,
baixadas do espelho no GitHub) já com:

| Ferramenta | Extensão | Equivalente na Wikipédia |
|---|---|---|
| Notas de rodapé / referências | `Cite` | `<ref>...</ref>` e `<references />` |
| Lógica em templates | `ParserFunctions` | `{{#if:}}`, `{{#switch:}}` etc. |
| Editor de wikitexto com barra | `WikiEditor` | barra clássica (negrito, link, assinatura...) |
| Editor visual (WYSIWYG) | `VisualEditor` | editor visual da Wikipédia |
| Formulário de campos de template | `TemplateData` | usado pelo VisualEditor para templates |
| Templates de citação em Lua | `Scribunto` | base de `{{citar web}}`, `{{citar livro}}` (CS1) |
| Upload de imagens + legenda + galeria | `$wgEnableUploads` + `ImageMagick` (config/pacote nativo, sem extensão) | `[[Arquivo:...\|thumb\|legenda]]`, `<gallery>` |
| Acervo do Wikimedia Commons | `$wgUseInstantCommons` (config nativa) | inserir imagens do Commons sem reenviar |

Histórico de página, diffs, página de discussão, lista de páginas vigiadas,
desfazer edição, pré-visualizar antes de salvar, redirecionamento, tabela de
conteúdo automática, tabelas ordenáveis — isso tudo já é nativo do MediaWiki,
sem precisar instalar nada. Além disso, `templates.wikitext` traz 4
templates iniciais que a Wikipédia resolve via template em vez de recurso
nativo: **Infobox religião**, **Ver também**, **Citação necessária** e
**Desambiguação**.

Como não é possível baixar o Docker Hub nem clonar os repositórios das
extensões dentro deste sandbox (ver nota mais abaixo), o `Dockerfile` não foi
testado ao vivo — a lista de extensões e a config de `VisualEditor`/`Scribunto`
seguem a documentação oficial do mediawiki.org, mas confira
`Special:Version` depois do primeiro `docker compose up` pra confirmar que
tudo carregou.

## Quem pode editar (acesso por convite)

Configurado para funcionar como você pediu: **leitura é pública/anônima,
edição é só de quem você escolher** — não existe cadastro público aberto.

1. Como `Admin`, vá em **Special:CreateAccount** e crie uma conta para a
   pessoa (defina uma senha provisória para ela trocar no primeiro acesso).
2. Vá em **Special:UserRights**, digite o nome de usuário dela, marque o
   grupo **`editor`** e salve.
3. Pronto — só quem estiver no grupo `editor` (ou for `Admin`) consegue criar
   e editar páginas e enviar imagens. Leitores anônimos e contas fora desse
   grupo só leem.

Para tirar o acesso de alguém, é o mesmo caminho: Special:UserRights,
desmarcar `editor`.

## Página principal

Conteúdo em `pagina-principal.wikitext`. Estrutura: título "Boas-vindas à
Religio Wiki" + subtítulo "a enciclopédia autêntica sobre as religiões" com
a contagem de artigos ao lado (via `{{NUMBEROFARTICLES}}`, nativo); abaixo,
lado a lado, "Artigo em destaque" e "Imagem do dia" — cada um transcluído de
uma sub-página própria (`Página principal/Artigo em destaque` e
`Página principal/Imagem do dia`) pra dar pra trocar sem editar a principal
inteira; por fim "Sobre a Religio Wiki" com o texto que você definiu. A
imagem do dia usa o `thumb` nativo do MediaWiki, que já preserva a proporção
original — o CSS só faz o contêiner ficar grande/responsivo.

## Doação

Botão **"Doar"** injetado como o primeiro item da barra pessoal em toda
página (à esquerda de "Entrar"/"Criar conta" — como o cadastro público está
fechado, a maioria dos visitantes só vê "Entrar" mesmo, mas o "Doar" fica
igualmente à esquerda dele). Leva para `Religio Wiki:Doar`
(`pagina-doar.wikitext`), com o texto sobre o projeto ser independente e um
widget de valores/frequência/forma de pagamento (`common.js`, seção "Widget
da página de doação"): BRL, Único/Mensal/Anualmente, valores predefinidos
(R$ 15 a R$ 300) + campo "Outro", e Pix/Débito/Crédito/Boleto/PayPal/Google
Pay como opções de forma de pagamento.

**Importante**: isso é só a interface — seleção de valor/frequência/forma
funciona (visualmente), mas não processa pagamento de verdade. Cobrança real
exige integrar um meio de pagamento de verdade (conta Pix, um gateway como
Mercado Pago/PagSeguro/Stripe para cartão e boleto, conta PayPal Business
etc.) — isso depende de credenciais/contas financeiras que só você pode
abrir, não é algo que eu tenha como criar por você. O widget já deixa claro
esse limite pra quem visitar a página (nota no rodapé do widget).

## Diagrama de categorias

Botão **"Ver diagrama de categorias"** logo abaixo da barra lateral (depois
da lista de Categorias) em toda página, injetado pelo `common.js`. Abre um
pop-up com a árvore de classificação (os três grupos do diagrama que você
enviou), no estilo da Religio Wiki — fundo/texto conforme o tema ativo,
Cristianismo e Islã já com a cor definida, espaçamento uniforme entre os
itens (a versão original desenhada à mão tinha espaços bem desiguais entre
os grupos; aqui ficou uma grade regular). Sem extensão nova — é só CSS/JS
(`common.css` seção 8, `common.js` "Pop-up do diagrama de categorias").

## Passo a passo (primeira instalação)

```bash
cd "Religio Wiki"

# 1. Copie o arquivo de ambiente e defina senhas fortes
cp .env.example .env
# edite DB_PASSWORD e DB_ROOT_PASSWORD em .env

# 2. Crie o arquivo LocalSettings.php vazio (necessário para o bind mount)
touch LocalSettings.php

# 3. Builde a imagem (baixa o MediaWiki oficial + as extensões, ver
#    "Ferramentas de edição, criação e citação" acima) e suba o banco
docker compose build
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

# 5. Cole o conteúdo de mediawiki-config/LocalSettings-snippet.php no final
#    do LocalSettings.php gerado (extensões, permissões, cor por religião)

# 6. Suba o MediaWiki
docker compose up -d

# 7. Acesse http://localhost:8080 e faça login como "Admin"
```

Nas próximas vezes, basta `docker compose up -d` (os passos 2, 4 e 5 são só
da primeira instalação, pois geram/editam o `LocalSettings.php`).

## Estrutura

- `Dockerfile` — `mediawiki:1.41` oficial + extensões de edição/citação (ver
  seção acima).
- `docker-compose.yml` — serviços `db` (MariaDB) e `mediawiki` (builda a
  partir do `Dockerfile`).
- `.env` — senhas do banco (não versionado, veja `.env.example`).
- `LocalSettings.php` — configuração gerada pelo instalador + o conteúdo de
  `mediawiki-config/LocalSettings-snippet.php` (não versionado, contém
  chaves secretas; fica só na máquina onde a wiki roda).

## Nota sobre este ambiente

Este setup foi montado no sandbox do Claude Code, cuja política de rede
bloqueia o Docker Hub, os servidores do Wikimedia e o clone dos repositórios
de extensão do GitHub — por isso não foi possível buildar a imagem nem
validar a subida completa aqui dentro (nem o `docker-compose.yml`/`Dockerfile`
originais, nem as extensões, nem os passos de permissão). Tudo segue a
documentação oficial do mediawiki.org; rode os passos acima na sua máquina ou
servidor (sem esse bloqueio) para validar de ponta a ponta.

## Próximos passos sugeridos

- Definir a cor de cabeçalho das 13 religiões que ainda faltam (ver seção
  "Cores por religião" acima).
- Ajustar `$wgSitename`, logo e paleta em `LocalSettings.php`/skin para
  refletir a identidade visual do projeto quando for decidida.
- Depois do primeiro deploy real, importar/adaptar os templates de citação
  (`{{citar web}}`, `{{citar livro}}`) — o `Scribunto` já está habilitado
  para suportá-los, mas os templates em si não vêm prontos, precisam ser
  criados ou importados de outro wiki.
- Decidir a lista inicial de pessoas com acesso de `editor` (ver "Quem pode
  editar" acima).
- Escrever/enviar o primeiro "Artigo em destaque" e "Imagem do dia" de
  verdade (as sub-páginas em `pagina-principal.wikitext` têm só exemplo).
- Escolher e configurar um meio de pagamento real para a página de doação
  (ver aviso em "Doação" acima) — nenhuma cobrança funciona ainda.
