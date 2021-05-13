-- Lua script of map debug.
-- This script is executed every time the hero enters this map.

-- Feel free to modify the code below.
-- You can add more events and remove the ones you don't need.

-- See the Solarus Lua API documentation:
-- http://www.solarus-games.org/doc/latest

local map = ...
local game = map:get_game()

-- Event called at initialization time, as soon as this map is loaded.
function map:on_started()

  -- You can initialize the movement and sprites of various
  -- map entities here.
end

-- Event called after the opening transition effect of the map,
-- that is, when the player takes control of the hero.
function map:on_opening_transition_finished()

end

function cutscene_1:on_activated()
  hero:teleport("overworld", "cutscene_1")
end

function cutscene_2:on_activated()
  game:set_value("cutscene1", true)
  game:set_value("stick_chest", true)
  game:get_item("stick"):set_variant(1)
  hero:teleport("overworld", "east_beach")
end

function cutscene_3:on_activated()
  game:set_value("cutscene1", true)
  game:set_value("stick_chest", true)
  game:get_item("stick"):set_variant(1)
  game:get_item("id_card"):set_variant(2)
  hero:create_follower("animals/beaver")
  hero:teleport("evolv/foyer")
end

function cutscene_4:on_activated()
  game:set_value("cutscene1", true)
  game:set_value("stick_chest", true)
  game:get_item("stick"):set_variant(1)
  game:get_item("id_card"):set_variant(2)
  game:set_value("hermione_asleep", true)
  hero:teleport("evolv/foyer", "lab")
end

function cutscene_5:on_activated()
  game:set_value("cutscene1", true)
  game:set_value("stick_chest", true)
  game:get_item("stick"):set_variant(1)
  game:get_item("id_card"):set_variant(2)
  game:set_value("hermione_asleep", true)
  game:set_value("cutscene4", true)
  hero:teleport("overworld", "east_beach")
  game:set_value("bridge_switch", true)
end
