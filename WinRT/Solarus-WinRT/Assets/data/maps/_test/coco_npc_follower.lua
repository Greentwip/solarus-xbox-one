-- Lua script of map _test/coco_npc_follower.

local map = ...
local game = map:get_game()

-- Event called at initialization time, as soon as this map is loaded.
function map:on_started()
  local hero = game:get_hero()
  hero:create_follower("animals/beaver")
end

-- Event called after the opening transition effect of the map,
-- that is, when the player takes control of the hero.
function map:on_opening_transition_finished()

end
