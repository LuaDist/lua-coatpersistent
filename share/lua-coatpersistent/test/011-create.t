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
require 'Coat.Persistent'.trace = print

if os.getenv "GEN_PNG" and os.execute "dot -V" == 0 then
    local f = io.popen("dot -T png -o 011.png", 'w')
    f:write(require 'Coat.UML'.to_dot())
    f:close()
end

os.remove 'test.db'
Person.establish_connection('sqlite3', 'test.db')
local conn = Person.connection()
conn:execute(Person.sql_create)

local p1 = Person.create { name = 'John', age = 23 }
ok( p1.id )
p1 = Person.find(p1.id)()
is( p1.name, 'John' )

Person.create {
    { name = 'Brenda', age = 31 },
    { name = 'Nate', age = 34 },
    { name = 'Dave', age = 29 },
}

local brenda = Person.find_by_name('Brenda')()
local nate = Person.find_by_name('Nate')()
local dave = Person.find_by_name('Dave')()

is( brenda.name, 'Brenda' )
is( dave.name, 'Dave' )
is( nate.name, 'Nate' )

