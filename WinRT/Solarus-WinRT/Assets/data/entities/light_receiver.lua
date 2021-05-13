-- Lua script of custom entity light_receiver.
-- This script is executed every time a custom entity with this model is created.

-- Feel free to modify the code below.
-- You can add more events and remove the ones you don't need.

-- See the Solarus Lua API documentation for the full specification
-- of types, events and methods:
-- http://www.solarus-games.org/doc/latest

local entity = ...
local game = entity:get_game()
local map = entity:get_map()

-- Event called when the custom entity is initialized.
function entity:on_created()
  self:set_traversable_by(false)
  self._activated = false
  x, y, depth = self:get_light_contact_point(1, 1)
  self.beam_in = sol.surface.create(2, math.abs(depth))
  self.beam_in:fill_color({255, 255, 255})
end

-- Call this function when light arrives for first time to the receiver (bool_state = true) or when the light
-- does not arrive anymore (bool_state = false) 
-- Second parameter is only needed when bool_state is true and it must be the last transmitter emitting
-- the light to the receiver
function entity:set_activated(bool_state, entity)
  if bool_state then
    self._activated = true
    self:get_sprite():set_animation("activated")
    self._activated_entity = entity
  else
    self._activated = false
    self:get_sprite():set_animation("deactivated")
  end
end

-- Returns the light contact point of this entity in the specified incoming direction.
-- Third value indicates how many pixels the light is introduced in the sprite. It is signed.
function entity:get_light_contact_point(light_d4, beam)
  local x, y = self:get_bounding_box()
  if light_d4 == 0 then
    local offset_x = beam == 1 and 2 or 1 
    return x + offset_x, y + 2 + beam, 0
  elseif light_d4 == 1 then
    return x + 6 + beam, y + 15, -5
  elseif light_d4 == 2 then
    return x + 16, y + 2 + beam, 0
  else
    return x + 6 + beam, y - 1, 0
  end
end

-- It draws the part of the incoming beam over the sprite
function entity:on_post_draw()
  if self._activated then
    local x, y, depth = self:get_light_contact_point(1, 1)
    local x_entity, y_entity = self._activated_entity:get_light_contact_point(1, 1)
    x = x_entity
    map:draw_visual(self.beam_in, x, y+depth)
  end
end
