-- Lua script of custom entity torch.

local entity = ...
local game = entity:get_game()
local map = entity:get_map()

-- Event called when the custom entity is initialized.
function entity:on_created()
  self:set_traversable_by(false)
  self:set_state(self:get_property("state"))

  -- Let sprites be animated even on suspend
  local sprite = self:get_sprite()
  if sprite then sprite:set_ignore_suspend() end
end

-- Light the torch
function entity:on_interaction()
  log("Interacting with torch.")
  if self:get_state() == "unlit" then
    if game:get_item("lighter"):get_variant() == 0 then
      game:start_dialog("_torch")
    else
      self:set_state("lit")
    end
  end
end

-- Get torch state
function entity:get_state()
  if self.is_lit then
    return "lit"
  else
    return "unlit"
  end
end

-- Set torch state
function entity:set_state(state)
  if state == "lit" then
    self.is_lit = true
    self:get_sprite():set_animation("lit")
  else
    self.is_lit = false
    self:get_sprite():set_animation("unlit")
  end
  self:update_light_radius_in_region()
end

function entity:update_light_radius_in_region()
  -- Determine number of lit torches in the region
  local n_lit_torches = 0
  if self.is_lit then n_lit_torches = 1 end
  for entity_i in map:get_entities_in_region(self) do -- loop ALL OTHER entities
    if entity_i:get_type() == "custom_entity" and entity_i:get_model() == "torch" and entity_i.is_lit then
      n_lit_torches = n_lit_torches + 1
    end
  end
  -- Set size of light radius according to number of lit torches in the region
  local size = "32"
  if n_lit_torches == 0 then
    size = nil
  elseif n_lit_torches == 1 then
    size = "32"
  elseif n_lit_torches == 2 then
    size = "64"
  else
    size = "128"
  end
  -- Update light radius of this torch
  if self.is_lit then self.light_radius = size end
  -- Update light radius of the rest of the torches
  for entity_i in map:get_entities_in_region(self) do -- loop ALL OTHER entities
    if entity_i:get_type() == "custom_entity" and entity_i:get_model() == "torch" then
      if entity_i.is_lit then entity_i.light_radius = size end
    end
  end
end

function entity:get_spotlight_size()
  return self.light_radius
end

function entity:should_show_interaction_bubble()
  local game = self:get_game()
  local hero = game:get_hero()
  local dialog_enabled = game:is_dialog_enabled()
  local hero_free = game:get_hero():get_state() == "free"

  return self:get_state() == "unlit" and not dialog_enabled and hero_free
end
