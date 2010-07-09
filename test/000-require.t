#!/usr/bin/env lua

require 'Test.More'

plan(9)

if not require_ok 'Coat.Persistent' then
    BAIL_OUT "no lib"
end

local m = require 'Coat.Persistent'
type_ok( m, 'table' )
is( m, Coat.Persistent )
is( m, package.loaded.Coat.Persistent )
like( m._COPYRIGHT, 'Perrad', "_COPYRIGHT" )
like( m._DESCRIPTION, 'ORM', "_DESCRIPTION" )
type_ok( m._VERSION, 'string', "_VERSION" )
like( m._VERSION, '^%d%.%d%.%d$' )

is( Coat.Persistent.math, nil, "check ns pollution" )

