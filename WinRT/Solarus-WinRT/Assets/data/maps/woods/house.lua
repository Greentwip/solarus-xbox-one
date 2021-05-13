local map = ...
local game = map:get_game()

-- Event called at initialization time, as soon as this map becomes is loaded.
function map:on_started()
  local chicken = map:get_entity("chicken")
  function chicken:on_interaction()
    game:start_dialog("woods.activist_house.chicken", function()
      chicken:prompt_item(function(item)
        if item and item:get_name() == "cultured_meat" then
          item:set_variant(0) -- destroy the item
          map:get_hero():start_treasure("flippers")
        end
      end)
    end)
  end
end
