-- "OK" appears on the screen and shakes. Animated BG.
require("scripts/utils")

local scene = {}

-- Called when the scene starts
function scene:on_started()
  self.ok_bubble_gfx = sol.sprite.create("menus/intro/ok_bubble")
  self.ok_gfx        = sol.sprite.create("menus/intro/ok")
  self.dot_gfx       = sol.sprite.create("menus/intro/dot")
  self.dot_surface   = sol.surface.create(512, 288)

  do -- Shiver the "OK"
    local m = shiver()
    m:set_intensity(4)
    m:set_delay(30)
    m:start(self.ok_gfx)
  end

  -- Draw the dots
  function draw_dots()
    local row = 0
    local col = 0
    while not finished do
      local x = col * 40
      local y = row * 40
      if x >= 512 then
        row = row + 1
        col = 0
      end
      if y >= 288 then
        return
      end
      x = col * 40
      y = row * 40
      self.dot_gfx:draw(self.dot_surface, x, y)
      col = col + 1
    end
  end

  draw_dots()

  do -- Move dots
    local m = sol.movement.create("straight")
    m:set_angle(math.pi * 1.25) -- 225 degrees
    m:set_speed(120)
    m:start(self.dot_surface)
  end

  -- End after a second
  sol.timer.start(1000, function()
    sol.menu.stop(scene)
  end)
end

-- Called every frame
function scene:on_draw(dst_surface)
  dst_surface:fill_color({32, 208, 240})
  self.dot_surface:draw(dst_surface, 0, -144)
  self.ok_bubble_gfx:draw(dst_surface, 44, 16)
  self.ok_gfx:draw(dst_surface, 58, 18)
end

return scene
