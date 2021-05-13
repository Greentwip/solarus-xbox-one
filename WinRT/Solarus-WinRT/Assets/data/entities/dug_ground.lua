-- Lua script of custom entity dug_ground.

local entity = ...
local game = entity:get_game()
local map = entity:get_map()

-- Event called when the custom entity is initialized.
function entity:on_created()
  self:snap_to_grid()
  self:bring_to_back()
end
