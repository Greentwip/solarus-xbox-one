-- Functions shared by multiple Solarus types.
-- This script does nothing on its own.
-- Other scripts should import it and use the functions.
-- ex.
--    local all = require("scripts/meta/all")
--    entity.think = all.think -- enable `entity:think()``

local all = {}

-- Puts a thought bubble over the entity's head
function all:think()
  local thought_bubble = self:create_sprite("menus/thinking", "thought_bubble")
  thought_bubble:set_ignore_suspend()
  function thought_bubble.on_animation_finished(thought_bubble)
    self:remove_sprite(thought_bubble)
  end
end

return all
