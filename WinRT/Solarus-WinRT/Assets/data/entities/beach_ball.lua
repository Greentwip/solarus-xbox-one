-- Lua script of custom entity beach_ball.

require("scripts/utils")

local entity = ...
local game = entity:get_game()
local map = entity:get_map()

-- Event called when the custom entity is initialized.
function entity:on_created()
  self:set_traversable_by(false)
  self:set_can_traverse_ground("deep_water", true)

  self:add_collision_test("facing", function()
    if self:can_drift() then
      log("A beach ball is being pushed by the hero")
      local d4 = map:get_hero():get_direction()
      self:drift(d4)
    end
  end)
end

-- Return if the beach ball can drift or not
function entity:can_drift()
  if entity:get_movement() then
    return false
  else
    return true
  end
end

-- Force the ball to drift in a given direction
function entity:drift(d4)
  local m = sol.movement.create("straight")
  m:set_angle(d4_to_angle(d4))
  m:set_max_distance(32)
  m:set_speed(80)
  function m:on_obstacle_reached()
    m:stop() -- let walls stop the movement
  end
  m:start(self, function()
    self:stop_movement() -- destroy the movement when it ends
  end)
end
