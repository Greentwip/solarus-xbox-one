-- Lua script of map _stage/adaptative_outline.
-- This script is executed every time the hero enters this map.

-- Feel free to modify the code below.
-- You can add more events and remove the ones you don't need.

-- See the Solarus Lua API documentation:
-- http://www.solarus-games.org/doc/latest

local map = ...
local game = map:get_game()

-- Event called at initialization time, as soon as this map is loaded.
function map:on_started()
  self:start_darkness()
  -- You can initialize the movement and sprites of various
  -- map entities here.
end

function separator1:on_activating(d4)
  map:stop_darkness()
  if d4 == 0 then map:start_darkness(300, false, "radius", 40) end
  if d4 == 2 then map:start_darkness() end
end

function separator2:on_activating(d4)
  map:stop_darkness()
  if d4 == 0 then map:start_darkness(30, true, "facing") end
  if d4 == 2 then map:start_darkness(300, false, "radius", 40) end
end

function separator3:on_activating(d4)
  map:stop_darkness()
  if d4 == 0 then map:start_darkness(30, false, "facing") end
  if d4 == 2 then map:start_darkness(30, true, "facing", 30) end
end

-- Event called after the opening transition effect of the map,
-- that is, when the player takes control of the hero.
function map:on_opening_transition_finished()

end