-- Lua script of custom entity wood_log.
-- This script is executed every time a custom entity with this model is created.

require("scripts/utils")

local entity = ...
local game = entity:get_game()
local map = entity:get_map()
local hero = game:get_hero()

-- Event called when the custom entity is initialized.
function entity:on_created()
  self:set_traversable_by(false) -- It's like a wall
  self:set_can_traverse_ground("deep_water", true)
  self:set_can_traverse("jumper", true)
  self:set_modified_ground("traversable")

  -- Determine the log's orientation
  self._orient = self:get_property("orientation")
  if not self._orient then
    local d4 = self:get_sprite():get_direction()
    self._orient = d4 % 2 == 0 and "vertical" or "horizontal"
  end

  -- Check if it is on water
  if self:get_ground_below() == "deep_water" then
    self:get_sprite():set_animation("floating")
    self:set_on_water_properties()
  end
end

-- Handle the hero pushing the log
function entity:on_update()
  if self:is_being_pushed() then
    log("A wood log is being pushed by the hero")
    local direction = hero:get_direction()
    if self:can_roll(direction) then
      self:roll(direction)
    end
  end
end

-- Check whether the log is currently rolling (boolean)
function entity:is_rolling()
  return entity:get_movement() and true or false
end

-- Check whether the log is being pushed (boolean)
function entity:is_being_pushed()
  return self:overlaps(hero, "facing") and hero:get_state() == "pushing"
end

-- Returns true if it's okay to roll the log a particular direction4
function entity:can_roll(d4)
  if self:is_rolling() then return false end -- You can't roll a rolling log
  if self._orient == "vertical"   and d4%2 == 1 then return false end -- Can't roll a vertical log up or down
  if self._orient == "horizontal" and d4%2 == 0 then return false end -- Can't roll a horizontal log left or right
  return true
end

-- Force the log to roll in the given direction4
function entity:roll(d4)
  self:get_sprite():set_animation("rolling", "stopped")
  local m = sol.movement.create("straight")
  m:set_angle(d4_to_angle(d4))
  m:set_max_distance(16)
  m:set_speed(40)
  m:set_smooth(false)
  function m:on_obstacle_reached()
    m:stop() -- let walls stop the movement
    entity:get_sprite():set_animation("stopped") -- prevent animation if the log is blocked from moving
  end
  m:start(self, function()
    self:stop_movement() -- destroy the movement when it ends
    self:on_roll_finished(d4)
  end)
end

-- Causes the log to drift 1 tile in deep water
function entity:drift(d4)
  self:get_sprite():set_animation("splash", "floating")
  hero:freeze()
  map:get_camera():shake(function()
    hero:unfreeze()
  end)
  local m = sol.movement.create("straight")
  m:set_angle(d4_to_angle(d4))
  m:set_max_distance(16)
  m:set_speed(40)
  m:set_smooth(false)
  function m:on_obstacle_reached()
    m:stop() -- let walls stop the movement
  end
  m:start(self, function()
    self:stop_movement() -- destroy the movement when it ends
    self:on_drift_finished()
  end)
end

-- Called when the roll is done
function entity:on_roll_finished(d4)
  local ground_below = self:get_ground_below()
  log("Ground below log: " .. ground_below)

  if ground_below == "deep_water" then
    self:drift(d4)
  end
end

-- Called when the drift is done
function entity:on_drift_finished()
  log("Drift finished")
  self:set_on_water_properties()
end

function entity:set_on_water_properties()
  self:set_traversable_by("hero", true)
  local x, y, width, height = self:get_bounding_box()
  local layer = select(3, self:get_position())
  x = x + tonumber(self:get_property("jumper_x_offset") or 0)
  y = y + tonumber(self:get_property("jumper_y_offset") or 0)
  map:create_jumper({layer=layer, x=x-8, y=y+height, width=width+16, height=8,  direction=6, jump_length=tonumber(self:get_property("down_jump_length") or 32)}) -- bottom
  map:create_jumper({layer=layer, x=x-8, y=y-8,      width=width+16, height=8,  direction=2, jump_length=tonumber(self:get_property("up_jump_length") or 32)}) -- top
  map:create_jumper({layer=layer, x=x+width, y=y-8,  width=8, height=height+16, direction=0, jump_length=tonumber(self:get_property("right_jump_length") or 32)}) -- right
  map:create_jumper({layer=layer, x=x-8, y=y-8,      width=8, height=height+16, direction=4, jump_length=tonumber(self:get_property("left_jump_length") or 32)}) -- left
end

-- Returns true if the log is submerged in water
function entity:is_submerged()
  local in_water = self:get_ground_below() == "deep_water"
  local is_floating = self:get_sprite():get_animation() == "floating"
  return in_water and is_floating
end
