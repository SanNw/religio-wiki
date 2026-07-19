-- Importado de https://pt.wikipedia.org/wiki/Módulo:Yesno (Wikipédia em português, CC BY-SA 4.0).
-- Biblioteca-base padrão do Scribunto; sem dependência de Wikidata nem de estilos.
-- Função que permite o tratamento consistente de texto wiki de entrada do tipo booleano.
-- Ela funciona similarmente à predefinição {{Yesno}}.

return function (val, default)
	-- Essa wiki usa caracteres que não são "ASCII" (o "ã" do "não") para "sim", "não", etc., foi
	-- preciso substituir "val:lower()" por "mw.ustring.lower(val)" na
	-- linha seguinte.
	val = type(val) == 'string' and mw.ustring.lower(val) or val
	if val == nil then
		return nil
	elseif val == true 
		or val == 'yes'
		or val == 'sim'
		or val == 'y'
		or val == 's'
		or val == 'true'
		or val == 'verdadeiro'
		or val == 't'
		or val == 'v'
		or val == 'on'
		or val == 'ligado'
		or val == 'l'
		or tonumber(val) == 1
	then
		return true
	elseif val == false
		or val == 'no'
		or val == 'não'
		or val == 'nao'
		or val == 'n'
		or val == 'false'
		or val == 'falso'
		or val == 'f'
		or val == 'off'
		or val == 'desligado'
		or val == 'd'
		or tonumber(val) == 0
	then
		return false
	else
		return default
	end
end