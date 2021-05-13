-- Lua script of map _stage/evolv.
-- This script is executed every time the hero enters this map.

require("scripts/coroutine_helper")

local map = ...
local game = map:get_game()
local hero = map:get_hero()
local camera = map:get_camera()

-- Event called at initialization time, as soon as this map is loaded.
function map:on_started()
  local hermione_asleep = game:get_value("hermione_asleep")
  local beaver_follower = game:get_value("npc_follower") == "animals/beaver"
  hermione:get_sprite():set_animation("sleeping")

  -- Hermione logic
  if beaver_follower and not hermione_asleep then
    hermione_sensor:set_enabled()
  elseif hermione_asleep then
    hermione:set_enabled()
  end

  -- What do to if the cutscene already happened
  if game:get_value("cutscene4_intro") then
    cutscene4:set_enabled(false)
    beakers:set_enabled(false)
    explosion:set_enabled(false)
  end

  -- What do to if you already agreed to warp
  if game:get_value("cutscene4") then
    martini:set_enabled(false)
    malcolm:set_enabled(false)
  end
end

-- Interaction with Neperforto's bell
function neperforto_bell:on_interaction()
  game:start_dialog("evolv.rachel.1")
  neperforto:get_sprite():set_direction(0)
end

function hermione_sensor:on_activated()
  self:set_enabled(false)

  local npc_follower = hero:get_follower()
  if npc_follower then
    hero:freeze()
    map:get_camera():focus_on(npc_follower, 160)
    game:start_dialog("evolv.hermione.1", function()
      npc_follower.free = true
      npc_follower:get_sprite():set_animation("walking")
      local m = sol.movement.create("target")
      m:set_target(hermione)
      m:set_speed(40)
      m:set_ignore_obstacles()
      m:start(npc_follower, function()
        hero:remove_follower()
        hermione:set_enabled()
        game:start_dialog("evolv.hermione.2", function()
          game:set_value("hermione_asleep", true)
          map:get_camera():focus_on(hero, 160)
          hero:unfreeze()
        end)
      end)
    end)
  end
end

local function do_explosion(callback)
  sol.timer.start(map, 500, function()
    beakers:set_enabled(false)
    camera:shake()
    -- TODO: sfx
    explosion:get_sprite():set_animation("exploding", function()
      sol.timer.start(map, 1000, callback)
    end)
  end)
end

local function warp_out()
  game:set_value("cutscene4", true)
  game:set_value("bridge_switch", true)
  hero:teleport("overworld", "east_beach")
end

function cutscene4:on_activated()
  self:set_enabled(false)

  map:start_coroutine(function()
    hero:freeze()
    game:set_pause_allowed(false)
    wait_for(camera.focus_on, camera, martini, 160)
    wait(1000)
    dialog("evolv.martini.1")
    wait_for(do_explosion)
    dialog("evolv.martini.3")
    dialog("evolv.martini.5")
    wait_for(camera.focus_on, camera, hero, 160)
    hero:get_sprite():set_animation("walking")
    local m = sol.movement.create("target")
    m:set_target(hero_dest)
    m:set_speed(50)
    movement(m, hero)
    hero:get_sprite():set_animation("stopped")
    dialog("evolv.rachel.3")
    wait_for(camera.focus_on, camera, malcolm, 160)
    wait_for(malcolm.on_interaction, malcolm)
    wait_for(camera.focus_on, camera, hero, 160)
    run_on_main(function()
      hero:unfreeze()
      game:set_pause_allowed()
    end)
  end)
end

function malcolm:on_interaction(callback)
  game:start_dialog("evolv.malcolm.3", function(answer)
    if answer == 1 then
      warp_out()
      callback()
    else
      game:start_dialog("evolv.malcolm.4", function()
        callback()
      end)
    end
  end)
end
