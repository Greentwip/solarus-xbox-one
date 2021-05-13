local item = ...
local game = item:get_game()

-- Mapping between variant and faction
-- The index is the variant
local factions = {"usa", "evolv", "transcend", "none"}


-- Event called when the game is initialized.
function item:on_created()
  self:set_savegame_variable("id_card")
  self:set_key_item(true)
end

-- Returns one of: "usa", "evolv", "transcend", "none"
function item:get_faction()
  return factions[self:get_variant()]
end

-- Takes a faction name as a string
function item:set_faction(faction)
  for i, v in ipairs(factions) do
    if v == faction then
      return self:set_variant(i)
    end
  end
  assert(false, 'Faction must be one of: "usa", "evolv", "transcend", "none"')
end

-- Get and set EVOLV level
function item:get_level()
  local is_evolv = factions[self:get_variant()] == "evolv"
  if is_evolv then
    return game:get_value("evolv_level")
  end
  return false
end
function item:set_level(level)
  assert(type(level) == "number", "Level must be a number.")
  local is_evolv = factions[self:get_variant()] == "evolv"
  if is_evolv then
    return game:set_value("evolv_level", level)
  end
  assert(is_evolv, "Can't set level. Only EVOLV has levels.")
  return false
end

function item:on_variant_changed(variant)
  -- Set level for EVOLV
  if factions[variant] == "evolv" then
    self:set_level(1)
  end
end
