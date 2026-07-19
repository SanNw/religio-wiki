-- Importado de https://pt.wikipedia.org/wiki/Módulo:Exponential_search (Wikipédia em português, CC BY-SA 4.0).
-- Este módulo fornece um algoritmo de pesquisa exponencial genérico.
require[[strict]]

local checkType = require('libraryUtil').checkType
local floor = math.floor

local function midPoint(lower, upper)
	return floor(lower + (upper - lower) / 2)
end

local function search(testFunc, i, lower, upper)
	if testFunc(i) then
		if i + 1 == upper then
			return i
		end
		lower = i
		if upper then
			i = midPoint(lower, upper)
		else
			i = i * 2
		end
		return search(testFunc, i, lower, upper)
	else
		upper = i
		i = midPoint(lower, upper)
		return search(testFunc, i, lower, upper)
	end
end

return function (testFunc, init)
	checkType('Exponential search', 1, testFunc, 'function') -- Falta confirmar se 'Exponential search' pode ser traduzido. Acho que sim, mas ainda não tenho certeza.
	checkType('Exponential search', 2, init, 'number', true) -- Falta confirmar se 'Exponential search' pode ser traduzido. Acho que sim, mas ainda não tenho certeza.
	if init and (init < 1 or init ~= floor(init) or init == math.huge) then
		error(string.format(
			"valor de inicialização ('init') '%s' inválido detectado no argumento #2 para " ..
			"'Exponential search' (o valor inicial ('init') deve ser um número inteiro positivo)", -- Falta confirmar se 'Exponential search' pode ser traduzido. Acho que sim, mas ainda não tenho certeza.
			tostring(init)
		), 2)
	end
	init = init or 2
	if not testFunc(1) then
		return nil
	end
	return search(testFunc, init, 1, nil)
end