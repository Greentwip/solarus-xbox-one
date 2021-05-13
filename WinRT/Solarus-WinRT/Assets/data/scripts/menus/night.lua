-- Simulates night

local night = {}

-- Prepare the surface
function night:on_started()
  self.night_layer = sol.surface.create(256, 144)
  self.night_layer:fill_color({128, 128, 255})
  self.night_layer:set_blend_mode("multiply")
end

-- Draw the surface
function night:on_draw(dst_surface)
  self.night_layer:draw(dst_surface, 0, 0)
end

return night
