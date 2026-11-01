-- Rex config: floating tools with persistent toggle, smart splits.

-- Call a terminal block method on the focused block; nil when it fails.
local function terminal(method, args)
	local ok, res = pcall(rex.block.call, "com.superlogical.terminal", method, args)
	if ok and type(res) == "table" then
		return res
	end
end

-- Working directory of a pane: nvim's real cwd when nvim is in front (it
-- follows :cd/:lcd/:tcd), else the shell's reported directory.
local function focused_cwd(block_id)
	local proc = terminal("process", block_id and { block_id = block_id })
	local fg = proc and proc.foreground
	if fg and type(fg.cwd) == "string" and fg.name and fg.name:lower():match("^n?vim") then
		return fg.cwd
	end
	local res = terminal("pwd")
	if res and type(res.pwd) == "string" then
		return (res.pwd:gsub("^file://[^/]*", ""))
	end
end

-- Whether `dir` is inside a git work tree.
local function is_git_repo(dir)
	if not dir then
		return false
	end
	local ok, res = pcall(rex.exec, { "git", "-C", dir, "rev-parse", "--show-toplevel" })
	return ok and type(res) == "table" and res.ok == true
end

-- macOS notification; the text is an argv entry, so nothing needs escaping.
local function notify(text)
	pcall(rex.exec, {
		"osascript",
		"-e",
		"on run argv",
		"-e",
		'display notification (item 1 of argv) with title "Rex"',
		"-e",
		"end run",
		text,
	})
end

local function session_view(sid)
	local ok, view = pcall(rex.session.view, { session_id = sid })
	if ok and type(view) == "table" then
		return view
	end
end

-- The focused block of the session's active window.
local function active_block(sid)
	local view = session_view(sid)
	for _, win in ipairs(view and view.windows or {}) do
		if win.window_id == view.active_window_id then
			return win.focused_block_id
		end
	end
end

-- Find a block by label: returns its layer and ID when shown, nil layer and
-- ID when detached (hidden).
local function find_block(sid, label)
	local view = session_view(sid)
	for _, win in ipairs(view and view.windows or {}) do
		for _, layer in ipairs(win.layers) do
			for _, blk in ipairs(layer.blocks) do
				if blk.label == label then
					return layer, blk.block_id
				end
			end
		end
	end
	local ok, list = pcall(rex.session.list_blocks, { session_id = sid })
	for _, blk in ipairs(ok and list.blocks or {}) do
		if blk.label == label then
			return nil, blk.block_id
		end
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

-- Toggle a floating tool: hide/show the same block, so its program keeps
-- running and its state (scrollback, selection, cluster connection) survives.
local function toggle(ctx, tool)
	local sid = ctx.session_id
	local layer, block_id = find_block(sid, tool.label)
	if layer then
		if layer.kind ~= "tiled" then
			return rex.session.detach_block({ session_id = sid, block_id = block_id })
		end
		return rex.session.float_block({ session_id = sid, block_id = block_id, bounds = tool.bounds })
	end
	if block_id then
		local anchor = ctx.block_id or active_block(sid)
		local rect = block_rect(session_view(sid), anchor)
		local cols, rows = window_cells(anchor, rect)
		rex.session.move_block({ session_id = sid, block_id = block_id, anchor_block_id = anchor })
		rex.session.float_block({ session_id = sid, block_id = block_id, bounds = tool.bounds })
		-- float_block keeps the size the block had in the split, so set the size
		-- the layer is about to give it.
		if cols and rows then
			terminal("resize", {
				block_id = block_id,
				columns = math.floor(cols * tool.bounds[3] + 0.5),
				rows = math.floor(rows * tool.bounds[4] + 0.5),
			})
		end
		return rex.session.focus_block({ session_id = sid, block_id = block_id })
	end
	local cwd = focused_cwd(ctx.block_id)
	if tool.git and not is_git_repo(cwd) then
		return notify("Not a git repository: " .. (cwd or "unknown directory"))
	end
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

rex.action({
	name = "toggle_lazygit",
	title = "Toggle lazygit",
	run = function(ctx)
		return toggle(ctx, {
			label = "lazygit",
			command = { "lazygit" },
			bounds = { 0.12, 0.08, 0.76, 0.84 },
			git = true,
		})
	end,
})
rex.bind("ctrl+space>l", "toggle_lazygit")

rex.action({
	name = "toggle_k9s",
	title = "Toggle k9s",
	run = function(ctx)
		return toggle(ctx, {
			label = "k9s",
			command = { "k9s" },
			bounds = { 0.05, 0.05, 0.90, 0.90 },
		})
	end,
})
rex.bind("ctrl+space>k", "toggle_k9s")

-- Scratch terminal: a fresh shell each time; toggling kills it, so nothing
-- lingers. Never detached, so the block is found by label in its layer.
rex.action({
	name = "toggle_scratch",
	title = "Toggle scratch terminal",
	run = function(ctx)
		local sid = ctx.session_id
		local _, block_id = find_block(sid, "scratch")
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
					options = { cwd = focused_cwd(ctx.block_id) },
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
