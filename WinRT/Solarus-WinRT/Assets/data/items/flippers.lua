local item = ...

function item:on_created()
  self:set_savegame_variable("flippers")
end

function item:on_variant_changed(variant)
  -- set the built-in ability
  self:get_game():set_ability("swim", variant)
end