-- Importado de https://pt.wikipedia.org/wiki/Módulo:TableTools (Wikipédia em português, CC BY-SA 4.0).
-- Biblioteca-base padrão do Scribunto; sem dependência de Wikidata nem de estilos.
--------------------------------------------------------------------------------
--                                   TableTools                               --
--                                                                            --
-- Este módulo inclui várias funções para lidar com tabelas Lua.              --
-- É um metamódulo, destinado a ser chamado a partir de outros módulos Lua, e --
-- não deve ser chamado diretamente a partir de "#invoke".                    --
--------------------------------------------------------------------------------

local libraryUtil = require('libraryUtil')

local p = {}

-- Define variáveis e funções usadas com frequência.
local floor = math.floor
local infinity = math.huge
local checkType = libraryUtil.checkType
local checkTypeMulti = libraryUtil.checkTypeMulti

--------------------------------------------------------------------------------
-- isPositiveInteger
--
-- Esta função retorna "true" se o valor fornecido for um número inteiro 
-- positivo e "false" se não. Embora não opere em tabelas, ela é incluída aqui 
-- porque ela é útil para determinar se uma determinada chave de tabela está na 
-- parte de arranjo ou na parte de 'hash' de uma tabela.
--------------------------------------------------------------------------------
function p.isPositiveInteger(v)
	return type(v) == 'number' and v >= 1 and floor(v) == v and v < infinity
end

--------------------------------------------------------------------------------
-- isNan
--
-- Essa função retorna "true" se o número fornecido for um valor de "NaN" e 
-- "false" se não. Embora não opere em tabelas, ela é incluída aqui porque ela 
-- é útil para determinar se um valor pode ser uma chave de tabela válida. Lua 
-- irá gerar um erro se um "NaN" for usado como uma chave de tabela.
--------------------------------------------------------------------------------
function p.isNan(v)
	return type(v) == 'number' and v ~= v
end

--------------------------------------------------------------------------------
-- shallowClone
--
-- Essa função retorna um clone de uma tabela. O valor retornado é uma nova 
-- tabela, mas todas as subtabelas e funções são compartilhadas. Os metamétodos 
-- são respeitados, mas a tabela retornada não terá metatabela própria.
--------------------------------------------------------------------------------
function p.shallowClone(t)
	checkType('shallowClone', 1, t, 'table')
	local ret = {}
	for k, v in pairs(t) do
		ret[k] = v
	end
	return ret
end

