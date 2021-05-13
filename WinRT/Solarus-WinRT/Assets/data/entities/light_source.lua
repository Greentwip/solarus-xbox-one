-- Lua script of custom entity laser_source.

local entity = ...
local game = entity:get_game()
local map = entity:get_map()

-- The entities which type is in this list will not stop the light
entity.black_list_blocking_entities = {
  ["camera"] = true,
  ["destination"] = true,
  ["teletransporter"] = true,
  ["sensor"] = true
}

-- Define where light touches entities that have not its own defined function get_light_contact_point()
local function get_default_light_contact_point(entity, d4, beam)
  local x, y = entity:get_bounding_box()
  if d4 == 0 then
    return x - 1, y + 2 + beam, 0
  elseif d4 == 1 then
    return x + 6 + beam, y + 16, 0
  elseif d4 == 2 then
    return x + 16, y + 2 + beam, 0
  else
    return x + 6 + beam, y - 1, 0
  end
end

-- This function decides the where the light stops when touching an entity
local function get_light_contact_point(entity, input_d4, beam)
  if entity.get_light_contact_point then
    return entity:get_light_contact_point(input_d4, beam)
  else
    return get_default_light_contact_point(entity, input_d4, beam)
  end
end

-- Draw the light beam emitted from entity until next_entity
-- d4 is the direction of propagation
-- n_calls is the n-th time that light has been emitted 
function entity:draw_light_beam(entity, d4, next_entity, n_calls)

  -- Set start and end of the light beam
  local start1_x, start1_y = entity:get_light_emitting_point(d4, 1)
  local start2_x, start2_y = entity:get_light_emitting_point(d4, 2)
  local end1_x, end1_y, end2_x, end2_y = nil, nil, nil, nil
  if next_entity then
    end1_x, end1_y = get_light_contact_point(next_entity, d4, 1)
    end2_x, end2_y = get_light_contact_point(next_entity, d4, 2)
  else
    local map_width, map_height = map:get_size()
    if d4 == 0 then
      end1_x, end1_y, end2_x, end2_y = map_width - 1, start1_y, map_width - 1, start2_y
    elseif d4 == 1 then
      end1_x, end1_y, end2_x, end2_y = start1_x, 0, start2_x, 0 
    elseif d4 == 2 then
      end1_x, end1_y, end2_x, end2_y = 0, start1_y, 0, start2_y
    else
      end1_x, end1_y, end2_x, end2_y = start1_x, map_height - 1, start2_x, map_height - 1
    end
  end

  -- Calculate length of the beams
  local length1, length2 = nil, nil
  if d4 == 0 then
    -- The max function is needed in some cases due to relative positions of bounding_boxes and light points
    length1 = math.max(0, end1_x - start1_x + 1)
    length2 = math.max(0, end2_x - start2_x + 1)
  elseif d4 == 1 then
    length1 = math.max(0, start1_y - end1_y + 1)
    length2 = math.max(0, start2_y - end2_y + 1)
  elseif d4 == 2 then
    length1 = math.max(0, start1_x - end1_x + 1)
    length2 = math.max(0, start2_x - end2_x + 1)
  else
    length1 = math.max(0, end1_y - start1_y + 1)
    length2 = math.max(0, end2_y - start2_y + 1) 
  end

  -- Ask the emitting entity to draw the beam
  if n_calls == 1 then
    entity:set_light_beam(d4, length1, length2)
  elseif n_calls == 2 then
    entity:set_light_beam(d4, length1, length2, self)
  else
    entity:set_light_beam(d4, length1, length2, self.transmitters_list[n_calls-2])
  end
end

