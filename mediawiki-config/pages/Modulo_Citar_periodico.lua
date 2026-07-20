-- Importado de https://pt.wikipedia.org/wiki/M%C3%B3dulo%3ACitar_peri%C3%B3dico (Wikipédia em português, CC BY-SA 4.0).
local p = require('Módulo:Citação/CS1')

--[[--------------------------< a b s t r a c a o >-----------------------------------

Código em comum às citações de periódico

]]
local abstracao = function(config, A)
    config.usaVolume = true
    config.usaIssue = true
    config.ChapterNaoSuportado = true
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
    if (is_set(Title)) then
        Title = kern_quotes (Title)
        Title = wrap_style ('quoted-title', Title)
        config.TituloFormatado.Title = Title
    end
    if (is_set(TransTitle)) then
        TransTitle= wrap_style ('trans-quoted-title', TransTitle ) -- .. ", "
        config.TituloFormatado.TransTitle = TransTitle
    end

end

--[[--------------------------< p . p e r i o d i c o >----------------------------------

Este é o método principal da predefinição {{citar periódico}}.

]]

p.periodico = function(frame)
    frame.whitelist = { aspas = true,
    					mes = true,
    					["mês"] = true}
    local config, args, A = tratarArgumentos(frame)
    config.CitationClass = ''
    config.permPCMcomoURL = true
    local classe = 'journal'

    -- abstração de códigos que os periódicos têm em comum
    abstracao(config, A)

    if is_set(args.aspas) and args.aspas:lower() == 'não' then
    	config.TituloFormatado = nil
    end
    
    local mes = args.mes or args["mês"]
    if is_set(A.Year) and is_set(mes) then
    	meses = {"janeiro", "fevereiro", "março", "abril", "maio", "junho", "julho", "agosto", "setembro", "outubro", "novembro", "dezembro"}
    	local n = mes:match("^(%d+)$")
    	n = n and tonumber(n)
    	if n and n > 0 and n < 13 then
        	A.Date = meses[n] .. ' de ' .. A.Year
        	A.Year = ''
        else
        	existe = false
        	for _,m in pairs(meses) do
        		if m == tostring(mes) then
	        		existe = true
	        		break
	        	end
	        end
    		if (existe) then
        		A.Date = mes .. ' de ' .. A.Year
	        	A.Year = ''
        	end
        end
    end

    local sepc = set_style (A.Mode:lower())
    local use_lowercase = sepc == ','
    local page, pages = '', ''
    -- mla sempre usa os prefixos p ou pp
    if A.Mode:lower() ~= 'mla' then
        if is_set(A.Page) then
            page = substitute(cfg.messages['j-page(s)'], A.Page)
        elseif is_set(A.Pages) then
            page = substitute (cfg.messages['j-page(s)'], A.Pages)
        end
        if is_set(A.TotalPages) then
            pages = substitute (cfg.messages['total-p'], {sepc, A.TotalPages})
        end
    else
        page, pages = format_pages (A.Page, A.Pages, sepc, A.NoPP, use_lowercase, A.TotalPages)
    end

    local volume = A.Volume
    if ('mla' == A.Mode:lower()) then
        -- mla 8th edition; força letra minúscula
        if is_set (volume) and is_set (A.Issue) then
            volume = wrap_msg ('vol-no', {sepc, volume, A.Issue}, true)
        elseif is_set (volume) then
            volume = wrap_msg ('vol', {sepc, volume}, true)
        else
            volume = ''
        end
    else
        volume = format_volume_issue (volume, A.Issue, sepc, use_lowercase)
    end
    if not is_set(A.Title) and is_set(volume) then
        config.TituloDispensavel = true
        if is_set(A.URL) then
            for i=1,volume:len() do
                if volume:sub(i,i):match(("[^%".. sepc .. "%s]")) then
                    volume = volume:sub(1, i-1) .. '['.. A.URL .. ' '.. volume:sub(i) .. ']'
                    break
                end
            end
            A.URL = ''
        end
	end

    -- Função com o código abstraído
    local B
    A, B = citation0(config, args, A)
    A.Page = page
    A.Pages = pages
    A.Volume = volume

    if is_set(A.Others) then
        A.Others = A.Others .. B.sepc .. " "
    end
    if 'mla' == A.Mode then
        B.tcommon = safe_join( {A.Periodical, A.Format, A.TitleType, A.Series, A.Language
            , A.Edition, B.Publisher, A.Agency, A.Volume}, B.sepc )
    else
        B.tcommon = safe_join( {A.Others, A.Title, A.TitleNote, A.Edition, B.Publisher, A.Periodical
            , A.Format, A.TitleType, A.Series, A.Language, A.Agency, A.Volume}, B.sepc )
    end


    config.CitationClass = classe
    B.config = config

    return textoFinal(A, B)
end


--[[--------------------------< p . j o r n a l >-----------------------------------------

Este é o método principal da predefinição {{citar jornal}}.

]]

p.jornal = function(frame)
    local config, args, A = tratarArgumentos(frame)
    config.CitationClass = ''
    local classe = 'news'

    -- abstração de códigos que os periódicos têm em comum
    abstracao(config, A)

    -- Função com o código abstraído
    local B
    A, B = citation0(config, args, A)

    if ('mla' == A.Mode) then -- caso especial caso estiver no modo MLA
        B.tcommon = safe_join( {A.Periodical, A.Format, A.TitleType, A.Series
            , A.Language, A.Edition, B.Publisher, A.Agency}, B.sepc )
    else
        B.tcommon = safe_join({A.Title, A.TitleNote, A.Periodical, A.Format, A.TitleType
            , A.Series, A.Language, A.Volume, A.Others, A.Edition, B.Publisher, A.Agency}, B.sepc )
    end

    config.CitationClass = classe
    B.config = config

    return textoFinal(A, B)
end


--[[--------------------------< p . r e v i s t a >----------------------------------

Este é o método principal da predefinição {{citar revista}}.

]]

p.revista = function(frame)
    local config, args, A = tratarArgumentos(frame)
    config.CitationClass = ''
    local classe = 'magazine'

    -- abstração de códigos que os periódicos têm em comum
    abstracao(config, A)


    local sepc = set_style (A.Mode:lower())
    local volume = A.Volume
    if is_set (volume) and is_set (A.Issue) then
        volume = wrap_msg ('vol-no', {sepc, volume, A.Issue}, sepc == ',');
    elseif is_set (volume) then
        volume = wrap_msg ('vol', {sepc, volume}, sepc == ',');
    elseif is_set (A.Issue) then
        volume = wrap_msg ('issue', {sepc, A.Issue}, sepc == ',');
    else
        volume = ''
    end

    -- Função com o código abstraído
    local B
    A, B = citation0(config, args, A)
    A.Volume = volume

    config.CitationClass = classe
    B.config = config

    return textoFinal(A, B)
end

return p