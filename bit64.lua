-- Lua unsigned 64bit emulated bitwises

--
-- I (TsT) decided to fork, improve, and provide a clean lua module
-- License: same than the Lua one

--
-- Original version : by Chessforeva Dev
-- no email or way found to contact the author
-- License: unknow license
-- source: http://stackoverflow.com/questions/3104722/does-lua-make-use-of-64-bit-integers
-- edited Sep 7 '11 at 12:20 ; answered Sep 7 '11 at 12:04
-- Original comment : Slow. But it works.
--	Profile: http://stackoverflow.com/users/932664/chessforeva-dev
--	Website: chessforeva.blogspot.com

-- TsT's changes :
-- . put every functions to local space, inside a module
-- . rename functions name to the same than the (32bits) "bit" module
--	i64_not -> *.bnot
--	i64_and -> *.band
--	i64_or  -> *.bor
--	i64_xor -> *.bxor
-- . manage as object with all meta function associated

-- TODO:
-- - detect platform (32/64bits native support) to fallback to native support if >=64bits
-- - create bit64 object with metatable including operators... to use a:rshift(b) instead of rshift(a, b)

local public = {}
local bit = require("bit")
--local tobit, tohex, bnot, band, bor, bxor, lshift, rshift, arshift, rol, ror, bswap =
--	bit.tobit, bit.tohex, bit.bnot, bit.band, bit.bor, bit.bxor, bit.lshift, bit.rshift, bit.arshift, bit.rol, bit.ror, bit.bswap

-- import here the local name
-- local bxor = bit.bxor
-- ...

-- Lua unsigned 64bit emulated bitwises
-- Slow. But it works.

local
function ugly_test()
	local test = ("%x"):format(0xFFFFFFFFFFFFF)
	if test == "fffffffffffff" then
		return 64
	elseif test == "0" then
		return 32
	else
		return -1
	end
end

local
function i64(v)
	local o = {}
	o.l = v
	o.h = 0
	return o
end -- constructor +assign 32-bit value

local
function i64_ax(h,l)
	local o = {}
	o.l = l
	o.h = h
	return o
end -- +assign 64-bit v.as 2 regs

local
function i64_new(s)
	if type(s) == "number" then
		return bit.tobit(s)
	end
	local s = s:gsub("^0x", "", 1)
	if #s <= 16 and s:match("^%x+$") then
		local l = tonumber("0x"..s:sub(-16,-9))
		local h = tonumber("0x"..s:sub( -8,-1))
		return i64_ax(l,h)
	end
end

local
function i64u(x)
	return ( ( (bit.rshift(x,1) * 2) + bit.band(x,1) ) % (0xFFFFFFFF+1))
end -- keeps [1+0..0xFFFFFFFFF]

local
function i64_clone(x)
	local o = {}
	o.l = x.l
	o.h = x.h
	return o
end -- +assign regs

-- Type conversions

local
function i64_toInt(a)
	return (a.l + (a.h * (0xFFFFFFFF+1)))
end -- value=2^53 or even less, so better use a.l value

local
function i64_toString(a)
	local al = (a.l % (0xFFFFFFFF+1)) -- bugfix in case of value > 32bits
	local ah = (a.h % (0xFFFFFFFF+1)) -- bugfix in case of value > 32bits
	return ("0x%0.8X%0.8X"):format(ah,al)
end

-- Bitwise operators (the main functionality)

local
function i64_band(a,b)
	local o = {}
	o.l = i64u( bit.band(a.l, b.l) )
	o.h = i64u( bit.band(a.h, b.h) )
	return o
end

local
function i64_bor(a,b)
	local o = {}
	o.l = i64u( bit.bor(a.l, b.l) )
	o.h = i64u( bit.bor(a.h, b.h) )
	return o
end

local
function i64_bxor(a,b)
	local o = {}
	o.l = i64u( bit.bxor(a.l, b.l) )
	o.h = i64u( bit.bxor(a.h, b.h) )
	return o
end

local
function i64_bnot(a)
	local o = {}
	o.l = i64u( bit.bnot(a.l) )
	o.h = i64u( bit.bnot(a.h) )
	return o
end

local
function i64_neg(a) -- "__unm" ?
	return i64_add( i64_bnot(a), i64(1) )
end  -- negative is inverted and incremented by +1

-- Simple Math-functions

-- just to add, not rounded for overflows
local
function i64_add(a,b) -- "__add"
	local o = {}
	o.l = a.l + b.l
	local r = o.l - 0xFFFFFFFF
	o.h = a.h + b.h
	if r > 0 then
		o.h = o.h + 1
		o.l = r-1
	end
	return o
end

