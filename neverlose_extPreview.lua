--[[============================================================
    NEVERLOSE EXT — Test Preview v2
    ----------------------------------------------------------
    Covers every component + API method exposed by neverlose_ext
    after patch8 (tag/info panel removed, font switched to Enum).
    ============================================================]]

local EXT_URL = "https://raw.githubusercontent.com/rapzxcwxcorparation/UI-LibraryModded/refs/heads/main/neverlose_ext.luau"

local NEVERLOSE = loadstring(game:HttpGet(EXT_URL))()

if not NEVERLOSE then
    warn("[Preview] failed to load NEVERLOSE")
    return
end

local extInfo = NEVERLOSE._extInfo or {}
print(("[Preview] neverlose_ext v%s loaded"):format(tostring(extInfo.version or "?")))
print("[Preview] upvalue scanner:", extInfo.hasUpvalueScanner)
print("[Preview] GC fallback:", extInfo.hasGCFallback)

local window = NEVERLOSE:AddWindow("NEVERLOSE", "EXT Preview")
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
-- TAB 1 — CONTROLS
-- ============================================================

local tabControls = window:AddTab("Controls", "home")
local secBasic = tabControls:AddSection("Basic Controls", "left")
local secLog = tabControls:AddSection("Callback Log", "right")

logLabel = secLog:AddLabel("waiting for events...")

secBasic:AddToggle("Enabled", false, function(v)
    log("Toggle -> " .. tostring(v))
end)

secBasic:AddSlider("Speed", 0, 100, 50, function(v)
    log("Slider Speed -> " .. tostring(v))
end)

secBasic:AddSlider("Gravity", 0, 10, 9.8, 2, function(v)
    log("Slider Gravity -> " .. tostring(v))
end, " m/s^2")

local singleDrop = secBasic:AddDropdown("Mode", {"Legit", "Rage", "Hybrid"}, "Legit", function(v)
    log("Dropdown Mode -> " .. tostring(v))
end, false)

secBasic:AddKeybind("Toggle Key", Enum.KeyCode.RightShift, function(k)
    log("Keybind pressed -> " .. tostring(k))
end, function(k)
    log("Keybind changed -> " .. tostring(k))
end)

secBasic:AddTextBox("Username", "Enter name...", "", function(text, enter)
    log("TextBox -> " .. tostring(text) .. " (enter=" .. tostring(enter) .. ")")
end)

secBasic:AddButton("Fire Event", function()
    log("Button fired")
end)

secBasic:AddSeparator()
secBasic:AddLabel("Static label. Use SetText to update at runtime.")

local toggleRef = secBasic:AddToggle("Runtime Toggle", false, function(v)
    log("Runtime Toggle -> " .. tostring(v))
end)

secBasic:AddButton("Toggle:Set(true, true)", function()
    toggleRef:Set(true, true)
    log("called Set(true, true)")
end)

secBasic:AddButton("Toggle:Set(true, false, true) -- force", function()
    toggleRef:Set(true, false, true)
    log("forced set")
end)

secBasic:AddButton("Toggle:Get()", function()
    log("Toggle:Get() -> " .. tostring(toggleRef:Get()))
end)

secBasic:AddButton("Dropdown:Set('Rage', true)", function()
    singleDrop:Set("Rage", true)
end)

secBasic:AddButton("Dropdown:SetOptions(New)", function()
    singleDrop:SetOptions({"A", "B", "C"}, "A", true)
    log("SetOptions fired")
end)

secBasic:AddButton("Dropdown:Refresh(New)", function()
    singleDrop:Refresh({"X", "Y", "Z"}, true)
    log("Refresh fired")
end)

local buttonRef = secBasic:AddButton("Mutable Button", function()
    log("Mutable button fired")
end)

secBasic:AddButton("Button:SetText('Changed')", function()
    buttonRef:SetText("Changed Text")
end)

-- ============================================================
-- TAB 2 — ADVANCED
-- ============================================================

local tabAdvanced = window:AddTab("Advanced", "list")
local secAdv = tabAdvanced:AddSection("Advanced Components", "left")
local secFolders = tabAdvanced:AddSection("Folders & Nested", "right")

secAdv:AddColorPicker("ESP Color", Color3.fromRGB(64, 140, 255), function(c)
    log("ColorPicker -> " .. tostring(c))
end)

local progress = secAdv:AddProgressBar("Loading", 0, 100, 0)
task.spawn(function()
    while task.wait(0.4) do
        local v = (os.clock() * 40) % 100
        progress:Set(v)
    end
end)

secAdv:AddInput("FOV", 70, 1, 180, 0, function(v)
    log("Input FOV -> " .. tostring(v))
end)

local combo = secAdv:AddToggleKeybind("Aimbot", false, Enum.KeyCode.E, function(on)
    log("ToggleKeybind toggle -> " .. tostring(on))
end, function(k)
    log("ToggleKeybind key -> " .. tostring(k))
end, function(k)
    log("ToggleKeybind changed -> " .. tostring(k))
end)

local multiDrop = secAdv:AddDropdown("Weapons", {"Rifle", "Shotgun", "Sniper", "Pistol"}, {"Rifle"}, function(list)
    local text = table.concat(list, ", ")
    log("Multi Dropdown -> " .. text)
end, true)

secAdv:AddButton("Combo:IsPressed()", function()
    log("Combo IsPressed -> " .. tostring(combo:IsPressed()))
end)

