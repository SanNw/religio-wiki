-- Importado de https://pt.wikipedia.org/wiki/M%C3%B3dulo%3ACitar_web (Wikipédia em português, CC BY-SA 4.0).
local w = require('Módulo:Citação/CS1')

--[[--------------------------< w . w e b >--------------------------------------

Este é o método principal da predefinição {{citar web}}.

]]

w.web= function(frame)
    local config, args, A = tratarArgumentos(frame)
    config.CitationClass = ''
    config.ChapterNaoSuportado = true
    local classe = 'web'

    if not is_set(A.URL) then
        table.insert(z.message_tail, { set_error('cite_web_url', {}, true)})
    end

    local chap_param
    -- pega o nome do parâmetro de um destes peta-parâmetros relacionados a "chapter"
    if is_set (A.Chapter) then
        chap_param = A:ORIGIN ('Chapter')
    elseif is_set (A.TransChapter) then
        chap_param = A:ORIGIN ('TransChapter')
    elseif is_set (A.ChapterURL) then
        chap_param = A:ORIGIN ('ChapterURL')
    elseif is_set (A.ScriptChapter) then
        chap_param = A:ORIGIN ('ScriptChapter')
    else is_set (A.ChapterFormat)
        chap_param = A:ORIGIN ('ChapterFormat')
    end

     -- se foi encontrado algum...
    if is_set (chap_param) then
        -- ... adiciona mensagem de erro
        table.insert( z.message_tail, { set_error( 'chapter_ignored', {chap_param}, true ) } )
        -- e esvazia para evitar problemas com concatenações
        A.Chapter = ''
        A.TransChapter = '';
        A.ChapterURL = '';
        A.ScriptChapter = '';
        A.ChapterFormat = '';
    end

    local TransTitle = A.TransTitle
    local Title = A.Title
    if is_set(A.TitleLink) and is_set(A.Title) then
        Title = "[[" .. A.TitleLink .. "|" .. Title .. "]]"
    end
    config.TituloFormatado = {}
    if is_set(A.Section) then
        Title = Title .. '&nbsp;' .. wrap_msg ('section', A.Section)
    end
    if (is_set(Title)) then
        Title = kern_quotes (Title)
        Title = wrap_style ('quoted-title', Title)
        config.TituloFormatado.Title = Title
    end
    if (is_set(TransTitle)) then
        TransTitle= wrap_style ('trans-quoted-title', TransTitle ) -- .. ", "
        config.TituloFormatado.TransTitle = TransTitle
    end

    -- Função com o código abstraído
    local B
    A, B = citation0( config, args, A)

    config.CitationClass = classe
    B.config = config

    return textoFinal(A, B)
end

return w