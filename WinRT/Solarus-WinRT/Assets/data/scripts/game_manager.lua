-- Script that creates a game ready to be played.

-- Usage:
-- local game_manager = require("scripts/game_manager")
-- local game = game_manager:create("savegame_file_name")
-- game:start()

local initial_game = require("scripts/initial_game")

local game_manager = {}

-- Name of the main save file
local save_file = "save1.dat"


-- Start a new game.
-- The old game will be overwritten when it saves.
function game_manager:new_game()
  -- FIXME: Deleting the file is an immediate and irreversible action.
  --        Instead it should be more graceful, starting a new game
  --        and only overwriting the old file upon saving.
  sol.game.delete(save_file)
  local game = sol.game.load(save_file)
  initial_game:initialize_new_savegame(game)
  sol.main:start_savegame(game)
end


-- Continue the existing game.
-- Check that it exists before calling this.
function game_manager:continue_game()
  local game = sol.game.load(save_file)
  sol.main:start_savegame(game)
end


return game_manager
