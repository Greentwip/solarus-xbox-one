-- This entity pushes the hero through doors.
-- Place an entity along the entire door path (on both sides of the room).
-- It's especially useful for north/south doorways because of the extra tiles.

-- FIXME: It has quirks. You can't enter the door backwards (eg when
--        strafing with the vacuum or pulling a block), and it doesn't
--        fully manage the sensor it creates.

local entity = ...
local game = entity:get_game()
local map = entity:get_map()
local hero = map:get_hero()

function entity:on_created()
  local width, height = self:get_size()
  local x, y, z       = self:get_position()

  local sensor = map:create_sensor({
    width=width, height=height,
    x=x, y=y, layer=z
  })

  function sensor:on_activated()
    log("Door walker: activated")
    local direction = hero:get_direction()
    hero:walk(direction * 2, true)
  end

  function sensor:on_left()
    log("Door walker: left")
    hero:unfreeze()
  end
end
