require("scripts/utils")
local tile_puzzle = require("scripts/tile_puzzle")
local darkness = require("scripts/menus/darkness")
local night = require("scripts/menus/night")
local map_meta = sol.main.get_metatable("map")

local DIGGABLE_TILES = { --only tiles with this pattern id are diggable, non-diggable tile on top blocks digging (except if it is on the IGNORED_TILES)
	['grass.soil'] = true,
  ['sand.soil'] = true,
  ['sand.shadow'] = true,
  ['62'] = true,  ['63'] = true,
  ['64'] = true,  ['65'] = true,
  ['67'] = true,  ['69'] = true,
  ['70'] = true,  ['71'] = true,
  ['73'] = true,  ['74'] = true,
  ['75'] = true,  ['363'] = true,
  ['68'] = true,  ['72'] = true,
  ['76'] = true,  ['103'] = true,
  ['104'] = true,
  ['grass.weed'] = true,
  ['grass.weed_big'] = true,
  ['grass.flower'] = true,
  ['grass.flower_double'] = true,
  ['130'] = true,  ['131'] = true,
  ['521'] = true,  ['522'] = true,
  ['523'] = true,
}

local IGNORED_TILES = { --if this tile is on top of a diggable tile then it does not prevent digging
	--['some_pattern_id'] = true, --example
}

local TILE_SIZE = 16 --number of pixels per tile

-- Return a list of puzzles on the map
function map_meta:get_puzzles()
  return self.tile_puzzles -- set by: entities/maze_tile.lua
end

-- Get a puzzle if it exists, or create one with the given name if not
function map_meta:get_puzzle(name)
  self.tile_puzzles[name] = self.tile_puzzles[name] or tile_puzzle:new()
  return self.tile_puzzles[name]
end

-- Destroy all puzzles associated with this map
function map_meta:clear_puzzles()
  self.tile_puzzles = {}
  log("Puzzles destroyed from map.")
end

-- Destroy puzzles by default when map is left
function map_meta:on_finished()
  self:clear_puzzles()
end

-- returns true if the map currently has trash entities on it
function map_meta:has_trash()
  -- Name of the savegame variable for this map and model
  local valname = string.format("entitystate__%s__%s", path_encode(self:get_id()), "trash")
  local trash_state_str = self:get_game():get_value(valname)

  for i = 1, #trash_state_str do
    local c = trash_state_str:sub(i, i)
    if c == "1" then
      return true -- 1 represents uncleaned trash. a single 1 means we have trash.
    end
  end
  return false
end

-- Called whenever a trash entity (from this map) is destroyed
function map_meta:on_trash_removed(trash_entity)
  if self:has_trash() == false then
    -- Trash is cleaned, roll the credits
    -- TODO: Do something.
  end
end

-- Create darkness around the hero. Variables are optional and are described in darkness.lua
function map_meta:start_darkness(adaptation_delay, adaptation_memory, adaptation_mode, adaptation_radius)
  if not sol.menu.is_started(darkness) then
    darkness.adaptation_delay = adaptation_delay
    darkness.adaptation_memory = adaptation_memory
    darkness.adaptation_mode = adaptation_mode
    darkness.adaptation_radius = adaptation_radius
    sol.menu.start(self, darkness)
    sol.menu.bring_to_back(darkness)
  end
end

-- Remove darkness around the hero
function map_meta:stop_darkness()
  if sol.menu.is_started(darkness) then
    sol.menu.stop(darkness)
  end
end

-- Starts night
function map_meta:start_night()
  if not sol.menu.is_started(night) then
    sol.menu.start(self, night)
    sol.menu.bring_to_back(night)
  end
end

-- Stops night
function map_meta:stop_night()
  if sol.menu.is_started(night) then
    sol.menu.stop(night)
  end
end

-- Returns a list iterator of custom entities of the given model
function map_meta:get_entities_by_model(model)
  assert(type(model) == "string", "Model must be a string, not a "..type(model))
  assert(sol.main.resource_exists("entity", model), "Invalid entity type: "..model)

  local entities = {}
  for entity in self:get_entities_by_type("custom_entity") do
    if entity:get_model() == model then
      table.insert(entities, entity)
    end
  end

  return list_iter(entities)
end

-- Return a list iterator of torches in the same region than the given entity
function map_meta:get_torches_in_region(entity)
  local torches = {}
  if entity:get_type() == "custom_entity" and entity:get_model() == "torch" then table.insert(torches, entity) end
  for entity_i in self:get_entities_in_region(entity) do -- loop ALL OTHER entities
    if entity_i:get_type() == "custom_entity" and entity_i:get_model() == "torch" then
      table.insert(torches, entity_i)
    end
  end
  return list_iter(torches)
end

--load map .dat file to find positions of all diggable tiles
function map_meta:load_diggable_tiles()
  self.tile_map = {}
	map_id = self:get_id()

	local env = {}
	local map_width, map_height

	--properties stores the size and coordinates for the map and the tileset used
	function env.properties(properties)
		local width = tonumber(properties.width)
		assert(width, "property width must be a number")
		local height = tonumber(properties.height)
		assert(height, "property height must be a number")

		map_width = width
		map_height = height
	end

	--each tile defines a size, coordinates and layer as well as the tile id to use
	function env.tile(properties)
		local pattern = properties.pattern --pattern is the tile id
		assert(pattern, "tile without pattern")

		local layer = properties.layer
		assert(layer, "tile without layer")
		layer = tonumber(layer)
		assert(layer, "tile layer must be a number")

		local x = tonumber(properties.x)
		assert(x, "tile x must be a number")
		local y = tonumber(properties.y)
		assert(y, "tile y must be a number")

		local width = tonumber(properties.width)
		assert(width, "tile width must be a number")
		local height = tonumber(properties.height)
		assert(height, "tile height must be a number")

		if not IGNORED_TILES[pattern] then
			local min_column = math.floor(x/TILE_SIZE) + 1
			local max_column = math.floor((x + width - 1)/TILE_SIZE) + 1

			local min_row = math.floor(y/TILE_SIZE) + 1
			local max_row = math.floor((y + height - 1)/TILE_SIZE) + 1

			local is_dig = not not DIGGABLE_TILES[pattern]
			for row = min_row, max_row do
				for column = min_column, max_column do
					if not self.tile_map[layer] then self.tile_map[layer] = {} end
					if not self.tile_map[layer][column] then self.tile_map[layer][column] = {} end

					self.tile_map[layer][column][row] = is_dig
				end
			end
		end
	end

	setmetatable(env, {__index = function() return function() end end})

	local chunk, err = sol.main.load_file("maps/"..map_id..".dat")
	setfenv(chunk, env)
	chunk()
end

--usage: map:is_diggable(hero:get_position())
function map_meta:is_diggable(x, y, layer)
	x = tonumber(x)
	assert(x, "Bad argument #1 to 'map:is_diggable' (number expected)")
	y = tonumber(y)
	assert(y, "Bad argument #2 to 'map:is_diggable' (number expected)")
	layer = tonumber(layer)
	assert(layer, "Bad argument #3 to 'map:is_diggable' (number expected)")

	local column = math.floor(x/TILE_SIZE) + 1
	local row = math.floor(y/TILE_SIZE) + 1

  local diggable = self.tile_map[layer] and
                   self.tile_map[layer][column] and
                   self.tile_map[layer][column][row]

	return diggable
end
