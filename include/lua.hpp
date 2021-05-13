// C++ wrapper for LuaJIT header files.
#ifndef LUA_HPP_H
#define LUA_HPP_H

#ifndef LUA_BUILD_AS_DLL
	#define LUA_BUILD_AS_DLL
#endif

extern "C" {
#include "lua.h"
#include "lauxlib.h"
#include "lualib.h"
}


#endif