secAdv:AddButton("Combo:SetKey(Q, true)", function()
    combo:SetKey(Enum.KeyCode.Q, true)
end)

-- Folder with nested components
local folder = secFolders:AddFolder("Movement", false)

folder:AddToggle("Bunny Hop", false, function(v)
    log("Folder/BHop -> " .. tostring(v))
end)

folder:AddSlider("Jump Power", 50, 500, 50, function(v)
    log("Folder/JumpPower -> " .. tostring(v))
end)

folder:AddButton("Reset Folder", function()
    log("Folder reset button")
end)

folder:AddLabel("Nested inside a collapsible folder.")

secFolders:AddButton("Folder:SetOpen(true)", function()
    folder:SetOpen(true)
end)

secFolders:AddButton("Folder:IsOpen()", function()
    log("Folder open -> " .. tostring(folder:IsOpen()))
end)

secFolders:AddButton("MultiDrop:Get()", function()
    local list = multiDrop:Get()
    log("MultiDrop:Get() -> " .. table.concat(list, ", "))
end)

-- ============================================================
-- TAB 3 — NOTIFICATIONS
-- ============================================================

local tabNotify = window:AddTab("Notify", "ads")
local secNotify = tabNotify:AddSection("Notify Types", "left")
local secWin = tabNotify:AddSection("Extra", "right")

secNotify:AddButton("Notify: error", function()
    NEVERLOSE:Notify("Error", "Something went wrong.", 4, "error")
end)
secNotify:AddButton("Notify: success", function()
    NEVERLOSE:Notify("Success", "Operation completed.", 4, "success")
end)
secNotify:AddButton("Notify: warning", function()
    NEVERLOSE:Notify("Warning", "Check your settings.", 4, "warning")
end)
secNotify:AddButton("Notify: info", function()
    NEVERLOSE:Notify("Info", "Library loaded correctly.", 4, "info")
end)
secNotify:AddButton("Notify: plain", function()
    NEVERLOSE:Notify("Plain", "No icon here.", 4)
end)
secNotify:AddButton("Notify: long text", function()
    NEVERLOSE:Notify("Long", "This is a much longer notification body to test wrapping and automatic sizing. It should expand the card vertically without clipping.", 6, "info")
end)
secNotify:AddButton("Notify: sticky 15s", function()
    NEVERLOSE:Notify("Sticky", "Click to dismiss early.", 15, "warning")
end)
secNotify:AddButton("Notify: spam x5", function()
    for i = 1, 5 do
        task.delay(i * 0.1, function()
            NEVERLOSE:Notify("Spam " .. i, "Testing stacking behavior.", 3, "info")
        end)
    end
end)

-- ============================================================
-- TAB 4 — DIAGNOSTICS
-- ============================================================

local tabDiag = window:AddTab("Diagnostics", "user")
local secApi = tabDiag:AddSection("API Tests", "left")
local secState = tabDiag:AddSection("Library State", "right")

local targetToggle = secApi:AddToggle("Target Row", false, function(v)
    log("Target -> " .. tostring(v))
end)

secApi:AddButton("SetVisible(false)", function()
    targetToggle:SetVisible(false)
    log("visible = false")
end)

secApi:AddButton("SetVisible(true)", function()
    targetToggle:SetVisible(true)
    log("visible = true")
end)

secApi:AddButton("SetTitle('Renamed')", function()
    targetToggle:SetTitle("Renamed Row")
end)

secApi:AddButton("SetTitle('Target Row')", function()
    targetToggle:SetTitle("Target Row")
end)

secApi:AddButton("Text alias test", function()
    targetToggle:Text("via :Text()")
end)

secApi:AddButton("Status alias test", function()
    targetToggle:Status(false)
    log("Status(false) called")
end)

secApi:AddButton("Value alias test", function()
    targetToggle:Value(true)
    log("Value(true) called")
end)

secApi:AddButton("Destroy target", function()
    targetToggle:Destroy()
    log("target destroyed")
end)

secState:AddLabel("version: " .. tostring(extInfo.version or "?"))
secState:AddLabel("upvalue scanner: " .. tostring(extInfo.hasUpvalueScanner))
secState:AddLabel("GC fallback: " .. tostring(extInfo.hasGCFallback))

local counterLabel = secState:AddLabel("sections extended: " .. tostring(extInfo.sectionsExtended or 0))

secState:AddButton("Refresh counters", function()
    counterLabel:SetText("sections extended: " .. tostring(extInfo.sectionsExtended or 0)
        .. "  |  failed: " .. tostring(extInfo.sectionsFailed or 0))
end)

secState:AddSeparator()
secState:AddLabel("Unloading restores NEVERLOSE.AddWindow only. Window/Tab/Section overrides stay baked until reload.")

secState:AddButton("Unload Extension", function()
    local ok = NEVERLOSE._extUnload and NEVERLOSE._extUnload()
    log("_extUnload -> " .. tostring(ok))
end)

-- ============================================================
-- BOOTSTRAP
-- ============================================================

NEVERLOSE:Notify("Test Preview", "All components loaded. Explore each tab.", 5, "success")

task.delay(1, function()
    NEVERLOSE:Notify("Tip", "Click notifications to dismiss early.", 4, "info")
end)

print("[Preview] setup complete")

return window
