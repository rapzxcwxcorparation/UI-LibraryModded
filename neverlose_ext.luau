local UserInputService = game:GetService("UserInputService")
local TweenService = game:GetService("TweenService")
local CoreGui = game:GetService("CoreGui")

local NEVERLOSE = loadstring(game:HttpGet(
    "https://raw.githubusercontent.com/riqegopeek/NeverLose/refs/heads/main/src/interface.luau"
))()

if NEVERLOSE._extended then
    return NEVERLOSE
end

local THEME_MAP = {
    Background = "BlackgroundColor",
    Surface = "SectionColor",
    Hover = "ButtonBlackgroundColor",
    Stroke = "StrokeColor",
    Accent = "MainColor",
    Text = "TextColor",
}

local THEME_FALLBACK = {
    Background = Color3.fromRGB(20, 20, 22),
    Surface = Color3.fromRGB(30, 30, 33),
    Hover = Color3.fromRGB(40, 40, 44),
    Stroke = Color3.fromRGB(52, 52, 58),
    Accent = Color3.fromRGB(64, 140, 255),
    Text = Color3.fromRGB(225, 225, 228),
    Muted = Color3.fromRGB(135, 135, 144),
}

local Theme = setmetatable({}, {
    __index = function(_, key)
        local name = THEME_MAP[key]
        if name and NEVERLOSE.Themes then
            local color = NEVERLOSE.Themes[name]
            if typeof(color) == "Color3" then
                return color
            end
        end
        return THEME_FALLBACK[key] or Color3.new(1, 1, 1)
    end,
})

NEVERLOSE.ThemePalette = Theme

local FONT_FAMILY = "rbxasset://fonts/families/SourceSansPro.json"
local FAST = TweenInfo.new(0.16, Enum.EasingStyle.Quad, Enum.EasingDirection.Out)

local function font(weight)
    return Font.new(FONT_FAMILY, weight or Enum.FontWeight.Regular, Enum.FontStyle.Normal)
end

local function new(class, props, parent)
    local obj = Instance.new(class)
    for key, value in pairs(props) do
        obj[key] = value
    end
    obj.Parent = parent
    return obj
end

local function corner(parent, scale, offset)
    return new("UICorner", { CornerRadius = UDim.new(scale or 0, offset or 0) }, parent)
end

local function stroke(parent, color, thickness)
    return new("UIStroke", {
        Color = color or Theme.Stroke,
        Thickness = thickness or 1,
        ApplyStrokeMode = Enum.ApplyStrokeMode.Border,
    }, parent)
end

local function tween(obj, props, info)
    TweenService:Create(obj, info or FAST, props):Play()
end

local function safeCall(fn, ...)
    if not fn then
        return
    end
    local ok, err = pcall(fn, ...)
    if not ok then
        warn("[NeverLose-Ext] " .. tostring(err))
    end
end

local function safeCallAsync(fn, ...)
    task.spawn(function(...)
        local ok, err = pcall(fn, ...)
        if not ok then
            warn("[NeverLose-Ext] " .. tostring(err))
        end
    end, ...)
end

local function isPress(input)
    return input.UserInputType == Enum.UserInputType.MouseButton1
        or input.UserInputType == Enum.UserInputType.Touch
end

local function isMove(input)
    return input.UserInputType == Enum.UserInputType.MouseMovement
        or input.UserInputType == Enum.UserInputType.Touch
end

local getUpvalues = (debug and debug.getupvalues) or getupvalues
local getGC = getgc or get_gc or nil

local function isSectionFrame(item)
    if typeof(item) ~= "Instance" then
        return false
    end
    if not item:IsA("Frame") or item.Name ~= "Section" then
        return false
    end
    local parent = item.Parent
    if not parent then
        return false
    end
    return parent:IsA("ScrollingFrame") or parent:IsA("Frame")
end

local function scanUpvalues(section)
    if not getUpvalues then
        return nil
    end
    for _, member in pairs(section) do
        if type(member) == "function" then
            local ok, upvalues = pcall(getUpvalues, member)
            if ok and type(upvalues) == "table" then
                for _, upvalue in pairs(upvalues) do
                    if isSectionFrame(upvalue) then
                        return upvalue
                    end
                end
            end
        end
    end
    return nil
end

local function scanGC()
    if not getGC then
        return nil
    end
    local ok, items = pcall(getGC, true)
    if not ok or type(items) ~= "table" then
        return nil
    end
    for _, item in ipairs(items) do
        if isSectionFrame(item) then
            return item
        end
    end
    return nil
end

local function findSectionFrame(section)
    if type(section) ~= "table" then
        return nil
    end
    return scanUpvalues(section) or scanGC()
end

local KNOWN_EXECUTORS = {
    ["synapse"] = { unc = 100, sunc = 100 },
    ["script-ware"] = { unc = 100, sunc = 100 },
    ["krnl"] = { unc = 98, sunc = 96 },
    ["fluxus"] = { unc = 97, sunc = 95 },
    ["electron"] = { unc = 97, sunc = 95 },
    ["solara"] = { unc = 98, sunc = 96 },
    ["wave"] = { unc = 98, sunc = 95 },
    ["delta"] = { unc = 96, sunc = 92 },
    ["codex"] = { unc = 97, sunc = 94 },
    ["hydrogen"] = { unc = 95, sunc = 90 },
    ["xeno"] = { unc = 98, sunc = 96 },
    ["swift"] = { unc = 96, sunc = 93 },
    ["arceus"] = { unc = 97, sunc = 94 },
    ["trigon"] = { unc = 98, sunc = 96 },
    ["awp"] = { unc = 95, sunc = 92 },
    ["sirhurt"] = { unc = 95, sunc = 90 },
    ["vega"] = { unc = 96, sunc = 92 },
    ["oxygen"] = { unc = 98, sunc = 96 },
    ["celery"] = { unc = 97, sunc = 94 },
    ["sander"] = { unc = 90, sunc = 85 },
    ["kiwi"] = { unc = 94, sunc = 88 },
}

local function detectExecutor()
    local name, version = "Unknown", nil
    if type(identifyexecutor) == "function" then
        local ok, n, v = pcall(identifyexecutor)
        if ok and n then
            name = tostring(n)
            version = v
        end
    elseif type(getexecutorname) == "function" then
        local ok, n = pcall(getexecutorname)
        if ok and n then
            name = tostring(n)
        end
    elseif syn then
        name = "Synapse"
    elseif KRNL_LOADED or krnl then
        name = "Krnl"
    elseif fluxus then
        name = "Fluxus"
    end
    return name, version
end

local function lookupStats(name)
    local key = tostring(name or ""):lower():gsub("%s+", "-")
    local entry = KNOWN_EXECUTORS[key]
    if entry then
        return entry.unc, entry.sunc
    end
    return "N/A", "N/A"
end

local function findWindowParts(fn)
    if type(fn) ~= "function" or not getUpvalues then
        return nil
    end
    local parts = {}
    local ok, upvalues = pcall(getUpvalues, fn)
    if not ok or type(upvalues) ~= "table" then
        return parts
    end
    for _, v in pairs(upvalues) do
        if typeof(v) == "Instance" then
            if v:IsA("TextLabel") and v.Name == "HeadName" then
                parts.headName = v
            elseif v:IsA("Frame") and v.Name == "UserData" then
                parts.userData = v
            elseif v:IsA("ImageLabel") and v.Name == "UserImage" then
                parts.userImage = v
            elseif v:IsA("TextLabel") and v.Name == "UserName" then
                parts.userName = v
            elseif v:IsA("Frame") and v.Name == "Frame" and v.Parent and v.Parent:IsA("ScreenGui") then
                parts.root = v
            elseif v:IsA("ScreenGui") then
                parts.screenGui = v
            end
        end
    end
    return parts
end

