-- Lua script of map _stage/catacombs_dungeon.
-- This script is executed every time the hero enters this map.

local map = ...
local game = map:get_game()

-- Event called at initialization time, as soon as this map is loaded.
function map:on_started()
  self:start_darkness()

  function cutscene2:on_activated()

    -- Skip if already activated
    if game:get_value("catacombs_cutscene2") then
      cutscene2:set_enabled(false)
      return
    end

    -- Cue dialog
    game:start_dialog("catacombs.entrance.billie.1", function()
      game:set_value("catacombs_cutscene2", 1)
    end)
  end


  function cutscene3:on_activated()

    -- Skip if already activated
    if game:get_value("catacombs_cutscene3") then
      cutscene3:set_enabled(false)
      return
    end

    -- Cue dialog
    game:start_dialog("catacombs.rachel.spider", function()
      game:set_value("catacombs_cutscene3", 1)
    end)
  end

end
