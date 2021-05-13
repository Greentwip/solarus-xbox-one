-- Outro sequence that plays at the end of the game

-- Load scenes
local scenes = {
  require("scripts/menus/outro_scenes/sunrise"),
  require("scripts/menus/outro_scenes/sailing"),
  require("scripts/menus/outro_scenes/fist")
}


local outro = {}

-- Called when the outro menu is started with sol.menu.start()
function outro:on_started()
  log("Outro started")
  sol.main.game:get_map():get_hero():freeze()

  self.current_scene = 1

  -- TODO: Add music
  -- sol.audio.play_music("outro")

  -- Loop through the scenes
  for i, scene in ipairs(scenes) do
    -- When each scene ends, play the next one
    function scene:on_finished()
      log("Finished scene ", i)
      local next_scene = scenes[i+1]
      if next_scene then
        outro.current_scene = i+1
        sol.menu.start(outro, next_scene)
      else
        -- Final scene, stop the outro menu
        sol.menu.stop(outro)
      end
    end
  end

  -- Start the first scene
  sol.menu.start(outro, scenes[1])
end

return outro
