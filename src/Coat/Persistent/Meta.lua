
--
-- lua-Coat : <http://fperrad.github.com/lua-CoatPersistent/>
--

local next = next
local table = require 'table'

module 'Coat.Persistent.Meta'

local _primary_key = {}
function primary_key (class, val)
    if val then
        _primary_key[class] = val
    else
        return _primary_key[class]
    end
end

local _table_name = {}
function table_name (class, val)
    if val then
        _table_name[class] = val
    else
        return _table_name[class]
    end
end

local _attr = {}

function attribute (class, attr)
    if not _attr[class] then
        _attr[class] = {}
    end
    table.insert(_attr[class], attr)
end

function attributes (class)
    local i = 0
    return function ()
        i = i + 1
        return _attr[class][i]
    end
end

--
-- Copyright (c) 2010 Francois Perrad
--
-- This library is licensed under the terms of the MIT/X11 license,
-- like Lua itself.
--
