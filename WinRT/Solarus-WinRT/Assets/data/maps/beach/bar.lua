-- Lua script of map bar.
-- This script is executed every time the hero enters this map.

-- Feel free to modify the code below.
-- You can add more events and remove the ones you don't need.

-- See the Solarus Lua API documentation:
-- http://www.solarus-games.org/doc/latest

local map = ...
local game = map:get_game()
local hero = game:get_hero()

-- Bartender's behavior
local function bartender_talk(bartender)
  local has_whiskey = game:has_item("whiskey")
  local has_vacuum  = game:has_item("vacuum")

  -- Player has the vacuum, stop the script here
  if has_vacuum then
    game:start_dialog("beach.seagulls.bartender.3") -- "Thanks, Rachel"
    return true
  end

  -- Claudia given whiskey
  if game:get_value("claudia_whiskey") then
    game:start_dialog("beach.seagulls.bartender.4")
    return true
  end

  -- Whiskey/vacuum behavior
  if not has_whiskey and not game:get_value("claudia_whiskey") then
    game:start_dialog("beach.seagulls.bartender.1", function()
      hero:start_treasure("whiskey") -- Get whiskey
    end)
  elseif not has_vacuum then
    game:start_dialog("beach.seagulls.bartender.2") -- "Claudia is up north"
  end
end

-- Event called at initialization time, as soon as this map becomes is loaded.
function map:on_started()
  local bartender = map:get_entity("bartender")
  bartender.on_interaction = bartender_talk

  -- A second NPC tile for the counter
  local bartender2 = map:get_entity("bartender_2")
  bartender2.on_interaction = function(self)
    bartender:get_sprite():set_direction(3)
    bartender_talk(bartender)
  end
end
