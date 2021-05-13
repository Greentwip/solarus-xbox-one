-- This menu ultimately exists to let you call npc:prompt_item()
-- It's designed to be called from npc:prompt_item() and really cannot stand alone

require("scripts/multi_events")

local menu_items = {} -- Items to show in the menu


-- Get the XY for an item sprite based on its position
local function get_slot_xy(i)
  local mx, my = 24, 32 -- offset from menu origin

  local r = math.ceil(i/4) -- row of this slot
  local ix = ((i-1)%4)*24
  local iy = (r-1)*24

  local x = mx + ix
  local y = my + iy

  return x, y
end


local picker = {} -- item picker menu


function picker:initialize()
  local font, font_size = "Comicoro", 16

  -- Graphics
  self.menu = sol.surface.create(144, 104)
  self.menu_bg = sol.sprite.create("menus/menu_bg")
  self.item_sheet = sol.sprite.create("entities/items")
  self.cursor_sprite = sol.sprite.create("menus/cursor")

  -- Player sprite
  self.player_sprite = sol.sprite.create("hero/tunic1")
  self.player_sprite:set_animation("walking")
  self.player_sprite:set_direction(3)

  -- NPC sprite
  self.npc_box = sol.surface.create(16, 16)
  self.npc_sprite = nil

  -- Question text
  self.title = sol.text_surface.create({text_key="menus.picker.question", font=font, font_size=font_size})
  self.title:set_color({0, 0, 0})

  -- Nope button
  self.nope_button = sol.surface.create(32, 16)
  self.nope_button:fill_color({198, 34, 0})
  local button_text = sol.text_surface.create({text_key="menus.picker.nope", font=font, font_size=font_size})
  button_text:draw(self.nope_button, 4, 8)
end


-- Called when the picker menu starts
function picker:on_started()
  local game = sol.main.game
  local all_items = sol.main.get_resource_ids("item")

  game:get_hero():freeze()
  game._picker_enabled = true
  menu_items = {} -- cleared when a menu starts

  -- Graphics
  self.npc_sprite = sol.sprite.create(self._npc:get_sprite():get_animation_set())
  self.npc_sprite:set_direction(3)

  -- Initialize properties
  self.cursor = 1
  self._selection = nil

  -- Filter items
  assert(self._filter, "A filter must be set")

  for _, item_id in ipairs(all_items) do
    local item = game:get_item(item_id)
    if item:get_savegame_variable() -- item is saved
       and game:has_item(item_id) -- player owns the item
       and self._filter(item) -- item passes any filters
    then
      table.insert(menu_items, item_id)
    end
  end

  -- Animate menu in
  self.menu:set_xy(0, -120)
  local m = sol.movement.create("straight")
  m:set_max_distance(120)
  m:set_speed(300)
  m:set_angle(3*math.pi/2)
  m:start(self.menu)

end


-- Set/get the selected item (when "action" is pressed)
function picker:set_selection(item)
  self._selection = item
end

function picker:get_selection()
  return self._selection
end


-- Called every frame
function picker:on_draw(dst_surface)
  local game = sol.main.game

  -- Draw BG graphics
  self.menu:draw(dst_surface, 56, 16)
  self.menu_bg:draw(self.menu)

  -- Draw characters
  local x, y
  x, y = self.player_sprite:get_origin()
  self.player_sprite:draw(self.menu, 24+x, 8+y) -- draw player sprite
  x, y = self.npc_sprite:get_origin()
  self.npc_box:clear()
  self.npc_sprite:draw(self.npc_box, x, y)
  self.npc_box:draw(self.menu, 104, 8) -- draw NPC sprite

  -- Draw question
  self.title:draw(self.menu, 49, 16)

  -- Draw items, loop through inventory
  for i, item in ipairs(menu_items) do
    if game:has_item(item) then
      self.item_sheet:set_animation(item) -- all items are in one sheet
      local x, y = get_slot_xy(i) -- item slot XY
      local ox, oy = self.item_sheet:get_origin() -- origin offset
      self.item_sheet:draw(self.menu, x+ox, y+oy) -- draw item
      if self.cursor == i then
        self.cursor_sprite:draw(self.menu, x, y) -- draw cursor
      end
    end
  end

  -- Draw cancel button
  self.nope_button:draw(self.menu, 56, 80)
  if self.cursor == #menu_items+1 then
    self.cursor_sprite:draw(self.menu, 64, 80) -- cancel button cursor
  end
end

-- Animate the menu before stopping it
function picker:quit()
  local game = sol.main.game

  local m = sol.movement.create("straight")
  m:set_max_distance(120)
  m:set_speed(300)
  m:set_angle(math.pi/2)
  m:start(self.menu)

  sol.timer.start(self, 400, function ()
    sol.menu.stop(self)
  end)

  game:get_hero():unfreeze()
  game._picker_enabled = false
end

-- Called when a button is pressed
function picker:on_command_pressed(command)
  local game = sol.main.game

  -- D-Pad controls
  if command == "up" then
    self.cursor = self.cursor - 4 -- up and down navigate between rows
  elseif command == "down" then
    self.cursor = self.cursor + 4
  elseif command == "left" then
    self.cursor = self.cursor - 1
  elseif command == "right" then
    self.cursor = self.cursor + 1
  end

  -- Cursor must be between 1 and #menu_items+1 (cancel)
  self.cursor = math.max(1, self.cursor)
  self.cursor = math.min(self.cursor, #menu_items+1)

  -- Handle selection
  if command == "action" then
    if self.cursor ~= #menu_items+1 then
      local item = game:get_item(menu_items[self.cursor])
      self:set_selection(item)
    end

    self:quit()
  end

  return true
end


-- Initialize picker when the game starts
local game_meta = sol.main.get_metatable("game")
game_meta:register_event("on_started", function(self)
  picker:initialize()
end)


return picker
