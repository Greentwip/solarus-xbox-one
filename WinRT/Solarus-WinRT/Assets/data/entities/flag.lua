-- Lua script of custom entity flag.

local entity = ...
local game = entity:get_game()
local map = entity:get_map()
local hero = map:get_hero()
local sprite = entity:get_sprite()
local dialog = entity:get_property("dialog")
local savegame_variable = entity:get_property("savegame_variable")


-- Event called when the custom entity is initialized.
function entity:on_created()

  -- Set defaults
  self._state = "inactivated"
  self._hero_speed = hero:get_walking_speed()

  -- Load state from gamesave
  if savegame_variable and game:get_value(savegame_variable) then
    self._state = "activated"
    sprite:set_animation("activated")
  end
end


-- Get state: "inactivated", "depressed", "released", or "activated"
function entity:get_state()
  return self._state
end


-- Set state
function entity:set_state(state)
  local error_str = "Invalid state. Must be one of: inactivated, stepped, left, activated."
  assert(type(state) == "string", error_str)
  assert(in_table(state, {"inactivated", "stepped", "left", "activated"}), error_str)
  self._state = state
  self:on_state_changed(state)
end


-- Process state change
function entity:on_state_changed(state)
  return self['on_'..state](self)
end


-- Called once when the hero steps on the entity
function entity:on_stepped()
  sprite:set_animation("pressing", "pressed")
  hero:set_walking_speed(self._hero_speed * 0.4)
end


-- Called once when the hero leaves the entity
function entity:on_left()

  -- Flag animation
  sprite:set_animation("releasing", function()
    self:set_state("activated")
  end)

  -- Hero sprint
  hero:set_walking_speed(self._hero_speed * 2.4)
  sol.timer.start(hero, 120, function()
    hero:set_walking_speed(self._hero_speed)
  end)
end


-- Called after leaving on_left()
function entity:on_activated()

  -- Set animation
  sprite:set_animation("activated")

  -- Start dialog
  if dialog then
    game:start_dialog(dialog)
  end

  -- Save state
  game:set_value(savegame_variable, true)
end


-- Clean up entity, only triggered by manually setting the state
function entity:on_inactivated()

  -- Set animation
  sprite:set_animation("inactivated")

  -- Save state
  game:set_value(savegame_variable, false)
end


-- Game loop
function entity:on_update()
  local hero_collision = hero:overlaps(self, "origin")
  local flag_state = self:get_state()

  if hero_collision and flag_state ~= "stepped" then
    return self:set_state("stepped")
  end

  if not hero_collision and flag_state == "stepped" then
    return self:set_state("left")
  end
end
