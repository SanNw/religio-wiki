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
  também, citação necessária, desambiguação) + o esqueleto padrão de seções
  (Bibliografia, Referências, Ligações externas).
- **`pagina-idiomas.wikitext`** → conteúdo de `Religio Wiki:Idiomas`, a
  página de ajuda linkada em "+ Adicionar idioma" no seletor de idioma.
- **`subcategorias.wikitext`** → exemplos de como ligar mais de uma religião
  num artigo, ou criar subcategoria dentro de uma religião (nativo do
  MediaWiki, sem configuração extra).

Skills usadas nesta rodada, instaladas em `~/.claude/skills/`: `web-design-guidelines`
(revisão de UI/responsividade) e `react-best-practices` (não aplicável ao
stack deste projeto — Religio Wiki é MediaWiki/PHP/wikitext, sem React —
mas instalada como pedido).

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

## Quem pode editar (acesso por convite) + criação de conta

**Criar conta é livre e funcional** — tanto pela página nativa
(`Special:CreateAccount`) quanto pelo **pop-up de login/cadastro no centro
da tela** que agora abre ao clicar em "Entrar" em qualquer página (ver
"Login e cadastro" abaixo) — **editar continua fechado**, só de quem você
escolher. São duas coisas separadas no MediaWiki: ter conta te coloca no
grupo `user`, que não tem permissão de editar
(`$wgGroupPermissions['user']['edit'] = false`); só quem for promovido
manualmente ao grupo `editor` (ou for `Admin`) consegue criar/editar página
ou enviar imagem.

Por que reabri a criação de conta em vez de deixar 100% fechada (como
estava antes): sem conta, o leitor não consegue salvar preferências (tema,
watchlist) nem comentar em página de discussão — e nada disso dá acesso de
edição, então não enfraquece o controle que você pediu. Se quiser voltar a
fechar completamente (nem conta pode ser criada por conta própria), é uma
linha só: `$wgGroupPermissions['*']['createaccount'] = false;` em
`LocalSettings-snippet.php` — aí só um admin cria conta pra alguém via
Special:CreateAccount.

Passo a passo pra dar (ou tirar) acesso de edição:

1. A pessoa cria a própria conta em **Special:CreateAccount** (ou, se você
   preferir a versão fechada acima, você cria pra ela).
2. Como `Admin`, vá em **Special:UserRights**, digite o nome de usuário dela,
   marque o grupo **`editor`** e salve.
3. Pronto — só quem estiver no grupo `editor` (ou for `Admin`) consegue criar
   e editar páginas e enviar imagens. Contas comuns e leitores anônimos só
   leem.

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

Botão **"Ver diagrama de categorias"** logo abaixo do bloco "Categorias" da
barra lateral e **acima** do bloco nativo "Ferramentas" (não no fim da
lateral) — injetado pelo `common.js`, que agora procura especificamente o
portlet de categorias (`#p-categorias-religiao-heading`) e insere o botão
logo depois dele, antes de `#p-tb` (o "Ferramentas" nativo).

