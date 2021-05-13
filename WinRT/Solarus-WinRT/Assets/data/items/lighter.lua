local item = ...

-- Event called when the game is initialized.
function item:on_started()
  self:set_savegame_variable("lighter")
end
