-- Lua script of custom entity mask.

local entity = ...
local game = entity:get_game()
local map = entity:get_map()

-- Event called when the custom entity is initialized.
function entity:on_created()
  self:set_traversable_by(false)
end

-- Interaction does mask disappear and then the hero wear it
function entity:on_interaction()
  local hero = game:get_hero()
  local x, y, layer = self:get_position()
  if hero:get_mask() then
    local mask_name = hero:get_mask()
    map:create_custom_entity({layer=layer, x=x, y=y, width=16, height=16, direction=3, model="mask", sprite="entities/masks/" .. mask_name, properties={{key="mask", value=mask_name}}})
  end
  self:remove()
  hero:set_mask(self:get_property("mask"))
end
