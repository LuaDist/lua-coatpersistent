#!/usr/bin/env lua

require 'Coat.Persistent'

persistent 'Person'

has_p.name = { is = 'ro', required = true, isa = 'string' }
has_p.age = { is = 'rw', isa = 'number' }

sql_create = [[
    CREATE TABLE person (
        id INTEGER,
        name CHAR(64),
        age INTEGER
    )
]]

require 'Test.More'

plan(3)

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

local p = Person.find(1)()
is( p.name, 'Joe' )

error_like( [[local p = Person.find(1)(); p.name = 'Moe']],
            "Cannot set a read%-only attribute %(name%)" )

error_like( [[Person.create { age = 21 }]],
            "Attribute 'name' is required" )

