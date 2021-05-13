-- Lua script of map overworld.
-- This script is executed every time the hero enters this map.

-- Feel free to modify the code below.
-- You can add more events and remove the ones you don't need.

-- See the Solarus Lua API documentation:
-- http://www.solarus-games.org/doc/latest

local map = ...
local game = map:get_game()
require("scripts/coroutine_helper")
require("scripts/utils")

-- Event called at initialization time, as soon as this map becomes is loaded.
function map:on_started()
  sammy:set_watch(hero)
  big_rafflesia:set_traversable_by("hero", false)

  -- Set the new_stick cutscene according to some conditions
  if game:get_value("cutscene1") and not game:get_value("stick_chest") then
    hermione:set_position(104, 909, 0)
    peewee:set_position(152, 909, 0)
    greybeard:set_position(184, 877, 0)
    hermione:set_enabled()
    peewee:set_enabled()
    greybeard:set_enabled()
    wood_log_2:set_enabled()
  elseif game:get_value("cutscene1") and game:get_value("stick_chest") then
    wood_log_2:set_enabled()
    greybeard_2:set_enabled()
    hermione_2:set_enabled()
    peewee_2:set_enabled()
  end

  -- Hermione state
  if game:get_value("npc_follower") == "animals/beaver" or game:get_value("hermione_asleep") then
    hermione_2:set_enabled(false)
    peewee_2:set_position(peewee_2_dest:get_position())
  end

  -- Paco is moved on map load if you already showed your ID
  if game:get_value("paco_moved") then
    paco:set_position(paco_dest:get_position())
  end

  -- Recover the state of the path to EVOLV
  if game:get_value("bridge_switch") then
    bridge_switch:set_activated()
    bridge_switch:restore_EVOLV_path()
  end

  -- Martini & Malcolm state
  if game:get_value("cutscene4") then
    martini:set_enabled()
    malcolm:set_enabled()
  end

  -- pusillanimort state
  if game:get_value("pusillanimort_moved") then
    pusillanimort:set_enabled(false)
  end
end

function map:on_opening_transition_finished(destination)
  -- Trigger cutscene5
  if game:get_value("cutscene4") and not game:get_value("cutscene5") then
    self:do_cutscene5()
  end
end

function gravestone:on_interaction()
  game:start_dialog("beach.gravestone", function(status)
    if not game:has_item("tears") then
      -- Get male tears
      hero:start_treasure("tears")
    end
  end)
end

function trash_seagull_01:on_interaction()
  if self:get_sprite():get_animation() == "normal" then
    game:start_dialog("beach.seagulls.figured_out")
  else
    game:start_dialog("beach.seagulls.trash")
  end
end

function trash_seagull_02:on_interaction()
  if self:get_sprite():get_animation() == "normal" then
    game:start_dialog("beach.seagulls.uncomfortable")
  else
    game:start_dialog("beach.seagulls.sucks")
  end
end

function trash_seagull_03:on_interaction()
  if self:get_sprite():get_animation() == "normal" then
    game:start_dialog("beach.seagulls.transgressions")
  else
    game:start_dialog("beach.seagulls.compatriots")
  end
end

function trash_seagull_04:on_interaction()
  if self:get_sprite():get_animation() == "normal" then
    game:start_dialog("beach.seagulls.poseidons_daughter")
  else
    game:start_dialog("beach.seagulls.great_again")
  end
end


function ocean_1:on_activated()
  game:start_dialog("beach.ocean.sadness")
end
function ocean_2:on_activated()
  game:start_dialog("beach.ocean.grave")
end
function ocean_3:on_activated()
  game:start_dialog("beach.ocean.oil_spill")
end

-- Disable GB and beavers when opening the chest
function stick_chest:on_opened(item, variant, var)
  hero:start_treasure(item:get_name(), variant)
  -- Disable NPCs
  hermione:set_enabled(false)
  peewee:set_enabled(false)
  greybeard:set_enabled(false)
  -- Enable their counterparts across the beach
  greybeard_2:set_enabled()
  hermione_2:set_enabled()
  peewee_2:set_enabled()
end

-- Set dialog of GB
function greybeard:on_interaction()
  if wood_log_2:is_submerged() then
    game:start_dialog("beach.stick_intro.greybeard.6")
  else
    game:start_dialog("beach.stick_intro.greybeard.5")
  end
