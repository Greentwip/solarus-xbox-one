-- Lua script of custom entity gear.

local entity = ...
local game = entity:get_game()
local map = entity:get_map()

-- Event called when the custom entity is initialized.
function entity:on_created()
  self:set_traversable_by(false)
  self._installed = false
  self._powered = false
  self._spin_direction = "none"
  if self:has_pedestal() then self:set_installed() end
end

-- Returns if the gear is moveable
function entity:is_movable()
  if self:get_property("movable") then
    return true
  else
    return false
  end
end

-- Event called when the hero interacts with the gear
function entity:on_interaction()
  installed_str = self:is_installed() and "installed" or "not installed"
  movable_str = self:is_movable() and "movable" or "immovable"
  powered_str = self:is_powered() and "powered" or "not powered"
  log("This gear is " .. movable_str .. ", is " .. installed_str .. " and is " .. powered_str .. ".")
end

-- Return the pedestal below. If there is no pedestal, it returns nil.
function entity:get_pedestal()
  local x, y, w, h = self:get_bounding_box()
  local n_pedestals = 0
  local pedestal = {}
  -- Filter out gear_pedestal entities
  for entity_i in map:get_entities_in_rectangle(x, y, w, h) do
    if entity_i:get_type() == "custom_entity" and entity_i:get_model() == "gear_pedestal" then
      n_pedestals = n_pedestals + 1
      pedestal = entity_i
    end
  end
  -- Handle no pedestals found
  if n_pedestals < 1 then
    return nil
  -- Handle multiple pedestals found
  else
    assert(n_pedestals == 1, "More than 1 pedestal entity overlaps with this gear.")
    return pedestal
  end
end

-- Return if the gear is powered or not
function entity:is_powered()
  return self._powered
end

-- Set the gear powered or not according to value
function entity:set_powered(value, spin_direction)
  self._powered = value
  self._spin_direction = spin_direction
  if value == true then
    assert(spin_direction == "cw" or spin_direction == "ccw", "Gear must spin in some direction")
    if spin_direction == "cw" then
      self:get_sprite():set_animation("spinning_cw")
    else
      self:get_sprite():set_animation("spinning_ccw")
    end
  else
    assert(spin_direction == "none", "Gear cannot spin when unpowered")
    self:get_sprite():set_animation("installed")
 end
end

-- Returns true if there is a pedestal below the gear
function entity:has_pedestal()
  if self:get_pedestal() then
    return true
  else
    return false
  end
end

-- If 'installed' is true or not passed, set gear's sprite and disable its pedestal. If false, set on_ground sprite
function entity:set_installed(installed)
  if installed == nil or installed == true then
    self._installed = true
    self:get_pedestal():set_enabled(false)
    self:get_sprite():set_animation("installed")
  else
    self._installed = false
    self:get_sprite():set_animation("on_ground")
  end
end

-- Returns if the animation of the gear is one of the installed ones
function entity:is_installed()
  return self._installed
end

-- Returns an iterator with the adjacent gears
function entity:get_adjacent_gears()

  -- Insert in table t the gear (if any) located di tiles right and dj tiles down from the entity (values can be negative)
  local function insert_gear_in_offset_tile(t, di, dj)
    local x, y, w, h = self:get_bounding_box()
    for entity_i in map:get_entities_in_rectangle(x+di*w, y+dj*h, w, h) do
      if entity_i:get_type() == "custom_entity" and entity_i:get_model() == "gear" then
        table.insert(t, entity_i)
      end
    end
  end

  -- Get all the gears in the 4 directions
  local adjacent_gears = {}
  insert_gear_in_offset_tile(adjacent_gears, 1, 0)
  insert_gear_in_offset_tile(adjacent_gears, 0, -1)
  insert_gear_in_offset_tile(adjacent_gears, -1, 0)
  insert_gear_in_offset_tile(adjacent_gears, 0, 1)

  return list_iter(adjacent_gears)
end
