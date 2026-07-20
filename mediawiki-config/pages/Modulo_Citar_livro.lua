-- Importado de https://pt.wikipedia.org/wiki/M%C3%B3dulo%3ACitar_livro (Wikipédia em português, CC BY-SA 4.0).
local l = require('Módulo:Citação/CS1')

--[[--------------------------< l . l i v r o >-----------------------------------------------

Este é o método principal da predefinição {{citar livro}}

]]

l.livro= function(frame)
    local config, args, A = tratarArgumentos(frame)
    config.CitationClass = ''
    config.usaVolume = true
    config.usaContributor = true

    cfg.aliases.Number = {'número', 'numero'}

    -- coleção é alias de séries
    local coins_series = ''
    if is_set(A.Series) then
    	if is_set(A.Number) then
        	A.Series = A.Series .. ',&nbsp;' .. A.Number
        end
		coins_series = A.Series
	    A.Series = 'Col: ' .. A.Series
    end

    -- Função com o código abstraído
    local B
    A, B = citation0( config, args, A)

    B.coins_table.Series = coins_series

    local sn = is_set(A.PublisherName) and '' or (': [s.n.]')
    local sl = is_set(A.PublicationPlace) and '' or '[S.l.]: '
    if A.PublisherName:lower():match("^%s*desconhecido%s*$") then
	    B.coins_table.PublisherName = ''
        sn = ''
        A.PublisherName = ''
    end
    if A.PublicationPlace:lower():match("^%s*desconhecido%s*$") then
	    B.coins_table.PublicationPlace = ''
        sl = ''
        A.PublicationPlace = ''
    end

    if (sn ~= '') then
	    if (sl ~= '') then
        	sl = B.sepc .. " [S.l.: s.n.]"
	        sn = ''
        elseif not is_set(A.PublicationPlace) then
        	sn = B.sepc .. ' [S.n.]'
        end
    else
    	if sl ~= '' and not is_set(A.PublisherName) then
	   		sl = B.sepc .. ' [S.l.]'
	   	end
    end

    if is_set(A.PublisherName) then
        B.Publisher = B.sepc .. " " .. (is_set(A.PublicationPlace) and (A.PublicationPlace .. ": ")
            or sl) .. A.PublisherName .. A.PublicationDate
    elseif is_set(A.PublicationPlace) then
        B.Publisher= B.sepc .. " " .. A.PublicationPlace
            .. sn .. A.PublicationDate
    else
        B.Publisher =  sl .. sn .. A.PublicationDate
    end

    if is_set (B.Contributors) then -- when we are citing foreword, preface, introduction, etc
        B.tcommon = safe_join( {A.Title, A.TitleNote}, B.sepc ) -- author and other stuff will come after this and before tcommon2
        if 'mla' == A.Mode then
            B.tcommon2 = safe_join( {A.Periodical, A.Format, A.TitleType, A.Edition, B.Publisher, A.Series, A.Language, A.Volume, A.Agency}, B.sepc )
        else
            B.tcommon2 = safe_join( {A.Periodical, A.Format, A.TitleType, A.Edition, B.Publisher, A.Series, A.Language, A.Volume, A.Others, A.Agency}, B.sepc )
        end
    elseif 'mla' == A.Mode then
        B.tcommon = safe_join( {A.TitleNote, A.Periodical, A.Format, A.TitleType, A.Series, A.Language, A.Volume, B.Publisher, A.Agency}, B.sepc )
    else
        B.tcommon = safe_join( {A.Title, A.TitleNote, A.Periodical, A.Format, A.TitleType, A.Series, A.Language, A.Volume, A.Others, A.Edition, B.Publisher, A.Agency}, B.sepc )
    end

    config.CitationClass = 'book'
    B.config = config

    return textoFinal(A, B)
end

return l