-- verify a>=b before usage
local
function i64_sub(a,b) -- "__sub" ?
	local o = {}
	o.l = a.l - b.l
	o.h = a.h - b.h
	if( o.l<0 ) then
		o.h = o.h - 1
		o.l = o.l + 0xFFFFFFFF+1
	end
	return o
end

-- x n-times
local
function i64_by(a,n) -- "__mul"
	local o = {}
	o.l = a.l
	o.h = a.h
	for i=2, n, 1 do
		o = i64_add(o,a)
	end
	return o
end
-- no divisions

-- Bit-shifting

local
function i64_lshift(a,n)
	local o = {}
	if(n==0) then
		o.l=a.l
		o.h=a.h
	else
		if(n<32) then
			o.l = i64u( bit.lshift( a.l, n) )
			o.h = i64u( bit.lshift( a.h, n) )+ bit.rshift(a.l, (32-n))
		else
			o.l = 0
			o.h = i64u( bit.lshift( a.l, (n-32)))
		end
	end
	return o
end

local
function i64_rshift(a,n)
	local o = {}
	if(n==0) then
		o.l=a.l
		o.h=a.h
	else
		if(n<32) then
			o.l = bit.rshift(a.l, n)+i64u( bit.lshift(a.h, (32-n)))
			o.h = bit.rshift(a.h, n)
		else
			o.l = bit.rshift(a.h, (n-32))
			o.h = 0
		end
	end
	return o
end

local
function i64_arshift(a,n)
	error("not implemented")
end

local
function i64_rol(a, n)
	error("not implemented")
end

local
function i64_ror(a, n)
	error("not implemented")
end

local
function i64_bswap(a)
	error("not implemented")
	-- 32bits:	afbeadde -> deadbeaf
	--		11223344 -> 44332211
	--		12 34 56 78 -> 78 56 34 12
	-- 64bits:	fecaefbeafdeedfe -> feeddeafbeefcafe
	--		12 34 56 78 87 65 43 21 -> 21 43 65 87 78 56 34 12
	-- source:
	-- http://stackoverflow.com/questions/105252/how-do-i-convert-between-big-endian-and-little-endian-values-in-c
end

-- Comparisons

local
function i64_eq(a,b)
	return ((a.h == b.h) and (a.l == b.l))
end

local
function i64_ne(a,b)
	return ((a.h ~= b.h) or (a.l ~= b.l))
end

local
function i64_gt(a,b)
	return ((a.h > b.h) or ((a.h == b.h) and (a.l >  b.l)))
end

local
function i64_ge(a,b)
	return ((a.h > b.h) or ((a.h == b.h) and (a.l >= b.l)))
end

local
function i64_lt(a,b)
	return ((a.h < b.h) or ((a.h == b.h) and (a.l <  b.l)))
end

local
function i64_le(a,b)
	return ((a.h < b.h) or ((a.h == b.h) and (a.l <= b.l)))
end


-- bit.tobit, bit.tohex,
-- i64, i64_ax, i64_new, i64u, i64_clone,
-- i64_toInt, i64_toString,

-- bit.bnot, bit.band, bit.bor, bit.bxor,
-- i64_bnot, i64_band, i64_bor, i64_bxor,

-- bit.lshift, bit.rshift, bit.arshift, bit.rol, bit.ror, bit.bswap
-- i64_lshift, i64_rshift, i64_arshift, i64_rol, i64_ror, i64_bswap

-- i64_neg, i64_add, i64_sub, i64_by,
-- i64_eq, i64_ne, i64_gt, i64_ge, i64_lt, i64_le,


public.i64		= assert( i64 )
public.i64_ax		= assert( i64_ax )
public.i64_new		= assert( i64_new )
public.i64u		= assert( i64u )
public.i64_clone	= assert( i64_clone )
public.i64_toInt	= assert( i64_toInt )
public.i64_toString	= assert( i64_toString )
public.i64_band		= assert( i64_band )
public.i64_bor		= assert( i64_bor )
public.i64_bxor		= assert( i64_bxor )
public.i64_bnot		= assert( i64_bnot )
public.i64_neg		= assert( i64_neg )
public.i64_add		= assert( i64_add )
public.i64_sub		= assert( i64_sub )
public.i64_by		= assert( i64_by )
public.i64_lshift	= assert( i64_lshift )
public.i64_rshift	= assert( i64_rshift )
public.i64_eq		= assert( i64_eq )
public.i64_ne		= assert( i64_ne )
public.i64_gt		= assert( i64_gt )
public.i64_ge		= assert( i64_ge )
public.i64_lt		= assert( i64_lt )
public.i64_le		= assert( i64_le )

return public
