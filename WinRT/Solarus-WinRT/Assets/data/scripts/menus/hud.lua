-- Displays the HUD

local hud = {}

function hud:on_started()
  -- Load resources
  self.items_sprite = sol.sprite.create("entities/items")
  self.item_box     = sol.surface.create(20, 20)
  self.item_frame   = sol.sprite.create("hud/hud")

  assert(self._game, "HUD is trying to render but isn't bound to any game.")
end

-- Display the item icon in the corner of the screen
function hud:on_draw(dst_surface)
  local game = self._game
  self.item_box:clear()

  -- Draw the BG
  self.item_frame:draw(self.item_box)

  -- Draw the item icon
  local item = game:get_item_assigned(1)
  if item then
    self.items_sprite:set_animation(item:get_name())
    self.items_sprite:set_direction(item:get_variant() - 1)
    self.items_sprite:draw(self.item_box, 10, 6)
  end

  -- Paint onto screen
  self.item_box:draw(dst_surface, 4, 4)
end


-- Set up the HUD on any game that starts.
local game_meta = sol.main.get_metatable("game")

game_meta:register_event("on_started", function(game)
  hud._game = game
  sol.menu.start(game, hud) -- show the HUD
end)


return true
