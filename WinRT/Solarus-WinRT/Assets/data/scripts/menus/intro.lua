-- Intro sequence that plays at the start of the game

-- Load scenes
local scenes = {
  require("scripts/menus/intro_scenes/letter"),
  require("scripts/menus/intro_scenes/hmm"),
  require("scripts/menus/intro_scenes/ok"),
  require("scripts/menus/intro_scenes/capn"),
  require("scripts/menus/intro_scenes/shipwreck"),
}


local intro = {}

-- Called when the intro menu is started with sol.menu.start()
function intro:on_started()
  log("Intro started")
  self.current_scene = 1
  sol.audio.play_music("cosmicgem829/intro")

  -- Loop through the scenes
  for i, scene in ipairs(scenes) do
    -- When each scene ends, play the next one
    function scene:on_finished()
      log("Finished scene ", i)
      local next_scene = scenes[i+1]
      if next_scene then
        intro.current_scene = i+1
        sol.menu.start(intro, next_scene)
      else
        -- Final scene, stop the intro menu
        sol.menu.stop(intro)
      end
    end
  end

  -- Start the first scene
  sol.menu.start(intro, scenes[1])
end


-- Let the intro be skipped
function intro:on_command_pressed(command)
  if command == "action" or command == "pause" or command == "item_1" then
    log("Intro skipped in scene ", self.current_scene, "/", #scenes)
    for i = self.current_scene, #scenes do
      scenes[i].on_finished = nil
      sol.menu.stop(scenes[i])
    end
    sol.menu.stop(intro)
  end
  return true
end


return intro
