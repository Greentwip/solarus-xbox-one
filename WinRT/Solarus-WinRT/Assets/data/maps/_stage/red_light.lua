-- Lua script of map _stage/red_light.
-- This script is executed every time the hero enters this map.

-- Feel free to modify the code below.
-- You can add more events and remove the ones you don't need.

-- See the Solarus Lua API documentation:
-- http://www.solarus-games.org/doc/latest

local map = ...
local game = map:get_game()

-- Event called at initialization time, as soon as this map is loaded.
function map:on_started()

  -- You can initialize the movement and sprites of various
  -- map entities here.
end

-- Run this function if sensor is activated
local function sensor_activated(self)
  local hero = game:get_hero()
  hero:track(function(x, y, z)
    -- Check if Rachel tries to walk only when the sensor is activated
    if self:is_enabled() then
      -- Stop any timer that this function may have launched (if Rachel did not wait) 
      sol.timer.stop_all(self)
      -- Freeze the hero during the pan effect
      hero:freeze()
      map:get_camera():focus_on(ferdinand, 160, function()
        game:start_dialog("theater.ferdinand.1", function()
          map:get_camera():focus_on(hero, 160, function()
            hero:unfreeze()
          end)
        end)
      end)
      -- Launch a timer: if it is not stopped, Rachel is allowed to pass
      sol.timer.start(self, 10000, function()
        -- Freeze the hero during the pan effect
        hero:freeze()
        map:get_camera():focus_on(ferdinand, 160, function()
          game:start_dialog("theater.ferdinand.2", function()
            map:get_camera():focus_on(hero, 160, function()
              hero:unfreeze()
            end)
          end)
          -- Disable the sensor after waiting successfully
          self:set_enabled(false)          
        end)
      end)
    end
  end)
end

sensor1.on_activated = sensor_activated
sensor2.on_activated = sensor_activated
sensor3.on_activated = sensor_activated

-- Event called after the opening transition effect of the map,
-- that is, when the player takes control of the hero.
function map:on_opening_transition_finished()

end
