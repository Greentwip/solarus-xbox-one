local game_manager = require("scripts/game_manager")

local title_screen = {}
local popup = {}


-- Helper functions to start a new game or continue
local save_file = "save1.dat"


function title_screen:on_started()
  self.phase = 0

  -- Initial graphics
  self.main_surface  = sol.surface.create()
  self.title_graphic = sol.surface.create("menus/title.png")
  self.title_text    = sol.surface.create("menus/title_text.png")
  self.press_start   = sol.sprite.create("menus/press_start")

  -- Hide "Press Start" initially
  self.press_start:set_xy(-100, -100)

  sol.audio.play_music("cosmicgem829/title", false)

  self.main_surface:fade_in(30, function()
    -- Show "Press Start" after the fade in
    self.press_start:set_xy(0, 0)
    self.phase = 1
  end)
end


function title_screen:on_draw(screen)
  screen:fill_color({255, 255, 255})
  self.main_surface:draw(screen)
  self.title_graphic:draw(self.main_surface)
  self.title_text:draw(self.main_surface)
  self.press_start:draw(self.main_surface, 96, 64)
end


-- Check if a game exists.
-- Display the game options popup, or not, depending.
function title_screen:on_command_pressed(command)
  if self.phase < 1 then return true end -- fade_in hasn't finished

  if command == "action" or command == "pause" or command == "item_1" then
    local game_exists = sol.game.exists("save1.dat")
    if game_exists then
      sol.menu.start(title_screen, popup)
      return true
    else
      sol.menu.stop(title_screen)
      game_manager:new_game()
      return true
    end
  end
end


-- Popup menu

function popup:on_started()
  self.cursor = 1
--
  -- Black box
  self.box = sol.surface.create(75, 43)
  self.box:fill_color({0, 0, 0})
  self.box:set_xy(-400, -400)

  -- Options
  self.options = {"title_screen.continue", "title_screen.new_game"}

  -- Hide title screen stuff
  title_screen.title_text:set_opacity(0)
  title_screen.press_start:set_xy(-100, -100)

  -- Scroll the title screen up
  local title_movement = sol.movement.create("target")
  title_movement:set_speed(100)
  title_movement:set_target(0, -20)
  title_movement:start(title_screen.title_graphic, function()
    self.box:set_xy(0, 0)
  end)

end


function popup:on_draw(dst_surface)
  -- Draw box
  self.box:draw(dst_surface, 94, 83)

  -- Draw options
  local font, font_size = "Comicoro", 16

  for i, v in ipairs(self.options) do
    local text = sol.text_surface.create({text_key=v, font=font, font_size=font_size})
    if popup.cursor == i then
      text:set_color({255, 255, 255})
    else
      text:set_color({100, 100, 100})
    end
    text:draw(self.box, 8, i*12)
  end
end


function popup:on_command_pressed(command)
  if command == "up" then
    popup.cursor = popup.cursor - 1
  elseif command == "down" then
    popup.cursor = popup.cursor + 1
  end

  -- cursor must be between 1 and #self.options
  popup.cursor = math.max(1, popup.cursor)
  popup.cursor = math.min(popup.cursor, #self.options)

  if command == "action" or command == "pause" or command == "item_1" then
    if popup.cursor == 1 then
      game_manager:continue_game()
    elseif popup.cursor == 2 then
      game_manager:new_game()
    end
    sol.menu.stop(title_screen)
  end
  return true
end


return title_screen
