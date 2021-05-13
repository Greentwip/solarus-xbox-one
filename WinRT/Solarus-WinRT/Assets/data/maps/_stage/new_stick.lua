-- Lua script of map _stage/new_stick.
-- This script is executed every time the hero enters this map.

require("scripts/coroutine_helper")

local map = ...
local game = map:get_game()

-- Event called at initialization time, as soon as this map is loaded.
function map:on_started()

  -- Trigger the cutscene
  function cutscene_sensor:on_left()
    -- Don't run the cutscene if it has already happened
    if game:get_value("cutscene1") then return end
    game:set_value("cutscene1", true)

    local function up_movement()
      local m = sol.movement.create("straight")
      m:set_speed(60)
      m:set_max_distance(16*8+8)
      m:set_angle(math.pi / 2)
      m:set_ignore_obstacles()
      return m
    end

    -- Cutscene
    map:start_coroutine(function()
      hero:freeze()
      greybeard:remove_sprite()
      greybeard:create_sprite("npc/greybeard_log")
      map:get_camera():focus_on(beaver_2, 160)
      do -- Rachel walk side
        local m = sol.movement.create("target")
        m:set_speed(60)
        m:set_target(120, 301)
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
      up_movement():start(beaver_1)
      up_movement():start(greybeard)
      do
        local m = sol.movement.create("path")
        m:set_path({2,2,2,2,2,2,2,2,2,6,4,4,2,2,2,2,2,2,2,0,0,2,2})
        m:set_speed(60)
        m:set_ignore_obstacles()
        movement(m, beaver_2)
      end
      map:get_camera():focus_on(hero, 160)
      greybeard:get_sprite():set_direction(1)
      dialog("_stage.newstick.greybeard.1")
      dialog("_stage.newstick.rachel.0")
      dialog("_stage.newstick.peewee.1")
      dialog("_stage.newstick.rachel.1")
      dialog("_stage.newstick.hermione.1")
      dialog("_stage.newstick.rachel.2")
      dialog("_stage.newstick.hermione.2")
      dialog("_stage.newstick.peewee.2")
      dialog("_stage.newstick.greybeard.3")
      game:start_confetti() -- FIXME: Make this shorter
      dialog("_stage.newstick.rachel.3")
      do -- Rachel walk side
        local m = sol.movement.create("target")
        m:set_speed(60)
        m:set_target(104, 301)
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
      wood_log:set_enabled()
      wait(200)
      greybeard:get_sprite():set_direction(3)
      dialog("_stage.newstick.greybeard.4")
      do -- Greybeard move out of the way
        local m = sol.movement.create("path")
        m:set_path({0,0,0,0,0,0,0})
        m:set_speed(60)
        m:set_ignore_obstacles()
        movement(m, greybeard)
        greybeard:get_sprite():set_direction(1)
      end
      hero:unfreeze()
    end)

  end

end
