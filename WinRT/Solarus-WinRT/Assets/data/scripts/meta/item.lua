require("scripts/multi_events")
local item_meta = sol.main.get_metatable("item")

-- -- When the player obtains their first item, assign it to slot 1 automatically.
-- item_meta:register_event("on_obtained", function(self, variant, savegame_variable)
--   local slot_1 = sol.main.game:get_item_assigned(1)
--   if slot_1 == nil and self:is_assignable() then
--     sol.main.game:set_item_assigned(1, self)
--   end
-- end)

-- Key item designation, used by inventory screen and npc:prompt_item()
function item_meta:is_key_item()
  return self._is_key_item or false
end
function item_meta:set_key_item(key_item)
  if key_item == nil then key_item = true  end -- empty function call
  assert(type(key_item) == "boolean")
  self._is_key_item = key_item
end
