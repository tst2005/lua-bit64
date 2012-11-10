
local import = require("import")
local import = import.import

local bit64 = require("bit64")
local	_new, _clone, _toString, _band, _bor, _bxor, _bnot, _neg, _add, _sub, _by, _lshift, _rshift = import(bit64,[[
	_new, _clone, _toString, _band, _bor, _bxor, _bnot, _neg, _add, _sub, _by, _lshift, _rshift ]], "i64%s")


--    _a = 0x006cd2d2bab6fb1b;
--    _b = 0x42fc73c2ace698ad;
--    _c = 0x2b20cc237775d265;

local _a = _new(  "0x6cd2d2bab6fb1b")
local _b = _new("0x42fc73c2ace698ad")
local _c = _new("0x2b20cc237775d265")

local function NextUlong()

--        _a = _b + ((_a <<  7) | (_c >> 57));
--        _b = _c ^ ((_c << 13) | (_a >> 51));
--        _c = _a - ((_b << 17) | (_b >> 44));
--	  return _c;

	_a = _add (_b, _bor( _lshift(_a, _new( 7)), _rshift(_c, _new(57)) ) )
	_b = _bxor(_c, _bor( _lshift(_c, _new(13)), _rshift(_a, _new(51)) ) )
	_c = _sub (_a, _bor( _lshift(_b, _new(17)), _rshift(_b, _new(44)) ) )
	return _c
end

--for i=1,10000000,1 do
while true do
	local _c = NextUlong()
	print(_toString(_c))
end

--[[
planned to be able to use lua op like :
	_a = _b + _bor( _lshift(_a, _new( 7)), _rshift(_c, _new(57)) )
	_b = _c ^ _bor( _lshift(_c, _new(13)), _rshift(_a, _new(51)) )
	_c = _a - _bor( _lshift(_b, _new(17)), _rshift(_b, _new(44)) )

or maybe
	_a = _b + _a:lshift(_new( 7)):bor( _c:rshift(_new(57)) )
or maybe
	_a = _b + _a:lshift(7):bor( _c:rshift(57) )
or maybe
	_a = _b:add( _a:lshift(7):bor( _c:rshift(57) ) )


another try
	_a = (_b + (_a <<  7)) | (_c >> 57);
=>
	_a = (_b + _a:lshift(7)):bor(_c:rshift(57))


]]--

