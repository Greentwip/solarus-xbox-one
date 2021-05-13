-- This script initializes game values for a new savegame file.
-- You should modify the initialize_new_savegame() function below
-- to set values like the initial life and equipment
-- as well as the starting location.
--
-- Usage:
-- local initial_game = require("scripts/initial_game")
-- initial_game:initialize_new_savegame(game)

local initial_game = {}

-- Sets initial values to a new savegame file.
function initial_game:initialize_new_savegame(game)

  -- Starting location
  if sol.main.is_debug_enabled()then
    game:set_starting_location("debug")
  else
    game:set_starting_location("beach/teepee")
  end

  game:set_max_life(12)
  game:set_life(game:get_max_life())
  game:set_ability("lift", 1)
  game:set_ability("sword", 0)
  game:get_item("id_card"):set_variant(1)
  game:set_max_magic(20) -- Set max level of stamina

  local running_shoes = game:get_item("running_shoes")
  running_shoes:set_variant(1)
  game:set_item_assigned(2, running_shoes)

end

return initial_game
