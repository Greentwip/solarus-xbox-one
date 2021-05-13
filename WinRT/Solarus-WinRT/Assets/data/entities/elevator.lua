-- When another entity intersects with an elevator (from any layer),
-- the elevator raises it to its layer.

local entity = ...
local game = entity:get_game()
local map = entity:get_map()

function entity:on_created()
  self:set_layer_independent_collisions(true)
  self:set_modified_ground("traversable")
  self:add_collision_test("overlapping", function(self, touching_entity)
    if touching_entity:get_type() ~= "hero" then return end
    log("Collision with elevator entity")
    local ex, ey, ez = self:get_position()
    local hx, hy, hz = touching_entity:get_position()
    if hz ~= ez then
      touching_entity:set_position(hx, hy, ez)
      log(touching_entity:get_position())
    end
  end)
end
