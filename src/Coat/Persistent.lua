
--
-- lua-CoatPersistent : <http://fperrad.github.com/lua-CoatPersistent/>
--

local rawget = rawget
local rawset  = rawset
local require = require
local setmetatable = setmetatable
local tostring = tostring
local type = type
local _G = _G
local Coat = require 'Coat'
local dado = require 'dado.sql'

local error = Coat.error
local argerror = Coat.argerror
local checktype = Coat.checktype

module 'Coat.Persistent'

local drv = {}
local cnx = {}

function establish_connection (class, driver, ...)
    local function create_db_sequence_tables (conn)
        if not conn:execute "select count(*) from db_sequence_state" then
            local r, msg = conn:execute "create table db_sequence_state (dataset varchar(50), state_id int(11))"
            if not r then
                error(msg)
            end
        end
    end --  create_db_sequence_tables

    drv[class] = driver
    local conn = cnx[driver]
    if not conn then
        require('luasql.' .. driver)
        local env = _G.luasql[driver]()
        if not env then
            error("cannot create an environment for " .. driver)
        end
        local msg
        conn, msg = env:connect(...)
        if not conn then 
            error(msg) 
        end
        cnx[driver] = conn
    end
    create_db_sequence_tables(conn)
    return conn
end

function connection (class)
    return cnx[drv[class]]
end

local function execute (class, sql)
    _G.print('#', sql)
    local conn = cnx[drv[class]]
    if not conn then
        error("No connection for class " .. class._NAME)
    end
    local r, msg = conn:execute(sql)
    if not r then
        error(msg)
    end
    return r
end

local function next_id (class)
    local dataset = class._TABLE_NAME
    local cond = dado.AND { dataset = dataset }
    local cur = execute(class, dado.select('*', 'db_sequence_state', cond))
    local row = cur:fetch({}, 'a')
    if not row then
        local id_1 = 1
        execute(class, dado.insert('db_sequence_state', { dataset = dataset, state_id = id_1 }))
        return id_1
    else
        local id = row.state_id
        local id_1 = id + 1
        local cond = dado.AND { dataset = dataset, state_id = id }
        execute(class, dado.update('db_sequence_state', { state_id = id_1 }, cond))
        return id_1
    end
end

function save (class, obj)
    local primary_key = class._PRIMARY_KEY

    local values = {}
    local attrs = class._ATTR_P
    for i = 1, #attrs do
        local field = attrs[i]
        local val = obj[field]
        if val ~= nil then
            values[field] = tostring(val)
        end
    end

    if rawget(obj, '_db_exist') then
        execute(class, dado.update(class._TABLE_NAME, values))
    else
        obj[primary_key] = next_id(class)
        values[primary_key] = obj[primary_key]
        execute(class, dado.insert(class._TABLE_NAME, values))
        rawset(obj, '_db_exist', true)
    end

    local t = rawget(obj, '_subobjects')
    if t then
        for i = 1, #t do
            t[i]:save()
        end
        rawset(obj, '_subobjects', nil)
    end

    if primary_key then
        return obj[primary_key]
    else
        return 'saved'
    end
end

function delete (class, obj)
    local primary_key = class._PRIMARY_KEY
    local cond = dado.AND { [primary_key] = obj[primary_key] }
    return execute(class, dado.delete(class._TABLE_NAME, cond))
end

function create (class, val)
    if type(val) == 'table' and #val > 0 then
        for i = 1, #val do
            create(class, val[i])
        end
    else
        local obj = class.new(val)
        obj:save()
        return obj
    end
end

function find_by_sql (class, sql)
    local cur = execute(class, sql)
    return function ()
        local row = cur:fetch({}, 'a')
        if row then
            local obj = class.new(row)
            rawset(obj, '_db_exist', true)
            return obj
        else
            cur:close()
            return nil
        end
    end
end

function find (class, val)
    if val == nil then
        return find_by_sql(class, dado.select('*', class._TABLE_NAME))
    elseif type(val) == 'number' then
        local cond = dado.AND { [class._PRIMARY_KEY] = val }
        return find_by_sql(class, dado.select('*', class._TABLE_NAME, cond))
    elseif type(val) == 'string' then
        return find_by_sql(class, dado.select('*', class._TABLE_NAME, val))
    else
        argerror('find', 2, "number or string expected")
    end
end

