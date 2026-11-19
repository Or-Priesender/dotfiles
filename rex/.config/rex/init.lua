-- Rex config, ported from ~/.config/tmux/tmux.conf.
-- tmux windows map to Rex sessions. Reload with: rex config reload

local TERMINAL = "com.superlogical.terminal"
local SHELL = "com.superlogical.terminal.shell"
local HOME = os.getenv("HOME")
local CONFIG_DIR = HOME .. "/.config/rex"

local function foreground_name(block_id)
  if not block_id then return nil end
  local p = rex.block.call(TERMINAL, "process", { block_id = block_id })
  return p and p.foreground and p.foreground.name
end

local function pwd(block_id)
  local r = block_id and rex.block.call(TERMINAL, "pwd", { block_id = block_id })
  return (r and r.pwd) or HOME
end

-- Last-session tracking for prefix+; (Rex has no built-in "last session" and
-- no event for "the app changed session"). observe() runs in the actions and
-- bindings below, so a switch made with the mouse or cmd+k is seen at the next
-- key press. State is in a file, so a config reload keeps it.
local STATE_FILE = CONFIG_DIR .. "/.session-state"
local state = {}
do
  local f = io.open(STATE_FILE)
  if f then
    state.cur, state.last = f:read("*l"), f:read("*l")
    f:close()
  end
end

local function save_state()
  local f = io.open(STATE_FILE, "w")
  if f then
    f:write((state.cur or ""), "\n", (state.last or ""), "\n")
    f:close()
  end
end

local function observe(ctx)
  local s = ctx.session_id
  if s and s ~= state.cur then
    if state.cur and state.cur ~= "" then state.last = state.cur end
    state.cur = s
    save_state()
  end
end

local function switch_to(ctx, session_id)
  observe(ctx)
  if session_id and session_id ~= ctx.session_id then
    state.last, state.cur = ctx.session_id, session_id
    save_state()
    rex.client.queue("session.select", { session_id = session_id })
  end
end

---------------------------------------------------------------------------
-- Prefix
---------------------------------------------------------------------------
rex.bind("ctrl+b>ctrl+b", "pane.send_key", { key = "ctrl+b" })
rex.bind("ctrl+b>r", "client.config.reload")

---------------------------------------------------------------------------
-- Panes
---------------------------------------------------------------------------
for key, dir in pairs({ h = "left", j = "down", k = "up", l = "right" }) do
  rex.bind("ctrl+b>" .. key, "pane.focus", { direction = dir })
end
for _, dir in ipairs({ "left", "right", "up", "down" }) do
  rex.bind("alt+" .. dir, "pane.focus", { direction = dir })
end

rex.bind("ctrl+b>-", "pane.split", { direction = "down" })
rex.bind("ctrl+b>shift+\\", "pane.split", { direction = "right" })
rex.bind("ctrl+b>z", "pane.zoom")
-- prefix+x: like tmux kill-pane. Closing a tab's last pane already closes the
-- tab, but the session's last pane leaves an empty session, so close that too.
rex.action{
  name = "close_pane_cascade",
  title = "Close Pane (and Empty Tab or Session)",
  run = function(ctx)
    local r = rex.session.list_blocks{}
    local placed = 0
    for _, b in ipairs((r and r.blocks) or {}) do
      if b.placement == "placed" then placed = placed + 1 end
    end
    rex.client.queue(placed <= 1 and "session.close" or "pane.close")
  end,
}
rex.bind("ctrl+b>x", "close_pane_cascade")

-- vim-tmux-navigator: ctrl+hjkl goes to (n)vim/fzf when it runs in the pane,
-- otherwise it moves pane focus. nvimk does the reverse at its window edge.
local vim_names = { vim = true, nvim = true, view = true, vimdiff = true, nvimdiff = true,
  lvim = true, fzf = true }
-- fzf inside a script (pick.sh) shows as "bash", so picker panes get this label.
local PASSTHROUGH_LABEL = "keys-passthrough"

local function block_label(block_id)
  local r = block_id and rex.session.list_blocks{}
  for _, b in ipairs((r and r.blocks) or {}) do
    if b.block_id == block_id then return b.label end
  end
end

for key, dir in pairs({ h = "left", j = "down", k = "up", l = "right" }) do
  rex.bind("ctrl+" .. key, function(ctx)
    observe(ctx)
    if vim_names[foreground_name(ctx.block_id) or ""] then return false end
    if block_label(ctx.block_id) == PASSTHROUGH_LABEL then return false end
    rex.session.focus_direction({ direction = dir })
    return true
  end)
end

-- Resize: prefix+H/J/K/L resizes once and enters a repeat mode, where
-- h/j/k/l (with or without shift) keep resizing. Escape or Enter leaves it.
rex.action{
  name = "resize_repeat",
  title = "Resize Pane (repeat)",
  args = { direction = "string" },
  run = function(ctx, args)
    rex.client.queue("pane.resize", { direction = args.direction, amount = 5 })
    rex.client.queue("client.mode.enter", { name = "resize" })
  end,
}
rex.mode("resize", { exclusive = true })
for key, dir in pairs({ h = "left", j = "down", k = "up", l = "right" }) do
  rex.bind("ctrl+b>shift+" .. key, "resize_repeat", { direction = dir })
  rex.bind("resize/" .. key, "pane.resize", { direction = dir, amount = 5 })
  rex.bind("resize/shift+" .. key, "pane.resize", { direction = dir, amount = 5 })
