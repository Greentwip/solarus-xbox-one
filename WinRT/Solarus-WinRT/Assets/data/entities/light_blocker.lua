-- Lua script of custom entity light_blocker.
local entity = ...
local game = entity:get_game()
local map = entity:get_map()

-- Event called when the custom entity is initialized.
function entity:on_created()
  local x, y, depth = self:get_light_contact_point(1, 1)
  self.beam_in = sol.surface.create(2, math.abs(depth))
  self.beam_in:fill_color({255, 255, 255})
end

-- Returns the light contact point of this entity in the specified incoming direction.
function entity:get_light_contact_point(d4, beam)
  local x, y = self:get_bounding_box()
  if d4 == 0 then
    return x - 1, y + 2 + beam, 0
  elseif d4 == 1 then
    return x + 6 + beam, y + 16, -8
  elseif d4 == 2 then
    return x + 16, y + 2 + beam, 0
  else
    return x + 6 + beam, y - 1, 0
  end
end

-- This function should be called when this entity is blocking some light beam
function entity:block_light(d4, emitting_entity)
  self._blocking = true
  self._blocking_d4 = d4
  self._blocking_entity = emitting_entity
end

-- This function should be called when this entity is not blocking a light beam any more
function entity:unset_blocking_light()
  self._blocking = false
end

-- In this function it is managed the part of the beam covering the pixels of this sprite
function entity:on_post_draw()
  if self._blocking and self._blocking_d4 == 1 then
    local x, y, depth = self:get_light_contact_point(1, 1)
    local x_entity, y_entity = self._blocking_entity:get_light_contact_point(self._blocking_d4, 1)
    x = x_entity
    map:draw_visual(self.beam_in, x, y+depth)
  end
end