end

-- Trigger the cutscene
function cutscene_sensor:on_left()
  -- Don't run the cutscene if it has already happened
  if game:get_value("cutscene1") then return end
  game:set_value("cutscene1", true)

  local function up_movement()
    local m = sol.movement.create("straight")
    m:set_speed(60)
    m:set_max_distance(16*7+8)
    m:set_angle(math.pi / 2)
    m:set_ignore_obstacles()
    return m
  end

  -- Stick cutscene
  map:start_coroutine(function()
    hero:freeze()
    game:set_pause_allowed(false)
    hermione:set_enabled()
    peewee:set_enabled()
    greybeard:set_enabled()
    greybeard:remove_sprite()
    greybeard:create_sprite("npc/greybeard_log")
    map:get_camera():focus_on(camera_pan_1, 160, function()
      map:get_camera():start_tracking(peewee)
    end)
    do -- Rachel walk side
      local m = sol.movement.create("target")
      m:set_speed(60)
      m:set_target(cutscene1_hero_dest_1)
      m:set_smooth()
      local hero_x, hero_y = hero:get_position()
      local hero_sprite = hero:get_sprite()
      if hero_x > 120 then
        hero_sprite:set_direction(2)
      else
        hero_sprite:set_direction(0)
      end
      hero_sprite:set_animation("walking")
      m:start(hero, function()
        hero_sprite:set_direction(3)
        hero_sprite:set_animation("stopped")
      end)
    end
    -- greybeard & co walk up
    up_movement():start(hermione)
    up_movement():start(greybeard)
    do
      local m = sol.movement.create("path")
      m:set_path({2,2,2,2,2,2,2,6,4,4,2,2,2,2,2,2,2,0,0,2,2})
      m:set_speed(60)
      m:set_ignore_obstacles()
      movement(m, peewee)
    end
    map:get_camera():focus_on(hero, 160)
    greybeard:get_sprite():set_direction(1)
    local response = dialog("beach.stick_intro.greybeard.1")
    if response == 1 then
      dialog("beach.stick_intro.rachel.0")
    else
      dialog("beach.stick_intro.rachel.4")
    end
    hero:think()
    dialog("beach.stick_intro.greybeard.3")
    game:start_confetti()
    dialog("beach.stick_intro.rachel.3")
    do -- Rachel walk side
      local m = sol.movement.create("target")
      m:set_speed(60)
      m:set_target(cutscene1_hero_dest_2)
      m:set_smooth()
      local hero_x, hero_y = hero:get_position()
      local hero_sprite = hero:get_sprite()
      if hero_x > 104 then
        hero_sprite:set_direction(2)
      else
        hero_sprite:set_direction(0)
      end
      hero_sprite:set_animation("walking")
      m:start(hero, function()
        hero_sprite:set_direction(1)
        hero_sprite:set_animation("stopped")
      end)
    end
    do -- Greybeard set log
      local m = up_movement()
      m:set_max_distance(8*3)
      movement(m, greybeard)
    end
    greybeard:remove_sprite()
    greybeard:create_sprite("npc/greybeard"):set_direction(1)
    wood_log_2:set_enabled()
    wait(200)
    greybeard:get_sprite():set_direction(3)
    dialog("beach.stick_intro.greybeard.4")
    do -- Greybeard move out of the way
      local m = sol.movement.create("path")
      m:set_path({0,0,0,0,0,0,0})
      m:set_speed(60)
      m:set_ignore_obstacles()
      movement(m, greybeard)
      greybeard:get_sprite():set_direction(1)
    end
    game:set_pause_allowed()
    hero:unfreeze()
  end)
end

-- Paco moves if you show him your EVOLV ID card
function paco:on_interaction()
  local paco_moved = game:get_value("paco_moved")

  if paco_moved then
    game:start_dialog("evolv.paco.3")
    return
  end

  game:start_dialog("evolv.paco.1", function()
    paco:prompt_item(function(item)
      if not item then return end

      local variant = item:get_variant()
      local is_id = item:get_name() == "id_card"
      local is_usa_id = is_id and variant == 1
      local is_evolv_id = is_id and variant == 2

      if is_evolv_id then
        game:set_value("paco_moved", true)
        game:start_dialog("evolv.paco.2", function()
          local m = sol.movement.create("target")
          m:set_target(paco_dest)
          m:start(paco)
        end)
      elseif is_usa_id then
        game:start_dialog("evolv.paco.4")
      else
        game:start_dialog("evolv.paco.5")
      end
    end)
  end)
