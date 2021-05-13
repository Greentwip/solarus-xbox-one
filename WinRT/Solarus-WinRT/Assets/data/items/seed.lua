local item = ...

-- Event called when the game is initialized.
function item:on_started()
  self:set_savegame_variable("seed")
  self:set_key_item(true)
end
