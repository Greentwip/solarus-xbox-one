-- Script that lets you use the sword as a normal item.
-- Note that the sword button cannot be held with this method (for charging or tapping)

local item = ...
local game = item:get_game()

function item:on_created()
  self:set_savegame_variable("stick")
  self:set_assignable(true)
end

function item:on_variant_changed(variant)
  -- The possession state of the sword determines the built-in ability "sword".
  self:get_game():set_ability("sword", variant)
end

function item:on_command_pressed(command)
  local hero = game:get_hero()
  hero:start_attack()
  item:set_finished()
end