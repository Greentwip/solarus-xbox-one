-- Lua script of custom entity mirror.
require("scripts/utils")

local entity = ...
local game = entity:get_game()
local map = entity:get_map()

-- This table contains all the information about the emitting points of mirrors:
-- x and y coordinates relative to the upper left corner of the bounding box and the number of pixels that
-- the light penetrates from that point.
-- It is called as
--
-- entity.reflecting_light_offset[mirror_d4][orientation][beam][coordinate]
--
--  mirror_d4    -- The mirror direction, from 0 to 3
--  orientation  -- Indicates the side of the mirror. 1 means in the horizontal axis and 2 means the opposite.
--                  That fully specifies it since this table only has information for the side
--                  which can transmit the light.
--  beam         -- As always considered in the code, 1 means the beam in left or up position and 2 the other
--  coordinate   -- 1 means x, 2 means y, 3 means how many pixels lights penetrates from x, y
--               -- this last value is signed indicating the direction of penetration as in windows coordinates
entity.reflecting_light_offset = {}
entity.reflecting_light_offset[0] = {{{16, 3, -2}, {16, 4, -2}}, {{7, -6, 0}, {8, -5, 0}}}
entity.reflecting_light_offset[1] = {{{-1, 3, 2}, {-1, 4, 2}}, {{7, -5, 0}, {8, -6, 0}}}
entity.reflecting_light_offset[2] = {{{-1, 3, 7}, {-1, 4, 7}}, {{7, 16, -13}, {8, 16, -13}}}
entity.reflecting_light_offset[3] = {{{16, 3, -7}, {16, 4, -7}}, {{7, 16, -13}, {8, 16, -13}}}

-- This table contains all the information about the contact points of light in the blocking sides of the mirror
-- (the contact points in the other sides are the same than the emitting points, so you can obtain them from
-- entity.reflecting_light_offset). The convention is the same than in entity.reflecting_light_offset.
entity.blocking_light_offset = {}
entity.blocking_light_offset[0] = {{{-1, 3, 4}, {-1, 4, 4}}, {{7, 16, -10}, {8, 16, -10}}}
entity.blocking_light_offset[1] = {{{16, 3, -4}, {16, 4, -4}}, {{7, 16, -10}, {8, 16, -10}}}
entity.blocking_light_offset[2] = {{{16, 3, -2}, {16, 4, -2}}, {{7, -6, 0}, {8, -6, 0}}}
entity.blocking_light_offset[3] = {{{-1, 3, 2}, {-1, 4, 2}}, {{7, -6, 0}, {8, -6, 0}}}

-- Moves an entity in the 16x16 grid
local function grid_movement(d4)
  local m = sol.movement.create("straight")
  m:set_max_distance(16)
  m:set_speed(30)
  m:set_angle(d4_to_angle(d4))
  return m
end

-- Event called when the custom entity is initialized.
function entity:on_created()
  self:set_traversable_by(false)
  self:set_can_traverse(false)
  self:set_drawn_in_y_order()
  self._cooldown = sol.timer.start(self, 0, function() end)
  self._reflecting = false
  self._blocking = false
  self:create_beams_inside_mirror()
end

-- Handle the hero pushing/pulling the entity
function entity:on_update()
  local hero = game:get_hero()
  local d4 = hero:get_direction()

  if not self:can_move() then
    return -- skip
  end

  if self:is_being_pushed() then self:push(d4) end
  if self:is_being_pulled() then self:pull(invert_d4(d4)) end
end

-- Push the entity
function entity:push(d4)
  log("Entity is being pushed")

  -- Set hero state
  local hero = game:get_hero()
  hero:freeze()
  hero:get_sprite():set_animation("pushing")

  -- Move entity
  local m = grid_movement(d4)
  function m:on_obstacle_reached()
    entity:stop_movement()
    hero:unfreeze()
  end
  m:start(self, function()
    entity:stop_movement() -- HACK: solarus-games/solarus#1396
    entity:snap_to_grid()
  end)

  -- Move hero
  local m_hero = grid_movement(d4)
  m_hero:set_smooth()
  m_hero:start(hero, function()
    hero:unfreeze()
    hero:start_grabbing()
    entity:start_cooldown()
  end)
end

