-- Lua script of map forest.
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
  local mimosa = map:get_entity("mimosa")

  function mimosa:set_watered(watered)
    assert(type(watered), "boolean")
    game:set_value("mimosa_watered", watered)
    mimosa:get_sprite():set_animation("green") -- TODO: 1.6, set sprite instead
  end

  function mimosa:is_watered()
    return game:get_value("mimosa_watered")
  end

  -- Set to brown if not watered
  if not mimosa:is_watered() then
    mimosa:get_sprite():set_animation("brown") -- TODO: 1.6, set sprite instead
  end

  -- Mimosa interaction
  function mimosa:on_interaction()
    if self:is_watered() then
      -- Already been watered
      game:start_dialog("forest.mimosa.water.watered")
      return
    end
    -- Not watered, prompt for item
    game:start_dialog("forest.mimosa.water.needs_water", function()
      mimosa:prompt_item(function(item)
        if item and item:get_name() == "tears" then
          item:set_variant(0) -- destroy the tears
          mimosa:set_watered(true)
          game:start_dialog("forest.mimosa.water.thanks", function()
            hero:start_treasure("b12")
          end)
        elseif item and item:get_name() == "whiskey" then
          game:start_dialog("forest.mimosa.wrong_item.whiskey")
        elseif item and item:get_name() == "seed" then
          game:start_dialog("forest.mimosa.wrong_item.seed")
        -- b12 should be impossible to give to the plant
        -- dialog set anyways
        elseif item and item:get_name() == "b12" then
          game:start_dialog("forest.mimosa.wrong_item.b12")
        else
          game:start_dialog("forest.mimosa.water.no")
        end
      end)
    end)
  end

end
