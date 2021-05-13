-- Custom script to extend the functionality of `block` map entites.
require("scripts/utils")

local block_meta = sol.main.get_metatable("block")

-- Get the direction the block is being moved.
-- Takes a `block` map entity and returns a direction4
local function get_block_direction(block)
  local hero = block:get_map():get_hero()
  local state = hero:get_state()
  local direction = hero:get_direction()
  if state == "pushing" then
    return direction
  elseif state == "pulling" then
    return invert_d4(direction)
  end
end

-- Constrains the movement of this block.
-- Possible values:
--    "vertical"  - only vertical movment is allowed
--    "horizontal - only horizontal movement is allowed"
--    nil         - removes any constraints
function block_meta:set_constraint(constraint)
  self.set_property("constraint", constraint)
end

-- Returns true if the block should be allowed to move in its current state.
function block_meta:move_test()
  local constraint = self:get_property("constraint")
  local direction = get_block_direction(self)
  if constraint == "vertical" and (direction == 1 or direction == 3) then
    return true
  elseif constraint == "horizontal" and (direction == 0 or direction == 2) then
    return true
  elseif constraint == nil then
    return true
  end
  return false
end

function block_meta:on_moving()
  log("block: on moving")
  if not self:move_test() then
    local hero = self:get_map():get_hero()
    local x, y, z = hero:get_position()
    log("block: move disallowed")
    self:stop_movement()
    self.hero_wall = self:get_map():create_wall({x=x, y=y, layer=z, width=16, height=16, stops_hero=true})
  else
    log("block: move allowed")
  end
end

function block_meta:on_moved()
  if self.hero_wall then
    self.hero_wall:remove()
    self.hero_wall = nil
  end
end
