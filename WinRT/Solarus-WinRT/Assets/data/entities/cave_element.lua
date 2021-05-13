-- Lua script of custom entity non-traversable.

local entity = ...
local game = entity:get_game()
local map = entity:get_map()

-- Event called when the custom entity is initialized.
function entity:on_created()
  self:set_traversable_by("hero", false)
  if not self:get_property("outline") then self:set_property("outline", "adaptative") end 
end
