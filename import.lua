local public = {}

-- <module> <fields...> <format>
local function import(mod, str_fields, fmt)
	local fmt = fmt or "%s"
	assert(mod, "missing argument <module>")
	local r = {}
	for field in str_fields:gmatch("([^%s,]+)") do
		local field = fmt:format(field)
		assert(mod[field], ("Field %s is empty"):format(field))
		r[#r+1] = mod[field]
	end
	return unpack(r)
end

public.import = import
return public

---- sample of use :
--  local mod = require("mod")
--  local a, b, c, d = import(mod,
--  [[	  a, b, c, d ]])

--  local mod = require("mod")
--  local a, b, c, d = import(mod,
--  [[    a, b, c, d ]], "prefix_%s")
-- in case of local a = mod.prefix_a


