-- Lua script of map _stage/cave_after_evolv.
-- This script is executed every time the hero enters this map.

-- Feel free to modify the code below.
-- You can add more events and remove the ones you don't need.

-- See the Solarus Lua API documentation:
-- http://www.solarus-games.org/doc/latest

local map = ...
local game = map:get_game()

local darkness_area1 = {5, false, "radius", 35}
local darkness_area2 = {10}
local darkness_area3 = {20}
local darkness_area4 = {10, true, "facing"}
local darkness_area5 = {20}
local darkness_area6 = {5, false, "radius", 35}

-- Event called at initialization time, as soon as this map is loaded.
function map:on_started()
  self:start_darkness(unpack(darkness_area1)) 
end

function separator_1:on_activating(d4)
  map:stop_darkness()
  if d4 == 1 then map:start_darkness(unpack(darkness_area2)) end
  if d4 == 3 then map:start_darkness(unpack(darkness_area1)) end
end

function separator_2:on_activating(d4)
  map:stop_darkness()
  if d4 == 1 then map:start_darkness(unpack(darkness_area3)) end
  if d4 == 3 then map:start_darkness(unpack(darkness_area2)) end
end

function separator_3:on_activating(d4)
  map:stop_darkness()
  if d4 == 2 then map:start_darkness(unpack(darkness_area4)) end
  if d4 == 0 then map:start_darkness(unpack(darkness_area3)) end
end

function separator_4:on_activating(d4)
  map:stop_darkness()
  if d4 == 3 then map:start_darkness(unpack(darkness_area5)) end
  if d4 == 1 then map:start_darkness(unpack(darkness_area4)) end
end

function separator_5:on_activating(d4)
  map:stop_darkness()
  if d4 == 3 then map:start_darkness(unpack(darkness_area6)) end
  if d4 == 1 then map:start_darkness(unpack(darkness_area5)) end
end
