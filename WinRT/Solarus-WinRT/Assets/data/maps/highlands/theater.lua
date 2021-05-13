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
  local camera = map:get_camera()
  hero:track(function(x, y, z)
    -- Check if Rachel tries to walk only when the sensor is activated
    if self:is_enabled() then
      -- Stop any timer that this function may have launched (if Rachel did not wait)
      sol.timer.stop_all(self)
      -- Freeze the hero during the pan effect
      hero:freeze()
      camera:focus_on(ferdinand, 400, function()
        game:start_dialog("theater.ferdinand.1", function()
          camera:focus_on(hero, 200, function()
            hero:unfreeze()
          end)
        end)
      end)
      -- Launch a timer: if it is not stopped, Rachel is allowed to pass
      sol.timer.start(self, 10000, function()
        -- Freeze the hero during the pan effect
        hero:freeze()
        camera:focus_on(ferdinand, 200, function()
          game:start_dialog("theater.ferdinand.2", function()
            camera:focus_on(hero, 200, function()
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
