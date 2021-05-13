local entity = ...
local game = entity:get_game()
local map = entity:get_map()

-- Event called when the custom entity is initialized.
function entity:on_created()
  self:set_traversable_by("hero", false)
  self:set_drawn_in_y_order()
end
