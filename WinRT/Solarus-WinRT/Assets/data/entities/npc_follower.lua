-- Lua script of custom entity npc_follower.
local entity = ...
local game = entity:get_game()
local map = entity:get_map()

-- Event called when the custom entity is initialized.
function entity:on_created()

  -- Rolling buffer of states
  self._npc_states = {first = 0, last = -1}

  -- Initialize older position of the hero
  local hero = game:get_hero()
  self.x, self.y, self.z = hero:get_position()
end

-- Returns the sprite ID
function entity:get_type()
  return self.sprite_id
end

-- Set the sprite according to passed sprite ID
function entity:set_type(sprite_id)
  local hero = game:get_hero()

  self:remove_sprite()
  self:create_sprite(sprite_id)
  self.sprite_id = sprite_id
  self:get_sprite():set_direction(hero:get_sprite():get_direction())

  self:bring_to_front()
  game:set_value("npc_follower", sprite_id)
end

-- Reset the states of the rolling buffer
function entity:reset_states()
  if self._npc_states.last >= self._npc_states.first then
    for i = self._npc_states.first, self._npc_states.last do
      self._npc_states[i] = nil
    end
  end
  self._npc_states.first = 0
  self._npc_states.last = -1
end

-- Add a new position to the rolling buffer
function entity:push_states(x, y, z, animation, frame, direction)
  local last = self._npc_states.last + 1
  self._npc_states.last = last
  self._npc_states[last] = {x, y, z, animation, frame, direction}
end

-- Extract position of rolling buffer
function entity:pop_states()
  local first = self._npc_states.first
  local value = self._npc_states[first]
  self._npc_states[first] = nil
  self._npc_states.first = first + 1
  return value[1], value[2], value[3], value[4], value[5], value[6]
end

-- Return number of states saved in the rolling buffer
function entity:n_states()
  return self._npc_states.last - self._npc_states.first
end

-- Save the state of the hero in the rolling buffer and update the sprite if it is full
function entity:update_buffer(hero_x, hero_y, hero_z)
  local hero = game:get_hero()

  local positions_delay = 16
  local hero_sprite = hero:get_sprite()
  local npc_sprite = self:get_sprite()
  local buffer_full = self:n_states() == positions_delay

  -- Push state
  local hero_state = {
    hero_x, hero_y, hero_z,
    hero_sprite:get_animation(),
    hero_sprite:get_direction(),
    hero_sprite:get_frame()
  }
  self:push_states(unpack(hero_state))

  -- Update sprite if buffer is full
  if buffer_full then
    local npc_state = {self:pop_states()}
    self:set_position(npc_state[1], npc_state[2], npc_state[3])
    if npc_state[4] ~= npc_sprite:get_animation() and npc_sprite:has_animation(npc_state[4]) then
      npc_sprite:set_animation(npc_state[4])
    end
    npc_sprite:set_direction(npc_state[5])
  end

end

-- Called on each cycle
function entity:on_update()

  -- Update the buffer
  local hero = map:get_hero()
  local x, y, z = hero:get_position()  
  if self.x ~= x or self.y ~=y or self.z ~=z then
    self:update_buffer(x, y, z)
    self.x = x
    self.y = y
    self.z = z
  end

  -- Stop NPC follower when Rachel stops
  local stopped_animations = {"stopped", "pushing", "pulling"}
  local npc_follower = map:get_entity("npc_follower")
  if npc_follower and not npc_follower.free then
    for _, a in ipairs(stopped_animations) do
      if hero:get_sprite():get_animation() == a then
        npc_follower:get_sprite():set_animation("stopped")
      end
    end
  end
end
