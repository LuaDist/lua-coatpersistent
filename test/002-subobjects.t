#!/usr/bin/env lua

require 'Coat.Persistent'

persistent 'Avatar'

has_p.imgpath = { is = 'rw', isa = 'string' }

sql_create = [[
    CREATE TABLE avatar (
        id INTEGER,
        imgpath CHAR(255)
    )
]]

persistent 'Person'

has_one.Avatar = {}
-- has_many.Car = {} -- see below
has_p.name = { is = 'rw', isa = 'string' }
has_p.age = { is = 'rw', isa = 'number' }

sql_create = [[
    CREATE TABLE person (
        id INTEGER,
        avatar_id INTEGER, 
        name CHAR(64),
        age INTEGER
    )
]]

persistent 'Car'

has_one.Person = {}
has_p.name = { is = 'rw', isa = 'string' }

sql_create = [[
    CREATE TABLE car (
        id INTEGER,
        person_id INTEGER,
        name CHAR(255)
    )
]]

Person.has_many.Car = {} -- avoid circular definition


require 'Test.More'

plan(16)
Coat.Persistent.trace = print

if os.getenv "GEN_PNG" and os.execute "dot -V" == 0 then
    local f = io.popen("dot -T png -o 002.png", 'w')
    f:write(require 'Coat.UML'.to_dot())
    f:close()
end

os.remove 'test.db'
Person.establish_connection('sqlite3', 'test.db'):execute(Person.sql_create)
Avatar.establish_connection('sqlite3', 'test.db'):execute(Avatar.sql_create)
Car.establish_connection('sqlite3', 'test.db'):execute(Car.sql_create)

local a = Avatar{ imgpath = '/tmp/face.png' }
a:save()
local bmw = Car{ name = 'BMW' }
bmw:save()
local ford = Car{ name = 'Ford' }
ford:save()
local nissan = Car{ name = 'Nissan' }
nissan:save()

local p = Person{ name = 'Joe', age = 17 }
is( p:type(), 'Person', "Person" )
ok( p:isa 'Person' )
ok( p:save(), "p:save()" )

p.avatar = a
is( (p.avatar).id, a.id, "p.avatar.id == a.id" )
is( p.avatar_id, a.id, "p.avatar_id == a.id" )

ok( p:save(), "p:save() -- with avatar" )

p2 = Person.find(p.id)()
ok( p2.avatar, "p2.avatar is defined after a find" )
is( p2.avatar.id, a.id, "p2.avatar.id == a.id" )

p.cars = { bmw, nissan, ford }
ok( p:save(), "p:save() -- with cars" )
local cars = p.cars
is( #cars, 3, "3 cars returned by p.cars" )

error_like( [[local p = Person{ name = 'Joe', age = 17 }; local a = Avatar{ imgpath = '/tmp/face.png' }; p.cars = { a }]],
            "Not an object of class Car %(got Avatar%)" )

error_like( [[local p = Person{ name = 'Joe', age = 17 }; local bmw = Car{ name = 'BMW' }; p.cars = bmw]],
            "Not an array of object" )

error_like( [[Person.has_one.Foo = {}]],
            "Unknown class Foo" )

error_like( [[Person.has_many.Foo = {}]],
            "Unknown class Foo" )

class 'Foo'

error_like( [[Person.has_one.Foo = {}]],
            "The class Foo has not a primary key" )

error_like( [[Person.has_many.Foo = {}]],
            "The class Foo has not a primary key" )

