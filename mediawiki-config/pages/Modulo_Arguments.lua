-- Importado de https://pt.wikipedia.org/wiki/Módulo:Arguments (Wikipédia em português, CC BY-SA 4.0).
-- Biblioteca-base padrão do Scribunto; sem dependência de Wikidata nem de estilos.
-- Este módulo fornece processamento fácil de argumentos passados para a Scribunto 
-- a partir de #invoke. Ele destina-se ao uso por outros módulos Lua e não 
-- deve ser chamado diretamente a partir de #invoke.

local libraryUtil = require('libraryUtil')
local checkType = libraryUtil.checkType

local arguments = {}

-- Gera quatro funções "tidyVal" diferentes, para que não tenhamos que verificar 
-- as opções todas vezes que chamamos.

local function tidyValDefault(key, val)
	if type(val) == 'string' then
		val = val:match('^%s*(.-)%s*$')
		if val == '' then
			return nil
		else
			return val
		end
	else
		return val
	end
end

local function tidyValTrimOnly(key, val)
	if type(val) == 'string' then
		return val:match('^%s*(.-)%s*$')
	else
		return val
	end
end

local function tidyValRemoveBlanksOnly(key, val)
	if type(val) == 'string' then
		if val:find('%S') then
			return val
		else
			return nil
		end
	else
		return val
	end
end

local function tidyValNoChange(key, val)
	return val
end

local function matchesTitle(given, title)
	local tp = type( given )
	return (tp == 'string' or tp == 'number') and mw.title.new( given ).prefixedText == title
end

local translate_mt = { __index = function(t, k) return k end }

