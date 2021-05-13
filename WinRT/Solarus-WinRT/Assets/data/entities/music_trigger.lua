-- Changes the music when the hero steps on it.
-- Must have a `music_id` property set on the entity.

local entity = ...
local game = entity:get_game()
local map = entity:get_map()
local hero = map:get_hero()

entity:add_collision_test("overlapping", function(self, touching_entity)
  if touching_entity == hero and self:is_in_same_region(hero) then
    local music_id = self:get_property("music_id")
    local playing_music = sol.audio.get_music()
    if music_id ~= playing_music then
      sol.audio.play_music(music_id)
      log("Music changed to: " .. music_id)
    end
  end
end)
