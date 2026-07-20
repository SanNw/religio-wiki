-- Importado de https://pt.wikipedia.org/wiki/M%C3%B3dulo%3ACita%C3%A7%C3%A3o/CS1 (Wikipédia em português, CC BY-SA 4.0).
local cs1 ={}

--[[--------------------------< F O R W A R D   D E C L A R A T I O N S >--------------------------------------
  ATENÇÃO! As variáveis estão definidas como globais porque a função "setfenv" está desativada
  na Wikipédia, e Lua não tem modificadores protected (para herança de objetos)
]]

z ={} -- tables in Module:Citation/CS1/Utilities

cfg = {} -- table of configuration tables that are defined in Módulo:Citação/CS1/Configuração

whitelist = {} -- table of tables listing valid template parameter names; defined in Module:Citation/CS1/Whitelist

--[[
dates, year_date_check, reformat_dates, date_hyphen_to_dash -- functions in Module:Citation/CS1/Date_validation

is_set, in_array, substitute, error_comment, set_error, select_one, -- functions in Module:Citation/CS1/Utilities
    add_maint_cat, wrap_style, safe_for_italics, remove_wiki_link

extract_ids, extract_id_access_levels, build_id_list, is_embargoed -- functions in Module:Citation/CS1/Identifiers

make_coins_title, get_coins_pages, COinS -- functions in Module:Citation/CS1/COinS
]]

--[[--------------------------< P A G E   S C O P E   V A R I A B L E S >--------------------------------------

delare variables here that have page-wide scope that are not brought in from other modules; thatare created here
and used here

]]

added_prop_cats = {} -- list of property categories that have been added to z.properties_cats

--[[
added_deprecated_cat boolean flag so that the category is added only once

added_vanc_errs boolean flag so we only emit one Vancouver error / category

Frame -- holds the module's frame table
]]

--[[--------------------------< F I R S T _ S E T >------------------------------------------------------------
Localiza e retorna o primeiro atributo que possui argumento na tabela passada por
parâmetro, na ordem estabelecida na tabela. Da esquerda para direita é a ordem em
que os valores serão avaliados. Retorna nil se nenhum argumento existir.

O motivo de estar implementado um próprio iterador, bem como receber o tamanho por
parâmetro é porque se usar o 'ipairs' e houver algum valor nil no meio, o valor
nil é considerado o último elemento e para a iteração; se usar 'pairs' a ordem
numérica não é garantida. O tamanho é passado por parâmetro porque o operador '#'
retorna a quantidade de atributo de índice numérico de 1 a 'nil', deparando no
mesmo problema de se usar o 'ipairs'.

@param list a tabela que contém a lista
@param count a quantidade de elementos a ser iterado a partir de 1
]]
function first_set (list, count)
    local i = 1;
    while i <= count do -- loop through all items in list
        if is_set( list[i] ) then
            return list[i];                                                        -- return the first set list member
        end
        i = i + 1;                                                                -- point to next
    end
end

--[[--------------------------< A D D _ P R O P _ C A T >--------------------------------------
Adds a category to z.properties_cats using names from the configuration file with additional text if any.

added_prop_cats is a table declared in page scope variables above
]]
function add_prop_cat (key, arguments)
    if not added_prop_cats [key] then
        added_prop_cats [key] = true;                                            -- note that we've added this category
        table.insert( z.properties_cats, substitute (cfg.prop_cats [key], arguments));        -- make name then add to table
    end
end

--[[--------------------------< A D D _ V A N C _ E R R O R >----------------------------------
Adds a single Vancouver system error message to the template's output regardless of how many error actually exist.
To prevent duplication, added_vanc_errs is nil until an error message is emitted.

added_vanc_errs is a boolean declared in page scope variables above
]]
function add_vanc_error (source)
    if not added_vanc_errs then
        added_vanc_errs = true;                                                    -- note that we've added this category
        table.insert( z.message_tail, { set_error( 'vancouver', {source}, true ) } );
    end
end


--[[--------------------------< I S _ S C H E M E >--------------------------------------------
does this thing that purports to be a uri scheme seem to be a valid scheme?  The scheme is checked to see if it
is in agreement with http://tools.ietf.org/html/std66#section-3.1 which says:
    Scheme names consist of a sequence of characters beginning with a
   letter and followed by any combination of letters, digits, plus
   ("+"), period ("."), or hyphen ("-").

returns true if it does, else false
]]
function is_scheme (scheme)
    return scheme and scheme:match ('^%a[%a%d%+%.%-]*:');                        -- true if scheme is set and matches the pattern
end


--[=[-------------------------< I S _ D O M A I N _ N A M E >-----------------------------------
Does this thing that purports to be a domain name seem to be a valid domain name?

Syntax defined here: http://tools.ietf.org/html/rfc1034#section-3.5
BNF defined here: https://tools.ietf.org/html/rfc4234
Single character names are generally reserved; see https://tools.ietf.org/html/draft-ietf-dnsind-iana-dns-01#page-15;
    see also [[Single-letter second-level domain]]
list of tlds: https://www.iana.org/domains/root/db

rfc952 (modified by rfc 1123) requires the first and last character of a hostname to be a letter or a digit.  Between
the first and last characters the name may use letters, digits, and the hyphen.

Also allowed are IPv4 addresses. IPv6 not supported

domain is expected to be stripped of any path so that the last character in the last character of the tld.  tld
is two or more alpha characters.  Any preceding '//' (from splitting a url with a scheme) will be stripped
here.  Perhaps not necessary but retained incase it is necessary for IPv4 dot decimal.

There are several tests:
    the first character of the whole domain name including subdomains must be a letter or a digit
    internationalized domain name (ascii characters with .xn-- ASCII Compatible Encoding (ACE) prefix xn-- in the tld) see https://tools.ietf.org/html/rfc3490
    single-letter/digit second-level domains in the .org TLD
    q, x, and z SL domains in the .com TLD
    i and q SL domains in the .net TLD
    single-letter SL domains in the ccTLDs (where the ccTLD is two letters)
    two-character SL domains in gTLDs (where the gTLD is two or more letters)
    three-plus-character SL domains in gTLDs (where the gTLD is two or more letters)
    IPv4 dot-decimal address format; TLD not allowed

returns true if domain appears to be a proper name and tld or IPv4 address, else false
]=]
function is_domain_name (domain)
	if not domain then
		return false;															-- if not set, abandon
	end
	
	domain = domain:gsub ('^//', '');											-- strip '//' from domain name if present; done here so we only have to do it once
	
	if not domain:match ('^[%w]') then											-- first character must be letter or digit
		return false;
	end

	if domain:match ('^%a+:') then												-- hack to detect things that look like s:Page:Title where Page: is namespace at Wikisource
		return false;
	end

	local patterns = {															-- patterns that look like URLs
		'%f[%w][%w][%w%-]+[%w]%.%a%a+$',										-- three or more character hostname.hostname or hostname.tld
		'%f[%w][%w][%w%-]+[%w]%.xn%-%-[%w]+$',									-- internationalized domain name with ACE prefix
		'%f[%a][qxz]%.com$',													-- assigned one character .com hostname (x.com times out 2015-12-10)
		'%f[%a][iq]%.net$',														-- assigned one character .net hostname (q.net registered but not active 2015-12-10)
		'%f[%w][%w]%.%a%a$',													-- one character hostname and ccTLD (2 chars)
		'%f[%w][%w][%w]%.%a%a+$',												-- two character hostname and TLD
		'^%d%d?%d?%.%d%d?%d?%.%d%d?%d?%.%d%d?%d?',								-- IPv4 address
		'[%a%d]+%:?'                                                            -- IPv6 address
		}

	for _, pattern in ipairs (patterns) do										-- loop through the patterns list
		if domain:match (pattern) then
			return true;														-- if a match then we think that this thing that purports to be a URL is a URL
		end
	end

	for _, d in ipairs (cfg.single_letter_2nd_lvl_domains_t) do					-- look for single letter second level domain names for these top level domains
		if domain:match ('%f[%w][%w]%.' .. d) then
			return true
		end
	end
	return false;																-- no matches, we don't know what this thing is
end


--[[--------------------------< I S _ U R L >----------------------------------------------------
returns true if the scheme and domain parts of a url appear to be a valid url; else false.

This function is the last step in the validation process.  This function is separate because there are cases that
are not covered by split_url(), for example is_parameter_ext_wikilink() which is looking for bracketted external
wikilinks.
]]
function is_url (scheme, domain)
    if is_set (scheme) then                                                        -- if scheme is set check it and domain
        return is_scheme (scheme) and is_domain_name (domain);
    else
        return is_domain_name (domain);                                            -- scheme not set when url is protocol relative
    end
end


