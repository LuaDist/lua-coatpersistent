#!/usr/bin/env lua

require 'Coat.Persistent'

persistent('Car', { table_name = 'vehicle', primary_key = 'c_id' })

has_p.color = { is = 'rw', isa = 'string' }
has_p.max_speed = { is = 'rw', isa = 'number' }

sql_create = [[
    CREATE TABLE vehicle (
        c_id INTEGER, 
        color CHAR(64),
        max_speed INTEGER
    )
]]

persistent('Person', { table_name = 'people', primary_key = 'people_id' })

has_p.name = { is = 'rw', isa = 'string' }
has_p.age = { is = 'rw', isa = 'number' }
has_one.its_car = { class_name = 'Car', foreign_key = 'c_id' }

sql_create = [[
    CREATE TABLE people (
        people_id INTEGER,
        name CHAR(64),
        age INTEGER,
        c_id INTEGER
    )
]]

persistent('Friend', { table_name = 'amigo', primary_key = 'f_id' })
extends 'Person'

has_p.nickname = { is ='rw', isa = 'string', default = 'dude' }
has_one.f = { class_name = 'Person', foreign_key = 'people_people_id' }

sql_create = [[
    CREATE TABLE amigo (
        f_id INTEGER,
        people_people_id INTEGER,
        name CHAR(64),
        age INTEGER,
        nickname CHAR(64)
    )
]]

Person.has_many.amigos = { class_name = 'Friend' }


require 'Test.More'

plan(12)

if os.getenv "GEN_PNG" and os.execute "dot -V" == 0 then
    local f = io.popen("dot -T png -o 016.png", 'w')
    f:write(require 'Coat.UML'.to_dot())
    f:close()
end

os.remove 'test.db'
Car.establish_connection('sqlite3', 'test.db'):execute(Car.sql_create)
Person.establish_connection('sqlite3', 'test.db'):execute(Person.sql_create)
Friend.establish_connection('sqlite3', 'test.db'):execute(Friend.sql_create)

local p = Person.create{ name = 'John' }
ok( p:isa 'Person' )
is( p.people_id, 1, "primary_key people_id is set" )
is( p.name, 'John', "name is set" )

pp = Person.find_by_name 'John'()
is( pp.name, 'John', "find_by_name works" )

pp = Person.find(1)()
is( pp.name, 'John', 'find works' );

p.name = 'David'
ok( p:save(), "name changed" )
pp = Person.find(1)()
is( pp.name, 'David', "name is David" )

local car = Car.create{ color = 'red', max_speed = 180 }
ok( car:isa 'Car', "car created" )

p.its_car = car
c = p.its_car
is( car.c_id, c.c_id )
ok( p:save(), "p:save() with car" )

p.amigos = {
    Friend{ name = 'Joe', age = 20 },
    Friend{ name = 'John', age = 20 },
}
ok( p:save(), "p:save() with friends" )
local f = p.amigos
is( #f, 2, "2 friends returned by p.amigos" )
