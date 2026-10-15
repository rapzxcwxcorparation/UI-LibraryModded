--[[
	NEVERLOSE UI - PREVIEW / TEST SCRIPT (self-fix)
	===============================================
	Loads library from GitHub, builds every tab, then applies
	mobile-friendly UI scale + compact notifications locally.
	Execute as-is in your executor.
]]

local URL = "https://raw.githubusercontent.com/rapzxcwxcorparation/UI-LibraryModded/refs/heads/main/neverlose_modded.luau"

local src = game:HttpGet(URL .. "?v=" .. tostring(tick()))
assert(type(src) == "string" and #src > 0, "Failed to fetch library source")

local chunk, err = loadstring(src, "neverlose_modded")
assert(chunk, "loadstring failed: " .. tostring(err))

local NEVERLOSE = chunk()
assert(type(NEVERLOSE) == "table", "Library did not return a table")

-- =====================================================================
-- LOCAL UI FIXES (applied on top of whatever the lib gives us)
-- =====================================================================

local function applyScale(scaleGui, baseSize)
	local cam = workspace.CurrentCamera
	if not cam or not scaleGui then return end
	local vp = cam.ViewportSize
	local w = baseSize.X.Scale * vp.X + baseSize.X.Offset
	local h = baseSize.Y.Scale * vp.Y + baseSize.Y.Offset
	if w <= 0 or h <= 0 then return end
	local us = scaleGui:FindFirstChildOfClass("UIScale")
	if not us then
		us = Instance.new("UIScale")
		us.Parent = scaleGui
	end
	us.Scale = math.min(1, (vp.X * 0.78) / w, (vp.Y * 0.68) / h)
end

local function hookScale(scaleGui, baseSize)
	task.spawn(function()
		applyScale(scaleGui, baseSize)
		local cam = workspace.CurrentCamera
		if cam then
			cam:GetPropertyChangedSignal("ViewportSize"):Connect(function()
				applyScale(scaleGui, baseSize)
			end)
		end
	end)
end

local function findNotifyGui()
	local parent = (gethui and gethui()) or game:FindFirstChild("CoreGui") or game.Players.LocalPlayer.PlayerGui
	for _, g in ipairs(parent:GetDescendants()) do
		if g.Name == "NeverLoseModNotify" and g:IsA("ScreenGui") then
			return g
		end
	end
	return nil
end

local function compactNotify()
	task.spawn(function()
		for _ = 1, 60 do
			local gui = findNotifyGui()
			if gui then
				local holder
				for _, c in ipairs(gui:GetChildren()) do
					if c:IsA("Frame") then holder = c; break end
				end
				if holder then
					local function setW()
						local cam = workspace.CurrentCamera
						local vp = cam and cam.ViewportSize or Vector2.new(1280, 720)
						local w = math.clamp(math.floor(vp.X * 0.52), 170, 240)
						holder.Size = UDim2.new(0, w, 0, holder.Size.Y.Offset)
					end
					setW()
					local cam = workspace.CurrentCamera
					if cam then
						cam:GetPropertyChangedSignal("ViewportSize"):Connect(setW)
					end
					return
				end
			end
			task.wait(0.1)
		end
	end)
end

-- =====================================================================
-- PREVIEW
-- =====================================================================

local pvReady = false
task.delay(1.2, function() pvReady = true end)

local function pvNotify(title, text, kind)
	if not pvReady then return end
	NEVERLOSE:Notify(tostring(title), tostring(text), 3, kind or "info")
end

local BASE_SIZE = UDim2.new(0, 720, 0, 500)
local Window = NEVERLOSE:AddWindow("NEVERLOSE PREVIEW", "component showcase", BASE_SIZE)

task.spawn(function()
	task.wait(0.3)
	local parent = (gethui and gethui()) or game:FindFirstChild("CoreGui") or game.Players.LocalPlayer.PlayerGui
	for _, g in ipairs(parent:GetDescendants()) do
		if g:IsA("ScreenGui") and g ~= findNotifyGui() then
			local hasFrame = false
			for _, c in ipairs(g:GetChildren()) do
				if c:IsA("Frame") and c.Active then hasFrame = true; break end
			end
			if hasFrame then hookScale(g, BASE_SIZE) end
		end
	end
end)

compactNotify()

-- =====================================================================
-- TAB 1 : CONTROLS
-- =====================================================================
local TabControls = Window:AddTab("Controls", "home")
do
	local s = TabControls:AddSection("Basic Controls")
	s:AddLabel("Preview: every NVM component is showcased here.")
	s:AddToggle("Toggle Example", true, function(v)
		pvNotify("Toggle", "Value: " .. tostring(v), "info")
	end)
	s:AddSlider("Slider Example", 0, 100, 50, function(v) end)
	s:AddButton("Click Me", function()
		NEVERLOSE:Notify("Button", "Button pressed!", 3, "success")
	end)
	s:AddSeparator()
	s:AddLabel("Muted label. Hidden/shown via :Status().")

	local s2 = TabControls:AddSection("Notifications", "right")
	local lbl = s2:AddLabel("Notifications fire from the buttons below.")
	s2:AddToggle("Show Info Label", true, function(v)
		lbl:Status(v)
	end)
	s2:AddButton("Notify Info", function()
		NEVERLOSE:Notify("Info", "Sample info notification", 3, "info")
	end)
	s2:AddButton("Notify Success", function()
		NEVERLOSE:Notify("Success", "Sample success notification", 3, "success")
	end)
	s2:AddButton("Notify Warning", function()
		NEVERLOSE:Notify("Warning", "Sample warning notification", 3, "warning")
	end)
	s2:AddButton("Notify Error", function()
		NEVERLOSE:Notify("Error", "Sample error notification", 3, "error")
	end)
end

-- =====================================================================
-- TAB 2 : INPUT
-- =====================================================================
local TabInput = Window:AddTab("Input", "user")
do
	local s = TabInput:AddSection("Text & Numbers")
	s:AddTextBox("Text Box", "type something...", "hello world", function(v)
		pvNotify("TextBox", v, "info")
	end)
	s:AddInput("Number Input", 10, 0, 100, 0, function(v)
		pvNotify("Input", v, "info")
	end)
	s:AddInput("Decimal Input", 1.5, 0, 10, 2, function(v)
		pvNotify("Decimal", v, "info")
	end)

	local s2 = TabInput:AddSection("Binds", "right")
	s2:AddKeybind("Press Bind Key", Enum.KeyCode.F, function(k)
		pvNotify("Keybind", "Pressed: " .. tostring(k.Name), "warning")
	end)
	s2:AddToggleKeybind("Toggle + Key", false, Enum.KeyCode.G,
		function(on)
			pvNotify("ToggleKeybind", "Toggle: " .. tostring(on), "info")
		end,
		function(k)
			pvNotify("Key", "Pressed: " .. tostring(k.Name), "warning")
		end)
end

-- =====================================================================
-- TAB 3 : DROPDOWN
-- =====================================================================
local TabDropdown = Window:AddTab("Dropdown", "list")
do
	local s = TabDropdown:AddSection("Single Select")
	s:AddDropdown("Single Dropdown", {"Option A", "Option B", "Option C", "Option D", "Option E"}, "Option A", function(v)
		pvNotify("Dropdown", v, "info")
	end)

	local s2 = TabDropdown:AddSection("Multi Select", "right")
	s2:AddDropdown("Multi Dropdown", {"Alpha", "Beta", "Gamma", "Delta", "Epsilon"}, {"Alpha"}, function(v)
		if type(v) == "table" then
			pvNotify("Multi", table.concat(v, ", "), "info")
		end
	end, true)
end

-- =====================================================================
-- TAB 4 : VISUAL
-- =====================================================================
local TabVisual = Window:AddTab("Visual", "earth")
do
	local s = TabVisual:AddSection("Color Pickers")
	s:AddColorPicker("Color (no alpha)", Color3.fromRGB(100, 200, 255), function(c)
		pvNotify("Color", c:ToHex(), "info")
	end)
	s:AddColorPicker("Color + Alpha", Color3.fromRGB(255, 100, 150), function(c, a)
		pvNotify("Color+Alpha", c:ToHex() .. " | " .. string.format("%.2f", a), "info")
	end, 0.8)

	local s2 = TabVisual:AddSection("Progress Bars", "right")
	s2:AddProgressBar("Static Progress", 0, 100, 75)
	s2:AddProgressBar("Loading Demo", 0, 100, 30)
end

-- =====================================================================
-- TAB 5 : FOLDERS
-- =====================================================================
local TabFolders = Window:AddTab("Folders", "folder")
do
	local s = TabFolders:AddSection("Collapsed Folder")
	local f1 = s:AddFolder("Collapsed Folder", true)
	f1:AddToggle("Inner Toggle 1", false, function(v) end)
	f1:AddToggle("Inner Toggle 2", true, function(v) end)
	f1:AddButton("Inner Button", function()
		NEVERLOSE:Notify("Folder", "Inner button clicked", 2, "success")
	end)

	local s2 = TabFolders:AddSection("Open Folder", "right")
	local f2 = s2:AddFolder("Open Folder", false)
	f2:AddLabel("Contents of a folder that starts expanded.")
	f2:AddSlider("Inner Slider", 0, 50, 25, function(v) end)
	f2:AddTextBox("Inner TextBox", "type...", "", function(v) end)
end

-- =====================================================================
-- TAB 6 : CONFIG
-- =====================================================================
if Window.AddConfigTab then Window:AddConfigTab("Config") end

-- =====================================================================
-- TAB 7 : THEMES
-- =====================================================================
if Window.AddThemeTab then Window:AddThemeTab("Themes") end

task.delay(0.8, function()
	NEVERLOSE:Notify("Preview", "All tabs & components loaded. Browse around!", 5, "success")
end)
