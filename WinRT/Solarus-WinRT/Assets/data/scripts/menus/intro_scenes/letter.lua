-- Pink letter comes into frame. Rachel shakes it and it pops open.
require("scripts/utils")

local scene = {} -- menu object

-- Called when the scene is started with sol.menu.start(scene)
function scene:on_started()

  -- Load graphics
  self.envelope_gfx = sol.sprite.create("menus/intro/envelope")
  self.letter_gfx   = sol.sprite.create("menus/intro/letter")
  self.box_gfx      = sol.sprite.create("menus/intro/box")
  self.box          = sol.surface.create(160, 32)
  self.box_text     = sol.surface.create(256, 144)

  do -- draw letter text
    local letter_text = sol.language.get_dialog("game.intro.letter").text
    local lines = get_lines(letter_text)
    for i, line in ipairs(lines) do
      local letter_gfx = sol.text_surface.create({font_size=16, text=line})
      local x = 8
      local y = i*13 - 3
      if i > 2 then -- HACK: second box of text needs a different padding
        y = y + 2
      end
      letter_gfx:draw(self.box_text, x, y)
    end
  end

  -- Animation to shake envelope back and forth
  function self.envelope_gfx:shiver(cb)
    local m = sol.movement.create("pixel")
    m:set_loop(true)
    m:set_trajectory({
      {2, 0},
      {-2, 0}
    })
    m:set_delay(60)
    m:start(self)

    -- End the movement manually (otherwise it goes forever)
    sol.timer.start(240, function()
      m:stop()
      cb()
    end)
  end

  -- Slide-in animation
  function self.envelope_gfx:slide_in(cb)
    local m = translate("y", -91)
    m:set_speed(96)
    m:start(self, cb)
  end

  -- Slide-out
  function self.envelope_gfx:slide_out(cb)
    local m = translate("y", 147)
    m:set_speed(200)
    m:start(self, cb)
  end

  -- Letter slide-in
  function self.letter_gfx:slide_in(cb)
    local m = translate("y", -138)
    m:set_speed(200)
    m:start(self, cb)
  end

  -- Move envelope up screen and call shiver animation
  local envelope = self.envelope_gfx
  local letter   = self.letter_gfx
  envelope:slide_in(function()
    envelope:shiver(function()
      envelope:set_animation("open")
      sol.timer.start(1000, function()
        envelope:slide_out()
        letter:slide_in(function()
          sol.timer.start(300, function()
            self.box:set_xy(0, 148)
            sol.timer.start(2000, function()
              do
                local m = sol.movement.create("target")
                m:set_target(0, -28)
                m:set_speed(200)
                m:start(self.box_text, function()
                  sol.timer.start(2000, function()
                    sol.menu.stop(scene)
                  end)
                end)
              end
            end)
          end)
        end)
      end)
    end)
  end)
end

-- Called every frame
function scene:on_draw(dst_surface)
  dst_surface:fill_color({160, 240, 240}) -- blue BG
  self.envelope_gfx:draw(dst_surface, 43, 150)
  self.letter_gfx:draw(dst_surface, 83, 150)
  self.box_gfx:draw(self.box)
  self.box_text:draw(self.box)
  self.box:draw(dst_surface, 48, -100)
end

return scene
