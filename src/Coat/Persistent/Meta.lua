
--
-- lua-Coat : <http://fperrad.github.com/lua-CoatPersistent/>
--

module 'Coat.Persistent.Meta'

function attributes (class)
    local i = 0
    return function ()
        i = i + 1
        return class._ATTR_P[i]
    end
end

--
-- Copyright (c) 2010 Francois Perrad
--
-- This library is licensed under the terms of the MIT/X11 license,
-- like Lua itself.
--
