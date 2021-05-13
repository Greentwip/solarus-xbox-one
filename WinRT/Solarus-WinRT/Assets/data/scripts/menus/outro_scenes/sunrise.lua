-- A boat against the sunrise
require("scripts/coroutine_helper")
require("scripts/utils")

local scene = {}

-- Called when the scene is created
function scene:on_started()
  -- Load graphics
  self._gfx = {}
  self._gfx.sun = sol.sprite.create("menus/outro/sun1")
  self._gfx.ocean = sol.sprite.create("menus/outro/ocean1")
  self._gfx.shine = sol.sprite.create("menus/outro/ocean_shine")
  self._gfx.stars = sol.sprite.create("menus/outro/stars")
  self._gfx.cloud_left = sol.sprite.create("menus/outro/cloud_left")
  self._gfx.cloud_right = sol.sprite.create("menus/outro/cloud_right")
  self._gfx.shore = sol.sprite.create("menus/outro/shore")
  self._gfx.boat = sol.sprite.create("menus/outro/boat1")

  do -- Move the sun up
    local m = sol.movement.create("straight")
    m:set_angle(math.pi / 2) -- North
    m:set_speed(8)
    m:set_max_distance(21)
    m:start(self._gfx.sun)
  end

  do -- clouds
    local speed = 4
    local distance = 16
    local m1 = sol.movement.create("straight")
    local m2 = sol.movement.create("straight")

    m1:set_angle(math.pi)
    m1:set_speed(speed)
    m1:set_max_distance(distance)
    m1:start(self._gfx.cloud_left)

    m2:set_angle(0)
    m2:set_speed(speed)
    m2:set_max_distance(distance)
    m2:start(self._gfx.cloud_right)
  end

  sol.menu.start_coroutine(self, function()
    wait(7000)
    dialog("game.outro.1", {vertical_position="top"})
    local m1 = shiver()
    m1:start(self._gfx.boat)
    wait(1000)
    m1:stop()
    wait(500)
    local m2 = sol.movement.create("target")
    m2:set_target(0, 96+48)
    m2:set_speed(8)
    movement(m2, self._gfx.shore)
    wait(2000)
    sol.menu.stop(self)
  end, sol.main.game)

end

-- Called every frame
function scene:on_draw(dst_surface)
  dst_surface:fill_color({112, 16, 255})
  self._gfx.cloud_left:draw(dst_surface, 0, -4)
  self._gfx.cloud_right:draw(dst_surface, 176, -4)
  self._gfx.sun:draw(dst_surface, 112, 64)
  self._gfx.stars:draw(dst_surface, 96, 0)
  self._gfx.ocean:draw(dst_surface, 0, 64)
  self._gfx.shine:draw(dst_surface, 112, 64)
  self._gfx.shore:draw(dst_surface, 0, 96)
  self._gfx.boat:draw(dst_surface, 64, 80)
end

return scene
