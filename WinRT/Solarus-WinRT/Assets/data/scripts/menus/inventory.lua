-- All game items that could appear in this menu
local id_card = require("scripts/menus/id_card.lua")

local font, font_size = "Comicoro", 16

-- Items to never show in the inventory, even if other criteria is met
local blacklist = {
  'running_shoes',
  'id_card'
}

-- Return true if the given item is blacklisted
local function in_blacklist(item)
  local given_item = item:get_name()
  for _, blacklist_item in ipairs(blacklist) do
    if given_item == blacklist_item then return true end
  end
  return false
end


-- Get the XY for an item sprite based on its position
local function get_slot_xy(i)

  local r = math.ceil(i/5) -- row of this slot
  local x = ((i-1)%5)*24
  local y = (r-1)*24

  return x, y
end

-- Show only some game items on the inventory screen
local function is_owned_equipment(item)
  if item:get_savegame_variable() -- the item is saved
     and item:get_variant() > 0 -- player owns the item
     and item:is_assignable() -- item is equipment
     and not item:is_key_item() -- not a key item
  then
    return true end
end

local function is_owned_key_item(item)
  return item:get_savegame_variable() -- the item is saved
         and item:get_variant() > 0 -- player owns the item
         and item:is_key_item() -- is a key item
end


local inventory = {}

function inventory:initialize()
  local font, font_size = "Comicoro", 16

  -- Graphics
  self.menu = sol.surface.create(144, 48)
  self.menu_bg = sol.sprite.create("menus/tool_select_bg")
  self.item_sheet = sol.sprite.create("entities/items")
  self.cursor_sprite = sol.sprite.create("menus/cursor")
  self.equip_frame = sol.sprite.create("menus/equip_frame")
  self.tools_text = sol.text_surface.create({text_key="menus.inventory.tools", font=font, font_size=font_size})
  self.stuff_menu = sol.surface.create(144, 56)
  self.stuff_bg = sol.sprite.create("menus/stuff_bg")

  self.button_left = sol.sprite.create("menus/button_red_left")
  self.button_middle = sol.sprite.create("menus/button_red_middle")
  self.button_right = sol.sprite.create("menus/button_red_right")
  self.exit_text = sol.text_surface.create({text_key="menus.inventory.exit", font=font, font_size=font_size})
  self.save_text = sol.text_surface.create({text_key="menus.inventory.save", font=font, font_size=font_size})
end

function inventory:on_started()
  local game = sol.main.game
  local all_items = sol.main.get_resource_ids("item")

  game:get_hero():freeze()

  -- Set items that should show in the inventory
  self.tool_items = {}
  self.key_items = {}
  for _, item_key in ipairs(all_items) do
    local item = game:get_item(item_key)
    local blacklisted = in_blacklist(item)
    if is_owned_equipment(item) and not blacklisted then
      table.insert(self.tool_items, item_key)
    end
    if is_owned_key_item(item) and not blacklisted then
      table.insert(self.key_items, item_key)
    end
  end

  -- Set initial cursor position
  self.cursor = 0
  local slot_1 = game:get_item_assigned(1)
  if slot_1 then
    for i, item in ipairs(self.tool_items) do
      if item == slot_1:get_name() then
        self.cursor = i break
      end
    end
  end

  -- ID card
  id_card.x = 160
  id_card.y = 8
  sol.menu.start(self, id_card)
end

-- Draw a button on dst_surface at the given coordinates with text provided by text_surface
function inventory:draw_button(dst_surface, x, y, text_surface)
  local repeat_center_n_times = math.ceil(text_surface:get_size() / 8)
  self.button_left:draw(dst_surface, x, y)
  for i = 0, repeat_center_n_times-1 do
    self.button_middle:draw(dst_surface, x + 3 + i*8, y)
  end
  self.button_right:draw(dst_surface, x + 3 + 8*repeat_center_n_times, y)
  local x_text = x + 3 + math.floor(0.5 + (8*repeat_center_n_times - text_surface:get_size())/2)
  text_surface:draw(dst_surface, x_text, y+7)
end

function inventory:on_draw(dst_surface)
  local game = sol.main.game

  self.menu:draw(dst_surface, 8, 8)
  self.menu_bg:draw(self.menu)
  self.tools_text:draw(self.menu, 8, 7)

  self.stuff_menu:draw(dst_surface, 8, 60)
  self.stuff_bg:draw(self.stuff_menu)

  -- Draw tool items, loop through inventory
  for i, item in ipairs(self.tool_items) do
    if i > 5 then break end -- 5 columns, 1 row
    if game:has_item(item) then
      self.item_sheet:set_animation(item) -- all items are in one sheet
      local x, y = get_slot_xy(i) -- item slot XY
      local ox, oy = self.item_sheet:get_origin() -- origin offset
      x = x + 8
      y = y + 19
      self.item_sheet:draw(self.menu, x+ox, y+oy) -- draw item
      if game:get_item_assigned(1) == game:get_item(item) then
        self.equip_frame:draw(self.menu, x, y) -- draw "EQUIP" frame
      end
      if self.cursor == i then
        self.cursor_sprite:draw(self.menu, x, y) -- draw cursor
      end
    end
  end

  -- Draw key items
  for i, item in ipairs(self.key_items) do
    if i > 10 then break end -- 5 columns, 2 rows
    if game:has_item(item) then
      self.item_sheet:set_animation(item) -- all items are in one sheet
      local x, y = get_slot_xy(i) -- item slot XY
      local ox, oy = self.item_sheet:get_origin() -- origin offset
      self.item_sheet:draw(self.stuff_menu, x+ox+8, y+oy+10) -- draw item
    end
  end

  -- Exit button
  self:draw_button(dst_surface, 160, 64, self.exit_text)
  if self.cursor == #self.tool_items+1 then
    self.cursor_sprite:draw(dst_surface, 168, 64) -- cancel button cursor
  end

  -- Save button
  self:draw_button(dst_surface, 200, 64, self.save_text)
  if self.cursor == #self.tool_items+2 then
    self.cursor_sprite:draw(dst_surface, 208, 64)
  end

end

function inventory:on_finished()
  local game = sol.main.game
  game:get_hero():unfreeze()
end

function inventory:on_command_pressed(command)
  local game = sol.main.game
  local exit_btn_pos = #self.tool_items+2

  -- D-Pad controls
  if command == "up" then
    self.cursor = self.cursor - 5 -- up and down navigate between rows
  elseif command == "down" then
    self.cursor = self.cursor + 5
  elseif command == "left" then
    self.cursor = self.cursor - 1
  elseif command == "right" then
    self.cursor = self.cursor + 1
  end

  -- Cursor must be between 1 and exit_btn_pos
  self.cursor = math.max(1, self.cursor)
  self.cursor = math.min(self.cursor, exit_btn_pos)
  log("Inventory cursor: " .. self.cursor)

  -- Handle selection
  if command == "action" then
    if self.cursor == exit_btn_pos-1 then
      return game:set_paused(false)
    elseif self.cursor == exit_btn_pos then
      return game:save()
    end
    -- Set item
    local item = game:get_item(self.tool_items[self.cursor])
    if item then
      game:set_item_assigned(1, item)
      log("Item assigned: " .. item:get_name())
    end
  end
end

-- Initialize when the game starts
local game_meta = sol.main.get_metatable("game")
game_meta:register_event("on_started", function(self)
  inventory:initialize()
end)

return inventory
