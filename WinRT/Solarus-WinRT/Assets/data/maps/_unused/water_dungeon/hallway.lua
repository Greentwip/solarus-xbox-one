-- Lua script of map water_dungeon_hallway.
-- This script is executed every time the hero enters this map.

-- Feel free to modify the code below.
-- You can add more events and remove the ones you don't need.

-- See the Solarus Lua API documentation:
-- http://www.solarus-games.org/doc/latest

local map = ...
local game = map:get_game()

-- Event called at initialization time, as soon as this map becomes is loaded.
function map:on_started()

  -- You can initialize the movement and sprites of various
  -- map entities here.

 -- Fix block teletransporter behavior: https://gitlab.com/solarus-games/solarus/issues/725
  for transporter in map:get_entities_by_type("teletransporter") do
    function transporter:on_activated()
      for overlap in map:get_entities_in_region(transporter) do
        if overlap:get_type() == "block" then
          overlap:reset()
        end
      end
    end
  end

end

-- Event called after the opening transition effect of the map,
-- that is, when the player takes control of the hero.
function map:on_opening_transition_finished()

end
