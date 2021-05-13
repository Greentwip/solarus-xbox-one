-- Menu that appears when the game is saved

local save_feedback = {}

-- Called when the menu is started
function save_feedback:on_started()
  self.feedback_bg = sol.surface.create(80, 16)  
  self.feedback_bg:fill_color{0, 0, 0}
  self.feedback_text = sol.text_surface.create({text_key="menus.save_feedback", font="Comicoro", font_size=16})
end

-- Called each frame
function save_feedback:on_draw(dst_surface)
  self.feedback_text:draw(self.feedback_bg, 7, 8)
  self.feedback_bg:draw(dst_surface, 0, 144)
end

return save_feedback
