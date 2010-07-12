
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
local table = require 'table'
local Coat = require 'Coat'
local dado = require 'dado.sql'

local error = Coat.error
local argerror = Coat.argerror
local checktype = Coat.checktype

module 'Coat.Persistent'

local Meta = require 'Coat.Persistent.Meta'

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
    end

    drv[class] = driver
    require('luasql.' .. driver)
    local env = _G.luasql[driver]()
    if not env then
        error("cannot create an environment for " .. driver)
    end
    local conn, msg = env:connect(...)
    if not conn then 
        error(msg) 
    end
    cnx[class] = conn
    create_db_sequence_tables(conn)
    return conn
end

function connection (class)
    return cnx[class]
end

local function execute (class, sql)
    _G.print('#', sql)
    local conn = cnx[class]
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
    local dataset = Meta.table_name(class)
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
    local primary_key = Meta.primary_key(class)

    local values = {}
    for field in Meta.attributes(class) do
        local val = obj[field]
        if val ~= nil then
            values[field] = tostring(obj[field])
        end
    end

    if rawget(obj, '_db_exist') then
        execute(class, dado.update(Meta.table_name(class), values))
    else
        obj[primary_key] = next_id(class)
        values[primary_key] = obj[primary_key]
        execute(class, dado.insert(Meta.table_name(class), values))
        rawset(obj, '_db_exist', true)
    end

    if primary_key then
        return obj[primary_key]
    else
        return 'saved'
    end
end

function delete (class, obj)
    local primary_key = Meta.primary_key(class)
    local cond = dado.AND { [primary_key] = obj[primary_key] }
    return execute(class, dado.delete(Meta.table_name(class), cond))
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
        return find_by_sql(class, dado.select('*', Meta.table_name(class)))
    elseif type(val) == 'number' then
        local cond = dado.AND { [Meta.primary_key(class)] = val }
        return find_by_sql(class, dado.select('*', Meta.table_name(class), cond))
    elseif type(val) == 'string' then
        return find_by_sql(class, dado.select('*', Meta.table_name(class), val))
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
        return find_by_sql(class, dado.select('*', Meta.table_name(class), cond))
    end

    Meta.attribute(class, name)
    Coat.has(class, name, options)
end

function _G.persistent (modname, options)
    checktype('persistent', 1, modname, 'string')
    options = options or {}
    checktype('persistent', 2, options, 'table')
    local primary_key = options.primary_key or 'id'
    local table_name = options.table_name or modname:gsub('%.', '_')
    local M = Coat._class(modname)
    M.establish_connection = function (...) return establish_connection(M, ...) end
    M.connection = function () return connection(M) end
    M.save = function (...) return save(M, ...) end
    M.delete = function (...) return delete(M, ...) end
    M.create = function (...) return create(M, ...) end
    M.find = function (...) return find(M, ...) end
    M.find_by_sql = function (...) return find_by_sql(M, ...) end
    M.has_p = setmetatable({}, { __newindex = function (t, k, v) has_p(M, k, v) end })
    Meta.primary_key(M, primary_key)
    Meta.table_name(M, table_name)
    Meta.attribute(M, primary_key)
    Coat.has(M, primary_key, { is = 'rw', isa = 'number' })
end

_VERSION = "0.0.1"
_DESCRIPTION = "lua-CoatPersistent : an ORM for lua-Coat"
_COPYRIGHT = "Copyright (c) 2010 Francois Perrad"
--
-- This library is licensed under the terms of the MIT/X11 license,
-- like Lua itself.
--
