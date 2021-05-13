-- Lua script of custom entity trash.
-- This script is executed every time a custom entity with this model is created.

-- Feel free to modify the code below.
-- You can add more events and remove the ones you don't need.

-- See the Solarus Lua API documentation for the full specification
-- of types, events and methods:
-- http://www.solarus-games.org/doc/latest
require("scripts/utils")

local entity = ...
local game = entity:get_game()
local map = entity:get_map()
local hero = game:get_hero()

-- Name of the savegame variable for this map and model
local valname = string.format("entitystate__%s__%s", path_encode(map:get_id()), entity:get_model())

-- Takes in a trash_state and converts it to a string for
-- storage into a savegame variable
local function state_tostring(state)
  local chars = {}
  for i, v in ipairs(state) do
    table.insert(chars, tostring(v))
  end
  return table.concat(chars, "")
end

-- Takes a state string and returns a table
local function state_fromstring(str)
  if str == nil then return {} end
  local state = {}
  for i=1, #str do
    local n = tonumber(str:sub(i, i))
    state[i] = n
  end
  return state
end

-- Event called when the custom entity is initialized.
function entity:on_created()
  self:set_drawn_in_y_order()
  self:set_traversable_by("hero", false)

  -- Initialize some variables in the map
  if map._trash_count == nil then map._trash_count = 1 end
  if map._trash_state == nil then
    map._trash_state = state_fromstring(game:get_value(valname))
  end

  -- Store original position
  local pos = {}
  pos.x, pos.y, pos.z = self:get_position()
  self._original_position = pos

  -- Add an ID to this entity by the order it was created
  self._id = map._trash_count
  map._trash_count = map._trash_count + 1 -- increment counter

  -- Initialize the trash state
  if map._trash_state[self._id] == nil then
    map._trash_state[self._id] = 1
  end

  -- Remove this if it was already vacuumed
  if map._trash_state[self._id] == 0 then
    self:remove()
  end
end

-- Like remove(), but not called when the map ends
function entity:destroy()
  self:on_destroyed()
  self:remove()
end

-- Update the trash state table and save
function entity:on_destroyed()
  map._trash_state[self._id] = 0
  local state_string = state_tostring(map._trash_state)
  log("Trash state: " .. state_string)
  game:set_value(valname, state_string) -- Save the trash state
  map:on_trash_removed(self) -- notifies the map of this change (see trash_map.lua)
end

-- Causes the trash to shiver - used when being vacuumed
function entity:shiver()
  local m = sol.movement.create("pixel")
  m:set_loop(true)
  m:set_ignore_obstacles(true)
  m:set_trajectory({
    {2, 0},
    {-2, 0}
  })
  m:set_delay(100)
  m:start(self)
end

-- Called when the power of the vacuum changes
function entity:on_vacuum_changed(power)
  if power == 2 then
    self:shiver() -- Start shiver animation

  elseif power == 3 then
    -- Move the entity towards the hero
    local m = sol.movement.create("target")
    m:set_ignore_obstacles(true)
    m:set_target(hero)
    m:set_speed(200)
    m:start(self, function()
      self:destroy() -- destroy the entity once it reaches the hero
    end)

  elseif power == 0 then
    -- Release entity
    local pos = self._original_position
    self:stop_movement()
    self:set_position(pos.x, pos.y, pos.z) -- counteract shiver
  end
end
