-- Custom script to extend the functionality of the camera

local camera_meta = sol.main.get_metatable("camera")

function camera_meta:shake(callback)
  local hero = self:get_map():get_hero()
  local tracked_entity = self:get_tracked_entity()
  local m = sol.movement.create("pixel")
  m:set_ignore_obstacles(true)
  m:set_trajectory({
    {2, 2},
    {-2, -2},
    {1, 1},
    {-1, -1}
  })
  m:set_delay(100)
  m:start(self)
  sol.timer.start(self, 500, function()
    self:start_tracking(tracked_entity)
    if callback then
      callback()
    end
  end)
end

-- Implement camera pan effect
function camera_meta:focus_on(target_entity, speed, callback)
  local m = sol.movement.create("target")
  m:set_target(self:get_position_to_track(target_entity))
  m:set_speed(speed)
  m:set_ignore_obstacles(true)
  m:start(self, function()
    self:start_tracking(target_entity)
    if callback then callback() end
  end)
end
