local map = ...
local game = map:get_game()

-- Event called at initialization time, as soon as this map is loaded.
function map:on_started()
  local witch = map:get_entity("witch")
  function witch:on_interaction()
    hero:start_treasure("cultured_meat")
  end
end
