-- Lua script of custom entity pipe.
-- This script is executed every time a custom entity with this model is created.

local entity = ...
local game = entity:get_game()
local map = entity:get_map()
local hero = game:get_hero()

-- Event called when the custom entity is initialized.
function entity:on_created()
  self:set_traversable_by(false) -- It's like a wall

  -- Determine the pipe's orientation
  self._orient = self:get_property("orientation")
  if not self._orient then
    local d4 = self:get_sprite():get_direction()
    self._orient = d4 % 2 == 0 and "vertical" or "horizontal"
  end  
end

-- Handle the hero pushing the pipe
function entity:on_update()
  if self:is_being_pushed() then
    log("A pipe is being pushed by the hero")
    local direction = hero:get_direction()
    if self:can_roll(direction) then
      self:roll(direction)
    end
  end
end

-- Check whether the pipe is currently rolling (boolean)
function entity:is_rolling()
  return entity:get_movement() and true or false
end

-- Check whether the pipe is being pushed (boolean)
function entity:is_being_pushed()
  return self:overlaps(hero, "facing") and hero:get_state() == "pushing"
end

-- Returns true if it's okay to roll the pipe a particular direction4
function entity:can_roll(d4)
  if self:is_rolling() then return false end -- You can't roll a rolling pipe
  if self._orient == "vertical"   and d4%2 == 1 then return false end -- Can't roll a vertical pipe up or down
  if self._orient == "horizontal" and d4%2 == 0 then return false end -- Can't roll a horizontal pipe left or right
  return true
end

-- Force the pipe to roll in the given direction4
function entity:roll(d4)
  self:get_sprite():set_animation("rolling")
  local m = sol.movement.create("straight")
  m:set_angle(d4_to_angle(d4))
  m:set_speed(40)
  m:set_smooth(false)
  function m:on_obstacle_reached()
    m:stop() -- let walls stop the movement
    entity:get_sprite():set_animation("stopped") -- prevent animation if the pipe is blocked from moving
  end
  m:start(self, function()
    self:stop_movement() -- destroy the movement when it ends
  end)
end