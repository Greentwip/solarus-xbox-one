-- This is the main Lua script of your project.
-- You will probably make a title screen and then start a game.
-- See the Lua API! http://www.solarus-games.org/doc/latest

require("scripts/features")
local solarus_logo = require("scripts/menus/solarus_logo")
local intro        = require("scripts/menus/intro")
local title_screen = require("scripts/menus/title_screen")
local inventory    = require("scripts/menus/inventory.lua")

local debug_enabled = false
function sol.main.is_debug_enabled()
  return debug_enabled
end

-- This function is called when Solarus starts.
function sol.main:on_started()

  -- HACK: Solarus can't do certain things such as display built-in dialogs
  --       or read joypad inputs unless a game has been started.
  --       We start a fake game now, and it's later replaced by the real game.
  local fakegame = sol.game.load("save1.dat")
  fakegame:set_starting_location("0000", nil)
  fakegame:start()
  sol.main.game = fakegame

  -- Setting a language is useful to display text and dialogs.
  sol.language.set_language("en")

  -- If there is a file called "debug" in the write directory, enable debug mode.
  debug_enabled = sol.file.exists("debug")

  -- Preload sound effects
  sol.audio.preload_sounds()

  -- Show the Solarus logo initially.
  function fakegame:on_started()
    if sol.main.is_debug_enabled() then
      sol.menu.start(fakegame, title_screen)
    else
      sol.menu.start(fakegame, solarus_logo)
    end
  end

  -- Intro plays after Solarus logo
  function solarus_logo:on_finished()
    sol.menu.start(fakegame, intro)
  end

  -- Title screen after intro
  function intro:on_finished()
    sol.menu.start(fakegame, title_screen)
    sol.timer.start(fakegame, 25000, function()
      sol.menu.start(fakegame, intro)
    end)
  end

end

-- Event called when the player pressed a keyboard key.
function sol.main:on_key_pressed(key, modifiers)

  local handled = false
  if key == "f11" or
    (key == "return" and (modifiers.alt or modifiers.control)) then
    -- F11 or Ctrl + return or Alt + Return: switch fullscreen.
    local is_fullscreen = sol.video.is_fullscreen()
    sol.video.set_fullscreen(not is_fullscreen)
    sol.video.set_cursor_visible(is_fullscreen) -- hide mouse on fullscreen
    handled = true
  elseif key == "f4" and modifiers.alt then
    -- Alt + F4: stop the program.
    sol.main.exit()
    handled = true
  elseif key == "escape" and sol.main.game == nil then
    -- Escape in title screens: stop the program.
    sol.main.exit()
    handled = true
  elseif key == "escape" and sol.video.is_fullscreen() then
    -- Escape fullscreen
    sol.video.set_fullscreen(false)
    sol.video.set_cursor_visible(true)
    handled = true
  elseif key == "q" and sol.main.game and sol.main.is_debug_enabled() then
    sol.main.game:get_hero():teleport("debug")
  end

  return handled
end

-- Starts a game.
function sol.main:start_savegame(game)

  -- Skip initial menus if any.
  sol.menu.stop(solarus_logo)

  sol.main.game = game

  -- Disable game overs for this game
  function game:on_game_over_started()
    log("Game over technically happened")
    game:set_life(12)
    game:stop_game_over()
  end

  -- Returns an item for item_ command strings
  function get_item_for_command(command)

    local slot = tonumber(string.match(command, "^item_([12])$"))

    if slot then
      local item = game:get_item_assigned(slot)
      return item
    else
      return nil
    end
  end


  function game:on_command_pressed(command)
    -- Don't handle any of this stuff when a dialog box is open
    if game:is_dialog_enabled() or game:is_picker_enabled() then
      return false
    end

    -- Disable attacking; the stick is a regular item
    if command == "attack" then
      return true
    end

    -- Handle items with item:on_command_pressed()
    local item = get_item_for_command(command)
    if item and item.on_command_pressed ~= nil then
      if game:is_paused() then return true end
      item:on_command_pressed(command)
      return true
    else
      -- Fall back to item:on_using()
      return false
    end

  end

  function game:on_command_released(command)
    -- Handle items with item:on_command_released()
    local item = get_item_for_command(command)
    if item and item.on_command_released ~= nil then
      if game:is_paused() then return true end
      item:on_command_released(command)
      return true
    else
      return false
    end

  end

  function game:on_paused()
    sol.menu.start(sol.main.game, inventory)
  end

  function game:on_unpaused()
    sol.menu.stop(inventory)
  end

  game:start()
end
