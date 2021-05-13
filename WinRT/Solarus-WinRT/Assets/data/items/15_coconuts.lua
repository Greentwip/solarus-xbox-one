local item = ...

function item:on_created()
  self:set_amount_savegame_variable("num_coconuts")
end

function item:on_obtaining(variant, savegame_variable)
  -- Add to inventory
  self:add_amount(15)
  log("Number of coconuts: " .. self:get_amount())
end
