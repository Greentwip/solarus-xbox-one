-- Lua script of custom entity antihero.
-- This script is executed every time a custom entity with this model is created.

local entity = ...
local game = entity:get_game()
local map = entity:get_map()

-- Event called when the custom entity is initialized.
function entity:on_created()
  self:set_traversable_by("hero", false)
  local x0, y0, z0 = self:get_position()
  local hero = map:get_hero()
  local hero_x0, hero_y0, hero_z0 = hero:get_position()
  local hero_sprite = hero:get_sprite()
  -- Set animation and frame
  hero_sprite:register_event("on_frame_changed", function(self_hero_sprite, animation, frame)
    self:get_sprite():set_animation(animation)
    self:get_sprite():set_frame(frame)
  end)
  -- Set direction
  hero_sprite:register_event("on_direction_changed", function(self_hero_sprite, animation, direction)
    if direction == 1 then
      self_direction = 3
    elseif direction == 3 then
      self_direction = 1
    else
      self_direction = direction
    end
    self:get_sprite():set_direction(self_direction)
  end)
  -- Set position
  hero:track(function(hero_x, hero_y, hero_z)
    self:set_position(hero_x, y0 + hero_y0 - hero_y, hero_z)
  end)
end
