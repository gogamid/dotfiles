-- Rex config: floating tools with persistent toggle, smart splits.

-- Call a terminal block method on the focused block; nil when it fails.
local function terminal(method, args)
	local ok, res = pcall(rex.block.call, "com.superlogical.terminal", method, args)
	if ok and type(res) == "table" then
		return res
	end
end

-- Working directory of a pane: the foreground process's real cwd when it
-- reports one (nvim follows :cd/:lcd/:tcd, opencode/lazygit report their
-- launch dir), else the shell's reported directory.
local session_view

local function block_cwd(block_id)
	local proc = terminal("process", block_id and { block_id = block_id })
	local fg = proc and proc.foreground
	if fg and type(fg.cwd) == "string" then
		return fg.cwd
	end
	local res = terminal("pwd", block_id and { block_id = block_id })
	if res and type(res.pwd) == "string" then
		return (res.pwd:gsub("^file://[^/]*", ""))
	end
end

-- The focused block can be a non-terminal float (opencode, lazygit native
-- panes). Fall back to the tiled terminal behind it in the same window, so
-- tools still open in the directory the user is working in.
local function terminal_in_window(view, block_id)
	local target
	for _, win in ipairs(view and view.windows or {}) do
		for _, layer in ipairs(win.layers or {}) do
			for _, blk in ipairs(layer.blocks or {}) do
				if blk.block_id == block_id then
					target = win
				end
			end
		end
	end
	if not target then
		for _, win in ipairs(view and view.windows or {}) do
			if win.window_id == view.active_window_id then
				target = win
			end
		end
	end
	local fallback
	for _, layer in ipairs(target and target.layers or {}) do
		for _, blk in ipairs(layer.blocks or {}) do
			if blk.creator_name == "com.superlogical.terminal" then
				if layer.kind == "tiled" then
					return blk.block_id
				end
				fallback = fallback or blk.block_id
			end
		end
	end
	return fallback
end

local function focused_cwd(block_id, sid)
	local cwd = block_cwd(block_id)
	if cwd then
		return cwd
	end
	local fallback = terminal_in_window(sid and session_view(sid), block_id)
	if fallback then
		return block_cwd(fallback)
	end
end

session_view = function(sid)
	local ok, view = pcall(rex.session.view, { session_id = sid })
	if ok and type(view) == "table" then
		return view
	end
end

-- Rectangle of a block in its window, from the session view.
local function block_rect(view, block_id)
	local walk
	walk = function(node)
		if node.block_id == block_id then
			return node.rect
		end
		local split = node.split
		return split and (walk(split.before) or walk(split.after))
	end
	for _, win in ipairs(view and view.windows or {}) do
		for _, layer in ipairs(win.layers) do
			local rect = walk(layer.layout)
			if rect then
				return rect
			end
		end
	end
end

-- Cells a window has, worked out from one of its blocks.
local function window_cells(block_id, rect)
	local size = terminal("size", { block_id = block_id })
	if size and rect and rect[3] > 0 and rect[4] > 0 then
		return size.columns / rect[3], size.rows / rect[4]
	end
end

-- A block by label in an already fetched view. The layer comes back only while
-- the block is placed in a window.
local function find_block_in(view, label)
	for _, win in ipairs(view and view.windows or {}) do
		for _, layer in ipairs(win.layers or {}) do
			for _, blk in ipairs(layer.blocks or {}) do
				if blk.label == label then
					return layer, blk.block_id
				end
			end
		end
	end
end

local function window_index_of_layer(view, layer_id)
	for index, win in ipairs(view and view.windows or {}) do
		for _, layer in ipairs(win.layers or {}) do
			if layer.layer_id == layer_id then
				return index
			end
		end
	end
end

-- Toggle a floating tool; the block and its program always survive. By default
-- the float is detached (no capsule). `native = true` uses the client's layer
-- state instead: minimize hides it into the taskbar, normal restores it, and
-- the client animates both.
local function toggle(ctx, tool)
	local sid = ctx.session_id
	local view = session_view(sid)
	local layer, block_id = find_block_in(view, tool.label)
	if not block_id then
		-- A block an older toggle detached: list_blocks still reports it.
		local ok, list = pcall(rex.session.list_blocks, { session_id = sid })
		for _, blk in ipairs(ok and list and list.blocks or {}) do
			if blk.label == tool.label then
				block_id = blk.block_id
				break
			end
		end
	end

	if layer and layer.kind ~= "tiled" then
		if not tool.native then
			return rex.session.detach_block({ session_id = sid, block_id = block_id })
		end
		if layer.state ~= "minimized" then
			return rex.session.set_layer_state({ session_id = sid, layer_id = layer.layer_id, state = "minimized" })
		end
		rex.session.set_layer_state({ session_id = sid, layer_id = layer.layer_id, state = "normal", focus = true })
		-- Tabs belong to the app: focus alone does not reveal another tab.
		local index = window_index_of_layer(view, layer.layer_id)
		local active
		for i, win in ipairs(view.windows or {}) do
			if win.window_id == view.active_window_id then
				active = i
			end
		end
		if index and index ~= active then
			return rex.client.queue("client.tab.goto", { index = index })
		end
		return
	end

	if block_id and tool.follow_cwd then
		-- Re-showing a hidden float: keep it only if it still matches the
		-- current pane's directory. Otherwise close it and start fresh there.
		local want = focused_cwd(ctx.block_id, sid)
		local have = block_cwd(block_id)
		if want and have and want ~= have then
			rex.call("block.close", { session_id = sid, block_id = block_id })
			block_id = nil
		end
	end

	if block_id then
		-- Detached or tiled (split by the user): place it beside the focused
		-- pane, then float it. float_block keeps the split's size, so resize.
		local anchor = ctx.block_id
		if not anchor then
			for _, win in ipairs(view.windows or {}) do
				if win.window_id == view.active_window_id then
					anchor = win.focused_block_id
				end
			end
		end
		local rect = block_rect(view, anchor)
		local cols, rows = window_cells(anchor, rect)
		rex.session.move_block({ session_id = sid, block_id = block_id, anchor_block_id = anchor })
		rex.session.float_block({ session_id = sid, block_id = block_id, bounds = tool.bounds })
		if cols and rows then
			terminal("resize", {
				block_id = block_id,
				columns = math.floor(cols * tool.bounds[3] + 0.5),
				rows = math.floor(rows * tool.bounds[4] + 0.5),
			})
		end
		return rex.session.focus_block({ session_id = sid, block_id = block_id })
	end

	local cwd = focused_cwd(ctx.block_id, sid)
	return rex.session.new_layer({
		session_id = sid,
		bounds = tool.bounds,
		focus = true,
		layout = {
			block = {
				flavor = "com.superlogical.terminal.shell",
				label = tool.label,
				options = { command = tool.command, cwd = cwd },
			},
		},
	})