--------------------------------------------------------------------------------
-- removeDuplicates
--
-- Essa função remove os valores duplicados de um arranjo. As chaves de  
-- números inteiros que não são positivos são ignoradas. O valor mais antigo é 
-- mantido e todos os valores duplicados subsequentes são removidos, mas caso 
-- não, a ordem do arranjo permanece inalterada.
--------------------------------------------------------------------------------
function p.removeDuplicates(arr)
	checkType('removeDuplicates', 1, arr, 'table')
	local isNan = p.isNan
	local ret, exists = {}, {}
	for _, v in ipairs(arr) do
		if isNan(v) then
			-- Os "NaN"s não podem ser chaves de tabela e também são únicos,
			-- portanto não precisamos verificar a existência.
			ret[#ret + 1] = v
		elseif not exists[v] then
			ret[#ret + 1] = v
			exists[v] = true
		end
	end
	return ret
end

--------------------------------------------------------------------------------
-- numKeys
--
-- Essa função pega uma tabela e retorna um arranjo contendo os números 
-- de quaisquer chaves numéricas que tenham valores que não são nulos,
-- classificados em ordem numérica.
--------------------------------------------------------------------------------
function p.numKeys(t)
	checkType('numKeys', 1, t, 'table')
	local isPositiveInteger = p.isPositiveInteger
	local nums = {}
	for k in pairs(t) do
		if isPositiveInteger(k) then
			nums[#nums + 1] = k
		end
	end
	table.sort(nums)
	return nums
end

--------------------------------------------------------------------------------
-- affixNums
--
-- Essa função pega uma tabela e retorna um arranjo contendo os números 
-- de chaves com o prefixo e sufixo especificados. Por exemplo, para a tabela
-- {a1 = 'foo', a3 = 'bar', a6 = 'baz'} e o prefixo "a", "affixNums" retornará
-- {1, 3, 6}.
--------------------------------------------------------------------------------
function p.affixNums(t, prefix, suffix)
	checkType('affixNums', 1, t, 'table')
	checkType('affixNums', 2, prefix, 'string', true)
	checkType('affixNums', 3, suffix, 'string', true)

	local function cleanPattern(s)
		-- Limpa um padrão ('pattern') para que os caracteres mágicos "()%.[]*+-?^$"
		-- sejam interpretados literalmente.
		return s:gsub('([%(%)%%%.%[%]%*%+%-%?%^%$])', '%%%1')
	end

	prefix = prefix or ''
	suffix = suffix or ''
	prefix = cleanPattern(prefix)
	suffix = cleanPattern(suffix)
	local pattern = '^' .. prefix .. '([1-9]%d*)' .. suffix .. '$'

	local nums = {}
	for k in pairs(t) do
		if type(k) == 'string' then
			local num = mw.ustring.match(k, pattern)
			if num then
				nums[#nums + 1] = tonumber(num)
			end
		end
	end
	table.sort(nums)
	return nums
end

--------------------------------------------------------------------------------
-- numData
--
-- Dada uma tabela com chaves como {"foo1", "bar1", "foo2", "baz2"}, essa 
-- função retorna uma tabela de subtabelas no formato
-- {[1] = {foo = 'texto', bar = 'texto'}, [2] = {foo = 'texto', baz = 'texto'}}.
-- As chaves que não terminam com um número inteiro são armazenadas em uma 
-- subtabela chamada "other". A opção "compress" comprime a tabela para que 
-- ela possa ser iterada com "ipairs".
--------------------------------------------------------------------------------
function p.numData(t, compress)
	checkType('numData', 1, t, 'table')
	checkType('numData', 2, compress, 'boolean', true)
	local ret = {}
	for k, v in pairs(t) do
		local prefix, num = mw.ustring.match(tostring(k), '^([^0-9]*)([1-9][0-9]*)$')
		if num then
			num = tonumber(num)
			local subtable = ret[num] or {}
			if prefix == '' then
				-- Os parâmetros posicionais correspondem à sequência em branco; 
				-- coloca-os no início da subtabela.
				prefix = 1
			end
			subtable[prefix] = v
			ret[num] = subtable
		else
			local subtable = ret.other or {}
			subtable[k] = v
			ret.other = subtable
		end
	end
	if compress then
		local other = ret.other
		ret = p.compressSparseArray(ret)
		ret.other = other
	end
	return ret
end

--------------------------------------------------------------------------------
-- compressSparseArray
--
-- Essa função pega um arranjo com um ou mais valores nulos e  
-- remove os valores nulos enquanto preserva a ordem, para que o arranjo
-- possa ser percorrido com segurança com "ipairs".
--------------------------------------------------------------------------------
function p.compressSparseArray(t)
	checkType('compressSparseArray', 1, t, 'table')
	local ret = {}
	local nums = p.numKeys(t)
	for _, num in ipairs(nums) do
		ret[#ret + 1] = t[num]
	end
	return ret
end

--------------------------------------------------------------------------------
-- sparseIpairs
--
-- Esta função é uma iteradora para arranjos esparsos. Ela pode ser 
-- usada como "ipairs", mas pode manipular valores nulos.
--------------------------------------------------------------------------------
function p.sparseIpairs(t)
	checkType('sparseIpairs', 1, t, 'table')
	local nums = p.numKeys(t)
	local i = 0
	local lim = #nums
	return function ()
		i = i + 1
		if i <= lim then
			local key = nums[i]
			return key, t[key]
		else
			return nil, nil
		end
	end
end

--------------------------------------------------------------------------------
-- size
--
-- Essa função retorna o tamanho de uma tabela de pares chave/valor. Ela 
-- também funcionará em arranjos, mas para arranjos é mais eficiente usar o 
-- operador #.
--------------------------------------------------------------------------------
function p.size(t)
	checkType('size', 1, t, 'table')
	local i = 0
	for _ in pairs(t) do
		i = i + 1
	end
	return i
end

local function defaultKeySort(item1, item2)
	-- número < sequência, então os números serão ordenados antes das 
	-- sequências.
	local type1, type2 = type(item1), type(item2)
	if type1 ~= type2 then
		return type1 < type2
	elseif type1 == 'table' or type1 == 'boolean' or type1 == 'function' then
		return tostring(item1) < tostring(item2)
	else
		return item1 < item2
	end
end
--------------------------------------------------------------------------------
-- keysToList
--
-- Essa função retorna um arranjo das chaves em uma tabela, ordenada usando
-- uma função de comparação padrão ou uma função "keySort" personalizada.
--------------------------------------------------------------------------------
function p.keysToList(t, keySort, checked)
	if not checked then
		checkType('keysToList', 1, t, 'table')
		checkTypeMulti('keysToList', 2, keySort, {'function', 'boolean', 'nil'})
	end

	local arr = {}
	local index = 1
	for k in pairs(t) do
		arr[index] = k
		index = index + 1
	end

	if keySort ~= false then
		keySort = type(keySort) == 'function' and keySort or defaultKeySort
		table.sort(arr, keySort)
	end

	return arr
end

--------------------------------------------------------------------------------
-- sortedPairs
--
-- Essa função itera por meio de uma tabela, com as chaves ordenadas usando a 
-- função "keysToList". Se houver apenas chaves numéricas, "sparseIpairs" 
-- provavelmente será mais eficiente.
--------------------------------------------------------------------------------
function p.sortedPairs(t, keySort)
	checkType('sortedPairs', 1, t, 'table')
	checkType('sortedPairs', 2, keySort, 'function', true)

	local arr = p.keysToList(t, keySort, true)

	local i = 0
	return function ()
		i = i + 1
		local key = arr[i]
		if key ~= nil then
			return key, t[key]
		else
			return nil, nil
		end
	end
end

--------------------------------------------------------------------------------
-- isArray
--
-- Essa função retorna "true" se o valor fornecido for uma tabela e todas as   
-- chaves forem números inteiros consecutivos começando em 1.
--------------------------------------------------------------------------------
function p.isArray(v)
	if type(v) ~= 'table' then
		return false
	end
	local i = 0
	for _ in pairs(v) do
		i = i + 1
		if v[i] == nil then
			return false
		end
	end
	return true
end

--------------------------------------------------------------------------------
-- isArrayLike
--
-- Essa função retorna "true" se o valor fornecido for iterável e todas as  
-- chaves forem números inteiros consecutivos começando em 1.
--------------------------------------------------------------------------------
function p.isArrayLike(v)
	if not pcall(pairs, v) then
		return false
	end
	local i = 0
	for _ in pairs(v) do
		i = i + 1
		if v[i] == nil then
			return false
		end
	end
	return true
end

--------------------------------------------------------------------------------
-- invert
--
-- Essa função transpõe as chaves e valores em um arranjo. Por exemplo, 
-- {"a", "b", "c"} -> {a = 1, b = 2, c = 3}. As duplicatas não são suportadas 
-- (os valores dos resultados referem-se ao índice da última duplicata) e os  
-- valores "NaN" são ignorados.
--------------------------------------------------------------------------------
function p.invert(arr)
	checkType("invert", 1, arr, "table")
	local isNan = p.isNan
	local map = {}
	for i, v in ipairs(arr) do
		if not isNan(v) then
			map[v] = i
		end
	end

	return map
end

--------------------------------------------------------------------------------
-- listToSet
--
-- Essa função cria um conjunto a partir da parte do arranjo da tabela. 
-- A indexação do conjunto por qualquer um dos valores do arranjo retorna
-- "true". Por exemplo, {"a", "b", "c"} -> {a = true, b = true, c = true}. Os
-- valores "NaN" são ignorados, pois Lua os considera como nunca sendo iguais 
-- a qualquer valor (incluindo outros "NaN"s ou até eles mesmos).
--------------------------------------------------------------------------------
function p.listToSet(arr)
	checkType("listToSet", 1, arr, "table")
	local isNan = p.isNan
	local set = {}
	for _, v in ipairs(arr) do
		if not isNan(v) then
			set[v] = true
		end
	end

	return set
end

--------------------------------------------------------------------------------
-- deepCopy
--
-- Função de cópia profunda recursiva. Preserva as identidades das subtabelas.
--------------------------------------------------------------------------------
local function _deepCopy(orig, includeMetatable, already_seen)
	if type(orig) ~= "table" then
		return orig
	end
	
	-- already_seen armazena as cópias das tabelas indexadas pela tabela 
	-- original.
	local copy = already_seen[orig]
	if copy ~= nil then
		return copy
	end
	
	copy = {}
	already_seen[orig] = copy -- memoriza antes de qualquer recursão, para 
							  -- evitar loops infinitos
	
	for orig_key, orig_value in pairs(orig) do
		copy[_deepCopy(orig_key, includeMetatable, already_seen)] = _deepCopy(orig_value, includeMetatable, already_seen)
	end
	
	if includeMetatable then
		local mt = getmetatable(orig)
		if mt ~= nil then
			setmetatable(copy, _deepCopy(mt, true, already_seen))
		end
	end
	
	return copy
end

function p.deepCopy(orig, noMetatable, already_seen)
	checkType("deepCopy", 3, already_seen, "table", true)
	return _deepCopy(orig, not noMetatable, already_seen or {})
end

--------------------------------------------------------------------------------
-- sparseConcat
--
-- Essa função concatena todos os valores na tabela que são indexados por 
-- um número, em ordem.
-- "sparseConcat{a, nil, c, d}"  =>  "acd"
-- "sparseConcat{nil, b, c, d}"  =>  "bcd"
--------------------------------------------------------------------------------
function p.sparseConcat(t, sep, i, j)
	local arr = {}

	local arr_i = 0
	for _, v in p.sparseIpairs(t) do
		arr_i = arr_i + 1
		arr[arr_i] = v
	end

	return table.concat(arr, sep, i, j)
end

--------------------------------------------------------------------------------
-- length
--
-- Essa função localiza o comprimento de um arranjo ou de um 
-- quase-arranjo com chaves como "data1", "data2" etc., usando um
-- algoritmo de pesquisa exponencial. Ela é semelhante ao operador #, mas pode 
-- retornar um valor diferente quando houver lacunas na parte do arranjo
-- da tabela. Destina-se a ser usada em dados carregados com "mw.loadData".  
-- Para outras tabelas, use #.
-- Observação: "#frame.args" no objeto "frame" sempre será definido como 0, 
-- independentemente do número de parâmetros de predefinição sem nome, 
-- portanto, use esta função para "frame.args".
--------------------------------------------------------------------------------
function p.length(t, prefix)
	-- Exige módulo embutido, de modo que 
	-- [[Módulo:Exponential search]] que é necessário 
	-- somente para esta função, não obtenha milhões de transclusões.
	local expSearch = require("Módulo:Exponential search")
	checkType('length', 1, t, 'table')
	checkType('length', 2, prefix, 'string', true)
	return expSearch(function (i)
		local key
		if prefix then
			key = prefix .. tostring(i)
		else
			key = i
		end
		return t[key] ~= nil
	end) or 0
end

--------------------------------------------------------------------------------
-- inArray
--
-- Essa função Retorna "true" se "searchElement" for um membro do arranjo
-- e "false" se não. Equivalente a "array.includes(searchElement)" ou
-- "array.includes(searchElement, fromIndex)", exceto que "fromIndex" é 1 
-- indexado
--------------------------------------------------------------------------------
function p.inArray(array, searchElement, fromIndex)
	checkType("inArray", 1, array, "table")
	-- se "searchElement" for nulo, erro?

	fromIndex = tonumber(fromIndex)
	if fromIndex then
		if (fromIndex < 0) then
			fromIndex = #array + fromIndex + 1
		end
		if fromIndex < 1 then fromIndex = 1 end
		for _, v in ipairs({unpack(array, fromIndex)}) do
			if v == searchElement then
				return true
			end
		end
	else
		for _, v in pairs(array) do
			if v == searchElement then
				return true
			end
		end
	end
	return false
end

--------------------------------------------------------------------------------
-- merge
--
-- Dados os arranjos, retorna um arranjo contendo os elementos de cada arranjo 
-- de entrada em sequência.
--------------------------------------------------------------------------------
function p.merge(...)
	local arrays = {...}
	local ret = {}
	for i, arr in ipairs(arrays) do
		checkType('merge', i, arr, 'table')
		for _, v in ipairs(arr) do
			ret[#ret + 1] = v
		end
	end
	return ret
end

--------------------------------------------------------------------------------
-- extend
--
-- Estende o primeiro arranjo no lugar anexando todos os elementos do segundo
-- arranjo.
--------------------------------------------------------------------------------
function p.extend(arr1, arr2)
	checkType('extend', 1, arr1, 'table')
	checkType('extend', 2, arr2, 'table')

	for _, v in ipairs(arr2) do
		arr1[#arr1 + 1] = v
	end
end

return p