-- Importado de https://pt.wikipedia.org/wiki/M%C3%B3dulo%3ACita%C3%A7%C3%A3o/CS1/Configura%C3%A7%C3%A3o (Wikipédia em português, CC BY-SA 4.0).
local citation_config = {};
-- override <code>...</code> styling to remove color, border, and padding.  <code> css is specified here:
-- https://git.wikimedia.org/blob/mediawiki%2Fcore.git/69cd73811f7aadd093050dbf20ed70ef0b42a713/skins%2Fcommon%2FcommonElements.css#L199
local code_style="color:inherit; border:inherit; padding:inherit;";

--[[--------------------------< Categorização de nomes de espaços >------------------------------

List of namespaces that should not be included in citation error categories.  Same as setting notracking = true by default

Note: Namespace names should use underscores instead of spaces.

]]
local uncategorized_namespaces = { 'Usuário', 'Usuário(a)', 'Usuária', 'Discussão', 'Usuário(a)_Discussão', 'Usuário_Discussão', 'Wikipédia_Discussão', 'Ficheiro_Discussão', 'Predefinição_Discussão', 'Ajuda_Discussão', 'Categoria_Discussão', 'Portal_Discussão', 'Book_talk', 'Draft', 'Draft_talk', 'Education_Program_talk', 'Módulo_Discussão', 'MediaWiki_Discussão', 'Wikipédia', 'Wikiprojeto', 'Wikiprojeto_Discussão', 'Ensino', 'Ensino_Discussão'};

local uncategorized_subpages = {'/[Tt]estes', '/[Dd]oc'};    -- list of Lua patterns found in page names of pages we should not categorize

--[[--------------------------< M E N S A G E N S >--------------------------------------------------------------

Translation table

The following contains fixed text that may be output as part of a citation.
This is separated from the main body to aid in future translations of this
module.

]]

local messages = {
    ['agency'] = '$1 $2',
    ['archived-dead']  = 'Arquivado do $1 em $2',
    ['archived-not-dead'] = '$1 em $2',
    ['archived-missing'] = 'Arquivado do original$1 em $2',
    ['archived'] = 'Cópia arquivada',
    ['by'] = 'Por',
    ['cartography'] = 'Cartografado por $1',
    ['editor'] = 'ed.',
    ['editors'] = 'eds.',
    ['edition'] = '$1 ed.',
    ['episode'] = 'Episódio $1',
    ['et al'] = 'et al.',
    ['in'] = 'In:',
    ['col'] = 'col:',
    ['inactive']  = 'inativo',
    ['inset'] = 'Requadro: $1',
    ['interview'] = 'Entrevista com $1',
    ['lay summary'] = 'Resumo divulgativo',
    ['mismatch'] = '<code class="cs1-code">&#124;$1=</code> / <code class="cs1-code">&#124;$2=</code> mismatch',    -- $1 is year param name; $2 is date param name
    ['newsgroup'] = '[[Grupo de notícias]]:&nbsp;$1',
    ['notitle'] = 'Sem título',                                                    -- for |title=(()) and (in the future) |title=none
    ['original'] = 'original',
    ['published'] = ' (publicado em $1)',
    ['retrieved'] = 'Consultado em $1',
    ['origyear'] = ' [$1]',
    ['semlocal'] = '[S.l.]',
    ['semeditora'] = '[s.n.]',
    ['semlocaleeditora'] = '[S.l.: s.n.]',
    ['season'] = 'Temporada $1',
    ['section'] = '§ $1',
    ['sections'] = '§§ $1',
    ['series'] = 'Séries $1',
    ['translated'] = 'Traduzido por $1',
    ['type'] = ' ($1)',
    ['written'] = 'Escrito em $1',

    ['vol'] = '$1 Vol.&nbsp;$2', -- $1 is sepc; bold journal style volume is in presentation{}
    ['vol-no'] = '$1 Vol.&nbsp;$2 no.&nbsp;$3', -- sepc, volume, issue
    ['issue'] = '$1 No.&nbsp;$2', -- $1 is sepc

    ['j-vol'] = '$1 $2', -- sepc, volume; bold journal volume is in presentation{}
    ['j-issue'] = ' ($1)',

    ['nopp'] = '$1 $2', -- page(s) without prefix; $1 is sepc

    ['total-p'] = "$1 $2&nbsp;páginas", -- $1 is sepc
    ['p-prefix'] = "$1 p.&nbsp;$2", -- $1 is sepc
    ['pp-prefix'] = "$1 pp.&nbsp;$2", -- $1 is sepc
    ['j-page(s)'] = ': $1', -- same for page and pages

    ['sheet'] = '$1 Folha&nbsp;$2', -- $1 is sepc
    ['sheets'] = '$1 Folhas&nbsp;$2', -- $1 is sepc
    ['j-sheet'] = ': Folha&nbsp;$1',
    ['j-sheets'] = ': Folhas&nbsp;$1',

    ['subscription'] = '<span style="font-size:90%; color:#555">(pede subscrição (<span title="As fontes não têm como que estar disponíveis em linha. As fontes em linha nem sempre são de acesso livre. O sítio referenciado pode requerer uma subscrição de pagamento." style="border-bottom:1px dotted;cursor:help">ajuda</span>))</span>' ..
        '[[Categoria:!Páginas com links a conteúdo que pede subscrição]]',
    ['registration']='<span style="font-size:90%; color:#555">(pede registo (<span title="As fontes não têm como que estar disponíveis em linha. As fontes em linha nem sempre são de acesso livre. O sítio referenciado pode requerer uma subscrição de registo." style="border-bottom:1px dotted;cursor:help">ajuda</span>))</span>' ..
        '[[Categoria:!Páginas com fontes que requerem registo]]',

    ['language'] = '(em $1)',
    ['via'] = " &ndash; via $1",
    ['event'] = 'Em cena em',
    ['minutes'] = 'No minuto $1',

    ['parameter-separator'] = ', ',
    ['parameter-final-separator'] = ', e ',
    ['parameter-pair-separator'] = ' e ',

    -- Determines the location of the help page
    ['help page link'] = 'Ajuda:Erros nas referências',
    ['help page label'] = 'ajuda',

    -- Internal errors (should only occur if configuration is bad)
    ['undefined_error'] = 'Condição de erro não definida',
    ['unknown_manual_ID'] = 'Modo de ID manual não reconhecido',
    ['unknown_ID_mode'] = 'Modo de ID não reconhecido',
    ['unknown_argument_map'] = 'Mapa de argumento não foi definida para esta variável',
    ['bare_url_no_origin'] = 'Campo de url vazio mas indicador origem é nil ou vazio',
}

