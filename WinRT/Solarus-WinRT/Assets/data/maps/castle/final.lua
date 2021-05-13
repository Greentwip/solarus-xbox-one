-- Lua script of map Water_Dungeon_final.
-- This script is executed every time the hero enters this map.

-- Feel free to modify the code below.
-- You can add more events and remove the ones you don't need.

-- See the Solarus Lua API documentation:
-- http://www.solarus-games.org/doc/latest

local map = ...

-- Event called at initialization time, as soon as this map becomes is loaded.
function map:on_started()

  local greybeard = map:get_entity("greybeard")
  function greybeard:on_interaction()
    -- Talk to Greybeard, end the games.
    -- TODO: Rest of the sequence.
    map:get_game():start_ending()
  end
end

-- Event called after the opening transition effect of the map,
-- that is, when the player takes control of the hero.
function map:on_opening_transition_finished()

end