end
rex.bind("resize/enter", "client.mode.exit")

---------------------------------------------------------------------------
-- Sessions (tmux windows)
---------------------------------------------------------------------------
rex.action{
  name = "session_step",
  title = "Next or Previous Session",
  args = { direction = "string" },
  run = function(ctx, args)
    observe(ctx)
    state.last, state.cur = ctx.session_id, nil
    save_state()
    rex.client.queue(args.direction == "next" and "session.next" or "session.previous")
  end,
}
rex.bind("alt+h", "session_step", { direction = "previous" })
rex.bind("alt+l", "session_step", { direction = "next" })

rex.action{
  name = "last_session",
  title = "Go to Last Session",
  run = function(ctx)
    observe(ctx)
    local r = rex.call("session.list", {})
    local target, other
    for _, s in ipairs((r and r.sessions) or {}) do
      if s.session_id ~= ctx.session_id then
        other = other or s.session_id
        if s.session_id == state.last then target = s.session_id end
      end
    end
    switch_to(ctx, target or other)
  end,
}
rex.bind("ctrl+b>;", "last_session")

-- Called by scripts/pick.sh so prefix+; can return from a picker jump.
rex.action{
  name = "go_to_session",
  title = "Go to Session by ID",
  args = { session_id = "string" },
  run = function(ctx, args) switch_to(ctx, args.session_id) end,
}

rex.action{
  name = "new_session",
  title = "New Session Here",
  args = { cwd = "string?", ask_name = "boolean?" },
  run = function(ctx, args)
    local cwd = args.cwd or pwd(ctx.block_id)
    -- rex.ui.input needs a newer server, so ask for the name in a floating pane.
    if args.ask_name then
      observe(ctx)
      local _, err = rex.session.new_layer{
        bounds = { 0.3, 0.4, 0.4, 0.12 },
        focus = true,
        layout = rex.layout.block{
          flavor = SHELL,
          options = { command = { CONFIG_DIR .. "/scripts/new-session.sh", ctx.client_id or "", cwd } },
        },
      }
      if err then error(err, 0) end
      return
    end
    local r, err = rex.call("session.create", {
      initial_windows = { {
        layout = rex.layout.block{ flavor = SHELL, options = { cwd = args.cwd or pwd(ctx.block_id) } },
      } },
    })
    if not r then error(err, 0) end
    switch_to(ctx, r.session_id)
  end,
}
rex.bind("ctrl+b>c", "new_session")
rex.bind("ctrl+b>n", "new_session", { cwd = HOME .. "/dev", ask_name = true })

rex.bind("ctrl+b>shift+s", "session.switch")
rex.bind("ctrl+b>w", "pane.view_activity")
rex.bind("ctrl+b>,", "session.rename")
rex.bind("ctrl+b>shift+7", "session.close")

-- fzf picker in a floating pane, with agent status icons per session.
-- prefix+s: open sessions only. prefix+o: open sessions and ~/dev repos.
rex.action{
  name = "pick_session",
  title = "Open Session or Repo…",
  args = { mode = "string?" },
  run = function(ctx, args)
    observe(ctx)
    local _, err = rex.session.new_layer{
      bounds = { 0.1, 0.1, 0.8, 0.8 },
      focus = true,
      layout = rex.layout.block{
        flavor = SHELL,
        label = PASSTHROUGH_LABEL,
        options = { command = { CONFIG_DIR .. "/scripts/pick.sh", ctx.client_id or "", args.mode or "" } },
      },
    }
    if err then error(err, 0) end
  end,
}
rex.bind("ctrl+b>o", "pick_session")
rex.bind("ctrl+b>s", "pick_session", { mode = "sessions" })

---------------------------------------------------------------------------
-- Tools
---------------------------------------------------------------------------
rex.action{
  name = "lazygit",
  title = "Lazygit",
  run = function(ctx)
    local _, err = rex.session.new_layer{
      bounds = { 0.1, 0.1, 0.8, 0.8 },
      focus = true,
      layout = rex.layout.block{
        flavor = SHELL,
        options = { command = { "lazygit" }, cwd = pwd(ctx.block_id) },
      },
    }
    if err then error(err, 0) end
  end,
}
rex.bind("ctrl+b>g", "lazygit")

-- prefix+a: focus the plugin pane in Claude Code (ctrl+x tab), only when Claude
-- runs in the pane. Claude's process name is its version number.
rex.action{
  name = "claude_plugin_pane",
  title = "Claude Code: Focus Plugin Pane",
  run = function(ctx)
    if (foreground_name(ctx.block_id) or ""):match("^[%d%.]+$") then
      rex.client.queue("pane.send_key", { key = "ctrl+x" })
      rex.client.queue("pane.send_key", { key = "tab" })
    end
  end,
}
rex.bind("ctrl+b>a", "claude_plugin_pane")
