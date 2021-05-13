-- Lua script of map _stage/catacombs_entrance.
-- This script is executed every time the hero enters this map.

local map = ...
local game = map:get_game()

-- Event called at initialization time, as soon as this map is loaded.
function map:on_started()
  self:start_darkness()
end