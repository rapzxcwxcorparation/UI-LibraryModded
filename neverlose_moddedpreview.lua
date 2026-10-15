--[[============================================================
    NEVERLOSE MODDED — Preview Test
    ----------------------------------------------------------
    Test all baked-in components: original + extension.
    Cover: toggle, slider, button, dropdown, keybind, label,
           textbox, colorpicker, progressbar, separator,
           input, togglekeybind, folder, notify
    ============================================================]]

local MODDED_URL = "https://raw.githubusercontent.com/rapzxcwxcorparation/UI-LibraryModded/refs/heads/main/neverlose_modded.luau"

local NEVERLOSE = loadstring(game:HttpGet(MODDED_URL))()

if not NEVERLOSE then
    warn("[Preview] failed to load neverlose_modded")
    return
end

print("[Preview] NEVERLOSE loaded:", NEVERLOSE._Name, NEVERLOSE._Version)

local window = NEVERLOSE:AddWindow("NEVERLOSE", "MODDED Preview")
if not window then
    warn("[Preview] AddWindow returned nil")
    return
end

local logLabel
local function log(msg)
    print("[Preview]", msg)
    if logLabel then
        logLabel:SetText(tostring(msg))
    end
end

-- ============================================================
-- TAB 1 — ORIGINAL COMPONENTS (backward compat)
-- ============================================================

local tabOriginal = window:AddTab("Original", "home")
local secOrig = tabOriginal:AddSection("Original Components", "left")
local secLog = tabOriginal:AddSection("Callback Log", "right")

logLabel = secLog:AddLabel("waiting for events...")

secOrig:AddButton("Original Button", function()
    log("original button fired")
end)

secOrig:AddToggle("Original Toggle", false, function(v)
    log("orig toggle -> " .. tostring(v))
end)

secOrig:AddSlider("Original Slider", 0, 100, 50, function(v)
    log("orig slider -> " .. tostring(v))
end)

secOrig:AddKeybind("Original Keybind", Enum.KeyCode.F, function(k)
    log("orig keybind -> " .. tostring(k))
end)

secOrig:AddDropdown("Original Dropdown", {"One", "Two", "Three"}, "One", function(v)
    log("orig dropdown -> " .. tostring(v))
end)

secOrig:AddLabel("Original Label — via AddLabel")

-- ============================================================
-- TAB 2 — NEW COMPONENTS
-- ============================================================

local tabNew = window:AddTab("Extended", "list")
local secNew = tabNew:AddSection("New Components", "left")
local secNew2 = tabNew:AddSection("More Components", "right")

secNew:AddTextBox("Username", "Enter name...", "", function(text, enter)
    log("textbox -> '" .. tostring(text) .. "' enter=" .. tostring(enter))
end)

secNew:AddColorPicker("ESP Color", Color3.fromRGB(64, 140, 255), function(c)
    log("colorpicker -> " .. tostring(c))
end)

secNew:AddInput("FOV", 70, 1, 180, 0, function(v)
    log("input FOV -> " .. tostring(v))
end)

secNew:AddToggleKeybind("Aimbot", false, Enum.KeyCode.E, function(on)
    log("togglekeybind toggle -> " .. tostring(on))
end, function(k)
    log("togglekeybind key -> " .. tostring(k))
end, function(k)
    log("togglekeybind changed -> " .. tostring(k))
end)

secNew:AddSeparator()

secNew:AddLabel("Below is a progress bar that animates automatically.")

local progress = secNew:AddProgressBar("Loading", 0, 100, 0)
task.spawn(function()
    while task.wait(0.4) do
        local v = (os.clock() * 40) % 100
        progress:Set(v)
    end
end)

secNew2:AddSeparator()
secNew2:AddLabel("Dynamic value test")
secNew2:AddButton("Toggle:Set(true, true)", function()
    log("called toggle Set")
end)
secNew2:AddButton("Notify success", function()
    NEVERLOSE:Notify("Success", "Component fired correctly.", 4, "success")
end)
secNew2:AddButton("Notify error", function()
    NEVERLOSE:Notify("Error", "Something broke.", 4, "error")
end)
secNew2:AddButton("Notify warning", function()
    NEVERLOSE:Notify("Warning", "Check your settings.", 4, "warning")
end)
secNew2:AddButton("Notify info", function()
    NEVERLOSE:Notify("Info", "Just information.", 4, "info")
end)
secNew2:AddButton("Notify plain", function()
    NEVERLOSE:Notify("Plain", "No icon here.", 4)
end)