local function createTitleTag(rootFrame, text, color)
    color = color or Theme.Accent
    local holder = new("Frame", {
        Name = "ExtTitleTag",
        AnchorPoint = Vector2.new(1, 0),
        Position = UDim2.new(1, -3, 0.125, 0),
        Size = UDim2.new(0, 0, 0, 16),
        AutomaticSize = Enum.AutomaticSize.X,
        BackgroundColor3 = color,
        BackgroundTransparency = 0.15,
        BorderSizePixel = 0,
        ZIndex = 8,
    }, rootFrame)
    corner(holder, 1, 0)
    local holderStroke = stroke(holder, color, 1)
    new("UIPadding", {
        PaddingLeft = UDim.new(0, 6),
        PaddingRight = UDim.new(0, 6),
    }, holder)
    local label = new("TextLabel", {
        Name = "Label",
        BackgroundTransparency = 1,
        Size = UDim2.new(0, 0, 1, 0),
        AutomaticSize = Enum.AutomaticSize.X,
        FontFace = font(Enum.FontWeight.Bold),
        TextSize = 10,
        TextColor3 = Theme.Text,
        Text = tostring(text or "EXT"),
        TextXAlignment = Enum.TextXAlignment.Center,
        TextYAlignment = Enum.TextYAlignment.Center,
        ZIndex = 9,
    }, holder)
    holder.BackgroundTransparency = 1
    label.TextTransparency = 1
    tween(holder, { BackgroundTransparency = 0.15 })
    tween(label, { TextTransparency = 0 })
    return {
        Container = holder,
        Label = label,
        SetText = function(t)
            label.Text = tostring(t or "")
        end,
        SetColor = function(c)
            c = c or Theme.Accent
            holder.BackgroundColor3 = c
            if holderStroke then
                holderStroke.Color = c
            end
        end,
        Destroy = function()
            holder:Destroy()
        end,
    }
end

local function createInfoPanel(rootFrame)
    local panel = new("Frame", {
        Name = "ExtInfoPanel",
        AnchorPoint = Vector2.new(1, 1),
        Position = UDim2.new(0.998, -3, 0.998, -3),
        Size = UDim2.new(0.42, 0, 0, 0),
        AutomaticSize = Enum.AutomaticSize.Y,
        BackgroundColor3 = Theme.Background,
        BackgroundTransparency = 0.35,
        BorderSizePixel = 0,
        ZIndex = 8,
    }, rootFrame)
    corner(panel, 0, 4)
    stroke(panel)
    new("UIListLayout", {
        SortOrder = Enum.SortOrder.LayoutOrder,
        Padding = UDim.new(0, 1),
    }, panel)
    new("UIPadding", {
        PaddingTop = UDim.new(0, 5),
        PaddingBottom = UDim.new(0, 5),
        PaddingLeft = UDim.new(0, 8),
        PaddingRight = UDim.new(0, 8),
    }, panel)

    local function mkrow(text, order, color)
        return new("TextLabel", {
            Name = "Row",
            BackgroundTransparency = 1,
            Size = UDim2.new(1, 0, 0, 14),
            FontFace = font(Enum.FontWeight.Medium),
            TextSize = 10,
            TextColor3 = color or Theme.Text,
            TextXAlignment = Enum.TextXAlignment.Left,
            TextYAlignment = Enum.TextYAlignment.Center,
            Text = tostring(text or ""),
            LayoutOrder = order,
        }, panel)
    end

    local titleRow = mkrow("Info", 1, Theme.Accent)
    local execRow = mkrow("Executor: ...", 2, Theme.Text)
    local uncRow = mkrow("UNC: ...", 3, Theme.Muted)
    local suncRow = mkrow("sUNC: ...", 4, Theme.Muted)

    return {
        Panel = panel,
        Set = function(name, version, unc, sunc)
            execRow.Text = "Executor: " .. tostring(name) .. (version and (" v" .. tostring(version)) or "")
            uncRow.Text = "UNC: " .. tostring(unc)
            suncRow.Text = "sUNC: " .. tostring(sunc)
        end,
        SetTitle = function(t)
            titleRow.Text = tostring(t or "Info")
        end,
        Destroy = function()
            panel:Destroy()
        end,
    }
end

local function enhanceTabButton(btn)
    if btn:FindFirstChild("ExtIndicator") then
        return
    end

    local image = btn:FindFirstChild("Image")
    local label = btn:FindFirstChild("Label")

    local indicator = new("Frame", {
        Name = "ExtIndicator",
        AnchorPoint = Vector2.new(0, 0.5),
        Position = UDim2.new(0, 0, 0.5, 0),
        Size = UDim2.new(0, 0, 0.6, 0),
        BackgroundColor3 = Theme.Accent,
        BackgroundTransparency = 1,
        BorderSizePixel = 0,
        ZIndex = 7,
    }, btn)
    corner(indicator, 1, 0)

    local btnStroke = stroke(btn, Theme.Accent, 1)
    btnStroke.Transparency = 1

    local lastActive = nil

    local function sync()
        local active = btn.BackgroundTransparency < 0.8
        if active == lastActive then
            return
        end
        lastActive = active
        if active then
            tween(indicator, { Size = UDim2.new(0, 3, 0.6, 0), BackgroundTransparency = 0 })
            tween(btnStroke, { Transparency = 0.35, Color = Theme.Accent })
            if label then
                tween(label, { TextColor3 = Theme.Accent })
            end
        else
            tween(indicator, { Size = UDim2.new(0, 0, 0.6, 0), BackgroundTransparency = 1 })
            tween(btnStroke, { Transparency = 1 })
            if label then
                tween(label, { TextColor3 = Theme.Text })
            end
        end
    end

    btn:GetPropertyChangedSignal("BackgroundTransparency"):Connect(sync)

    btn.MouseEnter:Connect(function()
        if btn.BackgroundTransparency > 0.9 then
            tween(btn, { BackgroundTransparency = 0.88 })
        end
    end)

    btn.MouseLeave:Connect(function()
        if btn.BackgroundTransparency > 0.85 and btn.BackgroundTransparency < 0.99 then
            tween(btn, { BackgroundTransparency = 1 })
        end
    end)

    if image then
        tween(image, { ImageColor3 = Theme.Accent })
    end

    sync()
end

local function enhanceTabButtons(tabButtons)
    if not tabButtons then
        return
    end
    for _, child in ipairs(tabButtons:GetChildren()) do
        if child:IsA("Frame") and child.Name == "TabButton" then
            pcall(enhanceTabButton, child)
        end
    end
end

local function attachWindowExtras(window, originalFn)
    local parts = findWindowParts(originalFn)
    if not parts or not parts.root then
        return false
    end

    local existingTag = parts.root:FindFirstChild("ExtTitleTag")
    if existingTag then
        existingTag:Destroy()
    end

    local tag = createTitleTag(parts.root, "EXT", Theme.Accent)

    window.SetTag = function(_, text, color)
        tag.SetText(text)
        if color then
            tag.SetColor(color)
        end
    end
    window.GetTag = function()
        return tag.Container
    end

    local existingPanel = parts.root:FindFirstChild("ExtInfoPanel")
    if existingPanel then
        existingPanel:Destroy()
    end

    local panel = createInfoPanel(parts.root)
    local name, version = detectExecutor()
    local unc, sunc = lookupStats(name)
    panel.Set(name, version, unc, sunc)

    window.SetInfo = function(_, newName, newVersion, newUNC, newSUNC)
        panel.Set(
            newName or name,
            newVersion or version,
            newUNC or unc,
            newSUNC or sunc
        )
    end
    window.GetInfo = function()
        return panel.Panel
    end

    local tabButtons = parts.root:FindFirstChild("TabButtons")
    if tabButtons then
        enhanceTabButtons(tabButtons)
        tabButtons.ChildAdded:Connect(function(child)
            if child:IsA("Frame") and child.Name == "TabButton" then
                task.defer(enhanceTabButton, child)
            end
        end)
    end

    return true
end

local function prepareSection(frame)
    if frame:FindFirstChildWhichIsA("UIListLayout") then
        return
    end
    new("UIListLayout", {
        FillDirection = Enum.FillDirection.Vertical,
        SortOrder = Enum.SortOrder.LayoutOrder,
        Padding = UDim.new(0, 4),
    }, frame)
    if not frame:FindFirstChildWhichIsA("UIPadding") then
        new("UIPadding", {
            PaddingTop = UDim.new(0, 8),
            PaddingBottom = UDim.new(0, 8),
            PaddingLeft = UDim.new(0, 8),
            PaddingRight = UDim.new(0, 8),
        }, frame)
    end
