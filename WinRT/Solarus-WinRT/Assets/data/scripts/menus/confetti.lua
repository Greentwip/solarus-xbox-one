-- Confetti!

local confetti = {}

function confetti:on_started()
  log("Confetti started!")
  -- Create confetti surfaces
  self.main_surface   = sol.surface.create()
  self.confetti_small = sol.surface.create("menus/confetti_small.png")
  self.confetti_big   = sol.surface.create("menus/confetti_big.png")
  -- Set up the movements
  do
    local m = sol.movement.create("straight")
    m:set_speed(50)
    m:set_angle(3 * math.pi / 2)
    m:start(self.confetti_small)
  end
  do
    local m = sol.movement.create("straight")
    m:set_speed(70)
    m:set_angle(3 * math.pi / 2)
    m:start(self.confetti_big)
  end
end

function confetti:on_draw(dst_surface)
  -- Draw the confetti
  self.main_surface:clear()
  self.confetti_small:draw_region(0, 0, 272, 288, self.main_surface, -8, -288)
  self.confetti_big:draw_region(0, 0, 272, 288, self.main_surface, -8, -288)
  self.main_surface:draw(dst_surface)
end

function confetti:on_update()
  -- End the menu when the small confetti is no longer visible
  local x, y = self.confetti_small:get_xy()
  log("confetti y: " .. y)
  if y > 650 then -- FIXME: I don't understand why this extra padding is needed
    sol.menu.stop(self)
  end
end

function confetti:on_finished()
  log("Confetti ended")
end

return confetti
