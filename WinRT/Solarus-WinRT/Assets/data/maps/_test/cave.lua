-- Lua script of map _test/cave.
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
  self_map = self
  for entity in self:get_entities_by_type("teletransporter")
  do
    function entity:on_activated()
      self_map:stop_darkness()
      self_map:start_darkness()
    end
  end
end

-- Event called after the opening transition effect of the map,
-- that is, when the player takes control of the hero.
function map:on_opening_transition_finished()

end
