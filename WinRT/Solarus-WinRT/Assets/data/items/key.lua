local item = ...

function item:on_created()
  self:set_brandish_when_picked(false)
  self:set_amount_savegame_variable("num_keys")
end

function item:on_obtaining(variant, savegame_variable)
  -- Add to inventory
  self:add_amount(1)
  log("Number of keys: " .. self:get_amount())
end
