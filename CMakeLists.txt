# lua-CoatPersistent : <http://fperrad.github.com/lua-CoatPersistent/>

project ( lua-coatpersistent NONE )
cmake_minimum_required ( VERSION 2.6 )
include ( dist.cmake )

install_lua_module ( Coat.Persistent            src/Coat/Persistent.lua )

install_data ( CHANGES COPYRIGHT README.md )
install_test ( test/ )
