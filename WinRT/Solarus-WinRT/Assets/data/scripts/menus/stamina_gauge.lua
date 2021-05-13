-- Displays a stamina gauge

local stamina_gauge = {}

-- Prepare the surfaces
function stamina_gauge:on_started()
  self.border = sol.surface.create(12, 5)
  self.border:fill_color({0, 0, 0})
  self.empty_rec = sol.surface.create(10, 3)
  self.empty_rec:fill_color({255, 144, 0})
  self.full_rec = sol.surface.create(10, 3)
  self.full_rec:fill_color({112, 224, 0})
end

-- Display the stamina gauge on top of the hero
function stamina_gauge:on_draw(dst_surface)
  local game = self._game
  if not game:is_command_pressed("item_2") then return end
  local hero_x, hero_y = game:get_hero():get_screen_position()

  self.empty_rec:draw(self.border, 1, 1)
  self.full_rec:draw_region(0, 0, math.ceil(game:get_magic() / game:get_max_magic() * 10), 3, self.border, 1, 1)
  self.border:draw(dst_surface, hero_x-6, hero_y-19)

end

-- Set up the stamina gauge on any game that starts.
local game_meta = sol.main.get_metatable("game")

game_meta:register_event("on_started", function(game)
  stamina_gauge._game = game
  sol.menu.start(game, stamina_gauge) -- show the stamina gauge
end)

return true
