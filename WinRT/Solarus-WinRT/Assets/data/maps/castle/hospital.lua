require("scripts/coroutine_helper")

local map = ...
local game = map:get_game()

function map:on_started()
  hero:set_enabled(false)
  self:get_camera():start_tracking(greybeard)
end

function map:on_opening_transition_finished()
  hero:freeze()
  self:start_coroutine(function()
    local bed_sprite = rachel_bed:get_sprite()
    for i=1,4 do animation(bed_sprite, "rocking") end
    bed_sprite:set_animation("sleeping")
    wait(1000)
    for i=1,3 do animation(bed_sprite, "blinking") end
    bed_sprite:set_animation("awake")
    wait(1000)
    dialog("intro.greybeard.1")
    bed_sprite:set_animation("sitting_up")
    wait(1000)
    local fur_answer = dialog("intro.greybeard.2")
    if fur_answer == 1 then
      dialog("intro.greybeard.2.a")
    else
      dialog("intro.greybeard.2.b")
    end
    local alone_answer = dialog("intro.greybeard.3")
    if alone_answer == 1 then
      dialog("intro.greybeard.3.a")
    else
      local marvin_answer = dialog("intro.greybeard.3.b")
      if marvin_answer == 1 then
        dialog("intro.greybeard.3.b.1")
      else
        dialog("intro.greybeard.3.b.2")
      end
    end
    dialog("intro.greybeard.4")
    do
      local m = sol.movement.create("path")
      m:set_path({5,5,5,5,5,5,5,5,5,4,4,4,4,4,4,4,4,6,6,6,6,6})
      m:set_speed(60)
      movement(m, greybeard)
    end
    greybeard:remove()
    self:get_camera():start_tracking(hero)
    hero:unfreeze()
    hero:set_enabled()
    rachel_bed:remove()
    game:set_starting_location("beach/teepee")
    dialog("intro.segway")
    game:start()
  end)
end