-- Pull the entity
function entity:pull(d4)
  log("Entity is being pulled")

  -- Set hero state
  local hero = game:get_hero()
  hero:freeze()
  hero:get_sprite():set_animation("pulling")

  -- Move entity
  local m = grid_movement(d4)
  m:start(self, function()
    entity:stop_movement() -- HACK: solarus-games/solarus#1396
    entity:start_cooldown()
    entity:snap_to_grid()
  end)

  -- Move hero
  local m_hero = grid_movement(d4)
  m_hero:set_smooth()
  function m_hero:on_obstacle_reached()
    hero:unfreeze()
    hero:start_grabbing()
    entity:stop_movement() -- HACK: solarus-games/solarus#1396
  end
  m_hero:start(hero, function()
    hero:unfreeze()
    hero:start_grabbing()
  end)
end

-- Check if hero can move the entity (boolean)
function entity:can_move()
  return not self:is_moving() and self._cooldown:get_remaining_time() == 0
end

-- Check whether the entity is currently being pushed/pulled (boolean)
function entity:is_moving()
  return entity:get_movement() and true or false
end

-- Check whether the entity is being pushed (boolean)
function entity:is_being_pushed()
  local hero = game:get_hero()
  return self:overlaps(hero, "facing") and hero:get_state() == "pushing"
end

-- Check whether the entity is being pulled (boolean)
function entity:is_being_pulled()
  local hero = game:get_hero()
  return self:overlaps(hero, "facing") and hero:get_state() == "pulling"
end

-- Cooldown between pulling/pushing by 1 tile
function entity:start_cooldown()
  self._cooldown:stop()
  self._cooldown = sol.timer.start(self, 500, function() end)
end

-- It returns the emitting point of the mirror when light is being transmitted in the direction specified by
-- orientation parameter (0 for horizontal and 1 for vertical). you are allowed to pass the emitting direction instead of the raw orientation.
-- Third value indicates how many pixels the light is introduced in the sprite. It is signed.
function entity:get_light_emitting_point(orientation, beam)
  local x, y = self:get_bounding_box()
  local x_offset, y_offset, depth = unpack(self.reflecting_light_offset[self:get_sprite():get_direction()][orientation%2+1][beam])
  return x + x_offset, y + y_offset, depth
end

-- It returns the light blocking point of the mirror in the specified orientation
-- (0 for horizontal and 1 for vertical). You are free to pass the incoming direction of light too.
-- Third value indicates how many pixels the light is introduced in the sprite. It is signed.
function entity:get_light_blocking_point(orientation, beam)
  local x, y = self:get_bounding_box()
  local x_offset, y_offset, depth = unpack(self.blocking_light_offset[self:get_sprite():get_direction()][orientation%2+1][beam])
  return x + x_offset, y + y_offset, depth
end

-- Returns the light contact point of this entity in the specified incoming direction.
-- Third value indicates how many pixels the light is introduced in the sprite. It is signed.
function entity:get_light_contact_point(input_light_d4, beam)
  if self:get_reflecting_direction(input_light_d4) then
    return self:get_light_emitting_point(invert_d4(input_light_d4), beam)
  else
    return self:get_light_blocking_point(input_light_d4, beam)
  end
end

-- It returns the output direction in which light is reflected when it enters the mirror from the specified
-- direction. If the specified direction is not a incoming transmission direction of the mirror, nil is returned.
function entity:get_reflecting_direction(input_d4)
  local mirror_d4 = self:get_sprite():get_direction()
  local output_d4 = nil
  if mirror_d4 == 0 then
    if input_d4 == 3 then output_d4 = 0 end
    if input_d4 == 2 then output_d4 = 1 end
  elseif mirror_d4 == 1 then
    if input_d4 == 3 then output_d4 = 2 end
    if input_d4 == 0 then output_d4 = 1 end
  elseif mirror_d4 == 2 then
    if input_d4 == 1 then output_d4 = 2 end
    if input_d4 == 0 then output_d4 = 3 end
  else
    if input_d4 == 1 then output_d4 = 0 end
    if input_d4 == 2 then output_d4 = 3 end
  end
  return output_d4
end

