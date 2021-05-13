-- Initialize hero behavior specific to this quest.

require("scripts/multi_events")
require("scripts/utils")
local all = require("scripts/meta/all")

local hero_meta = sol.main.get_metatable("hero")

local function silence_music()
  -- silence music for brandish SFX
  local volume = sol.audio.get_music_volume()
  sol.audio.set_music_volume(0)
  log("Music volume: 0")
  local timer = sol.timer.start(2600, function()
    log("Music volume: 100")
    sol.audio.set_music_volume(volume)
  end)
  timer:set_suspended_with_map(false)
end

-- Rachel has a thought bubble animation
function hero_meta:think()
  all.think(self)
  force_animation(self:get_sprite("thought_bubble"))
end

-- Make Rachel blink
function hero_meta:blink()
  local sprite = self:get_sprite()
  -- Blink conditions
  local is_stopped = sprite:get_animation() == "stopped"
  local is_climbing = self:get_tunic_sprite_id() == "hero/tunic1-climbing"

  if is_stopped and not is_climbing then
    sprite:set_animation("blink", "stopped")
  end
end

-- The hero can only swing the sword, nothing else
function hero_meta:on_state_changed(state)
  if state == "sword loading"
  or state == "sword tapping"
  or state == "sword spin attack" then
    self:freeze()
    self:unfreeze()
  end
end

-- Return the hero's position relative to the screen.
function hero_meta:get_screen_position()
  local camera = self:get_map():get_camera()
  local hero_x, hero_y = self:get_position()
  local camera_x, camera_y = camera:get_position()
  return hero_x-camera_x, hero_y-camera_y
end

-- Tracks the position of the hero and updates the callback every frame
function hero_meta:track(callback)
  self:register_event("on_position_changed", function(self, x, y, z)
    callback(x, y, z)
  end)
end

-- The hero will brandish an item without obtaining it.
-- Reimplementation of hero:start_treasure() except you don't get the item.
function hero_meta:brandish(item_key, variant, dialog_id, callback)
  local item = self:get_game():get_item(item_key)
  local game = item:get_game()
  local map = item:get_map()

  local hero_sprite = self:get_sprite()
  local x, y, z = self:get_position()

  -- Set defaults
  if not variant then variant = 1 end
  if not dialog_id then
    dialog_id = "_treasure." .. item_key .. "." .. variant
  end

  local function do_brandish()
    self:freeze()
    silence_music()
    sol.audio.play_sound("treasure")

    -- Set the hero's sprite
    hero_sprite:set_animation("brandish")

    -- Create a map entity for the item to show during brandishing
    local item_entity = map:create_custom_entity({
      sprite = "entities/items",
      direction = variant - 1,
      x=0, y=0, layer=0, width=16, height=16
    })
    local item_sprite = item_entity:get_sprite()
    local ox, oy = item_sprite:get_origin()
    item_sprite:set_animation(item_key)
    if item_key == "coconut" then
      -- HACK: https://gitlab.com/voadi/voadi/issues/333
      item_entity:set_position(x, y-19+oy, z+1)
    else
      item_entity:set_position(x, y-28+oy, z+1)
    end

    -- Start item dialog
    game:start_dialog(dialog_id, function()
      -- End
      self:unfreeze()
      hero_sprite:set_animation("stopped")
      item_entity:remove()
      if callback then callback() end
    end)
  end

  if self:get_carried_object() then
    -- Throw any object that hero is carrying before brandishing
    self:throw(do_brandish)
  else
    do_brandish()
  end

end

-- Called when the hero is first created (once per game)
function hero_meta:on_created()
  -- Call hero:update() every frame
  sol.timer.start(self, 10, function()
    self:on_update()
    return true
  end)
  -- Make the hero blink her eyes every 6 seconds
  sol.timer.start(self, 6000, function()
    self:blink()
    return true -- loop forever
  end)

end

function hero_meta:on_state_changing(state_name, next_state_name)
  local item_star = self:get_sprite("item_star")
  local tunic_top = self:get_sprite("tunic_top") -- HACK
  if state_name == "treasure" then
    if item_star then self:remove_sprite(item_star) end
    if tunic_top then self:remove_sprite(tunic_top) end -- HACK
  end
end

function hero_meta:on_state_changed(new_state_name)
  if new_state_name == "treasure" then
    local item_star = self:create_sprite("menus/item_star", "item_star")
    item_star:set_ignore_suspend()
    self:bring_sprite_to_back(item_star)

    -- HACK: Layer the tunic sprite on again because
    -- setting the sprite order doesn't affect the hero
    -- https://gitlab.com/solarus-games/solarus/issues/1348#note_142442035
    local tunic_sprite = self:get_sprite("tunic")
    local tunic_top = self:create_sprite(tunic_sprite:get_animation_set(), "tunic_top")
    tunic_top:set_direction(tunic_sprite:get_direction())
    tunic_top:set_animation("brandish")
    -- END HACK

    force_animation(item_star, true)
    silence_music()
  end
end

