local item = ...

-- Event called when the game is initialized.
function item:on_created()
  self:set_savegame_variable("whiskey")
  self:set_key_item(true)
end