-- This function get an emitting entity and a direction of propagation
-- It finds the first entity that overlaps the light beam
-- If it is a mirror correctly orientated, this function calls itself to propagate the transmission of the light
-- If the last entity is light receiver, it is activated
-- This function draws also the beam
-- n_calls must be 1 the first time this function is called. It increased by one by successive calls
function entity:propagate_laser_beam(emitting_entity, d4, n_calls)

  local map_width, map_height = map:get_size()
  -- Get the point of emitting light from the entity
  local x, y = emitting_entity:get_light_emitting_point(d4, 1)

  local next_entity = nil
  -- Loop until find the first obstacle
  while(x >= 0 and x < map_width and y >= 0 and y < map_height)
  do
    -- Entities obtained by map:get_entities_in_rectangle can have a bounding box outside the rectangle
    --local rect_x, rect_y = test_entity:get_center_position()
    for entity_i in map:get_entities_in_rectangle(x, y, 1, 1)
    --for entity_i in map:get_entities()
    do
      if entity_i ~= emitting_entity and not self.black_list_blocking_entities[entity_i:get_type()] and entity_i:overlaps(x, y) then
        next_entity = entity_i
        break
      end
    end
    if next_entity then break end

    -- Update position of test entity if no obstacle is found
    if d4 == 0 then
      x = x + 1
    elseif d4 == 1 then
      y = y - 1
    elseif d4 == 2 then
      x = x - 1
    else
      y = y + 1
    end
  end

  -- Update the drawing of the light beam
  self:draw_light_beam(emitting_entity, d4, next_entity, n_calls)

  -- Clean transmitters list if next entity has changed
  if self.transmitters_list[n_calls] and self.transmitters_list[n_calls] ~= next_entity then
    for i = #self.transmitters_list, n_calls, -1 do
      self.transmitters_list[i]:unset_light_beam()
      self.transmitters_list[i] = nil
    end
  end

  -- Propagate the light under correct conditions:
  -- a mirror in the right direction which is not currently reflecting, so it does not cause an infinite loop
  local transmitted = false
  if next_entity and next_entity:get_type() == "custom_entity" and next_entity:get_model() == "mirror" then
    local reflecting_direction = next_entity:get_reflecting_direction(d4)
    local infinite_loop = false
    for i = 1, n_calls-1 do
      if next_entity == self.transmitters_list[i] then infinite_loop = true end
    end
    if reflecting_direction and not infinite_loop then
      transmitted = true
      -- Update the list of entities that are transmitting this beam
      self.transmitters_list[n_calls] = next_entity
      self:propagate_laser_beam(next_entity, reflecting_direction, n_calls+1)
    end
  end

  -- Manage what happens when light is blocked
  if not transmitted then
    -- Undo actions on entity that was previosly blocking the light
    if self.blocking_entity and self.blocking_entity ~= next_entity then
      -- Tell to an entity that it is not blocking the light anymore
      if self.blocking_entity.unset_blocking_light then self.blocking_entity:unset_blocking_light() end
      -- Deactivate a receiver
      if self.blocking_entity:get_type() == "custom_entity" and self.blocking_entity:get_model() == "light_receiver" then self.blocking_entity:set_activated(false) end
    end
    -- Do actions on blocking entity that was not previously blocking
    if not self.blocking_entity or self.blocking_entity ~= next_entity then
      if next_entity.block_light then next_entity:block_light(d4, emitting_entity) end
      if next_entity:get_type() == "custom_entity" and next_entity:get_model() == "light_receiver" then next_entity:set_activated(true, emitting_entity) end
    end
    -- Update currently blocking action
    self.blocking_entity = next_entity
  end
end

-- Event called when the custom entity is initialized.
function entity:on_created()
  self._activated = false
  self._blocking = false
  self.transmitters_list = {}
  x, y, depth = self:get_light_emitting_point(3, 1)
  self.beam_in = sol.surface.create(2, math.abs(depth))
  self.beam_in:fill_color({255, 255, 255})
  self.beam_out = {}
end

-- Activate/deactivate the light source
function entity:set_activated(bool_state)
  if bool_state or bool_state == nil then
    self._activated = true
    self:get_sprite():set_animation("activated")
  else
    self._activated = false
    self:get_sprite():set_animation("deactivated")
    self.beam_out = {}    
    for i = #self.transmitters_list, 1, -1 do
      self.transmitters_list[i]:unset_light_beam()
      self.transmitters_list[i] = nil
    end
    if self.blocking_entity and self.blocking_entity.unset_blocking_light then self.blocking_entity:unset_blocking_light() end
  end
end

-- Draw an output beam
-- d4 is not used, it should be always 3
-- length1 and length2 are the lengths of beams 1 and 2
function entity:set_light_beam(d4, length1, length2)
  self._beam_length = {length1, length2}
  for i = 1, 2 do
    if self._beam_length[i] > 0 then
      self.beam_out[i] = sol.surface.create(1, self._beam_length[i])
      self.beam_out[i]:fill_color({255, 255, 255})
    else
      self.beam_out[i] = nil
    end
  end
end

-- This function should be called when this entity is blocking some light beam
function entity:block_light(d4, emitting_entity)
  self._blocking = true
  self._blocking_entity = emitting_entity
end

-- This function should be called when this entity is not blocking a light beam any more
function entity:unset_blocking_light()
  self._blocking = false
end

-- In this function it is managed the part of the beam covering the pixels of this sprite
function entity:on_post_draw()
  if self._activated or self._blocking then
    local x, y, depth = self:get_light_emitting_point(3, 1)
    if self._blocking then
      local x_entity, y_entity = self._blocking_entity:get_light_contact_point(1, 1)
      x = x_entity
    end
    map:draw_visual(self.beam_in, x, y+depth)
  end
  if self._activated then
    for i = 1, 2 do
      local x, y = self:get_light_emitting_point(3, i)
      if self.beam_out[i] then map:draw_visual(self.beam_out[i], x, y) end
    end
  end
end

-- If this entity has been activated, this function propagate the beam until it is blocked
-- If it results too expensive, it should be reconsidered to move the code to a timer in on_created()
function entity:on_update()
  if self._activated then
    self:propagate_laser_beam(self, 3, 1)
  end
end

-- It returns the coordinates in which light comming in direction 1 touches the entity
-- d4 is not used but should be 1
function entity:get_light_contact_point(d4, beam)
  local x, y = self:get_bounding_box()
  return x + 6 + beam, y + 16, -8
end

-- It returns the coordinates in which light is started to be emitted in direction 3
-- d4 is not used but should be 3
function entity:get_light_emitting_point(d4, beam)
  return self:get_light_contact_point(1, beam)
end