-- Gets called every frame
function hero_meta:on_update()
  -- Handle ground stuff
  local current_ground = self:get_ground_below()
  if self._previous_ground and self._previous_ground ~= current_ground then
    -- Check if the ground below Rachel has changed
    self:on_ground_below_changed(current_ground)
  end
  self._previous_ground = current_ground
end

-- Make Rachel change her tunic if she is climbing
function hero_meta:on_ground_below_changed(ground_below)
  if ground_below == "ladder" then
    self:set_tunic_sprite_id("hero/tunic1-climbing")
  else
    self:set_tunic_sprite_id("hero/tunic1")
  end
end

-- Set up hero on any game that starts.
local function initialize_hero_features(game)
  local hero = game:get_hero()
  hero:set_invincible() -- In this game you can never die
  hero:set_walking_speed(80)
end

-- Create NPC follower above the hero
function hero_meta:create_follower(sprite_id)
  local game = self:get_game()
  local map = game:get_map()
  local x, y, layer = self:get_position()
  local hero_direction = self:get_sprite():get_direction()
  local npc_follower = map:get_entity("npc_follower")

  if npc_follower then
    npc_follower:remove_sprite()
    npc_follower:create_sprite(sprite_id)
    npc_follower:get_sprite():set_direction(hero_direction)
  else
    npc_follower = map:create_custom_entity({
      name="npc_follower",
      x=x, y=y, layer=layer,
      width=16, height=16,
      direction=hero_direction,
      model="npc_follower",
      sprite=sprite_id
    })
    npc_follower.free = false
    npc_follower.sprite_id = sprite_id
  end

  npc_follower:set_enabled()
  self:bring_to_front()

  game:set_value("npc_follower", sprite_id)
end

-- Return the NPC follower
function hero_meta:get_follower()
  local game = self:get_game()
  local map = game:get_map()
  return map:get_entity("npc_follower")
end

-- Remove NPC follower
function hero_meta:remove_follower()
  local game = self:get_game()
  local npc_follower = self:get_follower()

  if npc_follower then
    npc_follower:set_enabled(false)
  end
  game:set_value("npc_follower", nil)
  npc_follower:reset_states()
end

-- Wear a mask specified by name
function hero_meta:set_mask(mask_name)
  sol.main.game:set_value("mask", mask_name)
  if self.mask_sprite then
    self:remove_sprite(self.mask_sprite)
  end
  self.mask_sprite = self:create_sprite("entities/masks/" .. mask_name)

  local hero_sprite = self:get_sprite("tunic")
  -- Set direction of the mask according to hero
  self.mask_sprite:set_direction(hero_sprite:get_direction())

  -- Update mask direction automatically
  hero_sprite:register_event("on_direction_changed", function(self2, animation, direction)
    if self.mask_sprite then
      self.mask_sprite:set_direction(direction)
    end
  end)

end

-- Unwear any mask
function hero_meta:unset_mask()
  sol.main.game:set_value("mask", nil)
  if self.mask_sprite then
    self:remove_sprite(self.mask_sprite)
    self.mask_sprite = nil
  end
end

-- Return the worn mask
function hero_meta:get_mask()
  return sol.main.game:get_value("mask")
end

-- Display an exclamation bubble over the hero's head when facing an interactable entity
hero_meta.exclamation_sprite = sol.sprite.create("menus/exclamation_bubble")
function hero_meta:on_post_draw(camera)
  local map = self:get_map()
  local facing_entity = self:get_facing_entity()
 -- Only deal with entities that exist, are enabled and are really in that position
  local entity_is_there = facing_entity ~= nil and facing_entity:is_enabled() and facing_entity:overlaps(self, "facing")

  if entity_is_there and facing_entity.should_show_interaction_bubble and facing_entity:should_show_interaction_bubble() then
    if self.exclamation_sprite:get_animation() == "hidden" then
      self.exclamation_sprite:set_animation("started", "stopped")
    end

    local x, y = self:get_position()
    map:draw_visual(self.exclamation_sprite, x, y)
  else
    self.exclamation_sprite:set_animation("hidden")
  end
end

-- Throw any carried object that hero is currently lifting, if any
function hero_meta:throw(callback)
  local carried_object = self:get_carried_object()
  if carried_object then
    -- Consider that on_breaking is previously defined
    local _on_breaking = carried_object.on_breaking
    function carried_object:on_breaking()
      if _on_breaking then _on_breaking() end
      if callback then callback() end
    end
    -- Throw the object
    local game = self:get_game()
    game:simulate_command_pressed("action")
    game:simulate_command_released("action")
  end
end

-- Define where light touches Rachel
function hero_meta:get_light_contact_point(d4, beam)
  local x, y = self:get_bounding_box()
  if d4 == 0 then
    return x , y + 2 + beam
  elseif d4 == 1 then
    return x + 6 + beam, y + 15
  elseif d4 == 2 then
    return x + 15, y + 2 + beam
  else
    return x + 6 + beam, y + 1
  end
end

local game_meta = sol.main.get_metatable("game")
game_meta:register_event("on_started", initialize_hero_features)
return true
