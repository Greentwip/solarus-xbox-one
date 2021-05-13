-- Manages the state of tile puzzles.

-- Usage:
--
--     local puzzle = tile_puzzle:new()
--
--     puzzle:add_tile(tile1)
--     puzzle:add_tile(tile2)
--     puzzle:add_tile(tile3)
--
--     function puzzle:on_failure()
--       -- do stuff
--     end
--

local tile_puzzle = {}

-- Tile Puzzle constructor
-- https://www.lua.org/pil/16.1.html
function tile_puzzle:new(o)
  o = o or {}
  setmetatable(o, self)
  self.__index = self
  o.tiles = o.tiles or {}
  o.frozen = o.frozen or false
  return o
end

-- Getters/setters
function tile_puzzle:add_tile(tile)
  return table.insert(self.tiles, tile)
end
function tile_puzzle:get_tiles()
  return self.tiles
end

-- State
function tile_puzzle:is_frozen()
  return self.frozen
end
function tile_puzzle:freeze()
  self.frozen = true
end
function tile_puzzle:unfreeze()
  self.frozen = false
end

-- Return the whole puzzle to its initial state
function tile_puzzle:reset()
  self:unfreeze()
  for _, tile in ipairs(self:get_tiles()) do
    tile:set_level(tile:get_property("levels") or 1)
  end
end

-- Called when the hero fails the puzzle
function tile_puzzle:on_failure()
  log("Tile puzzle: puzzle failed ;_;")
  self:freeze()
end

-- Return true if the puzzle is 100% finished, false otherwise
function tile_puzzle:is_solved()
  for _, tile in ipairs(self:get_tiles()) do
    if tile:get_level() > 0 then
      return false
    end
  end
  return true
end

-- Called when the puzzle is solved
function tile_puzzle:on_solved() end

-- Called when the hero leaves the puzzle
function tile_puzzle:on_left()
  log("Puzzle: left")
  if not self:is_solved() then
    self:reset()
  end
end

return tile_puzzle
