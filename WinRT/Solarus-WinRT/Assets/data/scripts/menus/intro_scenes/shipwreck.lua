-- Ship crashes into the cliff
require("scripts/utils")

local scene = {}

-- Called when the menu starts
function scene:on_started()

  do -- Create main surface
    local width, height = sol.video.get_quest_size()
    self.main_surface = sol.surface.create(width, height)
  end

  -- Load graphics
  self.bg_gfx    = sol.sprite.create("menus/intro/island_bg")
  self.foam_gfx  = sol.sprite.create("menus/intro/beach_foam")
  self.shine_gfx = sol.sprite.create("menus/intro/ocean_shine")
  self.cloud_lg  = sol.sprite.create("menus/intro/cloud_large")
  self.cloud_sm  = sol.sprite.create("menus/intro/cloud_small")
  self.boat_gfx  = sol.sprite.create("menus/intro/little_boat")

  do -- Big cloud going right
    local m = translate("x", 195)
    m:set_speed(2)
    m:start(self.cloud_lg)
  end

  do -- Little cloud going left
    local m = translate("x", -80)
    m:set_speed(2)
    m:start(self.cloud_sm)
  end

  do -- Boat going right, then crashing
    local m = translate("x", -62)
    m:set_speed(12)
    m:start(self.boat_gfx, function()
      self.boat_gfx:set_animation("crashed")
      sol.timer.start(1000, function()
        -- Fade out, pause for a few seconds, then end
        sol.audio.play_music("cosmicgem829/title", false)
        self.main_surface:fade_out(5, function()
          self.main_surface:set_opacity(0)
          sol.timer.start(2000, function()
            sol.menu.stop(scene)
          end)
        end)
      end)
    end)
  end

end

-- Called every frame
function scene:on_draw(dst_surface)
  local main_surface = self.main_surface

  dst_surface:fill_color({255, 255, 255})

  self.bg_gfx:draw(main_surface) -- draw the BG
  self.foam_gfx:draw(main_surface, 68, 80)
  self.shine_gfx:draw(main_surface, 224, 80)
  self.cloud_lg:draw(main_surface, 59, 26)
  self.cloud_sm:draw(main_surface, 212, 58)
  self.boat_gfx:draw(main_surface, 195, 100)

  main_surface:draw(dst_surface)
end

return scene
