#!/usr/bin/env lua

require 'Coat.Persistent'

persistent 'Person'

has_p.name = { is = 'rw', isa = 'string' }
has_p.age = { is = 'rw', isa = 'number' }

sql_create = [[
    CREATE TABLE person (
        id INTEGER,
        name CHAR(64),
        age INTEGER
    )
]]

require 'Test.More'

plan(9)
Coat.Persistent.trace = print

if os.getenv "GEN_PNG" and os.execute "dot -V" == 0 then
    local f = io.popen("dot -T png -o 005.png", 'w')
    f:write(require 'Coat.UML'.to_dot())
    f:close()
end

os.remove 'test.db'
Person.establish_connection('sqlite3', 'test.db')
local conn = Person.connection()
conn:execute(Person.sql_create)

local names = { 'Joe', 'John', 'Brenda' }
for _, name in ipairs(names) do
    Person.create { name = name, age = 20 }
end

local nb = 0
local found = {}
for p in Person.find_by_age(20) do
    ok( p:isa 'Person' )
    table.insert(found, p.name)
    nb = nb + 1
end
is( nb, 3, "3 items returned" )
eq_array( found, names )

local first = Person.find_by_age(20)()
ok( first:isa 'Person' )
is( first.name, 'Joe' )

error_like( [[local first = Person.find_by_age()()]],
            "Cannot find without a value" )

local nb = 0
for p in Person.find() do
    nb = nb + 1
end
is( nb, 3, "3 items returned" )
