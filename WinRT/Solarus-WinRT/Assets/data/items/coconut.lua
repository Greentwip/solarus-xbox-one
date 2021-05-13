local item = ...

function item:on_created()
  self:set_can_disappear(true)
  self:set_brandish_when_picked(false)
  self:set_amount_savegame_variable("num_coconuts")
  self:set_shadow("small")
end

function item:on_obtaining(variant, savegame_variable)
  local game = self:get_game()
  local hero = game:get_hero()
  local map = hero:get_map()

  -- Show a dialog if this is your first coconut.
  if self:get_amount() == 0 and hero:get_state() ~= "treasure" then
    hero:brandish("coconut")
  else
    -- Throw anything that hero may be carrying
    hero:throw()
    -- Show above hero's head
    local x, y, z = hero:get_position()
    local item_entity = map:create_custom_entity({
      sprite = "entities/items",
      direction = 1,
      x=0, y=0, layer=0, width=16, height=16
    })
    -- Create sprite
    local item_sprite = item_entity:get_sprite()
    item_sprite:set_animation("coconut")
    local ox, oy = item_sprite:get_origin()
    item_entity:set_position(x, y-28+oy, z+1)
    -- Animate
    sol.timer.start(item_entity, 10, function()
      local x, y, z = hero:get_position()
      log("position changed x="..x.." y="..y)
      item_entity:set_position(x, y-28+oy, z+1)
      return true
    end)
    -- Remove sprite
    sol.timer.start(self, 300, function()
      item_entity:remove()
    end)
  end

  -- Add to inventory
  self:add_amount(1)
  log("Number of coconuts: " .. self:get_amount())
  -- Add stamina
  game:add_magic(5)
  log("Stamina level: " .. game:get_magic() .. "/" .. game:get_max_magic())
end