--[[--------------------------< P R E S E N T A T I O N >------------------------------------------------------

Fixed presentation markup.  Originally part of citation_config.messages it has been moved into its own, more semantically
correct place.

]]
local presentation =
    {
    -- Error output
    -- .error class is specified at https://git.wikimedia.org/blob/mediawiki%2Fcore.git/9553bd02a5595da05c184f7521721fb1b79b3935/skins%2Fcommon%2Fshared.css#L538
    -- .citation-comment class is specified at Help:CS1_errors#Controlling_error_message_display
    ['hidden-error'] = '<span style="display:none;font-size:100%" class="error citation-comment">$1</span>',
    ['visible-error'] = '<span style="font-size:100%" class="error citation-comment">$1</span>',

    ['accessdate'] = '<span class="reference-accessdate">$1$2</span>',            -- to allow editors to hide accessdate using personal css

    ['bdi'] = '<bdi$1>$2</bdi>',                                                -- bidirectional isolation used with |script-title= and the like

    ['cite'] = '<cite class="$1">$2</cite>';                                    -- |ref= not set so no id="..." attribute
    ['cite-id'] = '<cite id="$1" class="$2">$3</cite>';                            -- for use when |ref= is set

    ['format'] = ' <span style="font-size:85%;">($1)</span>',                    -- for |format=, |chapter-format=, etc

                                                                                -- various access levels, for |access=, |doi-access=, |arxiv=, ...
    ['free'] = '<span class="plainlinks">$1<span style="margin-left:0.1em">[[Imagem:Lock-green.svg|9px|link=|alt=Acessível livremente|Acessível livremente]]</span></span>',
    ['registration'] = '<span class="plainlinks">$1<span style="margin-left:0.1em">[[File:Lock-yellow.svg|9px|link=|alt=Registo grátis requerido|Registo grátis requerido]]</span></span>',
    ['limited'] = '<span class="plainlinks">$1<span style="margin-left:0.1em">[[Imagem:Lock-yellow.svg|9px|link=|alt=Acesso livre sujeito a período limitado experimental, a subscrição é normalmente requerida]]</span></span>',
    ['subscription'] = '<span class="plainlinks">$1<span style="margin-left:0.1em">[[Imagem:Lock-red.svg|9px|link=|alt=Subscrição paga é requerida|Subscrição paga é requerida]]</span></span>',

    ['italic-title'] = "''$1''",

    ['kern-left'] = '<span style="padding-left:0.2em;">$1</span>$2',            -- spacing to use when title contains leading single or double quote mark
    ['kern-right'] = '$1<span style="padding-right:0.2em;">$2</span>',            -- spacing to use when title contains trailing single or double quote mark

    ['nowrap1'] = '<span class="nowrap">$1</span>',                                -- for nowrapping an item: <span ...>yyyy-mm-dd</span>
    ['nowrap2'] = '<span class="nowrap">$1</span> $2',                            -- for nowrapping portions of an item: <span ...>dd mmmm</span> yyyy (note white space)

    ['ocins'] = '<span title="$1" class="Z3988"><span style="display:none;">&nbsp;</span></span>',        -- Note: Using display: none on the COinS span breaks some clients

    ['parameter'] = '<code style="'..code_style..'">&#124;$1=</code>',

    ['quoted-text'] = '<q>$1</q>', -- '«$1»',    -- for wrapping |quote= content
    ['quoted-title'] = '«$1»', --'"$1"',

    ['trans-italic-title'] = "&#91;''$1''&#93;",
    ['trans-quoted-title'] = "&#91;$1&#93;",
    ['vol-bold'] = '$1 <b>$2</b>',                                                -- sepc, volume; for bold journal cites; for other cites ['vol'] in messages{}
    }


--[[--------------------------< A L I A S E S >----------------------------------------------------------------

Aliases table for commonly passed parameters

]]

