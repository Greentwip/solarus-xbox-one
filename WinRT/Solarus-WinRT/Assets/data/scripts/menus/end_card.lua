-- Displays a THE END title card at the end of the game

local end_card = {}

-- Called when the menu is run
function end_card:on_started()
  self.art_gfx = sol.surface.create("menus/end.png")
  self.art_gfx:fade_in(100, function()
    sol.main.game:start_confetti()
  end)
end

-- Called every frame
function end_card:on_draw(dst_surface)
  dst_surface:fill_color({0, 0, 0})
  self.art_gfx:draw(dst_surface)
end

return end_card