end

-- Plain lazygit float, no Neovim/LazyRex integration: the float is created
-- once in the focused pane's directory and detached between toggles.
rex.action({
	name = "toggle_lazygit",
	title = "Toggle lazygit",
	run = function(ctx)
		return toggle(ctx, {
			label = "lazygit",
			command = { "lazygit" },
			bounds = { 0.12, 0.08, 0.76, 0.84 },
			follow_cwd = true,
		})
	end,
})
rex.bind("cmd+l", "toggle_lazygit")

rex.action({
	name = "toggle_opencode",
	title = "Toggle opencode",
	run = function(ctx)
		return toggle(ctx, {
			label = "ai",
			command = { "opencode" },
			bounds = { 0.25, 0.06, 0.50, 0.88 },
			native = true,
		})
	end,
})
rex.bind("ctrl+.", "toggle_opencode")

-- Scrollback paging (client actions, Rex 1829 preview). Plain Page Up/Down stay
-- with the program; Shift walks the terminal history instead.
rex.bind("shift+pageup", "client.scroll.page_up")
rex.bind("shift+pagedown", "client.scroll.page_down")
rex.bind("ctrl+space>n", "pane.new_floating")

-- Scratch terminal: a fresh shell each time; toggling kills it, so nothing
-- lingers. Never detached, so the block is found by label in its layer.
rex.action({
	name = "toggle_scratch",
	title = "Toggle scratch terminal",
	run = function(ctx)
		local sid = ctx.session_id
		local _, block_id = find_block_in(session_view(sid), "scratch")
		if block_id then
			return rex.call("block.close", { session_id = sid, block_id = block_id })
		end
		return rex.session.new_layer({
			session_id = sid,
			bounds = { 0.08, 0.06, 0.84, 0.88 },
			focus = true,
			layout = {
				block = {
					flavor = "com.superlogical.terminal.shell",
					label = "scratch",
					options = { cwd = focused_cwd(ctx.block_id, sid) },
				},
			},
		})
	end,
})
rex.bind("ctrl+space>s", "toggle_scratch")

-- alt+tab flips between the first two tabs; any other tab goes back to tab 1.
-- The app owns which tab is shown, so ask it with client.tab.goto instead of
-- only changing the server's active_window_id.
rex.action({
	name = "toggle_tab_1_2",
	title = "Toggle Tab 1/2",
	run = function(ctx)
		local view = session_view(ctx.session_id)
		local wins = view and view.windows or {}
		if #wins < 2 then
			return
		end
		local index = view.active_window_id == wins[1].window_id and 2 or 1
		return rex.client.queue("client.tab.goto", { index = index })
	end,
})

rex.bind("alt+tab", "toggle_tab_1_2")

-- ctrl+space>1..9 jumps straight to that tab, in tab order.
rex.action({
	name = "goto_tab",
	title = "Go to Tab",
	args = {
		type = "object",
		required = { "index" },
		properties = {
			index = { type = "integer", minimum = 1 },
		},
	},
	run = function(ctx, args)
		local view = session_view(ctx.session_id)
		local wins = view and view.windows or {}
		if not args or args.index > #wins then
			return
		end
		return rex.client.queue("client.tab.goto", { index = args.index })
	end,
})

for i = 1, 9 do
	rex.bind("ctrl+space>" .. i, "goto_tab", { index = i })
end

-- Smart splits: ctrl+KEY moves focus between blocks. When nvim has focus,
-- return false so the key reaches nvim, where smart-splits calls back at the
-- edge.
local function focused_process_name(ctx)
	local proc = ctx.block_id and terminal("process", { block_id = ctx.block_id })
	if not proc then
		return nil, false
	end
	local fg = proc.foreground
	return fg and (fg.name or (fg.path and fg.path:match("([^/]+)$"))), true
end

local function is_nvim(name)
	return name ~= nil and name:lower():match("^n?vim") ~= nil
end

local function focus_block(direction)
	return function(ctx)
		local name, known = focused_process_name(ctx)
		if not known or is_nvim(name) then
			return false
		end
		local _, err = rex.session.focus_direction({ direction = direction, wrap = true })
		return err == nil
	end
end

for _, pair in ipairs({ { "h", "left" }, { "j", "down" }, { "k", "up" }, { "l", "right" } }) do
	local key, direction = pair[1], pair[2]
	rex.bind("ctrl+" .. key, focus_block(direction))
	rex.bind("ctrl+alt+" .. key, "pane.resize", { direction = direction, amount = 3 })
end
