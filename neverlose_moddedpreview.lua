--[[
	NEVERLOSE UI - PREVIEW / TEST SCRIPT
	=====================================
	Loads the library from GitHub, then builds every NVM tab & component
	so you can see the whole thing in action.
	Just execute this in your executor.
]]

local URL = "https://raw.githubusercontent.com/rapzxcwxcorparation/UI-LibraryModded/refs/heads/main/neverlose_modded.luau"

local src = game:HttpGet(URL .. "?v=" .. tostring(tick()))
assert(type(src) == "string" and #src > 0, "Failed to fetch library source")

local chunk, err = loadstring(src, "neverlose_modded")
assert(chunk, "loadstring failed: " .. tostring(err))

local NEVERLOSE = chunk()
assert(type(NEVERLOSE) == "table", "Library did not return a table")

-- =====================================================================
-- PREVIEW
-- =====================================================================

local pvReady = false
task.delay(1.2, function() pvReady = true end)

local function pvNotify(title, text, kind)
	if not pvReady then return end
	NEVERLOSE:Notify(tostring(title), tostring(text), 3, kind or "info")
end

local Window = NEVERLOSE:AddWindow("NEVERLOSE PREVIEW", "component showcase", UDim2.new(0, 720, 0, 500))

-- =====================================================================
-- TAB 1 : CONTROLS
-- =====================================================================
local TabControls = Window:AddTab("Controls", "home")
do
	local s = TabControls:AddSection("Basic Controls")
	s:AddLabel("Preview window: every NVM component is showcased here.")
	s:AddToggle("Toggle Example", true, function(v)
		pvNotify("Toggle", "Value: " .. tostring(v), "info")
	end)
	s:AddSlider("Slider Example", 0, 100, 50, function(v)
		-- silent while dragging
	end)
	s:AddButton("Click Me", function()
		NEVERLOSE:Notify("Button", "Button pressed!", 3, "success")
	end)
	s:AddSeparator()
	s:AddLabel("Muted label. Can be hidden / shown via :Status().")

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
-- TAB 6 : CONFIG (built-in from library)
-- =====================================================================
Window:AddConfigTab("Config")

-- =====================================================================
-- TAB 7 : THEMES (built-in from library)
-- =====================================================================
Window:AddThemeTab("Themes")

-- Opening notification
task.delay(0.8, function()
	NEVERLOSE:Notify("Preview", "All tabs & components loaded. Browse around!", 5, "success")
end)
