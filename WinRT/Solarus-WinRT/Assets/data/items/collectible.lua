-- Lua script of item collectible.
-- This script is executed only once for the whole game.

local item = ...
local game = item:get_game()

function item:on_obtaining(variant, savegame_variable)
  game:set_value("collectible_"..variant, 1)
end