--[[--------------------------< S P L I T _ U R L >-----------------------------------------------
Split a url into a scheme, authority indicator, and domain.

First remove Fully Qualified Domain Name terminator (a dot following tld) (if any) and any path(/), query(?) or fragment(#).

If protocol relative url, return nil scheme and domain else return nil for both scheme and domain.

When not protocol relative, get scheme, authority indicator, and domain.  If there is an authority indicator (one
or more '/' characters immediately following the scheme's colon), make sure that there are only 2.

Strip off any port and path;
]]
function split_url (url_str)
	local scheme, authority, domain;
	
	url_str = url_str:gsub ('([%a%d])%.?[/%?#].*$', '%1');						-- strip FQDN terminator and path(/), query(?), fragment (#) (the capture prevents false replacement of '//')

	if url_str:match ('^//%S*') then											-- if there is what appears to be a protocol-relative URL
		domain = url_str:match ('^//(%S*)')
	elseif url_str:match ('%S-:/*%S+') then										-- if there is what appears to be a scheme, optional authority indicator, and domain name
		scheme, authority, domain = url_str:match ('(%S-:)(/*)(%S+)');			-- extract the scheme, authority indicator, and domain portions
		if is_set (authority) then
			authority = authority:gsub ('//', '', 1);							-- replace place 1 pair of '/' with nothing;
			if is_set(authority) then									-- if anything left (1 or 3+ '/' where authority should be) then
				return scheme;													-- return scheme only making domain nil which will cause an error message
			end
		else
			if not scheme:match ('^news:') then									-- except for news:..., MediaWiki won't link URLs that do not have authority indicator; TODO: a better way to do this test?
				return scheme;													-- return scheme only making domain nil which will cause an error message
			end
		end
		domain = domain:gsub ('(%a):%d+', '%1');								-- strip port number if present
	end
	
	return scheme, domain;
end


--[[--------------------------< L I N K _ P A R A M _ O K >--------------------------------------
checks the content of |title-link=, |series-link=, |author-link= etc for properly formatted content: no wikilinks, no urls

Link parameters are to hold the title of a wikipedia article so none of the WP:TITLESPECIALCHARACTERS are allowed:
    # < > [ ] | { } _
except the underscore which is used as a space in wiki urls and # which is used for section links

returns false when the value contains any of these characters.

When there are no illegal characters, this function returns TRUE if value DOES NOT appear to be a valid url (the
|<param>-link= parameter is ok); else false when value appears to be a valid url (the |<param>-link= parameter is NOT ok).
]]
function link_param_ok (value)
    local scheme, domain;
    if value:find ('[<>%[%]|{}]') then                                            -- if any prohibited characters
        return false;
    end

    scheme, domain = split_url (value);                                            -- get scheme or nil and domain or nil from url;
    return not is_url (scheme, domain);                                            -- return true if value DOES NOT appear to be a valid url
end

--[[--------------------------< L I N K _ T I T L E _ O K >------------------------------------
Use link_param_ok() to validate |<param>-link= value and its matching |<title>= value.

|<title>= may be wikilinked but not when |<param>-link= has a value.  This function emits an error message when
that condition exists
]]
function link_title_ok (link, lorig, title, torig)
local orig;

    if is_set (link) then                                                         -- don't bother if <param>-link doesn't have a value
        if not link_param_ok (link) then                                        -- check |<param>-link= markup
            orig = lorig;                                                        -- identify the failing link parameter
        elseif title:find ('%[%[') then                                            -- check |title= for wikilink markup
            orig = torig;                                                        -- identify the failing |title= parameter
        end
    end

    if is_set (orig) then
        table.insert( z.message_tail, { set_error( 'bad_paramlink', orig)});    -- url or wikilink in |title= with |title-link=;
    end
end


--[[--------------------------< C H E C K _ U R L >--------------------------------------------
Determines whether a URL string appears to be valid.

First we test for space characters.  If any are found, return false.  Then split the url into scheme and domain
portions, or for protocol relative (//example.com) urls, just the domain.  Use is_url() to validate the two
portions of the url.  If both are valid, or for protocol relative if domain is valid, return true, else false.

Because it is different from a standard url, and because this module used external_link() to make external links
that work for standard and news: links, we validate newsgroup names here.  The specification for a newsgroup name
is at https://tools.ietf.org/html/rfc5536#section-3.1.4
]]
function check_url( url_str )
    if nil == url_str:match ("^%S+$") then                                        -- if there are any spaces in |url=value it can't be a proper url
        return false;
    end
    local scheme, domain;

    scheme, domain = split_url (url_str);                                        -- get scheme or nil and domain or nil from url;

    if 'news:' == scheme then                                                    -- special case for newsgroups
        return domain:match('^[%a%d%+%-_]+%.[%a%d%+%-_%.]*[%a%d%+%-_]$');
    end

    return is_url (scheme, domain);                                                -- return true if value appears to be a valid url
end


--[=[----------------------< I S _ P A R A M E T E R _ E X T _ W I K I L I N K >------------------
Return true if a parameter value has a string that begins and ends with square brackets [ and ] and the first
non-space characters following the opening bracket appear to be a url.  The test will also find external wikilinks
that use protocol relative urls. Also finds bare urls.

The frontier pattern prevents a match on interwiki links which are similar to scheme:path urls.  The tests that
find bracketed urls are required because the parameters that call this test (currently |title=, |chapter=, |work=,
and |publisher=) may have wikilinks and there are articles or redirects like '//Hus' so, while uncommon, |title=[[//Hus]]
is possible as might be [[en://Hus]].
]=]
function is_parameter_ext_wikilink (value)
local scheme, domain;

    if value:match ('%f[%[]%[%a%S*:%S+.*%]') then                                -- if ext wikilink with scheme and domain: [xxxx://yyyyy.zzz]
        scheme, domain = split_url (value:match ('%f[%[]%[(%a%S*:%S+).*%]'));
    elseif value:match ('%f[%[]%[//%S+.*%]') then                                -- if protocol relative ext wikilink: [//yyyyy.zzz]
        scheme, domain = split_url (value:match ('%f[%[]%[(//%S+).*%]'));
    elseif value:match ('%a%S*:%S+') then                                        -- if bare url with scheme; may have leading or trailing plain text
        scheme, domain = split_url (value:match ('(%a%S*:%S+)'));
    elseif value:match ('//%S+') then                                            -- if protocol relative bare url: //yyyyy.zzz; may have leading or trailing plain text
        scheme, domain = split_url (value:match ('(//%S+)'));                    -- what is left should be the domain
    else
        return false;                                                            -- didn't find anything that is obviously a url
    end

    return is_url (scheme, domain);                                                -- return true if value appears to be a valid url
end


--[[-------------------------< C H E C K _ F O R _ U R L >---------------------------------------
loop through a list of parameters and their values.  Look at the value and if it has an external link, emit an error message.
]]
function check_for_url (parameter_list)
local error_message = '';
    for k, v in pairs (parameter_list) do                                        -- for each parameter in the list
        if is_parameter_ext_wikilink (v) then                                    -- look at the value; if there is a url add an error message
            if is_set(error_message) then                                        -- once we've added the first portion of the error message ...
                error_message=error_message .. ", ";                            -- ... add a comma space separator
            end
            error_message=error_message .. "&#124;" .. k .. "=";                -- add the failed parameter
        end
    end
    if is_set (error_message) then                                                -- done looping, if there is an error message, display it
        table.insert( z.message_tail, { set_error( 'param_has_ext_link', {error_message}, true ) } );
    end
end


--[[--------------------------< S A F E _ F O R _ U R L >-----------------------------------------
Escape sequences for content that will be used for URL descriptions
]]
function safe_for_url( str )
    if str:match( "%[%[.-%]%]" ) ~= nil then
        return false
    end

    -- não ser wikilink não significa que não tenha colchetes
    return str:gsub( '[%[%]\n]', {
        ['['] = '&#91;',
        [']'] = '&#93;',
        ['\n'] = ' ' } )
end

--[[--------------------------< E X T E R N A L _ L I N K >--------------------------------------
Format an external link with error checking
]]
function external_link( URL, label, source, access)
    local error_str = "";
    local domain;
    local path;
    local base_url;

    if not is_set( label ) then
        label = URL;
        if is_set( source ) then
            error_str = set_error( 'bare_url_missing_title', { wrap_style ('parameter', source) }, false, " " );
        else
            error( cfg.messages["bare_url_no_origin"] );
        end
    end
    if not check_url( URL ) then
        error_str = set_error( 'bad_url', {wrap_style ('parameter', source)}, false, " " ) .. error_str;
    end

    domain, path = URL:match ('^([/%.%-%+:%a%d]+)([/%?#].*)$');                    -- split the url into scheme plus domain and path
    if path then                                                                -- if there is a path portion
        path = path:gsub ('[%[%]]', {['[']='%5b',[']']='%5d'});                    -- replace '[' and ']' with their percent encoded values
        URL=domain..path;                                                        -- and reassemble
    end

    local safe_label = safe_for_url( label )
    if safe_label then
        base_url = table.concat({ "[", URL, " ", safe_label, "]" })
    else
        base_url = table.concat({ label, "&nbsp;[", URL, " ", "🔗]" })
    end

    if is_set(access) then -- access level (free, paywalled, ...)
        base_url = substitute(cfg.presentation[access], base_url);
    end

    return table.concat({ base_url, error_str });
end


--[[-----------------------< D E P R E C A T E D _ P A R A M E T E R >--------------------------
Categorize and emit an error message when the citation contains one or more deprecated parameters.  The function includes the
offending parameter name to the error message.  Only one error message is emitted regardless of the number of deprecated
parameters in the citation.

added_deprecated_cat is a boolean declared in page scope variables above
]]
function deprecated_parameter(name)
    if not added_deprecated_cat then
        added_deprecated_cat = true;                                            -- note that we've added this category
        table.insert( z.message_tail, { set_error( 'deprecated_params', {name}, true ) } );        -- add error message
    end
end

--[[--------------------------< K E R N _ Q U O T E S >------------------------------------------
Apply kerning to open the space between the quote mark provided by the Module and a leading or trailing quote mark contained in a |title= or |chapter= parameter's value.
This function will positive kern either single or double quotes:
    "'Unkerned title with leading and trailing single quote marks'"
    " 'Kerned title with leading and trailing single quote marks' " (in real life the kerning isn't as wide as this example)
Double single quotes (italic or bold wikimarkup) are not kerned.

Replaces unicode quotemarks with typewriter quote marks regardless of the need for kerning.

Call this function for chapter titles, for website titles, etc; not for book titles.
]]
function kern_quotes (str)
    local cap='';
    local cap2='';
                                                                                -- TODO: move this elswhere so that all title-holding elements get these quote marks replaced?
    str= mw.ustring.gsub (str, '[“”]', '\"');                                    -- replace “” (U+201C & U+201D) with " (typewriter double quote mark)
    str= mw.ustring.gsub (str, '[‘’]', '\'');                                    -- replace ‘’ (U+2018 & U+2019) with ' (typewriter single quote mark)

    cap, cap2 = str:match ("^([\"\'])([^\'].+)");                                -- match leading double or single quote but not double single quotes
    if is_set (cap) then
        str = substitute (cfg.presentation['kern-left'], {cap, cap2});
    end

    cap, cap2 = str:match ("^(.+[^\'])([\"\'])$")
    if is_set (cap) then
        str = substitute (cfg.presentation['kern-right'], {cap, cap2});
    end
    return str;
end

--[[--------------------------< F O R M A T _ S C R I P T _ V A L U E >---------------------------
|script-title= holds title parameters that are not written in Latin based scripts: Chinese, Japanese, Arabic, Hebrew, etc. These scripts should
not be italicized and may be written right-to-left.  The value supplied by |script-title= is concatenated onto Title after Title has been wrapped
in italic markup.

Regardless of language, all values provided by |script-title= are wrapped in <bdi>...</bdi> tags to isolate rtl languages from the English left to right.

|script-title= provides a unique feature.  The value in |script-title= may be prefixed with a two-character ISO639-1 language code and a colon:
    |script-title=ja:*** *** (where * represents a Japanese character)
Spaces between the two-character code and the colon and the colon and the first script character are allowed:
    |script-title=ja : *** ***
    |script-title=ja: *** ***
    |script-title=ja :*** ***
Spaces preceding the prefix are allowed: |script-title = ja:*** ***

The prefix is checked for validity.  If it is a valid ISO639-1 language code, the lang attribute (lang="ja") is added to the <bdi> tag so that browsers can
know the language the tag contains.  This may help the browser render the script more correctly.  If the prefix is invalid, the lang attribute
is not added.  At this time there is no error message for this condition.

Supports |script-title= and |script-chapter=

TODO: error messages when prefix is invalid ISO639-1 code; when script_value has prefix but no script;
]]
function format_script_value (script_value)
    local lang='';                                                                -- initialize to empty string
    local name;
    if script_value:match('^%l%l%s*:') then                                        -- if first 3 non-space characters are script language prefix
        lang = script_value:match('^(%l%l)%s*:%s*%S.*');                        -- get the language prefix or nil if there is no script
        if not is_set (lang) then
            return '';                                                            -- script_value was just the prefix so return empty string
        end
                                                                                -- if we get this far we have prefix and script
        name = mw.language.fetchLanguageName( lang, "pt" );                        -- get language name so that we can use it to categorize
        if is_set (name) then                                                    -- is prefix a proper ISO 639-1 language code?
            script_value = script_value:gsub ('^%l%l%s*:%s*', '');                -- strip prefix from script
                                                                                -- is prefix one of these language codes?
            if in_array (lang, cfg.script_lang_codes) then
                add_prop_cat ('script_with_name', {name, lang})
            else
                add_prop_cat ('script')
            end
            lang = ' lang="' .. lang .. '" ';                                    -- convert prefix into a lang attribute
        else
            lang = '';                                                            -- invalid so set lang to empty string
        end
    end
    script_value = substitute (cfg.presentation['bdi'], {lang, script_value});    -- isolate in case script is rtl

    return script_value;
end

--[[--------------------------< S C R I P T _ C O N C A T E N A T E >-----------------------------
Initially for |title= and |script-title=, this function concatenates those two parameter values after the script value has been
wrapped in <bdi> tags.
]]
function script_concatenate (title, script)
    if is_set (script) then
        script = format_script_value (script);                                    -- <bdi> tags, lang atribute, categorization, etc; returns empty string on error
        if is_set (script) then
            title = title .. ' ' .. script;                                        -- concatenate title and script title
        end
    end
    return title;
end


--[[--------------------------< W R A P _ M S G >-------------------------------------------------
Applies additional message text to various parameter values. Supplied string is wrapped using a message_list
configuration taking one argument.  Supports lower case text for {{citation}} templates.  Additional text taken
from citation_config.messages - the reason this function is similar to but separate from wrap_style().
]]
function wrap_msg (key, str, lower)
    if not is_set( str ) then
        return "";
    end
    if true == lower then
        local msg;
        msg = cfg.messages[key]:lower();                                        -- set the message to lower case before
        return substitute( msg, str );                                        -- including template text
    else
        return substitute( cfg.messages[key], str );
    end
end


--[[--------------------------< F O R M A T _ C H A P T E R _ T I T L E >-----------------------
Format the four chapter parameters: |script-chapter=, |chapter=, |trans-chapter=, and |chapter-url= into a single Chapter meta-
parameter (chapter_url_source used for error messages).
]]
function format_chapter_title (scriptchapter, chapter, transchapter, chapterurl, chapter_url_source, no_quotes)
    local chapter_error = '';

    if not is_set (chapter) then
        chapter = '';                                                            -- to be safe for concatenation
    else
        if false == no_quotes then
            chapter = kern_quotes (chapter);                                        -- if necessary, separate chapter title's leading and trailing quote marks from Module provided quote marks
            chapter = wrap_style ('quoted-title', chapter);
        end
    end

    chapter = script_concatenate (chapter, scriptchapter)                        -- <bdi> tags, lang atribute, categorization, etc; must be done after title is wrapped

    if is_set (transchapter) then
        transchapter = wrap_style ('trans-quoted-title', transchapter);
        if is_set (chapter) then
            chapter = chapter ..  ' ' .. transchapter;
        else                                                                    -- here when transchapter without chapter or script-chapter
            chapter = transchapter;                                                --
            chapter_error = ' ' .. set_error ('trans_missing_title', {'capítulo'});
        end
    end

    if is_set (chapterurl) then
        chapter = external_link (chapterurl, chapter, chapter_url_source, nil);        -- adds bare_url_missing_title error if appropriate
    end

    return chapter .. chapter_error;
end

--[[--------------------------< H A S _ I N V I S I B L E _ C H A R S >-----------------------------
This function searches a parameter's value for nonprintable or invisible characters.  The search stops at the
first match.

This function will detect the visible replacement character when it is part of the wikisource.

Detects but ignores nowiki and math stripmarkers.  Also detects other named stripmarkers (gallery, math, pre, ref)
and identifies them with a slightly different error message.  See also coins_cleanup().

Detects but ignores the character pattern that results from the transclusion of {{'}} templates.

Output of this function is an error message that identifies the character or the Unicode group, or the stripmarker
that was detected along with its position (or, for multi-byte characters, the position of its first byte) in the
parameter value.
]]
function has_invisible_chars (param, v)
    local position = '';                                                        -- position of invisible char or starting position of stripmarker
    local dummy;                                                                -- end of matching string; not used but required to hold end position when a capture is returned
    local capture;                                                                -- used by stripmarker detection to hold name of the stripmarker
    local i=1;
    local stripmarker, apostrophe;

    capture = string.match (v, '[%w%p ]*');                                        -- Test for values that are simple ASCII text and bypass other tests if true
    if capture == v then                                                        -- if same there are no unicode characters
        return;
    end

    while cfg.invisible_chars[i] do
        local char=cfg.invisible_chars[i][1]                                    -- the character or group name
        local pattern=cfg.invisible_chars[i][2]                                    -- the pattern used to find it
        position, dummy, capture = mw.ustring.find (v, pattern)                    -- see if the parameter value contains characters that match the pattern

        if position then
            if 'nowiki' == capture or 'math' == capture then                     -- nowiki, math stripmarker (not an error condition)
                stripmarker = true;                                                -- set a flag
            elseif true == stripmarker and 'delete' == char then                -- because stripmakers begin and end with the delete char, assume that we've found one end of a stripmarker
                position = nil;                                                    -- unset
            else
                local err_msg;
                if capture then
                    err_msg = capture .. ' ' .. char;
                else
                    err_msg = char .. ' ' .. 'character';
                end

                table.insert( z.message_tail, { set_error( 'invisible_char', {err_msg, wrap_style ('parameter', param), position}, true ) } );    -- add error message
                return;                                                            -- and done with this parameter
            end
        end
        i=i+1;                                                                    -- bump our index
    end
end


--[[-------------------------< A R G U M E N T _ W R A P P E R >-----------------------------------
Argument wrapper.  This function provides support for argument mapping defined in the configuration file so that
multiple names can be transparently aliased to single internal variable.
]]
function argument_wrapper( args )
    local origin = {};

    return setmetatable({
        ORIGIN = function( self, k )
            local dummy = self[k]; --force the variable to be loaded.
            return origin[k];
        end
    },
    {
        __index = function ( tbl, k )
            if origin[k] ~= nil then
                return nil;
            end

            local args, list, v = args, cfg.aliases[k];

            if type( list ) == 'table' then
                v, origin[k] = select_one( args, list, 'redundant_parameters' );
                if origin[k] == nil then
                    origin[k] = ''; -- Empty string, not nil
                end
            elseif list ~= nil then
                v, origin[k] = args[list], list;
            else
                -- maybe let through instead of raising an error?
                -- v, origin[k] = args[k], k;
                error( cfg.messages['unknown_argument_map'] );
            end

            -- Empty strings, not nil;
            if v == nil then
                v = cfg.defaults[k] or '';
                origin[k] = '';
            end

            tbl = rawset( tbl, k, v );
            return v;
        end,
    });
end

--[[--------------------------< V A L I D A T E >-------------------------------------------------
Looks for a parameter's name in the whitelist.

Parameters in the whitelist can have three values:
    true - active, supported parameters
    false - deprecated, supported parameters
    nil - unsupported parameters
]]
function validate( name )
    local name = tostring( name );
    local state = whitelist.basic_arguments[ name ];

    -- Normal arguments
    if true == state then return true; end        -- valid actively supported parameter
    if false == state then
        deprecated_parameter (name);                -- parameter is deprecated but still supported
        return true;
    end

    -- Arguments with numbers in them
    name = name:gsub( "%d+", "#" );                -- replace digit(s) with # (last25 becomes last#
    state = whitelist.numbered_arguments[ name ];
    if true == state then return true; end        -- valid actively supported parameter
    if false == state then
        deprecated_parameter (name);                -- parameter is deprecated but still supported
        return true;
    end

    return false;                                -- Not supported because not found or name is set to nil
end


--[[--------------------------< N O W R A P _ D A T E >------------------------------------------
When date is YYYY-MM-DD format wrap in nowrap span: <span ...>YYYY-MM-DD</span>.  When date is DD MMMM YYYY or is
MMMM DD, YYYY then wrap in nowrap span: <span ...>DD MMMM</span> YYYY or <span ...>MMMM DD,</span> YYYY

DOES NOT yet support MMMM YYYY or any of the date ranges.
]]
function nowrap_date (date)
    local cap='';
    local cap2='';

    if date:match("^%d%d%d%d%-%d%d%-%d%d$") then
        date = substitute (cfg.presentation['nowrap1'], date);

    elseif date:match("^%a+%s*%d%d?,%s+%d%d%d%d$") or date:match ("^%d%d?%s*%a+%s+%d%d%d%d$") then
        cap, cap2 = string.match (date, "^(.*)%s+(%d%d%d%d)$");
        date = substitute (cfg.presentation['nowrap2'], {cap, cap2});
    end

    return date;
end

--[[--------------------------< S E T _ T I T L E T Y P E >----------------------------------------
This function sets default title types (equivalent to the citation including |type=<default value>) for those templates that have defaults.
Also handles the special case where it is desirable to omit the title type from the rendered citation (|type=none).
]]
function set_titletype (cite_class, title_type)
    if is_set(title_type) then
        if "none" == title_type then
            title_type = "";                                                    -- if |type=none then type parameter not displayed
        end
        return title_type;                                                        -- if |type= has been set to any other value use that value
    end

    return cfg.title_types [cite_class] or '';                                    -- set template's default title type; else empty string for concatenation
end


--[[--------------------------< H Y P H E N _ T O _ D A S H >---------------------------------
Converts a hyphen to a dash
]]
function hyphen_to_dash( str )
    if not is_set(str) or str:match( "[%[%]{}<>]" ) ~= nil then
        return str;
    end
    return str:gsub( '-', '–' );
end


--[[--------------------------< S A F E _ J O I N >------------------------------------------------------------
Joins a sequence of strings together while checking for duplicate separation characters.
]]
function safe_join( tbl, duplicate_char )
    --[[
    Note: we use string functions here, rather than ustring functions.

    This has considerably faster performance and should work correctly as
    long as the duplicate_char is strict ASCII.  The strings
    in tbl may be ASCII or UTF8.
    ]]

    local str = '';                                                                -- the output string
    local comp = '';                                                            -- what does 'comp' mean?
    local end_chr = '';
    local trim;
    for _, value in ipairs( tbl ) do
        if value == nil then value = ''; end

        if str == '' then -- se a string de retorno ainda estiver vazia
            str = value -- assinala (primeiro) valor
        elseif value ~= '' then
            if value:sub(1,1) == '<' then                                        -- Special case of values enclosed in spans and other markup.
                comp = value:gsub( "%b<>", "" );                                -- remove html markup (<span>string</span> -> string)
            else
                comp = value;
            end
                                                                                -- typically duplicate_char is sepc
            if comp:sub(1,1) == duplicate_char then                                -- is first charactier same as duplicate_char? why test first character?
                                                                                --   Because individual string segments often (always?) begin with terminal punct for th
                                                                                --   preceding segment: 'First element' .. 'sepc next element' .. etc?
                trim = false;
                end_chr = str:sub(-1,-1);                                        -- get the last character of the output string
                -- str = str .. "<HERE(enchr=" .. end_chr.. ")"                    -- debug stuff?
                if end_chr == duplicate_char then                                -- if same as separator
                    str = str:sub(1,-2);                                        -- remove it
                elseif end_chr == "'" then                                        -- if it might be wikimarkup
                    if str:sub(-3,-1) == duplicate_char .. "''" then            -- if last three chars of str are sepc''
                        str = str:sub(1, -4) .. "''";                            -- remove them and add back ''
                    elseif str:sub(-5,-1) == duplicate_char .. "]]''" then        -- if last five chars of str are sepc]]''
                        trim = true;                                            -- why? why do this and next differently from previous?
                    elseif str:sub(-4,-1) == duplicate_char .. "]''" then        -- if last four chars of str are sepc]''
                        trim = true;                                            -- same question
                    end
                elseif end_chr == "]" then                                        -- if it might be wikimarkup
                    if str:sub(-3,-1) == duplicate_char .. "]]" then            -- if last three chars of str are sepc]] wikilink
                        trim = true;
                    elseif str:sub(-2,-1) == duplicate_char .. "]" then            -- if last two chars of str are sepc] external link
                        trim = true;
                    elseif str:sub(-4,-1) == duplicate_char .. "'']" then        -- normal case when |url=something & |title=Title.
                        trim = true;
                    end
                elseif end_chr == " " then                                        -- if last char of output string is a space
                    if str:sub(-2,-1) == duplicate_char .. " " then                -- if last two chars of str are <sepc><space>
                        str = str:sub(1,-3);                                    -- remove them both
                    end
                end

                if trim then
                    if value ~= comp then                                         -- value does not equal comp when value contains html markup
                        local dup2 = duplicate_char;
                        if dup2:match( "%A" ) then dup2 = "%" .. dup2; end        -- if duplicate_char not a letter then escape it

                        value = value:gsub( "(%b<>)" .. dup2, "%1", 1 )            -- remove duplicate_char if it follows html markup
                    else
                        value = value:sub( 2, -1 );                                -- remove duplicate_char when it is first character
                    end
                end
            end
            str = str .. value;                                                    --add it to the output string
        end
    end
    return str;
end


--[[--------------------------< I S _ S U F F I X >---------------------------------------------
returns true is suffix is properly formed Jr, Sr, or ordinal in the range 2–9.  Puncutation not allowed.
]]
function is_suffix (suffix)
    if in_array (suffix, {'Jr', 'Sr', '2nd', '3rd'}) or suffix:match ('^%dth$') then
        return true;
    end
    return false;
end

--[[--------------------------< I S _ G O O D _ V A N C _ N A M E >------------------------------
For Vancouver Style, author/editor names are supposed to be rendered in Latin (read ASCII) characters.  When a name
uses characters that contain diacritical marks, those characters are to converted to the corresponding Latin character.
When a name is written using a non-Latin alphabet or logogram, that name is to be transliterated into Latin characters.
These things are not currently possible in this module so are left to the editor to do.

This test allows |first= and |last= names to contain any of the letters defined in the four Unicode Latin character sets
    [http://www.unicode.org/charts/PDF/U0000.pdf C0 Controls and Basic Latin] 0041–005A, 0061–007A
    [http://www.unicode.org/charts/PDF/U0080.pdf C1 Controls and Latin-1 Supplement] 00C0–00D6, 00D8–00F6, 00F8–00FF
    [http://www.unicode.org/charts/PDF/U0100.pdf Latin Extended-A] 0100–017F
    [http://www.unicode.org/charts/PDF/U0180.pdf Latin Extended-B] 0180–01BF, 01C4–024F

|lastn= also allowed to contain hyphens, spaces, and apostrophes. (http://www.ncbi.nlm.nih.gov/books/NBK7271/box/A35029/)
|firstn= also allowed to contain hyphens, spaces, apostrophes, and periods

This original test:
    if nil == mw.ustring.find (last, "^[A-Za-zÀ-ÖØ-öø-ƿǄ-ɏ%-%s%']*$") or nil == mw.ustring.find (first, "^[A-Za-zÀ-ÖØ-öø-ƿǄ-ɏ%-%s%'%.]+[2-6%a]*$") then
was written ouside of the code editor and pasted here because the code editor gets confused between character insertion point and cursor position.
The test has been rewritten to use decimal character escape sequence for the individual bytes of the unicode characters so that it is not necessary
to use an external editor to maintain this code.

    \195\128-\195\150 – À-Ö (U+00C0–U+00D6 – C0 controls)
    \195\152-\195\182 – Ø-ö (U+00D8-U+00F6 – C0 controls)
    \195\184-\198\191 – ø-ƿ (U+00F8-U+01BF – C0 controls, Latin extended A & B)
    \199\132-\201\143 – Ǆ-ɏ (U+01C4-U+024F – Latin extended B)
]]
function is_good_vanc_name (last, first)
    local first, suffix = first:match ('(.-),?%s*([%dJS][%drndth]+)%.?$') or first;        -- if first has something that looks like a generational suffix, get it

    if is_set (suffix) then
        if not is_suffix (suffix) then
            add_vanc_error ('suffix');
            return false;                                                        -- not a name with an appropriate suffix
        end
    end
    if nil == mw.ustring.find (last, "^[A-Za-z\195\128-\195\150\195\152-\195\182\195\184-\198\191\199\132-\201\143%-%s%']*$") or
        nil == mw.ustring.find (first, "^[A-Za-z\195\128-\195\150\195\152-\195\182\195\184-\198\191\199\132-\201\143%-%s%'%.]*$") then
            add_vanc_error ('non-Latin character');
            return false;                                                        -- not a string of latin characters; Vancouver requires Romanization
    end;
    return true;
end

--[[--------------------------< R E D U C E _ T O _ I N I T I A L S >------------------------------------------
Attempts to convert names to initials in support of |name-list-format=vanc.

Names in |firstn= may be separated by spaces or hyphens, or for initials, a period. See http://www.ncbi.nlm.nih.gov/books/NBK7271/box/A35062/.

Vancouver style requires family rank designations (Jr, II, III, etc) to be rendered as Jr, 2nd, 3rd, etc.  See http://www.ncbi.nlm.nih.gov/books/NBK7271/box/A35085/.
This code only accepts and understands generational suffix in the Vancouver format because Roman numerals look like, and can be mistaken for, initials.

This function uses ustring functions because firstname initials may be any of the unicode Latin characters accepted by is_good_vanc_name ().
]]
function reduce_to_initials(first)
    local name, suffix = mw.ustring.match(first, "^(%u+) ([%dJS][%drndth]+)$");

    if not name then                                                            -- if not initials and a suffix
        name = mw.ustring.match(first, "^(%u+)$");                                -- is it just intials?
    end

    if name then                                                                -- if first is initials with or without suffix
        if 3 > name:len() then                                                    -- if one or two initials
            if suffix then                                                        -- if there is a suffix
                if is_suffix (suffix) then                                        -- is it legitimate?
                    return first;                                                -- one or two initials and a valid suffix so nothing to do
                else
                    add_vanc_error ('suffix');                                    -- one or two initials with invalid suffix so error message
                    return first;                                                -- and return first unmolested
                end
            else
                return first;                                                    -- one or two initials without suffix; nothing to do
            end
        end
    end                                                                            -- if here then name has 3 or more uppercase letters so treat them as a word


    local initials, names = {}, {};                                                -- tables to hold name parts and initials
    local i = 1;                                                                -- counter for number of initials

    names = mw.text.split (first, '[%s,]+');                                    -- split into a table of names and possible suffix

    while names[i] do                                                            -- loop through the table
        if 1 < i and names[i]:match ('[%dJS][%drndth]+%.?$') then                -- if not the first name, and looks like a suffix (may have trailing dot)
            names[i] = names[i]:gsub ('%.', '');                                -- remove terminal dot if present
            if is_suffix (names[i]) then                                        -- if a legitimate suffix
                table.insert (initials, ' ' .. names[i]);                        -- add a separator space, insert at end of initials table
                break;                                                            -- and done because suffix must fall at the end of a name
            end                                                                    -- no error message if not a suffix; possibly because of Romanization
        end
        if 3 > i then
            table.insert (initials, mw.ustring.sub(names[i],1,1));                -- insert the intial at end of initials table
        end
        i = i+1;                                                                -- bump the counter
    end

    return table.concat(initials)                                                -- Vancouver format does not include spaces.
end

--[[--------------------------< L I S T  _ P E O P L E >-------------------------------------------------------
Formats a list of people (e.g. authors / editors)
]]
function list_people(control, people, etal)
    local sep;
    local namesep;
    local format = control.format
    local maximum = control.maximum
    local lastauthoramp = control.lastauthoramp;
    local text = {}

    if 'vanc' == format then                                                    -- Vancouver-like author/editor name styling?
        sep = ',';                                                                -- name-list separator between authors is a comma
        namesep = ' ';                                                            -- last/first separator is a space
    elseif 'mla' == control.mode then
        sep = ',';                                                                -- name-list separator between authors is a comma
        namesep = ', '                                                            -- last/first separator is <comma><space>
    else
        sep = ';'                                                                -- name-list separator between authors is a semicolon
        namesep = ', '                                                            -- last/first separator is <comma><space>
    end

    if sep:sub(-1,-1) ~= " " then sep = sep .. " " end
    if is_set (maximum) and maximum < 1 then return "", 0; end                    -- returned 0 is for EditorCount; not used for authors

    for i,person in ipairs(people) do
        if is_set(person.last) then
            local mask = person.mask
            local one
            local sep_one = sep;
            if is_set (maximum) and i > maximum then
                etal = true;
                break;
            elseif (mask ~= nil) then
                local n = tonumber(mask)
                if (n ~= nil) then
                    one = string.rep("&mdash;",n)
                else
                    one = mask;
                    sep_one = " ";
                end
            else
                one = person.last
                local first = person.first
                if is_set(first) then
                    if 'mla' == control.mode then
                        if i == 1 then                                            -- for mla
                            one = one .. namesep .. first;                        -- first name last, first
                        else                                                    -- all other names
                            one = first .. ' ' .. one;                            -- first last
                        end
                    else
                        if ( "vanc" == format ) then                                -- if vancouver format
                            one = one:gsub ('%.', '');                                -- remove periods from surnames (http://www.ncbi.nlm.nih.gov/books/NBK7271/box/A35029/)
                            if not person.corporate and is_good_vanc_name (one, first) then                    -- and name is all Latin characters; corporate authors not tested
                                first = reduce_to_initials(first)                    -- attempt to convert first name(s) to initials
                            end
                        end
                        one = one .. namesep .. first;
                    end
                end
                if is_set(person.link) and person.link ~= control.page_name then
                    one = "[[" .. person.link .. "|" .. one .. "]]"                -- link author/editor if this page is not the author's/editor's page
                end
            end
            table.insert( text, one )
            table.insert( text, sep_one )
        end
    end

    local count = #text / 2;                                                    -- (number of names + number of separators) divided by 2
    if count > 0 then
        if count > 1 and is_set(lastauthoramp) and not etal then
            if 'mla' == control.mode then
                text[#text-2] = ", e ";                                        -- replace last separator with ', and ' text
            else
                text[#text-2] = " & ";                                            -- replace last separator with ampersand text
            end
        end
        text[#text] = nil;                                                        -- erase the last separator
    end

    local result = table.concat(text)                                            -- construct list
    if etal and is_set (result) then                                            -- etal may be set by |display-authors=etal but we might not have a last-first list
        result = result .. sep .. ' ' .. cfg.messages['et al'];                    -- we've go a last-first list and etal so add et al.
    end

    return result, count
end

--[[--------------------------< A N C H O R _ I D >------------------------------------------------------------
Generates a CITEREF anchor ID if we have at least one name or a date.  Otherwise returns an empty string.

namelist is one of the contributor-, author-, or editor-name lists chosen in that order.  year is Year or anchor_year.
]]
function anchor_id (namelist, year)
    local names={};                                                                -- a table for the one to four names and year
    for i,v in ipairs (namelist) do                                                -- loop through the list and take up to the first four last names
        names[i] = v.last
        if i == 4 then break end                                                -- if four then done
    end
    table.insert (names, year);                                                    -- add the year at the end
    local id = table.concat(names);                                                -- concatenate names and year for CITEREF id
    if is_set (id) then                                                            -- if concatenation is not an empty string
        return "CITEREF" .. id;                                                    -- add the CITEREF portion
    else
        return '';                                                                -- return an empty string; no reason to include CITEREF id in this citation
    end
end


--[[--------------------------< N A M E _ H A S _ E T A L >----------------------------------------------------
Evaluates the content of author and editor name parameters for variations on the theme of et al.  If found,
the et al. is removed, a flag is set to true and the function returns the modified name and the flag.

This function never sets the flag to false but returns it's previous state because it may have been set by
previous passes through this function or by the parameters |display-authors=etal or |display-editors=etal
]]
function name_has_etal (name, etal, nocat)

    if is_set (name) then                                                        -- name can be nil in which case just return
        local etal_pattern = "[;,]? *[\"']*%f[%a][Ee][Tt] *[Aa][Ll][%.\"']*$"    -- variations on the 'et al' theme
        local others_pattern = "[;,]? *%f[%a]and [Oo]thers";                    -- and alternate to et al.

        if name:match (etal_pattern) then                                        -- variants on et al.
            name = name:gsub (etal_pattern, '');                                -- if found, remove
            etal = true;                                                        -- set flag (may have been set previously here or by |display-authors=etal)
            if not nocat then                                                    -- no categorization for |vauthors=
                add_maint_cat ('etal');                                            -- and add a category if not already added
            end
        elseif name:match (others_pattern) then                                    -- if not 'et al.', then 'and others'?
            name = name:gsub (others_pattern, '');                                -- if found, remove
            etal = true;                                                        -- set flag (may have been set previously here or by |display-authors=etal)
            if not nocat then                                                    -- no categorization for |vauthors=
                add_maint_cat ('etal');                                            -- and add a category if not already added
            end
        end
    end
    return name, etal;                                                            --
end

--[[--------------------------< N A M E _ H A S _ M U L T _ N A M E S >----------------------------
Evaluates the content of author and editor (surnames only) parameters for multiple names.  Multiple names are
indicated if there is more than one comma and or semicolon.  If found, the function adds the multiple name
(author or editor) maintenance category.
]]
function name_has_mult_names (name, list_name)
local count, _;
    if is_set (name) then
        if name:match ('^%(%(.*%)%)$') then                                        -- if wrapped in doubled parentheses, ignore
            name = name:match ('^%(%((.*)%)%)$');                                -- strip parens
        else
            _, count = name:gsub ('[;,]', '');                                    -- count the number of separator-like characters

            if 1 < count then                                                    -- param could be |author= or |editor= so one separactor character is acceptable
                add_maint_cat ('mult_names', cfg.special_case_translation [list_name]);    -- more than one separator indicates multiple names so add a maint cat for this template
            end
        end
    end
    return name;                                                                -- and done
end

--[[--------------------------< E X T R A C T _ N A M E S >---------------------------------------
Gets name list from the input arguments

Searches through args in sequential order to find |lastn= and |firstn= parameters (or their aliases), and their matching link and mask parameters.
Stops searching when both |lastn= and |firstn= are not found in args after two sequential attempts: found |last1=, |last2=, and |last3= but doesn't
find |last4= and |last5= then the search is done.

This function emits an error message when there is a |firstn= without a matching |lastn=.  When there are 'holes' in the list of last names, |last1= and |last3=
are present but |last2= is missing, an error message is emitted. |lastn= is not required to have a matching |firstn=.

When an author or editor parameter contains some form of 'et al.', the 'et al.' is stripped from the parameter and a flag (etal) returned
that will cause list_people() to add the static 'et al.' text from Module:Citation/CS1/Configuration.  This keeps 'et al.' out of the
template's metadata.  When this occurs, the page is added to a maintenance category.
]]
function extract_names(args, list_name)
    local names = {};            -- table of names
    local last;                    -- individual name components
    local first;
    local link;
    local mask;
    local i = 1;                -- loop counter/indexer
    local n = 1;                -- output table indexer
    local count = 0;            -- used to count the number of times we haven't found a |last= (or alias for authors, |editor-last or alias for editors)
    local etal=false;            -- return value set to true when we find some form of et al. in an author parameter

    local err_msg_list_name = list_name:match ("(%w+)List") .. 's list';        -- modify AuthorList or EditorList for use in error messages if necessary
    while true do
        last = select_one( args, cfg.aliases[list_name .. '-Last'], 'redundant_parameters', i );        -- search through args for name components beginning at 1
        first = select_one( args, cfg.aliases[list_name .. '-First'], 'redundant_parameters', i );
        link = select_one( args, cfg.aliases[list_name .. '-Link'], 'redundant_parameters', i );
        mask = select_one( args, cfg.aliases[list_name .. '-Mask'], 'redundant_parameters', i );

        last, etal = name_has_etal (last, etal, false);                            -- find and remove variations on et al.
        first, etal = name_has_etal (first, etal, false);                        -- find and remove variations on et al.
--        last = name_has_mult_names (last, err_msg_list_name);                    -- check for multiple names in last and its aliases
        last = name_has_mult_names (last, list_name);                    -- check for multiple names in last and its aliases

        if first and not last then                                                -- if there is a firstn without a matching lastn
            table.insert( z.message_tail, { set_error( 'first_missing_last', {err_msg_list_name, i}, true ) } );    -- add this error message
        elseif not first and not last then                                        -- if both firstn and lastn aren't found, are we done?
            count = count + 1;                                                    -- number of times we haven't found last and first
            if 2 <= count then                                                    -- two missing names and we give up
                break;                                                            -- normal exit or there is a two-name hole in the list; can't tell which
            end
        else                                                                    -- we have last with or without a first
            link_title_ok (link, list_name:match ("(%w+)List"):lower() .. '-link' .. i, last, list_name:match ("(%w+)List"):lower() .. '-last' .. i);    -- check for improper wikimarkup

            names[n] = {last = last, first = first, link = link, mask = mask, corporate=false};    -- add this name to our names list (corporate for |vauthors= only)
            n = n + 1;                                                            -- point to next location in the names table
            if 1 == count then                                                    -- if the previous name was missing
                table.insert( z.message_tail, { set_error( 'missing_name', {err_msg_list_name, i-1}, true ) } );        -- add this error message
            end
            count = 0;                                                            -- reset the counter, we're looking for two consecutive missing names
        end
        i = i + 1;                                                                -- point to next args location
    end

    return names, etal;                                                            -- all done, return our list of names
end

--[[--------------------------< G E T _ I S O 6 3 9 _ C O D E >----------------------------------
Validates language names provided in |language= parameter if not an ISO639-1 or 639-2 code.

Returns the language name and associated two- or three-character code.  Because case of the source may be incorrect
or different from the case that WikiMedia uses, the name comparisons are done in lower case and when a match is
found, the Wikimedia version (assumed to be correct) is returned along with the code.  When there is no match, we
return the original language name string.

mw.language.fetchLanguageNames(<local wiki language>, 'all') return a list of languages that in some cases may include
extensions. For example, code 'cbk-zam' and its associated name 'Chavacano de Zamboanga' (MediaWiki does not support
code 'cbk' or name 'Chavacano'.

Names but that are included in the list will be found if that name is provided in the |language= parameter.  For example,
if |language=Chavacano de Zamboanga, that name will be found with the associated code 'cbk-zam'.  When names are found
and the associated code is not two or three characters, this function returns only the Wikimedia language name.

Adapted from code taken from Module:Check ISO 639-1.
]]
function get_iso639_code (lang, this_wiki_code)
    local languages = mw.language.fetchLanguageNames(this_wiki_code, 'all')        -- get a list of language names known to Wikimedia
                                                                                -- ('all' is required for North Ndebele, South Ndebele, and Ojibwa)
    local langlc = mw.ustring.lower(lang);                                        -- lower case version for comparisons

    for code, name in pairs(languages) do                                        -- scan the list to see if we can find our language
        if langlc == mw.ustring.lower(name) then
            if 2 ~= code:len() and 3 ~= code:len() then                            -- two- or three-character codes only; extensions not supported
                return name;                                                    -- so return the name but not the code
            end
            return name, code;                                                    -- found it, return name to ensure proper capitalization and the the code
        end
    end
    return lang;                                                                -- not valid language; return language in original case and nil for the code
end

--[[--------------------------< L A N G U A G E _ P A R A M E T E R >------------------------------
Gets language name from a provided two- or three-character ISO 639 code.  If a code is recognized by MediaWiki,
use the returned name; if not, then use the value that was provided with the language parameter.

When |language= contains a recognized language (either code or name), the page is assigned to the category for
that code: Category:Norwegian-language sources (no).  For valid three-character code languages, the page is assigned
to the single category for '639-2' codes: Category:CS1 ISO 639-2 language sources.

Languages that are the same as the local wiki are not categorized.  MediaWiki does not recognize three-character
equivalents of two-character codes: code 'ar' is recognized bit code 'ara' is not.

This function supports multiple languages in the form |language=nb, French, th where the language names or codes are
separated from each other by commas.
]]
function language_parameter (lang)
    local code;                                                                    -- the two- or three-character language code
    local name;                                                                    -- the language name
    local language_list = {};                                                    -- table of language names to be rendered
    local names_table = {};                                                        -- table made from the value assigned to |language=

    local this_wiki = mw.getContentLanguage();                                    -- get a language object for this wiki
    local this_wiki_code = this_wiki:getCode()                                    -- get this wiki's language code
    local this_wiki_name = mw.language.fetchLanguageName(this_wiki_code, this_wiki_code);    -- get this wiki's language name

    names_table = mw.text.split (lang, '%s*,%s*');                                -- names should be a comma separated list

    for _, lang in ipairs (names_table) do                                        -- reuse lang

        if lang:match ('^%a%a%-') then                                            -- strip ietf language tags from code; TODO: is there a need to support 3-char with tag?
            lang = lang:match ('(%a%a)%-')                                        -- keep only 639-1 code portion to lang; TODO: do something with 3166 alpha 2 country code?
        end
        if 2 == lang:len() or 3 == lang:len() then                                -- if two-or three-character code
            name = mw.language.fetchLanguageName( lang:lower(), this_wiki_code);    -- get language name if |language= is a proper code
        end

        if is_set (name) then                                                    -- if |language= specified a valid code
            code = lang:lower();                                                -- save it
        else
            name, code = get_iso639_code (lang, this_wiki_code);                -- attempt to get code from name (assign name here so that we are sure of proper capitalization)
        end

        if is_set (code) then                                                    -- only 2- or 3-character codes
            if this_wiki_code ~= code then                                        -- when the language is not the same as this wiki's language
                if 2 == code:len() then                                            -- and is a two-character code
                    add_prop_cat ('foreign_lang_source', {name, code})            -- categorize it
                else                                                            -- or is a recognized language (but has a three-character code)
                    add_prop_cat ('foreign_lang_source_2', {code})                -- categorize it differently TODO: support mutliple three-character code categories per cs1|2 template
                end
            end
        else
            add_maint_cat ('unknown_lang');                                        -- add maint category if not already added
        end

        table.insert (language_list, name);
        name = '';                                                                -- so we can reuse it
    end

    code = #language_list                                                        -- reuse code as number of languages in the list
    if 2 >= code then
        name = table.concat (language_list, ' e ')                            -- insert '<space>and<space>' between two language names
    elseif 2 < code then
        language_list[code] = 'e ' .. language_list[code];                    -- prepend last name with 'and<space>'
        name = table.concat (language_list, ', ')                                -- and concatenate with '<comma><space>' separators
    end
    if this_wiki_name == name then
        return '';                                                                -- if one language and that language is this wiki's return an empty string (no annotation)
    end
    return (" " .. wrap_msg ('language', name));                                -- otherwise wrap with '(in ...)'
    --[[ TODO: should only return blank or name rather than full list
    so we can clean up the bunched parenthetical elements Language, Type, Format
    ]]
end

--[[--------------------------< S E T _ S T Y L E >-----------------------------------------
Estabelece as configurações básicas de estilo para ser usado na rederização da citação.
]]
function set_style (mode, ps, ref)
    local sep
    if 'cs2' == mode then -- caso a citação for pra ser renderizado com estilo CS2
        if not is_set (ref) then -- se |ref= não está definido
            ref = "harv" -- o padrão é |ref=harv
        end
        sep = ',' -- separador é uma vírgula
    else -- caso a citação for estilo mla, CS1, ou não definido
        sep = '.'
    end
    -- se assinalado como 'none' então apaga-se
    if (not ps) or 'none' == ps:lower() then
        ps = ''
    end

    return sep, ps, ref
end

--[=[-------------------------< I S _ P D F >----------------------------------------------
Determines if a url has the file extension that is one of the pdf file extensions used by [[MediaWiki:Common.css]] when
applying the pdf icon to external links.

returns true if file extension is one of the recognized extension, else false
]=]
function is_pdf (url)
    return url:match ('%.pdf[%?#]?') or url:match ('%.PDF[%?#]?');
end

--[[--------------------------< S T Y L E _ F O R M A T >------------------------------------------------------
Applies css style to |format=, |chapter-format=, etc.  Also emits an error message if the format parameter does
not have a matching url parameter.  If the format parameter is not set and the url contains a file extension that
is recognized as a pdf document by MediaWiki's commons.css, this code will set the format parameter to (PDF) with
the appropriate styling.
]]
function style_format (format, url, fmt_param, url_param)
    if is_set (format) then
        format = wrap_style ('format', format);                                    -- add leading space, parenthases, resize
        if not is_set (url) then
            format = format .. set_error( 'format_missing_url', {fmt_param, url_param} );    -- add an error message
        end
    elseif is_pdf (url) then                                                    -- format is not set so if url is a pdf file then
        format = wrap_style ('format', 'PDF');                                    -- set format to pdf
    else
        format = '';                                                            -- empty string for concatenation
    end
    return format;
end

--[[----------------< G E T _ D I S P L A Y _ A U T H O R S _ E D I T O R S >----------------------
Returns a number that defines the number of names displayed for author and editor name lists and a boolean flag
to indicate when et al. should be appended to the name list.

When the value assigned to |display-xxxxors= is a number greater than or equal to zero, return the number and
the previous state of the 'etal' flag (false by default but may have been set to true if the name list contains
some variant of the text 'et al.').

When the value assigned to |display-xxxxors= is the keyword 'etal', return a number that is one greater than the
number of authors in the list and set the 'etal' flag true.  This will cause the list_people() to display all of
the names in the name list followed by 'et al.'

In all other cases, returns nil and the previous state of the 'etal' flag.

inputs:
    max: A['DisplayAuthors'] or A['DisplayEditors']; a number or some flavor of etal
    count: #a or #e
    list_name: 'authors' or 'editors'
    etal: author_etal or editor_etal
]]
function get_display_authors_editors (max, count, list_name, etal)
    if is_set (max) then
        if 'etal' == max:lower():gsub("[ '%.]", '') then                        -- the :gsub() portion makes 'etal' from a variety of 'et al.' spellings and stylings
            max = count + 1;                                                    -- number of authors + 1 so display all author name plus et al.
            etal = true;                                                        -- overrides value set by extract_names()
        elseif max:match ('^%d+$') then                                            -- if is a string of numbers
            max = tonumber (max);                                                -- make it a number
            if max >= count then                                                -- if |display-xxxxors= value greater than or equal to number of authors/editors
                add_maint_cat ('disp_auth_ed', cfg.special_case_translation [list_name]);
            end
        else                                                                    -- not a valid keyword or number
            table.insert( z.message_tail, { set_error( 'invalid_param_val', {'display-' .. list_name, max}, true ) } );        -- add error message
            max = nil;                                                            -- unset; as if |display-xxxxors= had not been set
        end
    end

    return max, etal;
end

--[[--------------------< E X T R A _ T E X T _ I N _ P A G E _ C H E C K >----------------------
Adds page to Category:CS1 maint: extra text if |page= or |pages= has what appears to be some form of p. or pp.
abbreviation in the first characters of the parameter content.

check Page and Pages for extraneous p, p., pp, and pp. at start of parameter value:
    good pattern: '^P[^%.P%l]' matches when |page(s)= begins PX or P# but not Px where x and X are letters and # is a dgiit
    bad pattern: '^[Pp][Pp]' matches matches when |page(s)= begins pp or pP or Pp or PP
]]
function extra_text_in_page_check (page)
--    local good_pattern = '^P[^%.P%l]';
    local good_pattern = '^P[^%.Pp]';                                            -- ok to begin with uppercase P: P7 (pg 7 of section P) but not p123 (page 123) TODO: add Gg for PG or Pg?
--    local bad_pattern = '^[Pp][Pp]';
    local bad_pattern = '^[Pp]?[Pp]%.?[ %d]';

    if not page:match (good_pattern) and (page:match (bad_pattern) or  page:match ('^[Pp]ages?')) then
        add_maint_cat ('extra_text');
    end
end


--[[--------------------------< G E T _ V _ N A M E _ T A B L E >----------------------------------------------

split apart a |vautthors= or |veditors= parameter.  This function allows for corporate names, wrapped in doubled
parentheses to also have commas; in the old version of the code, the doubled parnetheses were included in the
rendered citation and in the metadata.

    |vauthors=Jones AB, White EB, ((Black, Brown, and Co.))

This code is experimental and may not be retained.

]]
function get_v_name_table (vparam, output_table)
    local name_table = mw.text.split(vparam, "%s*,%s*");                        -- names are separated by commas

    local i = 1;

    while name_table[i] do
        if name_table[i]:match ('^%(%(.*[^%)][^%)]$') then                        -- first segment of corporate with one or more commas; this segment has the opening doubled parens
            local name = name_table[i];
            i=i+1;                                                                -- bump indexer to next segment
            while name_table[i] do
                name = name .. ', ' .. name_table[i];                            -- concatenate with previous segments
                if name_table[i]:match ('^.*%)%)$') then                        -- if this table member has the closing doubled parens
                    break;                                                        -- and done reassembling so
                end
                i=i+1;                                                            -- bump indexer
            end
            table.insert (output_table, name);                                    -- and add corporate name to the output table
        else
            table.insert (output_table, name_table[i]);                            -- add this name
        end
        i = i+1;
    end
    return output_table;
end

--[[--------------------------< P A R S E _ V A U T H O R S _ V E D I T O R S >--------------------------------
This function extracts author / editor names from |vauthors= or |veditors= and finds matching |xxxxor-maskn= and
|xxxxor-linkn= in args.  It then returns a table of assembled names just as extract_names() does.

Author / editor names in |vauthors= or |veditors= must be in Vancouver system style. Corporate or institutional names
may sometimes be required and because such names will often fail the is_good_vanc_name() and other format compliance
tests, are wrapped in doubled paranethese ((corporate name)) to suppress the format tests.

Supports generational suffixes Jr, 2nd, 3rd, 4th–6th.

This function sets the vancouver error when a reqired comma is missing and when there is a space between an author's initials.
]]
function parse_vauthors_veditors (args, vparam, list_name)
    local names = {};                                                            -- table of names assembled from |vauthors=, |author-maskn=, |author-linkn=
    local v_name_table = {};
    local etal = false;                                                            -- return value set to true when we find some form of et al. vauthors parameter
    local last, first, link, mask, suffix;
    local corporate = false;

    vparam, etal = name_has_etal (vparam, etal, true);                            -- find and remove variations on et al. do not categorize (do it here because et al. might have a period)
    if vparam:find ('%[%[') or vparam:find ('%]%]')    then                        -- no wikilinking vauthors names
        add_vanc_error ('wikilink');
    end
    v_name_table = get_v_name_table (vparam, v_name_table);                        -- names are separated by commas

    for i, v_name in ipairs(v_name_table) do
        if v_name:match ('^%(%(.+%)%)$') then                                    -- corporate authors are wrapped in doubled parentheses to supress vanc formatting and error detection
            first = '';                                                            -- set to empty string for concatenation and because it may have been set for previous author/editor
            last = v_name:match ('^%(%((.+)%)%)$')                                -- remove doubled parntheses
            corporate = true;                                                    -- flag used in list_people()
        elseif string.find(v_name, "%s") then
            if v_name:find('[;%.]') then                                        -- look for commonly occurring punctuation characters;
                add_vanc_error ('punctuation');
            end
            local lastfirstTable = {}
            lastfirstTable = mw.text.split(v_name, "%s")
            first = table.remove(lastfirstTable);                                -- removes and returns value of last element in table which should be author intials
            if is_suffix (first) then                                            -- if a valid suffix
                suffix = first                                                    -- save it as a suffix and
                first = table.remove(lastfirstTable);                            -- get what should be the initials from the table
            end                                                                    -- no suffix error message here because letter combination may be result of Romanization; check for digits?
            last = table.concat(lastfirstTable, " ")                            -- returns a string that is the concatenation of all other names that are not initials
            if mw.ustring.match (last, '%a+%s+%u+%s+%a+') then
                add_vanc_error ('missing comma');                                -- matches last II last; the case when a comma is missing
            end
            if mw.ustring.match (v_name, ' %u %u$') then                        -- this test is in the wrong place TODO: move or replace with a more appropriate test
                add_vanc_error ('name');                                        -- matches a space between two intiials
            end
        else
            first = '';                                                            -- set to empty string for concatenation and because it may have been set for previous author/editor
            last = v_name;                                                        -- last name or single corporate name?  Doesn't support multiword corporate names? do we need this?
        end

        if is_set (first) then
            if not mw.ustring.match (first, "^%u?%u$") then                        -- first shall contain one or two upper-case letters, nothing else
                add_vanc_error ('initials');                                    -- too many initials; mixed case initials (which may be ok Romanization); hyphenated initials
            end
            is_good_vanc_name (last, first);                                    -- check first and last before restoring the suffix which may have a non-Latin digit
            if is_set (suffix) then
                first = first .. ' ' .. suffix;                                    -- if there was a suffix concatenate with the initials
                suffix = '';                                                    -- unset so we don't add this suffix to all subsequent names
            end
        else
            if not corporate then
                is_good_vanc_name (last, '');
            end
        end
                                                                                -- this from extract_names ()
        link = select_one( args, cfg.aliases[list_name .. '-Link'], 'redundant_parameters', i );
        mask = select_one( args, cfg.aliases[list_name .. '-Mask'], 'redundant_parameters', i );
        names[i] = {last = last, first = first, link = link, mask = mask, corporate=corporate};        -- add this assembled name to our names list
    end
    return names, etal;                                                            -- all done, return our list of names
end


--[[---------------------< S E L E C T _ A U T H O R _ E D I T O R _ S O U R C E >------------------
Select one of |authors=, |authorn= / |lastn / firstn=, or |vauthors= as the source of the author name list or
select one of |editors=, |editorn= / editor-lastn= / |editor-firstn= or |veditors= as the source of the editor name list.

Only one of these appropriate three will be used.  The hierarchy is: |authorn= (and aliases) highest and |authors= lowest and
similarly, |editorn= (and aliases) highest and |editors= lowest

When looking for |authorn= / |editorn= parameters, test |xxxxor1= and |xxxxor2= (and all of their aliases); stops after the second
test which mimicks the test used in extract_names() when looking for a hole in the author name list.  There may be a better
way to do this, I just haven't discovered what that way is.

Emits an error message when more than one xxxxor name source is provided.

In this function, vxxxxors = vauthors or veditors; xxxxors = authors or editors as appropriate.
]]
function select_author_editor_source (vxxxxors, xxxxors, args, list_name)
local lastfirst = false;
    if select_one( args, cfg.aliases[list_name .. '-Last'], 'none', 1 ) or        -- do this twice incase we have a |first1= without a |last1=; this ...
        select_one( args, cfg.aliases[list_name .. '-First'], 'none', 1 ) or    -- ... also catches the case where |first= is used with |vauthors=
        select_one( args, cfg.aliases[list_name .. '-Last'], 'none', 2 ) or
        select_one( args, cfg.aliases[list_name .. '-First'], 'none', 2 ) then
            lastfirst=true;
    end

    if (is_set (vxxxxors) and true == lastfirst) or                                -- these are the three error conditions
        (is_set (vxxxxors) and is_set (xxxxors)) or
        (true == lastfirst and is_set (xxxxors)) then
            local err_name;
            if 'AuthorList' == list_name then                                    -- figure out which name should be used in error message
                err_name = 'author';
            else
                err_name = 'editor';
            end
            table.insert( z.message_tail, { set_error( 'redundant_parameters',
                {err_name .. '-name-list parameters'}, true ) } );                -- add error message
    end

    if true == lastfirst then return 1 end;                                        -- return a number indicating which author name source to use
    if is_set (vxxxxors) then return 2 end;
    if is_set (xxxxors) then return 3 end;
    return 1;                                                                    -- no authors so return 1; this allows missing author name test to run in case there is a first without last
end


--[[--------------------------< I S _ V A L I D _ P A R A M E T E R _ V A L U E >------------------------------
This function is used to validate a parameter's assigned value for those parameters that have only a limited number
of allowable values (yes, y, true, no, etc).  When the parameter value has not been assigned a value (missing or empty
in the source template) the function refurns true.  If the parameter value is one of the list of allowed values returns
true; else, emits an error message and returns false.
]]
function is_valid_parameter_value (value, name, possible)

    if not is_set (value) then
        return true;                                                            -- an empty parameter is ok
    elseif in_array(value:lower(), possible) then
        return true;
    else
        table.insert( z.message_tail, { set_error( 'invalid_param_val', {name, value}, true ) } );    -- not an allowed value so add error message
        return false
    end
end


--[[--------------------------< T E R M I N A T E _ N A M E _ L I S T >----------------------------------------
This function terminates a name list (author, contributor, editor) with a separator character (sepc) and a space
when the last character is not a sepc character or when the last three characters are not sepc followed by two
closing square brackets (close of a wikilink).  When either of these is true, the name_list is terminated with a
single space character.
]]
function terminate_name_list (name_list, sepc)
    if (string.sub (name_list,-1,-1) == sepc) or (string.sub (name_list,-3,-1) == sepc .. ']]') then    -- if last name in list ends with sepc char
        return name_list .. " ";                                                -- don't add another
    else
        return name_list .. sepc .. ' ';                                        -- otherwise terninate the name list
    end
end


--[[-------------------------< F O R M A T _ V O L U M E _ I S S U E >----------------------------------------
returns the concatenation of the formatted volume and issue parameters as a single string; or formatted volume
or formatted issue, or an empty string if neither are set.
]]
function format_volume_issue(volume, issue, sepc, lower)
    if not is_set (volume) and not is_set (issue) then
        return ''
    end

    local vol = ''

    if is_set (volume) then
        if (4 < mw.ustring.len(volume)) then
            vol = substitute (cfg.messages['j-vol'], {sepc, volume})
        else
            vol = substitute (cfg.presentation['vol-bold'], {sepc, hyphen_to_dash(volume)})
        end
    end
    if is_set (issue) then
        return vol .. substitute (cfg.messages['j-issue'], issue)
    end
    return vol
end


--[[-------------------------< F O R M A T _ P A G E S _ S H E E T S >-----------------------------------------
adds static text to one of |page(s)= values and returns it with all of the others set to empty strings.
The return order is:
    page, pages

Singular has priority over plural when both are provided.
]]
function format_pages(page, pages, sepc, nopp, lower, totalPages)
    local retorno = {'', ''}
    if is_set(page) then
        if not nopp then
            retorno = { substitute(cfg.messages['p-prefix'], {sepc, page}), ''}
        else
            retorno = { substitute (cfg.messages['nopp'], {sepc, page}), ''}
        end
    elseif is_set(pages) then
        if not nopp then
            retorno = { '', substitute (cfg.messages['pp-prefix'], {sepc, pages})}
        else
            retorno = { '', substitute (cfg.messages['nopp'], {sepc, pages})}
        end
    end

    if is_set(totalPages) then
        retorno[2] = retorno[2] .. substitute (cfg.messages['total-p'], {sepc, totalPages})
    end

    return unpack(retorno)
end


--[=[---------------------< A R C H I V E _ U R L _ C H E C K >------------------------------------
Check archive.org urls to make sure they at least look like they are pointing at valid archives and not to the
save snapshot url or to calendar pages.  When the archive url is 'https://web.archive.org/save/' (or http://...)
archive.org saves a snapshot of the target page in the url.  That is something that Wikipedia should not allow
unwitting readers to do.

When the archive.org url does not have a complete timestamp, archive.org chooses a snapshot according to its own
algorithm or provides a calendar 'search' result.  [[WP:ELNO]] discourages links to search results.

This function looks at the value assigned to |archive-url= and returns empty strings for |archive-url= and
|archive-date= and an error message when:
    |archive-url= holds an archive.org save command url
    |archive-url= is an archive.org url that does not have a complete timestamp (YYYYMMDDhhmmss 14 digits) in the
        correct place
otherwise returns |archive-url= and |archive-date=

There are two mostly compatible archive.org urls:
    //web.archive.org/<timestamp>...        -- the old form
    //web.archive.org/web/<timestamp>...    -- the new form

The old form does not support or map to the new form when it contains a display flag.  There are four identified flags
('id_', 'js_', 'cs_', 'im_') but since archive.org ignores others following the same form (two letters and an underscore)
we don't check for these specific flags but we do check the form.

This function supports a preview mode.  When the article is rendered in preview mode, this funct may return a modified
archive url:
    for save command errors, return undated wildcard (/*/)
    for timestamp errors when the timestamp has a wildcard, return the url unmodified
    for timestamp errors when the timestamp does not have a wildcard, return with timestamp limited to six digits plus wildcard (/yyyymm*/)
]=]
function archive_url_check (url, date)
    local err_msg = '';                                                            -- start with the error message empty
    local path, timestamp, flag;                                                -- portions of the archive.or url

    if not url:match('//web%.archive%.org/') then
        return url, date;                                                        -- not an archive.org archive, return ArchiveURL and ArchiveDate
    end

    if url:match('//web%.archive%.org/save/') then                                -- if a save command url, we don't want to allow saving of the target page
        err_msg = 'save command';
        url = url:gsub ('(//web%.archive%.org)/save/', '%1/*/', 1);                -- for preview mode: modify ArchiveURL
    else
        path, timestamp, flag = url:match('//web%.archive%.org/([^%d]*)(%d+)([^/]*)/');        -- split out some of the url parts for evaluation

        if not is_set(timestamp) or 14 ~= timestamp:len() then                    -- path and flag optional, must have 14-digit timestamp here
            err_msg = 'timestamp';
            if '*' ~= flag then
                url=url:gsub ('(//web%.archive%.org/[^%d]*%d?%d?%d?%d?%d?%d?)[^/]*', '%1*', 1)    -- for preview, modify ts to be yearmo* max (0-6 digits plus splat)
            end
        elseif is_set(path) and 'web/' ~= path then                                -- older archive urls do not have the extra 'web/' path element
            err_msg = 'path';
        elseif is_set (flag) and not is_set (path) then                            -- flag not allowed with the old form url (without the 'web/' path element)
            err_msg = 'flag';
        elseif is_set (flag) and not flag:match ('%a%a_') then                    -- flag if present must be two alpha characters and underscore (requires 'web/' path element)
            err_msg = 'flag';
        else
            return url, date;                                                    -- return archiveURL and ArchiveDate
        end
    end
                                                                                -- if here, something not right so
    table.insert( z.message_tail, { set_error( 'archive_url', {err_msg}, true ) } );    -- add error message and
    if is_set (Frame:preprocess('{{REVISIONID}}')) then
        return '', '';                                                            -- return empty strings for archiveURL and ArchiveDate
    else
        return url, date;                                                        -- preview mode so return archiveURL and ArchiveDate
    end
end


--[[--------------------------< M I S S I N G _ P I P E _ C H E C K >------------------------------
Look at the contents of a parameter. If the content has a string of characters and digits followed by an equal
sign, compare the alphanumeric string to the list of cs1|2 parameters.  If found, then the string is possibly a
parameter that is missing its pipe:
    {{cite ... |title=Title access-date=2016-03-17}}

cs1|2 shares some parameter names with xml/html atributes: class=, title=, etc.  To prevent false positives xml/html
tags are removed before the search.

If a missing pipe is detected, this function adds the missing pipe maintenance category.
]]
function missing_pipe_check (value)
    local capture;
    value = value:gsub ('%b<>', '');                                            -- remove xml/html tags because attributes: class=, title=, etc

    capture = value:match ('%s+(%a[%a%d]+)%s*=') or value:match ('^(%a[%a%d]+)%s*=');    -- find and categorize parameters with possible missing pipes
    if capture and validate (capture) then                                -- if the capture is a valid parameter name
        add_maint_cat ('missing_pipe');
    end
end


--[[--------------------------< C I T A T I O N 0 >------------------------------------------------------------
Esta é a função com as principais abstrações de formatação de citação.
]]
function citation0( config, args, A)
    -- Vetor de parâmetros a ser passado para a próxima função
    local B = {}

    -- define parâmetros padrão definidos pelo parâmetro |mode=, se não definido usa CS1
    A.Mode = A.Mode:lower()
    if not is_valid_parameter_value (A.Mode, 'mode', cfg.keywords['mode']) then
        A.Mode = ''
    end

    local author_etal;
    local a    = {} -- lista de autores em |lastn= / |firstn= ou |vauthors=

    do -- limita escopo de 'selected'
        local authors = ''
        local selected = select_author_editor_source (A['Vauthors'], A['Authors'], args, 'AuthorList');
        if 1 == selected then
            a, author_etal = extract_names (args, 'AuthorList') -- busca lista de autores em |authorn= / |lastn= / |firstn=, |author-linkn=, |author-maskn=
        elseif 2 == selected then
            A.NameListFormat = 'vanc' -- sobrescreve o que tiver em |name-list-format=
            a, author_etal = parse_vauthors_veditors (args, args.vauthors, 'AuthorList') -- busca lista de autores em |vauthors=, |author-linkn=, |author-maskn=
        elseif 3 == selected then
            -- usar conteúdo d |authors=
            authors = A.Authors
            -- mas adiciona uma categoria de manutenção caso parâmetro for |authors=
            if in_array(A:ORIGIN('Authors'), {'autores', 'authors'}) then
                -- porque o uso deste parâmetro é desencorajado
                add_maint_cat ('authors')
            end
        end
        if is_set (A.Collaboration) then
            author_etal = true -- assim, |display-authors=etal não requerido
        end
        A.Authors = authors
    end

    local editor_etal
    local e    = {} -- lista de editores em |editor-lastn= / |editor-firstn= ou |veditors=

    do -- limita escopo da variável 'selected'
        local selected = select_author_editor_source (A.Veditors, A.Editors, args, 'EditorList')
        if 1 == selected then
            e, editor_etal = extract_names (args, 'EditorList') -- busca lista de editores em |editorn= / |editor-lastn= / |editor-firstn=, |editor-linkn=, |editor-maskn=
        elseif 2 == selected then
            A.NameListFormat = 'vanc' -- sobrescreve o que tiver em |name-list-format=
            e, editor_etal = parse_vauthors_veditors (args, args.veditors, 'EditorList') -- busca lista de editores em |veditors=, |editor-linkn=, |editor-maskn=
        elseif 3 == selected then
            B.Editors = A['Editors'] -- usa conteúdo de |editors=
            add_maint_cat ('editors') -- mas ad maint cat, o uso deste parâmetro é desencorajado
        end
    end

    local t = {} -- lista de tradutores em |translator-lastn= / translator-firstn=
    local Translators -- lista de nome de tradutores montada
    t = extract_names (args, 'TranslatorList') -- busca lista de tradutores em |translatorn=, |translator-lastn=, -firstn=, -linkn=, -maskn=

    local c = {} -- lista de contribuidores em |contributor-lastn= / contributor-firstn=
    -- |contributor= |contribution= suportado em citação de livro como {{citation}} e {{citar livro}}
    if config.usaContributor then
        c = extract_names (args, 'ContributorList') -- busca lista de contribuidor em |contributorn=, |contributor-lastn=, -firstn=, -linkn=, -maskn=
        if 0 < #c then
            if not is_set (A.Contribution) then -- |contributor= requer |contribution=
                table.insert(z.message_tail, { set_error('contributor_missing_required_param', 'contribuição')}) -- ad mensagem de erro de que falta contribuição
                c = {} -- esvazia a tabela de contribuidores; será usado como flag depois
            end
            if 0 == #a then -- |contributor= requer |author=
                table.insert(z.message_tail, { set_error('contributor_missing_required_param', 'autor')}) -- ad mensagem de erro de que falta autor
                c = {} -- esvazia a tabela de contribuidores; será usado como flag depois
            end
        end
    else -- se não for uma citação de livro
        if select_one (args, cfg.aliases['ContributorList-Last'], 'redundant_parameters', 1 ) then    -- há nome de contribuidor nos parâmetros de lista de nome?
            table.insert(z.message_tail, { set_error('contributor_ignored')}) -- mensagem de contribuidor ignorado
        end
        A.Contribution = nil
    end

    if not is_valid_parameter_value (A.NameListFormat, 'name-list-format', cfg.keywords['name-list-format']) then -- único valor aceito é 'vanc'
        A.NameListFormat = '' -- qualquer outra coisa no lugar, esvaziar
    end
    -- verifica marcação wiki em |title-link= ou |title= se |title-link= for definido
    link_title_ok(A.TitleLink, A:ORIGIN ('TitleLink'), A.Title, 'title')

    A.ArchiveURL, A.ArchiveDate = archive_url_check (A['ArchiveURL'], A['ArchiveDate'])

    -- obter o nome do identificador das seguintes variáveis
    local URLorigin = A:ORIGIN('URL')
    local ChapterURLorigin = A:ORIGIN('ChapterURL')
    local Periodical_origin = A:ORIGIN('Periodical')
    local Chapter_origin = A:ORIGIN('Chapter')

    if not config.usaVolume then
        A.Volume = ''
    end

    if not config.usaIssue then
        A.Issue = ''
    end
    B.Position = '';
    if config.naoUsaPage then
        A.Page = ''
        A.Pages = ''
        A.TotalPages = ''
        A.At = ''
    else
        A.Pages = hyphen_to_dash(A.Pages)
    end

    if not is_valid_parameter_value(A.RegistrationRequired, 'registration', cfg.keywords ['yes_true_y_sim_s']) then
        A.RegistrationRequired=nil
    end

    if not is_valid_parameter_value(A.SubscriptionRequired, 'subscription', cfg.keywords ['yes_true_y_sim_s']) then
        A.SubscriptionRequired=nil
    end

    if not is_valid_parameter_value(A.UrlAccess, 'url-access', cfg.keywords ['url-access']) then
        A.UrlAccess = nil
    end

    if not is_set(A.URL) and is_set(A.UrlAccess) then
        A.UrlAccess = nil
        table.insert(z.message_tail, { set_error('param_access_requires_param', {'url'}, true )})
    end

    if is_set (A.UrlAccess) and is_set (A.SubscriptionRequired) then -- praticamente a mesma coisa
        table.insert(z.message_tail, { set_error('redundant_parameters', {wrap_style('parameter'
            , 'url-access') .. ' e ' .. wrap_style('parameter', 'subscrição')}, true)})
        A.SubscriptionRequired = nil -- preferir |access= sobre |subscription=
    end

    if is_set (A.UrlAccess) and is_set (A.RegistrationRequired) then -- contraditório
        table.insert(z.message_tail, { set_error('redundant_parameters', {wrap_style('parameter'
            , 'url-access') .. ' e ' .. wrap_style('parameter', 'registro')}, true)})
        A.RegistrationRequired = nil -- preferir |access= sobre |registration=
    end

    if not is_valid_parameter_value (A.IgnoreISBN, 'ignore-isbn-error', cfg.keywords ['yes_true_y_sim_s']) then
        A.IgnoreISBN = nil -- qualquer outra coisa no lugar, esvaziar
    end

    local ID_list = config.ID_list
    if ID_list then
        config.ID_list = nil
    else
        ID_list = extract_ids( args )
    end
    local ID_access_levels = extract_id_access_levels( args, ID_list )

    local TranscriptURLorigin = A:ORIGIN('TranscriptURL') -- pega o nome do parâmetro TranscriptURL

    if not is_valid_parameter_value (A.LastAuthorAmp, 'last-author-amp', cfg.keywords ['yes_true_y_sim_s']) then
        A.LastAuthorAmp = nil
    end

    if 'mla' == A.Mode then
        A.LastAuthorAmp = 'sim' -- substitui separador de último author/editor por ' e '
    end

    if not is_valid_parameter_value (A.NoTracking, 'no-tracking', cfg.keywords ['yes_true_y_sim_s']) then
        A.NoTracking = nil
    end

    --variáveis locais não oriúndas de parâmetros
    local this_page = mw.title.getCurrentTitle() -- também usado para COinS e para língua
    local COinS_date = {} -- conterá informação de data extraída de |date= pro COinS

    if not is_valid_parameter_value(A.DF, 'df', cfg.keywords['date-format']) then -- validar palavra-chave para reformatar
        A.DF = '' -- inválido, esvaziar
    end

    B.sepc, B.PostScript, B.Ref = set_style (A.Mode:lower(), A['PostScript'], A['Ref'])
    -- separador dos elementos da citação, sendo 'ponto' para CS1, 'vírgula' para CS2
    B.use_lowercase = ( B.sepc == ',' ) -- controle de uso do maiúsculo após ponto ou vírgula

    --verifica esta página para ver se é um domínio onde supõe-se não adicionar categorias de erro
    if not is_set (A.NoTracking) then -- ignora se já foi apontado para não categorizar a página
        if in_array (this_page.nsText, cfg.uncategorized_namespaces) then
            A.NoTracking = "true" -- define A.NoTracking
        end
        for _,v in ipairs (cfg.uncategorized_subpages) do
            if this_page.text:match (v) then -- testa nome da página com cada modelo
                A.NoTracking = "true" -- define A.NoTracking
                break -- sai do laço se encontrou algum
            end
        end
    end

    -- |publication-place= e |place= (|location=) permitido se diferentes
    if not is_set(A.PublicationPlace) and is_set(A.Place) then
        A.PublicationPlace = A.Place -- promove |place= (|location=) a |publication-place
    end

    if A.PublicationPlace == A.Place then
        A.Place = '' -- não precisa de dois se são iguais
    end

    if is_set(A.TitleType) then -- se o parâmetro tipo estiver especificado
        A.TitleType = substitute(cfg.messages['type'], A.TitleType) -- mostra entre parentesis
    end

--[[
Testar todos os parâmetros que contêm data, certificando que são válidas. Deve ser feito antes
de adicionar ao COinS para não estar errado nos metadados.

O código da validação de datas encontra-se em Módulo:Citação/CS1/ValidaçãoDatas
]]
    do -- cria escopo para conter variáveis locais de mensagem de erro etc
        if is_set(A.Year) then
            local d1, d2, d3 = A.Year:match('(%d%d%d)(%d)/(%d)')
            if d1 and d2 and d3 then
                A.Year = d1 .. d2 .. '–' .. d1 .. d3
            end
        end
        local error_message = ''

        -- converter formato de dada do padrão xx/xx/xxxx para o padrão utilizado
        local convertDate = require('Módulo:Conversor de data')
        A.AccessDate, A.ArchiveDate, A.Date, A.DoiBroken, A.Embargo, A.LayDate, A.PublicationDate =
            convertDate.main({args = {A.AccessDate}}),
            convertDate.main({args = {A.ArchiveDate}}),
            convertDate.main({args = {A.Date}}),
            convertDate.main({args = {A.DoiBroken}}),
            convertDate.main({args = {A.Embargo}}),
            convertDate.main({args = {A.LayDate}}),
            convertDate.main({args = {A.PublicationDate}})
        -- desreferenciando para enviar ao coletor de lixo e liberar memória
        convertDate = nil

        local date_parameters_list = {['acessodata']=A.AccessDate, ['arquivodata']=A.ArchiveDate, ['data']=A.Date, ['doi-incorrecto']=A.DoiBroken,
                ['embargo']=A.Embargo, ['resumo-data']=A.LayDate, ['data-publicacao']=A.PublicationDate, ['ano']=A.Year};

        for k, v in pairs(date_parameters_list) do
            local bool
            date_parameters_list[k], bool = v:gsub('[%[%]]', '')
            if bool ~= 0 then
                table.insert( z.error_categories, '!Páginas com erros CS1: datas')
            end
        end

        -- B.anchor_year usado no identificador CITEREF
        B.anchor_year, A.Embargo, error_message = dates(date_parameters_list, COinS_date);

        if is_set (A.Year) and is_set (A.Date) then -- não precisa de ambos |data= e |ano=
            local mismatch = year_date_check(A.Year, A.Date)
            if 0 == mismatch then -- |ano= não bate com ano em |data=
                if is_set(error_message) then -- se já tiver mensagem de erro
                    error_message = error_message .. ', '
                end
                error_message = error_message .. '&#124;ano= / &#124;data= mismatch'
            elseif 1 == mismatch then -- |ano= bate com ano em |data=
                add_maint_cat ('date_year')
            end
        end

        if not is_set(error_message) then -- entra nesse escopo apenas se não tiver erro
            local modified = false -- flag
            if is_set (A.DF) then -- se precisar reformatar data
                modified = reformat_dates(date_parameters_list, A.DF, false)
            end

            if true == date_hyphen_to_dash (date_parameters_list) then -- converte hífens para traços
                modified = true;
                add_maint_cat ('date_format') -- hífens convertidos, adicionar categoria
            end

            if modified then -- se date_parameters_list foi modicada, sobrescreve o original
                A.AccessDate = date_parameters_list['acessodata']
                A.ArchiveDate = date_parameters_list['arquivodata']
                A.Date = date_parameters_list['data']
                A.DoiBroken = date_parameters_list['doi-incorrecto']
                A.LayDate = date_parameters_list['resumo-data']
                A.PublicationDate = date_parameters_list['data-publicacao']
            end
        else -- adiciona esta mensagem de erro
            table.insert(z.message_tail, { set_error('bad_date', {error_message}, true)})
        end
    end -- fim do 'do'

    if A.Year:match('^%d%d?$') or A.Year:match('^%d%d?[–%-]%d%d?%d?$') then
        A.Year = A.Year .. '&nbsp;d.C.'
    end

    -- legado: promove PublicationDate para Date se nem Date nem Year forem definidos
    if not is_set (A.Date) then
        A.Date = A.Year -- promove Year para Date
        A.Year = nil -- torna nil assim Year como string vazia não é usado para CITEREF
        if not is_set (A.Date) and is_set(A.PublicationDate) then -- usa PublicationDate se |date= e |year= não foram definidos
            A.Date = A.PublicationDate -- promove PublicationDate para Date
            A.PublicationDate = '' -- não precisa mais
        end
    end

    if A.PublicationDate == A.Date then
        A.PublicationDate = '' -- se PublicationDate for igual Date, não aparecerá
    end

--[[permitir o uso do atributo |pmc= como |url= se vazio e configurado para tal, como em
- {{citar periódico}}. Isso deve ser feito depois de validar data e antes da tabela do COinS.
- Aqui se remove Embargo se PMC não tiver |embargo= ou estar expirado, senão, contém data.]]
    A.Embargo = is_embargoed (A.Embargo)

    if config.permPCMcomoURL and not is_set(A.URL) and is_set(ID_list['PMC']) then
        if not is_set (A.Embargo) then -- se não foi embargado ou se embargo expirou
            A.URL=cfg.id_handlers['PMC'].prefix .. ID_list['PMC'] -- url mesmo que link do PMC
            URLorigin = cfg.id_handlers['PMC'].parameters[1] -- alias para mensagens de erro
            if is_set(A.AccessDate) then -- acessodata requer |url=; o do pmc não vem de |url=
                table.insert(z.message_tail, { set_error('accessdate_missing_url', {}, true)})
                A.AccessDate = '' -- esvaziar
            end

        end
    end

    -- testa se citação não contém título
    if not is_set(A.Title) and not is_set(A.TransTitle)
        and not is_set(A.ScriptTitle) and not config.TituloDispensavel
    then
        table.insert(z.message_tail, { set_error('citation_missing_title', {'título'}, true)})
    end

    check_for_url ({ -- adiciona mensagem de erro quando algum destes parâmetros conter URL
        [A:ORIGIN('Title')]=A.Title,
        [Chapter_origin]=A.Chapter,
        --[A:ORIGIN('Periodical')]=A.Periodical,
        --[A:ORIGIN('PublisherName')] = A.PublisherName
        })

    -- metadados COinS (ver <http://ocoins.info/>) para análise automatizada de informação de citação

    local coins_author = a -- padrão para coins rft.au
    if 0 < #c then -- mas se tem lista de contribuidores
        coins_author = c -- usa ao invés
    end

    -- Tabela com os argumentos a ser usado na função COinS()
    B.coins_table = {
        Periodical = is_parameter_ext_wikilink(A.Periodical) and A.Periodical:match("%[[^%s]*%s*(.*)%]") or A.Periodical,
        Encyclopedia = is_parameter_ext_wikilink(A.Encyclopedia) and A.Encyclopedia:match("%[[^%s]*%s*(.*)%]") or A.Encyclopedia,
        Chapter = make_coins_title (A.Chapter, A.ScriptChapter), -- Chapter e ScriptChapter sem marcações
        Title = make_coins_title (A.Title, A.ScriptTitle), -- Title e ScriptTitle sem marcações
        PublicationPlace = A.PublicationPlace,
        Date = COinS_date.rftdate, -- COinS_date tem data corretamente formatada se Date for valida;
        Season = COinS_date.rftssn,
        Chron =  COinS_date.rftchron or (not COinS_date.rftdate and A.Date) or '', -- chron mas se não definido e formato de data inválido usa Date
        Series = A.Series,
        Volume = A.Volume,
        Issue = A.Issue,
        Pages = get_coins_pages(first_set({A.Page, A.Pages, A.At}, 3)),
        Edition = A.Edition,
        PublisherName = is_parameter_ext_wikilink(A.PublisherName) and A.PublisherName:match("%[[^%s]*%s*(.*)%]") or A.PublisherName,
        URL = first_set ({A.ChapterURL, A.URL}, 2),
        Authors = coins_author,
        ID_list = ID_list,
        RawPage = this_page.prefixedText
    }

    -- agora substitui vários campos, também adiciona espaços, marcações e
    -- pontuações em várias partes da citação, mas apenas se não forem nil
    do
        local last_first_list
        local control = {
            format = A.NameListFormat, -- string vazia ou 'vanc'
            lastauthoramp = A.LastAuthorAmp,
            page_name = this_page.text,
            mode = A.Mode
        } -- maximum = nil, -- se display-authors ou display-editors não definidos

        do -- lista de nomes de editor primeiro porque coautores pode modificar tabela de controle
            control.maximum, editor_etal = get_display_authors_editors(A.DisplayEditors, #e, 'editors', editor_etal)
            last_first_list, B.EditorCount = list_people(control, e, editor_etal)

            if is_set (B.Editors) then
                if editor_etal then
                    B.Editors = B.Editors .. ' ' .. cfg.messages['et al'] -- ad et al. a editores porque |display-editors=etal
                    B.EditorCount = 2 -- com et al., |editors= tem multiplos nomes; mostrar anotação (eds.)
                else
                    B.EditorCount = 2 -- assume que |editors= tem multiplos nomes para mostrar anotação (eds.)
                end
            else
                B.Editors = last_first_list -- ou uma lista de nome de autor ou uma string vazia
            end

            if 1 == B.EditorCount and (true == editor_etal or 1 < #e) then -- exibido apenas um editor, mas inclui et al.
                B.EditorCount = 2 -- para mostrar anotação (eds.)
            end
        end
        do -- agora, tradutores
            control.maximum = #t -- número de tradutores
            Translators = list_people(control, t, false) -- et al não suportado atualmente
        end
        do -- agora, contribuidores
            control.maximum = #c -- número de contribuidores
            B.Contributors = list_people(control, c, false) -- et al não suportado atualmente
        end
        do -- agora, autores
            control.maximum , author_etal = get_display_authors_editors (A['DisplayAuthors'], #a, 'authors', author_etal)

            if is_set(A.Coauthors) then -- se o campo coautor também for usado, previne '&' e et al.
                control.lastauthoramp = nil
                control.maximum = #a + 1
            end

            last_first_list = list_people(control, a, author_etal)

            if is_set (A.Authors) then
                A.Authors, author_etal = name_has_etal (A.Authors, author_etal, false) -- procura e remove variações em et al.
                if author_etal then
                    A.Authors = A.Authors .. ' ' .. cfg.messages['et al'] -- ad et al. a autores
                end
            else
                A.Authors = last_first_list -- ou uma lista de nome de autor ou uma string vazia
            end
        end -- fim do 'do'

        if is_set (A.Authors) and is_set (A.Collaboration) then
            A.Authors = A.Authors .. ' (' .. A.Collaboration .. ')' -- adiciona colaboração depois de et al.
        end

        if not is_set(A.Authors) and is_set(A.Coauthors) then -- coautores não exibidos se não tiver authors=, authorn=, ou lastn=
            table.insert(z.message_tail, { set_error('coauthors_missing_author', {}, true)})
        end
    end

-- aplica estilo |[xx-]format= no fim, tais parâmetros contêm anotações de formato com estilo correto
-- mensagem de erro se não tiver url associado, ou uma string vazia para concatenação
    A.ArchiveFormat = style_format(A.ArchiveFormat, A.ArchiveURL, 'archive-format', 'archive-url')
    A.Format = style_format(A.Format, A.URL, 'format', 'url')
    A.LayFormat = style_format(A.LayFormat, A.LayURL, 'lay-format', 'lay-url')
    A.TranscriptFormat = style_format(A.TranscriptFormat, A.TranscriptURL, 'transcript-format', 'transcripturl')

    -- tratamento especial ao formato de capítulo, assim nenhum erro ou cat se capítulo não suportado
    if not config.ChapterNaoSuportado then
        A.ChapterFormat = style_format (A.ChapterFormat, A.ChapterURL, 'chapter-format', 'chapter-url')
    end

    if not is_set(A.URL) then
        -- tem |accessdate= sem |url= ou |chapter-url= ?
        if is_set(A.AccessDate) and not is_set(A.ChapterURL) then -- pode ter ChapterURL ao invés
            table.insert(z.message_tail, { set_error('accessdate_missing_url', {}, true)})
            A.AccessDate = ''
        end
    end

    local OriginalURL, OriginalURLorigin, OriginalFormat, OriginalAccess
    A.DeadURL = A.DeadURL:lower() -- usado depois quando montar texto de arquivado
    if is_set( A.ArchiveURL ) then
        if is_set (A.ChapterURL) then -- URL não definido, se tem chapter-url aplica archive url nisso
            OriginalURL = A.ChapterURL -- salva cópia para o texto do arquivo
            OriginalURLorigin = ChapterURLorigin -- nome do parâmetro para mensagens de erro
            OriginalFormat = A.ChapterFormat -- |format= original
            if not in_array(A.DeadURL, {'não', 'no', 'live'}) then
                A.ChapterURL = A.ArchiveURL -- alterna o url do arquivo
                ChapterURLorigin = A:ORIGIN('ArchiveURL') -- nome do parâmetro para mensagens de erro
                A.ChapterFormat = A.ArchiveFormat or '' -- alterna o formato do arquivo
            end
        elseif is_set (A.URL) then
            OriginalURL = A.URL -- salva cópia
            OriginalURLorigin = URLorigin -- nome do parâmetro para mensagens de erro
            OriginalFormat = A.Format -- |format= original
            OriginalAccess = A.UrlAccess
            if not in_array(A.DeadURL, {'não', 'no'}) then -- se tem URL, archive-url se aplica
                A.URL = A.ArchiveURL -- alterna o url do arquivo
                URLorigin = A:ORIGIN('ArchiveURL') -- nome do parâmetro para mensagens de erro
                A.Format = A.ArchiveFormat or '' -- alterna o formato do arquivo
                A.UrlAccess = nil -- acessos restrito, não faz sentido usar como URL de arquivo
            end
         end
    end

    -- se capítulo for suportado, formata título de capítulo/artigo
    if not config.ChapterNaoSuportado then
        local no_quotes = false -- por padrão, inserirá aspas angulares
        if is_set (A.Contribution) and 0 < #c then -- se tiver colaborador(es)
            -- e um título de contribuição genérico
            if in_array (A.Contribution:lower(), cfg.keywords.contribution) then
                no_quotes = true -- então não se usará aspas angulares
            end
        end

        A.Chapter = format_chapter_title (A.ScriptChapter, A.Chapter, A.TransChapter, A.ChapterURL, ChapterURLorigin, no_quotes) -- A.Contribution também está em A.Chapter
        if is_set (A.Chapter) then
            A.Chapter = A.Chapter .. A.ChapterFormat
            A.Chapter = A.Chapter.. B.sepc .. ' '
        -- se |chapter= não estiver definido, mas estiver |chapter-format= então ...
        elseif is_set (A.ChapterFormat) then
            A.Chapter = A.ChapterFormat .. B.sepc .. ' '
        end
    end

    -- Formata título pricipal
    if is_set(A.TitleLink) and is_set(A.Title) then
        A.Title = "[[" .. A.TitleLink .. "|" .. A.Title .. "]]"
    end

    if config.TituloFormatado then
        A.Title = config.TituloFormatado.Title or A.Title
        A.TransTitle = config.TituloFormatado.TransTitle or A.TransTitle
    else
        A.Title = wrap_style ('italic-title', A.Title)
        A.TransTitle = wrap_style ('trans-italic-title', A.TransTitle)
    end
    -- <bdi> tags, atributo lang, categorização, etc; deve ser trabalhada após o invólucro do título
    A.Title = script_concatenate (A.Title, A.ScriptTitle)

    local TransError = "";
    if is_set(A.TransTitle) then
        if is_set(A.Title) then
            A.TransTitle = " " .. A.TransTitle;
        else
            TransError = " " .. set_error('trans_missing_title', {'título'})
        end
    end

    A.Title = A.Title .. A.TransTitle

    if is_set(A.Title) then
        if is_set(A.URL) then

            if is_set(A.UrlAccess) then
                if A.UrlAccess:match('^registr?o$') then
                    A.UrlAccess = 'registration'   
                elseif A.UrlAccess == 'subscrição' then
                    A.UrlAccess = 'subscription'
                elseif A.UrlAccess == 'limitada' then
                    A.UrlAccess = 'limited'
                else
                    A.UrlAccess = nil
                end
            end
            A.Title = external_link( A.URL, A.Title, URLorigin, A.UrlAccess ) .. TransError .. A.Format

            -- apagando porque não precisa mais
            A.URL = ''
            A.Format = ""
        else
            A.Title = A.Title .. TransError
        end
    end

    if is_set(A.Place) then
        A.Place = " " .. wrap_msg ('written', A.Place, B.use_lowercase) .. B.sepc .. " "
    end

    if not is_set(B.Position) then
        local Minutes = A['Minutes']
        local Time = A['Time']

        if is_set(Minutes) then
            if is_set (Time) then
                table.insert(z.message_tail, { set_error('redundant_parameters', { wrap_style
                ('parameter', 'minuto') .. ' e ' .. wrap_style ('parameter', 'tempo')}, true )})
            end
            B.Position = wrap_msg('minutes', Minutes, B.use_lowercase)
        else
            if is_set(Time) then
                local TimeCaption = A['TimeCaption']
                if not is_set(TimeCaption) then
                    TimeCaption = cfg.messages['event']
                    if B.use_lowercase then
                        TimeCaption = TimeCaption:lower()
                    end
                end
                B.Position = " " .. TimeCaption .. " " .. Time
            end
        end
    else
        B.Position = " " .. B.Position
        A.At = ''
    end

    A.Page, A.Pages = format_pages(A.Page, A.Pages, B.sepc, A.NoPP, B.use_lowercase, A.TotalPages)

    A.At = is_set(A.At) and (B.sepc .. " " .. A.At) or ""
    B.Position = is_set(B.Position) and (B.sepc .. " " .. B.Position) or ""

    if is_set (A.Language) then
        A.Language = language_parameter(A.Language) -- formato, categorias, nome de ISO639-1, etc
    else
        A.Language="" -- língua não especificada, certificar que a variável seja uma string vazia
    end

    A.Others = is_set(A.Others) and (B.sepc .. " " .. A.Others) or ""

    if is_set (Translators) then
        if 'mla' == A.Mode then
            A.Others = B.sepc .. ' Trad. ' .. Translators .. A.Others
        else
            A.Others = B.sepc .. ' ' .. wrap_msg('translated', Translators, B.use_lowercase) .. A.Others
        end
    end

    A.TitleNote = is_set(A.TitleNote) and (B.sepc .. " " .. A.TitleNote) or ""
    if is_set (A.Edition) then
        if A.Edition:match ('%f[%a][Ee]d%.?$') or A.Edition:match ('%f[%a][Ee]dição$') then
            add_maint_cat ('extra_text', 'edition')
        end
        if 'mla' == A.Mode then
            A.Edition = '. ' .. A.Edition .. ' ed.'
        else
            A.Edition = " " .. wrap_msg ('edition', A.Edition) .. " "
        end
    else
        A.Edition = ''
    end

    A.Series = is_set(A.Series) and (B.sepc .. " " .. A.Series) or ""
    if 'mla' == A.Mode then -- sem colchetes para mla
        A.OrigYear = is_set(A.OrigYear) and (". " .. A.OrigYear) or ""
    else
        A.OrigYear = is_set(A.OrigYear) and (" [" .. A.OrigYear .. "]") or ""
    end
    A.Agency = is_set(A.Agency) and (B.sepc .. " " .. A.Agency) or ""

    A.Volume = format_volume_issue (A.Volume, A.Issue, B.sepc, B.use_lowercase)

    ------------------------------------ dado completamente não relacionado
    if is_set(A.Via) then
        A.Via = " " .. wrap_msg ('via', A.Via)
    end

--[[
Subscrição pode requerer pagamento; registro não. Se ambos são usados na citação, uma
nota de que o link requer subscrição é mostrado. Não há mensagens de erro por isso.
]]
    if is_set (A.SubscriptionRequired) then -- aviso de que requer subscrição
        A.SubscriptionRequired = B.sepc .. " " .. cfg.messages['subscription']
    elseif is_set (A.RegistrationRequired) then -- aviso de que requer registro
        A.SubscriptionRequired = B.sepc .. " " .. cfg.messages['registration']
    else -- um deles ou ambos provavelmente está com outro valor além de sim, true...
        A.SubscriptionRequired = ''
    end

    if is_set(A.AccessDate) then
        local retrv_text = " " .. cfg.messages['retrieved']

        A.AccessDate = nowrap_date(A.AccessDate)
        if 'mla' == A.Mode then -- texto recuperado não usado em mla
            A.AccessDate = ' ' .. A.AccessDate
        else
            if (B.use_lowercase) then retrv_text = retrv_text:lower() end -- if cs2, caixa baixa
            A.AccessDate = substitute(retrv_text, A.AccessDate) -- adiciona texto recuperado
        end
        A.AccessDate = substitute(cfg.presentation['accessdate'], {B.sepc, A.AccessDate})
    end

    if is_set(A.ID) then
        A.ID = B.sepc .." ".. A.ID
    end

    ID_list = build_id_list(ID_list, {IdAccessLevels=ID_access_levels, DoiBroken = A.DoiBroken, ASINTLD = A.ASINTLD, IgnoreISBN = A.IgnoreISBN, Embargo=A.Embargo, Class = A.Class})

    if is_set(A.URL) then
        A.URL = " " .. external_link( A.URL, nil, URLorigin, Access )
    end

    if is_set(A.Quote) then
        if A.Quote:sub(1,1) == '"' and A.Quote:sub(-1,-1) == '"' then -- vê se tem aspas
            A.Quote = A.Quote:sub(2,-2) -- arranca fora se tiver
        end
        A.Quote = B.sepc .." " .. wrap_style ('quoted-text', A.Quote ) -- põe tags <q>...</q>
        B.PostScript = "" -- cs1|2 não fornece pontuação final quando |quote= está definido
    end

    local Archived
    if is_set(A.ArchiveURL) then
        if not is_set(A.ArchiveDate) then
            A.ArchiveDate = set_error('archive_missing_date')
        end
        if in_array(A.DeadURL, {'não', 'no'}) then
            local arch_text = cfg.messages['archived']
            if B.sepc ~= "." then arch_text = arch_text:lower() end
            Archived = B.sepc .. " " .. external_link( A.ArchiveURL, substitute(cfg.messages['archived-not-dead'],
                {  arch_text .. A.ArchiveFormat, A.ArchiveDate }), A:ORIGIN('ArchiveURL'), nil )
            if not is_set(OriginalURL) then
                Archived = Archived .. " " .. set_error('archive_missing_url')
            end
        elseif is_set(OriginalURL) then
            local arch_text = cfg.messages['archived-dead']
            if B.use_lowercase then arch_text = arch_text:lower() end
            if in_array (A.DeadURL, {'unfit', 'usurped', 'bot: unknown'}) then
                Archived = B.sepc .. " " .. 'Arquivado do original em ' .. A.ArchiveDate -- formato já estilizado
                if 'bot: unknown' == A.DeadURL then
                    add_maint_cat ('bot:_unknown') -- adiciona uma categoria, se já não estiver
                else
                    add_maint_cat ('unfit') -- adiciona uma categoria, se já não estiver
                end
            else -- A.DeadURL está vazio, 'sim', 'true'...
                Archived = B.sepc .. " " .. substitute( arch_text,
                    { external_link( OriginalURL, cfg.messages['original'], OriginalURLorigin, OriginalAccess ) .. OriginalFormat, A.ArchiveDate }) -- formato já estilizado
            end
        else
            local arch_text = cfg.messages['archived-missing']
            if B.use_lowercase then arch_text = arch_text:lower() end
            Archived = B.sepc .. " " .. substitute(arch_text,
                { set_error('archive_missing_url'), A.ArchiveDate })
        end
        A.DeadURL = ''
    elseif is_set (A.ArchiveFormat) then
        Archived = A.ArchiveFormat -- ArchiveURL não está definido ArchiveFormat tem mensagem de erro
    else
        Archived = ""
    end

    local Lay = ''
    if is_set(A.LayURL) then
        if is_set(A.LayDate) then A.LayDate = " (" .. A.LayDate .. ")" end
        if is_set(A.LaySource) then
            A.LaySource = " &ndash; ''" .. safe_for_italics(A.LaySource) .. "''"
        else
            A.LaySource = ""
        end
        if B.sepc == '.' then
            Lay = B.sepc .. " " .. external_link(A.LayURL, cfg.messages['lay summary']
                , A:ORIGIN('LayURL'), nil) .. A.LayFormat .. A.LaySource .. A.LayDate
        else
            Lay = B.sepc .. " " .. external_link(A.LayURL, cfg.messages['lay summary']:lower()
                , A:ORIGIN('LayURL'), nil) .. A.LayFormat .. A.LaySource .. A.LayDate
        end
    elseif is_set (A.LayFormat) then -- testa se |lay-format= esta sem |lay-url=
        Lay = B.sepc .. A.LayFormat -- se LayURL não está definido, LayFormat tem mensagem de erro
    end

    if is_set(A.Transcript) then
        if is_set(A.TranscriptURL) then
            A.Transcript = external_link( A.TranscriptURL, A.Transcript, TranscriptURLorigin, nil )
        end
        A.Transcript = B.sepc .. ' ' .. A.Transcript .. A.TranscriptFormat
    elseif is_set(A.TranscriptURL) then
        A.Transcript = external_link( A.TranscriptURL, nil, TranscriptURLorigin, nil )
    end

    if is_set(A.PublicationDate) then
        A.PublicationDate = wrap_msg ('published', A.PublicationDate)
    end
    if is_set(A.PublisherName) then
        if is_set(A.PublicationPlace) then
            B.Publisher = B.sepc .. " " .. A.PublicationPlace .. ": "
                .. A.PublisherName .. A.PublicationDate
        else
                B.Publisher = B.sepc .. " " .. A.PublisherName .. A.PublicationDate
        end
    elseif is_set(A.PublicationPlace) then
        B.Publisher= B.sepc .. " " .. A.PublicationPlace .. A.PublicationDate
    else
        B.Publisher = A.PublicationDate
    end

    if is_set(A.Periodical) then
        if is_set(A.Title) or is_set(A.TitleNote) then
            A.Periodical = B.sepc .. " " .. wrap_style ('italic-title', A.Periodical)
        else
            A.Periodical = wrap_style ('italic-title', A.Periodical)
        end
    end


    -- Piece all bits together at last.  Here, all should be non-nil.
    -- We build things this way because it is more efficient in LUA
    -- not to keep reassigning to the same string variable over and over.

    if 'mla' == A.Mode then
        B.tcommon = safe_join( {A.TitleNote, A.Periodical, A.Format, A.TitleType, A.Series
            , A.Language, A.Edition, B.Publisher, A.Agency}, B.sepc )
    else -- todos as outras predefinições CS1
        B.tcommon = safe_join({A.Title, A.TitleNote, A.Periodical, A.Format, A.TitleType
        , A.Series, A.Language, A.Volume, A.Others, A.Edition, B.Publisher, A.Agency}, B.sepc)
    end

    if #ID_list > 0 then
        ID_list = safe_join({ B.sepc .. " ", table.concat(ID_list, B.sepc .. " " ), A.ID }, B.sepc)
    else
        ID_list = A.ID
    end

    B.idcommon = safe_join({ ID_list, A.URL, A.AccessDate, Archived, A.Via, A.SubscriptionRequired, Lay, A.Quote }, B.sepc)

    if is_set(A.Date) then
        if ('mla' == A.Mode) then
                A.Date = ', ' .. A.Date  -- origyear segue título em mla
        elseif is_set (A.Authors) or is_set (B.Editors) then -- data segue autores ou editores
            A.Date = " (" .. A.Date ..")" .. A.OrigYear .. B.sepc .. " " -- in parentheses
        else -- nem autores nem editores definidos
            if (string.sub(B.tcommon,-1,-1) == B.sepc) then -- se o último caractere for sepc
                A.Date = " " .. A.Date .. A.OrigYear -- data não começa com sepc
            else -- data começa com sepc
                A.Date = B.sepc .. " " .. (B.use_lowercase and A.Date
                    or (A.Date:sub(1, 1):upper() .. A.Date:sub(2))) .. A.OrigYear
            end
        end
    end
    B.a = a
    B.c = c
    B.e = e
    return A, B
end

--[[--------------------------< t e x t o F i n a l >---------------------------------------------
Esta função serve para retornar o resultado final de todo o processo à
função inicial
]]
function textoFinal(A, B)
    local text
    local pgtext = B.Position .. A.Page .. A.Pages .. A.At

    -- esta é a chamada da função para COinS()
    local OCinSoutput = COinS(B.coins_table, B.config.CitationClass)

    if is_set(A.Authors) then
        if is_set(A.Coauthors) then
            if 'vanc' == A.NameListFormat then -- separa autores e coautores com separador apropriado
                A.Authors = A.Authors .. ', ' .. A.Coauthors
            else
                A.Authors = A.Authors .. '; ' .. A.Coauthors
            end
        end
        if (not is_set (A.Date)) or ('mla' == A.Mode) then -- quando tem data, está entre parêntesis; sem concluir autores
            A.Authors = terminate_name_list (A.Authors, B.sepc) -- sem data, termina com 0 ou 1 sepc e um espaço
        end
        if is_set(B.Editors) then
            local in_text = " ";
            local post_text = "";
            if is_set(A.Chapter) and 0 == #B.c and 'mla' ~= A.Mode then
                in_text = cfg.messages['in'] .. " " .. in_text
                if (B.use_lowercase) then in_text = in_text:lower() end -- caixa baixa para cs2
            elseif is_set(A.Chapter) and 'mla' == A.Mode then
                if B.EditorCount <= 1 then
                    in_text = '. Ed. '
                else
                    in_text = '. Eds. '
                end
            else
                if B.EditorCount <= 1 then
                    post_text = ", " .. cfg.messages['editor']
                else
                    post_text = ", " .. cfg.messages['editors']
                end
            end
            B.Editors = terminate_name_list (in_text .. B.Editors .. post_text, B.sepc) -- termina com 0 ou 1 sepc e um espaço
        end
        if is_set (B.Contributors) then -- citação de livro quando citar intro, prefácio, etc
            local by_text = B.sepc .. ' ' .. cfg.messages['by'] .. ' '
            if (B.use_lowercase) then by_text = by_text:lower() end -- caixa baixa para cs2
            A.Authors = by_text .. A.Authors -- autor segue título, então puxa pra cá
            if is_set (B.Editors) and ('mla' ~= A.Mode)then                                            -- quando tem editores, certificar que autores está concluído
                A.Authors = terminate_name_list (A.Authors, B.sepc) -- termina com 0 ou 1 sepc e um espaço
            end
            if (not is_set (A.Date)) or ('mla' == A.Mode) then -- quando tem data, está entre parêntesis; sem concluir contribuidores
                B.Contributors = terminate_name_list (B.Contributors, B.sepc) -- termina com 0 ou 1 sepc e um espaço
            end
            if 'mla' == A.Mode then
                text = safe_join({ B.Contributors, A.Chapter, B.tcommon, A.OrigYear, A.Authors, A.Place, A.Others, B.Editors, B.tcommon2, A.Date, pgtext, B.idcommon }, B.sepc)
            else
                text = safe_join({ B.Contributors, A.Date, A.Chapter, B.tcommon, A.Authors, A.Place, B.Editors, B.tcommon2, pgtext, B.idcommon }, B.sepc)
            end
        elseif 'mla' == A.Mode then
            B.tcommon = B.tcommon .. A.Date -- para evitar separador duplicado
            text = safe_join({ A.Authors, A.Chapter, A.Title, A.OrigYear, A.Others, B.Editors, A.Edition, A.Place, B.tcommon, pgtext, B.idcommon }, B.sepc)
        else
            text = safe_join({ A.Authors, A.Date, A.Chapter, A.Place, B.Editors, B.tcommon, pgtext, B.idcommon }, B.sepc)
        end
    elseif is_set(B.Editors) then
        if is_set(A.Date) then
            if B.EditorCount <= 1 then
                B.Editors = B.Editors .. ", " .. cfg.messages['editor']
            else
                B.Editors = B.Editors .. ", " .. cfg.messages['editors']
            end
        else
            if B.EditorCount <= 1 then
                B.Editors = B.Editors .. " (" .. cfg.messages['editor'] .. ")" .. B.sepc .. " "
            else
                B.Editors = B.Editors .. " (" .. cfg.messages['editors'] .. ")" .. B.sepc .. " "
            end
        end
        if 'mla' == A.Mode then
            if in_array(B.config.CitationClass, {'journal', 'news', 'web'}) and is_set(A.Periodical) then
                text = safe_join( {B.Editors, A.Title, A.Place, B.tcommon, pgtext, A.Date, B.idcommon}, B.sepc )
            else
                text = safe_join( {B.Editors, A.Chapter, A.Title, A.Place, B.tcommon, A.Date, pgtext, B.idcommon}, B.sepc )
            end
        else
            text = safe_join( {B.Editors, A.Date, A.Chapter, A.Place, B.tcommon, pgtext, B.idcommon}, B.sepc )
        end
    elseif 'mla' == A.Mode then
        text = safe_join({A.Chapter, A.Title, A.Place, B.tcommon, A.Date, pgtext, B.idcommon}, B.sepc)
    else
        if in_array(B.config.CitationClass, {"journal","citation"}) and is_set(A.Periodical) then
            text = safe_join( {A.Chapter, A.Place, B.tcommon, pgtext, A.Date, B.idcommon}, B.sepc )
        else
            text = safe_join( {A.Chapter, A.Place, B.tcommon, A.Date, pgtext, B.idcommon}, B.sepc )
        end
    end

    if is_set(B.PostScript) and B.PostScript ~= B.sepc then
        text = safe_join( {text, B.sepc}, B.sepc ) -- lida com espaços, itálicos etc.
        text = text:sub(1,-B.sepc:len()-1)
    end

    text = (safe_join( {text, B.PostScript}, B.sepc )):match(("%".. B.sepc .."?%s?(.*)$"))

    if is_set(A.DeadURL) and not in_array(A.DeadURL, {'não', 'no'}) then
        local data = A.DeadURL:match('([%aç]+ de %d%d%d%d)')
        text = text .. ' [[Wikipédia:Ligação inativa|<sup'.. (data and (' title="Constatado que a ligação está inativa em: '
            .. data .. '"') or '') .. '>\'\'[ligação inativa]\'\'</sup>]]'
        table.insert( z.error_categories, '!Artigos com ligações externas inativas')
        --table.insert( z.error_categories, '!Artigos com citações quebradas')
    end

    -- agora põe tudo num elemento <cite/>
    local options = {};

    if is_set(B.config.CitationClass) and B.config.CitationClass ~= "citation" then
        options.class = B.config.CitationClass
        -- class=citation requerido para realçar de azul quando usado |ref=
        options.class = "citation " .. B.config.CitationClass
    else
        options.class = "citation"
    end

    -- define a âncora da referencia, caso for apropriado
    if is_set(B.Ref) and B.Ref:lower() ~= "none" then
        local id = B.Ref
        if ('harv' == B.Ref ) then
            local namelist = {} -- a conter lista de nomes de contribuidor, autor ou editor
            local year = first_set ({A.Year, B.anchor_year}, 2)

            if #B.c > 0 then -- se houver uma lista de contribuidores
                namelist = B.c -- seleciona-o
            elseif #B.a > 0 then -- ou uma lista de autores
                namelist = B.a
            elseif #B.e > 0 then -- ou uma lista de editores
                namelist = B.e
            end
            if #namelist > 0 then -- se houver nomes na lista
                id = anchor_id (namelist, year) -- construirá a âncora CITEREF
            else
                id = ''
            end
        end
        options.id = id
    end

    -- remove tags <span> e outras marcações html; então obter o tamanho do que restar
    if string.len(text:gsub("<span[^>/]*>(.-)</span>", "%1"):gsub("%b<>","")) <= 2 then
        z.error_categories = {};
        text = set_error('empty_citation');
        z.message_tail = {};
    end

    if is_set(options.id) then -- por a citação renderizada dentro das tags <cite ...>...</cite>
        text = substitute(cfg.presentation['cite-id'], {mw.uri.anchorEncode(options.id)
            , mw.text.nowiki(options.class), text}) -- quando |ref= estiver definido
    else
        text = substitute(cfg.presentation['cite'], {mw.text.nowiki(options.class), text}) -- sem |ref=
    end

    text = text .. substitute(cfg.presentation['ocins'], {OCinSoutput}) -- acrescenta metadados à citação

    if #z.message_tail ~= 0 then
        text = text .. " "
        for i,v in ipairs( z.message_tail ) do
            if is_set(v[1]) then
                if i == #z.message_tail then
                    text = text .. error_comment( v[1], v[2] )
                else
                    text = text .. error_comment( v[1] .. "; ", v[2] )
                end
            end
        end
    end

    if #z.maintenance_cats ~= 0 then
        text = text .. '<span class="citation-comment" style="display:none; color:#33aa33">'
        for _, v in ipairs( z.maintenance_cats ) do -- acrescenta categorias de manutenção
            text = text .. ' ' .. v .. ' ([[:Categoria:' .. v ..'|link]])'
        end
        text = text .. '</span>'
    end

    A.NoTracking = A.NoTracking:lower();
    if in_array(A.NoTracking, {"", "no", "false", "n"}) then
        for _, v in ipairs( z.error_categories ) do
            text = text .. '[[Categoria:' .. v ..']]'
        end
        for _, v in ipairs( z.maintenance_cats ) do -- acrescenta categorias de manutenção
            text = text .. '[[Categoria:' .. v ..']]'
        end
        for _, v in ipairs( z.properties_cats ) do -- acrescenta categorias de manutenção
            text = text .. '[[Categoria:' .. v ..']]'
        end
    end

    return text
end

--[[--------------------------< tratarArgumentos >-----------------------------------------
Esta função serve para trarar os argumentos recebidos por parâmetro antes de
serem processados
]]
function tratarArgumentos(frame)
    -- salva uma cópia em caso de precisar mostrar uma mensagem de erro no modo "prever"
    Frame = frame
    local pframe = frame:getParent()
    local validation, utilities, identifiers, metadata

    -- verifica se é teste
    local tmp = string.find (frame:getTitle(), 'Testes', 1, true) and "/Testes" or ""
    cfg = require ('Módulo:Citação/CS1/Configuração' .. tmp)
    whitelist = require ('Módulo:Citação/CS1/Whitelist' .. tmp)
    utilities = require ('Módulo:Citação/CS1/Utilidades' .. tmp)
    validation = require ('Módulo:Citação/CS1/ValidaçãoDatas' .. tmp)
    identifiers = require ('Módulo:Citação/CS1/Identificadores' .. tmp)
    metadata = require ('Módulo:Citação/CS1/COinS' .. tmp)

    if frame.whitelist then -- facilita uso de parâmetros em módulos locais
        local tmpWhite = frame.whitelist
        tmpWhite.__index = tmpWhite
        whitelist.basic_arguments = setmetatable(whitelist.basic_arguments, tmpWhite)
        if tmpWhite.numWhitelist then
            tmpWhite.numWhitelist.__index = tmpWhite.numWhitelist
            whitelist.numbered_arguments = setmetatable(whitelist.numbered_arguments, tmpWhite.numWhitelist)
        end
    end

    -- para que as funções em Utilidades possam ver as tabelas em cfg
    utilities.set_selected_modules (cfg)
    -- para que as funções em Identificadores possam ver as tabelas de cfg selecionadas e o módulo Utilidades
    identifiers.set_selected_modules (cfg, utilities)
    -- para que as funções em ValidaçãoDatas possam ver o módulos Utilidades selecionado
    validation.set_selected_modules (utilities)
    -- para que as funções em COinS possam ver as tabelas de cfg selecionadas e o módulo Utilidades
    metadata.set_selected_modules (cfg, utilities)

    --  Teste validação datas
    dates = validation.dates -- importa funções de Módulo:Citação/CS1/ValidaçãoDatas
    year_date_check = validation.year_date_check
    reformat_dates = validation.reformat_dates
    date_hyphen_to_dash = validation.date_hyphen_to_dash

    is_set = utilities.is_set -- importa funções de Módulo:Citação/CS1/Utilidades
    in_array = utilities.in_array
    substitute = utilities.substitute
    error_comment = utilities.error_comment
    set_error = utilities.set_error
    select_one = utilities.select_one
    add_maint_cat = utilities.add_maint_cat
    wrap_style = utilities.wrap_style
    safe_for_italics = utilities.safe_for_italics
    remove_wiki_link = utilities.remove_wiki_link

    z = utilities.z -- tabela de erro e tabelas de categorias em Módulo:Citação/CS1/Utilidades

    extract_ids = identifiers.extract_ids -- importa funções de Módulo:Citação/CS1/Utilidades
    build_id_list = identifiers.build_id_list
    is_embargoed = identifiers.is_embargoed
    extract_id_access_levels = identifiers.extract_id_access_levels

    make_coins_title = metadata.make_coins_title -- importa funções de Módulo:Citação/CS1/COinS
    get_coins_pages = metadata.get_coins_pages
    COinS = metadata.COinS

    local args = {}
    local suggestions = {}
    local error_text, error_state

    local config = {}
    for k, v in pairs( frame.args ) do
        config[k] = v
        args[k] = v
    end

    local capture -- a única captura suportada quando encontrado parâmetro desconhecido
    for k, v in pairs( pframe.args ) do
        if v ~= '' then
            if not validate( k ) then
                error_text = "";
                if type( k ) ~= 'string' then
                    -- Exclui parâmetros numéricos vazios
                    if v:match("%S+") ~= nil then
                        error_text, error_state = set_error( 'text_ignored', {v}, true )
                    end
                elseif validate( k:lower() ) then
                    error_text, error_state = set_error( 'parameter_ignored_suggest', {k, k:lower()}, true )
                else
                    -- se esta tabela for nil então precisa caregar isso
                    if nil == suggestions.suggestions then
                        suggestions = mw.loadData(('Módulo:Citação/CS1/Sugestões' .. tmp))
                    end
                    -- laço sobre o "patterns" para ver o se pode-se sugerir um parâmetro apropriado
                    for pattern, param in pairs (suggestions.patterns) do
                        --[[ pega a captura que corresponde ao modelo (pattern), ou senão
                         pega todo o texto caso a captura não corresponda ao modelo]]
                        capture = k:match (pattern)
                        -- se o modelo confere
                        if capture then
                            -- adiciona a captura ao parâmetro sugerido (normalmente o enumerador)
                            param = substitute( param, capture )
                            error_text, error_state = set_error( 'parameter_ignored_suggest', {k, param}, true ) -- define a mensagem de erro
                        end
                    end
                    -- não corresponde ao modelo, há alguma sugestão explícita?
                    if not is_set (error_text) then
                        if suggestions.suggestions[ k:lower() ] ~= nil then
                            error_text, error_state = set_error( 'parameter_ignored_suggest', {k, suggestions.suggestions[ k:lower() ]}, true )
                        else
                            error_text, error_state = set_error( 'parameter_ignored', {k}, true )
                        end
                    end
                end
                if error_text ~= '' then
                    table.insert( z.message_tail, {error_text, error_state} )
                end
            end
            -- será que há algum parâmetro precisando de um pipe?
            missing_pipe_check (v)

            args[k] = v
        elseif args[k] ~= nil or (k == 'postscript') then
            args[k] = v
        end
    end

    for k, v in pairs( args ) do
        -- não avalia parâmetros posicionais
        if 'string' == type (k) then
            has_invisible_chars (k, v)
        end
    end

    --[[
    Carrega os parâmetros de entrada. A função argument_wrapper facilita
    o mapeamento de múltiplos aliases para uma única variável interna.
    ]]
    local A = argument_wrapper( args )
    if is_set (A.NoPP) and is_valid_parameter_value (A.NoPP, 'nopp', cfg.keywords ['yes_true_y_sim_s']) then
        A.NoPP = true;
    else
        A.NoPP = nil;                                                                -- unset, used as a flag later
    end

    if is_set(A.Pages) then
        -- se pages é apenas dígitos, assume-se que é o número total de páginas
        if tonumber(A.Pages) then
            A.TotalPages = A.Pages
            A.Pages = ''
        end
    end
    if is_set(A.Page) then
        if is_set(A.Pages) or is_set(A.At) then
            A.Pages = ''
            A.At = ''
        end
        extra_text_in_page_check(A.Page) -- ad esta página para maint cat se |pages= começa com algo como p. or pp.
    elseif is_set(A.Pages) then
        if is_set(A.At) then
            A.At = ''
        end
        extra_text_in_page_check(A.Pages) -- ad esta página para maint cat se |pages= começa com algo como p. or pp.
    end

    if is_set(A.Wayb) then
        if is_set(A.ArchiveDate) then
            table.insert( z.message_tail, { set_error('redundant_parameters', {wrap_style ('parameter', A:ORIGIN('Wayb')) .. ' e ' .. wrap_style ('parameter', A:ORIGIN('ArchiveDate'))}, true )});
        end
        if is_set(A.ArchiveURL) then
            table.insert( z.message_tail, { set_error('redundant_parameters', {wrap_style ('parameter', A:ORIGIN('Wayb')) .. ' e ' .. wrap_style ('parameter', A:ORIGIN('ArchiveURL'))}, true )});
        end

        if tonumber(A.Wayb) and A.Wayb:len() > 7 then
            if is_set(A.URL) then
                A.ArchiveURL = 'http://web.archive.org/web/' .. A.Wayb .. '/' .. A.URL
                A.ArchiveDate = (A.Wayb:sub(7, 8) ..'-'.. A.Wayb:sub(5, 6) ..'-'.. A.Wayb:sub(1, 4))
            else
                table.insert(z.message_tail, { set_error('wayb_missing_url')})
            end
        else
            table.insert(z.message_tail, { set_error('invalid_param_val'
                , {A:ORIGIN('Wayb'), A.Wayb}, true)})
        end
    end

    return config, args, A
end

--[[--------------------------< C S 1 . C I T A T I O N >----------------------------------------
Esta função é usada nas predefinições de citação em geral para criar
um texto de citação.
]]
function cs1.citation(frame)
    local config, args, A = tratarArgumentos(frame)
    local B

    A, B = citation0(config, args, A)

    B.config = config
    return textoFinal(A, B)
end

return cs1