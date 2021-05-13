/*
 * Copyright (C) 2006-2019 Christopho, Solarus - http://www.solarus-games.org
 *
 * Solarus is free software; you can redistribute it and/or modify
 * it under the terms of the GNU General Public License as published by
 * the Free Software Foundation, either version 3 of the License, or
 * (at your option) any later version.
 *
 * Solarus is distributed in the hope that it will be useful,
 * but WITHOUT ANY WARRANTY; without even the implied warranty of
 * MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the
 * GNU General Public License for more details.
 *
 * You should have received a copy of the GNU General Public License along
 * with this program. If not, see <http://www.gnu.org/licenses/>.
 */
#include "solarus/core/CurrentQuest.h"
#include "solarus/core/QuestFiles.h"
#include "solarus/lua/LuaContext.h"
#include "solarus/lua/LuaTools.h"
#include "solarus/core/Logger.h"
#ifdef SOLARUS_LUA_WIN_UNICODE_WORKAROUND
#  include <cerrno>
#  include <cstdio>
#  include <cstring>
#  include <windows.h>
#endif

namespace Solarus {

#ifdef SOLARUS_LUA_WIN_UNICODE_WORKAROUND
namespace {
  FILE*& create_file_pointer(lua_State* l);
}
#endif

/**
 * Name of the Lua table representing the file module.
 */
const std::string LuaContext::file_module_name = "sol.file";

/**
 * \brief Initializes the file features provided to Lua.
 */
void LuaContext::register_file_module() {

  std::vector<luaL_Reg> functions = {
      { "open", file_api_open },
      { "exists", file_api_exists },
      { "remove", file_api_remove },
      { "mkdir", file_api_mkdir },
  };
  if (CurrentQuest::is_format_at_least({ 1, 6 })) {
    functions.insert(functions.end(), {
        { "is_dir", file_api_is_dir },
        { "list_dir", file_api_list_dir },
    });
  }
  register_functions(file_module_name, functions);

#ifdef SOLARUS_LUA_WIN_UNICODE_WORKAROUND
    // Our sol.file.open() needs the same environment as io.open
    // to initialize the userdata correctly.
                                  // --
    lua_getglobal(current_l, "io");
                                  // io
    lua_getfield(current_l, -1, "open");
                                  // io io.open
    Debug::check_assertion(lua_isfunction(current_l, -1), "Could not find io.open");
    lua_getglobal(current_l, "sol");
                                  // io io.open sol
    lua_getfield(current_l, -1, "file");
                                  // io io.open sol sol.file
    lua_getfield(current_l, -1, "open");
                                  // io io.open sol sol.file sol.file.open
    lua_getfenv(current_l, -4);
                                  // io io.open sol sol.file sol.file.open env
    lua_setfenv(current_l, -2);
                                  // io io.open sol sol.file
    lua_pop(current_l, 4);
                                  // --
#else

  // Store the original io.open function in the registry.
  // We will need to access it from sol.file.open().
                                  // --
  lua_getglobal(current_l, "io");
                                  // io
  lua_getfield(current_l, -1, "open");
                                  // io open
  Debug::check_assertion(lua_isfunction(current_l, -1), "Could not find io.open");
  lua_setfield(current_l, LUA_REGISTRYINDEX, "io.open");
                                  // io
  lua_pop(current_l, 1);
                                  // --
#endif
}

/**
 * \brief Implementation of sol.file.open().
 * \param l The Lua context that is calling this function.
 * \return Number of values to return to Lua.
 */
int LuaContext::file_api_open(lua_State* l) {

  return state_boundary_handle(l, [&] {
    const std::string& file_name = LuaTools::check_string(l, 1);
    const std::string& mode = LuaTools::opt_string(l, 2, "r");

    const bool writing = !(mode.rfind("r", 0) == 0);

    // file_name is relative to the data directory, the data archive or the
    // quest write directory.
    // Let's determine the full file path to use when opening the file.
    std::string file_path;
    if (writing) {
      // Writing a file.
      if (QuestFiles::get_quest_write_dir().empty()) {
        LuaTools::error(l,
            "Cannot open file for writing: no write directory was specified in quest.dat");
      }

      file_path = QuestFiles::get_full_quest_write_dir() + "/" + file_name;
    }
    else {
      // Reading a file.
      QuestFiles::DataFileLocation location = QuestFiles::data_file_get_location(file_name);

      switch (location) {

      case QuestFiles::DataFileLocation::LOCATION_NONE:
        // Not found.
        lua_pushnil(l);
        push_string(l, std::string("Cannot find file '") + file_name
            + "' in the quest write directory, in data/, data.solarus or in data.solarus.zip");
        return 2;

      case QuestFiles::DataFileLocation::LOCATION_WRITE_DIRECTORY:
        // Found in the quest write directory.
        file_path = QuestFiles::get_full_quest_write_dir() + "/" + file_name;
        break;

      case QuestFiles::DataFileLocation::LOCATION_DATA_DIRECTORY:
        // Found in the data directory.
        file_path = QuestFiles::get_quest_path() + "/data/" + file_name;
        break;

      case QuestFiles::DataFileLocation::LOCATION_DATA_ARCHIVE:
      {
        // Found in the data archive.
        // To open the file, we need it to be a regular file, so let's create
        // a temporary one.
        const std::string& buffer = QuestFiles::data_file_read(file_name);
        file_path = QuestFiles::create_temporary_file(buffer);
        break;
      }
      }
    }

#ifdef SOLARUS_LUA_WIN_UNICODE_WORKAROUND
    FILE*& file_handle = create_file_pointer(l);

    // In windows, open the file using _wfopen() for Unicode filenames support.
    errno = EINVAL;  // Start by assuming an invalid argument.
    int wfp_len = MultiByteToWideChar(CP_UTF8, MB_ERR_INVALID_CHARS,
        &file_path[0], file_path.length(), nullptr, 0);
    int wmode_len = MultiByteToWideChar(CP_UTF8, MB_ERR_INVALID_CHARS,
        &mode[0], mode.length(), nullptr, 0);
    if (wfp_len > 0 && wmode_len > 0) {
      wchar_t* wfp = static_cast<wchar_t*>(alloca(sizeof(wchar_t) * (wfp_len + 1)));
      wchar_t* wmode = static_cast<wchar_t*>(alloca(sizeof(wchar_t) * (wmode_len + 1)));
      wfp_len = MultiByteToWideChar(CP_UTF8, MB_ERR_INVALID_CHARS,
          &file_path[0], file_path.length(), wfp, wfp_len);
      wmode_len = MultiByteToWideChar(CP_UTF8, MB_ERR_INVALID_CHARS,
          &mode[0], mode.length(), wmode, wmode_len);
      if (wfp_len > 0 && wmode_len > 0) {
        wfp[wfp_len] = 0;
        wmode[wmode_len] = 0;
        file_handle = _wfopen(wfp, wmode);
      }
    }

    // Note: if you want to test the hack on non-Windows systems you can just do
    // file_handle = fopen(file_path.c_str(), mode.c_str());

    if (file_handle == nullptr) {
      lua_pushnil(l);
      push_string(l, file_name + ": " + strerror(errno));
      lua_pushinteger(l, errno);
      return 3;
    }
    return 1;
#else

    // In other than Windows, just call io.open() in Lua.
    lua_getfield(l, LUA_REGISTRYINDEX, "io.open");
    push_string(l, file_path);
    push_string(l, mode);

    bool called = LuaTools::call_function(l, 2, 2, "io.open");
    if (!called) {
      LuaTools::error(l, "Unexpected error: failed to call io.open()");
    }
    return 2;
#endif
  });
}

/**
 * \brief Implementation of sol.file.exists().
 * \param l The Lua context that is calling this function.
 * \return Number of values to return to Lua.
 */
int LuaContext::file_api_exists(lua_State* l) {

  return state_boundary_handle(l, [&] {
    const std::string& file_name = LuaTools::check_string(l, 1);

    lua_pushboolean(l, QuestFiles::data_file_exists(file_name, false));

    return 1;
  });
}

/**
 * \brief Implementation of sol.file.remove().
 * \param l The Lua context that is calling this function.
 * \return Number of values to return to Lua.
 */
int LuaContext::file_api_remove(lua_State* l) {

  return state_boundary_handle(l, [&] {
    const std::string& file_name = LuaTools::check_string(l, 1);

    bool success = QuestFiles::data_file_delete(file_name);

    if (!success) {
      lua_pushnil(l);
      push_string(l, std::string("Failed to delete file '") + file_name + "'");
      return 2;
    }

    lua_pushboolean(l, true);
    return 1;
  });
}

/**
 * \brief Implementation of sol.file.mkdir().
 * \param l The Lua context that is calling this function.
 * \return Number of values to return to Lua.
 */
int LuaContext::file_api_mkdir(lua_State* l) {

  return state_boundary_handle(l, [&] {
    const std::string& dir_name = LuaTools::check_string(l, 1);

    bool success = QuestFiles::data_file_mkdir(dir_name);

    if (!success) {
      lua_pushnil(l);
      push_string(l, std::string("Failed to create directory '") + dir_name + "'");
      return 2;
    }

    lua_pushboolean(l, true);
    return 1;
  });
}

/**
 * \brief Implementation of sol.file.is_dir().
 * \param l The Lua context that is calling this function.
 * \return Number of values to return to Lua.
 */
int LuaContext::file_api_is_dir(lua_State* l) {

  return state_boundary_handle(l, [&] {
    const std::string& file_name = LuaTools::check_string(l, 1);

    lua_pushboolean(l, QuestFiles::data_file_is_dir(file_name));

    return 1;
  });
}

/**
 * \brief Implementation of sol.file.list_dir().
 * \param l The Lua context that is calling this function.
 * \return Number of values to return to Lua.
 */
int LuaContext::file_api_list_dir(lua_State* l) {

  return state_boundary_handle(l, [&] {

    const std::string& dir_name = LuaTools::check_string(l, 1);
    if (!QuestFiles::data_file_is_dir(dir_name)) {
      lua_pushnil(l);
      return 1;
    }

    const std::vector<std::string>& files = QuestFiles::data_file_list_dir(dir_name);

    lua_createtable(l, files.size(), 0);
    int i = 1;
    for (const std::string& file : files) {
      push_string(l, file);
      lua_rawseti(l, -2, i);
      ++i;
    }

    return 1;
  });
}

#ifdef SOLARUS_LUA_WIN_UNICODE_WORKAROUND
namespace {

// Mimic the userdata used in LuaJIT for handling FILE* pointers.
// The following is highly specific to LuaJIT internals, unfortunately.
// Tested only with LuaJIT 2.1.0-beta3.
struct SolarusLuaJit_IOFileUD {
  FILE *file;
  uint32_t type;
};

// GCudata definition without LJ_GC64.
struct SolarusLuaJit_GCudata32 {
  uint32_t nextgc;
  uint8_t marked;
  uint8_t gct;
  uint8_t udtype;
  uint8_t unused2;
  uint32_t env;
  uint32_t len;
  uint32_t metatable;
  uint32_t align1;
};

// GCudata definition in case of LJ_GC64.
struct SolarusLuaJit_GCudata64 {
  uint64_t nextgc;
  uint8_t marked;
  uint8_t gct;
  uint8_t udtype;
  uint8_t unused2;
  uint64_t env;
  uint32_t len;
  uint64_t metatable;
  uint32_t align1;
};

/**
 * \brief Detects if LuaJIT was compiled with the LJ_GC64 option.
 *
 * We need to detect it at runtime for ABI compatibility and because
 * there is no way to be sure at compilation time.
 *
 * \param l The Lua state.
 * \return \c true if LuaJIT uses 64 bit pointers for garbage collection info.
 */
bool detect_luajit_gc64(lua_State* l) {

  SolarusLuaJit_IOFileUD* file_udata = static_cast<SolarusLuaJit_IOFileUD*>(lua_newuserdata(l, sizeof(SolarusLuaJit_IOFileUD)));
  file_udata->file = nullptr;
  file_udata->type = 0;  // Same as IOFILE_TYPE_FILE, meaning a regular file and not a pipe or stdin/stdout.

  // At this point, LuaJIT has internally allocated a memory buffer of size GCudata + IOFileUD.
  SolarusLuaJit_GCudata64* gc_udata64 = reinterpret_cast<SolarusLuaJit_GCudata64*>(
        reinterpret_cast<char*>(file_udata) - sizeof(SolarusLuaJit_GCudata64)
  );

  Debug::check_assertion(lua_objlen(l, -1) == sizeof(SolarusLuaJit_IOFileUD), "Unexpected userdata size");
  // Check the len field. It should be the size of our userdata if LJ_GC64 is set,
  // otherwise is it the env field (a pointer value).
  const bool gc64 = gc_udata64->len == sizeof(SolarusLuaJit_IOFileUD);
  Logger::debug("Enabled LuaJIT Unicode filenames workaround. GC64: " + std::string(gc64 ? "yes" : "no"));

  lua_pop(l, 1);

  return gc64;
}

/**
 * \brief Pushes a new nullptr FILE* userdata for a regular file.
 *
 * This function is a hack that only exists because all functions
 * of the Lua API also open a file, which sometimes we want to do ourselves.
 * The created userdata is a valid one for the Lua I/O API.
 *
 * \warning This has been tested only with vanilla Lua 5.1 and LuaJIT 2.1.0-beta3.
 *
 * \warning The current environment when calling this function
 * is assumed to be the same as the one of io.open().
 *
 * \param l The Lua state.
 * \return Reference to the created file handle.
 */
FILE*& create_file_pointer(lua_State* l) {

  FILE** file_handle = nullptr;
  if (!LuaContext::get().is_luajit()) {
    // In vanilla Lua 5.1, the userdata is a simple FILE* pointer,
    // and relies on its environment table to know the correct close function.
    if (LuaContext::get().get_lua_version() != "Lua 5.1") {
      // Lua versions more recent than 5.1 have a completely different
      // FILE* userdata implementation.
      // If one day we switch to a more recent version of Lua, we will need to update this code.
      Debug::die("FILE* userdata creation in Solarus is only supported with Lua 5.1 or LuaJIT");
    }

    file_handle = static_cast<FILE**>(lua_newuserdata(l, sizeof(FILE*)));
    *file_handle = nullptr;
    luaL_getmetatable(l, LUA_FILEHANDLE);
    lua_setmetatable(l, -2);
  } else {
    SolarusLuaJit_IOFileUD* file_udata = static_cast<SolarusLuaJit_IOFileUD*>(lua_newuserdata(l, sizeof(SolarusLuaJit_IOFileUD)));
    file_udata->file = nullptr;
    file_udata->type = 0;  // Same as IOFILE_TYPE_FILE, meaning a regular file and not a pipe or stdin/stdout.
    file_handle = &file_udata->file;

    static bool luajit_gc64 = detect_luajit_gc64(l);
    if (luajit_gc64) {
      SolarusLuaJit_GCudata64* gc_udata = reinterpret_cast<SolarusLuaJit_GCudata64*>(
            reinterpret_cast<char*>(file_udata) - sizeof(SolarusLuaJit_GCudata64)
      );
      gc_udata->udtype = 1;  // Same as UDTYPE_IO_FILE.
    } else {
      SolarusLuaJit_GCudata32* gc_udata = reinterpret_cast<SolarusLuaJit_GCudata32*>(
            reinterpret_cast<char*>(file_udata) - sizeof(SolarusLuaJit_GCudata32)
      );
      gc_udata->udtype = 1;  // Same as UDTYPE_IO_FILE.
    }

    // Set the metatable of the userdata to the current environment.
                                  // ... file
    lua_getfenv(l, -1);
                                  // ... file env
    lua_setmetatable(l, -2);
                                  // ... file
  }
  return *file_handle;
}

}  // Anonymous namespace.
#endif

}
