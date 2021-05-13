local all = require("scripts/meta/all")
local picker = require("scripts/menus/picker")
local npc_meta = sol.main.get_metatable("npc")

function npc_meta:on_created()
  local game = self:get_game()
  local name = self:get_name()
  local cleaned = false

  if name then
    cleaned = game:get_value(name.."__cleaned")
  end

  if cleaned then
    self:get_sprite():set_animation("normal")
  end
end

-- Start a picker menu for the NPC
-- https://gitlab.com/voadi/voadi/wikis/docs/lua-api#npcprompt_itemcallback
function npc_meta:prompt_item(callback, filter)
  if not filter then -- default filter shows only key items
    filter = function(item) return item:is_key_item() end
  end
  picker._npc = self
  picker._filter = filter
  sol.menu.start(self:get_map(), picker)
  function picker:on_finished()
    callback(self:get_selection())
    picker._npc = nil
    picker._filter = nil
    self.on_finished = nil -- destroy this function between calls
  end
end

-- Enable thought bubble
npc_meta.think = all.think

-- Let NPC sprites be animated even on suspend
function npc_meta:on_suspended()
  local sprite = self:get_sprite()
  if sprite then sprite:set_ignore_suspend() end
end

-- Like `game:start_dialog()` except it uses a talking animation if that exists
function npc_meta:start_dialog(dialog_id, callback)
  local sprite = self:get_sprite()
  sprite:set_ignore_suspend()
  if sprite:has_animation("talking") then
    sprite:set_animation("talking")
  end
  local new_callback = function() sprite:set_animation("stopped") end
  if callback then
    function new_callback(...)
      sprite:set_animation("stopped")
      callback(...)
    end
  end
  self:get_game():start_dialog(dialog_id, nil, new_callback)
end

-- Set default on_vacuum_changed event for NPCs.
-- Namely, if their animation is called "trash", set it to "normal" after power level >= 3.
function npc_meta:on_vacuum_changed(power)
  local game = self:get_game()
  local sprite = self:get_sprite()
  local animation = sprite:get_animation()

  -- Set to normal
  if power >= 3
     and animation == "trash"
     and sprite:has_animation("normal")
  then
    sprite:set_animation("normal")
    game:set_value(self:get_name().."__cleaned", true)
    log(string.format("NPC (%d, %d) set to normal by vacuum.", self:get_position()))
  end
end

-- Set the NPC to turn themselves to always face an entity (unset by passing nil as argument)
function npc_meta:set_watch(entity)
  if not entity then
    -- If nil is passed and an entity was previously being watched, stop watching it
    if self.watching then
      self.watching.being_watched_by = nil
    end
    self.watching = nil
  else
    -- Store the entity being watched
    self.watching = entity
    -- Store who is watching the entity
    entity.being_watched_by = self
    -- Register when the entity changes its position
    entity:register_event("on_position_changed", function(self2, ...)
      if self2.being_watched_by then
        npc_sprite = self2.being_watched_by:get_sprite()
        local npc_x, npc_y, npc_layer = self2.being_watched_by:get_position()
        local entity_x, entity_y, entity_layer = self2:get_position()
        local dx = entity_x - npc_x
        local dy = entity_y - npc_y
        -- Determine the direction to watch according to their relative positions
        if math.abs(dx) > math.abs(dy) then
          if dx > 0 then
            npc_sprite:set_direction(0)
          else
            npc_sprite:set_direction(2)
          end
        else
          if dy > 0 then
            npc_sprite:set_direction(3)
          else
            npc_sprite:set_direction(1)
          end
        end
      end
    end)
  end
end

-- It decides if a bubble is displayed over the hero when facing
function npc_meta:should_show_interaction_bubble()
  local game = self:get_game()
  local dialog_enabled = game:is_dialog_enabled()
  local hero_free = game:get_hero():get_state() == "free"

  return hero_free and not dialog_enabled
end
