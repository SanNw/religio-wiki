# Status do skin — leia isto primeiro

Documento de orientação rápida sobre o skin ReligioWiki, no mesmo espírito
do `docs/STATUS.md` da extensão ReligiowikiCustomizer: um mapa dos pontos
de risco, não uma garantia de que está tudo testado.

## Por que um skin, e não Common.css/Common.js em cima do Vector

A abordagem antiga (ainda em `git log` deste repositório) tentava
reconciliar a identidade visual do artefato de prévia com o skin Vector
clássico via `MediaWiki:Common.css`/`Common.js`. Nunca bateu 100% porque o
DOM do Vector legado (`#mw-panel`, `.portal`, `#p-personal`) é sutilmente
diferente do layout de grid 3 colunas do artefato (`rw-topbar`/`rw-layout`
com sidebar | conteúdo | TOC como colunas irmãs de verdade, não uma caixa
flutuante). O skin próprio gera o DOM certo desde o início.

## ⚠️ Nunca testado contra um MediaWiki real

Assim como a extensão ReligiowikiCustomizer, todo o código deste skin foi
escrito e validado só com `php -l` (sintaxe) e validação de JSON — não há
MediaWiki rodando no ambiente onde isso foi escrito. **Primeira coisa a
fazer ao continuar**: subir o wiki de verdade
(`docker compose build && docker compose up -d && ./scripts/deploy-wiki-content.sh`)
e olhar a tela/log de erro com atenção antes de mexer em mais nada.

## Primeira execução ao vivo — contrato de saída do MediaWiki 1.43

O primeiro deploy ao vivo derrubou TODAS as páginas com erro 500:
`Call to undefined method ReligioWikiTemplate::printTrail()`
(em `includes/ReligioWikiTemplate.php`, na última linha do `execute()`).

Causa: no MediaWiki 1.43, `Skin::outputPageFinal()` (método `final`) envolve
a saída do `execute()` deste template — ele mesmo prepende o topo
(`OutputPage::headElement()`, que já inclui `<!DOCTYPE><html><head>…<body …>`)
e anexa o rodapé (`OutputPage::tailElement()`, que emite
`getBottomScripts()` + `</body></html>`). Portanto o `execute()` deve gerar
**só o conteúdo do `<body>`**. Duas construções da API clássica não valem
mais aqui:

- `$this->printTrail()` — removido do `BaseTemplate`; chamar = método
  indefinido (o erro 500 acima). O rodapé agora vem do `tailElement()`.
- `$this->html( 'headelement' )` — `headelement` deixou de ser chave de
  dados do QuickTemplate; virava no-op + warning "Undefined array key". O
  head agora vem do `headElement()`, prependido pelo framework.

Fechar `</body></html>` no próprio template também está errado pelo mesmo
motivo (duplica as tags do `tailElement` e joga os scripts do rodapé pra
fora do `<html>`). Corrigido: `execute()` não abre head nem fecha o
documento — só imprime o miolo do body.

## Pontos específicos de risco

- **Registro do skin via `skin.json`** (`ValidSkinNames.religiowiki.args`
  com `class`/`template`/`responsive`) segue o padrão clássico usado por
  skins como MonoBook — mas o formato exato esperado pelo `SkinFactory` do
  MediaWiki 1.43 para um skin `SkinTemplate` (não `SkinMustache`) não foi
  conferido contra o código-fonte desta versão específica. Se
  `Special:Version` não listar "ReligioWiki" ou o site cair com erro de
  classe/skin não encontrado, é o primeiro lugar a olhar — comparar com
  `skins/MonoBook/skin.json` da própria instalação
  (`/var/www/html/skins/MonoBook/skin.json` dentro do container) é o jeito
  mais rápido de achar divergência de formato.
- **`BaseTemplate::getSidebar( [ 'search' => false ] )`** — a opção
  `'search'` pra excluir a caixa de busca do loop genérico (ela é
  renderizada à parte, no `rw-topbar`) é um comportamento que lembro da API
  clássica, mas não confirmei a assinatura exata nesta versão. Se a busca
  aparecer duas vezes (uma no topo, outra dentro da sidebar) ou sumir da
  sidebar sem motivo, é aqui.
