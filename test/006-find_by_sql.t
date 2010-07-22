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

if os.getenv "GEN_PNG" and os.execute "dot -V" == 0 then
    local f = io.popen("dot -T png -o 006.png", 'w')
    f:write(require 'Coat.UML'.to_dot())
    f:close()
end

error_like( [[local first = Person.find()()]],
            "No connection for class Person" )

os.remove 'test.db'
Person.establish_connection('sqlite3', 'test.db')
local conn = Person.connection()
conn:execute(Person.sql_create)

 Person.create { 
    { name = 'Joe', age = 20 },
    { name = 'John', age = 20 },
    { name = 'Brenda', age = 20 },
}

local nb = 0
for p in Person.find_by_sql "select * from person where name like 'Jo%'" do
    ok( p:isa 'Person' )
    nb = nb + 1
end
is( nb, 2, "2 items returned", find_by_sql )

local nb = 0
for p in Person.find "name like 'Jo%'" do
    ok( p:isa 'Person' )
    nb = nb + 1
end
is( nb, 2, "2 items returned", find )

error_like( [[Person.find(true)]],
            "bad argument #2 to find %(number or string expected%)" )

error_like( [[Person.find_by_sql "syntax error"]],
            'LuaSQL: near "syntax": syntax error' )

