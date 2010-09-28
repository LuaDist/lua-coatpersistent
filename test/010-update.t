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

plan(5)
Coat.Persistent.trace = print

if os.getenv "GEN_PNG" and os.execute "dot -V" == 0 then
    local f = io.popen("dot -T png -o 010.png", 'w')
    f:write(require 'Coat.UML'.to_dot())
    f:close()
end

os.remove 'test.db'
Person.establish_connection('sqlite3', 'test.db')
local conn = Person.connection()
conn:execute(Person.sql_create)

local p = Person { name = 'Dude', age = 23 }
ok( p:save(), "save --> insert")
is( p.name, 'Dude' )
p.name = 'Bob'
ok( p:save(), "save --> update" )

local p2 = Person.find(p.id)()
is( p2.id, p.id )
is( p2.name, 'Bob' )

