-- Importado de https://pt.wikipedia.org/wiki/M%C3%B3dulo%3ACitar_tese (Wikipédia em português, CC BY-SA 4.0).
local t = require('Módulo:Citação/CS1')

--[[--------------------------< r . t e s e >------------------------------------------------------

Este é o método principal da predefinição {{citar tese}}

]]

t.tese= function(frame)
    frame.whitelist = {
        grau = true,
        degree = true,
        grado = true
    }
    local config, args, A = tratarArgumentos(frame)
    config.CitationClass = ''
    config.usaVolume = true
    local classe = 'thesis'

    cfg.aliases.Degree = {'grau', 'degree', 'grado'}
    
    if is_set(A.Docket) then
        if is_set(A.ID) then
            local sepc = set_style (A.Mode:lower())
            A.ID = sepc .. ' ' ..A.ID
        end
        A.ID = "Expediente: ".. A.Docket .. A.ID
    end

    A.TitleType = set_titletype (classe, A.TitleType)
    if (cfg.title_types[classe] ~= A.TitleType) then
        A.TitleType = A.TitleType:sub(1, 1):upper() .. A.TitleType:sub(2)
    end
    if (cfg.title_types[classe] == A.TitleType or A.TitleType == 'Dissertação') and is_set(A.Degree) then
        A.TitleType = A.TitleType .. ' de ' .. A.Degree
    end

    -- Função com o código abstraído
    local B
    A, B = citation0( config, args, A)

    B.coins_table.Degree = A.Degree

    config.CitationClass = classe
    B.config = config

    return textoFinal(A, B)
end

return t