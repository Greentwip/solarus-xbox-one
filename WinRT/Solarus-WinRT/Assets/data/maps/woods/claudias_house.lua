-- Lua script of map woods_cave.
-- This script is executed every time the hero enters this map.

-- Feel free to modify the code below.
-- You can add more events and remove the ones you don't need.

-- See the Solarus Lua API documentation:
-- http://www.solarus-games.org/doc/latest

local map = ...
local game = map:get_game()
local hero = game:get_hero()

-- Event called at initialization time, as soon as this map becomes is loaded.
function map:on_started()
  -- Vase behavior
  if game:get_value("claudia_plant_watered") then
    vase_plant:get_sprite():set_animation("stopped")
  else
    vase_plant:set_enabled(false)
  end
end

-- Claudia's behavior
function claudia:on_interaction()
  local has_vacuum  = game:has_item("vacuum")

  -- Player has the vacuum, stop the script here
  if has_vacuum then
    game:start_dialog("beach.seagulls.claudia.3")
    return true
  end

  -- Given whiskey and watered plant
  if game:get_value("claudia_whiskey")
     and game:get_value("claudia_plant_watered")
  then
    game:start_dialog("beach.seagulls.claudia.4", function()
      game:get_hero():start_treasure("vacuum") -- get the vacuum
    end)
    return true
  end

  -- Given only the whiskey
  if game:get_value("claudia_whiskey") then
    game:start_dialog("beach.seagulls.claudia.5")
    return true
  end

  -- Whiskey/vacuum sequence
  game:start_dialog("beach.seagulls.claudia.1", function()
    claudia:prompt_item(function(item)
      if item and item:get_name() == "whiskey" then
        item:set_variant(0) -- kill the whiskey
        game:set_value("claudia_whiskey", true)
        game:start_dialog("beach.seagulls.claudia.2", function()
          if game:get_value("claudia_plant_watered") then
            claudia:on_interaction()
          end
        end)
      elseif item and item:get_name() == "seed" then
        game:start_dialog("beach.seagulls.claudia.wrong_item.seed")
      elseif item and item:get_name() == "tears" then
        game:start_dialog("beach.seagulls.claudia.wrong_item.tears")
      elseif item and item:get_name() == "b12" then
        game:start_dialog("beach.seagulls.claudia.wrong_item.b12")
      elseif item then
        game:start_dialog("game.misc.nothanks")
      end
    end)
  end)
end

function vase:on_interaction()
  if vase_plant:is_enabled() then
    return true
  end
  game:start_dialog("beach.vase", function()
    vase:prompt_item(function(item)
      if item and item:get_name() == "seed" then
        item:set_variant(0) -- destroy the seed
        vase_plant:set_enabled(true)
        vase_plant:get_sprite():set_animation("growing", function()
          game:set_value("claudia_plant_watered", true)
          vase_plant:get_sprite():set_animation("stopped")
        end)
        log("Seed planted!")
      elseif item and item:get_name() == "whiskey" then
        game:start_dialog("beach.vase.wrong_item.whiskey")
      elseif item and item:get_name() == "tears" then
        game:start_dialog("beach.vase.wrong_item.tears")
      elseif item and item:get_name() == "b12" then
        game:start_dialog("beach.vase.wrong_item.b12")
      elseif item then
        game:start_dialog("game.misc.didntwork")
      end
    end)
  end)
end
