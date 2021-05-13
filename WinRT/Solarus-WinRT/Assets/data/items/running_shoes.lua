-- Lua script of item running_shoes.
-- This script is executed only once for the whole game.

local item = ...
local game = item:get_game()

-- Event called when the game is initialized.
function item:on_started()
  self:set_savegame_variable("running_shoes")
  self:set_assignable(true)
  self.running_speed = 150
  self.walking_speed = 80
  self.remove_magic_ratio = 500 -- 1 of magic every ?? ms
end

-- Called when button pressed
function item:on_command_pressed(command)
  log("Running shoes: Pressed")
  -- Detect if some key used for motion is pressed 
  local function is_motion_command_pressed()
    return game:is_command_pressed("left") or game:is_command_pressed("right") or game:is_command_pressed("up") or game:is_command_pressed("down")
  end

  local current_magic = game:get_magic()
  if current_magic > 0 then
    local hero = game:get_hero() 
    hero:set_walking_speed(self.running_speed)
    if is_motion_command_pressed() then game:remove_magic(1) end
    log("Stamina level: " .. game:get_magic() .. "/" .. game:get_max_magic())
    -- Loop is repeated while button is pressed
    sol.timer.start(self, self.remove_magic_ratio, function()
      if is_motion_command_pressed() then game:remove_magic(1) end
      log("Stamina level: " .. game:get_magic() .. "/" .. game:get_max_magic())
      -- If no stamina, return hero to normal speed
      if game:get_magic() == 0 then hero:set_walking_speed(self.walking_speed) end
      return true
    end)
  end
end

-- Called when button released
function item:on_command_released(command)
  log("Running shoes: Released")
  sol.timer.stop_all(self)
  local hero = game:get_hero()
  hero:set_walking_speed(self.walking_speed)
end
