#!/usr/bin/env lua

require 'Coat.Persistent'
require 'Coat.Types'

persistent 'Person'

subtype.Person.Name = {
    as = 'string',
    where = function (val) return val:match '^%a%a' end,
}

has_p.name = { is = 'rw', isa = 'Person.Name' }
has_p.age = { is = 'rw', isa = 'number' }

sql_create = [[
    CREATE TABLE person (
        id INTEGER,
        name CHAR(64),
        age INTEGER
    )
]]

require 'Test.More'

plan(2)
Coat.Persistent.trace = print

if os.getenv "GEN_PNG" and os.execute "dot -V" == 0 then
    local f = io.popen("dot -T png -o 007.png", 'w')
    f:write(require 'Coat.UML'.to_dot())
    f:close()
end

os.remove 'test.db'
local conn = Person.establish_connection('sqlite3', 'test.db')
conn:execute(Person.sql_create)

error_like( [[local p = Person.new { name = '213' }; p:save()]],
            "Value for attribute 'name' does not validate type constraint 'Person.Name'" )

local p = Person.new { name = 'jo213' }
ok( p:save() )

