-- When the hero reaches the edge of the map, this entity
-- warns them they cannot trek into the deep ocean.

local entity = ...
local game = entity:get_game()
local map = entity:get_map()
local hero = map:get_hero()


-- Hero is rotated to direction4 and pushed forward 8px
function push_hero(direction4)
  hero:freeze()
  local sprite = hero:get_sprite()
  sprite:set_animation("swimming_stopped")
  hero:set_direction(direction4)
  local x, y, z = hero:get_position()
  if     direction4 == 0 then x = x + 4
  elseif direction4 == 1 then y = y - 4
  elseif direction4 == 2 then x = x - 4
  elseif direction4 == 3 then y = y + 4 end
  return hero:set_position(x, y, z)
end

-- Direction4 the hero should be pushed
function entity:get_d4()
  local x, y, z = self:get_position()
  local width, height = self:get_size()
  local map_width, map_height = map:get_size()
  local ox, oy = self:get_origin()
  if     y == map_height + oy then return 1
  elseif y == -1*height  + oy then return 3
  elseif x == 0 - width  + ox then return 0
  elseif x == map_width  + ox then return 2 end
  return nil
end

-- Triggers when the hero touches the entity (any adjacent pixely)
entity:add_collision_test("touching", function(self, touching_entity)
  if touching_entity == hero then
    local d4 = self:get_d4()
    push_hero(d4)
    game:start_dialog("game.water_toofar", function()
      hero:unfreeze()
    end)
  end
end)
