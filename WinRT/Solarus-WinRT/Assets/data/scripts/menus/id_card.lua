-- Manage the ID card
-- USAGE:
--
--  local id_card = require("scripts/menus/id_card.lua")
--  [SET OPTIONAL PARAMETERS]
--  sol.menu.start(self, id_card)
--
-- OPTIONAL PARAMETERS:
--
--  id_card.x, id_card.y          - Set X and Y position of the menu in the screen
--  id_card.m                     - Set an initial movement for the menu
--  id_card.is_faction_blinking   - If it is true, the faction logo will blink
--  id_card.is_level_blinking     - If it is true, the EVOLV level will blink (if EVOLV faction is set)

local id_card = {}

function id_card:on_started()
  local game = sol.main.game

  -- Create surfaces
  self.card = sol.surface.create(88, 48)
  self.card_bg = sol.sprite.create("menus/id_card/card")
  self.card_title = sol.text_surface.create({text_key="menus.inventory.id_card_title", font="Poco", font_size=10})
  self.logo = sol.sprite.create("menus/id_card/logo")

  -- Set EVOLV ID card level
  local id_card = game:get_item("id_card")
  if id_card:get_faction() == "evolv" then
    local level = id_card:get_level()
    self.card_level = sol.text_surface.create({text="L"..level, font="Poco", font_size=10})
  else
    self.card_level = nil
  end

  -- Apply initial movement
  if self.m then
    local m_card_bg = self.m
    local m_card = self.m
    m_card_bg:start(self.card_bg)
    m_card:start(self.card)
  end

  -- Blink faction
  if self.is_faction_blinking then
    sol.timer.start(self, 128, function()
      self.logo:set_opacity(255-self.logo:get_opacity())
      return true
    end)
  end

  -- Blink EVOLV level
  if self.card_level and self.is_level_blinking then
    sol.timer.start(self, 128, function()
      self.card_level:set_opacity(255-self.card_level:get_opacity())
      return true
    end)
  end
end

function id_card:on_finished()
  -- Restore optional variables to default values
  self.x = nil
  self.y = nil
  self.m = nil
  self.is_faction_blinking = nil
  self.is_level_blinking = nil
end

function id_card:on_draw(dst_surface)
  local game = sol.main.game

  if not self.x then self.x = 0 end
  if not self.y then self.y = 0 end

  -- Draw Card and background
  local card_item = game:get_item("id_card")
  if card_item:get_variant() > 0 then
    self.card:draw(dst_surface, self.x, self.y)
    self.card_bg:draw(self.card)
  end

  -- Draw Logo
  local variants = {"usa", "evolv", "transcend"}
  local animation = variants[card_item:get_variant()]
  if animation then self.logo:set_animation(animation) end
  if card_item:get_variant() < 4 then
    self.logo:draw(self.card, 32, 24)
  end

  -- Draw Title
  self.card_title:draw(self.card, 5, 3)

  -- Draw EVOLV level
  if self.card_level then
    local w, h = self.card_level:get_size()
    self.card_level:draw(self.card, 83-w, 3)
  end
end

return id_card
