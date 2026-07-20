-- Importado de https://pt.wikipedia.org/wiki/M%C3%B3dulo%3AConversor_de_data (Wikipédia em português, CC BY-SA 4.0).
local p = {}

local month_names = {"janeiro", "fevereiro", "março", "abril", "maio", "junho", "julho", "agosto", "setembro", "outubro", "novembro", "dezembro"}

local function d_m_y(day, month, year)
	year = tonumber(year)
	day = tonumber(day)
	month = tonumber(month)
    
	-- Inverte dia pelo ano, caso o formato da data for xxxx/xx/xx
	if (day and day > 100) then
		day, year = year, day
	end

	-- Soma dois mil caso a data inserida for de dois dígitos
	if (year and year < 100) then
		year = year + 2000
	end

	-- Inverte dia pelo mes, caso o formato da data mês/dia/ano
	if (month and (month > 12 and month < 32)) then
		day, month = month, day
	end

	-- Algumas poucas páginas tinham erro de índice inexistente para o mês
	if (month and (month > 12 or month < 1)) then
		month = nil
	end

	if (day and month and year) ~= nil then
		return day .. " de " .. month_names[month] .. " de " .. year
	end

	return nil
end

local function m_y(month, year)
	year = tonumber(year)
	month = tonumber(month)
    
	-- Retorna nil se nenhum dos números for ano maior que 1000
	if not year or not month or (year < 1000 and month < 1000) then
		return nil
	end
	
	-- Inverte mês pelo ano, caso o formato da data ano/mês
	if month > 1000 then
		month, year = year, month
	end
	
	-- Algumas poucas páginas tinham erro de índice inexistente para o mês
	if month > 12 or month < 1 then
		return nil
	end

	if (month and year) ~= nil then
		return month_names[month] .. " de " .. year
	end

	return nil
end

function p.main(frame)
	local date = frame.args[1]
	local converted
	local day, month, year = string.match(date, "^(%d+)[/%.%-](%d+)[/%.%-](%d+)$")
	if day then
		converted = d_m_y(day, month, year)
	else
		month, year = string.match(date, "^(%d+)[/%.%-](%d+)$")
		converted = m_y(month, year)
	end
	return converted or date
end

return p