local aliases = {
    ['AccessDate'] = {'acesso', 'acessodata', 'acesso-data', 'accessodata', 'acessadoem', 'dataacesso', 'accessdate', 'access-date', 'dataacesso', 'fechaacceso', 'consulta', 'acessdate'},
    ['Agency'] = {'agencia', 'agency', 'agência'},
    ['AirDate'] = {'transmissão', 'airdate', 'air-date'},
    ['ArchiveDate'] = {'arquivodata', 'arquivo-data', 'archive-date', 'archivedate'},
    ['ArchiveFormat'] = {'formato-arquivo', 'arquivoformato', 'archive-format'},
    ['ArchiveURL'] = {'arquivourl', 'arquivo-url', 'urlarquivo', 'archive-url', 'archiveurl', 'urlarchivo'},
    ['ASINTLD'] = {'ASIN-TLD', 'asin-tld'},
    ['At'] = {'at', 'em', 'en'},
    ['Authors'] = {'autores', 'pessoas', 'authors','people', 'credits', 'créditos', 'argumentistas', 'persona', 'personas'},
    ['BookTitle'] = {'titulolivro', 'títulolivro', 'título-livro', 'booktitle', 'book-title'},
    ['Cartography'] = 'cartography',
    ['Callsign'] = {'indicativo', 'callsign', 'call-sign'}, --obsoleto
    ['Chapter'] = {'capitulo', 'capítulo', 'artigo', 'chapter', 'article', 'contribuição', 'contribuicao', 'contribution', 'entry'},
    ['ChapterFormat'] = {'formato-capitulo', 'chapter-format', 'contribution-format', 'section-format', 'article-format', 'entry-format'},
    ['ChapterURL'] = {'urlcapitulo', 'urlcapítulo', 'capítulourl', 'capítulo-url', 'url-capítulo', 'chapter-url', 'chapterurl', 'contribution-url', 'contributionurl', 'section-url', 'sectionurl', 'article-url', 'entry-url'},
    ['ChapterUrlAccess'] = {'chapter-url-access', 'contribution-url-access', 'entry-url-access', 'article-url-access', 'section-url-access'},    -- Used by InternetArchiveBot
    ['City'] = {'cidade', 'city'}, --obsoleto
    ['Class'] = {'classe', 'class'},
    ['Coauthors'] = {'coautor', 'coautores', 'coauthors', 'coauthor'},
    ['Collaboration'] = {'colaboração', 'collaboration'},
    ['Conference'] = {'conference', 'event', 'conferencia', 'conferência', 'evento'},
    ['ConferenceFormat'] = {'conference-format', 'event-format', 'formato-conferência'},
    ['ConferenceURL'] = {'conference-url', 'conferenceurl', 'event-url', 'eventurl', 'url-conferência', 'conferência-url'},
    ['Contribution'] = {'contribuição', 'contribuicao', 'contribution'}, -- introduction, foreword, afterword, etc; required when |contributor= set
    ['Date'] = {'data', 'date', 'airdate', 'dataemissão', 'fecha', 'data2'},
    ['DeadURL'] = {'datali', 'li', 'ligação inativa', 'ligação inactiva', 'urlmorta', 'dead-url', 'deadurl'},
    ['Degree'] = {'degree', 'grau'},
    ['DF'] = 'df',
    ['DisplayAuthors'] = {'numero-autores', 'display-authors', 'displayauthors'},
    ['DisplayEditors'] = {'numero-editores', 'displayeditors', 'display-editors'},
    ['Docket'] = {'expediente', 'docket'},
    ['DoiBroken'] = {'doi-incorrecto', 'doi-broken', 'doi-broken-date', 'doi-inactive-date', 'doi-inactivedate'},
    ['Edition'] = {'edicao', 'edition', 'edição', 'ed', 'Edição', 'edición'},
    ['Editors'] = {'editores', 'editors'},
    ['Embargo'] = 'embargo',
    ['Encyclopedia'] = {'enciclopedia', 'enciclopédia', 'encyclopedia', 'encyclopaedia'},        -- this one only used by citation
    ['Episode'] = {'episode', 'episódio'},                                                    -- cite serial only TODO: make available to cite episode?
    ['Format'] = {'formato', 'format'},
    ['ID'] = {'id', 'ID'},
    ['IgnoreISBN'] = {'ignore-isbn-error', 'ignore-isbn', 'ignoreisbnerror'},
    ['Inset'] = {'requadro','inset'},
    ['Issue'] = {'numero', 'número', 'issue', 'number'},
    ['Interviewers'] = {'interviewer', 'interviewers', 'entrevistador', 'entrevistadores'},
    ['Language'] = {'lingua', 'língua', 'idioma', 'language', 'in', 'língua2', 'lingua2', 'lingua3', 'língua3', 'lang', 'codling', 'ling', 'idioma2', 'idioma3', 'língua4', 'idioma4', 'lingua4'},
    ['LastAuthorAmp'] = {'ultimoamp',  'lastauthoramp', 'last-author-amp'},
    ['LayDate'] = {'resumo-data', 'data-resumo', 'lay-date', 'laydate'},
    ['LayFormat'] = {'resumo-formato', 'formato-resumo', 'lay-format'},
    ['LaySource'] = {'resumo-fonte', 'fonte-resumo', 'lay-source', 'laysource'},
    ['LayURL'] = {'url-resumo', 'resumo-url', 'resumo','lay-url', 'lay-summary', 'layurl', 'laysummary'},
                        -- Used by InternetArchiveBot
    ['MailingList'] = {'mailing-list', 'mailinglist'},                            -- cite mailing list only
    ['Map'] = {'map', 'mapa'},                                                            -- cite map only
    ['MapFormat'] = {'map-format', 'mapa-formato'},                                                -- cite map only
    ['MapURL'] = {'map-url', 'mapurl', 'mapa-url'},                                            -- cite map only -- Used by InternetArchiveBot
    ['MapUrlAccess'] = 'map-url-access',                                        -- cite map only -- Used by InternetArchiveBot
    ['MessageID'] = {'id-mensagem', 'mensagem-id', 'message-id'}, --obsoleto
    ['Minutes'] = {'minuto', 'minutos', 'minutes'},
    ['Mode'] = {'modo', 'mode'},
    ['Month'] = {'mes', 'mês', 'month', 'acessomesdia'},    -- obsoleto
    ['NameListFormat'] = {'formato-lista-nomes', 'formato-autor', 'formato-editor', 'name-list-format', 'name-list-style'},
    ['Network'] = {'rede', 'network'},
    ['NoPP'] = {'nopp', 'no-pp'},
    ['NoTracking'] = {'template-doc-demo', 'template doc demo', 'nocat', 'no-tracking', 'notracking'},
    ['OrigYear'] = {'anooriginal', 'orig-year', 'origyear'},
    ['Others'] = {'outros', 'entrevistador', 'entrevistadores', 'notas', 'interviewer', 'interviewers', 'otros', 'others'},
    ['Page'] = {'pagina', 'página', 'page', 'p'},
    ['Pages'] = {'paginas', 'pp', 'páginas', 'pages'},
    ['TotalPages'] = {'total-paginas', 'total-páginas'},
    ['Periodical'] = {'jornal', 'revista', 'dicionario', 'dicionário', 'publicacao', 'publicação', 'periodico', 'periódico', 'website', 'site', 'obra', 'encyclopedia', 'encyclopaedia', 'enciclopedia', 'enciclopédia', 'trabalho', 'work', 'journal', 'newspaper', 'magazine', 'periodical', 'dictionary', 'publicación', 'diccionario'},
    ['Place'] = {'local', 'location', 'lugar', 'place', 'localização'},
    ['PostScript'] = {'pontofinal', 'postscript'},
    ['Program'] = {'programa', 'program'},
    ['PublicationDate'] = {'data-publicação', 'data-publicacao', 'publication-date', 'publicationdate', 'fecha-publicación'},
    ['PublicationPlace'] = {'publication-place', 'publicationplace', 'local-publicação', 'local-publicacao', 'lugar-publicación', 'Local publicação'},
    ['PublisherName'] = {'publicado', 'produtora', 'editora', 'Editora', 'instituição', 'instituicao', 'universidade', 'publisher', 'grupo-noticias', 'distributor', 'institution', 'newsgroup', 'editorial', 'publicadopor', 'publicado por'},
    ['Quote'] = {'citacao', 'citação', 'cita', 'quote', 'quotation', 'citar'},
    ['Ref'] = 'ref',
    ['RegistrationRequired'] = {'registo', 'registro', 'registration', 'cadastro'},
    ['Scale'] = {'escala', 'scale'},
    ['ScriptChapter'] = {'capitulo-translit', 'script-chapter'},
    ['ScriptMap'] = 'script-map',
    ['ScriptPeriodical'] = {'script-journal', 'script-magazine', 'script-newspaper', 'script-periodical', 'script-website', 'script-work'},
   ['ScriptTitle'] = {'título-translit', 'titulo-translit', 'script-title'},
    ['Section'] = {'secao', 'seccao', 'section', 'seção'},
    ['Season'] = {'temporada', 'season'},
    ['Sections'] = {'seções', 'secoes', 'sections'},
    ['Series'] = {'series', 'serie', 'série', 'séries', 'coleção', 'Coleção', 'colecao', 'versão', 'version'},
    ['SeriesSeparator'] = {'separador-series', 'series-separator'},
    ['SeriesLink'] = {'serieslink', 'series-link', 'sérielink'},
    ['SeriesNumber'] = {'seriesnumber', 'numero-serie', 'series-no', 'seriesno', 'series-number'},
    ['Sheet'] = {'sheet', 'folha'},                                                        -- cite map only
    ['Sheets'] = {'sheets', 'folhas'},                                                        -- cite map only
    ['Station'] = {'estacao', 'estação', 'station'},
    ['SubscriptionRequired'] = {'subscription', 'subscrição', 'subscriçao', 'subscricao', 'suscripción', 'assinatura'},
    ['Time'] = {'tempo', 'time', 'tiempo'},
    ['TimeCaption'] = {'time-caption', 'timecaption','legenda'},
    ['Title'] = {'titulo', 'título', 'title', 'titlo', 'Título'},
    ['TitleLink'] = {'title-link', 'episode-link', 'titlelink', 'episodelink', 'episódiolink', 'titulolink', 'títulolink'},
    ['TitleNote'] = {'departamento', 'subtitulo', 'subtítulo', 'Subtítulo', 'department'},
    ['TitleType'] = {'type', 'medium', 'tipo', 'medio'},
    ['TransChapter'] = {'trad-capitulo', 'trans-chapter', 'trans_chapter', 'capítulo-trad'},
    ['TranscriptFormat'] = {'transcrição-formato', 'transcricao-formato', 'transcript-format'},
    ['Transcript'] = {'transcript', 'transcricao', 'transcrição'},
    ['TranscriptURL'] = {'transcript-url', 'transcripturl', 'urltranscricao', 'transcricaourl', 'transcriçãourl'},                    -- Used by InternetArchiveBot
    ['TransMap'] = 'trans-map',                                                    -- cite map only
    ['TransPeriodical'] = {'trans-journal', 'trans-magazine', 'trans-newspaper', 'trans-periodical', 'trans-website', 'trans-work'},

    ['TransTitle'] = {'títulotrad', 'titulotrad', 'trans-title', 'trans_title', 'títulotrad', 'título-trad'},
    ['URL'] = {'url', 'URL'},
    ['UrlAccess'] = {'url-access', 'acesso-url', 'acessourl'},                                                -- Used by InternetArchiveBot
    ['UrlStatus'] = 'url-status',                                                -- Used by InternetArchiveBot
    ['Vauthors'] = {'vautores', 'vauthors'},
    ['Veditors'] = {'veditores', 'veditors'},
    ['Via'] = 'via',
    ['Volume'] = {'volume', 'volumen'},
    ['Wayb'] = 'wayb',
    ['Year'] = {'ano', 'year', 'Ano', 'año'},

    ['AuthorList-First'] = {"nome#", "primeiro#", "prenome#", "first#", "given#", "author-first#", "author#-first", "nombre#"},
    ['AuthorList-Last'] = {"autor#", "cognome#", "ultimo#", "último#", "sobrenome#", "author#", "last#", "surname#", "author-last#", "author#-last", "subject#", "Autor#", "apelido#", "apellido#", "apellidos#","sujeito#", "entrevistado#", "host#"},
    ['AuthorList-Link'] = {"autorlink#", "autor-link#", "entrevistadolink#", "authorlink#", "author#-link", "author-link#", "subjectlink#", "author#link", "subject-link#", "subject#-link", "sujeitolink#"},
    ['AuthorList-Mask'] = {"autor-mascara#", "author-mask#", "authormask#", "author#mask", "author#-mask"},

    ['ContributorList-First'] = {'contribuidor#-primeiro', 'contribuidor-primeiro#','contributor-first#','contributor#-first'},
    ['ContributorList-Last'] = {'contribuidor#-ultimo', 'contribuidor-ultimo#', 'contributor-last#', 'contributor#-last'},
    ['ContributorList-Link'] = {'contribuidor-link#','contributor-link#', 'contributor#-link'},
    ['ContributorList-Mask'] = {'contribuidor-mascara#','contributor-mask#', 'contributor#-mask'},

    ['EditorList-First'] = {"editor-nome#", "editor#-first", "editor-first#", "editor-given#", "editor#-given", "editor-primeiro#"},
    ['EditorList-Last'] = {"editor-sobrenome#", "editor#", "editor#-last","editor-last#", "editor-surname#", "editor#-surname"},
    ['EditorList-Link'] = {"editor-link#", "editor#-link", "editorlink#", "editor#link"},
    ['EditorList-Mask'] = {"editor-mascara#", "editor-mask#", "editor#-mask", "editormask#", "editor#mask"},

    ['TranslatorList-First'] = {'tradutor-primeiro#', 'tradutor#-primeiro', 'translator-first#','translator#-first', 'translator-given#', 'translator#-given' },
    ['TranslatorList-Last'] = {'tradutor#', 'tradutor-ultimo#', 'tradutor#-ultimo', 'translator#', 'translator-last#', 'translator#-last'},
    ['TranslatorList-Link'] = {'tradutor-link#', 'tradutor#-link', 'translator-link#', 'translator#-link'},
    ['TranslatorList-Mask'] = {'tradutor-mascara#', 'tradutor#-mascara', 'translator-mask#', 'translator#-mask'},
}