end

-- Restore the direct way to EVOLV
function bridge_switch:restore_EVOLV_path()
  disableAll({
    jumper_up,
    jumper_down,
    log_puzzle_1,
    log_puzzle_2,
    log_puzzle_3,
    log_puzzle_4,
    log_puzzle_5,
    log_puzzle_6,
    log_puzzle_7,
    log_puzzle_8})

  enableAll({bridge_left, bridge_center, bridge_right, jumper_left, jumper_right})
end

-- Behaviour of EVOLV bridge switch
function bridge_switch:on_activated()
  game:set_value("bridge_switch", true)
  bridge_switch:restore_EVOLV_path()
end

function greybeard_2:on_interaction()
  local evolv_id = game:get_item("id_card"):get_variant() == 2

  if game:get_value("cutscene5") then
    game:start_dialog("beach.cutscene5.greybeard.7")
    return
  end

  if evolv_id then
    game:start_dialog("beach.trash_scene.greybeard.5")
    return
  end

  -- Trash cutscene logic
  map:start_coroutine(function()
    hero:freeze()
    game:set_pause_allowed(false)
    dialog("beach.trash_scene.greybeard.1")
    wait_for(hero.start_treasure, hero, "id_card", 2, nil)
    dialog("beach.trash_scene.greybeard.2")
    hero:freeze()
    do
      local m = sol.movement.create("target")
      m:set_target(peewee_2_dest)
      m:set_speed(32)
      movement(m, peewee_2)
    end
    do
      local m = sol.movement.create("target")
      m:set_target(hero)
      m:set_ignore_obstacles()
      m:set_speed(32)
      movement(m, hermione_2)
    end
    dialog("beach.trash_scene.hermione.3")
    hermione_2:set_enabled(false)
    hero:create_follower("animals/beaver")
    game:set_pause_allowed()
    hero:unfreeze()
  end)
end

-- Pusillanimort behavior
function pusillanimort:on_interaction()
  game:start_dialog("beach.pusillanimort.1", function()
    pusillanimort:prompt_item(function(item)
      if not item then return end

      local variant = item:get_variant()
      local is_id = item:get_name() == "id_card"
      local is_usa_id = is_id and variant == 1
      local is_evolv_id_L1 = is_id and variant == 2 and item:get_level() == 1
      local is_evolv_id_L2 = is_id and variant == 2 and item:get_level() == 2

      if is_usa_id then
        game:start_dialog("beach.pusillanimort.2")
      elseif is_evolv_id_L1 then
        game:start_dialog("beach.pusillanimort.3")
      elseif is_evolv_id_L2 then
        game:start_dialog("beach.pusillanimort.4", function()
          self:set_position(pusillanimort_dest:get_position())
          game:set_value("pusillanimort_moved", true)
          pusillanimort:set_enabled(false)
          -- TODO: Proper walking animation
          -- local m = sol.movement.create("target")
          -- m:set_target(pusillanimort_dest)
          -- function m:on_finished()
          --   game:set_value("pusillanimort_moved", true)
          --   pusillanimort:set_enabled(false)
          -- end
          -- m:start(self)
        end)
      end
    end)
  end)
end

-- cutscene5
function map:do_cutscene5()
  local id_card = game:get_item("id_card")

  map:start_coroutine(function()
    hero:freeze()
    hero:set_position(east_beach:get_position())
    hero:get_sprite():set_direction(1)
    game:set_pause_allowed(false)
    wait(1200)
    log("cutscene5")

    dialog("beach.cutscene5.greybeard.1")
    -- greybeard_2:think()
    hero:think()
    malcolm:think()
    wait(2000)
    dialog("beach.cutscene5.greybeard.4")
    id_card:set_level(2)
    wait_for(hero.brandish, hero, "id_card", 2, "beach.cutscene5.rachel.1")
    dialog("beach.cutscene5.greybeard.7")

    game:set_value("cutscene5", true)
    game:set_pause_allowed()
    hero:unfreeze()
  end)
end

-- tutorial
function tutorial_trigger:on_activated()
  self:set_enabled(false)
  tutorial_gate:set_enabled()
  tutorial_gate_npc:set_enabled()
end
