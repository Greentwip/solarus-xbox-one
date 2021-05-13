-- Lua script of map _stage/underground_river.
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

  -- Save current swim ability and allow the hero to swim in this map
  self.prev_swim_ability = self:get_game():get_ability("swim")
  self:get_game():set_ability("swim", 1)
end

-- Restore previous swim ability 
function map:on_finished()
  self:get_game():set_ability("swim", self.prev_swim_ability)
end

-- Event called after the opening transition effect of the map,
-- that is, when the player takes control of the hero.
function map:on_opening_transition_finished()

end