function has_p (class, name, options)
    checktype('has_p', 1, name, 'string')
    checktype('has_p', 2, options or {}, 'table')

    class['find_by_' .. name] = function (val)
        if val == nil then
            error "Cannot find without a value"
        end
        local cond = dado.AND { [name] = val }
        return find_by_sql(class, dado.select('*', class._TABLE_NAME, cond))
    end

    local t = class._ATTR_P; t[#t+1] = name
    Coat.has(class, name, options)
end

function has_one (class, name, options)
    checktype('has_one', 1, name, 'string')
    options = options or {}
    checktype('has_one', 2, options, 'table')
    local owned_class_name = options.class_name or name
    local owned_class = Coat.Meta.Class.class(owned_class_name)
    if not owned_class then
        error("Unknown class " .. owned_class_name)
    end
    local owned_table_name = owned_class._TABLE_NAME
    local owned_primary_key = owned_class._PRIMARY_KEY
    if not owned_primary_key then
        error("The class " .. owned_class_name .. " has not a primary key.")
    end
    local attr_name = owned_table_name
    if options.class_name then
        attr_name = name
    end
    local foreign_key = options.foreign_key or owned_table_name .. '_' .. owned_primary_key

    has_p(class, foreign_key, { is = 'rw', isa = 'number' })

    class['_set_' .. attr_name] = function (obj, val)
        obj[foreign_key] = val[owned_primary_key]
        return val
    end

    class['_get_' .. attr_name] = function (obj)
        local id = obj[foreign_key]
        if id then
            return find(owned_class, id)()
        else 
            return nil
        end
    end

    class._ACCESSOR = attr_name
end

function has_many (class, name, options)
    checktype('has_one', 1, name, 'string')
    options = options or {}
    checktype('has_one', 2, options, 'table')
    local owned_class_name = options.class_name or name
    local owned_class = Coat.Meta.Class.class(owned_class_name)
    if not owned_class then
        error("Unknown class " .. owned_class_name)
    end
    local table_name = class._TABLE_NAME
    local primary_key = class._PRIMARY_KEY
    local owned_table_name = owned_class._TABLE_NAME
    local owned_primary_key = owned_class._PRIMARY_KEY
    if not owned_primary_key then
        error("The class " .. owned_class_name .. " has not a primary key.")
    end
    local attr_name = owned_table_name .. 's'
    if options.class_name then
        attr_name = name
    end

    class['_set_' .. attr_name] = function (obj, list)
        if type(list) ~= 'table' or list._CLASS then
            error("Not an array of object")
        end
        local accessor = owned_class._ACCESSOR or table_name
        local t = rawget(obj, '_subobjects')
        if not t then
            t = {}
            rawset(obj, '_subobjects', t)
        end
        for i = 1, #list do
            local val = list[i]
            if not val:isa(owned_class) then
                error("Not an object of class " .. owned_class._NAME .. " (got " .. Coat.type(val) .. ")")
            end
            val[accessor] = obj
            t[#t+1] = val
        end
    end

    class['_get_' .. attr_name] = function (obj)
        local t = {}
        local iter = owned_class['find_by_' .. table_name .. '_' .. primary_key](obj[primary_key])
        for v in iter do
            t[#t+1] = v
        end
        return t
    end
end

function _G.persistent (modname, options)
    checktype('persistent', 1, modname, 'string')
    options = options or {}
    checktype('persistent', 2, options, 'table')
    local primary_key = options.primary_key or 'id'
    local table_name = options.table_name or modname:gsub('%.', '_')
    local M = Coat._class(modname)
    M._PRIMARY_KEY = primary_key
    M._TABLE_NAME = table_name:lower()
    M._ATTR_P = { primary_key }
    M.establish_connection = function (...) return establish_connection(M, ...) end
    M.connection = function () return connection(M) end
    M.save = function (...) return save(M, ...) end
    M.delete = function (...) return delete(M, ...) end
    M.create = function (...) return create(M, ...) end
    M.find = function (...) return find(M, ...) end
    M.find_by_sql = function (...) return find_by_sql(M, ...) end
    M.has_p = setmetatable({}, { __newindex = function (t, k, v) has_p(M, k, v) end })
    M.has_one = setmetatable({}, { __newindex = function (t, k, v) has_one(M, k, v) end })
    M.has_many = setmetatable({}, { __newindex = function (t, k, v) has_many(M, k, v) end })
    Coat.has(M, primary_key, { is = 'rw', isa = 'number' })
end

_VERSION = "0.0.1"
_DESCRIPTION = "lua-CoatPersistent : an ORM for lua-Coat"
_COPYRIGHT = "Copyright (c) 2010 Francois Perrad"
--
-- This library is licensed under the terms of the MIT/X11 license,
-- like Lua itself.
--
