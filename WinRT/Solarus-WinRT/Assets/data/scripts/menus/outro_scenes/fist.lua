require("scripts/coroutine_helper")

local scene = {}

-- Called when the scene is created
function scene:on_started()
  self._gfx = {}
  self._gfx.ocean = sol.surface.create(256, 40)
  self._gfx.ocean:fill_color({32, 208, 240})
  self._gfx.sun = sol.sprite.create("menus/outro/sun3")
  self._gfx.rachel = sol.sprite.create("menus/outro/rachel")

  sol.menu.start_coroutine(self, function()
    local m1 = sol.movement.create("straight")
    m1:set_angle(0)
    m1:set_speed(384)
    m1:set_max_distance(256)
    m1:start(self._gfx.rachel)
    local m2 = sol.movement.create("straight")
    m2:set_angle(0)
    m2:set_speed(128)
    m2:set_max_distance(96)
    m2:start(self._gfx.sun)
    dialog("game.outro.4", {vertical_position="top"})
    sol.menu.stop(self)
  end, sol.main.game)
end

-- Called every frame
function scene:on_draw(dst_surface)
  dst_surface:fill_color({160, 240, 240})
  self._gfx.ocean:draw(dst_surface, 0, 104)
  self._gfx.sun:draw(dst_surface, 18, 50)
  self._gfx.rachel:draw(dst_surface, -100, 44)
end

return scene