--[[--------------------------< S P E C I A L   C A S E   T R A N S L A T I O N S >----------------------------

This table is primarily here to support internationalization.  Translations in this table are used, for example,
when an error message, category name, etc is extracted from the English alias key.  There may be other cases where
this translation table may be useful.

]]

local special_case_translation = {
    ['AuthorList'] = "lista de autores",                                            -- these for multiple names maint categories
    ['ContributorList'] = "lista de contribuidores",
    ['EditorList'] = "lista de editores",
    ['TranslatorList'] = "lista de tradutores",

    ['authors'] = "autores",                                                    -- used in get_display_authors_editors()
    ['editors'] = "editores",
    }

--[[--------------------------< D E F A U L T S >--------------------------------------------------------------

Default parameter values

TODO: keep this?  Only one default?
]]

local defaults = {
    DeadURL = 'não'
}

--[[--------------------------< K E Y W O R D S >--------------------------------------------------------------

This table holds keywords for those parameters that have defined sets of acceptible keywords.

]]

local keywords = {
    ['yes_true_y_sim_s'] = {'yes', 'true', 'y', 'sim', 's'},                                        -- ignore-isbn-error, last-author-amp, no-tracking, nopp, registration, subscription
--    ['deadurl'] = {'yes', 'true', 'y', 'no', 'unfit', 'usurped', 'sim', 's', 'não', 'n', 'unfit no archive', 'usurped no archive'},        -- hidden 2016-04-10; see Help_talk:Citation_Style_1#Recycled_urls

    ['mode'] = {'cs1', 'cs2', 'mla'},
    ['name-list-format'] = {'vanc'},
    ['contribution'] = {'posfácio', 'preâmbulo', 'introdução', 'prefácio'},    -- generic contribution titles that are rendered unquoted in the 'chapter' position
    ['date-format'] = {'dmy', 'dmy-all', 'mdy', 'mdy-all', 'ymd', 'ymd-all'},
    ['url-access'] = {'subscrição', 'limitada', 'limitado', 'registo', 'registro', 'registration', 'limited'},        -- access level of a URL (subscription required, limited access, free registration required), free to read by default
    ['id-access'] = {'free'},                                          -- access level of an identifier (free to read), subscription required (or no full text) by default
}


--[[--------------------------< S T R I P M A R K E R S >------------------------------------------------------

Common pattern definition location for stripmarkers so that we don't have to go hunting for them if (when)
MediaWiki changes their form.

]]

local stripmarkers = {
    ['any'] = '\127[^\127]*UNIQ%-%-(%a+)%-[%a%d]+%-QINU[^\127]*\127',            -- capture returns name of stripmarker
    ['math'] = '\127[^\127]*UNIQ%-%-math%-[%a%d]+%-QINU[^\127]*\127'            -- math stripmarkers used in coins_cleanup() and coins_replace_math_stripmarker()
    }


