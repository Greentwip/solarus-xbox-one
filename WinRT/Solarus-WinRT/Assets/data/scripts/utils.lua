-- https://www.lua.org/pil/7.1.html
function list_iter (t)
  local i = 0
  local n = table.getn(t)
  return function ()
           i = i + 1
           if i <= n then return t[i] end
         end
end

-- https://stackoverflow.com/a/8316375/8811886
function build_array(...)
  local arr = {}
  for v in ... do
    arr[#arr + 1] = v
  end
  return arr
end


-- Alias of print() but for debug mode only
function log(...)
  if sol.main.is_debug_enabled() then
    print(...)
  end
end


-- Check if the value (needle) is found in the table (haystick)
function in_table(needle, haystack)
  assert(type(haystack) == "table", "Haystack must be a table.")
  for _, value in ipairs(haystack) do
    if value == needle then return true end
  end
  return false
end


-- Encodes a resource path for use as a savegame variable
function path_encode(path)
  return string.gsub(path, '/', '_SLASH_')
end


-- Break dialog text into a table of lines
function get_lines(text)
  local lines = text
  lines = lines:gsub("\r\n", "\n"):gsub("\r", "\n")
  lines = build_array(lines:gmatch("([^\n]*)\n"))
  return lines
end


-- Movement that shivers back and forth for a duration of time
function shiver()
  -- Create movements
  local m = sol.movement.create("pixel")

  -- Change how far the entity shakes
  function m:set_intensity(n)
    m:set_trajectory({
      {n, 0},
      {n*-1, 0}
    })
  end

  m:set_intensity(2)
  m:set_loop(true)
  m:set_delay(60)

  -- Override start method
  m._start = m.start
  function m:start(entity)
    local x, y = entity:get_xy()
    -- return entity to starting position
    function self:on_finished()
      entity:set_xy(x, y)
    end
    self:_start(entity)
  end

  return m
end


-- Create a movement for a certain distance across the X or Y axis.
-- Usage: local m = translate("x", 100) -- move 100px to the right
--        local m = translate("y", -50) -- move 50px up
function translate(axis, distance)
  local m = sol.movement.create("straight")
  if axis == "x" and distance >= 0 then
    m:set_angle(0) -- east (increasing x)
  elseif axis == "x" and distance < 0 then
    m:set_angle(math.pi) -- west (decreasing x)
  elseif axis == "y" and distance < 0 then
    m:set_angle(math.pi / 2) -- north (decreasing y)
  elseif axis == "y" and distance >= 0 then
    m:set_angle(3 * math.pi / 2) -- south (increasing y)
  end

  -- Extend m:start()
  m._start = m.start
  function m:start(entity, cb)
    function self:on_position_changed()
      local x, y = self:get_xy()
      if not cb then cb = function() end end
      -- east
      if self:get_direction4() == 0 and x >= distance then
        self:stop()
        entity:set_xy(distance, y)
        cb()
      -- west
      elseif self:get_direction4() == 2 and x <= distance then
        self:stop()
        entity:set_xy(distance, y)
        cb()
      -- north
      elseif self:get_direction4() == 1 and y <= distance then
        self:stop()
        entity:set_xy(x, distance)
        cb()
      -- south
      elseif self:get_direction4() == 3 and y >= distance  then
        self:stop()
        entity:set_xy(x, distance)
        cb()
      end
    end
    self:_start(entity)
  end

  return m
end


-- Takes a direction4 and returns its reflection
-- eg 0 (east) becomes 2 (west)
function invert_d4(direction4)
  return (direction4 + 2) % 4
end


-- Takes a direction4 and returns an angle
-- for use with straight_movement:set_angle()
function d4_to_angle(direction4)
  assert(type(direction4) == "number", "direction4 must be a number.")
  assert(direction4 >=0 and direction4 <=3, "direction4 must be between 0 and 3.")
  if direction4 == 0 then return 0               end -- east
  if direction4 == 1 then return math.pi / 2     end -- north
  if direction4 == 2 then return math.pi         end -- west
  if direction4 == 3 then return 3 * math.pi / 2 end -- south
  return nil
end


-- Manually advance a sprite's animation
-- https://gitlab.com/solarus-games/solarus/issues/1348
function force_animation(sprite, loop)
  local timer = sol.timer.start(sprite:get_frame_delay(), function()
    local next_frame = sprite:get_frame() + 1
    if next_frame >= sprite:get_num_frames() then
      if loop then
        sprite:set_frame(0)
        return true
      end
      if sprite.on_animation_finished then
        sprite:on_animation_finished()
      end
      return false
    end
    sprite:set_frame(next_frame)
    return true
  end)
  timer:set_suspended_with_map(false)
end

-- Disable all entities passed in an array
-- WARNING: If you write directly the array, mistyped entities will be silently ignored
function disableAll(entities)
  for entity in list_iter(entities) do
    entity:set_enabled(false)
  end
end

-- Enable all entities passed in an array
-- WARNING: If you write directly the array, mistyped entities will be silently ignored
function enableAll(entities)
  for entity in list_iter(entities) do
    entity:set_enabled()
  end
end
