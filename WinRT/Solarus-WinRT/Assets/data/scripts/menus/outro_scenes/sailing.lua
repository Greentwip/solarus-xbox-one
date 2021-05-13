local scene = {}

-- Called when the scene is created
function scene:on_started()
  self._gfx = {}
  self._gfx.ocean = sol.sprite.create("menus/outro/ocean2")
  self._gfx.sun = sol.sprite.create("menus/outro/sun2")
  self._gfx.island = sol.sprite.create("menus/outro/island")
  self._gfx.cloud_small = sol.sprite.create("menus/outro/cloud_small")
  self._gfx.cloud_big = sol.sprite.create("menus/outro/cloud_big")
  self._gfx.ship = sol.sprite.create("menus/outro/little_boat")

  do -- boat
    local m = sol.movement.create("straight")
    m:set_angle(math.pi) -- West
    m:set_speed(8)
    m:start(self._gfx.ship)
  end

  do -- sun
    local m = sol.movement.create("straight")
    m:set_angle(math.pi / 2) -- North
    m:set_speed(8)
    m:set_max_distance(52)
    m:start(self._gfx.sun)
  end

  do -- cloud small
    local m = sol.movement.create("straight")
    m:set_angle(0) -- East
    m:set_speed(4)
    m:start(self._gfx.cloud_small)
  end

  do -- cloud big
    local m = sol.movement.create("straight")
    m:set_angle(0) -- East
    m:set_speed(8)
    m:start(self._gfx.cloud_big)
  end

  sol.timer.start(self, 7000, function()
    self:start_dialog()
  end)

end

-- Called every frame
function scene:on_draw(dst_surface)
  dst_surface:fill_color({255, 98, 80})
  self._gfx.sun:draw(dst_surface, 142, 80)
  self._gfx.ocean:draw(dst_surface, 0, 96)
  self._gfx.island:draw(dst_surface, 200, 44)
  self._gfx.cloud_big:draw(dst_surface, -20, -11)
  self._gfx.cloud_small:draw(dst_surface, 224, -6)
  self._gfx.ship:draw(dst_surface, 176, 79)
end

-- Called when the boat finished animating
function scene:start_dialog()
  local game = sol.main.game
  game:start_dialog("game.outro.2", {vertical_position="top"}, function()
    sol.menu.stop(self)
  end)
end

return scene