--[[--------------------------< I N V I S I B L E _ C H A R A C T E R S >--------------------------------------

This table holds non-printing or invisible characters indexed either by name or by Unicode group. Values are decimal
representations of UTF-8 codes.  The table is organized as a table of tables because the lua pairs keyword returns
table data in an arbitrary order.  Here, we want to process the table from top to bottom because the entries at
the top of the table are also found in the ranges specified by the entries at the bottom of the table.

This list contains patterns for templates like {{'}} which isn't an error but transcludes characters that are
invisible.  These kinds of patterns must be recognized by the functions that use this list.

Also here is a pattern that recognizes stripmarkers that begin and end with the delete characters.  The nowiki
stripmarker is not an error but some others are because the parameter values that include them become part of the
template's metadata before stripmarker replacement.

]]

local invisible_chars = {
    {'replacement', '\239\191\189'},                                            -- U+FFFD, EF BF BD
    {'zero width joiner', '\226\128\141'},                                        -- U+200D, E2 80 8D
    {'zero width space', '\226\128\139'},                                        -- U+200B, E2 80 8B
    {'hair space', '\226\128\138'},                                                -- U+200A, E2 80 8A
    {'soft hyphen', '\194\173'},                                                -- U+00AD, C2 AD
    {'horizontal tab', '\009'},                                                    -- U+0009 (HT), 09
    {'line feed', '\010'},                                                        -- U+000A (LF), 0A
    {'carriage return', '\013'},                                                -- U+000D (CR), 0D
    {'stripmarker', stripmarkers.any},                                            -- stripmarker; may or may not be an error; capture returns the stripmaker type
    {'delete', '\127'},                                                            -- U+007F (DEL), 7F; must be done after stripmarker test
    {'C0 control', '[\000-\008\011\012\014-\031]'},                                -- U+0000–U+001F (NULL–US), 00–1F (except HT, LF, CR (09, 0A, 0D))
    {'C1 control', '[\194\128-\194\159]'},                                        -- U+0080–U+009F (XXX–APC), C2 80 – C2 9F
--    {'Specials', '[\239\191\185-\239\191\191]'},                                -- U+FFF9-U+FFFF, EF BF B9 – EF BF BF
--    {'Private use area', '[\238\128\128-\239\163\191]'},                        -- U+E000–U+F8FF, EE 80 80 – EF A3 BF
--    {'Supplementary Private Use Area-A', '[\243\176\128\128-\243\191\191\189]'},    -- U+F0000–U+FFFFD, F3 B0 80 80 – F3 BF BF BD
--    {'Supplementary Private Use Area-B', '[\244\128\128\128-\244\143\191\189]'},    -- U+100000–U+10FFFD, F4 80 80 80 – F4 8F BF BD
}


--[[--------------------------< L A N G U A G E S >------------------------------------------------------------

This table is used to hold ISO 639-1 two-character language codes that apply only to |script-title= and |script-chapter=

]]

local script_lang_codes = {'am', 'ar', 'be', 'bg', 'bn', 'bs', 'dv', 'el',        -- ISO 639-1 codes only for |script-title= and |script-chapter=
    'fa', 'he', 'hy', 'ja', 'ka', 'kn', 'ko', 'ku',
    'mk', 'ml', 'mr', 'ps', 'ru', 'sd', 'sr', 'th',
    'uk', 'ug', 'ur', 'yi', 'zh'};


--[[--------------------------< M A I N T E N A N C E _ C A T E G O R I E S >----------------------------------

Here we name maintenance categories to be used in maintenance messages.

]]

local maint_cats = {
    ['ASIN'] = '!CS1 manut: ASIN usando ISBN',
    ['authors'] = '!CS1 manut: Usa parâmetro autores',
    ['bot:_unknown'] = '!CS1 manut: BOT: estado original-url desconhecido',
    ['date_format'] = '!CS1 manut: Formato data',
    ['date_year'] = '!CS1 manut: Data e ano',
    ['disp_auth_ed'] = '!CS1 manut: número-$1',                                    -- $1 is authors or editors
    ['editors'] = '!CS1 manut: Usa parâmetro editores',
    ['embargo'] = '!CS1 manut: Embargo PMC expirado',
    ['english'] = '!CS1 manut: Específicado língua inglês',
    ['etal'] = '!CS1 manut: Uso explícito de et al.',
    ['extra_text'] = '!CS1 manut: Texto extra',
    ['ignore_isbn_err'] = '!CS1 manut: Erros ISBN ignorados',
    ['missing_pipe'] = '!CS1 manut: Falta pipe',
    ['mult_names'] = '!CS1 manut: Nomes múltiplos: $1',                            -- $1 is <name>s list; gets value from special_case_translation table
    ['unfit'] = '!CS1 manut: Url estragada',
    ['unknown_lang'] = '!CS1 manut: Língua não reconhecida',
    ['untitled'] = '!CS1 manut: Periódico sem título',
    }

--[[--------------------------< P R O P E R T I E S _ C A T E G O R I E S >------------------------------------

Here we name properties categories

]]

local prop_cats = {
    ['foreign_lang_source'] = '!CS1 $1-fontes em língua ($2)',                    -- |language= categories; $1 is language name, $2 is ISO639-1 code
    ['foreign_lang_source_2'] = '!CS1 fontes em língua estrangeira (ISO 639-2)|$1',    -- |language= category; a cat for ISO639-2 languages; $1 is the ISO 639-2 code
    ['script'] = '!CS1 usa script em língua estrangeira',                            -- when language specified by |script-title=xx: não tem sua categoria
    ['script_with_name'] = '!CS1 usa script na língua $1 ($2)',                    -- |script-title=xx: has matching category; $1 is language name, $2 is ISO639-1 code
    }



--[[--------------------------< T I T L E _ T Y P E S >--------------------------------------------------------

Here we map a template's CitationClass to TitleType (default values for |type= parameter)

]]

local title_types = {
    ['AV-media-notes'] = 'Notas de mídia',
    ['interview'] = 'entrevista',                                                -- special case for cite interview  TODO: make cite interview not need special cases
    ['mailinglist'] = 'Lista de grupo de correio',
    ['map'] = 'Mapa',
    ['podcast'] = 'Podcast',
    ['pressrelease'] = 'Nota de imprensa',
    ['report'] = 'Relatório',
    ['techreport'] = 'Relatório técnico',
    ['thesis'] = 'Tese',
    }

--[[--------------------------< E R R O R _ C O N D I T I O N S >----------------------------------------------

Error condition table

The following contains a list of IDs for various error conditions defined in the code.  For each ID, we specify a
text message to display, an error category to include, and whether the error message should be wrapped as a hidden comment.

Anchor changes require identical changes to matching anchor in Help:CS1 errors

]]

local error_conditions = {
    accessdate_missing_url = {
        message = '<code style="'..code_style..'">&#124;acessodata=</code> requer <code style="'..code_style..'">&#124;url=</code>',
        anchor = 'accessdate_missing_url',
        category = '!Páginas com referências sem URL e com acessodata',
        hidden = true },
    archive_missing_date = {
        message = '<code style="'..code_style..'">&#124;arquivourl=</code> requer <code style="'..code_style..'">&#124;arquivodata=</code>',
        anchor = 'archive_missing_date',
        category = '!Páginas com erros CS1: urlarquivo',
        hidden = false },
    archive_missing_url = {
        message = '<code style="'..code_style..'">&#124;arquivourl=</code> requer <code style="'..code_style..'">&#124;url=</code>',
        anchor = 'archive_missing_url',
        category = '!Páginas com erros CS1: urlarquivo',
        hidden = false },
    archive_url = {
        message = '<code style="'..code_style..'">&#124;arquivourl=</code> é mal formado: $1',
        anchor = 'archive_url',
        category = '!Páginas com erros CS1: urlarquivo',
        hidden = false },
    arxiv_missing = {
        message = '<code style="'..code_style..'">&#124;arxiv=</code> requerido',
        anchor = 'arxiv_missing',
        category = '!Páginas com erros CS1: arXiv',
        hidden = false },
    arxiv_params_not_supported = {
        message = 'Parâmetros não válidos no arXiv',
        anchor = 'arxiv_params_not_supported',
        category = '!Páginas com erros CS1: arXiv',
        hidden = false },
    bad_arxiv = {
        message = 'Verifique <code style="'..code_style..'">&#124;arxiv=</code>',
        anchor = 'bad_arxiv',
        category = '!Páginas com erros CS1: arXiv',
        hidden = false },
    bad_asin = {
        message = 'Verifique <code style="'..code_style..'">&#124;asin=</code>',
        anchor = 'bad_asin',
        category ='!Páginas com erros CS1: ASIN',
        hidden = false },
    bad_bibcode = {
        message = 'Verifique <code style="'..code_style..'">&#124;bibcode=</code> $1',
        anchor = 'bad_bibcode',
        category ='!Páginas com erros CS1: bibcode',
        hidden = false },
    bad_biorxiv = {
        message = 'Verifique <code style="'..code_style..'">&#124;biorxiv=</code> value',
        anchor = 'bad_biorxiv',
        category ='!Páginas com erros CS1: biorxiv',
        hidden = false },
    bad_citeseerx = {
        message = 'Verifique <code style="'..code_style..'">&#124;citeseerx=</code> value',
        anchor = 'bad_citeseerx',
        category = 'CS1 errors: citeseerx',
        hidden = false },
    bad_date = {
        message = 'Verifique data em: <code style="'..code_style..'">$1</code>',
        anchor = 'bad_date',
        category = '!Páginas com erros CS1: datas',
        hidden = false },
    bad_doi = {
        message = 'Verifique  <code style="'..code_style..'">&#124;doi=</code>',
        anchor = 'bad_doi',
        category = '!Páginas com erros CS1: DOI',
        hidden = false },
    bad_hdl = {
        message = 'Verifique <code style="'..code_style..'">&#124;hdl=</code>',
        anchor = 'bad_hdl',
        category = 'CS1 errors: HDL',
        hidden = false },
    bad_isbn = {
        message = 'Verifique <code style="'..code_style..'">&#124;isbn=</code>',
        anchor = 'bad_isbn',
        category = '!Páginas com erros ISBN',
        hidden = false },
    bad_ismn = {
        message = 'Verifique <code style="'..code_style..'">&#124;ismn=</code>',
        anchor = 'bad_ismn',
        category = '!Páginas com erros CS1: ISMN',
        hidden = false },
    bad_issn = {
        message = 'Verifique <code style="'..code_style..'">&#124;issn=</code>',
        anchor = 'bad_issn',
        category = '!Páginas com erros ISSN',
        hidden = false },
    bad_lccn = {
        message = 'Verifique <code style="'..code_style..'">&#124;lccn=</code>',
        anchor = 'bad_lccn',
        category = '!Páginas com erros CS1: LCCN',
        hidden = false },
    bad_message_id = {
        message = 'Verifique <code style="'..code_style..'">&#124;mensagem-id=</code>',
        anchor = 'bad_message_id',
        category = '!Páginas com erros CS1: id-mensagem',
        hidden = false },
    bad_ol = {
        message = 'Verifique <code style="'..code_style..'">&#124;ol=</code>',
        anchor = 'bad_ol',
        category = '!Páginas com erros CS1: OL',
        hidden = false },
    bad_paramlink = {                                                            -- for |title-link=, |author/editor/translator-link=, |series-link=, |episode-link=
        message = 'Verifique <code style="'..code_style..'">&#124;$1=</code> valor',
        anchor = 'bad_paramlink',
        category = '!Páginas com erros link de parâmetro',
        hidden = false },
    bad_pmc = {
        message = 'Verifique <code style="'..code_style..'">&#124;pmc=</code>',
        anchor = 'bad_pmc',
        category = '!Páginas com erros CS1: PMC',
        hidden = false },
    bad_pmid = {
        message = 'Verifique <code style="'..code_style..'">&#124;pmid=</code>',
        anchor = 'bad_pmid',
        category = '!Páginas com erros CS1: PMID',
        hidden = false },
    bad_oclc = {
        message = 'Verifique <code style="'..code_style..'">&#124;oclc=</code> value',
        anchor = 'bad_oclc',
        category = '!Páginas com erros CS1: OCLC',
        hidden = false },
    bad_s2cid = {
        message = 'Check <code class="cs1-code">&#124;s2cid=</code> value',
        anchor = 'bad_s2cid',
        category = 'CS1 errors: S2CID',
        hidden = false
        },
    bad_sbn = {
        message = 'Check <code class="cs1-code">&#124;sbn=</code> value: $1',    -- $1 is error message detail
        anchor = 'bad_sbn',
        category = 'CS1 errors: SBN',
        hidden = false
        },
    bad_ssrn = {
        message = 'Check <code class="cs1-code">&#124;ssrn=</code> value',
        anchor = 'bad_ssrn',
        category = 'CS1 errors: SSRN',
        hidden = false
        },
    bad_url = {
        message = 'Verifique valor $1',
        anchor = 'bad_url',
        category = '!Páginas com erros URL',
        hidden = false },
    bare_url_missing_title = {
        message = '$1 missing title',
        anchor = 'bare_url_missing_title',
        category = '!Páginas com citações e URLs vazios',
        hidden = false },
    chapter_ignored = {
        message = '<code style="'..code_style..'">&#124;$1=</code> ignorado',
        anchor = 'chapter_ignored',
        category = '!Páginas com erros CS1: capítulo ignorado',
        hidden = false },
    citation_missing_title = {
        message = 'Em falta ou vazio <code style="'..code_style..'">&#124;$1=</code>',
        anchor = 'citation_missing_title',
        category = '!Páginas com citações sem título',
        hidden = false },
    cite_web_url = {                                                            -- this error applies to cite web and to cite podcast
        message = 'Em falta ou vazio <code style="'..code_style..'">&#124;url=</code>',
        anchor = 'cite_web_url',
        category = '!Páginas com citações web sem URL',
        hidden = true },
    coauthors_missing_author = {
        message = '<code style="'..code_style..'">&#124;coautores=</code> requer <code style="'..code_style..'">&#124;autor=</code>',
        anchor = 'coauthors_missing_author',
        category = '!Páginas com erros coautores sem autor',
        hidden = false },
    contributor_ignored = {
        message = '<code style="'..code_style..'">&#124;contributor=</code> ignorado</code>',
        anchor = 'contributor_ignored',
        category = '!Páginas com erros CS1: contribuidor',
        hidden = false },
    contributor_missing_required_param = {
        message = '<code style="'..code_style..'">&#124;contribuidor=</code> requer <code style="'..code_style..'">&#124;$1=</code>',
        anchor = 'contributor_missing_required_param',
        category = '!Páginas com erros CS1: contribuidor',
        hidden = false },
    deprecated_params = {
        message = 'A referência emprega parâmetros obsoletos <code style="'..code_style..'">&#124;$1=</code>',
        anchor = 'deprecated_params',
        category = '!Páginas que usam referências com parâmetros obsoletas',
        hidden = true },
    empty_citation = {
        message = 'Citação vazia',
        anchor = 'empty_citation',
        category = '!Páginas com citações vazias',
        hidden = false },
    first_missing_last = {
        message = '<code style="'..code_style..'">&#124;nome$2=</code> sem <code style="'..code_style..'">&#124;sobrenome$2=</code> em $1',
        anchor = 'first_missing_last',
        category = '!Páginas com erros CS1: falta autor ou editor',
        hidden = false },
    format_missing_url = {
        message = '<<code style="'..code_style..'">&#124;formato=</code> requer <code style="'..code_style..'">&#124;url=</code>',
        anchor = 'format_missing_url',
        category = '!Páginas usando citações com formato e sem URL',
        hidden = true },
    invalid_param_val = {
        message = 'Verifique o valor de <code style="'..code_style..'">&#124;$1=$2</code>',
        anchor = 'invalid_param_val',
        category = '!Páginas com erros CS1: valor inválido de parâmetro',
        hidden = false },
    invisible_char = {
        message = '$1 character in $2 at position $3',
        anchor = 'invisible_char',
        category = '!Páginas com erros CS1: caracteres invisíveis',
        hidden = false },
    missing_name = {
        message = 'Faltam os <code style="'..code_style..'">&#124;sobrenomes$2=</code> em $1',
        anchor = 'missing_name',
        category = '!Páginas com erros CS1: falta autor ou editor',
        hidden = false },
    param_access_requires_param = {
        message = '<code style="'..code_style..'">&#124;$1-access=</code> requer <code style="'..code_style..'">&#124;$1=</code>',
        anchor = 'param_access_requires_param',
        category = '!Páginas com erros CS1: parâmetro acesso',
        hidden = false },
    param_has_ext_link = {
        message = 'Ligação externa em <code style="'..code_style..'">$1</code>',
        anchor = 'param_has_ext_link',
        category = '!Páginas com erros ligações externas',
        hidden = false },
    parameter_ignored = {
        message = 'Parâmetro desconhecido <code style="'..code_style..'">&#124;$1=</code> ignorado',
        anchor = 'parameter_ignored',
        category = '!Páginas com citações usando parâmetros sem suporte',
        hidden = false },
    parameter_ignored_suggest = {
        message = 'Parâmetro desconhecido <code style="'..code_style..'">&#124;$1=</code> ignorado (<code style="'..code_style..'">&#124;$2=</code>) sugerido',
        anchor = 'parameter_ignored_suggest',
        category = '!Páginas com referências com parâmetros sugeridos',
        hidden = false },
    redundant_parameters = {
        message = '$1 redundantes',
        anchor = 'redundant_parameters',
        category = '!Páginas com citações e parâmetros redundantes',
        hidden = false },
    text_ignored = {
        message = 'Texto "$1" ignorado',
        anchor = 'text_ignored',
        category = '!Páginas com referências com parâmetros indefinidos',
        hidden = false },
    trans_missing_title = {
        message = '<code style="'..code_style..'">&#124;$1-trad=</code> requer <code style="'..code_style..'">&#124;$1=</code>',
        anchor = 'trans_missing_title',
        category = '!Páginas com erros CS1: título traduzido',
        hidden = false },
    vancouver = {
        message = 'Erro no estilo Vancouver: $1',
        anchor = 'vancouver',
        category = '!Páginas com erros CS1: estilo Vancouver',
        hidden = false },
    wayb_missing_url = {
        message = '<code style="'..code_style..'">&#124;wayb=</code> requer <code style="'..code_style..'">&#124;url=</code>',
        anchor = 'wayb_missing_url',
        category = '!Páginas com erros CS1: urlarquivo',
        hidden = false },
    wikilink_in_url = {
        message = 'Ligação wiki dentro do título da URL',
        anchor = 'wikilink_in_url',
        category = '!Páginas com erros CS1: conflito URL–wikilink',         -- uses ndash
        hidden = false }
}
--[[--------------------------< I D _ L I M I T S >------------------------------------------------------------

certain identifiers have limits set upon their values so that typographic errors may be detected.  These (max)
limits are defined here so that those limits may be automatically included in the template documentation and error
message help text.

]]

local id_limits = {
    pmc = 7500000,                                                                -- |pmc=
    pmid = 33000000,                                                            -- |pmid=
    ssrn = 4000000,                                                                -- |ssrn=
    s2cid = 230000000,                                                            -- |s2cid=
    }


--[[--------------------------< I D _ H A N D L E R S >--------------------------------------------------------

The following contains a list of values for various defined identifiers.  For each identifier we specify a
variety of information necessary to properly render the identifier in the citation.

    parameters: a list of parameter aliases for this identifier
    link: Wikipedia article name
    label: the alternate name to apply to link
    mode:     'manual' when there is a specific function in the code to handle the identifier;
            'external' for identifiers that link outside of Wikipedia;
    prefix: the first part of a url that will be concatenated with a second part which usually contains the identifier
    encode: true if uri should be percent encoded; otherwise false
    COinS: identifier link or keyword for use in COinS:
        for identifiers registered at info-uri.info use: info:....
        for identifiers that have COinS keywords, use the keyword: rft.isbn, rft.issn, rft.eissn
        for others make a url using the value in prefix, use the keyword: pre (not checked; any text other than 'info' or 'rft' works here)
        set to nil to leave the identifier out of the COinS
    separator: character or text between label and the identifier in the rendered citation
    access: use this parameter to set the access level for all instances of this identifier.
            the value must be a valid access level for an identifier (see ['id-access'] in this file).
    custom_access: to enable custom access level for an identifier, set this parameter
            to the parameter that should control it (normally 'id-access')
]]

local id_handlers = {
    ['ARXIV'] = {
        parameters = {'arxiv', 'ARXIV', 'eprint'},
        link = 'arXiv',
        label = 'arXiv',
        mode = 'manual',
        prefix = '//arxiv.org/abs/',                                             -- protocol relative tested 2013-09-04
        encode = false,
        COinS = 'info:arxiv',
        separator = ':',
        access = 'free',                                                        -- free to read
    },
    ['ASIN'] = {
        parameters = { 'asin', 'ASIN' },
        link = 'Amazon Standard Identification Number',
        label = 'ASIN',
        mode = 'manual',
        prefix = '//www.amazon.',
        COinS = nil,                                                            -- no COinS for this id (needs thinking on implementation because |asin-tld=)
        separator = '&nbsp;',
        encode = false;
    },
    ['BIBCODE'] = {
        parameters = {'bibcode','BIBCODE'},
        link = 'Bibcode',
        label = 'Bibcode',
--        mode = 'external',
        mode = 'manual',
        prefix = 'http://ui.adsabs.harvard.edu/abs/',
        encode = false,
        COinS = 'info:bibcode',
        separator = ':',
        custom_access = 'bibcode-access',
    },
    ['BIORXIV'] = {
        parameters = {'biorxiv'},
        link = 'bioRxiv',
        label = 'bioRxiv',
        mode = 'manual',
        prefix = '//dx.doi.org/10.1101/',
        COinS = 'pre',                                                            -- use prefix value
        access = 'free',                                                        -- free to read
        encode = true,
        separator = '&nbsp;',
    },
    ['CITESEERX'] = {
        parameters = {'citeseerx'},
        link = 'CiteSeerX',
        label = 'CiteSeerX',
        mode = 'manual',                                                        -- manual for custom validation of the "doi"
        prefix = '//citeseerx.ist.psu.edu/viewdoc/summary?doi=',
        COinS =  'pre',                                                            -- use prefix value
        access = 'free',                                                        -- free to read
        encode = true,
        separator = '&nbsp;',
    },
    ['DOI'] = {
        parameters = { 'doi', 'DOI', 'rotulodoi', 'nomedoi', 'rótulodoi'},
        link = 'Digital object identifier',
        label = 'doi',
        mode = 'manual',
        prefix = '//dx.doi.org/',
        COinS = 'info:doi',
        separator = ':',
        encode = true,
        custom_access = 'doi-access',
    },
    ['EISSN'] = {
        parameters = {'eissn', 'EISSN'},
        link = 'International_Standard_Serial_Number#Electronic_ISSN',
        label = 'eISSN',
        mode = 'manual',
        prefix = '//www.worldcat.org/issn/',
        COinS = 'rft.eissn',
        encode = false,
        separator = '&nbsp;',
    },
    ['HDL'] = {
        parameters = { 'hdl', 'HDL' },
        link = 'Handle System',
        label = 'hdl',
        mode = 'manual',
        prefix = '//hdl.handle.net/',
        COinS = 'info:hdl',
        separator = ':',
        encode = true,
        custom_access = 'hdl-access',
    },
    ['ISBN'] = {
        parameters = {'isbn', 'ISBN', 'isbn13', 'ISBN13', 'isbn2', 'isbn3'},
        link = 'International Standard Book Number',
        label = 'ISBN',
        mode = 'manual',
        prefix = 'Special:BookSources/',
        COinS = 'rft.isbn',
        separator = '&nbsp;',
    },
    ['ISMN'] = {
        parameters = {'ismn', 'ISMN'},
        link = 'International Standard Music Number',
        label = 'ISMN',
        mode = 'manual',
        prefix = '',                                                            -- not currently used;
        COinS = 'nil',                                                            -- nil because we can't use pre or rft or info:
        separator = '&nbsp;',
    },
    ['ISSN'] = {
        parameters = {'issn', 'ISSN'},
        link = 'International Standard Serial Number',
        label = 'ISSN',
        mode = 'manual',
        prefix = '//www.worldcat.org/issn/',
        COinS = 'rft.issn',
        encode = false,
        separator = '&nbsp;',
    },
    ['JFM'] = {
        parameters = {'jfm', 'JFM'},
        link = 'Jahrbuch über die Fortschritte der Mathematik',
        label = 'JFM',
        mode = 'external',
        prefix = '//zbmath.org/?format=complete&q=an:',
        COinS = 'pre',                                                            -- use prefix value
        encode = true,
        separator = '&nbsp;',
    },
    ['JSTOR'] = {
        parameters = {'jstor', 'JSTOR'},
        link = 'JSTOR',
        label = 'JSTOR',
        mode = 'external',
        prefix = '//www.jstor.org/stable/',                                     -- protocol relative tested 2013-09-04
        COinS = 'pre',                                                            -- use prefix value
        encode = false,
        separator = '&nbsp;',
        custom_access = 'jstor-access',
    },
    ['LCCN'] = {
        parameters = {'LCCN', 'lccn'},
        link = 'Library of Congress Control Number',
        label = 'LCCN',
        mode = 'manual',
        prefix = '//lccn.loc.gov/',                                             -- protocol relative tested 2015-12-28
        COinS = 'info:lccn',                                                    -- use prefix value
        encode = false,
        separator = '&nbsp;',
    },
    ['MR'] = {
        parameters = {'MR', 'mr'},
        link = 'Mathematical Reviews',
        label = 'MR',
        mode = 'external',
        prefix = '//www.ams.org/mathscinet-getitem?mr=',                         -- protocol relative tested 2013-09-04
        COinS = 'pre',                                                            -- use prefix value
        encode = true,
        separator = '&nbsp;',
    },
    ['OCLC'] = {
        parameters = {'OCLC', 'oclc'},
        link = 'OCLC',
        label = 'OCLC',
        mode = 'manual',
        prefix = '//www.worldcat.org/oclc/',
        COinS = 'info:oclcnum',
        encode = true,
        separator = '&nbsp;',
    },
    ['OL'] = {
        parameters = { 'ol', 'OL' },
        link = 'Open Library',
        label = 'OL',
        mode = 'manual',
        prefix = '//openlibrary.org/',
        COinS = nil,                                                            -- no COinS for this id (needs thinking on implementation because /authors/books/works/OL)
        separator = '&nbsp;',
        encode = true,
        custom_access = 'ol-access',
    },
    ['OSTI'] = {
        parameters = {'OSTI', 'osti'},
        link = 'Office of Scientific and Technical Information',
        label = 'OSTI',
        mode = 'external',
        prefix = '//www.osti.gov/energycitations/product.biblio.jsp?osti_id=',    -- protocol relative tested 2013-09-04
        COinS = 'pre',                                                            -- use prefix value
        encode = true,
        separator = '&nbsp;',
        custom_access = 'osti-access',
    },
    ['PMC'] = {
        parameters = {'PMC', 'pmc'},
        link = 'PubMed Central',
        label = 'PMC',
        mode = 'manual',
        prefix = '//www.ncbi.nlm.nih.gov/pmc/articles/PMC',
        suffix = " ",
        COinS = 'pre',                                                            -- use prefix value
        encode = true,
        separator = '&nbsp;',
        access = 'free',                                                        -- free to read
    },
    ['PMID'] = {
        parameters = {'PMID', 'pmid'},
        link = 'PubMed Identifier',
        label = 'PMID',
        mode = 'manual',
        prefix = '//www.ncbi.nlm.nih.gov/pubmed/',
        COinS = 'info:pmid',
        encode = false,
        separator = '&nbsp;',
    },
    ['RFC'] = {
        parameters = {'RFC', 'rfc'},
        link = 'Request for Comments',
        label = 'RFC',
        mode = 'external',
        prefix = '//tools.ietf.org/html/rfc',
        COinS = 'pre',                                                            -- use prefix value
        encode = false,
        separator = '&nbsp;',
        access = 'free',                                                        -- free to read
    },
    ['SSRN'] = {
        parameters = {'SSRN', 'ssrn'},
        link = 'Social Science Research Network',
        label = 'SSRN',
        mode = 'external',
        prefix = '//ssrn.com/abstract=',                                         -- protocol relative tested 2013-09-04
        COinS = 'pre',                                                            -- use prefix value
        encode = true,
        separator = '&nbsp;',
        access = 'free',                                                        -- always free to read
    },
    ['USENETID'] = {
        parameters = {'message-id', 'id-mensagem', 'mensagem-id'},
        link = 'Usenet',
        label = 'Usenet:',
        mode = 'manual',
        prefix = 'news:',
        encode = false,
        COinS = 'pre',                                                            -- use prefix value
        separator = '&nbsp;',
    },
    ['ZBL'] = {
        parameters = {'ZBL', 'zbl'},
        link = 'Zentralblatt MATH',
        label = 'Zbl',
        mode = 'external',
        prefix = '//zbmath.org/?format=complete&q=an:',
        COinS = 'pre',                                                            -- use prefix value
        encode = true,
        separator = '&nbsp;',
    },
}

return {
    aliases = aliases,
    special_case_translation = special_case_translation,
    defaults = defaults,
    error_conditions = error_conditions,
    id_handlers = id_handlers,
    id_limits = id_limits,
    keywords = keywords,
    stripmarkers=stripmarkers,
    invisible_chars = invisible_chars,
    maint_cats = maint_cats,
    messages = messages,
    presentation = presentation,
    prop_cats = prop_cats,
    script_lang_codes = script_lang_codes,
    title_types = title_types,
    uncategorized_namespaces = uncategorized_namespaces,
    uncategorized_subpages = uncategorized_subpages
}