-- Lua script of map _stage/before_catacombs.
-- This script is executed every time the hero enters this map.

local map = ...
local game = map:get_game()
local hero = map:get_hero()

-- Event called at initialization time, as soon as this map is loaded.
function map:on_started()
  hero:create_Billie()

  function cutscene1:on_activated()

    -- Skip if already activated
    if game:get_value("catacombs_cutscene1") then
      cutscene1:set_enabled(false)
      return
    end

    -- Cue dialog
    hero:freeze()
    hero:think()
    hero:get_sprite():set_direction(3)
    game:start_dialog("catacombs.outside.billie.1", function()
      game:set_value("catacombs_cutscene1", 1)
      hero:get_sprite():set_direction(1)
      hero:unfreeze()
    end)
  end
end
