-- Importado de https://pt.wikipedia.org/wiki/M%C3%B3dulo%3ACitar_confer%C3%AAncia (Wikipédia em português, CC BY-SA 4.0).
local c = require('Módulo:Citação/CS1')


--[[--------------------------< c . c o n f e r e n c i a >------------------------------------

Este é o método principal da predefinição {{citar série}}.

]]

c.conferencia = function(frame)
    local config, args, A = tratarArgumentos(frame)
    config.CitationClass = ''
    config.usaVolume = true
    config.usaIssue = true
    local B
    local sepc = set_style (A.Mode:lower())

    local ConferenceURLorigin = A:ORIGIN('ConferenceURL')

    -- conferência no formato de livro não suporta o parâmetro issue
    if not is_set (A.Periodical) then
        A.Issue = ''
    end


    if is_set(A.BookTitle) then
        cfg.aliases.ChapterURL = cfg.aliases.URL
        --[[ isto é apenas para forçar o upvalue da tabela 'origin' do metadados de
         'A' a carregar o nome do alias usado pelo parâmetro em tal tabela.
        ]]
        A:ORIGIN('Chapter')
        A:ORIGIN('URL')
        A.Chapter = A.Title
        --ChapterURLorigin = URLorigin
        A.ChapterFormat = A.Format
        A.TransChapter = A.TransTitle
        A.Title = A.BookTitle
        A.Format = ''
        A.TransTitle = '';
        A.URL = '';
    end

    A.ConferenceFormat = style_format (A.ConferenceFormat, A.ConferenceURL, 'conference-format', 'conference-url');

    if is_set (A.Conference) then
        if is_set (A.ConferenceURL) then
            A.Conference = external_link( A.ConferenceURL, A.Conference, ConferenceURLorigin, nil );
        end
        A.Conference = sepc .. " " .. A.Conference .. A.ConferenceFormat;
    elseif is_set(A.ConferenceURL) then
        A.Conference = sepc .. " " .. external_link( A.ConferenceURL, nil, ConferenceURLorigin, nil );
    end

    -- Função com o código abstraído
    A, B = citation0( config, args, A)

    B.tcommon = safe_join( {A.Title, A.TitleNote, A.Conference, A.Periodical, A.Format, A.TitleType
        , A.Series, A.Language, A.Volume, A.Others, A.Edition, B.Publisher, A.Agency}, sepc )

    config.CitationClass = 'conference'
    B.config = config

    return textoFinal(A, B)
end

return c