O pop-up mostra o SVG que você enviou (mesma estrutura/coordenadas/textos),
com as cores fixas do arquivo trocadas por classes que seguem os tokens da
Religio Wiki — então ele já respeita tema claro/escuro/personalizado
automaticamente, e Cristianismo/Islã saem coloridos com o vermelho/verde já
definidos. Fonte trocada de Georgia/Helvetica (do arquivo original) para a
Noto Sans do projeto. Sem extensão nova — é só CSS/JS (`common.css`,
comentário "Diagrama em SVG"; `common.js`, "Pop-up do diagrama de
categorias").

## Ferramentas de leitura do artigo

Quatro coisas novas em todo artigo, seguindo o padrão da Wikipédia:

- **Idiomas** (acima de "Neste artigo", em **estilo collapse**: começa
  fechado, um clique no cabeçalho abre/fecha): lista Português (original) +
  os idiomas configurados. Um detalhe importante: a Wikipédia de verdade
  liga **wikis inteiramente separados** por idioma (pt.wikipedia.org,
  en.wikipedia.org...); aqui é **um wiki só**, então "trocar de idioma" é
  navegar para uma sub-página do mesmo artigo (`Cristianismo/en`, por
  exemplo) — não existe conteúdo traduzido automaticamente, é preciso
  escrever cada versão. O seletor já configurado (inglês, espanhol, francês,
  italiano) mostra em itálico/esmaecido o idioma que ainda não tem
  sub-página escrita, com um link "+ Adicionar idioma" apontando para
  `Religio Wiki:Idiomas` (`pagina-idiomas.wikitext`), que explica como
  traduzir um artigo e como configurar um idioma novo na lista. Ver
  "Idiomas do artigo (convenção de sub-página)" em
  `LocalSettings-snippet.php`.
- **Aparência** (abaixo de "Neste artigo"): tamanho do texto
  (Pequeno/Padrão/Grande) e largura do conteúdo (Padrão/Largo), persistido
  por leitor via `localStorage` — como o menu de aparência da Wikipédia,
  mas separado do seletor de tema (claro/escuro/personalizado) que já
  existia. **Corrigido dois bugs** que você reportou: (1) tamanho do texto
  agora reescala o `<html>` inteiro (`font-size: 87.5%/112.5%`) em vez de só
  um trecho isolado — antes só o parágrafo mudava um pouco e os títulos
  ficavam do mesmo tamanho, dando a impressão de "não fazer nada"; (2)
  "Largo" agora só alarga a coluna de leitura (`#content`/`.mw-body`) — a
  versão anterior colapsava a grade inteira numa coluna só, o que esticava
  elementos pensados pra ficar estreitos, como o botão "Ver diagrama de
  categorias".
- **Lápis de edição** (✏, ao lado do título): só aparece pra quem realmente
  pode editar aquela página — o hook `OutputPageBodyAttributes` marca
  `body.rw-can-edit` no servidor checando a permissão de verdade
  (`Title::quickUserCan('edit', ...)`), o `common.js` só mostra o ícone
  quando essa classe está presente. Não é decorativo: o link já leva direto
  pro modo de edição.
- **Quem editou por último**: rodapé do artigo mostrando usuário + data da
  última edição (`$wgMaxCredits`, nativo). O histórico completo, com todas
  as edições e quem fez cada uma, já existia nativamente na aba
  "Ver histórico" — isso só adiciona o resumo rápido no rodapé, como a
  Wikipédia tem.

## Esqueleto padrão de artigo

Bibliografia, Referências e Ligações externas — nessa ordem, no fim de
todo artigo — documentado em `templates.wikitext` ("Esqueleto padrão de
artigo"). É convenção editorial, não algo que o software force sozinho;
`Referências` usa `{{references}}`/`<references />` (extensão `Cite`, já
habilitada) pra listar as notas de rodapé do corpo do texto.

## Responsivo / versão mobile

O skin legacy Vector (o que a instalação usa) não foi desenhado pra tela
pequena — essas regras (seção 14 do `common.css`) adaptam o que dá:

- Abaixo de 851px, a barra lateral fixa (`#mw-panel`) some e vira um menu
  hambúrguer (☰, canto superior esquerdo, `common.js` "Menu hambúrguer") —
  abre como painel deslizante por cima do conteúdo, com fundo escurecido
  atrás; fecha ao clicar fora, apertar Esc, ou clicar num link do menu.
- Na página principal, "Artigo em destaque" e "Imagem do dia" (lado a lado
  no desktop) empilham em coluna única abaixo de 720px — isso já existia
  desde a primeira versão da página principal.
- Abaixo de 600px: título do artigo com fonte menor, cabeçalho da página
  principal empilha em vez de ficar lado a lado com o contador de artigos,
  a grade de valores da doação vira 2 colunas em vez de 3, e o infobox para
  de flutuar ao lado do texto (ocupa a largura toda, no fluxo normal) —
  senão ele fica apertado demais numa tela de celular.

**Isso não é o mesmo que a Wikipédia tem de verdade no celular** — a
Wikipédia usa a extensão `MobileFrontend`, com um skin próprio (Minerva)
feito do zero pra mobile, algo bem mais completo do que adaptar o Vector
com CSS. O que fiz aqui deixa o Vector *utilizável* em tela pequena; se no
futuro quiser uma experiência mobile realmente nativa (like a Wikipédia
em m.wikipedia.org), aí vale a pena avaliar instalar o MobileFrontend — é
um projeto à parte, não incluído nesta rodada.

## Login e cadastro

Pop-up centralizado (`common.css` seção 15, `common.js` "Pop-up de login /
criar conta") que abre ao clicar em "Entrar" (ou "Criar conta", quando
visível) em qualquer página — no lugar de ir pra uma página cheia à parte.
Duas abas, Entrar/Criar conta, cada uma com:

- **Login/cadastro por usuário e senha, de verdade funcional**: usa as APIs
  nativas do MediaWiki feitas exatamente pra isso —
  `action=clientlogin` e `action=createaccount` (é a mesma API que os
  apps oficiais da Wikipédia usam pra logar sem sair da tela). Não é uma
  simulação: se as credenciais estiverem certas, cria a conta / loga de
  verdade, sem sair do pop-up.
- **Google / Facebook / GitHub**: os botões existem na interface, mas
  ficam **desabilitados até você configurar cada provedor** —
  `LocalSettings-snippet.php` já tem o framework (`PluggableAuth` +
  `OpenIDConnect`, baixados pelo `Dockerfile`) com um bloco comentado
  pronto pra Google e GitHub, faltando só suas credenciais OAuth
  (Client ID + Client Secret), que só você consegue gerar — são chaves
  ligadas à sua conta em cada plataforma:
  - Google: [console.cloud.google.com/apis/credentials](https://console.cloud.google.com/apis/credentials)
  - GitHub: [github.com/settings/developers](https://github.com/settings/developers) → "OAuth Apps"
  - Facebook: precisa de um conector diferente (Facebook não fala o
    protocolo padrão que Google/GitHub falam) — deixei só o botão
    desabilitado por enquanto, configurar isso é mais trabalho, considere
    deixar para depois.

  Depois de gerar as credenciais, é descomentar o bloco em
  `LocalSettings-snippet.php`, colar Client ID/Secret, e adicionar o
  provedor em `$wgRWSocialProviders` (ex.: `['google', 'github']`) — o
  pop-up habilita o botão correspondente sozinho.

Não testável ao vivo neste sandbox (mesma limitação de rede de sempre) —
o fluxo de `clientlogin`/`createaccount` segue a documentação oficial da
API do MediaWiki, mas confira no seu deploy real.

## Subcategorias e artigos que ligam mais de uma religião

Já é nativo, sem precisar de nada extra: qualquer página pode ter várias
`[[Category:...]]`, e uma categoria pode ser subcategoria de outra do mesmo
jeito — quem estiver no grupo `editor` (ou for Admin) já consegue fazer
isso hoje, editando a página. `subcategorias.wikitext` documenta com os
dois exemplos que você deu:

- **Ritos da Igreja Católica** → subcategoria `Catolicismo`, que por sua vez
  é subcategoria de `Cristianismo`.
- **Jesus Cristo** → categorizado em `Cristianismo` **e** `Islã` ao mesmo
  tempo (mais uma categoria temática cruzada, `Figuras bíblicas e
  coránicas`), já que as duas religiões o citam.

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
- Validar ao vivo (fora deste sandbox) o seletor de idioma, o menu
  hambúrguer e o pop-up de login/cadastro — todos dependem de APIs nativas
  do MediaWiki (`action=query`, `action=clientlogin`, `action=createaccount`)
  ou de elementos do DOM do skin (`#mw-panel`, `#pt-login`) respondendo do
  jeito esperado, não testável aqui.
- Decidir se quer voltar a fechar a criação de conta 100% (ver "Quem pode
  editar" acima) ou manter aberta como ficou agora.
- Gerar as credenciais OAuth do Google e/ou GitHub se quiser login social
  funcionando de verdade (ver "Login e cadastro" acima) — e decidir se vale
  a pena investir no conector do Facebook depois.
- Se quiser uma experiência mobile mais completa (tipo a Wikipédia no
  celular), avaliar a extensão MobileFrontend — o que foi feito agora deixa
  o Vector usável em tela pequena, não é a mesma coisa (ver "Responsivo /
  versão mobile" acima).