-- This function creates the beams inside the mirror sprite.
-- It should be called only once. They will be drawn when an output beam is asked to be drawn with
-- set_light_beam() function
function entity:create_beams_inside_mirror()
  local mirror_d4 = self:get_sprite():get_direction()
  self.reflecting_beam_hor_in = {}
  self.reflecting_beam_ver_in = {}
  self.blocking_beam_hor_in = {}
  self.blocking_beam_ver_in = {}
  -- For mirrors that show completely internal beams, make them of variable length to match input beams
  if mirror_d4 == 2 or mirror_d4 == 3 then
    self.reflecting_beam_hor_in_adaptative = {}
    self.reflecting_beam_ver_in_adaptative = {}
  end

  for i = 1, 2 do
    -- Set the horizontal internal beams used when the mirror is reflecting light
    local depth = self.reflecting_light_offset[mirror_d4][1][i][3]
    if depth ~= 0 then
     self.reflecting_beam_hor_in[i] = sol.surface.create(math.abs(depth), 1)
     self.reflecting_beam_hor_in[i]:fill_color({255, 255, 255})
    end
    -- Set the vertical internal beams used  when the mirror is reflecting light
    local depth = self.reflecting_light_offset[mirror_d4][2][i][3]
    if depth ~= 0 then
      self.reflecting_beam_ver_in[i] = sol.surface.create(1, math.abs(depth))
      self.reflecting_beam_ver_in[i]:fill_color({255, 255, 255})
    end

    -- Set the variable-length internal beams used when the mirror is reflecting light
    if self.reflecting_beam_hor_in_adaptative then
      self.reflecting_beam_hor_in_adaptative[i] = {}
      self.reflecting_beam_ver_in_adaptative[i] = {}
      for j = 1, 16 do
        self.reflecting_beam_hor_in_adaptative[i][j] = sol.surface.create(j, 1)
        self.reflecting_beam_hor_in_adaptative[i][j]:fill_color({255, 255, 255})
        self.reflecting_beam_ver_in_adaptative[i][j] = sol.surface.create(1, j)
        self.reflecting_beam_ver_in_adaptative[i][j]:fill_color({255, 255, 255})
      end
    end
    -- Set the horizontal internal beams used when the mirror is blocking the light
    local depth = self.blocking_light_offset[mirror_d4][1][i][3]
    if depth ~= 0 then
     self.blocking_beam_hor_in[i] = sol.surface.create(math.abs(depth), 1)
     self.blocking_beam_hor_in[i]:fill_color({255, 255, 255})
    end
    -- Set the vertical internal beams used when the mirror is blocking the light
    local depth = self.blocking_light_offset[mirror_d4][2][i][3]
    if depth ~= 0 then
      self.blocking_beam_ver_in[i] = sol.surface.create(1, math.abs(depth))
      self.blocking_beam_ver_in[i]:fill_color({255, 255, 255})
    end
  end  
end

-- Set an output beam in direction d4 which beams have lengths length1 and length2
-- prev_entity is the entity which emits the light to this mirror. It is used to place correctly the beams
-- inside the mirror so they are weel drawn even when the emitting entity is being moved
function entity:set_light_beam(d4, length1, length2, prev_entity)
  self._reflecting = true
  if d4 == self._reflecting_d4 and length1 == self._reflecting_length[1] and length2 == self._reflecting_length[2] then return end
  self._reflecting_d4 = d4
  self._reflecting_length = {length1, length2}
  self._reflecting_entity = prev_entity
  self.beam_out = {}

  -- Create the output beam
  for i = 1, 2 do
    if self._reflecting_length[i] > 0 then
      if self._reflecting_d4 % 2 == 0 then
        self.beam_out[i] = sol.surface.create(self._reflecting_length[i], 1)
        self.beam_out[i]:fill_color({255, 255, 255})
      else
        self.beam_out[i] = sol.surface.create(1, self._reflecting_length[i])
        self.beam_out[i]:fill_color({255, 255, 255})    
      end
    else
      self.beam_out[i] = nil
    end
  end
end

-- This function must be called when this mirror is not reflecting the light anymore
function entity:unset_light_beam()
  self._reflecting = false
  self._reflecting_d4 = mil
  self._reflecting_length = nil
  self._reflecting_entity = nil
  self.beam_out = nil
end

-- This function must be called when this mirror is blocking the light comming in direction d4
-- d4 should be a blocking direction for the sprite direction of the mirror 
function entity:block_light(d4, emitting_entity)
  self._blocking = true
  self._blocking_d4 = d4
  self._blocking_entity = emitting_entity
