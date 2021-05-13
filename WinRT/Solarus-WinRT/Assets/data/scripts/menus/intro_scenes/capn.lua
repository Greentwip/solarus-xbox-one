-- Pans across Rachel on her boat
require("scripts/utils")

local scene = {}

-- Called when the scene is created
function scene:on_started()
  self.main_surface = sol.surface.create(512, 256)
  -- Load graphics
  self.boat_gfx  = sol.sprite.create("menus/intro/boat")
  self.sky_gfx   = sol.surface.create(512, 95)
  self.sky_gfx:fill_color({160, 240, 240})
  self.cloud_lg  = sol.sprite.create("menus/intro/cloud_large")
  self.cloud_sm  = sol.sprite.create("menus/intro/cloud_small")
  self.shine_gfx = sol.sprite.create("menus/intro/ocean_shine")

  do -- Pan the scene
    local m = sol.movement.create("target")
    -- m:set_target(-256, -112) -- perflectly diagonal
    m:set_target(-120, -88)
    m:set_speed(36)
    m:start(self.main_surface, function()
      sol.menu.stop(scene)
    end)
  end

  do -- Move big cloud
    local m = translate("x", -232)
    m:set_speed(70)
    m:start(self.cloud_lg)
  end

  do -- Move small cloud
    local m = translate("x", -232)
    m:set_speed(30)
    m:start(self.cloud_sm)
  end
end

-- Called every frame
function scene:on_draw(dst_surface)
  local main_surface = self.main_surface

  main_surface:fill_color({32, 208, 240})
  self.sky_gfx:draw(main_surface)
  self.cloud_lg:draw(main_surface, 146, 10)
  self.cloud_sm:draw(main_surface, 242, 57)
  self.boat_gfx:draw(main_surface, 184, 32)
  self.shine_gfx:draw(main_surface, 144, 104)
  self.shine_gfx:draw(main_surface, 344, 192)

  main_surface:draw(dst_surface)
end

return scene