-- ============================================================
-- TAB 3 — FOLDER (nested)
-- ============================================================

local tabFolder = window:AddTab("Folder", "folder")
local secFolder = tabFolder:AddSection("Nested Components", "left")
local secFolder2 = tabFolder:AddSection("Folder Controls", "right")

local folder = secFolder:AddFolder("Advanced Options", false)

folder:AddToggle("Nested Toggle", false, function(v)
    log("nested toggle -> " .. tostring(v))
end)

folder:AddSlider("Nested Slider", 0, 100, 30, function(v)
    log("nested slider -> " .. tostring(v))
end)

folder:AddButton("Nested Button", function()
    log("nested button fired")
end)

folder:AddTextBox("Nested Text", "type here", "", function(t)
    log("nested text -> " .. tostring(t))
end)

folder:AddLabel("Inside folder. Should be hidden when collapsed.")

secFolder:AddSeparator()
secFolder:AddLabel("Note: folder starts open. Try toggling below.")

secFolder2:AddButton("Folder:SetOpen(true)", function()
    folder:SetOpen(true)
    log("folder opened")
end)

secFolder2:AddButton("Folder:SetOpen(false)", function()
    folder:SetOpen(false)
    log("folder closed")
end)

secFolder2:AddButton("Folder:IsOpen()", function()
    log("folder open = " .. tostring(folder:IsOpen()))
end)

secFolder2:AddButton("Folder:SetTitle('Renamed')", function()
    folder:SetTitle("Renamed Folder")
end)

-- ============================================================
-- TAB 4 — API / ALIAS
-- ============================================================

local tabApi = window:AddTab("API", "user")
local secApi = tabApi:AddSection("Alias & Runtime API", "left")
local secNotif = tabApi:AddSection("Notifications", "right")

local apiToggle = secApi:AddToggle("Target Row", false, function(v)
    log("target -> " .. tostring(v))
end)

secApi:AddButton("SetTitle('Renamed')", function()
    apiToggle:SetTitle("Renamed via :SetTitle")
end)

secApi:AddButton("Text('via :Text alias')", function()
    apiToggle:Text("via :Text alias")
end)

secApi:AddButton("SetVisible(false)", function()
    apiToggle:SetVisible(false)
end)

secApi:AddButton("SetVisible(true)", function()
    apiToggle:SetVisible(true)
end)

secApi:AddButton("Status(false) alias", function()
    apiToggle:Status(false)
end)

secApi:AddButton("Value(true) alias", function()
    apiToggle:Value(true)
end)

secApi:AddButton("Destroy()", function()
    apiToggle:Destroy()
    log("toggle destroyed")
end)

secApi:AddSeparator()
secApi:AddLabel("Notify: long text test")

secNotif:AddButton("Long notify", function()
    NEVERLOSE:Notify(
        "Long Notification",
        "This is a much longer body to test wrapping and automatic sizing. It should expand the card vertically without clipping.",
        6,
        "info"
    )
end)

secNotif:AddButton("Sticky 15s", function()
    NEVERLOSE:Notify("Sticky", "Click to dismiss early.", 15, "warning")
end)

secNotif:AddButton("Spam x5", function()
    for i = 1, 5 do
        task.delay(i * 0.12, function()
            NEVERLOSE:Notify("Spam #" .. i, "Stacking test.", 3, "info")
        end)
    end
end)

secNotif:AddButton("Clear (info)", function()
    NEVERLOSE:Notify("Cleared", "You clicked clear.", 2, "success")
end)

-- ============================================================
-- BOOTSTRAP
-- ============================================================

NEVERLOSE:Notify("Preview Ready", "Explore all 4 tabs.", 5, "success")

task.delay(1.5, function()
    NEVERLOSE:Notify("Tip", "Click notifications to dismiss early.", 4, "info")
end)

print("[Preview] setup complete")

return window
