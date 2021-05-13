-- Makes bats fly through the dungeon

local entity = ...
local game = entity:get_game()
local map = entity:get_map()

-- Event called when the custom entity is initialized.
function entity:on_created()
  self._frame_delay = tonumber(self:get_property("frame_delay")) or 10
  self._threshold = tonumber(self:get_property("threshold")) or 1
  self._invert = self:get_property("invert") == "1"
  self._x, self._y = self:get_position()
end

-- Returns true if the entity is off screen
function entity:is_offscreen()
  local camera = map:get_camera()
  return not (self:overlaps(camera) or self:overlaps(camera, "touching"))
end

-- function entity:activate()
--   sol.timer.start(self, 40, function()
--     local x, y = entity:get_position()
--     x = x - 1
--     self:set_position(x, 8*math.sin(x) + self._y)
--     return true
--   end)
-- end

function entity:activate()
  local m = sol.movement.create("pixel")
  m:set_delay(self._frame_delay)
  m:set_ignore_obstacles()

  local trajectory = {}
  for x = 1, 1000 do
      local dy = self._threshold*x
      local dx = 1
      if self._invert then dx = -1 end
      trajectory[#trajectory + 1] = {dx, dy}
  end
  m:set_trajectory(trajectory)

  function m.on_position_changed(m)
    if self:is_offscreen() then
      self:remove()
      log("bat removed")
    end
  end

  m:start(self)
end
