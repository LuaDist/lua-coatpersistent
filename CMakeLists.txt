# Copyright (C) 2012 LuaDist.
# Created by Peter Kapec
# Redistribution and use of this file is allowed according to the terms of the MIT license.
# For details see the COPYRIGHT file distributed with LuaDist.
# Please note that the package source code is licensed under its own license.

project ( lua-coatpersistent NONE )
cmake_minimum_required ( VERSION 2.8 )
include ( cmake/dist.cmake )
include ( lua )

install_lua_module ( Coat.Persistent src/Coat/Persistent.lua )
install_data ( CHANGES COPYRIGHT README.md )
install_test ( test/ )
