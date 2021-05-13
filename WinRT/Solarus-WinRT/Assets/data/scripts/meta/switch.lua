-- Override default switch behavior

local switch_meta = sol.main.get_metatable("switch")

function switch_meta:on_created()
  -- Make the hitbox a better size for Rachel
  self:set_size(16, 22)
  self:set_origin(0, 6)
end
