-- Lua script of custom entity centerpiece.

local entity = ...
local game = entity:get_game()
local map = entity:get_map()

-- What to do on interaction with centerpiece
function entity:on_interaction()
  local n_torches = 0
  local n_lit_torches = 0
  for torch in map:get_torches_in_region(self) do
    n_torches = n_torches + 1
    if torch:get_state() == "lit" then n_lit_torches = n_lit_torches + 1 end
  end
  if n_torches == n_lit_torches then
    game:start_dialog("catacombs.rachel.centerpiece")
  else
    game:start_dialog("catacombs.rachel.centerpiece_darkness")
  end
end