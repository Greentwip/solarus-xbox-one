require("scripts/coroutine_helper")

local end_credits = require("scripts/menus/end_credits")
local confetti = require("scripts/menus/confetti")
local save_feedback = require("scripts/menus/save_feedback")
local outro = require("scripts/menus/outro")
local end_card = require("scripts/menus/end_card.lua")
local id_card = require("scripts/menus/id_card.lua")

local game_meta = sol.main.get_metatable("game")

-- Start the end sequence of the game
function game_meta:start_ending()

  game_self = self

  -- Show credits when outro finishes
  function outro:on_finished()
    sol.menu.start(game_self, end_credits)
  end

  -- Show end card when credits finish
  function end_credits:on_finished()
    sol.menu.start(game_self, end_card)
  end

  sol.menu.start(self, outro)
end

-- Adds game:roll_credits() which sequences out the last part of the game.
function game_meta:roll_credits()
  sol.menu.start(self, end_credits)
end

-- Make confetti fall across the screen
function game_meta:start_confetti()
  sol.menu.start(self, confetti)
end

-- Start the end sequence of the game
function game_meta:start_outro()
  self:set_pause_allowed(false)
  sol.menu.start(self, outro)
end

-- The ID card with the current set faction appears from above in the screen.
-- ```emphasize``` is an optional parameter string.
--  * If it is equal to "faction", the faction logo will blink.
--  * If it is equal to "level", the EVOLV level will blink (if EVOLV faction is set).
function game_meta:show_id_card(emphasize)
  -- Hide previous ID card if any
  self:hide_id_card()

  -- Set initial position of the ID
  id_card.x = 84
  id_card.y = -50

  -- Set initial movement of the ID
  id_card.m = sol.movement.create("straight")
  id_card.m:set_angle(3*math.pi/2)
  id_card.m:set_max_distance(70)
  id_card.m:set_speed(300)

  -- Set optional faction blinking
  id_card.is_faction_blinking = emphasize == "faction"

  -- Set optional EVOLV level blinking
  id_card.is_level_blinking = emphasize == "level"

  sol.menu.start(self, id_card)
end

-- Hide the ID card from the screen
function game_meta:hide_id_card()
  if sol.menu.is_started(id_card) then sol.menu.stop(id_card) end
end

-- Event that will be called when the game is saved
function game_meta:on_saved()
  log("Game saved")
  sol.main.start_coroutine(function()
    run_on_main(function() sol.menu.start(self, save_feedback) end)
    local m1 = sol.movement.create("straight")
    m1:set_angle(math.pi/2)
    m1:set_max_distance(16)
    m1:set_speed(500)
    movement(m1, save_feedback.feedback_bg)
    wait(3000)
    local m2 = sol.movement.create("straight")
    m2:set_angle(3*math.pi/2)
    m2:set_max_distance(16)
    m2:set_speed(32)
    movement(m2, save_feedback.feedback_bg)
    run_on_main(function() sol.menu.stop(save_feedback) end)
  end)
end

-- Override game:save()
game_meta._save = game_meta.save
function game_meta:save()
  self:_save()
  self:on_saved()
end

-- Check whether a picker is already active
-- https://gitlab.com/voadi/voadi/wikis/docs/lua-api#gameis_picker_enabled
function game_meta:is_picker_enabled()
  return self._picker_enabled
end

function game_meta:on_map_changed(map)
  local npc_follower_id = self:get_value("npc_follower")
  if npc_follower_id then
    local hero = self:get_hero()
    hero:create_follower(npc_follower_id)
  end
  if not map.tile_map then
    map:load_diggable_tiles()
  end
end

game_meta:register_event("on_started", function(self)
  self._picker_enabled = false -- Initialize game with _picker_enabled attribute

  -- Set volume for debug mode
  if sol.main.is_debug_enabled() then
    sol.audio.set_music_volume(0)
    sol.audio.set_sound_volume(50)
  end
end)
