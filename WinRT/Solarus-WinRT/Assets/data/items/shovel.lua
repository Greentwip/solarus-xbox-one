-- Lua script of item shovel.

local item = ...
local game = item:get_game()

-- Event called when the game is initialized.
function item:on_started()
  self:set_savegame_variable("shovel")
  self:set_assignable(true)
end

function item:can_dig()
  local map = game:get_map()
  local hero = map:get_hero()
  return map:is_diggable(hero:get_position())
end

function item:dig()
  local map = game:get_map()
  local hero = map:get_hero()
  local x, y, layer = hero:get_position()
  x = x + 8 - x%16
  y = y + 16 - y%16
  log("Creating dug ground in " .. x .. ", " .. y)
  local dug_ground = map:create_custom_entity({
    x=x, y=y, layer=layer,
    width=16, height=16,
    direction=0,
    sprite="entities/dug_ground",
    model="dug_ground"
  })
end

function item:on_using()
  local hero = game:get_hero()
  local map = game:get_map()

  hero:freeze()
  hero:set_animation("digging", function()
    if self:can_dig() then
      self:dig()
      -- TODO: dig SFX
    else
      -- TODO: can't dig SFX
    end
    hero:unfreeze()
    hero:get_sprite():set_direction(3)
  end)
end
