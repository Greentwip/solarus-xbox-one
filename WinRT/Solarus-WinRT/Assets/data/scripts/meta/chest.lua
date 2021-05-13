-- Custom script to extend the functionality of the chest

local chest_meta = sol.main.get_metatable("chest")

-- It decides if a bubble is displayed over the hero when facing
function chest_meta:should_show_interaction_bubble()
  local game = self:get_game()  
  local hero = game:get_hero()
  local dialog_enabled = game:is_dialog_enabled()
  local hero_free = game:get_hero():get_state() == "free"
  local hero_correct_direction = hero:get_sprite():get_direction() == 1

  return not self:is_open() and hero_correct_direction and not dialog_enabled and hero_free
end