end

-- This function must be called when this mirror is not blocking the light anymore 
function entity:unset_blocking_light()
  self._blocking = false
  self._blocking_d4 = nil
  self._blocking_entity = nil
end

-- Beams are drawn in this function
function entity:on_post_draw()
  local function sgn(x)
    return x > 0 and 1 or - 1
  end
  -- Draw beams inside the mirror sprite when it is reflecting light
  if self._reflecting then
    for i = 1, 2 do
      -- Draw horizontal beam inside the mirror sprite
      if self.reflecting_beam_hor_in[i] then
        local x, y, depth = self:get_light_emitting_point(0, i)
        local x_init = math.min(x + sgn(depth), x + depth)
        -- Correct the beam inside using the coordinates of the comming light
        if self._reflecting_d4 % 2 == 1 then
          local _, y_emitting = self._reflecting_entity:get_light_emitting_point(0, i)
          map:draw_visual(self.reflecting_beam_hor_in[i], x_init, y_emitting)
        elseif self._reflecting_d4 % 2 == 0 and self.reflecting_beam_hor_in_adaptative then
          local x_emitting = self._reflecting_entity:get_light_emitting_point(1, 2)
          if self.reflecting_beam_hor_in_adaptative[i][math.abs(x_emitting - x - sgn(depth)) + 1] then map:draw_visual(self.reflecting_beam_hor_in_adaptative[i][math.abs(x_emitting - x - sgn(depth)) + 1], math.min(x + sgn(depth), x_emitting), y) end
        else
          map:draw_visual(self.reflecting_beam_hor_in[i], x_init, y)
        end
      end

      -- Draw vertical beam inside the mirror sprite
      if self.reflecting_beam_ver_in[i] then
        local x, y, depth = self:get_light_emitting_point(1, i)
        local y_init = math.min(y + sgn(depth), y + depth)
        -- Correct the beam inside using the coordinates of the comming light
        if self._reflecting_d4 % 2 == 0 then
          local x_emitting = self._reflecting_entity:get_light_emitting_point(1, i)
          map:draw_visual(self.reflecting_beam_ver_in[i], x_emitting, y_init)
        elseif self._reflecting_d4 % 2 == 1 and self.reflecting_beam_ver_in_adaptative then
          local _, y_emitting = self._reflecting_entity:get_light_emitting_point(0, 1)
          if self.reflecting_beam_ver_in_adaptative[i][math.abs(y_emitting - y + 1) + 1] then map:draw_visual(self.reflecting_beam_ver_in_adaptative[i][math.abs(y_emitting - y + 1) + 1], x, math.min(y - 1, y_emitting)) end
        else
          map:draw_visual(self.reflecting_beam_ver_in[i], x, y_init)
        end
      end

      if self.beam_out[i] then
        if self._reflecting_d4 % 2 == 0 then
          local x, y, depth = self:get_light_emitting_point(0, i)
          map:draw_visual(self.beam_out[i], self._reflecting_d4 == 0 and x or x - self._reflecting_length[i] + 1, y)
        else
          local x, y, depth = self:get_light_emitting_point(1, i)
          map:draw_visual(self.beam_out[i], x, self._reflecting_d4 == 1 and y - self._reflecting_length[i] + 1 or y)
        end
      end
    end
  end
  -- Draw beams inside the mirror sprite when it is blocking light
  if self._blocking then
    for i = 1, 2 do
      if self.blocking_beam_hor_in[i] and self._blocking_d4 % 2 == 0 then
        local x, y, depth = self:get_light_blocking_point(0, i)
        local entity_x, entity_y = self._blocking_entity:get_light_emitting_point(0, i)
        map:draw_visual(self.blocking_beam_hor_in[i], math.min(x + sgn(depth), x + depth), entity_y)
      end

      if self.blocking_beam_ver_in[i] and self._blocking_d4 % 2 == 1 then
        local x, y, depth = self:get_light_blocking_point(1, i)
        local entity_x, entity_y = self._blocking_entity:get_light_emitting_point(1, i)
        map:draw_visual(self.blocking_beam_ver_in[i], entity_x, math.min(y + sgn(depth), y + depth))
      end
    end
  end
end
