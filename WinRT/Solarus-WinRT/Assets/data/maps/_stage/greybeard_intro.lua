local map = ...
local game = map:get_game()

-- Event called at initialization time, as soon as this map is loaded.
function map:on_started()
  function greybeard:on_interaction()
    self:start_dialog("evolv.greybeard.intro", function(choice)
      if choice == 1 then
        self:start_dialog("evolv.greybeard.intro.yes")
      else
        self:start_dialog("evolv.greybeard.intro.no")
      end
    end)
  end
end
