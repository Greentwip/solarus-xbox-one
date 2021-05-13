-- Lua script of map dungeon1.
-- This script is executed every time the hero enters this map.

-- Feel free to modify the code below.
-- You can add more events and remove the ones you don't need.

-- See the Solarus Lua API documentation:
-- http://www.solarus-games.org/doc/latest

local map = ...
local game = map:get_game()

-- Event called at initialization time, as soon as this map is loaded.
function map:on_started()

  -- You can initialize the movement and sprites of various
  -- map entities here.
  local switch = map:get_entity("switch")
  local gate = map:get_entity("gate")
  function switch:on_activated()
    gate:open()
  end

  local switch2 = map:get_entity("switch_2")
  local block = map:get_entity("that_block")
  function switch2:on_activated()
    block:set_enabled(false)
  end
  function switch2:on_inactivated()
    block:set_enabled()
  end

  local puzzle1 = map:get_puzzle("1")
  function puzzle1:on_solved()
    log("puzzle solved!")
    gate_2:open()
  end

  local puzzle2 = map:get_puzzle("2")
  function puzzle2:on_solved()
    gate_3:open()
  end

  function switch_3:on_activated()
    final_door:open()
  end
  function switch_3:on_inactivated()
    final_door:close()
  end

  function switch_4:on_activated()
    gate_4:open()
  end
  function switch_4:on_inactivated()
    gate_4:close()
  end

  local puzzle3 = map:get_puzzle("3")
  function puzzle3:on_solved()
    gate_5:open()
    gate_6:open()
  end

  function bat_sensor:on_activated()
    if bat_1 then
      bat_1:activate()
      bat_2:activate()
      bat_3:activate()
      bat_4:activate()
      bat_5:activate()
      bat_6:activate()
    end
  end

end
