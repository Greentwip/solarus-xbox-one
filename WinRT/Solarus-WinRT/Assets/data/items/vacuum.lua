-- The vacuum can be used to suck up some objects
-- in front of Rachel.

-- This script is executed only once for the whole game.

require("scripts/utils")

local item = ...


-- Called when the game is initialized.
function item:on_started()
  self._power = 0
  self._power_timers = {}
  self._sound_timers = {}
  self._vacuuming = {}

  self:set_savegame_variable("vacuum")
  self:set_assignable(true)
end


-- Set the power level of the vacuum
function item:vacuum(power)
  assert(tonumber(power),
         "vacuum:vacuum() got "..power..", but it must a number.")
  self._power = power
  self:_play_sound()
  for _, entity in ipairs(self._vacuuming) do
    log(string.format("Vacuuming (%d): %s (%d, %d, %d)", power, entity:get_type(), entity:get_position()))
    if entity.on_vacuum_changed then
      entity:on_vacuum_changed(power)
    end
  end
end


-- Called when the item button is held.
function item:on_command_pressed(command)
  log(string.format("%s command pressed", item:get_name()))
  local hero = item:get_map():get_hero()
  if hero:get_state() ~= "free" then
    return
  end
  hero:freeze() -- prevent the hero from moving with the vacuum
  hero:set_animation("vacuum") -- set hero's sprite

  self._vacuuming = self:get_vacuumable_entities()
  self:vacuum(1)

  log("Vacuum is being used.")
  log(string.format("Vacuumable Rectangle: x = %d, y = %d, width = %d, height = %d", self:get_vacuumable_rectangle()))
  for _, entity in ipairs(self._vacuuming) do
    log(string.format("Entity: %s (%d, %d, %d)", entity:get_type(), entity:get_position()))
  end

  -- After 0.3s, increase the vacuum power
  self._power_timers[1] = sol.timer.start(self, 300, function()
    self:vacuum(2)
  end)

  -- After 1 second, increase the vacuum power
  self._power_timers[2] = sol.timer.start(self, 1000, function()
    self:vacuum(3)
  end)
end


-- Called when the item button is released.
function item:on_command_released(command)
  log(string.format("%s command released", item:get_name()))
  local hero = item:get_map():get_hero()
  if hero:get_animation() ~= "vacuum" then
    return
  end
  hero:unfreeze()
  hero:set_animation("stopped")
  self:vacuum(0)

  -- Release all entities
  sol.timer.stop_all(self)

  -- Set all sound timers to nil
  -- FIXME: I don't understand why looping through them didn't work
  self._sound_timers[1] = nil
  self._sound_timers[2] = nil
  self._sound_timers[3] = nil

  item:set_finished()
end


-- Gets entities in the vacuumable rectangle, returns them as an array
function item:get_vacuumable_entities()
  local entity_iter = item:get_map():get_entities_in_rectangle(
    self:get_vacuumable_rectangle()
  )
  -- Convert to an array
  local entities = {}
  for entity in entity_iter do
    table.insert(entities, entity)
  end
  return entities
end


-- Get vacuumable rectangle (based on where the hero is).
function item:get_vacuumable_rectangle()
  local hero = item:get_map():get_hero()

  -- Hero's position
  local hero_x, hero_y = hero:get_position()
  local direction      = hero:get_direction()

  -- Hero's direction
  local hero_up    = direction == 1
  local hero_right = direction == 0
  local hero_down  = direction == 3
  local hero_left  = direction == 2

  -- Vacuumable rectangle size.
  -- 16x32 or 32x16 depending on the hero's direction.
  local width, height

  if hero_up or hero_down then
    width = 16
    height = 32
  elseif hero_left or hero_right then
    width = 32
    height = 16
  end

  -- Vacuumable rectangle position.
  -- Hero's origin point == (8, 13)
  -- Hero's size         == 16x16
  local x, y

  if hero_up then
    x = hero_x - 8
    y = hero_y - (32 + 13)
  elseif hero_down then
    x = hero_x - 8
    y = hero_y + 3
  elseif hero_left then
    y = hero_y - 13
    x = hero_x - (32 + 8)
  elseif hero_right then
    y = hero_y - 13
    x = hero_x + 8
  end

  -- Return rectangle's xpos, ypos, width, and height in pixels
  return x, y, width, height
end


-- Handle repeating sfx
-- FIXME: Make this code not horrible!
-- See: https://gitlab.com/solarus-games/solarus/issues/1289
function item:_play_sound()
  if self._power == 1 and not self._sound_timers[1] then
    log("sfx start: Vacuum 1")
    sol.audio.play_sound("vacuum_1")
    self._sound_timers[1] = sol.timer.start(self, 180, function()
      self._sound_timers[1] = nil
      item:_play_sound()
    end)
  elseif self._power == 2 and not self._sound_timers[2] then
    log("sfx start: Vacuum 2")
    sol.audio.play_sound("vacuum_2")
    self._sound_timers[2] = sol.timer.start(self, 125, function()
      self._sound_timers[2] = nil
      item:_play_sound()
    end)
  elseif self._power == 3 and not self._sound_timers[3] then
    log("sfx start: Vacuum 3")
    sol.audio.play_sound("vacuum_3")
    self._sound_timers[3] = sol.timer.start(self, 125, function()
      self._sound_timers[3] = nil
      item:_play_sound()
    end)
  end
end
