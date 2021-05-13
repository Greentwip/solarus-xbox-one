-- Rachel ponders her invitation
require("scripts/utils")

local scene = {}

-- Called when the scene is started
function scene:on_started()
  self.rachel_gfx = sol.sprite.create("menus/intro/rachel_large")
  self.bubble_gfx = sol.sprite.create("menus/intro/thought_bubble")
  self.arm_gfx    = sol.sprite.create("menus/intro/rachel_arm")
  self.eyes_gfx   = sol.sprite.create("menus/intro/rachel_eyes")

  -- move speech bubble down
  sol.timer.start(500, function()
    self.bubble_gfx:set_xy(0, 41)
    self.bubble_gfx:set_animation("loading", function()
      self.bubble_gfx:set_animation("finished")
      sol.timer.start(500, function()
        sol.menu.stop(scene)
      end)
    end)
  end)

  do -- move arm left/right
    local m = sol.movement.create("pixel")
    m:set_loop(true)
    m:set_delay(200)
    m:set_trajectory({
      {0, 0}, {0, 0}, {0, 0}, {0, 0},
      {-1, 0}, {1, 0}, {-1, 0}, {1, 0},
      {0, 0}, {0, 0}, {0, 0}, {0, 0},
      {0, 0}, {0, 0}, {0, 0}, {0, 0},
    })
    function m.on_position_changed(m)
      local x, y = m:get_xy()
      if x == -1 then
        self.arm_gfx:set_animation("2")
      else
        self.arm_gfx:set_animation("1")
      end
    end
    m:start(self.arm_gfx)
  end

  function blink(cb)
    self.eyes_gfx:set_animation("closed")
    sol.timer.start(scene, 120, function()
      self.eyes_gfx:set_animation("open")
      if cb then cb() end
    end)
  end

  function start_blink_loop()
    sol.timer.start(scene, 2000, function()
      blink(function()
        start_blink_loop()
      end)
    end)
  end

  start_blink_loop()

end

-- Called every frame
function scene:on_draw(dst_surface)
  dst_surface:fill_color({160, 255, 144})
  self.rachel_gfx:draw(dst_surface, 83, 12)
  self.bubble_gfx:draw(dst_surface, 168, -24)
  self.arm_gfx:draw(dst_surface, 83, 56)
  self.eyes_gfx:draw(dst_surface, 116, 49)
end

return scene