end

local orderCache = setmetatable({}, { __mode = "k" })

local function nextOrder(frame)
    local order = orderCache[frame]
    if not order then
        order = 0
        for _, child in ipairs(frame:GetChildren()) do
            if child:IsA("GuiObject") then
                order = math.max(order, child.LayoutOrder)
            end
        end
    end
    order += 1
    orderCache[frame] = order
    return order
end

local function createRow(section, height, auto)
    local row = new("Frame", {
        Name = "ExtRow",
        BackgroundColor3 = Theme.Hover,
        BackgroundTransparency = 1,
        BorderSizePixel = 0,
        ClipsDescendants = true,
        Size = UDim2.new(1, 0, 0, height),
        LayoutOrder = nextOrder(section),
    }, section)
    if auto then
        row.AutomaticSize = Enum.AutomaticSize.Y
    end
    corner(row, 0, 4)
    return row
end

local function binder(row)
    local connections = {}
    row.Destroying:Connect(function()
        for _, connection in ipairs(connections) do
            connection:Disconnect()
        end
        table.clear(connections)
    end)
    return function(signal, fn)
        local connection = signal:Connect(fn)
        connections[#connections + 1] = connection
        return connection
    end
end

local function hoverable(row, on)
    on(row.MouseEnter, function()
        tween(row, { BackgroundTransparency = 0.6 })
    end)
    on(row.MouseLeave, function()
        tween(row, { BackgroundTransparency = 1 })
    end)
end

local function createTitle(row, text, rightOffset)
    return new("TextLabel", {
        Name = "Title",
        Text = text or "",
        FontFace = font(Enum.FontWeight.Medium),
        TextSize = 12,
        TextColor3 = Theme.Text,
        TextXAlignment = Enum.TextXAlignment.Left,
        TextTruncate = Enum.TextTruncate.AtEnd,
        BackgroundTransparency = 1,
        Position = UDim2.new(0, 10, 0, 0),
        Size = UDim2.new(1, -(rightOffset or 20), 0, 30),
    }, row)
end

local function finish(row, api)
    api.Container = row
    api.SetVisible = function(_, visible)
        row.Visible = visible ~= false
    end
    api.SetTitle = function(_, text)
        local title = row:FindFirstChild("Title")
        if title then
            title.Text = tostring(text)
        end
    end
    api.Text = api.SetTitle
    api.Status = api.SetVisible
    if api.Set then
        api.Value = function(_, value)
            return api.Set(api, value, true)
        end
    end
    api.Destroy = function()
        row:Destroy()
    end
    return api
end

local function createToggle(section, name, default, callback)
    local row = createRow(section, 30)
    local on = binder(row)
    createTitle(row, name, 56)

    local state = default and true or false

    local track = new("Frame", {
        AnchorPoint = Vector2.new(1, 0.5),
        Position = UDim2.new(1, -10, 0, 15),
        Size = UDim2.fromOffset(30, 16),
        BackgroundColor3 = Theme.Stroke,
        BorderSizePixel = 0,
    }, row)
    corner(track, 1, 0)

    local knob = new("Frame", {
        AnchorPoint = Vector2.new(0, 0.5),
        Position = UDim2.new(0, 2, 0.5, 0),
        Size = UDim2.fromOffset(12, 12),
        BackgroundColor3 = Theme.Muted,
        BorderSizePixel = 0,
    }, track)
    corner(knob, 1, 0)

    local hit = new("TextButton", {
        Text = "",
        BackgroundTransparency = 1,
        Size = UDim2.fromScale(1, 1),
    }, row)

    local function render(animate)
        local position = state and UDim2.new(1, -14, 0.5, 0) or UDim2.new(0, 2, 0.5, 0)
        local trackColor = state and Theme.Accent or Theme.Stroke
        local knobColor = state and Theme.Text or Theme.Muted
        if animate then
            tween(knob, { Position = position, BackgroundColor3 = knobColor })
            tween(track, { BackgroundColor3 = trackColor })
        else
            knob.Position = position
            knob.BackgroundColor3 = knobColor
            track.BackgroundColor3 = trackColor
        end
    end

    local function set(value, fire, force)
        local nextState = value and true or false
        local changed = nextState ~= state
        state = nextState
        render(true)
        if (changed or force) and callback then
            safeCall(callback, state)
        end
    end

    on(hit.MouseButton1Click, function()
        set(not state, true)
    end)

    hoverable(row, on)
    render(false)

    if callback then
        safeCall(callback, state)
    end

    return finish(row, {
        Set = function(_, value, fire, force)
            set(value, fire, force)
        end,
        Get = function()
            return state
        end,
    })
end

local function createSlider(section, name, minVal, maxVal, default, decimals, callback, suffix)
    if type(decimals) == "function" then
        callback = decimals
        decimals = 0
    end
    minVal = tonumber(minVal) or 0
    maxVal = tonumber(maxVal) or 100
    if maxVal <= minVal then
        maxVal = minVal + 1
    end
    decimals = math.max(0, math.floor(tonumber(decimals) or 0))
    suffix = suffix and tostring(suffix) or ""

    local multiplier = 10 ^ decimals
    local value = math.clamp(tonumber(default) or minVal, minVal, maxVal)
    local dragging = false

    local row = createRow(section, 42)
    local on = binder(row)
    createTitle(row, name, 100)

    local valueLabel = new("TextLabel", {
        AnchorPoint = Vector2.new(1, 0),
        Position = UDim2.new(1, -10, 0, 0),
        Size = UDim2.new(0, 90, 0, 30),
        BackgroundTransparency = 1,
        FontFace = font(Enum.FontWeight.Medium),
        TextSize = 11,
        TextColor3 = Theme.Muted,
        TextXAlignment = Enum.TextXAlignment.Right,
        Text = "",
    }, row)

    local track = new("Frame", {
        Position = UDim2.new(0, 10, 0, 31),
        Size = UDim2.new(1, -20, 0, 4),
        BackgroundColor3 = Theme.Stroke,
        BorderSizePixel = 0,
    }, row)
    corner(track, 1, 0)

    local fill = new("Frame", {
        Size = UDim2.fromScale(0, 1),
        BackgroundColor3 = Theme.Accent,
        BorderSizePixel = 0,
    }, track)
    corner(fill, 1, 0)

    local knob = new("Frame", {
        AnchorPoint = Vector2.new(0.5, 0.5),
        Position = UDim2.fromScale(0, 0.5),
        Size = UDim2.fromOffset(10, 10),
        BackgroundColor3 = Theme.Text,
        BorderSizePixel = 0,
    }, track)
    corner(knob, 1, 0)

    local hit = new("TextButton", {
        Text = "",
        BackgroundTransparency = 1,
        Size = UDim2.fromScale(1, 1),
    }, row)

    local function format(number)
        if decimals == 0 then
            return string.format("%d", math.round(number)) .. suffix
        end
        return string.format("%." .. decimals .. "f", number) .. suffix
    end

    local function render()
        local alpha = (value - minVal) / (maxVal - minVal)
        fill.Size = UDim2.fromScale(alpha, 1)
        knob.Position = UDim2.fromScale(alpha, 0.5)
        valueLabel.Text = format(value)
    end

    local function set(newValue, fire, force)
        local rounded = math.clamp(math.round((tonumber(newValue) or minVal) * multiplier) / multiplier, minVal, maxVal)
        local changed = rounded ~= value
        value = rounded
        render()
        if fire and (changed or force) and callback then
            safeCall(callback, value)
        end
    end

    local function sample(x)
        local size = track.AbsoluteSize.X
        if size <= 0 then
            return
        end
        local alpha = math.clamp((x - track.AbsolutePosition.X) / size, 0, 1)
        set(minVal + alpha * (maxVal - minVal), true)
    end

    on(hit.InputBegan, function(input)
        if isPress(input) then
            dragging = true
            sample(input.Position.X)
        end
    end)

    on(UserInputService.InputChanged, function(input)
        if dragging and isMove(input) then
            sample(input.Position.X)
        end
    end)

    on(UserInputService.InputEnded, function(input)
        if isPress(input) then
            dragging = false
        end
    end)

    hoverable(row, on)
    render()

    return finish(row, {
        Set = function(_, newValue, fire, force)
            set(newValue, fire, force)
        end,
        Get = function()
            return value
        end,
    })
end

local function createProgressBar(section, name, minVal, maxVal, default)
    minVal = tonumber(minVal) or 0
    maxVal = tonumber(maxVal) or 100
    if maxVal <= minVal then
        maxVal = minVal + 1
    end
    local value = math.clamp(tonumber(default) or minVal, minVal, maxVal)

    local row = createRow(section, 42)
    local on = binder(row)
    createTitle(row, name, 100)

    local valueLabel = new("TextLabel", {
        AnchorPoint = Vector2.new(1, 0),
        Position = UDim2.new(1, -10, 0, 0),
        Size = UDim2.new(0, 90, 0, 30),
        BackgroundTransparency = 1,
        FontFace = font(Enum.FontWeight.Medium),
        TextSize = 11,
        TextColor3 = Theme.Muted,
        TextXAlignment = Enum.TextXAlignment.Right,
        Text = "",
    }, row)

    local track = new("Frame", {
        Position = UDim2.new(0, 10, 0, 31),
        Size = UDim2.new(1, -20, 0, 4),
        BackgroundColor3 = Theme.Stroke,
        BorderSizePixel = 0,
    }, row)
    corner(track, 1, 0)

    local fill = new("Frame", {
        Size = UDim2.fromScale(0, 1),
        BackgroundColor3 = Theme.Accent,
        BorderSizePixel = 0,
    }, track)
    corner(fill, 1, 0)

    local function render()
        local alpha = (value - minVal) / (maxVal - minVal)
        fill.Size = UDim2.fromScale(alpha, 1)
        valueLabel.Text = string.format("%d", math.round(value))
    end

    hoverable(row, on)
    render()

    return finish(row, {
        Set = function(_, newValue)
            value = math.clamp(tonumber(newValue) or value, minVal, maxVal)
            render()
        end,
        Get = function()
            return value
        end,
    })
end

local function createDropdown(section, name, options, default, callback, multi)
    local HEADER, ITEM, MAX_VISIBLE = 30, 22, 6

    options = type(options) == "table" and options or {}
    multi = multi and true or false

    local selected
    local expanded = false
    local items = {}

    local function resetSelection(value)
        if multi then
            selected = {}
            if type(value) == "table" then
                for _, option in ipairs(value) do
                    selected[option] = true
                end
            end
        else
            selected = value ~= nil and value or options[1]
        end
    end

    resetSelection(default)

    local row = createRow(section, HEADER)
    local on = binder(row)
    createTitle(row, name, 170)

    local valueLabel = new("TextLabel", {
        AnchorPoint = Vector2.new(1, 0),
        Position = UDim2.new(1, -26, 0, 0),
        Size = UDim2.new(0, 140, 0, HEADER),
        BackgroundTransparency = 1,
        FontFace = font(),
        TextSize = 11,
        TextColor3 = Theme.Muted,
        TextXAlignment = Enum.TextXAlignment.Right,
        TextTruncate = Enum.TextTruncate.AtEnd,
        Text = "",
    }, row)

    local arrow = new("TextLabel", {
        AnchorPoint = Vector2.new(1, 0),
        Position = UDim2.new(1, -10, 0, 0),
        Size = UDim2.fromOffset(14, HEADER),
        BackgroundTransparency = 1,
        FontFace = font(Enum.FontWeight.Bold),
        TextSize = 11,
        TextColor3 = Theme.Muted,
        Text = "▾",
    }, row)

    local list = new("ScrollingFrame", {
        Position = UDim2.new(0, 8, 0, HEADER + 2),
        Size = UDim2.new(1, -16, 0, 0),
        BackgroundColor3 = Theme.Surface,
        BorderSizePixel = 0,
        ScrollBarThickness = 2,
        ScrollBarImageColor3 = Theme.Muted,
        CanvasSize = UDim2.new(),
        AutomaticCanvasSize = Enum.AutomaticSize.Y,
        ScrollingDirection = Enum.ScrollingDirection.Y,
    }, row)
    corner(list, 0, 4)
    new("UIListLayout", { SortOrder = Enum.SortOrder.LayoutOrder }, list)
    new("UIPadding", {
        PaddingTop = UDim.new(0, 2),
        PaddingBottom = UDim.new(0, 2),
        PaddingLeft = UDim.new(0, 2),
        PaddingRight = UDim.new(0, 2),
    }, list)

    local hit = new("TextButton", {
        Text = "",
        BackgroundTransparency = 1,
        Size = UDim2.new(1, 0, 0, HEADER),
    }, row)

    local function snapshot()
        if multi then
            local result = {}
            for _, option in ipairs(options) do
                if selected[option] then
                    result[#result + 1] = option
                end
            end
            return result
        end
        return selected
    end

    local function summary()
        if multi then
            local parts = {}
            for _, option in ipairs(options) do
                if selected[option] then
                    parts[#parts + 1] = tostring(option)
                end
            end
            return #parts > 0 and table.concat(parts, ", ") or "None"
        end
        return selected ~= nil and tostring(selected) or "None"
    end

    local function refresh()
        valueLabel.Text = summary()
        for _, item in ipairs(items) do
            local active
            if multi then
                active = selected[item.option] == true
            else
                active = selected == item.option
            end
            item.button.TextColor3 = active and Theme.Accent or Theme.Muted
        end
    end

    local function listHeight()
        if #options == 0 then
            return 0
        end
        return math.min(#options, MAX_VISIBLE) * ITEM + 4
    end

    local function setExpanded(value)
        if value == expanded then
            return
        end
        expanded = value
        local height = listHeight()
        tween(row, { Size = UDim2.new(1, 0, 0, value and (HEADER + height + 8) or HEADER) })
        tween(list, { Size = UDim2.new(1, -16, 0, value and height or 0) })
        tween(arrow, { Rotation = value and 180 or 0 })
    end

    local function choose(option)
        if multi then
            selected[option] = (not selected[option]) or nil
        else
            selected = option
            setExpanded(false)
        end
        refresh()
        if callback then
            safeCall(callback, snapshot())
        end
    end

    local function build()
        for _, child in ipairs(list:GetChildren()) do
            if child:IsA("TextButton") then
                child:Destroy()
            end
        end
        table.clear(items)
        for index, option in ipairs(options) do
            local button = new("TextButton", {
                Text = tostring(option),
                FontFace = font(),
                TextSize = 11,
                TextColor3 = Theme.Muted,
                TextXAlignment = Enum.TextXAlignment.Left,
                AutoButtonColor = false,
                BackgroundColor3 = Theme.Hover,
                BackgroundTransparency = 1,
                BorderSizePixel = 0,
                Size = UDim2.new(1, 0, 0, ITEM),
                LayoutOrder = index,
            }, list)
            corner(button, 0, 3)
            new("UIPadding", { PaddingLeft = UDim.new(0, 8) }, button)
            on(button.MouseButton1Click, function()
                choose(option)
            end)
            on(button.MouseEnter, function()
                tween(button, { BackgroundTransparency = 0 })
            end)
            on(button.MouseLeave, function()
                tween(button, { BackgroundTransparency = 1 })
            end)
            items[index] = { option = option, button = button }
        end
        refresh()
    end

    on(hit.MouseButton1Click, function()
        setExpanded(not expanded)
    end)

    on(UserInputService.InputBegan, function(input)
        if not expanded or not isPress(input) then
            return
        end
        local position, size = row.AbsolutePosition, row.AbsoluteSize
        local x, y = input.Position.X, input.Position.Y
        if x < position.X or x > position.X + size.X or y < position.Y or y > position.Y + size.Y then
            setExpanded(false)
        end
    end)

    hoverable(row, on)
    build()

    return finish(row, {
        Set = function(_, value, fire)
            resetSelection(value)
            refresh()
            if fire and callback then
                safeCall(callback, snapshot())
            end
        end,
        Get = snapshot,
        SetOptions = function(_, newOptions, newDefault, fire)
            setExpanded(false)
            options = type(newOptions) == "table" and newOptions or {}
            resetSelection(newDefault)
            build()
            if fire and callback then
                safeCall(callback, snapshot())
            end
        end,
        Refresh = function(_, newOptions, fire)
            setExpanded(false)
            options = type(newOptions) == "table" and newOptions or options
            build()
            if fire and callback then
                safeCall(callback, snapshot())
            end
        end,
    })
end

local function resolveKey(value)
    if typeof(value) == "EnumItem" and value.EnumType == Enum.KeyCode then
        return value
    end
    if type(value) == "string" then
        local ok, result = pcall(function()
            return Enum.KeyCode[value]
        end)
        if ok and result then
            return result
        end
    end
    return Enum.KeyCode.Unknown
end

local function createKeybind(section, name, default, callback, changed, ignoreProcessed)
    local row = createRow(section, 30)
    local on = binder(row)
    createTitle(row, name, 94)

    local key = resolveKey(default)
    local listening = false

    local button = new("TextButton", {
        AnchorPoint = Vector2.new(1, 0.5),
        Position = UDim2.new(1, -10, 0, 15),
        Size = UDim2.fromOffset(72, 20),
        BackgroundColor3 = Theme.Surface,
        BorderSizePixel = 0,
        AutoButtonColor = false,
        FontFace = font(Enum.FontWeight.Medium),
        TextSize = 11,
        TextColor3 = Theme.Text,
        TextTruncate = Enum.TextTruncate.AtEnd,
        Text = "",
    }, row)
    corner(button, 0, 4)
    stroke(button)

    local function render()
        if listening then
            button.Text = "..."
            button.TextColor3 = Theme.Accent
        else
            button.Text = key == Enum.KeyCode.Unknown and "None" or key.Name
            button.TextColor3 = Theme.Text
        end
    end

    on(button.MouseButton1Click, function()
        if listening then
            return
        end
        listening = true
        render()
    end)

    on(UserInputService.InputBegan, function(input, processed)
        if input.UserInputType ~= Enum.UserInputType.Keyboard then
            return
        end
        if listening then
            listening = false
            if input.KeyCode ~= Enum.KeyCode.Escape then
                key = input.KeyCode == Enum.KeyCode.Backspace and Enum.KeyCode.Unknown or input.KeyCode
                if changed then
                    safeCall(changed, key)
                elseif callback then
                    safeCall(callback, key)
                end
            end
            render()
            return
        end
        if (processed and not ignoreProcessed) or key == Enum.KeyCode.Unknown then
            return
        end
        if input.KeyCode == key and callback then
            safeCall(callback, key)
        end
    end)

    hoverable(row, on)
    render()

    return finish(row, {
        Set = function(_, value, fire)
            key = resolveKey(value)
            render()
            if fire and changed then
                safeCall(changed, key)
            end
        end,
        Get = function()
            return key
        end,
        IsPressed = function()
            return key ~= Enum.KeyCode.Unknown and UserInputService:IsKeyDown(key)
        end,
    })
end

local function createTextBox(section, name, placeholder, default, callback)
    local row = createRow(section, 30)
    local on = binder(row)

    local title = createTitle(row, name)
    title.Size = UDim2.new(0.45, -10, 0, 30)

    local input = new("TextBox", {
        AnchorPoint = Vector2.new(1, 0.5),
        Position = UDim2.new(1, -10, 0, 15),
        Size = UDim2.new(0.55, -10, 0, 20),
        BackgroundColor3 = Theme.Surface,
        BorderSizePixel = 0,
        ClearTextOnFocus = false,
        ClipsDescendants = true,
        FontFace = font(),
        TextSize = 11,
        TextColor3 = Theme.Text,
        PlaceholderColor3 = Theme.Muted,
        PlaceholderText = placeholder or "Type here...",
        TextXAlignment = Enum.TextXAlignment.Left,
        TextTruncate = Enum.TextTruncate.AtEnd,
        Text = tostring(default or ""),
    }, row)
    corner(input, 0, 4)
    new("UIPadding", {
        PaddingLeft = UDim.new(0, 6),
        PaddingRight = UDim.new(0, 6),
    }, input)
    local border = stroke(input)

    on(input.Focused, function()
        tween(border, { Color = Theme.Accent })
    end)

    on(input.FocusLost, function(enterPressed)
        tween(border, { Color = Theme.Stroke })
        if callback then
            safeCall(callback, input.Text, enterPressed)
        end
    end)

    hoverable(row, on)

    return finish(row, {
        Set = function(_, value)
            input.Text = tostring(value or "")
        end,
        Get = function()
            return input.Text
        end,
    })
end

local function createColorPicker(section, name, default, callback)
    local HEADER, SV_HEIGHT, HUE_HEIGHT = 30, 80, 10
    local HOLDER_HEIGHT = SV_HEIGHT + 10 + HUE_HEIGHT
    local EXPANDED = HEADER + 4 + HOLDER_HEIGHT + 8

    default = typeof(default) == "Color3" and default or Color3.new(1, 1, 1)

    local h, s, v = Color3.toHSV(default)
    local expanded = false
    local mode = nil

    local row = createRow(section, HEADER)
    local on = binder(row)
    createTitle(row, name, 110)

    local hexLabel = new("TextButton", {
        AnchorPoint = Vector2.new(1, 0),
        Position = UDim2.new(1, -42, 0, 0),
        Size = UDim2.new(0, 64, 0, HEADER),
        BackgroundTransparency = 1,
        AutoButtonColor = false,
        FontFace = font(Enum.FontWeight.Medium),
        TextSize = 11,
        TextColor3 = Theme.Muted,
        TextXAlignment = Enum.TextXAlignment.Right,
        Text = "",
    }, row)
    on(hexLabel.MouseButton1Click, function()
        local text = hexLabel.Text
        if text == "" or text == "copied!" then
            return
        end
        local ok = pcall(function()
            if setclipboard then
                setclipboard(text)
            elseif toclipboard then
                toclipboard(text)
            end
        end)
        if ok then
            hexLabel.Text = "copied!"
            task.delay(0.8, function()
                if hexLabel.Parent then
                    hexLabel.Text = text
                end
            end)
        end
    end)

    local swatch = new("Frame", {
        AnchorPoint = Vector2.new(1, 0.5),
        Position = UDim2.new(1, -10, 0, 15),
        Size = UDim2.fromOffset(24, 14),
        BackgroundColor3 = default,
        BorderSizePixel = 0,
    }, row)
    corner(swatch, 0, 3)
    stroke(swatch)

    local header = new("TextButton", {
        Text = "",
        BackgroundTransparency = 1,
        Size = UDim2.new(1, 0, 0, HEADER),
    }, row)

    local holder = new("Frame", {
        Position = UDim2.new(0, 10, 0, HEADER + 4),
        Size = UDim2.new(1, -20, 0, HOLDER_HEIGHT),
        BackgroundTransparency = 1,
    }, row)

    local svBox = new("TextButton", {
        Text = "",
        AutoButtonColor = false,
        BackgroundColor3 = Color3.fromHSV(h, 1, 1),
        BorderSizePixel = 0,
        Size = UDim2.new(1, 0, 0, SV_HEIGHT),
    }, holder)
    corner(svBox, 0, 4)

    local white = new("Frame", {
        BackgroundColor3 = Color3.new(1, 1, 1),
        BorderSizePixel = 0,
        Size = UDim2.fromScale(1, 1),
        ZIndex = 2,
    }, svBox)
    corner(white, 0, 4)
    new("UIGradient", { Transparency = NumberSequence.new(0, 1) }, white)

    local black = new("Frame", {
        BackgroundColor3 = Color3.new(0, 0, 0),
        BorderSizePixel = 0,
        Size = UDim2.fromScale(1, 1),
        ZIndex = 3,
    }, svBox)
    corner(black, 0, 4)
    new("UIGradient", { Rotation = 90, Transparency = NumberSequence.new(1, 0) }, black)

    local svKnob = new("Frame", {
        AnchorPoint = Vector2.new(0.5, 0.5),
        Size = UDim2.fromOffset(10, 10),
        BackgroundTransparency = 1,
        ZIndex = 4,
    }, svBox)
    corner(svKnob, 1, 0)
    stroke(svKnob, Color3.new(1, 1, 1), 2)

    local hueTrack = new("TextButton", {
        Text = "",
        AutoButtonColor = false,
        BackgroundColor3 = Color3.new(1, 1, 1),
        BorderSizePixel = 0,
        Position = UDim2.new(0, 0, 0, SV_HEIGHT + 10),
        Size = UDim2.new(1, 0, 0, HUE_HEIGHT),
    }, holder)
    corner(hueTrack, 1, 0)

    local hueKeys = {}
    for index = 0, 6 do
        hueKeys[#hueKeys + 1] = ColorSequenceKeypoint.new(index / 6, Color3.fromHSV(index / 6, 1, 1))
    end
    new("UIGradient", { Color = ColorSequence.new(hueKeys) }, hueTrack)

    local hueKnob = new("Frame", {
        AnchorPoint = Vector2.new(0.5, 0.5),
        Size = UDim2.fromOffset(4, HUE_HEIGHT + 4),
        BackgroundColor3 = Color3.new(1, 1, 1),
        BorderSizePixel = 0,
    }, hueTrack)
    corner(hueKnob, 0, 2)
    stroke(hueKnob, Theme.Background, 1)

    local function apply(fire)
        local color = Color3.fromHSV(h, s, v)
        swatch.BackgroundColor3 = color
        svBox.BackgroundColor3 = Color3.fromHSV(h, 1, 1)
        svKnob.Position = UDim2.fromScale(s, 1 - v)
        hueKnob.Position = UDim2.new(h, 0, 0.5, 0)
        hexLabel.Text = "#" .. string.upper(color:ToHex())
        if fire and callback then
            safeCall(callback, color)
        end
    end

    local function sample(position)
        if mode == "sv" then
            local origin, size = svBox.AbsolutePosition, svBox.AbsoluteSize
            if size.X <= 0 or size.Y <= 0 then
                return
            end
            s = math.clamp((position.X - origin.X) / size.X, 0, 1)
            v = 1 - math.clamp((position.Y - origin.Y) / size.Y, 0, 1)
        elseif mode == "hue" then
            local origin, size = hueTrack.AbsolutePosition, hueTrack.AbsoluteSize
            if size.X <= 0 then
                return
            end
            h = math.clamp((position.X - origin.X) / size.X, 0, 1)
        else
            return
        end
        apply(true)
    end

    on(header.MouseButton1Click, function()
        expanded = not expanded
        tween(row, { Size = UDim2.new(1, 0, 0, expanded and EXPANDED or HEADER) })
    end)

    on(svBox.InputBegan, function(input)
        if isPress(input) then
            mode = "sv"
            sample(input.Position)
        end
    end)

    on(hueTrack.InputBegan, function(input)
        if isPress(input) then
            mode = "hue"
            sample(input.Position)
        end
    end)

    on(UserInputService.InputChanged, function(input)
        if mode and isMove(input) then
            sample(input.Position)
        end
    end)

    on(UserInputService.InputEnded, function(input)
        if isPress(input) then
            mode = nil
        end
    end)

    hoverable(row, on)
    apply(false)

    return finish(row, {
        Set = function(_, color, fire)
            if typeof(color) == "Color3" then
                h, s, v = Color3.toHSV(color)
                apply(fire)
            end
        end,
        Get = function()
            return Color3.fromHSV(h, s, v)
        end,
    })
end

local function createButton(section, name, callback)
    local row = createRow(section, 30)
    local on = binder(row)

    local button = new("TextButton", {
        Text = name or "Button",
        AutoButtonColor = false,
        BackgroundColor3 = Theme.Surface,
        BorderSizePixel = 0,
        Size = UDim2.fromScale(1, 1),
        FontFace = font(Enum.FontWeight.Medium),
        TextSize = 12,
        TextColor3 = Theme.Text,
    }, row)
    corner(button, 0, 4)
    stroke(button)

    on(button.MouseEnter, function()
        tween(button, { BackgroundColor3 = Theme.Hover })
    end)
    on(button.MouseLeave, function()
        tween(button, { BackgroundColor3 = Theme.Surface })
    end)
    on(button.MouseButton1Click, function()
        button.BackgroundColor3 = Theme.Accent
        tween(button, { BackgroundColor3 = Theme.Hover })
        if callback then
            safeCall(callback)
        end
    end)

    return finish(row, {
        SetText = function(_, text)
            button.Text = tostring(text)
        end,
        Fire = function(_, ...)
            if callback then
                safeCall(callback, ...)
            end
        end,
    })
end

local function createLabel(section, text)
    local row = createRow(section, 0, true)

    local label = new("TextLabel", {
        Name = "Title",
        BackgroundTransparency = 1,
        AutomaticSize = Enum.AutomaticSize.Y,
        Size = UDim2.new(1, 0, 0, 0),
        FontFace = font(),
        TextSize = 11,
        TextColor3 = Theme.Muted,
        TextWrapped = true,
        TextXAlignment = Enum.TextXAlignment.Left,
        TextYAlignment = Enum.TextYAlignment.Top,
        Text = tostring(text or ""),
    }, row)
    new("UIPadding", {
        PaddingTop = UDim.new(0, 5),
        PaddingBottom = UDim.new(0, 5),
        PaddingLeft = UDim.new(0, 10),
        PaddingRight = UDim.new(0, 10),
    }, label)

    return finish(row, {
        SetText = function(_, value)
            label.Text = tostring(value)
        end,
        Get = function()
            return label.Text
        end,
    })
end

local function createSeparator(section)
    local row = createRow(section, 9)
    new("Frame", {
        AnchorPoint = Vector2.new(0, 0.5),
        Position = UDim2.new(0, 10, 0.5, 0),
        Size = UDim2.new(1, -20, 0, 1),
        BackgroundColor3 = Theme.Stroke,
        BorderSizePixel = 0,
    }, row)
    return finish(row, {})
end

local function createInput(section, name, default, minVal, maxVal, decimals, callback)
    minVal = tonumber(minVal)
    maxVal = tonumber(maxVal)
    decimals = math.max(0, math.floor(tonumber(decimals) or 0))

    local row = createRow(section, 30)
    local on = binder(row)

    local title = createTitle(row, name)
    title.Size = UDim2.new(0.45, -10, 0, 30)

    local input = new("TextBox", {
        AnchorPoint = Vector2.new(1, 0.5),
        Position = UDim2.new(1, -10, 0, 15),
        Size = UDim2.new(0.55, -10, 0, 20),
        BackgroundColor3 = Theme.Surface,
        BorderSizePixel = 0,
        ClearTextOnFocus = false,
        ClipsDescendants = true,
        FontFace = font(),
        TextSize = 11,
        TextColor3 = Theme.Text,
        PlaceholderColor3 = Theme.Muted,
        PlaceholderText = "0",
        TextXAlignment = Enum.TextXAlignment.Right,
        Text = tostring(default or 0),
    }, row)
    corner(input, 0, 4)
    new("UIPadding", {
        PaddingRight = UDim.new(0, 6),
    }, input)
    local border = stroke(input)

    local function clampValue(v)
        v = tonumber(v) or minVal or 0
        if minVal and v < minVal then
            v = minVal
        end
        if maxVal and v > maxVal then
            v = maxVal
        end
        if decimals > 0 then
            local mult = 10 ^ decimals
            v = math.round(v * mult) / mult
        else
            v = math.round(v)
        end
        return v
    end

    on(input.Focused, function()
        tween(border, { Color = Theme.Accent })
    end)

    on(input.FocusLost, function(enterPressed)
        tween(border, { Color = Theme.Stroke })
        local v = clampValue(input.Text)
        input.Text = tostring(v)
        if callback then
            safeCall(callback, v, enterPressed)
        end
    end)

    hoverable(row, on)

    return finish(row, {
        Set = function(_, value)
            local v = clampValue(value)
            input.Text = tostring(v)
        end,
        Get = function()
            return clampValue(input.Text)
        end,
    })
end

local function createToggleKeybind(section, name, defaultToggle, defaultKey, toggleCb, keyCb, changedCb)
    local row = createRow(section, 30)
    local on = binder(row)
    createTitle(row, name, 180)

    local state = defaultToggle and true or false
    local key = resolveKey(defaultKey)
    local listening = false

    local track = new("Frame", {
        AnchorPoint = Vector2.new(1, 0.5),
        Position = UDim2.new(1, -10, 0, 15),
        Size = UDim2.fromOffset(30, 16),
        BackgroundColor3 = Theme.Stroke,
        BorderSizePixel = 0,
    }, row)
    corner(track, 1, 0)

    local knob = new("Frame", {
        AnchorPoint = Vector2.new(0, 0.5),
        Position = UDim2.new(0, 2, 0.5, 0),
        Size = UDim2.fromOffset(12, 12),
        BackgroundColor3 = Theme.Muted,
        BorderSizePixel = 0,
    }, track)
    corner(knob, 1, 0)

    local keyButton = new("TextButton", {
        AnchorPoint = Vector2.new(1, 0.5),
        Position = UDim2.new(1, -48, 0, 15),
        Size = UDim2.fromOffset(72, 20),
        BackgroundColor3 = Theme.Surface,
        BorderSizePixel = 0,
        AutoButtonColor = false,
        FontFace = font(Enum.FontWeight.Medium),
        TextSize = 11,
        TextColor3 = Theme.Text,
        Text = "",
    }, row)
    corner(keyButton, 0, 4)
    stroke(keyButton)

    local hit = new("TextButton", {
        Text = "",
        BackgroundTransparency = 1,
        Size = UDim2.new(1, -130, 1, 0),
        Position = UDim2.new(0, 0, 0, 0),
    }, row)

    local function renderToggle(animate)
        local pos = state and UDim2.new(1, -14, 0.5, 0) or UDim2.new(0, 2, 0.5, 0)
        local tc = state and Theme.Accent or Theme.Stroke
        local kc = state and Theme.Text or Theme.Muted
        if animate then
            tween(knob, { Position = pos, BackgroundColor3 = kc })
            tween(track, { BackgroundColor3 = tc })
        else
            knob.Position = pos
            knob.BackgroundColor3 = kc
            track.BackgroundColor3 = tc
        end
    end

    local function renderKey()
        if listening then
            keyButton.Text = "..."
            keyButton.TextColor3 = Theme.Accent
        else
            keyButton.Text = key == Enum.KeyCode.Unknown and "None" or key.Name
            keyButton.TextColor3 = Theme.Text
        end
    end

    local function setToggle(value, fire, force)
        local nextState = value and true or false
        local changed = nextState ~= state
        state = nextState
        renderToggle(true)
        if (changed or force) and toggleCb then
            safeCall(toggleCb, state)
        end
    end

    on(hit.MouseButton1Click, function()
        setToggle(not state, true)
    end)

    on(keyButton.MouseButton1Click, function()
        if listening then
            return
        end
        listening = true
        renderKey()
    end)

    on(UserInputService.InputBegan, function(input, processed)
        if input.UserInputType ~= Enum.UserInputType.Keyboard then
            return
        end
        if listening then
            listening = false
            if input.KeyCode ~= Enum.KeyCode.Escape then
                key = input.KeyCode == Enum.KeyCode.Backspace and Enum.KeyCode.Unknown or input.KeyCode
                if changedCb then
                    safeCall(changedCb, key)
                end
            end
            renderKey()
            return
        end
        if processed or key == Enum.KeyCode.Unknown then
            return
        end
        if input.KeyCode == key and keyCb then
            safeCall(keyCb, key)
        end
    end)

    hoverable(row, on)
    renderToggle(false)
    renderKey()

    if toggleCb then
        safeCall(toggleCb, state)
    end

    return finish(row, {
        Set = function(_, value, fire, force)
            setToggle(value, fire, force)
        end,
        Get = function()
            return state
        end,
        GetKey = function()
            return key
        end,
        SetKey = function(_, value, fire)
            key = resolveKey(value)
            renderKey()
            if fire and changedCb then
                safeCall(changedCb, key)
            end
        end,
        IsPressed = function()
            return key ~= Enum.KeyCode.Unknown and UserInputService:IsKeyDown(key)
        end,
    })
end

local function createFolder(section, name, collapsed)
    local HEADER = 24
    local open = not collapsed

    local holder = new("Frame", {
        Name = "ExtFolder",
        BackgroundColor3 = Theme.Surface,
        BackgroundTransparency = 0.5,
        BorderSizePixel = 0,
        Size = UDim2.new(1, 0, 0, HEADER),
        LayoutOrder = nextOrder(section),
        ClipsDescendants = true,
    }, section)
    corner(holder, 0, 4)
    stroke(holder)

    local header = new("TextButton", {
        Name = "Header",
        Text = "",
        BackgroundTransparency = 1,
        AutoButtonColor = false,
        Size = UDim2.new(1, 0, 0, HEADER),
    }, holder)

    local arrow = new("TextLabel", {
        AnchorPoint = Vector2.new(0, 0.5),
        Position = UDim2.new(0, 8, 0, HEADER / 2),
        Size = UDim2.fromOffset(12, 12),
        BackgroundTransparency = 1,
        FontFace = font(Enum.FontWeight.Bold),
        TextSize = 10,
        TextColor3 = Theme.Accent,
        Text = open and "▾" or "▸",
        TextXAlignment = Enum.TextXAlignment.Left,
    }, holder)

    local label = new("TextLabel", {
        Position = UDim2.new(0, 26, 0, 0),
        Size = UDim2.new(1, -34, 0, HEADER),
        BackgroundTransparency = 1,
        FontFace = font(Enum.FontWeight.SemiBold),
        TextSize = 11,
        TextColor3 = Theme.Text,
        TextXAlignment = Enum.TextXAlignment.Left,
        Text = tostring(name or "Folder"),
    }, holder)

    local body = new("Frame", {
        Name = "Body",
        Position = UDim2.new(0, 0, 0, HEADER),
        Size = UDim2.new(1, 0, 0, 0),
        BackgroundTransparency = 1,
        ClipsDescendants = true,
    }, holder)
    local listLayout = new("UIListLayout", {
        SortOrder = Enum.SortOrder.LayoutOrder,
        Padding = UDim.new(0, 4),
    }, body)
    new("UIPadding", {
        PaddingTop = UDim.new(0, 4),
        PaddingBottom = UDim.new(0, 4),
        PaddingLeft = UDim.new(0, 4),
        PaddingRight = UDim.new(0, 4),
    }, body)

    local function bodyHeight()
        return listLayout.AbsoluteContentSize.Y + 8
    end

    local function render()
        arrow.Text = open and "▾" or "▸"
        local h = open and bodyHeight() or 0
        tween(holder, { Size = UDim2.new(1, 0, 0, HEADER + h) })
        tween(body, { Size = UDim2.new(1, 0, 0, h) })
    end

    local on = binder(holder)
    on(header.MouseButton1Click, function()
        open = not open
        render()
    end)

    listLayout:GetPropertyChangedSignal("AbsoluteContentSize"):Connect(function()
        if open then
            render()
        end
    end)

    render()

    local folderApi = {}
    folderApi.Container = holder
    folderApi.Body = body

    folderApi.AddToggle = function(_, ...)
        local r = createToggle(body, ...)
        task.defer(render)
        return r
    end
    folderApi.AddSlider = function(_, ...)
        local r = createSlider(body, ...)
        task.defer(render)
        return r
    end
    folderApi.AddDropdown = function(_, ...)
        local r = createDropdown(body, ...)
        task.defer(render)
        return r
    end
    folderApi.AddKeybind = function(_, ...)
        local r = createKeybind(body, ...)
        task.defer(render)
        return r
    end
    folderApi.AddTextBox = function(_, ...)
        local r = createTextBox(body, ...)
        task.defer(render)
        return r
    end
    folderApi.AddColorPicker = function(_, ...)
        local r = createColorPicker(body, ...)
        task.defer(render)
        return r
    end
    folderApi.AddButton = function(_, ...)
        local r = createButton(body, ...)
        task.defer(render)
        return r
    end
    folderApi.AddLabel = function(_, ...)
        local r = createLabel(body, ...)
        task.defer(render)
        return r
    end
    folderApi.AddSeparator = function()
        local r = createSeparator(body)
        task.defer(render)
        return r
    end
    folderApi.SetOpen = function(_, value)
        open = value and true or false
        render()
    end
    folderApi.IsOpen = function()
        return open
    end
    folderApi.Destroy = function()
        holder:Destroy()
    end
    folderApi.SetTitle = function(_, text)
        label.Text = tostring(text)
    end

    return folderApi
end

local notifyHolder

local function getNotifyHolder()
    if notifyHolder and notifyHolder.Parent then
        return notifyHolder
    end

    local gui = new("ScreenGui", {
        Name = "NeverLoseExtNotify",
        ResetOnSpawn = false,
        IgnoreGuiInset = true,
        DisplayOrder = 1000,
        ZIndexBehavior = Enum.ZIndexBehavior.Sibling,
    })
    if syn and syn.protect_gui then
        pcall(syn.protect_gui, gui)
    end
    gui.Parent = (gethui and gethui()) or CoreGui

    notifyHolder = new("Frame", {
        AnchorPoint = Vector2.new(1, 1),
        Position = UDim2.new(1, -16, 1, -16),
        Size = UDim2.new(0, 260, 1, -32),
        BackgroundTransparency = 1,
    }, gui)
    new("UIListLayout", {
        SortOrder = Enum.SortOrder.LayoutOrder,
        HorizontalAlignment = Enum.HorizontalAlignment.Right,
        VerticalAlignment = Enum.VerticalAlignment.Bottom,
        Padding = UDim.new(0, 6),
    }, notifyHolder)

    return notifyHolder
end

function NEVERLOSE:Notify(title, text, duration, kind)
    duration = tonumber(duration) or 4

    local NOTIFY_ICONS = {
        error = { tag = "[!]", color = Color3.fromRGB(255, 90, 90) },
        success = { tag = "[+]", color = Color3.fromRGB(90, 220, 130) },
        warning = { tag = "[~]", color = Color3.fromRGB(255, 190, 80) },
        info = { tag = "[i]", color = Theme.Accent },
    }
    local iconInfo = kind and NOTIFY_ICONS[tostring(kind):lower()] or nil

    local card = new("CanvasGroup", {
        BackgroundColor3 = Theme.Background,
        BorderSizePixel = 0,
        AutomaticSize = Enum.AutomaticSize.Y,
        Size = UDim2.new(1, 0, 0, 0),
        GroupTransparency = 1,
    }, getNotifyHolder())
    corner(card, 0, 4)
    stroke(card)
    new("UIListLayout", {
        SortOrder = Enum.SortOrder.LayoutOrder,
        Padding = UDim.new(0, 2),
    }, card)
    new("UIPadding", {
        PaddingTop = UDim.new(0, 8),
        PaddingBottom = UDim.new(0, 9),
        PaddingLeft = UDim.new(0, 10),
        PaddingRight = UDim.new(0, 10),
    }, card)

    new("TextLabel", {
        BackgroundTransparency = 1,
        AutomaticSize = Enum.AutomaticSize.Y,
        Size = UDim2.new(1, 0, 0, 0),
        FontFace = font(Enum.FontWeight.SemiBold),
        TextSize = 12,
        TextColor3 = iconInfo and iconInfo.color or Theme.Text,
        TextWrapped = true,
        TextXAlignment = Enum.TextXAlignment.Left,
        Text = iconInfo and (iconInfo.tag .. " " .. tostring(title or "")) or tostring(title or ""),
        LayoutOrder = 1,
    }, card)

    if text and text ~= "" then
        new("TextLabel", {
            BackgroundTransparency = 1,
            AutomaticSize = Enum.AutomaticSize.Y,
            Size = UDim2.new(1, 0, 0, 0),
            FontFace = font(),
            TextSize = 11,
            TextColor3 = Theme.Muted,
            TextWrapped = true,
            TextXAlignment = Enum.TextXAlignment.Left,
            Text = tostring(text),
            LayoutOrder = 2,
        }, card)
    end

    tween(card, { GroupTransparency = 0 })

    local dismiss = new("TextButton", {
        Text = "",
        BackgroundTransparency = 1,
        Size = UDim2.fromScale(1, 1),
        ZIndex = 100,
    }, card)
    dismiss.MouseButton1Click:Connect(function()
        if card.Parent then
            tween(card, { GroupTransparency = 1 })
            task.delay(FAST.Time + 0.05, function()
                if card.Parent then
                    card:Destroy()
                end
            end)
        end
    end)

    task.delay(duration, function()
        if card.Parent then
            tween(card, { GroupTransparency = 1 })
            task.wait(FAST.Time + 0.05)
            card:Destroy()
        end
    end)
end

local function extendSection(section)
    if type(section) ~= "table" or section._extended then
        return section
    end

    local frame = findSectionFrame(section)
    if not frame then
        warn("[NeverLose-Ext] Section frame tidak ditemukan")
        if NEVERLOSE._extInfo then
            NEVERLOSE._extInfo.sectionsFailed += 1
        end
        return section
    end

    prepareSection(frame)

    section.AddToggle = function(_, ...)
        return createToggle(frame, ...)
    end
    section.AddSlider = function(_, ...)
        return createSlider(frame, ...)
    end
    section.AddDropdown = function(_, ...)
        return createDropdown(frame, ...)
    end
    section.AddKeybind = function(_, ...)
        return createKeybind(frame, ...)
    end
    section.AddTextBox = function(_, ...)
        return createTextBox(frame, ...)
    end
    section.AddColorPicker = function(_, ...)
        return createColorPicker(frame, ...)
    end
    section.AddButton = function(_, ...)
        return createButton(frame, ...)
    end
    section.AddLabel = function(_, ...)
        return createLabel(frame, ...)
    end
    section.AddProgressBar = function(_, ...)
        return createProgressBar(frame, ...)
    end
    section.AddSeparator = function()
        return createSeparator(frame)
    end
    section.AddInput = function(_, ...)
        return createInput(frame, ...)
    end
    section.AddToggleKeybind = function(_, ...)
        return createToggleKeybind(frame, ...)
    end
    section.AddFolder = function(_, ...)
        return createFolder(frame, ...)
    end

    section._extended = true
    section._frame = frame
    if NEVERLOSE._extInfo then
        NEVERLOSE._extInfo.sectionsExtended += 1
    end
    return section
end

local function extendTab(tab)
    if type(tab) ~= "table" or tab._patched then
        return tab
    end
    local original = tab.AddSection
    if type(original) ~= "function" then
        return tab
    end
    tab.AddSection = function(self, ...)
        local ok, result = pcall(original, self, ...)
        if not ok then
            warn("[NeverLose-Ext] AddSection error: " .. tostring(result))
            return nil
        end
        return extendSection(result)
    end
    tab._patched = true
    return tab
end

local function extendWindow(window)
    if type(window) ~= "table" or window._patched then
        return window
    end
    local original = window.AddTab
    if type(original) ~= "function" then
        return window
    end
    window.AddTab = function(self, ...)
        local ok, result = pcall(original, self, ...)
        if not ok then
            warn("[NeverLose-Ext] AddTab error: " .. tostring(result))
            return nil
        end
        return extendTab(result)
    end
    local okExtras = pcall(attachWindowExtras, window, original)
    if not okExtras then
        warn("[NeverLose-Ext] window extras failed")
    end
    window._patched = true
    return window
end

local originalAddWindow = NEVERLOSE.AddWindow
if type(originalAddWindow) == "function" then
    NEVERLOSE.AddWindow = function(self, ...)
        local ok, result = pcall(originalAddWindow, self, ...)
        if not ok then
            warn("[NeverLose-Ext] AddWindow error: " .. tostring(result))
            return nil
        end
        return extendWindow(result)
    end
end

NEVERLOSE._extended = true
NEVERLOSE._extInfo = NEVERLOSE._extInfo or {
    version = "5.1.0-ext",
    loadedAt = (os and os.time and os.time()) or 0,
    hasUpvalueScanner = (getUpvalues ~= nil),
    hasGCFallback = (getGC ~= nil),
    sectionsExtended = 0,
    sectionsFailed = 0,
}

NEVERLOSE._extUnload = function()
    if originalAddWindow then
        NEVERLOSE.AddWindow = originalAddWindow
    end
    NEVERLOSE._extended = false
    NEVERLOSE._extInfo = nil
    return true
end

return NEVERLOSE