- **`$this->data['content_navigation']`** (abas Página/Discussão/Editar/
  Vigiar/Mais) — a estrutura em `namespaces`/`views`/`actions` é o
  resultado histórico do `SkinTemplate::buildContentNavigationUrls()`;
  `ReligioWikiTemplate::execute()` usa `views` como abas soltas e `actions`
  dentro do dropdown "Mais". Se as abas não aparecerem, `var_dump(
  $this->data['content_navigation'] )` dentro do `execute()` é o primeiro
  passo de debug.
- **`Sanitizer::escapeIdForAttribute`** — usado pra montar o id de cada
  portlet da sidebar (`p-<nome>`); é um método estável do core, baixo
  risco, mas o namespace exato (`MediaWiki\Sanitizer\Sanitizer` vs
  `Sanitizer` global) pode ter mudado de posição em versões recentes — se
  der erro de classe não encontrada, checar `use` no topo do arquivo.
- **`SidebarBeforeOutput`** (hook do "Criar artigo") — nome e assinatura
  `( $sk, &$sidebar )` conferem com a documentação histórica do hook, mas
  não foram exercitados ao vivo. Se o item não aparecer na caixa de
  ferramentas pra uma conta do grupo `editor`, confirme primeiro que
  `getAuthority()->isAllowed('createpage')` está retornando `true` pra
  essa conta (`editor` tem `createpage = true` em
  `LocalSettings-snippet.php`).
- **`#toc` nativo** — `skin.js` (bloco "Aparência") tenta mover
  `document.getElementById('toc')` pra dentro da coluna `.rw-toc`. Versões
  recentes do MediaWiki reformularam a geração do índice (TOC); se o
  índice não aparecer na coluna certa (ficar solto dentro do artigo, ou
  não aparecer), inspecionar o HTML gerado pra achar o id/estrutura real
  usada por essa versão — é o ponto de maior incerteza de todo o skin.
- **Rebuild de imagem Docker** — `scripts/deploy-wiki-content.sh` agora
  roda `docker compose build "$SERVICE"` antes de `up -d`, especificamente
  porque o Dockerfile passou a copiar `skins/ReligioWiki` (mudança no
  Dockerfile não é pega por `up -d` sozinho). Se o skin não aparecer depois
  de um deploy, confirme que esse rebuild rodou de verdade (não falhou
  silenciosamente) antes de suspeitar de outra coisa.
- **Agrupamento da barra pessoal em dropdown** (`skin.js`, bloco "agrupa a
  barra pessoal") — usa `mw.config.get('wgUserName')` pra decidir se
  alguém está logado; deveria funcionar em qualquer versão razoavelmente
  recente, baixo risco.
- **`RwPageViews.php`** (Artigo em destaque / Imagem do dia automáticos) —
  usa `MediaWikiServices::getConnectionProvider()` (API de 1.42+) e
  `IDatabase::newSelectQueryBuilder()`; sintaticamente válido pro 1.43, mas
  não exercitado contra um banco de verdade. Depois do primeiro
  `update.php` (cria a tabela `rw_pageviews`), confira: (1)
  `Special:Version` não acusa erro de classe; (2) a home mostra ALGUM
  artigo em destaque mesmo no primeiro dia, sem view nenhuma registrada
  ainda (cai pro `getFallbackArticle()`); (3) depois de visitar um artigo
  e virar o dia (ou forçar `rwpv_date` no banco pra testar), o destaque
  muda pro mais visto. Se `{{#artigoemdestaque:}}`/`{{#imagemdodia:}}`
  aparecerem como texto cru na página em vez de processados, o
  `ParserFirstCallInit` não registrou — checar ordem de carregamento em
  `LocalSettings-snippet.php`.

## Mapa de arquivos

```
skin.json                             registro do skin
includes/SkinReligioWiki.php          classe do skin (extends SkinTemplate)
includes/ReligioWikiTemplate.php      marcação (extends BaseTemplate, execute())
resources/skin.css                    identidade visual retrô, portada do artefato
resources/skin.js                     comportamento portado de Common.js
i18n/                                 en.json (fonte), qqq.json (docs), pt-br.json
docs/SKIN_STATUS.md                   este arquivo
```
