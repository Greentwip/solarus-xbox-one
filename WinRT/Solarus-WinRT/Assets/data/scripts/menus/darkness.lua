-- Simulates a dark cave
-- DESCRIPTION:
--
--   When called, everything becomes black except some white outlines and the areas close to lit torches.
--   Outlines are drawn for those entities which sprite has a "darkness/*" version available.
--   It can be avoided to draw the outline by setting the user-defined property "outline" equal to "no".
--   It is also possible to increase/decrease the opacity of the outline according to the position of the hero
--   simulating visual adaptation. To use that feature use the user-defined property "outline" equal to "adaptative".
--
-- USAGE:
--   local darkness = require("scripts/menus/darkness")
--   [SET OPTIONAL PARAMETERS]
--   sol.menu.start(self, darkness)
--
-- OPTIONAL PARAMETERS (Only apply to entities with a darkness sprite and user-defined property "outline" equal to "adaptative"):
--
--   darkness.adaptation_delay           - Delay for increasing and decreasing opacity
--   darkness.adaptation_memory          - Set if opacity can be decreased
--   darkness.adaptation_mode            - "radius": Opacity depends on hero distance to the entity.
--                                         "facing": Opacity depends whether the hero is facing the entity
--   darkness.adaptation_radius          - Vision radius of the hero. Only applies in "radius" mode
require("scripts/multi_events")

local darkness = {}

  -- Prepare the surfaces
function darkness:on_started()
  local map = sol.main.game:get_map()
  local hero = map:get_hero()

  -- Create layers
  self.black_layer = sol.surface.create(map:get_size())
  self.outline_layer = sol.surface.create(map:get_size())

  -- Create spotlights of fixed sizes
  self.spotlight = {}
  self.spotlight_black = {}
  local spotlight_sizes = {"32", "64", "128"}
  for k, size in ipairs(spotlight_sizes) do
    self.spotlight[size] = sol.sprite.create("menus/spotlight")
    self.spotlight_black[size] = sol.sprite.create("menus/spotlight_black")
    self.spotlight[size]:set_animation(size)
    self.spotlight_black[size]:set_animation(size)
  end

  -- White pixels become transparent
  self.black_layer:set_blend_mode("multiply")

  -- Black pixels become transparent
  self.outline_layer:set_blend_mode("add")

  -- Set default of optional parameters
  if not self.adaptation_delay then self.adaptation_delay = 30 end
  if not self.adaptation_memory then self.adaptation_memory = false end
  if not self.adaptation_mode then self.adaptation_mode = "radius" end
  if not self.adaptation_radius then self.adaptation_radius = 30 end
  self.entities = {}

  -- Update opacity of darkness sprites
  sol.timer.start(self, self.adaptation_delay, function()
    for _, entity in ipairs(self.entities) do
      if entity.darkness_sprite and entity:get_property("outline") == "adaptative" then
        if self.adaptation_mode == "radius" then self:update_opacity_radius_mode(entity) end
        if self.adaptation_mode == "facing" then self:update_opacity_facing_mode(entity) end
      end
    end
    return true
  end)
end

function darkness:on_finished()
  -- Restore optional variables to default values
  self.adaptation_delay = nil
  self.adaptation_memory = nil
  self.adaptation_mode = nil
  self.adaptation_radius = nil

  -- Remove darkness information from entities
  local map = sol.main.game:get_map()
  for entity in map:get_entities() do
    entity.darkness_sprite_checked = nil
    entity.darkness_sprite = nil
  end
end

-- Make everything dark except sprites under darkness/
function darkness:on_draw(dst_surface)
  local map = sol.main.game:get_map()
  local camera = map:get_camera()
  local camera_x, camera_y = camera:get_position()

  self.outline_layer:clear()
  self.black_layer:fill_color({0, 0, 0})

  self:process_entities()
  self.black_layer:draw(dst_surface, 0-camera_x, 0-camera_y)
  self.outline_layer:draw(dst_surface, 0-camera_x, 0-camera_y)
end


-- Performs the looping over all entities in the map.
function darkness:process_entities()
  local map = sol.main.game:get_map()
  local hero = map:get_hero()
  local camera = map:get_camera()

  -- Entities that overlap with the camera
  self.entities = build_array(map:get_entities_in_rectangle(camera:get_bounding_box()))

  -- Draw white outlines for sprites
  for _, entity in ipairs(self.entities) do
    if entity:get_sprite() then self:draw_outline(entity) end
  end

  -- Draw spotlights
  for _, entity in ipairs(self.entities) do
    self:draw_spotlight(entity)
  end
end


-- Logic which looks for the darkness sprite
function darkness:draw_outline(entity)
  local pos_x, pos_y = entity:get_position()
  local entity_sprite = entity:get_sprite()

  -- Create darkness sprite if there is an equivalent sprite in darkness/
  if not entity.darkness_sprite_checked then
    local sprite_id = "darkness/" .. entity:get_sprite():get_animation_set()
    if sol.file.exists("sprites/"..sprite_id..".dat") and entity:get_property("outline") ~= "no" then
      entity.darkness_sprite = sol.sprite.create("darkness/" .. entity:get_sprite():get_animation_set())
      if entity:get_property("outline") == "adaptative" then entity.darkness_sprite:set_opacity(0) end
    end
    entity.darkness_sprite_checked = true
  end

  -- Make outlined sprite mirror the real one
  if entity.darkness_sprite then
    entity.darkness_sprite:set_animation(entity_sprite:get_animation())
    entity.darkness_sprite:set_direction(entity_sprite:get_direction())
    entity.darkness_sprite:set_frame(entity_sprite:get_frame())
    entity.darkness_sprite:draw(self.outline_layer, pos_x, pos_y)
  end
end


-- Draw spotlights
function darkness:draw_spotlight(entity)
  local pos_x, pos_y = entity:get_position()

  if entity.get_spotlight_size then
    local spotlight_size = entity:get_spotlight_size()
    if spotlight_size then
      self.spotlight[spotlight_size]:draw(self.black_layer, pos_x, pos_y)
      self.spotlight_black[spotlight_size]:draw(self.outline_layer, pos_x, pos_y)
    end
  end
end

-- Determine if an entity is enough close to hero
function darkness:is_hero_close_to_entity(entity)
  local hero = sol.main.game:get_hero()
  local hero_x, hero_y = hero:get_position()
  local entity_x, entity_y = entity:get_position()

  return math.abs(entity_x-hero_x)^2 + math.abs(entity_y-hero_y)^2 < self.adaptation_radius^2
end

-- Set the opacity of the darkness sprite of an entity by proximity of the hero
function darkness:update_opacity_radius_mode(entity)
  local current_opacity = entity.darkness_sprite:get_opacity()
  local new_opacity = current_opacity
  if self:is_hero_close_to_entity(entity) then
    new_opacity = math.min(current_opacity+1, 255)
  else
    if not self.adaptation_memory then new_opacity = math.max(current_opacity-1, 0) end
  end
  entity.darkness_sprite:set_opacity(new_opacity)
end

-- Set the opacity of the darkness sprite of an entity depending whether the hero faces the entity
function darkness:update_opacity_facing_mode(entity)
  local hero = sol.main.game:get_hero()
  local current_opacity = entity.darkness_sprite:get_opacity()
  local new_opacity = current_opacity
  if entity == hero:get_facing_entity() then
    new_opacity = math.min(current_opacity+1, 255)
  else
    if not self.adaptation_memory then new_opacity = math.max(current_opacity-1, 0) end
  end
  entity.darkness_sprite:set_opacity(new_opacity)
end

return darkness
