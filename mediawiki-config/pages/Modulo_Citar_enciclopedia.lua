-- Importado de https://pt.wikipedia.org/wiki/M%C3%B3dulo%3ACitar_enciclop%C3%A9dia (Wikipédia em português, CC BY-SA 4.0).
local e = require('Módulo:Citação/CS1')

--[[--------------------------< e . e n c i c l o p e d i a >---------------------------------

Este é o método principal da predefinição {{citar enciclopédia}}.

]]

e.enciclopedia = function(frame)
    local config, args, A = tratarArgumentos(frame)
    config.CitationClass = ''
    config.usaVolume = true

    local coins_chapter
    local coins_title
    if is_set(A.Periodical) then -- Periodical definido quando |encyclopedia também é
        if is_set(A.Title) or is_set (A.ScriptTitle) then
            if not is_set(A.Chapter) then
    -- |encyclopedia e |title definidos, mapeia |title para |article e |encyclopedia para |title
                A.Chapter = A.Title
                A.ScriptChapter = A.ScriptTitle
                A.TransChapter = A.TransTitle
                A.ChapterURL = A.URL
                if not is_set (A.ChapterURL) and is_set (A.TitleLink) then
                    A.Chapter= '[[' .. A.TitleLink .. '|' .. A.Chapter .. ']]'
                end
                A.Title = A.Periodical
                A.ChapterFormat = A.Format
                A.Periodical = '' -- redundante
                A.TransTitle = ''
                A.URL = ''
                A.Format = ''
                A.TitleLink = ''
                A.ScriptTitle = ''
            elseif is_set(A.Title) then
                coins_chapter =  A.Title -- remapeia
                coins_title = A.Periodical
            end
        else -- |title não definido
            A.Title = A.Periodical -- mapeia |encyclopedia (alias) ao título
            A.Periodical = '' -- redundante
        end
    end
    coins_chapter = make_coins_title (coins_chapter or A.Chapter, A.ScriptChapter)
    coins_title = make_coins_title (coins_title or A.Title, A.ScriptTitle)

    -- Função com o código abstraído
    local B
    A, B = citation0( config, args, A)

    B.coins_table.Chapter = coins_chapter
    B.coins_table.Title = coins_title

    config.CitationClass = 'encyclopaedia'
    B.config = config

    return textoFinal(A, B)
end

return e