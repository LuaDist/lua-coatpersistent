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

plan(19)

if os.getenv "GEN_PNG" and os.execute "dot -V" == 0 then
    local f = io.popen("dot -T png -o 001.png", 'w')
    f:write(require 'Coat.UML'.to_dot())
    f:close()
end

os.remove 'test.db'
local conn = Person.establish_connection('sqlite3', 'test.db')
conn:execute(Person.sql_create)

ok( Coat.Meta.Class.has( Person, 'id' ), "field id" )
ok( Coat.Meta.Class.has( Person, 'name' ), "field name" )
ok( Coat.Meta.Class.has( Person, 'age' ), "field age" )

john = Person { name = 'John', age = 23 }
is( john:type(), 'Person', "Person" )
ok( john:isa 'Person' )

is( john.id, nil, "john.id is nil" )
ok( john:save(), "john:save()" )
is( john.id, 1, "john.id is 1" )
--john.age = john.age + 1
--ok( john:save(), "john:save()" )

brenda = Person { name = 'Brenda', age = 22 }
is( brenda.id, nil, "brenda.id is nil" )
ok( brenda:save(), "brenda:save()" )
is( brenda.id, 2, "brenda.id is 2" )

local p = Person.find(1)()
ok( p, "Person.find(1) returns something" )
ok( p:isa 'Person', "it is a Person" )
is( p.name, 'John', "it is John" )
is( p.age, 23 )

local p = Person.find_by_name('Brenda')()
ok( p, "Person.find_by_name returns something" )
ok( p:isa 'Person', "it is a Person" )
is( p.name, 'Brenda', "it is Brenda" )

ok( brenda:delete(), "brenda:delete()" )

--bob = Person.create { name = 'Bob', age = 23 }
--ok( bob, "Person.create returns something" )
--ok( bob:isa 'Person', "it is a Person" )
--is( bob.id, 3 )

--Person.create {
--    { name = 'A', age = 20 },
--    { name = 'B', age = 20 },
--}
--for p in Person.find_by_age(23) do
--    print(p.name)
--end

--for p in Person.find() do
--    print(p.name)
--end

--local p = brenda.find(1)()
--ok( p, "Person.find(1) returns something" )
--ok( p:isa 'Person', "it is a Person" )
--is( p.name, 'John', "it is John" )
