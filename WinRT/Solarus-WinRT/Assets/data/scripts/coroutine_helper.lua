-- @author std::gregwar
--
-- This script allows to run your code in a co-routine, to write code with less callbacks.
-- The passed function is run in a special environment that expose various helpers.
--
-- Usage:
--
-- require() the script, this add map:start_coroutine sol.main.start_coroutine and sol.menu.start_coroutne helpers
--
-- Example:
--
-- --In a map script file
--
-- -- somewhere
--   map:start_coroutine(function()
--     dialog("sample_dialog") --display a dialog, waiting for it to finish
--     wait(100) -- wait some time
--     local mov = sol.movement.create(...) --create a movement like anywhere else
--     movement(mov,a_movable) -- execute the movement and wait for it to finish
--     animation(a_sprite,"anim_name") -- play an animation and wait for it to finish
--    end)
--
-- -- control flow
-- -- the main advantage of this is to be able to use if,else,for,while during the cinematics
--
-- Example:
--   map:start_coroutine(function()
--    local response = dialog("dialog_with_yes_no_answer")
--    if response then --
--      dialog("dialog for yes")
--    else
--      dialog("dialog for no")
--    end
--   end)
-- ---------
--  Helpers
-- ---------
--
-- wait(time)                         -- suspend execution of the cinematic for time [ms]
-- dialog(dialog_id,[info])           -- display the dialog (with optional info) and resume exec when it finishes, only available if game context is passed or deduced
-- movement(a_movement,a_movable)     -- start the given movement on the given movable, resume execution when movement finishes
-- animation(a_sprite,animation_id)   -- play the animation on the given sprite and wait for it to finish
-- run_on_main(a_function)            -- run a given closure on the main thread
-- wait_for(method,object,args...)    -- wait for a method or function that accept a callback as last argument (that you must ommit, the helper adds it for you)
-- return                             -- at any time, returning from the function will end the cutscene
--
-- note that code inside the function is not restrained to those helpers,
-- any valid code still works, those helper are just here to offer blocking primitives
--
-- -----------
--  Launchers
-- -----------
-- sol.main.start_coroutine(func,[game]) --start coroutine with main as timer context, pass game to be able to use dialog
--
-- sol.menu.start_coroutine(menu,func,[game]) --start coroutine with menu as context, pass game to be able to use dialog
--
-- map:start_coroutine(func) --start coroutine with map as context
--
--
-- handle.abort() -- abort the cutscene from outside the special function (aborting from the inside is just 'return')
--
-- --------------------------------------------------------------------------------------

local ok, multi_event = pcall(require,"scripts/multi_events")
if not ok then
  print("Warning multi-events script not found, coroutine_helper will lack auto-abort")
  multi_event = nil
end

local co_cut = {}
local coroutine = coroutine

-- start the cutscene env, game can be nil
function co_cut.start(timer_context,game,func,env_index)
  local thread = coroutine.create(func)

  local aborted = false

  local function resume_thread(...)
    assert(coroutine.status(thread) == 'suspended', "Resuming a unsuspended coroutine")
    local status, err = coroutine.resume(thread,...)
    if not status then
      error(err) --forward errors
    end
  end

  local function yield()
    local ress = {coroutine.yield()}
    if aborted then
      coroutine.yield() --final yield, never shall we return
    end
    return unpack(ress)
  end

  local function assert_coroutine()
    local status = coroutine.status(thread)
    if status ~= "running"  then
      error(
        string.format(
          "Coroutine helper isn't called from a coroutine (status : %s)...\
            did you forget to use 'wait_for' to wait on a callback?",
          status
        )
      )
    end
  end

  local current_timer

  local cells = {}
  --suspend cinematic execution for a while
  function cells.wait(time)
    assert_coroutine()
    current_timer = sol.timer.start(timer_context,time,resume_thread)
    current_timer:set_suspended_with_map(false)
    -- resume normal engine execution
    yield()
    current_timer = nil
  end

  function cells.suspendable_wait(time)
    assert_coroutine()
    current_timer = sol.timer.start(timer_context,time,resume_thread)
    yield()
    current_timer = nil
  end

  function cells.run_on_main(func)
    assert_coroutine()
    sol.timer.start(sol.main,0,function()
                      func()
                      resume_thread()
    end)
    return yield()
  end

  if game then --enable dialog only if game available
    function cells.dialog(id,info)
      assert_coroutine()
      if info then
        game:start_dialog(id,info,resume_thread)
      else
        game:start_dialog(id,resume_thread)
      end
      return yield()
    end
  else
    function cells.dialog()
      error("Dialog can only be used if a game context is passed or deduced")
    end
  end

  function cells.movement(movement,entity)
    assert_coroutine()
    movement:start(entity,resume_thread)
    return yield()
  end

  function cells.animation(sprite,anim_name)
    assert_coroutine()
    sprite:set_animation(anim_name,resume_thread)
    return yield()
  end

  --run and wait a function that takes args and then a callback
  function cells.wait_for(method,...)
    assert_coroutine()
    local args = {...}
    local n = select('#',...)
    args[n+1] = resume_thread
    method(unpack(args, 1, n+1))
    return yield()
  end

  local function abort()
   aborted = true --mark coroutine as dead to prevent further execution
   if current_timer then
     current_timer:stop()
   end

  end

  --inherit global scope
  setmetatable(cells,{__index=getfenv((env_index or 1) + 1)}) --get the env of calling function
  setfenv(func,cells) --
  resume_thread() -- launch coroutine to start executing it's content
  return {abort=abort} --return a handle that you can use to abort the coroutine
end

--add map method
local map_meta = sol.main.get_metatable("map")

function map_meta:start_coroutine(func)
  local handle = co_cut.start(self,self:get_game(),func,2)
  if multi_event then
    self:register_event("on_finished",handle.abort) --auto abort
  end
  return handle
end

--add main function
function sol.main.start_coroutine(func,game)
  return co_cut.start(sol.main,game,func,2)
end

--add menu function
function sol.menu.start_coroutine(menu,func,game)
  local handle = co_cut.start(menu,game,func,2)
  if multi_event then
    multi_event:enable(menu)
    menu:register_event("on_finished",handle.abort)
  end
  return handle
end

return co_cut
