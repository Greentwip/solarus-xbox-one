local entity = ...
local game = entity:get_game()
local map = entity:get_map()
local hero = map:get_hero()

local collision_mode = "center"

-- Event called when the custom entity is initialized.
function entity:on_created()
  -- HACK: https://gitlab.com/solarus-games/solarus/issues/1339
  self:set_size(14, 14)
  self:set_origin(7, 12)
  self:set_level(self:get_property("levels") or 1)
  map.tile_puzzles = map.tile_puzzles or {}
  local puzzle_id = self:get_property("puzzle_id") or "map"
  local puzzle = map:get_puzzle(puzzle_id)
  puzzle:add_tile(self)
end

-- Get the Tile Puzzle associated with this tile
function entity:get_puzzle()
  return map.tile_puzzles[self:get_property("puzzle_id") or "map"]
end

-- Runs on each call of the game loop
function entity:on_update()
  if hero:overlaps(self, collision_mode) then
    if not self._stepped then
      self:on_stepped()
      self._stepped = true
    end
  else
    if self._stepped then
      self:on_left()
      self._stepped = false
    end
  end
end

-- Get and set the level
function entity:get_level()
  return self._level
end
function entity:set_level(level)
  self._level = level
  self:get_sprite():set_direction(level)
  log("Maze tile: level set to ", level)
end

-- Called when the hero steps on
function entity:on_stepped()
  log("Maze tile: stepped on")
  local puzzle = self:get_puzzle()
  if puzzle:is_frozen() then return end
  local level = self:get_level()
  if level > 0 then
    self:set_level(level - 1)
    self:get_sprite():set_animation("stepped_on")
  else
    if not puzzle:is_solved() then
      puzzle:on_failure()
      return
    end
  end
  if puzzle:is_solved() then
    puzzle:on_solved()
  end
end

-- Called when the hero steps off
function entity:on_left()
  log("Maze tile: left")
  self:get_sprite():set_animation("normal")
  -- Reset the puzzle when left
  local x, y, z = hero:get_position()
  local ox, oy = hero:get_origin()
  for entity in map:get_entities_in_rectangle(x-ox-16, y-oy-16, 48, 48) do
    if entity.get_model and entity:get_model() == "maze_tile" and hero:overlaps(entity, collision_mode) then
      return
    end
  end
  self:get_puzzle():on_left()
end
