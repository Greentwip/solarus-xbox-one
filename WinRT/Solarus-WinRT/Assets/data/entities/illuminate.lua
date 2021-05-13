-- Lua script of custom entity illuminate.
-- This script is executed every time a custom entity with this model is created.

local entity = ...
local game = entity:get_game()
local map = entity:get_map()

-- Event called when the custom entity is initialized.
function entity:on_created()
end

-- Return the entity's position relative to the screen.
function entity:get_screen_position()
  local camera = self:get_map():get_camera()
  local entity_x, entity_y = self:get_position()
  local camera_x, camera_y = camera:get_position()
  return entity_x-camera_x, entity_y-camera_y
end
