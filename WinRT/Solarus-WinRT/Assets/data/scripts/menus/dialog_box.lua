-- Script that creates a dialog box for a game.

-- Usage:
-- require("scripts/menus/dialog_box")

require("scripts/utils")
require("scripts/multi_events")
local language_manager = require("scripts/language_manager")

-- Creates and sets up a dialog box for the specified game.
local function initialize_dialog_box_features(game)

  if game.get_dialog_box ~= nil then
    -- Already done.
    return
  end

  local dialog_box = {

    -- Dialog box properties.
    dialog = nil,                -- Dialog being displayed or nil.
    first = true,                -- Whether this is the first dialog of a sequence.
    style = nil,                 -- "box" or "empty".
    vertical_position = "auto",  -- "auto", "top" or "bottom".
    skip_mode = nil,             -- "none", "current", "all" or "unchanged".
    icon_index = nil,            -- Index of the 16x16 icon in hud/dialog_icons.png or nil.
    info = nil,                  -- Parameter passed to start_dialog().
    skipped = false,             -- Whether the player skipped the dialog.
    selected_answer = nil,       -- Selected answer (1 or 2) or nil if there is no question.

    -- Displaying text gradually.
    next_line = nil,             -- Next line to display or nil.
    line_it = nil,               -- Iterator over of all lines of the dialog.
    lines = {},                  -- Array of the text of the 3 visible lines.
    line_surfaces = {},          -- Array of the 3 text surfaces.
    line_index = nil,            -- Line currently being shown.
    char_index = nil,            -- Next character to show in the current line.
    char_delay = nil,            -- Delay between two characters in milliseconds.
    full = false,                -- Whether the 3 visible lines have shown all content.
    need_letter_sound = false,   -- Whether a sound should be played with the next character.
    gradual = true,              -- Whether text is displayed gradually.
    is_name = nil,               -- Whether name box is visible
    is_name_on_right = nil,      -- If true then name is drawn on right side of dialog box.
    name_surface = nil,          -- Text surface for name text

    -- Graphics.
    dialog_surface = nil,
    box_img = nil,
    icons_img = nil,
    end_lines_sprite = nil,
    box_dst_position = nil,      -- Destination coordinates of the dialog box.
    question_dst_position = nil, -- Destination coordinates of the question icon.
    icon_dst_position = nil,     -- Destination coordinates of the icon.
    bg_sprite = nil,

    photo_animation_done = false,
  }

  -- Constants.
  local nb_visible_lines = 3     -- Maximum number of lines in the dialog box.
  local char_delays = {          -- Delay before displaying the next character.
    slow = 60,
    medium = 40,
    fast = 20  -- Default.
  }
  local letter_sound_delay = 100
  local box_width = 152
  local box_height = 48

  -- Initialize dialog box data.
  local font, font_size = "Comicoro", 16
  for i = 1, nb_visible_lines do
    dialog_box.lines[i] = ""
    dialog_box.line_surfaces[i] = sol.text_surface.create{
      horizontal_alignment = "left",
      vertical_alignment = "top",
      font = font,
      font_size = font_size,
    }
  end
  dialog_box.name = ""
  dialog_box.name_surface = sol.text_surface.create{
    horizontal_alignment = "left",
    vertical_alignment = "top",
    font = "Poco",
    color = {0, 0, 0},
    font_size = 10,
  }
  dialog_box.dialog_surface = sol.surface.create(sol.video.get_quest_size())
  dialog_box.box_img = sol.surface.create("hud/dialog_box.png")
  dialog_box.icons_img = sol.surface.create("hud/dialog_icons.png")
  dialog_box.end_lines_sprite = sol.sprite.create("hud/dialog_box_message_end")
  dialog_box.bg_sprite = sol.sprite.create("menus/dialog_bg")
  dialog_box.photo_sprite = sol.sprite.create("menus/dialog_photos")
  dialog_box.photo_sprite:set_ignore_suspend()
  dialog_box.photo_frame = sol.sprite.create("menus/dialog_photo_frame")

  -- Exits the dialog box system.
  function dialog_box:quit(status)

    -- Determine the position of the dialog box on the screen. (Copied from dialog_box:on_started())
    local map = game:get_map()
    local camera_x, camera_y, camera_width, camera_height = map:get_camera():get_bounding_box()

    local top = false
    if self.vertical_position == "top" then
      top = true
    elseif self.vertical_position == "auto" then
      local hero = map:get_entity("hero")
      if hero:is_enabled() and hero:is_visible() then
        local hero_x, hero_y = hero:get_position()
        if hero_y >= camera_y + (camera_height / 2 + 10) then
          top = true
        end
      end
    end

    -- Animate the dialog before closing
    local distance = 70
    if top then
      distance = 65
    end
    local movement_speed = 300
    local photo_movement_delay = 100

    -- helper to create the movement out
    local function movement_out(distance, speed)
      local m = sol.movement.create("straight")
      m:set_max_distance(distance)
      m:set_speed(speed)
      if top then
        m:set_angle(math.pi/2)
      else
        m:set_angle(3*math.pi/2)
      end
      return m
    end

    local m_bg = movement_out(distance, movement_speed)
    local m_dialog = movement_out(distance, movement_speed)
    local m_photo = movement_out(distance, movement_speed)
    local m_frame = movement_out(distance, movement_speed)

    m_bg:start(self.bg_sprite)
    m_dialog:start(self.dialog_surface)
    self.photo_timer = sol.timer.start(self, photo_movement_delay, function()
      dialog_box.photo_animation_done = false
      m_photo:start(self.photo_sprite, function()
        dialog_box.photo_animation_done = true
      end)
      m_frame:start(self.photo_frame)
    end)

    -- Stop dialog with passed status from here
    sol.timer.start(self, 300, function()
      game:stop_dialog(status)

      -- Original code of this function below
      --if sol.menu.is_started(dialog_box) then
        --sol.menu.stop(dialog_box)
      --end
    end)
  end

  function game:get_dialog_box()
    return dialog_box
  end

  -- Called by the engine when a dialog starts.
  game:register_event("on_dialog_started", function(game, dialog, info)

    dialog_box.dialog = dialog
    dialog_box.info = info

    if info and info.vertical_position then
      dialog_box:set_position(info.vertical_position)
    end

    sol.menu.start(game, dialog_box)
  end)

  -- Called by the engine when a dialog finishes.
  game:register_event("on_dialog_finished", function(game, dialog)

    if sol.menu.is_started(dialog_box) then
      sol.menu.stop(dialog_box)
    end
    dialog_box.dialog = nil
    dialog_box.info = nil
    dialog_box.is_name = nil
    dialog_box.is_name_on_right = nil
  end)

  -- Sets the style of the dialog box for subsequent dialogs.
  -- style must be one of:
  -- - "box" (default): Usual dialog box.
  -- - "empty": No decoration.
  function dialog_box:set_style(style)

    dialog_box.style = style
    if style == "box" then
      -- Make the dialog box slightly transparent.
      -- dialog_box.dialog_surface:set_opacity(216)
    end
  end

  -- Sets the vertical position of the dialog box for subsequent dialogs.
  -- vertical_position must be one of:
  -- - "auto" (default): Choose automatically so that the hero is not hidden.
  -- - "top": Top of the screen.
  -- - "bottom": Botton of the screen.
  function dialog_box:set_position(vertical_position)
    dialog_box.vertical_position = vertical_position
  end

  local function repeat_show_character()

    dialog_box:check_full()
    while not dialog_box:is_full()
      and dialog_box.char_index > #dialog_box.lines[dialog_box.line_index] do
      -- The current line is finished.
      dialog_box.char_index = 1
      dialog_box.line_index = dialog_box.line_index + 1
      dialog_box:check_full()
    end

    if not dialog_box:is_full() then
      dialog_box:add_character()
    else
      sol.audio.play_sound("message_end")
    end
  end

  -- The first dialog of a sequence starts.
  function dialog_box:on_started()

    -- Set the initial properties.
    -- Subsequent dialogs in the same sequence do not reset them.
    self.icon_index = nil
    self.skip_mode = "none"
    self.char_delay = char_delays["fast"]
    self.selected_answer = nil

    -- Determine the position of the dialog box on the screen.
    local map = game:get_map()
    local camera_x, camera_y, camera_width, camera_height = map:get_camera():get_bounding_box()

    local top = false
    if self.vertical_position == "top" then
      top = true
    elseif self.vertical_position == "auto" then
      local focused_entity = map:get_camera():get_tracked_entity() or map:get_hero()
      if focused_entity:is_enabled() and focused_entity:is_visible() then
        local focused_entity_x, focused_entity_y = focused_entity:get_position()
        if focused_entity_y >= camera_y + (camera_height / 2 + 10) then
          top = true
        end
      end
    end

    -- Set the coordinates of graphic objects.
    local screen_width, screen_height = sol.video.get_quest_size()
    local x = 48
    local y = (screen_height - 52)

    if top then
      y = 16
    end

    self.box_dst_position = { x = x, y = y }
    self.question_dst_position = { x = x + 18, y = y + 27 }
    self.icon_dst_position = { x = x + 18, y = y + 22 }

    self:show_dialog()

    -- Place the dialog and photo outside the screen and animate them in
    local y_offset = 70
    if top then
      y_offset = -60
    end
    local movement_speed = 350
    local photo_movement_delay = 100
    local bounce_delay = 50
    self.bg_sprite:set_xy(0, y_offset)
    self.dialog_surface:set_xy(0, y_offset)
    self.photo_sprite:set_xy(0, y_offset)
    self.photo_frame:set_xy(0, y_offset)

    -- helper to create the movement in
    local function movement_in(distance, speed)
      local m = sol.movement.create("straight")
      m:set_max_distance(distance)
      m:set_speed(speed)
      if top then
        m:set_angle(3*math.pi/2)
      else
        m:set_angle(math.pi/2)
      end
      return m
    end

    -- helper to create the bounce movement
    local function movement_bounce(distance, speed)
      local m = sol.movement.create("straight")
      m:set_max_distance(distance)
      m:set_speed(speed)
      if top then
        m:set_angle(math.pi/2)
      else
        m:set_angle(3*math.pi/2)
      end
      return m
    end

    local m_bg = movement_in(math.abs(y_offset)+4, movement_speed)
    local m_bg_bounce = movement_bounce(4, 20)
    local m_dialog = movement_in(math.abs(y_offset)+4, movement_speed)
    local m_dialog_bounce = movement_bounce(4, 20)
    local m_photo = movement_in(math.abs(y_offset)+2, 250)
    local m_photo_bounce = movement_bounce(2, 60)
    local m_frame = movement_in(math.abs(y_offset)+2, 250)
    local m_frame_bounce = movement_bounce(2, 60)

    -- Complete animation: Entering + bounce
    local function animate_in_and_bounce(m, m_bounce, drawable, cb)
      m:start(drawable, function()
        sol.timer.start(self, bounce_delay, function()
          m_bounce:start(drawable, cb)
        end)
      end)
    end

    animate_in_and_bounce(m_bg, m_bg_bounce, self.bg_sprite)
    animate_in_and_bounce(m_dialog, m_dialog_bounce, self.dialog_surface)
    self.photo_timer = sol.timer.start(self, photo_movement_delay, function()
      dialog_box.photo_animation_done = false
      animate_in_and_bounce(m_photo, m_photo_bounce, self.photo_sprite, function()
        dialog_box.photo_animation_done = true
      end)
      animate_in_and_bounce(m_frame, m_frame_bounce, self.photo_frame)
    end)

  end

  -- The dialog box is being closed.
  function dialog_box:on_finished()

    -- Remove overriden command effects.
    if game.set_custom_command_effect ~= nil then
      game:set_custom_command_effect("action", nil)
      game:set_custom_command_effect("item_1", nil)
    end
  end

  -- A dialog starts (not necessarily the first one of its sequence).
  function dialog_box:show_dialog()

    -- Initialize this dialog.
    local dialog = self.dialog

    local text = dialog.text
    if dialog_box.info ~= nil then
      -- There is a "$v" sequence to substitute.
      text = text:gsub("%$v", dialog_box.info)
    end
    -- Split the text in lines.
    text = text:gsub("\r\n", "\n"):gsub("\r", "\n")
    self.line_it = text:gmatch("([^\n]*)\n")  -- Each line including empty ones.

    self.next_line = self.line_it()
    self.line_index = 1
    self.char_index = 1
    self.skipped = false
    self.full = false
    self.need_letter_sound = self.style ~= "empty"

    if dialog.skip ~= nil then
      -- The skip mode changes for this dialog.
      self.skip_mode = dialog.skip
    end

    if dialog.icon ~= nil then
      -- The icon changes for this dialog ("-1" means none).
      if dialog.icon == "-1" then
        self.icon_index = nil
      else
        self.icon_index = dialog.icon
      end
    end

    if dialog.question == "1" then
      -- This dialog is a question.
      self.selected_answer = 1  -- The answer will be 1 or 2.
    end

    -- Start displaying text.
    self:show_more_lines()
  end

  -- Returns whether there are more lines remaining to display after the current
  -- 3 lines.
  function dialog_box:has_more_lines()
    return self.next_line ~= nil
  end

  -- Check if the photo animation is done
  function dialog_box:is_photo_animation_finished()
    return dialog_box.photo_animation_done
  end

  -- Updates the result of is_full().
  function dialog_box:check_full()
    if self.line_index >= nb_visible_lines
      and self.char_index > #self.lines[nb_visible_lines]
      and self:is_photo_animation_finished() then
      self.full = true
    else
      self.full = false
    end
  end

  -- Returns whether all 3 current lines of the dialog box are entirely
  -- displayed.
  function dialog_box:is_full()
    return self.full
  end

  -- Shows the next dialog of the sequence.
  -- Closes the dialog box if there is no next dialog.
  function dialog_box:show_next_dialog()

    local next_dialog_id
    if self.selected_answer ~= 2 then
      -- No question or first answer
      next_dialog_id = self.dialog.next
    else
      -- Second answer.
      next_dialog_id = self.dialog.next2
    end

    if next_dialog_id ~= nil and next_dialog_id ~= "_unknown" then
      -- Show the next dialog.
      self.first = false
      self.selected_answer = nil
      self.dialog = sol.language.get_dialog(next_dialog_id)
      self:show_dialog()
    else
      -- Finish the dialog, returning the answer or nil if there was no question.
      local status = self.selected_answer

      -- Conform to the built-in handling of shop items.
      if self.dialog.id == "_shop.question" then
        -- The engine expects a boolean answer after the "do you want to buy"
        -- shop item dialog.
        status = self.selected_answer == 1
      end

      -- Commented line below is the original code.
      -- Changed to implement 'end dialog animation' in dialog_box:quit()
      -- game:stop_dialog(status)
      self:quit(status)
    end
  end

  -- Starts showing a new group of 3 lines in the dialog.
  -- Shows the next dialog (if any) if there are no remaining lines.
  function dialog_box:show_more_lines()

    self.gradual = true

    if not self:has_more_lines() then
      self:show_next_dialog()
      return
    end

    -- Hide the action icon and change the sword icon.
    if game.set_custom_command_effect ~= nil then
      game:set_custom_command_effect("action", nil)
      if self.skip_mode ~= "none" then
        game:set_custom_command_effect("item_1", "skip")
        game:set_custom_command_effect("action", "next")
      else
        game:set_custom_command_effect("item_1", nil)
      end
    end

    -- Check if name should be displayed
    if self:has_more_lines() then
      local is_empty, is_right, is_special, name = self.next_line:match"^%s*##(#?)(>?)([@&]?)(.*)"
      if name then
        self.is_name = is_empty=="" --3rd # hides name
        self.is_name_on_right = is_right==">"
        if is_special=="&" then --use savegame value
          self.name_surface:set_text(game:get_value(name) or "")
        elseif is_special=="@" then --use strings.dat value
          self.name_surface:set_text(sol.language.get_string(name) or "")
        else
          self.name_surface:set_text(name)
        end
        self.next_line = self.line_it()
      end
    end

    -- Prepare the 3 lines.
    for i = 1, nb_visible_lines do
      self.line_surfaces[i]:set_text("")
      if self:has_more_lines() then
        self.lines[i] = self.next_line
        self.next_line = self.line_it()
      else
        self.lines[i] = ""
      end
    end
    self.line_index = 1
    self.char_index = 1

    if self.gradual then
      sol.timer.start(self, self.char_delay, repeat_show_character)
    end
  end

  -- Adds the next character to the dialog box.
  -- If this is a special character (like $0, $v, etc.),
  -- the corresponding action is performed.
  function dialog_box:add_character()

    local line = self.lines[self.line_index]
    local current_char = line:sub(self.char_index, self.char_index)
    if current_char == "" then
      error("No remaining character to add on this line")
    end
    self.char_index = self.char_index + 1
    local additional_delay = 0
    local text_surface = self.line_surfaces[self.line_index]

    -- Special characters:
    -- - $1, $2 and $3: slow, medium and fast
    -- - $0: pause
    -- - $v: variable
    -- - space: don't add the delay
    -- - 110xxxx: multibyte character

    local special = false
    if current_char == "$" then
      -- Special character.

      special = true
      current_char = line:sub(self.char_index, self.char_index)
      self.char_index = self.char_index + 1

      if current_char == "0" then
        -- Pause.
        additional_delay = 1000

      elseif current_char == "1" then
        -- Slow.
        self.char_delay = char_delays["slow"]

      elseif current_char == "2" then
        -- Medium.
        self.char_delay = char_delays["medium"]

      elseif current_char == "3" then
        -- Fast.
        self.char_delay = char_delays["fast"]

      else
        -- Not a special char, actually.
        text_surface:set_text(text_surface:get_text() .. "$")
        special = false
      end
    end

    if not special then
      -- Normal character to be displayed.
      text_surface:set_text(text_surface:get_text() .. current_char)

      -- If this is a multibyte character, also add the next byte.
      local byte = current_char:byte()
      if byte >= 192 and byte < 224 then
        -- The first byte is 110xxxxx: the character is stored with
        -- two bytes (utf-8).
        current_char = line:sub(self.char_index, self.char_index)
        self.char_index = self.char_index + 1
        text_surface:set_text(text_surface:get_text() .. current_char)
      end

      if current_char == " " then
        -- Remove the delay for whitespace characters.
        additional_delay = -self.char_delay
      end
    end

    if not special and current_char ~= nil and self.need_letter_sound then
      -- Play a letter sound sometimes.
      sol.audio.play_sound("message_letter")
      self.need_letter_sound = false
      sol.timer.start(self, letter_sound_delay, function()
        self.need_letter_sound = true
      end)
    end

    if self.gradual then
      sol.timer.start(self, self.char_delay + additional_delay, repeat_show_character)
    end
  end

  -- Stops displaying gradually the current 3 lines, shows them immediately.
  -- If the 3 lines were already finished, the next group of 3 lines starts
  -- (if any).
  function dialog_box:show_all_now()

    if self:is_full() then
      self:show_more_lines()
    else
      self.gradual = false
      -- Check the end of the current line.
      self:check_full()
      while not self:is_full() do

        while not self:is_full()
            and self.char_index > #self.lines[self.line_index] do
          self.char_index = 1
          self.line_index = self.line_index + 1
          self:check_full()
        end

        if not self:is_full() then
          self:add_character()
        end
        self:check_full()
      end
    end
  end

  function dialog_box:on_command_pressed(command)

    if command == "action" then

      -- Display more lines.
      if self:is_full() then
        self:show_more_lines()
      elseif self.skip_mode ~= "none" then
        self:show_all_now()
      end

    elseif command == "item_1" then

      -- Attempt to skip the dialog.
      if self.skip_mode == "all" then
        self.skipped = true
        -- Commented line below is the original code.
        -- Changed to implement 'end dialog animation' in dialog_box:quit()
        -- game:stop_dialog("skipped")
        self:quit("skipped")
      elseif self:is_full() then
        self:show_more_lines()
      elseif self.skip_mode == "current" then
        self:show_all_now()
      end

    elseif command == "up" or command == "down" then

      if self.selected_answer ~= nil
          and not self:has_more_lines()
          and self:is_full() then
        sol.audio.play_sound("message_end")
        self.selected_answer = 3 - self.selected_answer  -- Switch between 1 and 2.
      end
    end

    -- Don't propagate the event to anything below the dialog box.
    return true
  end

  function dialog_box:on_draw(dst_surface)
    dialog_box:check_full()

    local x, y = self.box_dst_position.x, self.box_dst_position.y

    self.dialog_surface:clear()

    -- Draw a photo
    if self.dialog.photo then
      if self.dialog.photo ~= self.dialog.old_photo then
        self.photo_sprite:set_animation(self.dialog.photo)
      end
      self.dialog.old_photo = self.dialog.photo -- support animated photos
      local bg_width, bg_height = self.bg_sprite:get_size()
      local photo_x, photo_y = x + bg_width + 8, y + 4
      self.photo_sprite:draw(dst_surface, photo_x, photo_y)
      self.photo_frame:draw(dst_surface, photo_x, photo_y)
    end

    -- Draw a dark rectangle.
    self.bg_sprite:draw(dst_surface, x, y-5)

    -- Draw the name box.
    if self.is_name then
      local text_width = self.name_surface:get_size()
      text_width = math.max(text_width, 12)
      local right_offset = self.is_name_on_right and (131-text_width) or 0
      self.box_img:draw_region( -- left side
        204, 60, 4, 13, self.dialog_surface,
        x + 5 + right_offset, y - 12
      )
      local x_offset = 0
      while x_offset < text_width do
        self.box_img:draw_region(
          208, 60,
          math.min(8, text_width - x_offset), 13,
          self.dialog_surface,
          x + 9 + x_offset + right_offset,
          y - 12
        )
        x_offset = x_offset + 8
      end
      self.box_img:draw_region( -- right side
        213, 60, 7, 13, self.dialog_surface,
        x + 9 + text_width + right_offset, y - 12
      )
      self.name_surface:draw(self.dialog_surface, x + 11 + right_offset, y - 14)
    end

    -- Draw the text.
    local text_x = x + (self.icon_index == nil and 8 or 16)
    local text_y = y - 9
    for i = 1, nb_visible_lines do
      text_y = text_y + 12
      if self.selected_answer ~= nil
          and i == nb_visible_lines - 1
          and not self:has_more_lines() then
        -- The last two lines are the answer to a question.
        text_x = text_x + 8
      end
      self.line_surfaces[i]:draw(self.dialog_surface, text_x, text_y)
    end

    -- Draw the icon.
    if self.icon_index ~= nil then
      local row, column = math.floor(self.icon_index / 10), self.icon_index % 10
      self.icons_img:draw_region(16 * column, 16 * row, 16, 16,
      self.dialog_surface,
      self.icon_dst_position.x, self.icon_dst_position.y)
      self.question_dst_position.x = x + 50
    else
      self.question_dst_position.x = x + 18
    end

    -- Draw the question arrow.
    if self.selected_answer ~= nil
        and self:is_full()
        and not self:has_more_lines() then
      self.question_dst_position.y = self.box_dst_position.y +
          (self.selected_answer == 1 and 19 or 32)
      self.box_img:draw_region(96, 60, 8, 8, self.dialog_surface,
          self.question_dst_position.x - 11, self.question_dst_position.y -1)
    end

    -- Draw the end message arrow.
    if self:is_full() then
      self.end_lines_sprite:draw(self.dialog_surface, x + 103, y + 56)
    end

    -- Final blit.
    self.dialog_surface:draw(dst_surface)
  end

  dialog_box:set_style("box")

end

-- Set up the dialog box on any game that starts.
local game_meta = sol.main.get_metatable("game")
game_meta:register_event("on_started", initialize_dialog_box_features)

return true
