-- This is the secret map the hero enters during the title screen.
-- Basically a hack. Don't delete this file please.

local map = ...
local game = map:get_game()

function map:on_started()
  game:get_hero():freeze()
end
