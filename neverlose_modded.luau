--[[	

	|	NEVERLOSE MODDED  UI	|
		By: .gg/rapptezetyee 	
------------------------------------------------------------------------------------------
		original Neverlose		
		[https://neverlose.cc/] - csgo cheat
]]

local LocalPlayer = game:GetService('Players').LocalPlayer;
local Mouse = LocalPlayer:GetMouse();
local InputService = game:GetService('UserInputService');
local TextService = game:GetService('TextService');
local TweenService = game:GetService('TweenService');
local CoreGui = game:FindFirstChild('CoreGui') or LocalPlayer.PlayerGui;

local ProtectGui = protectgui or (syn and syn.protect_gui) or (function() end);

local ExtTheme = setmetatable({}, {
	__index = function(_, key)
		local map = {
			Background = "BlackgroundColor",
			Surface = "SectionColor",
			Hover = "ButtonBlackgroundColor",
			Stroke = "StrokeColor",
			Accent = "MainColor",
			Text = "TextColor",
		}
		local name = map[key]
		if name and NEVERLOSE.Themes then
			local c = NEVERLOSE.Themes[name]
			if typeof(c) == "Color3" then return c end
		end
		local fb = {
			Background = Color3.fromRGB(20, 20, 22),
			Surface = Color3.fromRGB(30, 30, 33),
			Hover = Color3.fromRGB(40, 40, 44),
			Stroke = Color3.fromRGB(52, 52, 58),
			Accent = Color3.fromRGB(64, 140, 255),
			Text = Color3.fromRGB(225, 225, 228),
			Muted = Color3.fromRGB(180, 180, 195),
		}
		return fb[key] or Color3.new(1, 1, 1)
	end,
})

local FAST = TweenInfo.new(0.16, Enum.EasingStyle.Quad, Enum.EasingDirection.Out)

local function extFont(weight)
	weight = weight or Enum.FontWeight.Regular
	if weight == Enum.FontWeight.Bold then return Enum.Font.SourceSansBold end
	if weight == Enum.FontWeight.SemiBold or weight == Enum.FontWeight.Medium then return Enum.Font.SourceSansSemibold end
	return Enum.Font.SourceSans
end

local function extNew(class, props, parent)
	local obj = Instance.new(class)
	for k, v in pairs(props) do obj[k] = v end
	obj.Parent = parent
	return obj
end

local function extCorner(parent, scale, offset)
	return extNew("UICorner", { CornerRadius = UDim.new(scale or 0, offset or 0) }, parent)
end

local function extStroke(parent, color, thickness)
	return extNew("UIStroke", {
		Color = color or ExtTheme.Stroke,
		Thickness = thickness or 1,
		ApplyStrokeMode = Enum.ApplyStrokeMode.Border,
	}, parent)
end

local function extTween(obj, props, info)
	TweenService:Create(obj, info or FAST, props):Play()
end

local function extSafe(fn, ...)
	if not fn then return end
	local ok, err = pcall(fn, ...)
	if not ok then warn("[NeverLose-Mod] " .. tostring(err)) end
end

local function extIsPress(input)
	return input.UserInputType == Enum.UserInputType.MouseButton1
		or input.UserInputType == Enum.UserInputType.Touch
end

local function extIsMove(input)
	return input.UserInputType == Enum.UserInputType.MouseMovement
		or input.UserInputType == Enum.UserInputType.Touch
end

local ExtOrderCache = setmetatable({}, { __mode = "k" })
local function extNextOrder(frame)
	local order = ExtOrderCache[frame]
	if not order then
		order = 0
		for _, child in ipairs(frame:GetChildren()) do
			if child:IsA("GuiObject") then
				order = math.max(order, child.LayoutOrder)
			end
		end
	end
	order += 1
	ExtOrderCache[frame] = order
	return order
end

local function extCreateRow(section, height, auto)
	local row = extNew("Frame", {
		Name = "ExtRow",
		BackgroundColor3 = ExtTheme.Hover,
		BackgroundTransparency = 1,
		BorderSizePixel = 0,
		ClipsDescendants = not auto,
		Size = UDim2.new(0.9, 0, 0, height),
		LayoutOrder = extNextOrder(section),
	}, section)
	if auto then row.AutomaticSize = Enum.AutomaticSize.Y end
	extCorner(row, 0, 4)
	return row
end

local function extBinder(row)
	local conns = {}
	row.Destroying:Connect(function()
		for _, c in ipairs(conns) do c:Disconnect() end
		table.clear(conns)
	end)
	return function(signal, fn)
		local c = signal:Connect(fn)
		conns[#conns + 1] = c
		return c
	end
end

local function extHover(row, on)
	on(row.MouseEnter, function() extTween(row, { BackgroundTransparency = 0.7 }) end)
	on(row.MouseLeave, function() extTween(row, { BackgroundTransparency = 1 }) end)
end

local function extTitle(row, text, rightOffset)
	return extNew("TextLabel", {
		Name = "Title",
		Text = text or "",
		Font = extFont(Enum.FontWeight.Medium),
		TextSize = 12,
		TextColor3 = ExtTheme.Text,
		TextXAlignment = Enum.TextXAlignment.Left,
		TextTruncate = Enum.TextTruncate.AtEnd,
		BackgroundTransparency = 1,
		Position = UDim2.new(0, 10, 0, 0),
		Size = UDim2.new(1, -(rightOffset or 20), 0, 30),
	}, row)
end

local function extFinish(row, api)
	api.Container = row
	api.SetVisible = function(_, v) row.Visible = v ~= false end
	api.SetTitle = function(_, t)
		local title = row:FindFirstChild("Title")
		if title then title.Text = tostring(t) end
	end
	api.Text = api.SetTitle
	api.Status = api.SetVisible
	if api.Set then
		api.Value = function(_, v) return api.Set(api, v, true) end
	end
	api.Destroy = function() row:Destroy() end
	return api
end

local function extResolveKey(value)
	if typeof(value) == "EnumItem" and value.EnumType == Enum.KeyCode then return value end
	if type(value) == "string" then
		local ok, r = pcall(function() return Enum.KeyCode[value] end)
		if ok and r then return r end
	end
	return Enum.KeyCode.Unknown
end

local function extCreateToggle(section, name, default, callback)
	local row = extCreateRow(section, 30)
	local on = extBinder(row)
	extTitle(row, name, 56)
	local state = default and true or false

	local track = extNew("Frame", {
		AnchorPoint = Vector2.new(1, 0.5),
		Position = UDim2.new(1, -10, 0, 15),
		Size = UDim2.fromOffset(30, 16),
		BackgroundColor3 = ExtTheme.Stroke,
		BorderSizePixel = 0,
	}, row)
	extCorner(track, 1, 0)

	local knob = extNew("Frame", {
		AnchorPoint = Vector2.new(0, 0.5),
		Position = UDim2.new(0, 2, 0.5, 0),
		Size = UDim2.fromOffset(12, 12),
		BackgroundColor3 = ExtTheme.Muted,
		BorderSizePixel = 0,
	}, track)
	extCorner(knob, 1, 0)

	local hit = extNew("TextButton", {
		Text = "", BackgroundTransparency = 1, Size = UDim2.fromScale(1, 1),
	}, row)

	local function render(animate)
		local pos = state and UDim2.new(1, -14, 0.5, 0) or UDim2.new(0, 2, 0.5, 0)
		local tc = state and ExtTheme.Accent or ExtTheme.Stroke
		local kc = state and ExtTheme.Text or ExtTheme.Muted
		if animate then
			extTween(knob, { Position = pos, BackgroundColor3 = kc })
			extTween(track, { BackgroundColor3 = tc })
		else
			knob.Position = pos; knob.BackgroundColor3 = kc; track.BackgroundColor3 = tc
		end
	end

	local function set(value, fire, force)
		local ns = value and true or false
		local changed = ns ~= state
		state = ns
		render(true)
		if (changed or force) and callback then extSafe(callback, state) end
	end

	on(hit.MouseButton1Click, function() set(not state, true) end)
	extHover(row, on)
	render(false)
	if callback then extSafe(callback, state) end

	return extFinish(row, {
		Set = function(_, v, f, force) set(v, f, force) end,
		Get = function() return state end,
	})
end

local function extCreateSlider(section, name, minVal, maxVal, default, decimals, callback, suffix)
	if type(decimals) == "function" then callback = decimals; decimals = 0 end
	minVal = tonumber(minVal) or 0
	maxVal = tonumber(maxVal) or 100
	if maxVal <= minVal then maxVal = minVal + 1 end
	decimals = math.max(0, math.floor(tonumber(decimals) or 0))
	suffix = suffix and tostring(suffix) or ""
	local mult = 10 ^ decimals
	local value = math.clamp(tonumber(default) or minVal, minVal, maxVal)
	local dragging = false

	local row = extCreateRow(section, 42)
	local on = extBinder(row)
	extTitle(row, name, 100)

	local valueLabel = extNew("TextLabel", {
		AnchorPoint = Vector2.new(1, 0),
		Position = UDim2.new(1, -10, 0, 0),
		Size = UDim2.new(0, 90, 0, 30),
		BackgroundTransparency = 1,
		Font = extFont(Enum.FontWeight.Medium),
		TextSize = 11,
		TextColor3 = ExtTheme.Muted,
		TextXAlignment = Enum.TextXAlignment.Right,
		Text = "",
	}, row)

	local track = extNew("Frame", {
		Position = UDim2.new(0, 10, 0, 31),
		Size = UDim2.new(1, -20, 0, 4),
		BackgroundColor3 = ExtTheme.Stroke,
		BorderSizePixel = 0,
	}, row)
	extCorner(track, 1, 0)

	local fill = extNew("Frame", {
		Size = UDim2.fromScale(0, 1),
		BackgroundColor3 = ExtTheme.Accent,
		BorderSizePixel = 0,
	}, track)
	extCorner(fill, 1, 0)

	local knob = extNew("Frame", {
		AnchorPoint = Vector2.new(0.5, 0.5),
		Position = UDim2.fromScale(0, 0.5),
		Size = UDim2.fromOffset(10, 10),
		BackgroundColor3 = ExtTheme.Text,
		BorderSizePixel = 0,
	}, track)
	extCorner(knob, 1, 0)

	local hit = extNew("TextButton", { Text = "", BackgroundTransparency = 1, Size = UDim2.fromScale(1, 1) }, row)

	local function fmt(n)
		if decimals == 0 then return string.format("%d", math.round(n)) .. suffix end
		return string.format("%." .. decimals .. "f", n) .. suffix
	end

	local function render()
		local a = (value - minVal) / (maxVal - minVal)
		fill.Size = UDim2.fromScale(a, 1)
		knob.Position = UDim2.fromScale(a, 0.5)
		valueLabel.Text = fmt(value)
	end

	local function set(nv, fire, force)
		local r = math.clamp(math.round((tonumber(nv) or minVal) * mult) / mult, minVal, maxVal)
		local changed = r ~= value
		value = r
		render()
		if fire and (changed or force) and callback then extSafe(callback, value) end
	end

	local function sample(x)
		local size = track.AbsoluteSize.X
		if size <= 0 then return end
		local a = math.clamp((x - track.AbsolutePosition.X) / size, 0, 1)
		set(minVal + a * (maxVal - minVal), true)
	end

	on(hit.InputBegan, function(i) if extIsPress(i) then dragging = true; sample(i.Position.X) end end)
	on(UserInputService.InputChanged, function(i) if dragging and extIsMove(i) then sample(i.Position.X) end end)
	on(UserInputService.InputEnded, function(i) if extIsPress(i) then dragging = false end end)
	extHover(row, on)
	render()

	return extFinish(row, {
		Set = function(_, v, f, force) set(v, f, force) end,
		Get = function() return value end,
	})
end

local function extCreateButton(section, name, callback)
	local row = extCreateRow(section, 30)
	local on = extBinder(row)

	local button = extNew("TextButton", {
		Text = name or "Button",
		AutoButtonColor = false,
		BackgroundColor3 = ExtTheme.Surface,
		BorderSizePixel = 0,
		Size = UDim2.fromScale(1, 1),
		Font = extFont(Enum.FontWeight.Medium),
		TextSize = 12,
		TextColor3 = ExtTheme.Text,
	}, row)
	extCorner(button, 0, 4)
	extStroke(button)

	on(button.MouseEnter, function() extTween(button, { BackgroundColor3 = ExtTheme.Hover }) end)
	on(button.MouseLeave, function() extTween(button, { BackgroundColor3 = ExtTheme.Surface }) end)
	on(button.MouseButton1Click, function()
		button.BackgroundColor3 = ExtTheme.Accent
		extTween(button, { BackgroundColor3 = ExtTheme.Hover })
		if callback then extSafe(callback) end
	end)

	return extFinish(row, {
		SetText = function(_, t) button.Text = tostring(t) end,
		Fire = function(_, ...) if callback then extSafe(callback, ...) end end,
	})
end

local function extCreateLabel(section, text)
	local row = extCreateRow(section, 0, true)

	local label = extNew("TextLabel", {
		Name = "Title",
		BackgroundTransparency = 1,
		AutomaticSize = Enum.AutomaticSize.Y,
		Size = UDim2.new(1, 0, 0, 0),
		Font = extFont(),
		TextSize = 11,
		TextColor3 = ExtTheme.Muted,
		TextWrapped = true,
		TextXAlignment = Enum.TextXAlignment.Left,
		TextYAlignment = Enum.TextYAlignment.Top,
		Text = tostring(text or ""),
	}, row)
	extNew("UIPadding", {
		PaddingTop = UDim.new(0, 5),
		PaddingBottom = UDim.new(0, 5),
		PaddingLeft = UDim.new(0, 10),
		PaddingRight = UDim.new(0, 10),
	}, label)

	return extFinish(row, {
		SetText = function(_, v) label.Text = tostring(v) end,
		Get = function() return label.Text end,
	})
end

local function extCreateSeparator(section)
	local row = extCreateRow(section, 9)
	extNew("Frame", {
		AnchorPoint = Vector2.new(0, 0.5),
		Position = UDim2.new(0, 10, 0.5, 0),
		Size = UDim2.new(1, -20, 0, 1),
		BackgroundColor3 = ExtTheme.Stroke,
		BorderSizePixel = 0,
	}, row)
	return extFinish(row, {})
end

local function extCreateProgressBar(section, name, minVal, maxVal, default)
	minVal = tonumber(minVal) or 0
	maxVal = tonumber(maxVal) or 100
	if maxVal <= minVal then maxVal = minVal + 1 end
	local value = math.clamp(tonumber(default) or minVal, minVal, maxVal)

	local row = extCreateRow(section, 42)
	local on = extBinder(row)
	extTitle(row, name, 100)

	local valueLabel = extNew("TextLabel", {
		AnchorPoint = Vector2.new(1, 0),
		Position = UDim2.new(1, -10, 0, 0),
		Size = UDim2.new(0, 90, 0, 30),
		BackgroundTransparency = 1,
		Font = extFont(Enum.FontWeight.Medium),
		TextSize = 11,
		TextColor3 = ExtTheme.Muted,
		TextXAlignment = Enum.TextXAlignment.Right,
		Text = "",
	}, row)

	local track = extNew("Frame", {
		Position = UDim2.new(0, 10, 0, 31),
		Size = UDim2.new(1, -20, 0, 4),
		BackgroundColor3 = ExtTheme.Stroke,
		BorderSizePixel = 0,
	}, row)
	extCorner(track, 1, 0)

	local fill = extNew("Frame", {
		Size = UDim2.fromScale(0, 1),
		BackgroundColor3 = ExtTheme.Accent,
		BorderSizePixel = 0,
	}, track)
	extCorner(fill, 1, 0)

	local function render()
		local a = (value - minVal) / (maxVal - minVal)
		fill.Size = UDim2.fromScale(a, 1)
		valueLabel.Text = string.format("%d", math.round(value))
	end

	extHover(row, on)
	render()

	return extFinish(row, {
		Set = function(_, nv) value = math.clamp(tonumber(nv) or value, minVal, maxVal); render() end,
		Get = function() return value end,
	})
end

local function extCreateTextBox(section, name, placeholder, default, callback)
	local row = extCreateRow(section, 30)
	local on = extBinder(row)

	local title = extTitle(row, name)
	title.Size = UDim2.new(0.45, -10, 0, 30)

	local input = extNew("TextBox", {
		AnchorPoint = Vector2.new(1, 0.5),
		Position = UDim2.new(1, -10, 0, 15),
		Size = UDim2.new(0.55, -10, 0, 20),
		BackgroundColor3 = ExtTheme.Surface,
		BorderSizePixel = 0,
		ClearTextOnFocus = false,
		ClipsDescendants = true,
		Font = extFont(),
		TextSize = 11,
		TextColor3 = ExtTheme.Text,
		PlaceholderColor3 = ExtTheme.Muted,
		PlaceholderText = placeholder or "Type here...",
		TextXAlignment = Enum.TextXAlignment.Left,
		TextTruncate = Enum.TextTruncate.AtEnd,
		Text = tostring(default or ""),
	}, row)
	extCorner(input, 0, 4)
	extNew("UIPadding", { PaddingLeft = UDim.new(0, 6), PaddingRight = UDim.new(0, 6) }, input)
	local border = extStroke(input)

	on(input.Focused, function() extTween(border, { Color = ExtTheme.Accent }) end)
	on(input.FocusLost, function(enter)
		extTween(border, { Color = ExtTheme.Stroke })
		if callback then extSafe(callback, input.Text, enter) end
	end)

	extHover(row, on)

	return extFinish(row, {
		Set = function(_, v) input.Text = tostring(v or "") end,
		Get = function() return input.Text end,
	})
end

local function extCreateInput(section, name, default, minVal, maxVal, decimals, callback)
	minVal = tonumber(minVal)
	maxVal = tonumber(maxVal)
	decimals = math.max(0, math.floor(tonumber(decimals) or 0))

	local row = extCreateRow(section, 30)
	local on = extBinder(row)
	local title = extTitle(row, name)
	title.Size = UDim2.new(0.45, -10, 0, 30)

	local input = extNew("TextBox", {
		AnchorPoint = Vector2.new(1, 0.5),
		Position = UDim2.new(1, -10, 0, 15),
		Size = UDim2.new(0.55, -10, 0, 20),
		BackgroundColor3 = ExtTheme.Surface,
		BorderSizePixel = 0,
		ClearTextOnFocus = false,
		ClipsDescendants = true,
		Font = extFont(),
		TextSize = 11,
		TextColor3 = ExtTheme.Text,
		PlaceholderColor3 = ExtTheme.Muted,
		PlaceholderText = "0",
		TextXAlignment = Enum.TextXAlignment.Right,
		Text = tostring(default or 0),
	}, row)
	extCorner(input, 0, 4)
	extNew("UIPadding", { PaddingRight = UDim.new(0, 6) }, input)
	local border = extStroke(input)

	local function clamp(v)
		v = tonumber(v) or minVal or 0
		if minVal and v < minVal then v = minVal end
		if maxVal and v > maxVal then v = maxVal end
		if decimals > 0 then
			local m = 10 ^ decimals
			v = math.round(v * m) / m
		else
			v = math.round(v)
		end
		return v
	end

	on(input.Focused, function() extTween(border, { Color = ExtTheme.Accent }) end)
	on(input.FocusLost, function(enter)
		extTween(border, { Color = ExtTheme.Stroke })
		local v = clamp(input.Text)
		input.Text = tostring(v)
		if callback then extSafe(callback, v, enter) end
	end)

	extHover(row, on)

	return extFinish(row, {
		Set = function(_, v) input.Text = tostring(clamp(v)) end,
		Get = function() return clamp(input.Text) end,
	})
end

local function extCreateToggleKeybind(section, name, defaultToggle, defaultKey, toggleCb, keyCb, changedCb)
	local row = extCreateRow(section, 30)
	local on = extBinder(row)
	extTitle(row, name, 180)

	local state = defaultToggle and true or false
	local key = extResolveKey(defaultKey)
	local listening = false

	local track = extNew("Frame", {
		AnchorPoint = Vector2.new(1, 0.5),
		Position = UDim2.new(1, -10, 0, 15),
		Size = UDim2.fromOffset(30, 16),
		BackgroundColor3 = ExtTheme.Stroke,
		BorderSizePixel = 0,
	}, row)
	extCorner(track, 1, 0)

	local knob = extNew("Frame", {
		AnchorPoint = Vector2.new(0, 0.5),
		Position = UDim2.new(0, 2, 0.5, 0),
		Size = UDim2.fromOffset(12, 12),
		BackgroundColor3 = ExtTheme.Muted,
		BorderSizePixel = 0,
	}, track)
	extCorner(knob, 1, 0)

	local keyBtn = extNew("TextButton", {
		AnchorPoint = Vector2.new(1, 0.5),
		Position = UDim2.new(1, -48, 0, 15),
		Size = UDim2.fromOffset(72, 20),
		BackgroundColor3 = ExtTheme.Surface,
		BorderSizePixel = 0,
		AutoButtonColor = false,
		Font = extFont(Enum.FontWeight.Medium),
		TextSize = 11,
		TextColor3 = ExtTheme.Text,
		Text = "",
	}, row)
	extCorner(keyBtn, 0, 4)
	extStroke(keyBtn)

	local hit = extNew("TextButton", {
		Text = "", BackgroundTransparency = 1,
		Size = UDim2.new(1, -130, 1, 0), Position = UDim2.new(0, 0, 0, 0),
	}, row)

	local function renderToggle(animate)
		local p = state and UDim2.new(1, -14, 0.5, 0) or UDim2.new(0, 2, 0.5, 0)
		local tc = state and ExtTheme.Accent or ExtTheme.Stroke
		local kc = state and ExtTheme.Text or ExtTheme.Muted
		if animate then
			extTween(knob, { Position = p, BackgroundColor3 = kc })
			extTween(track, { BackgroundColor3 = tc })
		else
			knob.Position = p; knob.BackgroundColor3 = kc; track.BackgroundColor3 = tc
		end
	end

	local function renderKey()
		if listening then
			keyBtn.Text = "..."; keyBtn.TextColor3 = ExtTheme.Accent
		else
			keyBtn.Text = key == Enum.KeyCode.Unknown and "None" or key.Name
			keyBtn.TextColor3 = ExtTheme.Text
		end
	end

	local function setToggle(v, fire, force)
		local ns = v and true or false
		local changed = ns ~= state
		state = ns
		renderToggle(true)
		if (changed or force) and toggleCb then extSafe(toggleCb, state) end
	end

	on(hit.MouseButton1Click, function() setToggle(not state, true) end)
	on(keyBtn.MouseButton1Click, function() if not listening then listening = true; renderKey() end end)
	on(UserInputService.InputBegan, function(i, processed)
		if i.UserInputType ~= Enum.UserInputType.Keyboard then return end
		if listening then
			listening = false
			if i.KeyCode ~= Enum.KeyCode.Escape then
				key = i.KeyCode == Enum.KeyCode.Backspace and Enum.KeyCode.Unknown or i.KeyCode
				if changedCb then extSafe(changedCb, key) end
			end
			renderKey()
			return
		end
		if processed or key == Enum.KeyCode.Unknown then return end
		if i.KeyCode == key and keyCb then extSafe(keyCb, key) end
	end)

	extHover(row, on)
	renderToggle(false); renderKey()
	if toggleCb then extSafe(toggleCb, state) end

	return extFinish(row, {
		Set = function(_, v, f, force) setToggle(v, f, force) end,
		Get = function() return state end,
		GetKey = function() return key end,
		SetKey = function(_, v, f)
			key = extResolveKey(v); renderKey()
			if f and changedCb then extSafe(changedCb, key) end
		end,
		IsPressed = function() return key ~= Enum.KeyCode.Unknown and UserInputService:IsKeyDown(key) end,
	})
end

local function extCreateDropdown(section, name, options, default, callback, multi)
	local HEADER, ITEM, MAXV = 30, 22, 6
	options = type(options) == "table" and options or {}
	multi = multi and true or false
	local selected, expanded, items = nil, false, {}

	local function resetSel(v)
		if multi then
			selected = {}
			if type(v) == "table" then for _, o in ipairs(v) do selected[o] = true end end
		else
			selected = v ~= nil and v or options[1]
		end
	end
	resetSel(default)

	local row = extCreateRow(section, HEADER)
	local on = extBinder(row)
	extTitle(row, name, 170)

	local valueLabel = extNew("TextLabel", {
		AnchorPoint = Vector2.new(1, 0), Position = UDim2.new(1, -26, 0, 0),
		Size = UDim2.new(0, 140, 0, HEADER), BackgroundTransparency = 1,
		Font = extFont(), TextSize = 11, TextColor3 = ExtTheme.Muted,
		TextXAlignment = Enum.TextXAlignment.Right, TextTruncate = Enum.TextTruncate.AtEnd, Text = "",
	}, row)

	local arrow = extNew("TextLabel", {
		AnchorPoint = Vector2.new(1, 0), Position = UDim2.new(1, -10, 0, 0),
		Size = UDim2.fromOffset(14, HEADER), BackgroundTransparency = 1,
		Font = extFont(Enum.FontWeight.Bold), TextSize = 11, TextColor3 = ExtTheme.Muted, Text = "v",
	}, row)

	local list = extNew("ScrollingFrame", {
		Position = UDim2.new(0, 8, 0, HEADER + 2),
		Size = UDim2.new(1, -16, 0, 0),
		BackgroundColor3 = ExtTheme.Surface, BorderSizePixel = 0,
		ScrollBarThickness = 2, ScrollBarImageColor3 = ExtTheme.Muted,
		CanvasSize = UDim2.new(), AutomaticCanvasSize = Enum.AutomaticSize.Y,
		ScrollingDirection = Enum.ScrollingDirection.Y,
	}, row)
	extCorner(list, 0, 4)
	extNew("UIListLayout", { SortOrder = Enum.SortOrder.LayoutOrder }, list)

	local hit = extNew("TextButton", {
		Text = "", BackgroundTransparency = 1, Size = UDim2.new(1, 0, 0, HEADER),
	}, row)

	local function snapshot()
		if multi then
			local r = {}
			for _, o in ipairs(options) do if selected[o] then r[#r + 1] = o end end
			return r
		end
		return selected
	end

	local function summary()
		if multi then
			local parts = {}
			for _, o in ipairs(options) do if selected[o] then parts[#parts + 1] = tostring(o) end end
			return #parts > 0 and table.concat(parts, ", ") or "None"
		end
		return selected ~= nil and tostring(selected) or "None"
	end

	local function refresh()
		valueLabel.Text = summary()
		for _, item in ipairs(items) do
			local a = multi and (selected[item.option] == true) or (selected == item.option)
			item.button.TextColor3 = a and ExtTheme.Accent or ExtTheme.Muted
		end
	end

	local function listH() if #options == 0 then return 0 end return math.min(#options, MAXV) * ITEM + 4 end

	local function setExpanded(v)
		if v == expanded then return end
		expanded = v
		local h = listH()
		extTween(row, { Size = UDim2.new(0.9, 0, 0, v and (HEADER + h + 8) or HEADER) })
		extTween(list, { Size = UDim2.new(1, -16, 0, v and h or 0) })
		extTween(arrow, { Rotation = v and 180 or 0 })
	end

	local function choose(o)
		if multi then selected[o] = (not selected[o]) or nil
		else selected = o; setExpanded(false) end
		refresh()
		if callback then extSafe(callback, snapshot()) end
	end

	local function build()
		for _, c in ipairs(list:GetChildren()) do if c:IsA("TextButton") then c:Destroy() end end
		table.clear(items)
		for i, o in ipairs(options) do
			local b = extNew("TextButton", {
				Text = tostring(o), Font = extFont(), TextSize = 11, TextColor3 = ExtTheme.Muted,
				TextXAlignment = Enum.TextXAlignment.Left, AutoButtonColor = false,
				BackgroundColor3 = ExtTheme.Hover, BackgroundTransparency = 1, BorderSizePixel = 0,
				Size = UDim2.new(1, 0, 0, ITEM), LayoutOrder = i,
			}, list)
			extCorner(b, 0, 3)
			extNew("UIPadding", { PaddingLeft = UDim.new(0, 8) }, b)
			on(b.MouseButton1Click, function() choose(o) end)
			on(b.MouseEnter, function() extTween(b, { BackgroundTransparency = 0 }) end)
			on(b.MouseLeave, function() extTween(b, { BackgroundTransparency = 1 }) end)
			items[i] = { option = o, button = b }
		end
		refresh()
	end

	on(hit.MouseButton1Click, function() setExpanded(not expanded) end)
	extHover(row, on)
	build()

	return extFinish(row, {
		Set = function(_, v, f) resetSel(v); refresh(); if f and callback then extSafe(callback, snapshot()) end end,
		Get = snapshot,
		SetOptions = function(_, no, nd, f)
			setExpanded(false)
			options = type(no) == "table" and no or {}
			resetSel(nd); build()
			if f and callback then extSafe(callback, snapshot()) end
		end,
		Refresh = function(_, no, f)
			setExpanded(false)
			options = type(no) == "table" and no or options
			build()
			if f and callback then extSafe(callback, snapshot()) end
		end,
	})
end

local function extCreateKeybind(section, name, default, callback, changed)
	local row = extCreateRow(section, 30)
	local on = extBinder(row)
	extTitle(row, name, 94)

	local key = extResolveKey(default)
	local listening = false

	local button = extNew("TextButton", {
		AnchorPoint = Vector2.new(1, 0.5), Position = UDim2.new(1, -10, 0, 15),
		Size = UDim2.fromOffset(72, 20), BackgroundColor3 = ExtTheme.Surface,
		BorderSizePixel = 0, AutoButtonColor = false, Font = extFont(Enum.FontWeight.Medium),
		TextSize = 11, TextColor3 = ExtTheme.Text, Text = "",
	}, row)
	extCorner(button, 0, 4)
	extStroke(button)

	local function render()
		if listening then
			button.Text = "..."; button.TextColor3 = ExtTheme.Accent
		else
			button.Text = key == Enum.KeyCode.Unknown and "None" or key.Name
			button.TextColor3 = ExtTheme.Text
		end
	end

	on(button.MouseButton1Click, function() if not listening then listening = true; render() end end)
	on(UserInputService.InputBegan, function(i, processed)
		if i.UserInputType ~= Enum.UserInputType.Keyboard then return end
		if listening then
			listening = false
			if i.KeyCode ~= Enum.KeyCode.Escape then
				key = i.KeyCode == Enum.KeyCode.Backspace and Enum.KeyCode.Unknown or i.KeyCode
				if changed then extSafe(changed, key) end
			end
			render()
			return
		end
		if processed or key == Enum.KeyCode.Unknown then return end
		if i.KeyCode == key and callback then extSafe(callback, key) end
	end)

	extHover(row, on); render()

	return extFinish(row, {
		Set = function(_, v, f)
			key = extResolveKey(v); render()
			if f and changed then extSafe(changed, key) end
		end,
		Get = function() return key end,
		IsPressed = function() return key ~= Enum.KeyCode.Unknown and UserInputService:IsKeyDown(key) end,
	})
end

local function extCreateColorPicker(section, name, default, callback)
	local HEADER, SV_H, HUE_H = 30, 80, 10
	local HOLDER_H = SV_H + 10 + HUE_H
	local EXPANDED = HEADER + 4 + HOLDER_H + 8

	default = typeof(default) == "Color3" and default or Color3.new(1, 1, 1)
	local h, s, v = Color3.toHSV(default)
	local expanded = false
	local mode = nil

	local row = extCreateRow(section, HEADER)
	local on = extBinder(row)
	extTitle(row, name, 110)

	local hexLabel = extNew("TextButton", {
		AnchorPoint = Vector2.new(1, 0), Position = UDim2.new(1, -42, 0, 0),
		Size = UDim2.new(0, 64, 0, HEADER), BackgroundTransparency = 1, AutoButtonColor = false,
		Font = extFont(Enum.FontWeight.Medium), TextSize = 11, TextColor3 = ExtTheme.Muted,
		TextXAlignment = Enum.TextXAlignment.Right, Text = "",
	}, row)
	on(hexLabel.MouseButton1Click, function()
		local t = hexLabel.Text
		if t == "" or t == "copied!" then return end
		local ok = pcall(function()
			if setclipboard then setclipboard(t) elseif toclipboard then toclipboard(t) end
		end)
		if ok then
			hexLabel.Text = "copied!"
			task.delay(0.8, function() if hexLabel.Parent then hexLabel.Text = t end end)
		end
	end)

	local swatch = extNew("Frame", {
		AnchorPoint = Vector2.new(1, 0.5), Position = UDim2.new(1, -10, 0, 15),
		Size = UDim2.fromOffset(24, 14), BackgroundColor3 = default, BorderSizePixel = 0,
	}, row)
	extCorner(swatch, 0, 3); extStroke(swatch)

	local header = extNew("TextButton", {
		Text = "", BackgroundTransparency = 1, Size = UDim2.new(1, 0, 0, HEADER),
	}, row)

	local holder = extNew("Frame", {
		Position = UDim2.new(0, 10, 0, HEADER + 4),
		Size = UDim2.new(1, -20, 0, HOLDER_H), BackgroundTransparency = 1,
	}, row)

	local svBox = extNew("TextButton", {
		Text = "", AutoButtonColor = false, BackgroundColor3 = Color3.fromHSV(h, 1, 1),
		BorderSizePixel = 0, Size = UDim2.new(1, 0, 0, SV_H),
	}, holder)
	extCorner(svBox, 0, 4)

	local white = extNew("Frame", {
		BackgroundColor3 = Color3.new(1, 1, 1), BorderSizePixel = 0,
		Size = UDim2.fromScale(1, 1), ZIndex = 2,
	}, svBox)
	extCorner(white, 0, 4)
	extNew("UIGradient", { Transparency = NumberSequence.new(0, 1) }, white)

	local black = extNew("Frame", {
		BackgroundColor3 = Color3.new(0, 0, 0), BorderSizePixel = 0,
		Size = UDim2.fromScale(1, 1), ZIndex = 3,
	}, svBox)
	extCorner(black, 0, 4)
	extNew("UIGradient", { Rotation = 90, Transparency = NumberSequence.new(1, 0) }, black)

	local svKnob = extNew("Frame", {
		AnchorPoint = Vector2.new(0.5, 0.5), Size = UDim2.fromOffset(10, 10),
		BackgroundTransparency = 1, ZIndex = 4,
	}, svBox)
	extCorner(svKnob, 1, 0)
	extStroke(svKnob, Color3.new(1, 1, 1), 2)

	local hueTrack = extNew("TextButton", {
		Text = "", AutoButtonColor = false, BackgroundColor3 = Color3.new(1, 1, 1),
		BorderSizePixel = 0, Position = UDim2.new(0, 0, 0, SV_H + 10),
		Size = UDim2.new(1, 0, 0, HUE_H),
	}, holder)
	extCorner(hueTrack, 1, 0)

	local hueKeys = {}
	for i = 0, 6 do
		hueKeys[#hueKeys + 1] = ColorSequenceKeypoint.new(i / 6, Color3.fromHSV(i / 6, 1, 1))
	end
	extNew("UIGradient", { Color = ColorSequence.new(hueKeys) }, hueTrack)

	local hueKnob = extNew("Frame", {
		AnchorPoint = Vector2.new(0.5, 0.5), Size = UDim2.fromOffset(4, HUE_H + 4),
		BackgroundColor3 = Color3.new(1, 1, 1), BorderSizePixel = 0,
	}, hueTrack)
	extCorner(hueKnob, 0, 2)
	extStroke(hueKnob, ExtTheme.Background, 1)

	local function apply(fire)
		local color = Color3.fromHSV(h, s, v)
		swatch.BackgroundColor3 = color
		svBox.BackgroundColor3 = Color3.fromHSV(h, 1, 1)
		svKnob.Position = UDim2.fromScale(s, 1 - v)
		hueKnob.Position = UDim2.new(h, 0, 0.5, 0)
		hexLabel.Text = "#" .. string.upper(color:ToHex())
		if fire and callback then extSafe(callback, color) end
	end

	local function sample(pos)
		if mode == "sv" then
			local o, sz = svBox.AbsolutePosition, svBox.AbsoluteSize
			if sz.X <= 0 or sz.Y <= 0 then return end
			s = math.clamp((pos.X - o.X) / sz.X, 0, 1)
			v = 1 - math.clamp((pos.Y - o.Y) / sz.Y, 0, 1)
		elseif mode == "hue" then
			local o, sz = hueTrack.AbsolutePosition, hueTrack.AbsoluteSize
			if sz.X <= 0 then return end
			h = math.clamp((pos.X - o.X) / sz.X, 0, 1)
		else return end
		apply(true)
	end

	on(header.MouseButton1Click, function()
		expanded = not expanded
		extTween(row, { Size = UDim2.new(0.9, 0, 0, expanded and EXPANDED or HEADER) })
	end)
	on(svBox.InputBegan, function(i) if extIsPress(i) then mode = "sv"; sample(i.Position) end end)
	on(hueTrack.InputBegan, function(i) if extIsPress(i) then mode = "hue"; sample(i.Position) end end)
	on(UserInputService.InputChanged, function(i) if mode and extIsMove(i) then sample(i.Position) end end)
	on(UserInputService.InputEnded, function(i) if extIsPress(i) then mode = nil end end)

	extHover(row, on); apply(false)

	return extFinish(row, {
		Set = function(_, c, f)
			if typeof(c) == "Color3" then h, s, v = Color3.toHSV(c); apply(f) end
		end,
		Get = function() return Color3.fromHSV(h, s, v) end,
	})
end

local function extCreateFolder(section, name, collapsed)
	local HEADER = 24
	local open = not collapsed
	local holder = extNew("Frame", {
		Name = "ExtFolder", BackgroundColor3 = ExtTheme.Surface, BackgroundTransparency = 0.5,
		BorderSizePixel = 0, Size = UDim2.new(1, 0, 0, HEADER),
		LayoutOrder = extNextOrder(section), ClipsDescendants = true,
	}, section)
	extCorner(holder, 0, 4); extStroke(holder)

	local header = extNew("TextButton", {
		Name = "Header", Text = "", BackgroundTransparency = 1,
		AutoButtonColor = false, Size = UDim2.new(1, 0, 0, HEADER),
	}, holder)

	local arrow = extNew("TextLabel", {
		AnchorPoint = Vector2.new(0, 0.5), Position = UDim2.new(0, 8, 0, HEADER / 2),
		Size = UDim2.fromOffset(12, 12), BackgroundTransparency = 1,
		Font = extFont(Enum.FontWeight.Bold), TextSize = 10, TextColor3 = ExtTheme.Accent,
		Text = open and "v" or ">", TextXAlignment = Enum.TextXAlignment.Left,
	}, holder)

	local label = extNew("TextLabel", {
		Position = UDim2.new(0, 26, 0, 0), Size = UDim2.new(1, -34, 0, HEADER),
		BackgroundTransparency = 1, Font = extFont(Enum.FontWeight.SemiBold), TextSize = 11,
		TextColor3 = ExtTheme.Text, TextXAlignment = Enum.TextXAlignment.Left,
		Text = tostring(name or "Folder"),
	}, holder)

	local body = extNew("Frame", {
		Name = "Body", Position = UDim2.new(0, 0, 0, HEADER),
		Size = UDim2.new(1, 0, 0, 0), BackgroundTransparency = 1, ClipsDescendants = true,
	}, holder)
	local listLayout = extNew("UIListLayout", { SortOrder = Enum.SortOrder.LayoutOrder, Padding = UDim.new(0, 4) }, body)
	extNew("UIPadding", {
		PaddingTop = UDim.new(0, 4), PaddingBottom = UDim.new(0, 4),
		PaddingLeft = UDim.new(0, 4), PaddingRight = UDim.new(0, 4),
	}, body)

	local function render()
		arrow.Text = open and "v" or ">"
		local h = open and (listLayout.AbsoluteContentSize.Y + 8) or 0
		extTween(holder, { Size = UDim2.new(1, 0, 0, HEADER + h) })
		extTween(body, { Size = UDim2.new(1, 0, 0, h) })
	end

	local on = extBinder(holder)
	on(header.MouseButton1Click, function() open = not open; render() end)
	listLayout:GetPropertyChangedSignal("AbsoluteContentSize"):Connect(function() if open then render() end end)
	render()

	local f = {}
	f.Container = holder
	f.Body = body
	f.AddToggle = function(_, ...) local r = extCreateToggle(body, ...); task.defer(render); return r end
	f.AddSlider = function(_, ...) local r = extCreateSlider(body, ...); task.defer(render); return r end
	f.AddDropdown = function(_, ...) local r = extCreateDropdown(body, ...); task.defer(render); return r end
	f.AddKeybind = function(_, ...) local r = extCreateKeybind(body, ...); task.defer(render); return r end
	f.AddTextBox = function(_, ...) local r = extCreateTextBox(body, ...); task.defer(render); return r end
	f.AddColorPicker = function(_, ...) local r = extCreateColorPicker(body, ...); task.defer(render); return r end
	f.AddButton = function(_, ...) local r = extCreateButton(body, ...); task.defer(render); return r end
	f.AddLabel = function(_, ...) local r = extCreateLabel(body, ...); task.defer(render); return r end
	f.AddSeparator = function() local r = extCreateSeparator(body); task.defer(render); return r end
	f.SetOpen = function(_, v) open = v and true or false; render() end
	f.IsOpen = function() return open end
	f.Destroy = function() holder:Destroy() end
	f.SetTitle = function(_, t) label.Text = tostring(t) end

	return f
end

local extNotifyHolder
local function extGetNotifyHolder()
	if extNotifyHolder and extNotifyHolder.Parent then return extNotifyHolder end
	local gui = extNew("ScreenGui", {
		Name = "NeverLoseModNotify", ResetOnSpawn = false, IgnoreGuiInset = true,
		DisplayOrder = 1000, ZIndexBehavior = Enum.ZIndexBehavior.Sibling,
	})
	if syn and syn.protect_gui then pcall(syn.protect_gui, gui) end
	gui.Parent = (gethui and gethui()) or CoreGui
	extNotifyHolder = extNew("Frame", {
		AnchorPoint = Vector2.new(1, 1), Position = UDim2.new(1, -16, 1, -16),
		Size = UDim2.new(0, 260, 0, 0), AutomaticSize = Enum.AutomaticSize.Y,
		BackgroundTransparency = 1,
	}, gui)
	extNew("UIListLayout", {
		SortOrder = Enum.SortOrder.LayoutOrder,
		HorizontalAlignment = Enum.HorizontalAlignment.Right,
		VerticalAlignment = Enum.VerticalAlignment.Bottom,
		Padding = UDim.new(0, 6),
	}, extNotifyHolder)
	return extNotifyHolder
end


local function cretate_button(asd)
	local button=Instance.new('TextButton')
	button.Size=UDim2.new(1,0,1,0)
	button.BackgroundTransparency=1
	button.TextTransparency=1
	button.Text=""
	button.Parent=asd
	button.ZIndex=5000
	return button
end


local function ConnectButtonEffect(UIFrame:Frame&TextButton&ImageLabel,UIStroke:UIStroke,int)
	if not UIStroke then
		return
	end

	int = int or 0.2
	local OldColor = UIStroke.Color
	local R,G,B = OldColor.R,OldColor.G,OldColor.B
	local MainColor = Color3.fromHSV(R,G,B + int)

	UIFrame.InputBegan:Connect(function(Input)
		if Input.UserInputType == Enum.UserInputType.Touch or Input.UserInputType == Enum.UserInputType.MouseMovement then
			TweenService:Create(UIStroke,TweenInfo.new(0.2),{Color = MainColor}):Play()
		end
	end)

	UIFrame.InputEnded:Connect(function(Input)
		if Input.UserInputType == Enum.UserInputType.Touch or Input.UserInputType == Enum.UserInputType.MouseMovement then
			TweenService:Create(UIStroke,TweenInfo.new(0.2),{Color = OldColor}):Play()
		end
	end)
end

local function scrolling_connect(scrollframe:ScrollingFrame)
	task.spawn(function()
		local addres = 45
		local UIListLayout:UIListLayout = scrollframe:WaitForChild('UIListLayout',9999999)
		scrollframe.CanvasSize=UDim2.new(0,0,0,UIListLayout.AbsoluteContentSize.Y+addres)

		UIListLayout:GetPropertyChangedSignal('AbsoluteContentSize'):Connect(function()
			scrollframe.CanvasSize=UDim2.new(0,0,0,UIListLayout.AbsoluteContentSize.Y+addres)
		end)
	end)
end

local function GetImageData(Name, Image)
	Name = tostring(Name or "ads")

	if Name:find("^rbxassetid://") then
		Image.Image = Name
		Image.ImageRectOffset = Vector2.zero
		Image.ImageRectSize = Vector2.zero
		return
	end

	Name = Name:lower()

	local Sprite = "rbxassetid://3926305904"

	if Name == "ads" then
		Image.Image = Sprite
		Image.ImageRectOffset = Vector2.new(205, 565)
		Image.ImageRectSize = Vector2.new(35, 35)
	elseif Name == "list" then
		Image.Image = Sprite
		Image.ImageRectOffset = Vector2.new(485, 205)
		Image.ImageRectSize = Vector2.new(35, 35)
	elseif Name == "folder" then
		Image.Image = Sprite
		Image.ImageRectOffset = Vector2.new(805, 45)
		Image.ImageRectSize = Vector2.new(35, 35)
	elseif Name == "earth" then
		Image.Image = Sprite
		Image.ImageRectOffset = Vector2.new(604, 324)
		Image.ImageRectSize = Vector2.new(35, 35)
	elseif Name == "locked" then
		Image.Image = Sprite
		Image.ImageRectOffset = Vector2.new(524, 644)
		Image.ImageRectSize = Vector2.new(35, 35)
	elseif Name == "home" then
		Image.Image = Sprite
		Image.ImageRectOffset = Vector2.new(964, 205)
		Image.ImageRectSize = Vector2.new(35, 35)
	elseif Name == "mouse" then
		Image.Image = "rbxassetid://3515393063"
	elseif Name == "user" then
		Image.Image = "rbxassetid://10494577250"
	end
end

local NEVERLOSE = {
	auto_function = {},
	Themes = {
		-- Pure black + white palette.
		BlackgroundColor = Color3.fromRGB(0, 0, 0),
		BlackColor = Color3.fromRGB(0, 0, 0),
		HeaderColor = Color3.fromRGB(0, 0, 0),
		TraceColor = Color3.fromRGB(255, 255, 255),
		MainColor = Color3.fromRGB(255, 255, 255),
		MainColorDrop = Color3.fromRGB(0, 0, 0),
		SectionColor = Color3.fromRGB(0, 0, 0),
		StrokeColor = Color3.fromRGB(255, 255, 255),
		ButtonBlackgroundColor = Color3.fromRGB(0, 0, 0),
		TextColor = Color3.fromRGB(255, 255, 255),
		HeadNameStrokeTransparency = 1
	},
	_Version="10.C-BLACKWHITE",
	_Name="NEVERLOSE"
}

print(NEVERLOSE._Name..":",NEVERLOSE._Version..':',[[https://neverlose.cc/]],": UI BY OWNER BEDOL HUB","__ui")

function NEVERLOSE:Theme(name)
	name = tostring(name or "original"):lower()
	if name == "original" then
		NEVERLOSE.Themes.BlackgroundColor = Color3.fromRGB(1, 17, 33)
		NEVERLOSE.Themes.BlackColor = Color3.fromRGB(9, 9, 19)
		NEVERLOSE.Themes.HeaderColor = Color3.fromRGB(7, 7, 17)
		NEVERLOSE.Themes.TraceColor = Color3.fromRGB(0, 34, 44)
		NEVERLOSE.Themes.MainColor = Color3.fromRGB(19, 176, 243)
		NEVERLOSE.Themes.MainColorDrop = Color3.fromRGB(3, 6, 25)
		NEVERLOSE.Themes.SectionColor = Color3.fromRGB(0, 17, 35)
		NEVERLOSE.Themes.StrokeColor = Color3.fromRGB(3, 35, 50)
		NEVERLOSE.Themes.ButtonBlackgroundColor = Color3.fromRGB(2, 5, 22)
		NEVERLOSE.Themes.TextColor = Color3.fromRGB(255, 255, 255)
		NEVERLOSE.Themes.HeadNameStrokeTransparency = 0.720
	end

	if name == "nightly" then
		NEVERLOSE.Themes.BlackgroundColor = Color3.fromRGB(43, 43, 43)
		NEVERLOSE.Themes.BlackColor = Color3.fromRGB(16, 16, 16)
		NEVERLOSE.Themes.HeaderColor = Color3.fromRGB(47, 47, 47)
		NEVERLOSE.Themes.TraceColor = Color3.fromRGB(100, 100, 100)
		NEVERLOSE.Themes.MainColor = Color3.fromRGB(255, 140, 0)
		NEVERLOSE.Themes.MainColorDrop = Color3.fromRGB(65, 54, 31)
		NEVERLOSE.Themes.SectionColor = Color3.fromRGB(26, 26, 26)
		NEVERLOSE.Themes.StrokeColor = Color3.fromRGB(50, 50, 50)
		NEVERLOSE.Themes.ButtonBlackgroundColor = Color3.fromRGB(26, 26, 26)
		NEVERLOSE.Themes.TextColor = Color3.fromRGB(255, 255, 255)
		NEVERLOSE.Themes.HeadNameStrokeTransparency = 0.720
	end

	if name == "dark" then
		NEVERLOSE.Themes.BlackgroundColor = Color3.fromRGB(37, 37, 37)
		NEVERLOSE.Themes.BlackColor = Color3.fromRGB(8, 8, 8)
		NEVERLOSE.Themes.HeaderColor = Color3.fromRGB(8, 8, 8)
		NEVERLOSE.Themes.TraceColor = Color3.fromRGB(25, 25, 25)
		NEVERLOSE.Themes.MainColor = Color3.fromRGB(0, 172, 247)
		NEVERLOSE.Themes.MainColorDrop = Color3.fromRGB(64, 65, 67)
		NEVERLOSE.Themes.SectionColor = Color3.fromRGB(13, 13, 13)
		NEVERLOSE.Themes.StrokeColor = Color3.fromRGB(28, 28, 28)
		NEVERLOSE.Themes.ButtonBlackgroundColor = Color3.fromRGB(13, 13, 13)
		NEVERLOSE.Themes.TextColor = Color3.fromRGB(255, 255, 255)
		NEVERLOSE.Themes.HeadNameStrokeTransparency = 0.720
	end

	if name == "white" or name == "light" or name == "branco" then
		-- Exact copy of DARK, changing only the blue accent to white.
		NEVERLOSE.Themes.BlackgroundColor = Color3.fromRGB(37, 37, 37)
		NEVERLOSE.Themes.BlackColor = Color3.fromRGB(8, 8, 8)
		NEVERLOSE.Themes.HeaderColor = Color3.fromRGB(8, 8, 8)
		NEVERLOSE.Themes.TraceColor = Color3.fromRGB(25, 25, 25)
		NEVERLOSE.Themes.MainColor = Color3.fromRGB(255, 255, 255)
		NEVERLOSE.Themes.MainColorDrop = Color3.fromRGB(64, 65, 67)
		NEVERLOSE.Themes.SectionColor = Color3.fromRGB(13, 13, 13)
		NEVERLOSE.Themes.StrokeColor = Color3.fromRGB(28, 28, 28)
		NEVERLOSE.Themes.ButtonBlackgroundColor = Color3.fromRGB(13, 13, 13)
		NEVERLOSE.Themes.TextColor = Color3.fromRGB(255, 255, 255)
		NEVERLOSE.Themes.HeadNameStrokeTransparency = 1
	end
end

function NEVERLOSE:AddWindow(NameScriptHub,Text,UICustomSize)
	local WindowFunctinos={}
	local ToggleUI=false
	local ooldsize=UICustomSize or UDim2.new(0.200000003, 210, 0.200000003, 175)
	local Tabs={}

	local ScreenGui = Instance.new("ScreenGui")
	local Frame = Instance.new("Frame")
	local UICorner = Instance.new("UICorner")
	local Frame_2 = Instance.new("Frame")
	local UICorner_2 = Instance.new("UICorner")
	local Frame_3 = Instance.new("Frame")
	local UICorner_3 = Instance.new("UICorner")
	local DropShadow = Instance.new("ImageLabel")
	local HeadName = Instance.new("TextLabel")
	local TabButtons = Instance.new("ScrollingFrame")
	local UIListLayout = Instance.new("UIListLayout")
	local TabHose = Instance.new("Frame")
	local outlo = Instance.new("Frame")
	local UICorner_4 = Instance.new("UICorner")
	local outlo_2 = Instance.new("Frame")
	local UICorner_5 = Instance.new("UICorner")
	local outlo_3 = Instance.new("Frame")
	local UICorner_6 = Instance.new("UICorner")
	local UserData = Instance.new("Frame")
	local UICorner_7 = Instance.new("UICorner")
	local UserImage = Instance.new("ImageLabel")
	local UICorner_8 = Instance.new("UICorner")
	local UserName = Instance.new("TextLabel")
	local headd2text
	local oldPositionClose
	
	--Anti Spoofer
	ScreenGui:GetPropertyChangedSignal('Enabled'):Connect(function()
		if not ScreenGui.Enabled then
			ScreenGui.Enabled=true
		end
	end)
	
	task.spawn(function()
		if Text then
			local TextLabel = Instance.new("TextLabel")

			TextLabel.Parent = Frame
			TextLabel.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
			TextLabel.BackgroundTransparency = 1.000
			TextLabel.BorderColor3 = Color3.fromRGB(0, 0, 0)
			TextLabel.BorderSizePixel = 0
			TextLabel.Position = UDim2.new(0.243000001, 0, 0.0250000004, 0)
			TextLabel.Size = UDim2.new(0.666889787, 0, 0.0627818182, 0)
			TextLabel.ZIndex = 5
			TextLabel.Font = Enum.Font.SourceSansBold
			TextLabel.Text = Text or" "
			TextLabel.TextColor3 = NEVERLOSE.Themes.TextColor
			TextLabel.TextScaled = true
			TextLabel.TextSize = 14.000
			TextLabel.TextStrokeColor3 = NEVERLOSE.Themes.MainColor
			TextLabel.TextStrokeTransparency = 0.900
			TextLabel.TextWrapped = true
			TextLabel.TextXAlignment = Enum.TextXAlignment.Left
			TextLabel.RichText=true

			headd2text=TextLabel
		end
	end)

	local toggle_valu = true

	local function ui_toggleong(val)
		local uptime=1.4
		if val then
			TweenService:Create(Frame,TweenInfo.new(uptime,Enum.EasingStyle.Quint),{Size=ooldsize,Position=UDim2.new(0.5,0,0.5,0)}):Play()
			TweenService:Create(HeadName,TweenInfo.new(uptime/3,Enum.EasingStyle.Quint),{Size=UDim2.new(0.205458686, 0, 0.133462012, 0),Position=UDim2.new(0.0100000342, 0, 0.010000146, 0)}):Play()


			TweenService:Create(TabHose,TweenInfo.new(0.3),{Position=UDim2.new(.223,0,0.143,0)}):Play()
			TweenService:Create(TabButtons,TweenInfo.new(0.3),{Position=UDim2.new(.008,0,0.143,0)}):Play()

			if headd2text then
				TweenService:Create(headd2text,TweenInfo.new(0.3),{TextTransparency=0,TextStrokeTransparency=0.900}):Play()
			end

			TweenService:Create(UserName,TweenInfo.new(0.3),{TextTransparency=0,TextStrokeTransparency=1}):Play()
			TweenService:Create(UserImage,TweenInfo.new(0.3),{ImageTransparency=0}):Play()
			TweenService:Create(outlo,TweenInfo.new(0.3),{BackgroundTransparency=0.7}):Play()
			TweenService:Create(outlo_2,TweenInfo.new(0.3),{BackgroundTransparency=0.7}):Play()
			TweenService:Create(outlo_3,TweenInfo.new(0.3),{BackgroundTransparency=0.7}):Play()
			TweenService:Create(Frame_2,TweenInfo.new(0.3),{BackgroundTransparency=0}):Play()
			TweenService:Create(Frame_3,TweenInfo.new(0.3),{BackgroundTransparency=0.9}):Play()
			TweenService:Create(DropShadow,TweenInfo.new(0.3),{ImageTransparency=0.86}):Play()

		else
			TweenService:Create(Frame,TweenInfo.new(uptime,Enum.EasingStyle.Quint),{Size=UDim2.new(0.14, 0,0.14, 0),Position=oldPositionClose}):Play()
			TweenService:Create(HeadName,TweenInfo.new(uptime/1.2,Enum.EasingStyle.Quint),{Size=UDim2.new(0.9, 0,0.5, 0),Position=UDim2.new(0.046,0,0.24,0)}):Play()

			TweenService:Create(TabHose,TweenInfo.new(0.3),{Position=UDim2.new(1.5,0,0.143,0)}):Play()
			TweenService:Create(TabButtons,TweenInfo.new(0.3),{Position=UDim2.new(-1.25,0,0.143,0)}):Play()

			if headd2text then
				TweenService:Create(headd2text,TweenInfo.new(0.3),{TextTransparency=1,TextStrokeTransparency=1}):Play()
			end

			TweenService:Create(UserName,TweenInfo.new(0.3),{TextTransparency=1,TextStrokeTransparency=1}):Play()
			TweenService:Create(UserImage,TweenInfo.new(0.3),{ImageTransparency=1}):Play()
			TweenService:Create(outlo,TweenInfo.new(0.3),{BackgroundTransparency=1}):Play()
			TweenService:Create(outlo_2,TweenInfo.new(0.3),{BackgroundTransparency=1}):Play()
			TweenService:Create(outlo_3,TweenInfo.new(0.3),{BackgroundTransparency=1}):Play()
			TweenService:Create(Frame_2,TweenInfo.new(0.3),{BackgroundTransparency=1}):Play()
			TweenService:Create(Frame_3,TweenInfo.new(0.3),{BackgroundTransparency=1}):Play()
			TweenService:Create(DropShadow,TweenInfo.new(0.3),{ImageTransparency=1}):Play()
		end
	end

	task.spawn(function()
		local ImageButton = Instance.new("ImageButton")

		ImageButton.Parent = Frame
		ImageButton.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
		ImageButton.BackgroundTransparency = 1.000
		ImageButton.BorderColor3 = Color3.fromRGB(0, 0, 0)
		ImageButton.BorderSizePixel = 0
		ImageButton.Position = UDim2.new(0.908723712, 0, 0.0239103697, 0)
		ImageButton.Size = UDim2.new(0.0900000036, 0, 0.0900000036, 0)
		ImageButton.SizeConstraint = Enum.SizeConstraint.RelativeYY
		ImageButton.ZIndex = 4
		ImageButton.Image = "rbxassetid://10002398990"
		ImageButton.ScaleType = Enum.ScaleType.Fit

		ImageButton.MouseButton1Click:Connect(function()
			toggle_valu=not toggle_valu

			if toggle_valu then
				oldPositionClose = Frame.Position
				TweenService:Create(ImageButton,TweenInfo.new(0.5),{
					Size=UDim2.new(0.0900000036, 0, 0.0900000036, 0),
					Position=UDim2.new(0.908723712, 0, 0.0239103697, 0),
					AnchorPoint=Vector2.new(0,0)
				}):Play()
			else
				TweenService:Create(ImageButton,TweenInfo.new(0.5),{
					Size=UDim2.new(0.3, 0,0.3, 0),
					Position=UDim2.new(1,0,-0.009,0),
					AnchorPoint=Vector2.new(1,0)
				}):Play()
			end

			ui_toggleong(toggle_valu)
		end)
	end)

	task.spawn(function()
		local dragToggle = nil
		local dragSpeed = 0.15
		local dragStart = nil
		local startPos = nil

		local function updateInput(input)
			local delta = input.Position - dragStart
			local position = UDim2.new(startPos.X.Scale, startPos.X.Offset + delta.X,
				startPos.Y.Scale, startPos.Y.Offset + delta.Y)
			game:GetService('TweenService'):Create(Frame, TweenInfo.new(dragSpeed), {Position = position}):Play()
		end

		Frame.InputBegan:Connect(function(input)
			if (input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch) and not toggle_valu then 
				dragToggle = true
				dragStart = input.Position
				startPos = Frame.Position
				input.Changed:Connect(function()
					if input.UserInputState == Enum.UserInputState.End then
						dragToggle = false
					end
				end)
			end
		end)

		InputService.InputChanged:Connect(function(input)
			if input.UserInputType == Enum.UserInputType.MouseMovement or input.UserInputType == Enum.UserInputType.Touch then
				if dragToggle and not toggle_valu then
					updateInput(input)
				end
			end
		end)
	end)

	ScreenGui.Parent = CoreGui
	ScreenGui.ResetOnSpawn = false
	ScreenGui.IgnoreGuiInset = true
	ScreenGui.ZIndexBehavior = Enum.ZIndexBehavior.Global
	ProtectGui(ScreenGui)

	Frame.Parent = ScreenGui
	Frame.Active = true
	Frame.AnchorPoint = Vector2.new(0.5, 0.5)
	Frame.BackgroundColor3 = NEVERLOSE.Themes.BlackgroundColor
	Frame.BackgroundTransparency = 0.200
	Frame.BorderColor3 = Color3.fromRGB(0, 0, 0)
	Frame.BorderSizePixel = 0
	Frame.Position = UDim2.new(0.5, 0, 0.5, 0)
	Frame.Size = UDim2.new(0,0,0,0)
	Frame.ZIndex = 2
	Frame.ClipsDescendants=true

	TweenService:Create(Frame,TweenInfo.new(1,Enum.EasingStyle.Quint),{Size=ooldsize}):Play()

	UICorner.Parent = Frame

	Frame_2.Parent = Frame
	Frame_2.BackgroundColor3 = NEVERLOSE.Themes.BlackColor
	Frame_2.BorderColor3 = Color3.fromRGB(0, 0, 0)
	Frame_2.BorderSizePixel = 0
	Frame_2.Position = UDim2.new(0.223214373, 0, 0, 0)
	Frame_2.Size = UDim2.new(0.774634778, 0, 1, 0)
	Frame_2.ZIndex = 2

	UICorner_2.CornerRadius = UDim.new(0, 4)
	UICorner_2.Parent = Frame_2

	Frame_3.Parent = Frame
	Frame_3.BackgroundColor3 = NEVERLOSE.Themes.HeaderColor
	Frame_3.BackgroundTransparency = 0.900
	Frame_3.BorderColor3 = Color3.fromRGB(0, 0, 0)
	Frame_3.BorderSizePixel = 0
	Frame_3.Position = UDim2.new(0.223214373, 0, 0, 0)
	Frame_3.Size = UDim2.new(0.774999976, 0, 0.140000001, 0)
	Frame_3.ZIndex = 4

	UICorner_3.CornerRadius = UDim.new(0, 4)
	UICorner_3.Parent = Frame_3

	DropShadow.Name = "DropShadow"
	DropShadow.Parent = Frame
	DropShadow.AnchorPoint = Vector2.new(0.5, 0.5)
	DropShadow.BackgroundTransparency = 1.000
	DropShadow.BorderSizePixel = 0
	DropShadow.Position = UDim2.new(0.963742971, 0, 0.5, 0)
	DropShadow.Size = UDim2.new(-0.0510042384, 47, 0.839458942, 47)
	DropShadow.ZIndex = 3
	DropShadow.Image = "rbxassetid://6014261993"
	DropShadow.ImageColor3 = Color3.fromRGB(0, 0, 0)
	DropShadow.ImageTransparency = 0.860
	DropShadow.ScaleType = Enum.ScaleType.Slice
	DropShadow.SliceCenter = Rect.new(49, 49, 450, 450)

	HeadName.Name = "HeadName"
	HeadName.Parent = Frame
	HeadName.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
	HeadName.BackgroundTransparency = 1.000
	HeadName.BorderColor3 = Color3.fromRGB(0, 0, 0)
	HeadName.BorderSizePixel = 0
	HeadName.Position = UDim2.new(0.0100000342, 0, 0.010000146, 0)
	HeadName.Size = UDim2.new(0.205458686, 0, 0.133462012, 0)
	HeadName.ZIndex = 4
	HeadName.Font = Enum.Font.SourceSansBold
	HeadName.Text = NameScriptHub or "NEVERLOSE"
	HeadName.TextColor3 = NEVERLOSE.Themes.TextColor
	HeadName.TextScaled = true
	HeadName.TextSize = 14.000
	HeadName.TextStrokeColor3 = NEVERLOSE.Themes.MainColor
	HeadName.TextStrokeTransparency = NEVERLOSE.Themes.HeadNameStrokeTransparency or 0.720
	HeadName.TextWrapped = true

	TabButtons.Name = "TabButtons"
	TabButtons.Parent = Frame
	TabButtons.Active = true
	TabButtons.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
	TabButtons.BackgroundTransparency = 1.000
	TabButtons.BorderColor3 = Color3.fromRGB(0, 0, 0)
	TabButtons.BorderSizePixel = 0
	TabButtons.Position = UDim2.new(0.00760957832, 0, 0.143462211, 0)
	TabButtons.Size = UDim2.new(0.20784913, 0, 0.753122032, 0)
	TabButtons.ZIndex = 5
	TabButtons.CanvasSize = UDim2.new(0, 0, 0, 0)
	TabButtons.ScrollBarThickness = 1


	UIListLayout.Parent = TabButtons
	UIListLayout.HorizontalAlignment = Enum.HorizontalAlignment.Center
	UIListLayout.SortOrder = Enum.SortOrder.LayoutOrder
	UIListLayout.Padding = UDim.new(0, 4)

	scrolling_connect(TabButtons)

	TabHose.Name = "TabHose"
	TabHose.Parent = Frame
	TabHose.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
	TabHose.BackgroundTransparency = 1.000
	TabHose.BorderColor3 = Color3.fromRGB(0, 0, 0)
	TabHose.BorderSizePixel = 0
	TabHose.Position = UDim2.new(0.223214373, 0, 0.143462211, 0)
	TabHose.Size = UDim2.new(0.774635077, 0, 0.856537759, 0)
	TabHose.ZIndex = 5

	outlo.Name = "outlo"
	outlo.Parent = Frame
	outlo.AnchorPoint = Vector2.new(1, 0)
	outlo.BackgroundColor3 = NEVERLOSE.Themes.TraceColor
	outlo.BackgroundTransparency = 0.700
	outlo.BorderColor3 = Color3.fromRGB(0, 0, 0)
	outlo.BorderSizePixel = 0
	outlo.Position = UDim2.new(1, 0, 0.136999995, 0)
	outlo.Size = UDim2.new(0.774999976, 0, 0, 1)
	outlo.ZIndex = 4

	UICorner_4.CornerRadius = UDim.new(0, 4)
	UICorner_4.Parent = outlo

	outlo_2.Name = "outlo"
	outlo_2.Parent = Frame
	outlo_2.AnchorPoint = Vector2.new(1, 0.5)
	outlo_2.BackgroundColor3 = NEVERLOSE.Themes.TraceColor
	outlo_2.BackgroundTransparency = 0.700
	outlo_2.BorderColor3 = Color3.fromRGB(0, 0, 0)
	outlo_2.BorderSizePixel = 0
	outlo_2.Position = UDim2.new(0.223908007, 0, 0.5, 0)
	outlo_2.Size = UDim2.new(0, 1, 1, 0)
	outlo_2.ZIndex = 4

	UICorner_5.CornerRadius = UDim.new(0, 4)
	UICorner_5.Parent = outlo_2

	outlo_3.Name = "outlo"
	outlo_3.Parent = Frame
	outlo_3.AnchorPoint = Vector2.new(1, 0)
	outlo_3.BackgroundColor3 = NEVERLOSE.Themes.TraceColor
	outlo_3.BackgroundTransparency = 0.700
	outlo_3.BorderColor3 = Color3.fromRGB(0, 0, 0)
	outlo_3.BorderSizePixel = 0
	outlo_3.Position = UDim2.new(0.223908007, 0, 0.923109949, 0)
	outlo_3.Size = UDim2.new(0.223908007, 0, 0, 1)
	outlo_3.ZIndex = 4

	UICorner_6.CornerRadius = UDim.new(0, 4)
	UICorner_6.Parent = outlo_3

	UserData.Name = "UserData"
	UserData.Parent = Frame
	UserData.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
	UserData.BackgroundTransparency = 1.000
	UserData.BorderColor3 = Color3.fromRGB(0, 0, 0)
	UserData.BorderSizePixel = 0
	UserData.Position = UDim2.new(-0.000179085735, 0, 0.926525652, 0)
	UserData.Size = UDim2.new(0.225179195, 0, 0.0718210712, 0)
	UserData.ZIndex = 5

	UICorner_7.CornerRadius = UDim.new(0, 2)
	UICorner_7.Parent = UserData

	UserImage.Name = "UserImage"
	UserImage.Parent = UserData
	UserImage.AnchorPoint = Vector2.new(0.5, 0.5)
	UserImage.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
	UserImage.BackgroundTransparency = 1.000
	UserImage.BorderColor3 = Color3.fromRGB(0, 0, 0)
	UserImage.BorderSizePixel = 0
	UserImage.Position = UDim2.new(0.150000006, 0, 0.5, 0)
	UserImage.Size = UDim2.new(0.949999988, 0, 0.949999988, 0)
	UserImage.SizeConstraint = Enum.SizeConstraint.RelativeYY
	UserImage.ZIndex = 5
	UserImage.Image = game:GetService('Players'):GetUserThumbnailAsync(LocalPlayer.UserId,Enum.ThumbnailType.HeadShot,Enum.ThumbnailSize.Size150x150)

	UICorner_8.CornerRadius = UDim.new(0.5, 0)
	UICorner_8.Parent = UserImage

	UserName.Name = "UserName"
	UserName.Parent = UserData
	UserName.AnchorPoint = Vector2.new(0, 0.5)
	UserName.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
	UserName.BackgroundTransparency = 1.000
	UserName.BorderColor3 = Color3.fromRGB(0, 0, 0)
	UserName.BorderSizePixel = 0
	UserName.Position = UDim2.new(0.31400001, 0, 0.5, 0)
	UserName.Size = UDim2.new(0.717000008, 0, 0.649999976, 0)
	UserName.ZIndex = 5
	UserName.Font = Enum.Font.SourceSansSemibold
	UserName.Text = LocalPlayer.DisplayName or "https://httpbin.org/get"
	UserName.TextColor3 = NEVERLOSE.Themes.TextColor
	UserName.TextScaled = true
	UserName.TextSize = 14.000
	UserName.TextWrapped = true
	UserName.TextXAlignment = Enum.TextXAlignment.Left

	function WindowFunctinos:AddTabLabel(Label)
		local TabTitle = Instance.new("TextLabel")
		local UIAspectRatioConstraint = Instance.new("UIAspectRatioConstraint")

		TabTitle.Name = "TabTitle"
		TabTitle.Parent = TabButtons
		TabTitle.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
		TabTitle.BackgroundTransparency = 1.000
		TabTitle.BorderColor3 = Color3.fromRGB(0, 0, 0)
		TabTitle.BorderSizePixel = 0
		TabTitle.Size = UDim2.new(0.949999988, 0, 0.5, 0)
		TabTitle.ZIndex = 5
		TabTitle.Font = Enum.Font.SourceSansSemibold
		TabTitle.Text = Label or "Home"
		TabTitle.TextColor3 = NEVERLOSE.Themes.TextColor
		TabTitle.TextScaled = true
		TabTitle.TextSize = 14.000
		TabTitle.TextTransparency = 0.610
		TabTitle.TextWrapped = true
		TabTitle.TextXAlignment = Enum.TextXAlignment.Left

		UIAspectRatioConstraint.Parent = TabTitle
		UIAspectRatioConstraint.AspectRatio = 7.000
		UIAspectRatioConstraint.AspectType = Enum.AspectType.ScaleWithParentSize

		local funcs = {}

		function funcs:Text(a)
			TabTitle.Text=tostring(a)
		end

		function funcs:Delete()
			TabTitle:Destroy()
		end

		return funcs
	end

	function WindowFunctinos:AddTab(TabNameString,IconType)
		local TabFunctions ={}
		local TabButton = Instance.new("Frame")
		local UIAspectRatioConstraint = Instance.new("UIAspectRatioConstraint")
		local UICorner = Instance.new("UICorner")
		local Image = Instance.new("ImageLabel")
		local UICorner_2 = Instance.new("UICorner")
		local Label = Instance.new("TextLabel")

		local cc = NEVERLOSE.Themes.MainColor

		if cc == Color3.fromRGB(0, 172, 247) then
			cc = NEVERLOSE.Themes.BlackgroundColor
		end

		TabButton.Name = "TabButton"
		TabButton.Parent = TabButtons
		TabButton.BackgroundColor3 = cc
		TabButton.BackgroundTransparency = 1
		TabButton.BorderColor3 = Color3.fromRGB(0, 0, 0)
		TabButton.BorderSizePixel = 0
		TabButton.Size = UDim2.new(0.899999976, 0, 0.5, 0)
		TabButton.ZIndex = 5

		UIAspectRatioConstraint.Parent = TabButton
		UIAspectRatioConstraint.AspectRatio = 4.000
		UIAspectRatioConstraint.AspectType = Enum.AspectType.ScaleWithParentSize

		UICorner.CornerRadius = UDim.new(0, 3)
		UICorner.Parent = TabButton

		Image.Name = "Image"
		Image.Parent = TabButton
		Image.AnchorPoint = Vector2.new(0, 0.5)
		Image.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
		Image.BackgroundTransparency = 1.000
		Image.BorderColor3 = Color3.fromRGB(0, 0, 0)
		Image.BorderSizePixel = 0
		Image.Position = UDim2.new(0.0149999997, 0, 0.5, 0)
		Image.Size = UDim2.new(0.850000024, 0, 0.800000012, 0)
		Image.SizeConstraint = Enum.SizeConstraint.RelativeYY
		Image.ZIndex = 5

		Image.ImageColor3 = NEVERLOSE.Themes.MainColor
		Image.ImageRectOffset = Vector2.new(205, 565)
		Image.ImageRectSize = Vector2.new(35, 35)

		GetImageData(tostring(IconType),Image)

		UICorner_2.CornerRadius = UDim.new(0, 3)
		UICorner_2.Parent = Image

		Label.Name = "Label"
		Label.Parent = TabButton
		Label.AnchorPoint = Vector2.new(0.5, 0.5)
		Label.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
		Label.BackgroundTransparency = 1.000
		Label.BorderColor3 = Color3.fromRGB(0, 0, 0)
		Label.BorderSizePixel = 0
		Label.Position = UDim2.new(0.640507042, 0, 0.500000238, 0)
		Label.Size = UDim2.new(0.718986034, 0, 0.600000024, 0)
		Label.ZIndex = 5
		Label.Font = Enum.Font.SourceSansBold
		Label.Text = TabNameString or "Index.json"
		Label.TextColor3 = NEVERLOSE.Themes.TextColor
		Label.TextScaled = true
		Label.TextSize = 14.000
		Label.TextWrapped = true
		Label.TextXAlignment = Enum.TextXAlignment.Left
		Label.TextYAlignment = Enum.TextYAlignment.Top

		local Tab = Instance.new("Frame")
		local Left = Instance.new("ScrollingFrame")
		local UIListLayout = Instance.new("UIListLayout")
		local Right = Instance.new("ScrollingFrame")
		local UIListLayout_2 = Instance.new("UIListLayout")

		Tab.Name = "Tab"
		Tab.Parent = TabHose
		Tab.AnchorPoint = Vector2.new(0.5, 0.5)
		Tab.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
		Tab.BackgroundTransparency = 1.000
		Tab.BorderColor3 = Color3.fromRGB(0, 0, 0)
		Tab.BorderSizePixel = 0
		Tab.ClipsDescendants = true
		Tab.Position = UDim2.new(0.5, 0, 0.5, 0)
		Tab.Size = UDim2.new(0.99000001, 0, 0.99000001, 0)
		Tab.ZIndex = 6

		Left.Name = "Left"
		Left.Parent = Tab
		Left.Active = true
		Left.AnchorPoint = Vector2.new(0, 0.5)
		Left.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
		Left.BackgroundTransparency = 1.000
		Left.BorderColor3 = Color3.fromRGB(0, 0, 0)
		Left.BorderSizePixel = 0
		Left.ClipsDescendants = false
		Left.Position = UDim2.new(0, 0, 0.5, 0)
		Left.Size = UDim2.new(0.499000001, 0, 0.980000019, 0)
		Left.ZIndex = 5
		Left.ScrollBarThickness = 0
		Left.VerticalScrollBarPosition = Enum.VerticalScrollBarPosition.Left

		UIListLayout.Parent = Left
		UIListLayout.HorizontalAlignment = Enum.HorizontalAlignment.Center
		UIListLayout.SortOrder = Enum.SortOrder.LayoutOrder
		UIListLayout.Padding = UDim.new(0, 5)

		Right.Name = "Right"
		Right.Parent = Tab
		Right.Active = true
		Right.AnchorPoint = Vector2.new(1, 0.5)
		Right.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
		Right.BackgroundTransparency = 1.000
		Right.BorderColor3 = Color3.fromRGB(0, 0, 0)
		Right.BorderSizePixel = 0
		Right.ClipsDescendants = false
		Right.Position = UDim2.new(1, 0, 0.5, 0)
		Right.Size = UDim2.new(0.499000001, 0, 0.980000019, 0)
		Right.ZIndex = 5
		Right.ScrollBarThickness = 0

		UIListLayout_2.Parent = Right
		UIListLayout_2.HorizontalAlignment = Enum.HorizontalAlignment.Center
		UIListLayout_2.SortOrder = Enum.SortOrder.LayoutOrder
		UIListLayout_2.Padding = UDim.new(0, 5)

		scrolling_connect(Right)
		scrolling_connect(Left)

		local function bedisea()
			if headd2text then
				TweenService:Create(headd2text,TweenInfo.new(.1),{
					TextTransparency = 0.1,
					TextStrokeTransparency=.95
				}):Play()
				task.wait(.11)
				TweenService:Create(headd2text,TweenInfo.new(.1),{
					TextTransparency = 0,
					TextStrokeTransparency=.9
				}):Play()
			end
		end

		local function tabcall(val,bas)
			if val then

				if not Tab.Visible then
					task.spawn(bedisea)
					Tab.Position=UDim2.new(0.5,0,0,0)
					Tab.Size=UDim2.new(0.85, 0, 0, 0)
				end

				Tab.Visible=true
				TweenService:Create(Tab,TweenInfo.new(.3,Enum.EasingStyle.Quint,Enum.EasingDirection.Out),{Position = UDim2.new(0.5, 0, 0.5, 0)}):Play()
				TweenService:Create(Tab,TweenInfo.new(.75,Enum.EasingStyle.Quint,Enum.EasingDirection.Out),{Size = UDim2.new(0.99000001, 0, 0.99000001, 0)}):Play()
				TweenService:Create(TabButton,TweenInfo.new(0.3),{BackgroundTransparency=0.6}):Play()
			else
				Tab.Visible=false
				TweenService:Create(Tab,TweenInfo.new(.5),{Position = UDim2.new(0.5, 0, 1.5, 0)}):Play()
				TweenService:Create(TabButton,TweenInfo.new(0.3),{BackgroundTransparency=1}):Play()
			end
		end

		if #Tabs==0 then
			tabcall(true,0)
		else
			tabcall(false,0)
		end

		table.insert(Tabs,{Tab,tabcall})

		cretate_button(TabButton).MouseButton1Click:Connect(function()
			for i,v in ipairs(Tabs) do
				if v[1]==Tab then
					v[2](true,0.4)
					task.wait()
				else
					v[2](false,0.4)
				end
			end
		end) 

		function TabFunctions:AddSection(SectionName,parentname)
			parentname = parentname or "left"

			local Section = Instance.new("Frame")
			local UICorner = Instance.new("UICorner")
			local UIStroke = Instance.new("UIStroke")
			local Header = Instance.new("TextLabel")
			local UIListLayout = Instance.new("UIListLayout")
			local lay = Instance.new("Frame")
			local UICorner_2 = Instance.new("UICorner")

			Section.Name = "Section"
			Section.Parent = (parentname=="left"and Left) or (parentname=="right"and Right) or nil

			Section.BackgroundColor3 = NEVERLOSE.Themes.SectionColor
			Section.BorderColor3 = Color3.fromRGB(0, 0, 0)
			Section.BorderSizePixel = 0
			Section.Size = UDim2.new(0.970000029, 0, 0, 0)
			Section.ZIndex = 5

			UICorner.CornerRadius = UDim.new(0, 3)
			UICorner.Parent = Section

			UIStroke.Color = NEVERLOSE.Themes.StrokeColor
			UIStroke.ApplyStrokeMode = Enum.ApplyStrokeMode.Border
			UIStroke.Parent = Section

			Header.Name = "Header"
			Header.Parent = Section
			Header.AnchorPoint = Vector2.new(0.5, 0)
			Header.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
			Header.BackgroundTransparency = 1.000
			Header.BorderColor3 = Color3.fromRGB(0, 0, 0)
			Header.BorderSizePixel = 0
			Header.Position = UDim2.new(0.5, 0, 0.100000001, 0)
			Header.Size = UDim2.new(0.949999988, 0, 0, 15)
			Header.ZIndex = 5
			Header.Font = Enum.Font.SourceSansSemibold
			Header.Text = SectionName or "Section"
			Header.TextColor3 = NEVERLOSE.Themes.TextColor
			Header.TextScaled = true
			Header.TextSize = 14.000
			Header.TextWrapped = true
			Header.TextXAlignment = Enum.TextXAlignment.Left
			Header.TextTransparency=1
			TweenService:Create(Header,TweenInfo.new(0.3),{TextTransparency=0}):Play()

			UIListLayout.Parent = Section
			UIListLayout.HorizontalAlignment = Enum.HorizontalAlignment.Center
			UIListLayout.SortOrder = Enum.SortOrder.LayoutOrder
			UIListLayout.Padding = UDim.new(0, 4)

			lay.Name = "lay"
			lay.Parent = Section
			lay.BackgroundColor3 = NEVERLOSE.Themes.StrokeColor
			lay.BorderColor3 = Color3.fromRGB(0, 0, 0)
			lay.BorderSizePixel = 0
			lay.Size = UDim2.new(0.970000029, 0, 0, 2)
			lay.ZIndex = 5
			lay.BackgroundTransparency=1
			Section.BackgroundTransparency=1
			UIStroke.Transparency=1

			TweenService:Create(lay,TweenInfo.new(1),{BackgroundTransparency=0}):Play()
			TweenService:Create(Section,TweenInfo.new(1),{BackgroundTransparency=0}):Play()
			TweenService:Create(UIStroke,TweenInfo.new(1),{Transparency=0}):Play()

			local section_value = true
			UICorner_2.CornerRadius = UDim.new(0, 3)
			UICorner_2.Parent = lay

			local function update_section_size(va)
				if not va then
					if Section.Visible and section_value then
						local a=math.ceil(1)

						for i,v:Frame|TextLabel in ipairs(Section:GetChildren()) do
							if v:isA('Frame') or v:isA('TextLabel') then
								if v.Visible then
									pcall(function()
										a=a+v.AbsoluteSize.Y*1.2
									end)
								end
							end
						end

						TweenService:Create(Section,TweenInfo.new(0.2),{Size=UDim2.new(0.97,0,0,15+a)}):Play()
					end
				else
					local a=math.ceil(1)

					for i,v:Frame|TextLabel in ipairs(Section:GetChildren()) do
						if v:isA('Frame') or v:isA('TextLabel') then
							if v.Visible then
								pcall(function()
									a=a+v.AbsoluteSize.Y*1.2
								end)
							end
						end
					end

					TweenService:Create(Section,TweenInfo.new(0.2),{Size=UDim2.new(0.97,0,0,15+a)}):Play()
				end
			end

			table.insert(NEVERLOSE.auto_function,update_section_size)

			Section:GetPropertyChangedSignal('Size'):Connect(function()
				if Section.Size.Y.Offset <= 1 then
					Section.Visible=false
				else
					Section.Visible=true
				end
			end)

			Section.InputBegan:Connect(update_section_size)

			update_section_size()

			local sectionfunc = {}

			function sectionfunc:AddButton(ButtonName,callback)
				callback=callback or function()

				end

				local Button = Instance.new("Frame")
				local UIAspectRatioConstraint = Instance.new("UIAspectRatioConstraint")
				local UICorner = Instance.new("UICorner")
				local LabelText = Instance.new("TextLabel")
				local UIStroke = Instance.new("UIStroke")

				Button.Name = "Button"
				Button.Parent = Section
				Button.BackgroundColor3 = NEVERLOSE.Themes.ButtonBlackgroundColor
				Button.BackgroundTransparency = 0.550
				Button.BorderColor3 = Color3.fromRGB(0, 0, 0)
				Button.BorderSizePixel = 0
				Button.Position = UDim2.new(0.0500000231, 0, 0.601014614, 0)
				Button.Size = UDim2.new(0.899999976, 0, -0.351014495, 0)
				Button.ZIndex = 5

				UIAspectRatioConstraint.Parent = Button
				UIAspectRatioConstraint.AspectRatio = 7.000
				UIAspectRatioConstraint.AspectType = Enum.AspectType.ScaleWithParentSize

				UICorner.CornerRadius = UDim.new(0, 3)
				UICorner.Parent = Button

				LabelText.Name = "LabelText"
				LabelText.Parent = Button
				LabelText.AnchorPoint = Vector2.new(0.5, 0.5)
				LabelText.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
				LabelText.BackgroundTransparency = 1.000
				LabelText.BorderColor3 = Color3.fromRGB(0, 0, 0)
				LabelText.BorderSizePixel = 0
				LabelText.Position = UDim2.new(0.5, 0, 0.5, 0)
				LabelText.Size = UDim2.new(0.899999976, 0, 0.75, 0)
				LabelText.ZIndex = 6
				LabelText.Font = Enum.Font.SourceSansSemibold
				LabelText.Text = ButtonName or"Kill all"
				LabelText.TextColor3 = NEVERLOSE.Themes.TextColor
				LabelText.TextScaled = true
				LabelText.TextSize = 14.000
				LabelText.TextTransparency = 0.300
				LabelText.TextWrapped = true

				UIStroke.Thickness = 0.500
				UIStroke.Color = NEVERLOSE.Themes.StrokeColor
				UIStroke.ApplyStrokeMode = Enum.ApplyStrokeMode.Border
				UIStroke.Parent = Button

				cretate_button(Button).MouseButton1Click:Connect(function()
					callback()
				end)

				Button.MouseEnter:Connect(function()
					TweenService:Create(LabelText,TweenInfo.new(0.1),{TextTransparency=0}):Play()
				end)

				Button.MouseLeave:Connect(function()
					TweenService:Create(LabelText,TweenInfo.new(0.1),{TextTransparency=0.3}):Play()
				end)

				local button_func={}
				function button_func:Fire(...)
					callback(...)
				end

				function button_func:Text(a)
					LabelText.Text=tostring(a)
				end

				return button_func
			end

			function sectionfunc:AddLabel(LabelNameString)
				local Label = Instance.new("Frame")
				local UIAspectRatioConstraint = Instance.new("UIAspectRatioConstraint")
				local UICorner = Instance.new("UICorner")
				local LabelText = Instance.new("TextLabel")

				Label.Name = "Label"
				Label.Parent = Section
				Label.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
				Label.BackgroundTransparency = 1.000
				Label.BorderColor3 = Color3.fromRGB(0, 0, 0)
				Label.BorderSizePixel = 0
				Label.Size = UDim2.new(0.899999976, 0, 0.5, 0)
				Label.ZIndex = 5

				UIAspectRatioConstraint.Parent = Label
				UIAspectRatioConstraint.AspectRatio = 6.000
				UIAspectRatioConstraint.AspectType = Enum.AspectType.ScaleWithParentSize

				UICorner.CornerRadius = UDim.new(0, 3)
				UICorner.Parent = Label

				LabelText.Name = "LabelText"
				LabelText.Parent = Label
				LabelText.AnchorPoint = Vector2.new(0.5, 0.5)
				LabelText.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
				LabelText.BackgroundTransparency = 1.000
				LabelText.BorderColor3 = Color3.fromRGB(0, 0, 0)
				LabelText.BorderSizePixel = 0
				LabelText.Position = UDim2.new(0.5, 0, 0.5, 0)
				LabelText.Size = UDim2.new(1, 0, 0.649999976, 0)
				LabelText.ZIndex = 6
				LabelText.Font = Enum.Font.SourceSansSemibold
				LabelText.Text = LabelNameString or"Label"
				LabelText.TextColor3 = NEVERLOSE.Themes.TextColor
				LabelText.TextScaled = true
				LabelText.TextSize = 14.000
				LabelText.TextTransparency = 0.300
				LabelText.TextWrapped = true
				LabelText.TextXAlignment = Enum.TextXAlignment.Left
				update_section_size(

				)

				LabelText:GetPropertyChangedSignal('TextTransparency'):Connect(function()
					if LabelText.TextTransparency <= 0.99 then
						Label.Visible=true
					else
						Label.Visible=false
					end
				end)

				local button_func = {}
				function button_func:Text(a)
					LabelText.Text=tostring(a)
				end

				function button_func:Status(val)
					if val then
						TweenService:Create(Label,TweenInfo.new(1,Enum.EasingStyle.Quint),{Size = UDim2.new(0.899999976, 0, 0.5, 0)}):Play()
						TweenService:Create(UIAspectRatioConstraint,TweenInfo.new(.1,Enum.EasingStyle.Quint),{AspectRatio = 6}):Play()
						TweenService:Create(LabelText,TweenInfo.new(0.7,Enum.EasingStyle.Quint),{TextTransparency = 0.3}):Play()
					else
						TweenService:Create(Label,TweenInfo.new(.8,Enum.EasingStyle.Quint),{Size = UDim2.new(0,0,0,0)}):Play()
						TweenService:Create(LabelText,TweenInfo.new(1,Enum.EasingStyle.Quint),{TextTransparency = 1}):Play()
					end
				end

				return button_func
			end

			function sectionfunc:AddToggle(ToggleName,Default,callback)
				callback=callback or function()

				end

				local Toggle = Instance.new("Frame")
				local UIAspectRatioConstraint = Instance.new("UIAspectRatioConstraint")
				local UICorner = Instance.new("UICorner")
				local LabelText = Instance.new("TextLabel")
				local Effect = Instance.new("Frame")
				local UICorner_2 = Instance.new("UICorner")
				local Icon = Instance.new("Frame")
				local UICorner_3 = Instance.new("UICorner")

				Toggle.Name = "Toggle"
				Toggle.Parent = Section
				Toggle.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
				Toggle.BackgroundTransparency = 1.000
				Toggle.BorderColor3 = Color3.fromRGB(0, 0, 0)
				Toggle.BorderSizePixel = 0
				Toggle.Position = UDim2.new(0.0500000231, 0, 0.601014614, 0)
				Toggle.Size = UDim2.new(0.899999976, 0, -0.351014495, 0)
				Toggle.ZIndex = 5

				UIAspectRatioConstraint.Parent = Toggle
				UIAspectRatioConstraint.AspectRatio = 7.000
				UIAspectRatioConstraint.AspectType = Enum.AspectType.ScaleWithParentSize

				UICorner.CornerRadius = UDim.new(0, 3)
				UICorner.Parent = Toggle

				LabelText.Name = "LabelText"
				LabelText.Parent = Toggle
				LabelText.AnchorPoint = Vector2.new(0.5, 0.5)
				LabelText.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
				LabelText.BackgroundTransparency = 1.000
				LabelText.BorderColor3 = Color3.fromRGB(0, 0, 0)
				LabelText.BorderSizePixel = 0
				LabelText.Position = UDim2.new(0.38587454, 0, 0.499999583, 0)
				LabelText.Size = UDim2.new(0.772000015, 0, 0.75, 0)
				LabelText.ZIndex = 6
				LabelText.Font = Enum.Font.SourceSansSemibold
				LabelText.Text = ToggleName or "Label-Test"
				LabelText.TextColor3 = NEVERLOSE.Themes.TextColor
				LabelText.TextScaled = true
				LabelText.TextSize = 14.000
				LabelText.TextWrapped = true
				LabelText.TextXAlignment = Enum.TextXAlignment.Left

				Effect.Name = "Effect"
				Effect.Parent = Toggle
				Effect.AnchorPoint = Vector2.new(0, 0.5)
				Effect.BackgroundColor3 = NEVERLOSE.Themes.MainColorDrop
				Effect.BorderColor3 = Color3.fromRGB(0, 0, 0)
				Effect.BorderSizePixel = 0
				Effect.Position = UDim2.new(0.800000012, 0, 0.5, 0)
				Effect.Size = UDim2.new(0.150000006, 0, 0.5, 0)
				Effect.ZIndex = 6

				UICorner_2.CornerRadius = UDim.new(0.5, 0)
				UICorner_2.Parent = Effect

				Icon.Name = "Icon"
				Icon.Parent = Effect
				Icon.AnchorPoint = Vector2.new(0.5, 0.5)
				Icon.BackgroundColor3 = NEVERLOSE.Themes.MainColor
				Icon.BorderColor3 = Color3.fromRGB(0, 0, 0)
				Icon.BorderSizePixel = 0
				Icon.Position = UDim2.new(0.75, 0, 0.5, 0)
				Icon.Size = UDim2.new(1, 0, 1, 0)
				Icon.SizeConstraint = Enum.SizeConstraint.RelativeYY
				Icon.ZIndex = 7

				UICorner_3.CornerRadius = UDim.new(0.5, 0)
				UICorner_3.Parent = Icon

				local function toggleval(val,timea)
					if val then
						TweenService:Create(LabelText,TweenInfo.new(timea),{TextTransparency=0}):Play()
						TweenService:Create(Icon,TweenInfo.new(timea),{Position=UDim2.new(0.75,0,0.5,0),BackgroundColor3=NEVERLOSE.Themes.MainColor}):Play();
					else
						TweenService:Create(LabelText,TweenInfo.new(timea),{TextTransparency=0.3}):Play()
						TweenService:Create(Icon,TweenInfo.new(timea),{Position=UDim2.new(0.25,0,0.5,0),BackgroundColor3=Color3.fromRGB(194, 194, 194)}):Play();
					end
				end

				toggleval(Default,0)
				callback(Default)
				
				cretate_button(Toggle).MouseButton1Click:Connect(function()
					Default = not Default
					toggleval(Default,0.1)
					callback(Default)
				end)

				local button_func = {}
				function button_func:Text(a)
					LabelText.Text=tostring(a)
				end

				function button_func:Value(a)
					Default=a
					toggleval(a,0.1)
					callback(a)
				end

				function button_func:Status(val)
					if val then
						local dex = (Default==true and 0) or .3
						TweenService:Create(Toggle,TweenInfo.new(.5,Enum.EasingStyle.Quint),{Size = UDim2.new(0.899999976, 0, -0.351014495, 0)}):Play()
						TweenService:Create(LabelText,TweenInfo.new(1,Enum.EasingStyle.Quint),{TextTransparency = dex}):Play()

						TweenService:Create(Effect,TweenInfo.new(0.4),{BackgroundTransparency=0}):Play()
						TweenService:Create(Icon,TweenInfo.new(0.4),{BackgroundTransparency=0}):Play()

					else
						TweenService:Create(Effect,TweenInfo.new(0.4),{BackgroundTransparency=1}):Play()
						TweenService:Create(Icon,TweenInfo.new(0.4),{BackgroundTransparency=1}):Play()

						TweenService:Create(Toggle,TweenInfo.new(1.5,Enum.EasingStyle.Quint),{Size = UDim2.new(0,0,0,0)}):Play()
						TweenService:Create(LabelText,TweenInfo.new(1,Enum.EasingStyle.Quint),{TextTransparency = 1}):Play()
					end
				end

				return button_func

			end

			function sectionfunc:AddKeybind(KeybindNameString,Default,callback)
				callback=callback or function()

				end

				local function gt(a:Enum.KeyCode)
					if not a then
						return "None"

					else
						return a.Name
					end
				end

				local Keybind = Instance.new("Frame")
				local UIAspectRatioConstraint = Instance.new("UIAspectRatioConstraint")
				local UICorner = Instance.new("UICorner")
				local LabelText = Instance.new("TextLabel")
				local BrindText = Instance.new("Frame")
				local UICorner_2 = Instance.new("UICorner")
				local UIStroke = Instance.new("UIStroke")
				local ValueText = Instance.new("TextLabel")

				Keybind.Name = "Keybind"
				Keybind.Parent = Section
				Keybind.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
				Keybind.BackgroundTransparency = 1.000
				Keybind.BorderColor3 = Color3.fromRGB(0, 0, 0)
				Keybind.BorderSizePixel = 0
				Keybind.Position = UDim2.new(0.0500000231, 0, 0.601014614, 0)
				Keybind.Size = UDim2.new(0.899999976, 0, -0.351014495, 0)
				Keybind.ZIndex = 5

				UIAspectRatioConstraint.Parent = Keybind
				UIAspectRatioConstraint.AspectRatio = 7.000
				UIAspectRatioConstraint.AspectType = Enum.AspectType.ScaleWithParentSize

				UICorner.CornerRadius = UDim.new(0, 3)
				UICorner.Parent = Keybind

				LabelText.Name = "LabelText"
				LabelText.Parent = Keybind
				LabelText.AnchorPoint = Vector2.new(0.5, 0.5)
				LabelText.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
				LabelText.BackgroundTransparency = 1.000
				LabelText.BorderColor3 = Color3.fromRGB(0, 0, 0)
				LabelText.BorderSizePixel = 0
				LabelText.Position = UDim2.new(0.296665907, 0, 0.499999106, 0)
				LabelText.Size = UDim2.new(0.593582749, 0, 0.75, 0)
				LabelText.ZIndex = 6
				LabelText.Font = Enum.Font.SourceSansSemibold
				LabelText.Text = KeybindNameString or ''
				LabelText.TextColor3 = NEVERLOSE.Themes.TextColor
				LabelText.TextScaled = true
				LabelText.TextSize = 14.000
				LabelText.TextWrapped = true
				LabelText.TextXAlignment = Enum.TextXAlignment.Left
				LabelText.TextTransparency=.3
				BrindText.Name = "BrindText"
				BrindText.Parent = Keybind
				BrindText.AnchorPoint = Vector2.new(1, 0.5)
				BrindText.BackgroundColor3 = Color3.fromRGB(26, 26, 26)
				BrindText.BackgroundTransparency = 0.500
				BrindText.BorderColor3 = Color3.fromRGB(0, 0, 0)
				BrindText.BorderSizePixel = 0
				BrindText.Position = UDim2.new(0.998, 0, 0.5, 0)
				BrindText.Size = UDim2.new(0.150000006, 0, 0.5, 0)
				BrindText.ZIndex = 6

				UICorner_2.CornerRadius = UDim.new(0, 3)
				UICorner_2.Parent = BrindText

				UIStroke.Thickness = 0.500
				UIStroke.Color = NEVERLOSE.Themes.StrokeColor
				UIStroke.ApplyStrokeMode = Enum.ApplyStrokeMode.Border
				UIStroke.Parent = BrindText

				ValueText.Name = "ValueText"
				ValueText.Parent = BrindText
				ValueText.AnchorPoint = Vector2.new(0.5, 0.5)
				ValueText.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
				ValueText.BackgroundTransparency = 1.000
				ValueText.BorderColor3 = Color3.fromRGB(0, 0, 0)
				ValueText.BorderSizePixel = 0
				ValueText.Position = UDim2.new(0.5, 0, 0.5, 0)
				ValueText.Size = UDim2.new(0.980000019, 0, 0.998000026, 0)
				ValueText.ZIndex = 6
				ValueText.Font = Enum.Font.SourceSansSemibold
				ValueText.Text = gt(Default)
				ValueText.TextColor3 = NEVERLOSE.Themes.TextColor
				ValueText.TextScaled = true
				ValueText.TextSize = 14.000
				ValueText.TextWrapped = true

				local function UpdateText()
					local size = TextService:GetTextSize(ValueText.Text,ValueText.TextSize,ValueText.Font,Vector2.new(math.huge,math.huge))

					TweenService:Create(BrindText,TweenInfo.new(0.2),{Size = UDim2.new(0, size.X + 1, 0.550000012, 0)}):Play()
				end

				local Binding = false
				cretate_button(Keybind).MouseButton1Click:Connect(function()
					if Binding then
						return
					end
					Binding =  true

					local targetloadded = nil

					local hook = InputService.InputBegan:Connect(function(is)
						if is.KeyCode ~= Enum.KeyCode.Unknown then
							targetloadded = is.KeyCode
						end
					end)
					TweenService:Create(LabelText,TweenInfo.new(0.3),{TextTransparency=0}):Play()
					ValueText.Text = "..."
					repeat task.wait() UpdateText() until targetloadded or not Binding
					TweenService:Create(LabelText,TweenInfo.new(0.3),{TextTransparency=0.3}):Play()
					Binding =false
					if hook then
						hook:Disconnect()
					end
					if targetloadded then
						ValueText.Text = gt(targetloadded)
						Default = targetloadded
						UpdateText() 
						callback(targetloadded)
					end
					return
				end)

				UpdateText()

				-- Fire the keybind callback when the currently bound key is pressed.
				InputService.InputBegan:Connect(function(Input, GameProcessed)
					if Binding then
						return
					end

					if Input.KeyCode == Default then
						callback(Input.KeyCode)
					end
				end)

				local KeybindFunctions = {}

				function KeybindFunctions:Text(a)
					LabelText.Text = tostring(a)
					UpdateText()
				end

				function KeybindFunctions:Value(l)
					ValueText.Text = gt(l)
					Default = l
					UpdateText() 
					callback(l)
				end

				return KeybindFunctions
			end

			function sectionfunc:AddSlider(SliderNameString,Min,Max,Default,callback)
				Min=Min or 1
				Max=Max or 100
				Default=Default or Min
				callback=callback or function()

				end

				local Slider = Instance.new("Frame")
				local UIAspectRatioConstraint = Instance.new("UIAspectRatioConstraint")
				local UICorner = Instance.new("UICorner")
				local LabelText = Instance.new("TextLabel")
				local Box = Instance.new("Frame")
				local UICorner_2 = Instance.new("UICorner")
				local UIStroke = Instance.new("UIStroke")
				local ValueText = Instance.new("TextLabel")
				local MoveFrame = Instance.new("Frame")
				local UICorner_3 = Instance.new("UICorner")
				local Inline = Instance.new("Frame")
				local UICorner_4 = Instance.new("UICorner")
				local Cir = Instance.new("Frame")
				local UICorner_5 = Instance.new("UICorner")
				local Frame = Instance.new("Frame")

				Slider.Name = "Slider"
				Slider.Parent = Section
				Slider.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
				Slider.BackgroundTransparency = 1.000
				Slider.BorderColor3 = Color3.fromRGB(0, 0, 0)
				Slider.BorderSizePixel = 0
				Slider.Position = UDim2.new(0.0500000231, 0, 0.601014614, 0)
				Slider.Size = UDim2.new(0.899999976, 0, -0.351014495, 0)
				Slider.ZIndex = 5

				UIAspectRatioConstraint.Parent = Slider
				UIAspectRatioConstraint.AspectRatio = 7.000
				UIAspectRatioConstraint.AspectType = Enum.AspectType.ScaleWithParentSize

				UICorner.CornerRadius = UDim.new(0, 3)
				UICorner.Parent = Slider

				LabelText.Name = "LabelText"
				LabelText.Parent = Slider
				LabelText.AnchorPoint = Vector2.new(0.5, 0.5)
				LabelText.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
				LabelText.BackgroundTransparency = 1.000
				LabelText.BorderColor3 = Color3.fromRGB(0, 0, 0)
				LabelText.BorderSizePixel = 0
				LabelText.Position = UDim2.new(0.238462642, 0, 0.499999374, 0)
				LabelText.Size = UDim2.new(0.477176398, 0, 0.75, 0)
				LabelText.ZIndex = 6
				LabelText.Font = Enum.Font.SourceSansSemibold
				LabelText.Text = SliderNameString or "Control"
				LabelText.TextColor3 = NEVERLOSE.Themes.TextColor
				LabelText.TextScaled = true
				LabelText.TextSize = 14.000
				LabelText.TextWrapped = true
				LabelText.TextXAlignment = Enum.TextXAlignment.Left
				LabelText.TextTransparency=.3

				Box.Name = "Box"
				Box.Parent = Slider
				Box.AnchorPoint = Vector2.new(0, 0.5)
				Box.BackgroundColor3 = NEVERLOSE.Themes.ButtonBlackgroundColor
				Box.BackgroundTransparency = 0.100
				Box.BorderColor3 = Color3.fromRGB(0, 0, 0)
				Box.BorderSizePixel = 0
				Box.Position = UDim2.new(0.800000012, 0, 0.5, 0)
				Box.Size = UDim2.new(0.150000006, 0, 0.5, 0)
				Box.ZIndex = 6

				UICorner_2.CornerRadius = UDim.new(0, 3)
				UICorner_2.Parent = Box

				UIStroke.Thickness = 0.500
				UIStroke.Color = NEVERLOSE.Themes.StrokeColor
				UIStroke.ApplyStrokeMode = Enum.ApplyStrokeMode.Border
				UIStroke.Parent = Box

				ValueText.Name = "ValueText"
				ValueText.Parent = Box
				ValueText.AnchorPoint = Vector2.new(0.5, 0.5)
				ValueText.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
				ValueText.BackgroundTransparency = 1.000
				ValueText.BorderColor3 = Color3.fromRGB(0, 0, 0)
				ValueText.BorderSizePixel = 0
				ValueText.Position = UDim2.new(0.5, 0, 0.5, 0)
				ValueText.Size = UDim2.new(0.99000001, 0, 0.99000001, 0)
				ValueText.ZIndex = 6
				ValueText.Font = Enum.Font.SourceSansSemibold
				ValueText.Text = tostring(Default)
				ValueText.TextColor3 = NEVERLOSE.Themes.TextColor
				ValueText.TextScaled = true
				ValueText.TextSize = 14.000
				ValueText.TextWrapped = true

				MoveFrame.Name = "MoveFrame"
				MoveFrame.Parent = Slider
				MoveFrame.AnchorPoint = Vector2.new(0, 0.5)
				MoveFrame.BackgroundColor3 = NEVERLOSE.Themes.MainColorDrop
				MoveFrame.BorderColor3 = Color3.fromRGB(0, 0, 0)
				MoveFrame.BorderSizePixel = 0
				MoveFrame.ClipsDescendants = true
				MoveFrame.Position = UDim2.new(0.477050841, 0, 0.50000006, 0)
				MoveFrame.Size = UDim2.new(0.290949076, 0, 0.099999994, 0)
				MoveFrame.ZIndex = 5

				UICorner_3.CornerRadius = UDim.new(0, 3)
				UICorner_3.Parent = MoveFrame

				Inline.Name = "Inline"
				Inline.Parent = MoveFrame
				Inline.AnchorPoint = Vector2.new(0, 0.5)
				Inline.BackgroundColor3 = NEVERLOSE.Themes.MainColor
				Inline.BorderColor3 = Color3.fromRGB(0, 0, 0)
				Inline.BorderSizePixel = 0
				Inline.Position = UDim2.new(0, 0, 0.5, 0)
				Inline.Size = UDim2.new((Default/Max), 0, 1, 0)
				Inline.ZIndex = 5

				UICorner_4.CornerRadius = UDim.new(0, 3)
				UICorner_4.Parent = Inline

				Cir.Name = "Cir"
				Cir.Parent = Inline
				Cir.AnchorPoint = Vector2.new(1, 0.5)
				Cir.BackgroundColor3 = NEVERLOSE.Themes.MainColor
				Cir.BorderColor3 = Color3.fromRGB(0, 0, 0)
				Cir.BorderSizePixel = 0
				Cir.Position = UDim2.new(1, 0, 0.5, 0)
				Cir.Rotation = 0.010
				Cir.Size = UDim2.new(3, 0, 3, 0)
				Cir.SizeConstraint = Enum.SizeConstraint.RelativeYY
				Cir.ZIndex = 5

				UICorner_5.CornerRadius = UDim.new(0.5, 0)
				UICorner_5.Parent = Cir

				Frame.Parent = Slider
				Frame.AnchorPoint = Vector2.new(0, 0.5)
				Frame.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
				Frame.BackgroundTransparency = 1.000
				Frame.BorderColor3 = Color3.fromRGB(0, 0, 0)
				Frame.BorderSizePixel = 0
				Frame.Position = UDim2.new(0.477050841, 0, 0.500000358, 0)
				Frame.Size = UDim2.new(0.322948873, 0, 0.900000036, 0)
				Frame.ZIndex = 5

				local danger = false

				local function update(Input)
					local SizeScale = math.clamp((((Input.Position.X) - MoveFrame.AbsolutePosition.X) / MoveFrame.AbsoluteSize.X), 0, 1)
					local Valuea = math.floor(((Max - Min) * SizeScale) + Min)
					local Size = UDim2.fromScale(math.clamp(SizeScale+0.15,0,1), 1)
					ValueText.Text = tostring(Valuea)
					TweenService:Create(Inline,TweenInfo.new(0.1),{Size = Size}):Play()
					callback(Valuea)
				end

				Frame.InputBegan:Connect(function(Input)
					if Input.UserInputType == Enum.UserInputType.MouseButton1 or Input.UserInputType == Enum.UserInputType.Touch then
						danger = true
						update(Input)
						TweenService:Create(LabelText,TweenInfo.new(0.1),{TextTransparency=0}):Play()
					end
				end)

				Frame.InputEnded:Connect(function(Input)
					if Input.UserInputType == Enum.UserInputType.MouseButton1 or Input.UserInputType == Enum.UserInputType.Touch then
						danger = false
						TweenService:Create(LabelText,TweenInfo.new(0.1),{TextTransparency=0.3}):Play()
					end
				end)

				InputService.InputChanged:Connect(function(Input)
					if danger then
						if (Input.UserInputType==Enum.UserInputType.MouseMovement or Input.UserInputType==Enum.UserInputType.Touch)  then
							update(Input)
						end
					end
				end)

				local func={}

				function func:Value(s)
					ValueText.Text = tostring(s)
					Inline.Size=UDim2.fromScale((s/Max),1)

					callback(s)
				end

				function func:Text(t)
					LabelText.Text=tostring(t)
				end

				update_section_size()
				return func
			end

			function sectionfunc:AddDropdown(DropdownName,data,Default,callback)
				data=data or {}
				Default=Default or data[1]
				callback=callback or function()

				end

				local Dropdown = Instance.new("Frame")
				local UIAspectRatioConstraint = Instance.new("UIAspectRatioConstraint")
				local UICorner = Instance.new("UICorner")
				local LabelText = Instance.new("TextLabel")
				local TopBar = Instance.new("Frame")
				local UICorner_2 = Instance.new("UICorner")
				local UIStroke = Instance.new("UIStroke")
				local ValueText = Instance.new("TextLabel")
				local Icon = Instance.new("TextLabel")
				local DownBar = Instance.new("Frame")
				local UICorner_3 = Instance.new("UICorner")
				local UIStroke_2 = Instance.new("UIStroke")
				local UIListLayout = Instance.new("UIListLayout")

				Dropdown.Name = "Dropdown"
				Dropdown.Parent = Section
				Dropdown.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
				Dropdown.BackgroundTransparency = 1.000
				Dropdown.BorderColor3 = Color3.fromRGB(0, 0, 0)
				Dropdown.BorderSizePixel = 0
				Dropdown.Position = UDim2.new(0.0500000231, 0, 0.601014614, 0)
				Dropdown.Size = UDim2.new(0.899999976, 0, -0.351014495, 0)
				Dropdown.ZIndex = 5

				UIAspectRatioConstraint.Parent = Dropdown
				UIAspectRatioConstraint.AspectRatio = 7.000
				UIAspectRatioConstraint.AspectType = Enum.AspectType.ScaleWithParentSize

				UICorner.CornerRadius = UDim.new(0, 3)
				UICorner.Parent = Dropdown

				LabelText.Name = "LabelText"
				LabelText.Parent = Dropdown
				LabelText.AnchorPoint = Vector2.new(0.5, 0.5)
				LabelText.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
				LabelText.BackgroundTransparency = 1.000
				LabelText.BorderColor3 = Color3.fromRGB(0, 0, 0)
				LabelText.BorderSizePixel = 0
				LabelText.Position = UDim2.new(0.296666116, 0, 0.499999374, 0)
				LabelText.Size = UDim2.new(0.593582511, 0, 0.75, 0)
				LabelText.ZIndex = 6
				LabelText.Font = Enum.Font.SourceSansSemibold
				LabelText.Text = DropdownName or "Label-Test"
				LabelText.TextColor3 = NEVERLOSE.Themes.TextColor
				LabelText.TextScaled = true
				LabelText.TextSize = 14.000
				LabelText.TextWrapped = true
				LabelText.TextXAlignment = Enum.TextXAlignment.Left

				TopBar.Name = "TopBar"
				TopBar.Parent = Dropdown
				TopBar.Active = true
				TopBar.AnchorPoint = Vector2.new(1, 0.5)
				TopBar.BackgroundColor3 = NEVERLOSE.Themes.ButtonBlackgroundColor
				TopBar.BackgroundTransparency = 0.500
				TopBar.BorderColor3 = Color3.fromRGB(0, 0, 0)
				TopBar.BorderSizePixel = 0
				TopBar.Position = UDim2.new(0.950000167, 0, 0.500000715, 0)
				TopBar.Size = UDim2.new(0.313529521, 0, 0.5, 0)
				TopBar.ZIndex = 6

				UICorner_2.CornerRadius = UDim.new(0, 3)
				UICorner_2.Parent = TopBar

				UIStroke.Thickness = 0.500
				UIStroke.Color = NEVERLOSE.Themes.StrokeColor
				UIStroke.ApplyStrokeMode = Enum.ApplyStrokeMode.Border
				UIStroke.Parent = TopBar

				ValueText.Name = "ValueText"
				ValueText.Parent = TopBar
				ValueText.AnchorPoint = Vector2.new(0.5, 0.5)
				ValueText.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
				ValueText.BackgroundTransparency = 1.000
				ValueText.BorderColor3 = Color3.fromRGB(0, 0, 0)
				ValueText.BorderSizePixel = 0
				ValueText.Position = UDim2.new(0.358571023, 0, 0.500001013, 0)
				ValueText.Size = UDim2.new(0.697142839, 0, 0.998000145, 0)
				ValueText.ZIndex = 6
				ValueText.Font = Enum.Font.SourceSansSemibold
				ValueText.Text = tostring(Default)
				ValueText.TextColor3 = NEVERLOSE.Themes.TextColor
				ValueText.TextScaled = true
				ValueText.TextSize = 14.000
				ValueText.TextWrapped = true

				Icon.Name = "Icon"
				Icon.Parent = TopBar
				Icon.AnchorPoint = Vector2.new(1, 0.5)
				Icon.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
				Icon.BackgroundTransparency = 1.000
				Icon.BorderColor3 = Color3.fromRGB(0, 0, 0)
				Icon.BorderSizePixel = 0
				Icon.Position = UDim2.new(1, 0, 0.5, 0)
				Icon.Rotation = 90.000
				Icon.Size = UDim2.new(0.949999988, 0, 0.949999988, 0)
				Icon.SizeConstraint = Enum.SizeConstraint.RelativeYY
				Icon.ZIndex = 6
				Icon.Font = Enum.Font.SourceSans
				Icon.Text = "<"
				Icon.TextColor3 = NEVERLOSE.Themes.TextColor
				Icon.TextScaled = true
				Icon.TextSize = 14.000
				Icon.TextWrapped = true

				DownBar.Name = "DownBar"
				DownBar.Parent = Dropdown
				DownBar.Active = true
				DownBar.AnchorPoint = Vector2.new(1, 0)
				DownBar.BackgroundColor3 = NEVERLOSE.Themes.ButtonBlackgroundColor
				DownBar.BackgroundTransparency = 0.100
				DownBar.BorderColor3 = Color3.fromRGB(0, 0, 0)
				DownBar.BorderSizePixel = 0
				DownBar.Position = UDim2.new(0.948214233, 0, 0.873961239, 0)
				DownBar.Size = UDim2.new(0.308999985, 0, 0, 0)
				DownBar.Visible = false
				DownBar.ZIndex = 10

				UICorner_3.CornerRadius = UDim.new(0, 3)
				UICorner_3.Parent = DownBar

				UIStroke_2.Thickness = 0.500
				UIStroke_2.Color = NEVERLOSE.Themes.StrokeColor
				UIStroke_2.ApplyStrokeMode = Enum.ApplyStrokeMode.Border
				UIStroke_2.Parent = DownBar

				UIListLayout.Parent = DownBar
				UIListLayout.HorizontalAlignment = Enum.HorizontalAlignment.Center
				UIListLayout.SortOrder = Enum.SortOrder.LayoutOrder
				UIListLayout.Padding = UDim.new(0, 2)

				local choose = Default
				local DropdownToggle = false

				DownBar:GetPropertyChangedSignal('Size'):Connect(function()
					if DownBar.Size.Y.Offset<4 then
						DownBar.Visible=false
					else
						DownBar.Visible=true
					end
				end)

				local function get_list_size()
					local a=0

					for i,v:TextButton in ipairs(DownBar:GetChildren()) do
						if v:isA('TextButton') then
							a=a + 9
						end
					end

					return a + 15
				end

				local function get_list_v4()
					local a=0

					for i,v:TextButton in ipairs(DownBar:GetChildren()) do
						if v:isA('TextButton') then
							a=a + v.AbsoluteSize.Y
						end
					end

					return a + 15
				end

				local function auto_updatea()
					if DropdownToggle then
						TweenService:Create(DownBar,TweenInfo.new(0.1),{Size=UDim2.new(0.4,0,0,get_list_v4())}):Play()
					else
						TweenService:Create(DownBar,TweenInfo.new(0.1),{Size=UDim2.new(0.4,0,0,0)}):Play()
					end
				end

				local function DropdownToggleEffect(val)
					if val then
						Dropdown.Visible=true
						TweenService:Create(Icon,TweenInfo.new(0.15),{Rotation=90}):Play()
						TweenService:Create(LabelText,TweenInfo.new(0.4),{TextTransparency=0}):Play()

						TweenService:Create(DownBar,TweenInfo.new(0.1),{Size=UDim2.new(0.4,0,0,get_list_size())}):Play()

						auto_updatea()

						for i,v:TextButton in ipairs(DownBar:GetChildren()) do
							if v:isA('TextButton') then
								v.Size=UDim2.new(0,0,0,0)
								v.TextTransparency=1
								TweenService:Create(v,TweenInfo.new(0.01+(i/100)),{
									Size  = UDim2.new(0.99000001, 0, 0.5, 0),
									TextTransparency=0.3
								}):Play()
							end
						end
					else
						for i,v:TextButton in ipairs(DownBar:GetChildren()) do
							if v:isA('TextButton') then
								v.TextTransparency=.3
								TweenService:Create(v,TweenInfo.new(0.04),{
									Size  = UDim2.new(0,0,0,0),
									TextTransparency=1
								}):Play()
							end
						end

						TweenService:Create(Icon,TweenInfo.new(0.15),{Rotation=-90}):Play()
						TweenService:Create(LabelText,TweenInfo.new(0.4),{TextTransparency=0.3}):Play()

						TweenService:Create(DownBar,TweenInfo.new(0.1),{Size=UDim2.new(0.4,0,0,0)}):Play()
					end
				end

				DropdownToggleEffect(DropdownToggle)

				cretate_button(Dropdown).MouseButton1Click:Connect(function()
					DropdownToggle=not DropdownToggle
					DropdownToggleEffect(DropdownToggle)
				end)

				local function newbutton()
					local Dropdown = Instance.new("TextButton")
					local UIAspectRatioConstraint = Instance.new("UIAspectRatioConstraint")

					Dropdown.Name = "Dropdown"
					Dropdown.Parent = DownBar
					Dropdown.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
					Dropdown.BackgroundTransparency = 1.000
					Dropdown.BorderColor3 = Color3.fromRGB(0, 0, 0)
					Dropdown.BorderSizePixel = 0
					Dropdown.Size = UDim2.new(0.99000001, 0, 0.5, 0)
					Dropdown.ZIndex = 1000
					Dropdown.Font = Enum.Font.SourceSansSemibold
					Dropdown.Text = "List"
					Dropdown.TextColor3 = NEVERLOSE.Themes.TextColor
					Dropdown.TextScaled = true
					Dropdown.TextSize = 14.000
					Dropdown.TextWrapped = true
					TweenService:Create(Dropdown,TweenInfo.new(0.1),{TextTransparency=0.3}):Play()
					Dropdown.ZIndex = 10000
					UIAspectRatioConstraint.Parent = Dropdown
					UIAspectRatioConstraint.AspectRatio = 4.5
					UIAspectRatioConstraint.AspectType = Enum.AspectType.ScaleWithParentSize

					Dropdown.MouseEnter:Connect(function()
						TweenService:Create(Dropdown,TweenInfo.new(0.1),{TextTransparency=0}):Play()
					end)

					Dropdown.MouseLeave:Connect(function()
						TweenService:Create(Dropdown,TweenInfo.new(0.1),{TextTransparency=0.3}):Play()
					end)

					return Dropdown
				end

				local function refresh()
					for i,v:TextButton in ipairs(DownBar:GetChildren()) do
						if v:isA('TextButton') then
							v:Destroy()
						end
					end

					for i,v in ipairs(data) do
						local button=newbutton()
						button.Text=tostring(v)
						button.MouseButton1Click:Connect(function()
							ValueText.Text=tostring(v)
							choose=v
							callback(v)
						end)

					end
				end

				table.insert(NEVERLOSE.auto_function,auto_updatea)
				refresh()

				local func={}

				function func:Refresh(new)
					data=new or data
					refresh()
				end

				update_section_size()

				function func:Text(a)
					LabelText.Text=tostring(a)
				end

				function func:Get()
					return choose
				end

				function func:Value(a)
					ValueText.Text=tostring(a)
					choose=a
					callback(a)
				end

				return func
			end

			function sectionfunc:AddTextBox(TextBoxName, Placeholder, Default, Callback)
				return extCreateTextBox(Section, TextBoxName, Placeholder, Default, Callback)
			end

			function sectionfunc:AddColorPicker(ColorName, Default, Callback)
				return extCreateColorPicker(Section, ColorName, Default, Callback)
			end

			function sectionfunc:AddProgressBar(ProgressName, Min, Max, Default)
				return extCreateProgressBar(Section, ProgressName, Min, Max, Default)
			end

			function sectionfunc:AddSeparator()
				return extCreateSeparator(Section)
			end

			function sectionfunc:AddInput(InputName, Default, Min, Max, Decimals, Callback)
				return extCreateInput(Section, InputName, Default, Min, Max, Decimals, Callback)
			end

			function sectionfunc:AddToggleKeybind(ToggleName, DefaultToggle, DefaultKey, ToggleCb, KeyCb, ChangedCb)
				return extCreateToggleKeybind(Section, ToggleName, DefaultToggle, DefaultKey, ToggleCb, KeyCb, ChangedCb)
			end

			function sectionfunc:AddFolder(FolderName, Collapsed)
				return extCreateFolder(Section, FolderName, Collapsed)
			end


			function sectionfunc:Hide()
				TweenService:Create(Section,TweenInfo.new(0.2),{Size=UDim2.new(0.97,0,0,1)}):Play()
				section_value=false
				TweenService:Create(lay,TweenInfo.new(1),{BackgroundTransparency=1}):Play()
				TweenService:Create(Section,TweenInfo.new(1),{BackgroundTransparency=1}):Play()
				TweenService:Create(UIStroke,TweenInfo.new(1),{Transparency=1}):Play()
				TweenService:Create(Header,TweenInfo.new(0.3),{TextTransparency=1}):Play()
			end

			function sectionfunc:Show()
				update_section_size(true)section_value=true
				TweenService:Create(Header,TweenInfo.new(0.3),{TextTransparency=0}):Play()
				TweenService:Create(lay,TweenInfo.new(1),{BackgroundTransparency=0}):Play()
				TweenService:Create(Section,TweenInfo.new(1),{BackgroundTransparency=0}):Play()
				TweenService:Create(UIStroke,TweenInfo.new(1),{Transparency=0}):Play()
			end

			return sectionfunc
		end


		return TabFunctions
	end

	function WindowFunctinos:Delete()
		return ScreenGui:Destroy()
	end

	local dragToggle = nil
	local dragSpeed = 0.1
	local dragStart = nil
	local startPos = nil

	local function updateInput(input)
		local delta = input.Position - dragStart
		local position = UDim2.new(startPos.X.Scale, startPos.X.Offset + delta.X,
			startPos.Y.Scale, startPos.Y.Offset + delta.Y)
		game:GetService('TweenService'):Create(Frame, TweenInfo.new(dragSpeed), {Position = position}):Play()
	end

	Frame_3.InputBegan:Connect(function(input)
		if (input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch) then 
			dragToggle = true
			dragStart = input.Position
			startPos = Frame.Position
			input.Changed:Connect(function()
				if input.UserInputState == Enum.UserInputState.End then
					dragToggle = false
				end
			end)
		end
	end)

	InputService.InputChanged:Connect(function(input)
		if input.UserInputType == Enum.UserInputType.MouseMovement or input.UserInputType == Enum.UserInputType.Touch then
			if dragToggle then
				updateInput(input)
			end
		end
	end)

	return WindowFunctinos
end

function NEVERLOSE:KeySystem(TitleName,LinkKey,callback)
	local Functions = {}

	local ScreenGui = Instance.new("ScreenGui")
	local Frame = Instance.new("Frame")
	local UICorner = Instance.new("UICorner")
	local Frame_2 = Instance.new("Frame")
	local UICorner_2 = Instance.new("UICorner")
	local Title = Instance.new("TextLabel")
	local PasteKey = Instance.new("TextBox")
	local UIStroke = Instance.new("UIStroke")
	local UICorner_3 = Instance.new("UICorner")
	local CopyKey = Instance.new("TextButton")
	local UIStroke_2 = Instance.new("UIStroke")
	local UICorner_4 = Instance.new("UICorner")
	local Submit = Instance.new("TextButton")
	local UIStroke_3 = Instance.new("UIStroke")
	local UICorner_5 = Instance.new("UICorner")

	ScreenGui.Parent = CoreGui
	ScreenGui.ResetOnSpawn = false
	ScreenGui.IgnoreGuiInset=true
	ScreenGui.ZIndexBehavior=Enum.ZIndexBehavior.Global

	Frame.Parent = ScreenGui
	Frame.AnchorPoint = Vector2.new(0.5, 0.5)
	Frame.BackgroundColor3 = NEVERLOSE.Themes.BlackgroundColor
	Frame.BackgroundTransparency = 0.100
	Frame.BorderColor3 = Color3.fromRGB(0, 0, 0)
	Frame.BorderSizePixel = 0
	Frame.Position = UDim2.new(0.5, 0, 0.5, 0)
	Frame.Size = UDim2.new(0, 0, 0, 0)

	UICorner.Parent = Frame

	Frame_2.Parent = Frame
	Frame_2.BackgroundColor3 = NEVERLOSE.Themes.BlackColor
	Frame_2.BorderColor3 = Color3.fromRGB(0, 0, 0)
	Frame_2.BorderSizePixel = 0
	Frame_2.Position = UDim2.new(-0.00109238492, 0, 0.081521742, 0)
	Frame_2.Size = UDim2.new(1, 0, 0.913586974, 0)
	Frame_2.ZIndex = 2

	UICorner_2.CornerRadius = UDim.new(0, 2)
	UICorner_2.Parent = Frame_2

	Title.Name = "Title"
	Title.Parent = Frame
	Title.AnchorPoint = Vector2.new(0.5, 0)
	Title.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
	Title.BackgroundTransparency = 1.000
	Title.BorderColor3 = Color3.fromRGB(0, 0, 0)
	Title.BorderSizePixel = 0
	Title.Position = UDim2.new(0.5, 0, 0.143000007, 0)
	Title.Size = UDim2.new(0.899999976, 0, 0.150000006, 0)
	Title.ZIndex = 4
	Title.Font = Enum.Font.SourceSansBold
	Title.Text = TitleName or "Key System"
	Title.TextColor3 = NEVERLOSE.Themes.TextColor
	Title.TextScaled = true
	Title.TextSize = 14.000
	Title.TextStrokeColor3 = NEVERLOSE.Themes.MainColor
	Title.TextStrokeTransparency = 0.860
	Title.TextWrapped = true

	PasteKey.Name = "PasteKey"
	PasteKey.Parent = Frame
	PasteKey.AnchorPoint = Vector2.new(0.5, 0)
	PasteKey.BackgroundColor3 = NEVERLOSE.Themes.ButtonBlackgroundColor
	PasteKey.BorderColor3 = Color3.fromRGB(0, 0, 0)
	PasteKey.BorderSizePixel = 0
	PasteKey.Position = UDim2.new(0.50000006, 0, 0.373641312, 0)
	PasteKey.Size = UDim2.new(0.899999976, 0, 0.25, 0)
	PasteKey.ZIndex = 4
	PasteKey.ClearTextOnFocus = false
	PasteKey.Font = Enum.Font.SourceSansSemibold
	PasteKey.Text = ""
	PasteKey.TextColor3 = NEVERLOSE.Themes.TextColor
	PasteKey.TextScaled = true
	PasteKey.TextSize = 14.000
	PasteKey.TextTransparency = 0.390
	PasteKey.TextWrapped = true

	UIStroke.Color = NEVERLOSE.Themes.StrokeColor
	UIStroke.ApplyStrokeMode = Enum.ApplyStrokeMode.Border
	UIStroke.Parent = PasteKey

	UICorner_3.CornerRadius = UDim.new(0, 3)
	UICorner_3.Parent = PasteKey

	CopyKey.Name = "CopyKey"
	CopyKey.Parent = Frame
	CopyKey.BackgroundColor3 = NEVERLOSE.Themes.ButtonBlackgroundColor
	CopyKey.BackgroundTransparency = 0.200
	CopyKey.BorderColor3 = Color3.fromRGB(0, 0, 0)
	CopyKey.BorderSizePixel = 0
	CopyKey.Position = UDim2.new(0.0489396416, 0, 0.754076123, 0)
	CopyKey.Size = UDim2.new(0.42039147, 0, 0.182608709, 0)
	CopyKey.ZIndex = 5
	CopyKey.Font = Enum.Font.SourceSansBold
	CopyKey.Text = "Get Key"
	CopyKey.TextColor3 = NEVERLOSE.Themes.TextColor
	CopyKey.TextScaled = true
	CopyKey.TextSize = 14.000
	CopyKey.TextStrokeColor3 = NEVERLOSE.Themes.MainColor
	CopyKey.TextStrokeTransparency = 0.760
	CopyKey.TextWrapped = true

	UIStroke_2.Color = NEVERLOSE.Themes.StrokeColor
	UIStroke_2.ApplyStrokeMode = Enum.ApplyStrokeMode.Border
	UIStroke_2.Parent = CopyKey

	UICorner_4.CornerRadius = UDim.new(0, 3)
	UICorner_4.Parent = CopyKey

	Submit.Name = "Submit"
	Submit.Parent = Frame
	Submit.BackgroundColor3 = NEVERLOSE.Themes.ButtonBlackgroundColor
	Submit.BackgroundTransparency = 0.200
	Submit.BorderColor3 = Color3.fromRGB(0, 0, 0)
	Submit.BorderSizePixel = 0
	Submit.Position = UDim2.new(0.517944396, 0, 0.754076123, 0)
	Submit.Size = UDim2.new(0.428548098, 0, 0.182608709, 0)
	Submit.ZIndex = 5
	Submit.Font = Enum.Font.SourceSansBold
	Submit.Text = "Submit"
	Submit.TextColor3 = NEVERLOSE.Themes.TextColor
	Submit.TextScaled = true
	Submit.TextSize = 14.000
	Submit.TextStrokeColor3 = NEVERLOSE.Themes.MainColor
	Submit.TextStrokeTransparency = 0.760
	Submit.TextWrapped = true

	UIStroke_3.Color = NEVERLOSE.Themes.StrokeColor
	UIStroke_3.ApplyStrokeMode = Enum.ApplyStrokeMode.Border
	UIStroke_3.Parent = Submit

	UICorner_5.CornerRadius = UDim.new(0, 3)
	UICorner_5.Parent = Submit

	TweenService:Create(Frame,TweenInfo.new(0.4,Enum.EasingStyle.Quint),{Size=UDim2.new(0.25, 0, 0.25, 0)}):Play()

	CopyKey.MouseButton1Click:Connect(function()
		pcall(function()
			setclipboard(tostring(LinkKey))
		end)

		pcall(function()
			toclipboard(tostring(LinkKey))
		end)
	end)

	local asd=false

	local function_call

	Submit.MouseButton1Click:Connect(function()
		if asd then
			return
		end

		asd=true
		if callback(PasteKey.Text) then
			TweenService:Create(Frame,TweenInfo.new(0.4,Enum.EasingStyle.Quint,Enum.EasingDirection.InOut),{Size=UDim2.new(0,0,0,0)}):Play()
			function_call=function_call or function()

			end

			task.spawn(function()
				task.wait(.45)
				ScreenGui:Destroy()
			end)

			function_call(PasteKey.Text)

			return

		else
			PasteKey.Text=''

		end

		asd=false
	end)

	task.spawn(function()
		local dragToggle = nil
		local dragSpeed = 0.2
		local dragStart = nil
		local startPos = nil

		local function updateInput(input)
			local delta = input.Position - dragStart
			local position = UDim2.new(startPos.X.Scale, startPos.X.Offset + delta.X,
				startPos.Y.Scale, startPos.Y.Offset + delta.Y)
			game:GetService('TweenService'):Create(Frame, TweenInfo.new(dragSpeed), {Position = position}):Play()
		end

		Frame.InputBegan:Connect(function(input)
			if (input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch) and not toggle_valu then 
				dragToggle = true
				dragStart = input.Position
				startPos = Frame.Position
				input.Changed:Connect(function()
					if input.UserInputState == Enum.UserInputState.End then
						dragToggle = false
					end
				end)
			end
		end)

		InputService.InputChanged:Connect(function(input)
			if input.UserInputType == Enum.UserInputType.MouseMovement or input.UserInputType == Enum.UserInputType.Touch then
				if dragToggle then
					updateInput(input)
				end
			end
		end)
	end)

	function Functions:Callback(func)
		function_call=func
	end

	return Functions
end

function NEVERLOSE:Notification()
	local Notification_ = {
		MaxNotifications = 5
	}

	local Notification = Instance.new("ScreenGui")
	local MainFrame = Instance.new("Frame")
	local UIListLayout = Instance.new("UIListLayout")

	Notification.Name = "Notification"
	Notification.Parent = CoreGui
	Notification.ResetOnSpawn = false
	Notification.ZIndexBehavior=Enum.ZIndexBehavior.Global
	Notification.IgnoreGuiInset=true
	ProtectGui(Notification)

	MainFrame.Name = "MainFrame"
	MainFrame.Parent = Notification
	MainFrame.AnchorPoint = Vector2.new(1, 1)
	MainFrame.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
	MainFrame.BackgroundTransparency = 1.000
	MainFrame.BorderColor3 = Color3.fromRGB(0, 0, 0)
	MainFrame.BorderSizePixel = 0
	MainFrame.Position = UDim2.new(0.99000001, 0, 0.99000001, 0)
	MainFrame.Size = UDim2.new(0.35, 0, 0.100000001, 0)

	UIListLayout.Parent = MainFrame
	UIListLayout.HorizontalAlignment = Enum.HorizontalAlignment.Right
	UIListLayout.SortOrder = Enum.SortOrder.LayoutOrder
	UIListLayout.VerticalAlignment = Enum.VerticalAlignment.Bottom
	UIListLayout.Padding = UDim.new(0, 4)
	function Notification_:Notify(Type,Head,Body,countdown)
		if (#MainFrame:GetChildren()) > Notification_.MaxNotifications then
			return false
		end

		local typeicon = {
			['error'] = "9072920609",
			['success'] = "9073052584",
			['warning'] = "9072448788",
			['info'] = "9072944922"
		}

		local iconId = typeicon[tostring(Type or "error"):lower()]

		local Notify = Instance.new("Frame")
		local UICorner = Instance.new("UICorner")
		local UIStroke = Instance.new("UIStroke")
		local IconImage = Instance.new("ImageLabel")
		local HeadTitle = Instance.new("TextLabel")
		local BodyTitle = Instance.new("TextLabel")
		local Countdown = Instance.new("Frame")
		local CloseButton = Instance.new("ImageButton")

		Notify.Name = "Notify"
		Notify.Parent = MainFrame
		Notify.BackgroundColor3 = NEVERLOSE.Themes.SectionColor
		Notify.BackgroundTransparency = 0.100
		Notify.BorderColor3 = Color3.fromRGB(0, 0, 0)
		Notify.BorderSizePixel = 0
		Notify.ClipsDescendants = true
		Notify.Size = UDim2.new(0.75,0,0,0)

		UICorner.CornerRadius = UDim.new(0, 3)
		UICorner.Parent = Notify

		UIStroke.Color = NEVERLOSE.Themes.StrokeColor
		UIStroke.ApplyStrokeMode = Enum.ApplyStrokeMode.Border
		UIStroke.Parent = Notify

		IconImage.Name = "IconImage"
		IconImage.Parent = Notify
		IconImage.AnchorPoint = Vector2.new(0.5, 0.5)
		IconImage.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
		IconImage.BackgroundTransparency = 1.000
		IconImage.BorderColor3 = Color3.fromRGB(0, 0, 0)
		IconImage.BorderSizePixel = 0
		IconImage.Position = UDim2.new(0.0549999997, 0, 0.5, 0)
		IconImage.Size = UDim2.new(0.850000024, 0, 0.850000024, 0)
		IconImage.SizeConstraint = Enum.SizeConstraint.RelativeYY
		IconImage.ZIndex = 5
		IconImage.Image = "rbxassetid://"..tostring(iconId)
		IconImage.ImageTransparency=1
		IconImage.ImageColor3=NEVERLOSE.Themes.MainColor

		HeadTitle.Name = "HeadTitle"
		HeadTitle.Parent = Notify
		HeadTitle.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
		HeadTitle.BackgroundTransparency = 1.000
		HeadTitle.BorderColor3 = Color3.fromRGB(0, 0, 0)
		HeadTitle.BorderSizePixel = 0
		HeadTitle.Position = UDim2.new(0.130612239, 0, 0.0750002638, 0)
		HeadTitle.Size = UDim2.new(0.738775492, 0, 0.369384199, 0)
		HeadTitle.ZIndex = 7
		HeadTitle.Font = Enum.Font.SourceSansSemibold
		HeadTitle.Text = Head or "Head"
		HeadTitle.TextColor3 = NEVERLOSE.Themes.TextColor
		HeadTitle.TextScaled = true
		HeadTitle.TextSize = 14.000
		HeadTitle.TextWrapped = true
		HeadTitle.TextXAlignment = Enum.TextXAlignment.Left
		HeadTitle.TextTransparency=1
		BodyTitle.Name = "BodyTitle"
		BodyTitle.Parent = Notify
		BodyTitle.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
		BodyTitle.BackgroundTransparency = 1.000
		BodyTitle.BorderColor3 = Color3.fromRGB(0, 0, 0)
		BodyTitle.BorderSizePixel = 0
		BodyTitle.Position = UDim2.new(0.130612239, 0, 0.444384605, 0)
		BodyTitle.Size = UDim2.new(0.738775492, 0, 0.47554332, 0)
		BodyTitle.ZIndex = 7
		BodyTitle.Font = Enum.Font.SourceSansSemibold
		BodyTitle.Text = Body or "Body"
		BodyTitle.TextColor3 = NEVERLOSE.Themes.TextColor
		BodyTitle.TextScaled = true
		BodyTitle.TextSize = 14.000
		BodyTitle.TextTransparency = 1
		BodyTitle.TextWrapped = true
		BodyTitle.TextXAlignment = Enum.TextXAlignment.Left

		Countdown.Name = "Countdown"
		Countdown.Parent = Notify
		Countdown.AnchorPoint = Vector2.new(0, 1)
		Countdown.BackgroundColor3 = NEVERLOSE.Themes.MainColor
		Countdown.BorderColor3 = Color3.fromRGB(0, 0, 0)
		Countdown.BorderSizePixel = 0
		Countdown.Position = UDim2.new(0, 0, 1.07500005, 0)
		Countdown.Size = UDim2.new(0, 0, 0.100000001, 0)
		Countdown.ZIndex = 6
		Countdown.BackgroundTransparency=1

		CloseButton.Name = "CloseButton"
		CloseButton.Parent = Notify
		CloseButton.AnchorPoint = Vector2.new(0.5, 0.5)
		CloseButton.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
		CloseButton.BackgroundTransparency = 1.000
		CloseButton.BorderColor3 = Color3.fromRGB(0, 0, 0)
		CloseButton.BorderSizePixel = 0
		CloseButton.Position = UDim2.new(0.939999998, 0, 0.5, 0)
		CloseButton.Size = UDim2.new(0.550000012, 0, 0.550000012, 0)
		CloseButton.SizeConstraint = Enum.SizeConstraint.RelativeYY
		CloseButton.ZIndex = 5
		CloseButton.Image = "rbxassetid://9127564477"
		CloseButton.ScaleType = Enum.ScaleType.Fit
		CloseButton.ImageTransparency=1
		
		local currenttime = 0.3
		local function start_vu()
			TweenService:Create(Notify,TweenInfo.new(currenttime/2,Enum.EasingStyle.Quint),{Size=UDim2.new(0.99,0,0.75,0)}):Play()
			TweenService:Create(UIStroke,TweenInfo.new(currenttime,Enum.EasingStyle.Quint,Enum.EasingDirection.In),{Transparency=0}):Play()
			TweenService:Create(HeadTitle,TweenInfo.new(currenttime,Enum.EasingStyle.Quint,Enum.EasingDirection.In),{TextTransparency=0}):Play()
			TweenService:Create(BodyTitle,TweenInfo.new(currenttime,Enum.EasingStyle.Quint,Enum.EasingDirection.In),{TextTransparency=0.3}):Play()
			TweenService:Create(Countdown,TweenInfo.new(currenttime,Enum.EasingStyle.Quint,Enum.EasingDirection.In),{BackgroundTransparency=0}):Play()
			TweenService:Create(IconImage,TweenInfo.new(currenttime,Enum.EasingStyle.Quint,Enum.EasingDirection.In),{ImageTransparency=0}):Play()
			TweenService:Create(CloseButton,TweenInfo.new(currenttime,Enum.EasingStyle.Quint,Enum.EasingDirection.In),{ImageTransparency=0}):Play()
		end


		local function end_vu()
			local trantween = TweenService:Create(Notify,TweenInfo.new(currenttime,Enum.EasingStyle.Quint,Enum.EasingDirection.In),{Size=UDim2.new(0.75,0,0,0)})
			TweenService:Create(UIStroke,TweenInfo.new(currenttime/2,Enum.EasingStyle.Quad),{Transparency=1}):Play()
			TweenService:Create(HeadTitle,TweenInfo.new(currenttime/2,Enum.EasingStyle.Quad),{TextTransparency=1}):Play()
			TweenService:Create(BodyTitle,TweenInfo.new(currenttime/2,Enum.EasingStyle.Quad),{TextTransparency=1}):Play()
			TweenService:Create(Countdown,TweenInfo.new(currenttime/2,Enum.EasingStyle.Quad),{BackgroundTransparency=1}):Play()
			TweenService:Create(IconImage,TweenInfo.new(currenttime/2,Enum.EasingStyle.Quad),{ImageTransparency=1}):Play()
			TweenService:Create(CloseButton,TweenInfo.new(currenttime/2,Enum.EasingStyle.Quad),{ImageTransparency=1}):Play()
			trantween:Play()

			trantween.Completed:Connect(function()
				Notify:Destroy()
			end)
		end

		start_vu()

		task.spawn(function()
			CloseButton.MouseButton1Click:Connect(end_vu)

			if countdown then

				pcall(function()
					task.wait(1.3)
					local tween = TweenService:Create(Countdown,TweenInfo.new(tonumber(countdown) or 3,Enum.EasingStyle.Linear),{Size=UDim2.new(1,0,0.1,0)
					})

					tween:Play()

					tween.Completed:Wait()
					task.wait(0.5)
					end_vu()
				end)
			end
		end)
	end

	return Notification_
end


function NEVERLOSE:Notify(title, text, duration, kind)
	duration = tonumber(duration) or 4
	local ICONS = {
		error = { tag = "[!]", color = Color3.fromRGB(255, 90, 90) },
		success = { tag = "[+]", color = Color3.fromRGB(90, 220, 130) },
		warning = { tag = "[~]", color = Color3.fromRGB(255, 190, 80) },
		info = { tag = "[i]", color = ExtTheme.Accent },
	}
	local icon = kind and ICONS[tostring(kind):lower()] or nil

	local card = extNew("Frame", {
		BackgroundColor3 = ExtTheme.Background,
		BackgroundTransparency = 1,
		BorderSizePixel = 0,
		AutomaticSize = Enum.AutomaticSize.Y,
		Size = UDim2.new(1, 0, 0, 0),
	}, extGetNotifyHolder())
	extCorner(card, 0, 4)
	extStroke(card)
	extNew("UIListLayout", { SortOrder = Enum.SortOrder.LayoutOrder, Padding = UDim.new(0, 2) }, card)
	extNew("UIPadding", {
		PaddingTop = UDim.new(0, 8), PaddingBottom = UDim.new(0, 9),
		PaddingLeft = UDim.new(0, 10), PaddingRight = UDim.new(0, 10),
	}, card)

	extNew("TextLabel", {
		BackgroundTransparency = 1, AutomaticSize = Enum.AutomaticSize.Y,
		Size = UDim2.new(1, 0, 0, 0), Font = extFont(Enum.FontWeight.SemiBold),
		TextSize = 12, TextColor3 = icon and icon.color or ExtTheme.Text,
		TextWrapped = true, TextXAlignment = Enum.TextXAlignment.Left,
		Text = icon and (icon.tag .. " " .. tostring(title or "")) or tostring(title or ""),
		LayoutOrder = 1,
	}, card)

	if text and text ~= "" then
		extNew("TextLabel", {
			BackgroundTransparency = 1, AutomaticSize = Enum.AutomaticSize.Y,
			Size = UDim2.new(1, 0, 0, 0), Font = extFont(),
			TextSize = 11, TextColor3 = ExtTheme.Muted,
			TextWrapped = true, TextXAlignment = Enum.TextXAlignment.Left,
			Text = tostring(text), LayoutOrder = 2,
		}, card)
	end

	extTween(card, { BackgroundTransparency = 0 })

	local dismiss = extNew("TextButton", {
		Text = "", BackgroundTransparency = 1, Size = UDim2.fromScale(1, 1), ZIndex = 100,
	}, card)
	dismiss.MouseButton1Click:Connect(function()
		if card.Parent then
			extTween(card, { BackgroundTransparency = 1 })
			task.delay(FAST.Time + 0.05, function() if card.Parent then card:Destroy() end end)
		end
	end)

	task.delay(duration, function()
		if card.Parent then
			extTween(card, { BackgroundTransparency = 1 })
			task.wait(FAST.Time + 0.05)
			card:Destroy()
		end
	end)
end

task.spawn(function()
	_G.index_neverlose=true
	while _G.index_neverlose do task.wait(0)
		pcall(function()
			for i,v in ipairs(NEVERLOSE.auto_function) do task.wait()
				pcall(function()
					task.spawn(v)
				end)
			end
		end)
	end
end)

return NEVERLOSE
