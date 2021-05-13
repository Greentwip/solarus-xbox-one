-- Lua script of custom entity gear_furnace.
require("scripts/utils")

local entity = ...
local game = entity:get_game()
local map = entity:get_map()

-- Event called when the custom entity is initialized.
function entity:on_created()
  self:set_traversable_by("hero", false)
  self._powered = false
  self._spin_direction = "none"
end

function entity:is_powered()
  -- TODO: Handle powering the furnace with mirrors.
  return true
end

-- Power the adjacent gears if value is nil or true. Stop the adjacent gears if value is false
function entity:set_powered(value) 
  -- Accept no argument as true
  if value == nil then value = true end

  -- It will contain as keys the gears that are installed and have already been checked (also the furnace, but it does not matter)
  local checked = {}

  -- It returns the opposite spin. Cases: "cw" -> "ccw"; "ccw" -> "cw"; "none" -> "none"
  local function opposite_spin(spin_direction)
    if spin_direction == "cw" then
      return "ccw"
    elseif spin_direction == "ccw" then
      return "cw"
    else
      return "none"
    end
  end

  -- Call gear:set_powered(value) for every adjacent gear that is installed and has not been checked
  local function update_adjacent_gears(entity)
    if not checked[entity] then
      checked[entity] = true
      for gear_i in entity:get_adjacent_gears() do
        if gear_i:is_installed() then
          gear_i:set_powered(entity._powered, opposite_spin(entity._spin_direction))
          update_adjacent_gears(gear_i)
        end
      end
    end
  end
  self._powered = value
  if value == true or value == nil then
    -- Furnace spin always clockwise if powered
    self._spin_direction = "cw"
  else
    self._spin_direction = "none"
  end
  update_adjacent_gears(self)
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