function arguments.getArgs(frame, options)
	checkType('getArgs', 1, frame, 'table', true)
	checkType('getArgs', 2, options, 'table', true)
	frame = frame or {}
	options = options or {}

	--[[
	-- Define a tradução de argumentos.
	--]]
	options.translate = options.translate or {}
	if getmetatable(options.translate) == nil then
		setmetatable(options.translate, translate_mt)
	end
	if options.backtranslate == nil then
		options.backtranslate = {}
		for k,v in pairs(options.translate) do
			options.backtranslate[v] = k
		end
	end
	if options.backtranslate and getmetatable(options.backtranslate) == nil then
		setmetatable(options.backtranslate, {
			__index = function(t, k)
				if options.translate[k] ~= k then
					return nil
				else
					return k
				end
			end
		})
	end

	--[[
	-- Obtém as tabelas de argumentos. Se nos foi passado um objeto de quadro válido, 
	-- obtemos os argumentos do quadro ("fargs") e os argumentos do quadro parental ("pargs"),
	-- dependendo das opções definidas e da disponibilidade do quadro parental. Se não nos 
	-- foi passado um objeto de quadro válido, estamos sendo chamados de outro módulo Lua
	-- ou do console de depuração, então assume que uma tabela de argumentos nos foi passada
	-- diretamente e a atribui a uma nova variável ("luaArgs").
	--]]
	local fargs, pargs, luaArgs
	if type(frame.args) == 'table' and type(frame.getParent) == 'function' then
		if options.wrappers then
			--[[
			-- A opção "wrappers" faz o Módulo:Arguments procurar argumentos na 
			-- tabela de argumentos do quadro ou na tabela de argumentos parental, mas
			-- mas não em ambas. Isso significa que os usuários podem usar a sintaxe
			-- "#invoke" ou uma predefinição "wrapper" sem a perda de desempenho 
			-- associada à procura de argumentos no quadro e no quadro parental.
			-- O Módulo:Arguments procurará argumentos no quadro parental
			-- se encontrar o título do quadro parental em "options.wrapper";
			-- caso não, ele procurará argumentos no objeto de quadro passado
			-- para "getArgs".
			--]]
			local parent = frame:getParent()
			if not parent then
				fargs = frame.args
			else
				local title = parent:getTitle():gsub('/Testes$', '')
				local found = false
				if matchesTitle(options.wrappers, title) then
					found = true
				elseif type(options.wrappers) == 'table' then
					for _,v in pairs(options.wrappers) do
						if matchesTitle(v, title) then
							found = true
							break
						end
					end
				end

				-- Nós testamos "false" especificamente aqui para que 
				-- "nil" (o padrão) aja como "true".
				if found or options.frameOnly == false then
					pargs = parent.args
				end
				if not found or options.parentOnly == false then
					fargs = frame.args
				end
			end
		else
			-- "options.wrapper" não está definido, portanto verifica as 
			-- outras opções.
			if not options.parentOnly then
				fargs = frame.args
			end
			if not options.frameOnly then
				local parent = frame:getParent()
				pargs = parent and parent.args or nil
			end
		end
		if options.parentFirst then
			fargs, pargs = pargs, fargs
		end
	else
		luaArgs = frame
	end

	-- Define a ordem de precedência das tabelas de argumentos. Se as variáveis 
	-- forem "nil", nada será adicionado à tabela, que é como evitamos confrontos
	-- entre os argumentos do quadro/parental e os argumentos Lua.
	local argTables = {fargs}
	argTables[#argTables + 1] = pargs
	argTables[#argTables + 1] = luaArgs

	--[[
	-- Gera a função "tidyVal". Se tiver sido especificado pelo usuário, nós
	-- usamos isso; caso não, escolhemos uma das quatro funções dependendo das
	-- opções escolhidas. Isso é para que não tenhamos que chamar a tabela de 
	-- opções toda vez que a função for chamada.
	--]]
	local tidyVal = options.valueFunc
	if tidyVal then
		if type(tidyVal) ~= 'function' then
			error(
				"valor inválido atribuído à opção 'valueFunc'"
					.. '(função esperada, obteve '
					.. type(tidyVal)
					.. ')',
				2
			)
		end
	elseif options.trim ~= false then
		if options.removeBlanks ~= false then
			tidyVal = tidyValDefault
		else
			tidyVal = tidyValTrimOnly
		end
	else
		if options.removeBlanks ~= false then
			tidyVal = tidyValRemoveBlanksOnly
		else
			tidyVal = tidyValNoChange
		end
	end

	--[[
	-- Define as tabelas "args", "metaArgs" e "nilArgs". "args" será a única
	-- acessada a partir de funções e "metaArgs" manterá os argumentos reais. 
	-- Os argumentos nulos são memorizados em "nilArgs" e a metatabela 
	-- conecta todos eles juntos.
	--]]
	local args, metaArgs, nilArgs, metatable = {}, {}, {}, {}
	setmetatable(args, metatable)

	local function mergeArgs(tables)
		--[[
		-- Aceita várias tabelas como entrada e mescla suas chaves e valores
		-- em uma tabela. Se um valor já estiver presente, ele não será substituído;
		-- as tabelas listadas anteriormente têm precedência. Também estamos memorizando 
		-- valores nulos, que podem ser sobrescritos se forem "s" ('soft').
		--]]
		for _, t in ipairs(tables) do
			for key, val in pairs(t) do
				if metaArgs[key] == nil and nilArgs[key] ~= 'h' then
					local tidiedVal = tidyVal(key, val)
					if tidiedVal == nil then
						nilArgs[key] = 's'
					else
						metaArgs[key] = tidiedVal
					end
				end
			end
		end
	end

	--[[
	-- Define o comportamento da metatabela. Os argumentos são memorizados na tabela "metaArgs",
	-- e são buscados apenas uma vez nas tabelas de argumentos. Obter os argumentos
	-- a partir das tabelas de argumentos é o passo mais intensiva em recursos neste
	-- módulo, então tentamos evitá-lo sempre que possível. Por este motivo, os argumentos nulos
	-- também são memorizados, na tabela "nilArgs". Além disso, mantemos um registro
	-- na metatabela de quando "pairs" e "ipairs" foram chamadas, então nós não 
	-- executamos "pairs" e "ipairs" nas tabelas de argumentos mais de uma vez. Nós também  
	-- não executamos "ipairs" em "fargs" e "pargs" se "pairs" já tiver sido executada, 
	-- pois todos os argumentos já terão sido copiados.
	--]]

	metatable.__index = function (t, key)
		--[[
		-- Busca um argumento quando a tabela "args" é indexada. Primeiro nós verificamos
		-- para ver se o valor está memorizado e, caso não, tentamos buscá-lo a partir 
		-- das tabelas de argumentos. Quando nós verificamos a memorização, nós precisamos verificar
		-- "metaArgs" antes de "nilArgs", pois ambas podem não ser nulas ('nil') ao mesmo tempo.
		-- Se o argumento não estiver presente em "metaArgs", nós também verificamos se
		-- "pairs" já foi executada. Se "pairs" já tiver sido executada, retornamos "nil" (nulo).
		-- Isso ocorre porque todos os argumentos já terão sido copiados para
		-- "metaArgs" pela função "mergeArgs", significando que quaisquer outros 
		-- argumentos devem ser "nil" (nulos).
		--]]
		if type(key) == 'string' then
			key = options.translate[key]
		end
		local val = metaArgs[key]
		if val ~= nil then
			return val
		elseif metatable.donePairs or nilArgs[key] then
			return nil
		end
		for _, argTable in ipairs(argTables) do
			local argTableVal = tidyVal(key, argTable[key])
			if argTableVal ~= nil then
				metaArgs[key] = argTableVal
				return argTableVal
			end
		end
		nilArgs[key] = 'h'
		return nil
	end

	metatable.__newindex = function (t, key, val)
		-- Esta função é chamada quando um módulo tenta adicionar um novo 
		-- valor à tabela "args" ou tenta alterar um valor existente.
		if type(key) == 'string' then
			key = options.translate[key]
		end
		if options.readOnly then
			error(
				'não foi possível gravar na chave da tabela de argumentos "'
					.. tostring(key)
					.. '"; a tabela é somente leitura',
				2
			)
		elseif options.noOverwrite and args[key] ~= nil then
			error(
				'não foi possível gravar na chave da tabela de argumentos "'
					.. tostring(key)
					.. '"; sobrescrever argumentos existentes não é permitido',
				2
			)
		elseif val == nil then
			--[[
			-- Se o argumento for substituído por "nil", nós precisamos apagar
			-- o valor em "metaArgs", para que "__index", "__pairs" e "__ipairs" 
			-- não usem um valor existente anterior, se presente; e nós também precisamos
			-- memorizar "nil" (nulo) em "nilArgs", para que o valor não seja procurado
			-- nas tabelas de argumentos se for acessado novamente.
			--]]
			metaArgs[key] = nil
			nilArgs[key] = 'h'
		else
			metaArgs[key] = val
		end
	end

	local function translatenext(invariant)
		local k, v = next(invariant.t, invariant.k)
		invariant.k = k
		if k == nil then
			return nil
		elseif type(k) ~= 'string' or not options.backtranslate then
			return k, v
		else
			local backtranslate = options.backtranslate[k]
			if backtranslate == nil then
				-- Ignora este. Esta é uma chamada final, então isso não causará 
				-- estouro de pilha
				return translatenext(invariant)
			else
				return backtranslate, v
			end
		end
	end

	metatable.__pairs = function ()
		-- Chamada quando "pairs" é executada na tabela "args".
		if not metatable.donePairs then
			mergeArgs(argTables)
			metatable.donePairs = true
		end
		return translatenext, { t = metaArgs }
	end

	local function inext(t, i)
		-- Isso usa nosso metamétodo "__index"
		local v = t[i + 1]
		if v ~= nil then
			return i + 1, v
		end
	end

	metatable.__ipairs = function (t)
		-- Chamada quando "ipairs" é executada na tabela "args".
		return inext, t, 0
	end

	return args
end

return arguments