local Players = game:GetService("Players")
local UserInputService = game:GetService("UserInputService")
local RunService = game:GetService("RunService")
local TweenService = game:GetService("TweenService")
local Workspace = game:GetService("Workspace")
local HttpService = game:GetService("HttpService")

local LocalPlayer = Players.LocalPlayer
local Camera = Workspace.CurrentCamera

pcall(function()
    local oldKick = LocalPlayer.Kick
    LocalPlayer.Kick = newcclosure(function(self, ...)
        if self == LocalPlayer then return end
        return oldKick(self, ...)
    end)
end)

pcall(function()
    local mt = getrawmetatable(game)
    local oldNamecall = mt.__namecall
    setreadonly(mt, false)
    mt.__namecall = newcclosure(function(self, ...)
        local method = getnamecallmethod()
        if method == "Kick" and self == LocalPlayer then return end
        return oldNamecall(self, ...)
    end)
    setreadonly(mt, true)
end)

local ConfigFile = "randes0m_config.json"

local DefaultConfig = {
    Fly = { Enabled = false, Speed = 50, Vertical = 30 },
    Speed = { Enabled = false, Value = 50 },
    JumpPower = 50,
    InfiniteJump = false,
    ESP = { Enabled = true, Names = true, Health = true, Distance = true },
    UI = { Transparency = 0 },
    Language = "ru"
}

local Config = {}

local function LoadConfig()
    Config = {}
    local data = {}
    if writefile and readfile and isfile and isfile(ConfigFile) then
        local ok, decoded = pcall(function() return HttpService:JSONDecode(readfile(ConfigFile)) end)
        if ok and type(decoded) == "table" then data = decoded end
    end
    
    for k, v in pairs(DefaultConfig) do
        if type(v) == "table" then
            Config[k] = {}
            for subK, subV in pairs(v) do
                if data[k] and data[k][subK] ~= nil then
                    Config[k][subK] = data[k][subK]
                else
                    Config[k][subK] = subV
                end
            end
        else
            if data[k] ~= nil then
                Config[k] = data[k]
            else
                Config[k] = v
            end
        end
    end
    Config.Noclip = false
end

local function SaveConfig()
    if not writefile then return end
    local toSave = {}
    for k, v in pairs(Config) do
        if k ~= "Noclip" then
            toSave[k] = v
        end
    end
    pcall(function()
        writefile(ConfigFile, HttpService:JSONEncode(toSave))
    end)
end

LoadConfig()

local Translations = {
    ru = {
        tab_main = "Главная", tab_esp = "ESP", tab_tp = "Телепорт", tab_players = "Игроки", tab_settings = "Настройки",
        sec_fly = "ПОЛЁТ", fly = "Полёт", fly_speed = "Скорость полёта", fly_vert = "Верт. скорость",
        up = "ВВЕРХ", down = "ВНИЗ", sec_move = "ДВИЖЕНИЕ", noclip = "Noclip", inf_jump = "Беск. прыжок",
        walk_speed = "Скорость ходьбы", speed_hack = "Speed Hack", sec_esp = "ESP", esp_on = "ESP включен",
        names = "Имена", health = "Здоровье", distance = "Дистанция", sec_tp = "ТОЧКИ ТЕЛЕПОРТА",
        tp_placeholder = "название точки", save = "+ сохранить", empty_points = "нет точек",
        tp_up = "Вверх 50", tp_sky = "На небо 500",
        lang_title = "ЯЗЫК", ui_sec = "ИНТЕРФЕЙС", ui_opacity = "Прозрачность",
        phys_sec = "ФИЗИКА", jump_power = "Сила прыжка",
        sec_players = "СПИСОК ИГРОКОВ", stop_hover = "ОТМЕНИТЬ ЗАВИСАНИЕ",
        toast_saved = "Точка сохранена", toast_tp = "Телепортация", toast_hover = "Зависаю над игроком"
    },
    en = {
        tab_main = "Main", tab_esp = "ESP", tab_tp = "Teleport", tab_players = "Players", tab_settings = "Settings",
        sec_fly = "FLIGHT", fly = "Flight", fly_speed = "Fly Speed", fly_vert = "Vertical Speed",
        up = "UP", down = "DOWN", sec_move = "MOVEMENT", noclip = "Noclip", inf_jump = "Infinite Jump",
        walk_speed = "Walk Speed", speed_hack = "Speed Hack", sec_esp = "ESP", esp_on = "ESP Enabled",
        names = "Names", health = "Health", distance = "Distance", sec_tp = "TELEPORT POINTS",
        tp_placeholder = "point name", save = "+ save", empty_points = "no points",
        tp_up = "Up 50", tp_sky = "Sky 500",
        lang_title = "LANGUAGE", ui_sec = "INTERFACE", ui_opacity = "Transparency",
        phys_sec = "PHYSICS", jump_power = "Jump Power",
        sec_players = "PLAYER LIST", stop_hover = "STOP HOVER",
        toast_saved = "Point saved", toast_tp = "Teleported", toast_hover = "Hovering over player"
    }
}

local function T(key)
    return Translations[Config.Language] and Translations[Config.Language][key] or key
end

local LangElements = {}
local function RegisterLang(obj, key, prop)
    table.insert(LangElements, {obj = obj, key = key, prop = prop or "Text"})
    obj[prop or "Text"] = T(key)
end

local function ApplyLanguage()
    for _, e in ipairs(LangElements) do
        pcall(function() e.obj[e.prop] = T(e.key) end)
    end
    if LangButtons then
        LangButtons.ru.Text = "Русский " .. (Config.Language == "ru" and "[V]" or "")
        LangButtons.en.Text = "English " .. (Config.Language == "en" and "[V]" or "")
    end
end

local Theme = {
    Bg = Color3.fromRGB(15, 15, 20), Sidebar = Color3.fromRGB(20, 20, 27), Panel = Color3.fromRGB(24, 24, 32),
    Card = Color3.fromRGB(32, 32, 42), CardHover = Color3.fromRGB(42, 42, 55), Input = Color3.fromRGB(28, 28, 37),
    Accent = Color3.fromRGB(88, 130, 255), Accent2 = Color3.fromRGB(150, 95, 255), Text = Color3.fromRGB(240, 240, 250),
    SubText = Color3.fromRGB(145, 145, 165), Danger = Color3.fromRGB(230, 75, 95), Success = Color3.fromRGB(85, 215, 145),
    Stroke = Color3.fromRGB(48, 48, 62),
}

local function corner(p, r) local c = Instance.new("UICorner"); c.CornerRadius = UDim.new(0, r or 8); c.Parent = p; return c end
local function stroke(p, color, th) local s = Instance.new("UIStroke"); s.Color = color or Theme.Stroke; s.Thickness = th or 1; s.ApplyStrokeMode = Enum.ApplyStrokeMode.Border; s.Parent = p; return s end
local function gradient(p, c1, c2, rot) local g = Instance.new("UIGradient"); g.Color = ColorSequence.new(c1, c2); g.Rotation = rot or 90; g.Parent = p; return g end
local function padding(p, n) local u = Instance.new("UIPadding"); u.PaddingTop = UDim.new(0, n); u.PaddingBottom = UDim.new(0, n); u.PaddingLeft = UDim.new(0, n); u.PaddingRight = UDim.new(0, n); u.Parent = p; return u end

local function GetHRP() local char = LocalPlayer.Character; if not char then return nil end; return char:FindFirstChild("HumanoidRootPart") end
local function GetHum() local char = LocalPlayer.Character; if not char then return nil end; return char:FindFirstChildOfClass("Humanoid") end

local Points = {}
local PointsFile = "randes0m_points.json"
local function LoadPoints()
    if not (writefile and readfile and isfile) then return end
    if isfile(PointsFile) then
        local ok, data = pcall(function() return HttpService:JSONDecode(readfile(PointsFile)) end)
        if ok and type(data) == "table" then Points = data end
    end
end
local function SavePoints()
    if not writefile then return end
    pcall(function() writefile(PointsFile, HttpService:JSONEncode(Points)) end)
end
LoadPoints()

local ScreenGui = Instance.new("ScreenGui")
ScreenGui.Name = "randes0m_menu"
ScreenGui.ResetOnSpawn = false
ScreenGui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
ScreenGui.DisplayOrder = 2147483647
ScreenGui.IgnoreGuiInset = true

local success = pcall(function()
    if gethui then ScreenGui.Parent = gethui() else ScreenGui.Parent = game:GetService("CoreGui") end
end)
if not success then ScreenGui.Parent = LocalPlayer:WaitForChild("PlayerGui") end

local ToastContainer = Instance.new("Frame")
ToastContainer.Size = UDim2.new(0, 250, 1, -40)
ToastContainer.Position = UDim2.new(1, -260, 0, 20)
ToastContainer.BackgroundTransparency = 1
ToastContainer.Parent = ScreenGui
ToastContainer.ZIndex = 99999

local ToastLayout = Instance.new("UIListLayout")
ToastLayout.Padding = UDim.new(0, 8)
ToastLayout.SortOrder = Enum.SortOrder.LayoutOrder
ToastLayout.VerticalAlignment = Enum.VerticalAlignment.Top
ToastLayout.Parent = ToastContainer

local function ShowToast(text, color)
    local toast = Instance.new("Frame")
    toast.Size = UDim2.new(1, 0, 0, 40)
    toast.Position = UDim2.new(1, 300, 0, 0)
    toast.BackgroundColor3 = Theme.Card
    toast.Parent = ToastContainer
    toast.ZIndex = 100000
    corner(toast, 8)
    stroke(toast, color or Theme.Accent, 2)

    local lbl = Instance.new("TextLabel")
    lbl.Size = UDim2.new(1, -20, 1, 0)
    lbl.Position = UDim2.new(0, 10, 0, 0)
    lbl.BackgroundTransparency = 1
    lbl.Text = text
    lbl.TextColor3 = Theme.Text
    lbl.Font = Enum.Font.GothamMedium
    lbl.TextSize = 12
    lbl.TextXAlignment = Enum.TextXAlignment.Left
    lbl.Parent = toast
    lbl.ZIndex = 100001

    TweenService:Create(toast, TweenInfo.new(0.3, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {Position = UDim2.new(0, 0, 0, 0)}):Play()
    task.delay(3, function()
        local fadeOut = TweenService:Create(toast, TweenInfo.new(0.3), {Position = UDim2.new(1, 100, 0, 0), BackgroundTransparency = 1})
        fadeOut:Play()
        TweenService:Create(lbl, TweenInfo.new(0.3), {TextTransparency = 1}):Play()
        fadeOut.Completed:Connect(function() toast:Destroy() end)
    end)
end

local ToggleBtn = Instance.new("TextButton")
ToggleBtn.Size = UDim2.new(0, 50, 0, 50)
ToggleBtn.Position = UDim2.new(0, 15, 0.5, -25)
ToggleBtn.BackgroundColor3 = Theme.Accent
ToggleBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
ToggleBtn.Font = Enum.Font.GothamBold
ToggleBtn.TextSize = 20
ToggleBtn.Text = "R"
ToggleBtn.AutoButtonColor = false
ToggleBtn.Draggable = true
ToggleBtn.Parent = ScreenGui
ToggleBtn.ZIndex = 99999
corner(ToggleBtn, 25)
gradient(ToggleBtn, Theme.Accent, Theme.Accent2, 45)
stroke(ToggleBtn, Color3.fromRGB(255,255,255), 2)

local Frame = Instance.new("Frame")
Frame.Size = UDim2.new(0, 380, 0, 540)
Frame.Position = UDim2.new(0.5, -190, 0.5, -270)
Frame.BackgroundColor3 = Theme.Bg
Frame.BorderSizePixel = 0
Frame.Active = true
Frame.Draggable = true
Frame.Visible = false
Frame.Parent = ScreenGui
Frame.ZIndex = 99999
corner(Frame, 14)
stroke(Frame, Theme.Stroke, 1)
Frame.BackgroundTransparency = Config.UI.Transparency / 100

ToggleBtn.MouseButton1Click:Connect(function() 
    Frame.Visible = not Frame.Visible 
end)

local TopBar = Instance.new("Frame")
TopBar.Size = UDim2.new(1, 0, 0, 50)
TopBar.BackgroundColor3 = Theme.Sidebar
TopBar.BorderSizePixel = 0
TopBar.Parent = Frame
corner(TopBar, 14)
gradient(TopBar, Color3.fromRGB(50, 40, 90), Color3.fromRGB(22, 22, 32), 0)
TopBar.BackgroundTransparency = Config.UI.Transparency / 100

local TopMask = Instance.new("Frame")
TopMask.Size = UDim2.new(1, 0, 0, 14)
TopMask.Position = UDim2.new(0, 0, 1, -14)
TopMask.BackgroundColor3 = Theme.Sidebar
TopMask.BorderSizePixel = 0
TopMask.Parent = TopBar

local Title = Instance.new("TextLabel")
Title.Size = UDim2.new(1, -90, 1, 0)
Title.Position = UDim2.new(0, 16, 0, 0)
Title.BackgroundTransparency = 1
Title.Text = "randes0m"
Title.TextColor3 = Theme.Text
Title.Font = Enum.Font.GothamBold
Title.TextSize = 18
Title.TextXAlignment = Enum.TextXAlignment.Left
Title.Parent = TopBar

local CloseBtn = Instance.new("TextButton")
CloseBtn.Size = UDim2.new(0, 30, 0, 30)
CloseBtn.Position = UDim2.new(1, -40, 0.5, -15)
CloseBtn.BackgroundColor3 = Color3.fromRGB(55, 25, 35)
CloseBtn.TextColor3 = Theme.Danger
CloseBtn.Font = Enum.Font.GothamBold
CloseBtn.TextSize = 16
CloseBtn.Text = "X"
CloseBtn.AutoButtonColor = false
CloseBtn.Parent = TopBar
corner(CloseBtn, 8)

CloseBtn.MouseButton1Click:Connect(function()
    Frame.Visible = false
end)

local Sidebar = Instance.new("Frame")
Sidebar.Size = UDim2.new(0, 92, 1, -50)
Sidebar.Position = UDim2.new(0, 0, 0, 50)
Sidebar.BackgroundColor3 = Theme.Sidebar
Sidebar.BorderSizePixel = 0
Sidebar.Parent = Frame
Sidebar.BackgroundTransparency = Config.UI.Transparency / 100

local SidebarLine = Instance.new("Frame")
SidebarLine.Size = UDim2.new(0, 1, 1, 0)
SidebarLine.Position = UDim2.new(1, -1, 0, 0)
SidebarLine.BackgroundColor3 = Theme.Stroke
SidebarLine.BorderSizePixel = 0
SidebarLine.Parent = Sidebar

local Content = Instance.new("Frame")
Content.Size = UDim2.new(1, -92, 1, -50)
Content.Position = UDim2.new(0, 92, 0, 50)
Content.BackgroundTransparency = 1
Content.Parent = Frame

local Pages = {}
local TabButtons = {}

local function MakeTab(langKey, y)
    local btn = Instance.new("TextButton")
    btn.Size = UDim2.new(1, -16, 0, 42)
    btn.Position = UDim2.new(0, 8, 0, y)
    btn.BackgroundColor3 = Theme.Sidebar
    btn.Text = ""
    btn.AutoButtonColor = false
    btn.Parent = Sidebar
    corner(btn, 10)

    local accent = Instance.new("Frame")
    accent.Size = UDim2.new(0, 3, 0, 20)
    accent.Position = UDim2.new(0, -8, 0.5, -10)
    accent.BackgroundColor3 = Theme.Accent
    accent.BorderSizePixel = 0
    accent.Visible = false
    accent.Parent = btn
    corner(accent, 2)

    local lbl = Instance.new("TextLabel")
    lbl.Size = UDim2.new(1, -20, 1, 0)
    lbl.Position = UDim2.new(0, 16, 0, 0)
    lbl.BackgroundTransparency = 1
    lbl.TextColor3 = Theme.SubText
    lbl.Font = Enum.Font.GothamMedium
    lbl.TextSize = 12
    lbl.TextXAlignment = Enum.TextXAlignment.Left
    lbl.Parent = btn
    RegisterLang(lbl, langKey)

    table.insert(TabButtons, {btn = btn, acc = accent, lbl = lbl})
    return btn
end

local function MakePage()
    local page = Instance.new("ScrollingFrame")
    page.Size = UDim2.new(1, 0, 1, 0)
    page.BackgroundTransparency = 1
    page.BorderSizePixel = 0
    page.ScrollBarThickness = 4
    page.ScrollBarImageColor3 = Theme.Accent
    page.AutomaticCanvasSize = Enum.AutomaticSize.Y
    page.CanvasSize = UDim2.new(0, 0, 0, 0)
    page.Visible = false
    page.Parent = Content
    padding(page, 12)

    local layout = Instance.new("UIListLayout")
    layout.Padding = UDim.new(0, 10)
    layout.SortOrder = Enum.SortOrder.LayoutOrder
    layout.Parent = page

    return page
end

local function SetTab(idx)
    for i, tb in ipairs(TabButtons) do
        local active = (i == idx)
        tb.btn:SetAttribute("active", active)
        tb.acc.Visible = active
        tb.lbl.TextColor3 = active and Theme.Text or Theme.SubText
        TweenService:Create(tb.btn, TweenInfo.new(0.2), {BackgroundColor3 = active and Theme.Card or Theme.Sidebar}):Play()
    end
    for i, p in ipairs(Pages) do p.Visible = (i == idx) end
end

local function MakeSection(parent, langKey)
    local lbl = Instance.new("TextLabel")
    lbl.Size = UDim2.new(1, 0, 0, 22)
    lbl.BackgroundTransparency = 1
    lbl.Font = Enum.Font.GothamBold
    lbl.TextSize = 11
    lbl.TextColor3 = Theme.SubText
    lbl.TextXAlignment = Enum.TextXAlignment.Left
    lbl.Parent = parent
    RegisterLang(lbl, langKey)
    return lbl
end

local function MakeToggle(parent, langKey, default, callback, save)
    local btn = Instance.new("TextButton")
    btn.Size = UDim2.new(1, 0, 0, 50)
    btn.BackgroundColor3 = Theme.Card
    btn.Text = ""
    btn.AutoButtonColor = false
    btn.Parent = parent
    corner(btn, 10)
    stroke(btn, Theme.Stroke, 1)

    local lbl = Instance.new("TextLabel")
    lbl.Size = UDim2.new(1, -80, 1, 0)
    lbl.Position = UDim2.new(0, 16, 0, 0)
    lbl.BackgroundTransparency = 1
    lbl.TextColor3 = Theme.Text
    lbl.Font = Enum.Font.GothamMedium
    lbl.TextSize = 14
    lbl.TextXAlignment = Enum.TextXAlignment.Left
    lbl.Parent = btn
    RegisterLang(lbl, langKey)

    local Pill = Instance.new("Frame")
    Pill.Size = UDim2.new(0, 50, 0, 26)
    Pill.Position = UDim2.new(1, -64, 0.5, -13)
    Pill.BackgroundColor3 = Theme.Input
    Pill.BorderSizePixel = 0
    Pill.Parent = btn
    corner(Pill, 13)
    stroke(Pill, Theme.Stroke, 1)

    local Knob = Instance.new("Frame")
    Knob.Size = UDim2.new(0, 20, 0, 20)
    Knob.Position = UDim2.new(0, 3, 0.5, -10)
    Knob.BackgroundColor3 = Theme.SubText
    Knob.BorderSizePixel = 0
    Knob.Parent = Pill
    corner(Knob, 10)

    local state = default
    local function apply()
        if state then
            TweenService:Create(Pill, TweenInfo.new(0.2), {BackgroundColor3 = Theme.Accent}):Play()
            TweenService:Create(Knob, TweenInfo.new(0.2), {Position = UDim2.new(1, -23, 0.5, -10), BackgroundColor3 = Color3.fromRGB(255, 255, 255)}):Play()
        else
            TweenService:Create(Pill, TweenInfo.new(0.2), {BackgroundColor3 = Theme.Input}):Play()
            TweenService:Create(Knob, TweenInfo.new(0.2), {Position = UDim2.new(0, 3, 0.5, -10), BackgroundColor3 = Theme.SubText}):Play()
        end
    end

    btn.MouseButton1Click:Connect(function()
        state = not state
        apply()
        pcall(function() callback(state) end)
        if save ~= false then SaveConfig() end
    end)
    apply()
    return btn
end

local function MakeSlider(parent, langKey, minVal, maxVal, default, callback)
    default = default or minVal
    local c = Instance.new("Frame")
    c.Size = UDim2.new(1, 0, 0, 60)
    c.BackgroundColor3 = Theme.Card
    c.BorderSizePixel = 0
    c.Parent = parent
    corner(c, 10)
    stroke(c, Theme.Stroke, 1)

    local lbl = Instance.new("TextLabel")
    lbl.Size = UDim2.new(1, -70, 0, 22)
    lbl.Position = UDim2.new(0, 16, 0, 6)
    lbl.BackgroundTransparency = 1
    lbl.TextColor3 = Theme.Text
    lbl.Font = Enum.Font.GothamMedium
    lbl.TextSize = 13
    lbl.TextXAlignment = Enum.TextXAlignment.Left
    lbl.Parent = c
    RegisterLang(lbl, langKey)

    local valLbl = Instance.new("TextLabel")
    valLbl.Size = UDim2.new(0, 60, 0, 22)
    valLbl.Position = UDim2.new(1, -70, 0, 6)
    valLbl.BackgroundTransparency = 1
    valLbl.Text = tostring(default)
    valLbl.TextColor3 = Theme.Accent
    valLbl.Font = Enum.Font.GothamBold
    valLbl.TextSize = 13
    valLbl.TextXAlignment = Enum.TextXAlignment.Right
    valLbl.Parent = c

    local track = Instance.new("Frame")
    track.Size = UDim2.new(1, -32, 0, 8)
    track.Position = UDim2.new(0, 16, 0, 40)
    track.BackgroundColor3 = Theme.Input
    track.BorderSizePixel = 0
    track.Parent = c
    corner(track, 4)

    local fill = Instance.new("Frame")
    local initRel = (default - minVal) / (maxVal - minVal)
    fill.Size = UDim2.new(initRel, 0, 1, 0)
    fill.BackgroundColor3 = Theme.Accent
    fill.BorderSizePixel = 0
    fill.Parent = track
    corner(fill, 4)
    gradient(fill, Theme.Accent, Theme.Accent2, 0)

    local knob = Instance.new("Frame")
    knob.Size = UDim2.new(0, 18, 0, 18)
    knob.Position = UDim2.new(initRel, -9, 0.5, -9)
    knob.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
    knob.BorderSizePixel = 0
    knob.Parent = track
    corner(knob, 9)
    stroke(knob, Theme.Accent, 2)

    local dragging = false
    local function updateFromX(mx)
        local ap = track.AbsolutePosition.X
        local as = track.AbsoluteSize.X
        local rel = math.clamp((mx - ap) / as, 0, 1)
        local val = math.floor(minVal + rel * (maxVal - minVal) + 0.5)
        fill.Size = UDim2.new(rel, 0, 1, 0)
        knob.Position = UDim2.new(rel, -9, 0.5, -9)
        valLbl.Text = tostring(val)
        pcall(function() callback(val) end)
    end

    track.InputBegan:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
            dragging = true
            updateFromX(input.Position.X)
        end
    end)
    UserInputService.InputChanged:Connect(function(input)
        if dragging and (input.UserInputType == Enum.UserInputType.MouseMovement or input.UserInputType == Enum.UserInputType.Touch) then
            updateFromX(input.Position.X)
        end
    end)
    UserInputService.InputEnded:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
            if dragging then SaveConfig() end
            dragging = false
        end
    end)

    return c
end

local function MakeButton(parent, text, color, callback)
    local btn = Instance.new("TextButton")
    btn.Size = UDim2.new(1, 0, 0, 44)
    btn.BackgroundColor3 = color or Theme.Card
    btn.TextColor3 = Theme.Text
    btn.Font = Enum.Font.GothamBold
    btn.TextSize = 13
    btn.Text = text
    btn.AutoButtonColor = false
    btn.Parent = parent
    corner(btn, 10)
    stroke(btn, Theme.Stroke, 1)
    btn.MouseButton1Click:Connect(function() pcall(function() callback() end) end)
    return btn
end

local TabMain = MakeTab("tab_main", 8)
local TabESP = MakeTab("tab_esp", 52)
local TabTP = MakeTab("tab_tp", 96)
local TabPlayers = MakeTab("tab_players", 140)
local TabSettings = MakeTab("tab_settings", 184)

local PageMain = MakePage()
local PageESP = MakePage()
local PageTP = MakePage()
local PagePlayers = MakePage()
local PageSettings = MakePage()

Pages = { PageMain, PageESP, PageTP, PagePlayers, PageSettings }

TabMain.MouseButton1Click:Connect(function() SetTab(1) end)
TabESP.MouseButton1Click:Connect(function() SetTab(2) end)
TabTP.MouseButton1Click:Connect(function() SetTab(3) end)
TabPlayers.MouseButton1Click:Connect(function() SetTab(4) end)
TabSettings.MouseButton1Click:Connect(function() SetTab(5) end)

-- ВКЛАДКА 1: ГЛАВНАЯ
MakeSection(PageMain, "sec_fly")
local flyConn, flyBV, flyBG = nil, nil, nil

local function StartFly()
    local hrp = GetHRP()
    if not hrp then return end
    flyBV = Instance.new("BodyVelocity")
    flyBV.MaxForce = Vector3.new(1e9, 1e9, 1e9)
    flyBV.Velocity = Vector3.new(0, 0, 0)
    flyBV.Parent = hrp
    flyBG = Instance.new("BodyGyro")
    flyBG.MaxTorque = Vector3.new(1e9, 1e9, 1e9)
    flyBG.P = 1000
    flyBG.CFrame = hrp.CFrame
    flyBG.Parent = hrp
    flyConn = RunService.Heartbeat:Connect(function()
        if not flyBV then return end
        local dir = Vector3.new(0, 0, 0)
        if UserInputService:IsKeyDown(Enum.KeyCode.W) then dir += Camera.CFrame.LookVector end
        if UserInputService:IsKeyDown(Enum.KeyCode.S) then dir -= Camera.CFrame.LookVector end
        if UserInputService:IsKeyDown(Enum.KeyCode.A) then dir -= Camera.CFrame.RightVector end
        if UserInputService:IsKeyDown(Enum.KeyCode.D) then dir += Camera.CFrame.RightVector end
        local hum = GetHum()
        if hum and hum.MoveDirection.Magnitude > 0.1 then dir += hum.MoveDirection end
        if UserInputService:IsKeyDown(Enum.KeyCode.Space) then dir += Vector3.new(0, 1, 0) end
        if UserInputService:IsKeyDown(Enum.KeyCode.LeftControl) then dir -= Vector3.new(0, 1, 0) end
        flyBV.Velocity = dir * Config.Fly.Speed
        flyBG.CFrame = Camera.CFrame
    end)
end

local function StopFly()
    if flyConn then flyConn:Disconnect() flyConn = nil end
    if flyBV then flyBV:Destroy() flyBV = nil end
    if flyBG then flyBG:Destroy() flyBG = nil end
end

MakeToggle(PageMain, "fly", Config.Fly.Enabled, function(v)
    Config.Fly.Enabled = v
    if v then StartFly() else StopFly() end
end)

MakeSlider(PageMain, "fly_speed", 10, 200, Config.Fly.Speed, function(v) Config.Fly.Speed = v end)
MakeSlider(PageMain, "fly_vert", 5, 100, Config.Fly.Vertical, function(v) Config.Fly.Vertical = v end)

local vertRow = Instance.new("Frame")
vertRow.Size = UDim2.new(1, 0, 0, 44)
vertRow.BackgroundTransparency = 1
vertRow.Parent = PageMain

local UpBtn = Instance.new("TextButton")
UpBtn.Size = UDim2.new(0.48, 0, 1, 0)
UpBtn.BackgroundColor3 = Theme.Card
UpBtn.TextColor3 = Theme.Success
UpBtn.Font = Enum.Font.GothamBold
UpBtn.TextSize = 16
UpBtn.AutoButtonColor = false
UpBtn.Parent = vertRow
corner(UpBtn, 10)
stroke(UpBtn, Theme.Stroke, 1)
RegisterLang(UpBtn, "up")

local DownBtn = Instance.new("TextButton")
DownBtn.Size = UDim2.new(0.48, 0, 1, 0)
DownBtn.Position = UDim2.new(0.52, 0, 0, 0)
DownBtn.BackgroundColor3 = Theme.Card
DownBtn.TextColor3 = Theme.Danger
DownBtn.Font = Enum.Font.GothamBold
DownBtn.TextSize = 16
DownBtn.AutoButtonColor = false
DownBtn.Parent = vertRow
corner(DownBtn, 10)
stroke(DownBtn, Theme.Stroke, 1)
RegisterLang(DownBtn, "down")

local vertHeld = 0
UpBtn.MouseButton1Down:Connect(function() vertHeld = 1 end)
UpBtn.MouseButton1Up:Connect(function() vertHeld = 0 end)
DownBtn.MouseButton1Down:Connect(function() vertHeld = -1 end)
DownBtn.MouseButton1Up:Connect(function() vertHeld = 0 end)

RunService.Heartbeat:Connect(function()
    if Config.Fly.Enabled and vertHeld ~= 0 and flyBV then
        flyBV.Velocity += Vector3.new(0, vertHeld * Config.Fly.Vertical, 0)
    end
end)

MakeSection(PageMain, "sec_move")
MakeToggle(PageMain, "noclip", Config.Noclip, function(v)
    Config.Noclip = v
    if not v then
        local char = LocalPlayer.Character
        if char then
            for _, p in ipairs(char:GetDescendants()) do
                if p:IsA("BasePart") then p.CanCollide = true end
            end
        end
    end
end, false)
MakeToggle(PageMain, "inf_jump", Config.InfiniteJump, function(v) Config.InfiniteJump = v end)
MakeSlider(PageMain, "walk_speed", 16, 200, Config.Speed.Value, function(v)
    Config.Speed.Value = v
    if Config.Speed.Enabled then
        local hum = GetHum()
        if hum then hum.WalkSpeed = v end
    end
end)
MakeToggle(PageMain, "speed_hack", Config.Speed.Enabled, function(v)
    Config.Speed.Enabled = v
    local hum = GetHum()
    if hum then hum.WalkSpeed = v and Config.Speed.Value or 16 end
end)

-- ВКЛАДКА 2: ESP
MakeSection(PageESP, "sec_esp")
MakeToggle(PageESP, "esp_on", Config.ESP.Enabled, function(v) Config.ESP.Enabled = v end)
MakeToggle(PageESP, "names", Config.ESP.Names, function(v) Config.ESP.Names = v end)
MakeToggle(PageESP, "health", Config.ESP.Health, function(v) Config.ESP.Health = v end)
MakeToggle(PageESP, "distance", Config.ESP.Distance, function(v) Config.ESP.Distance = v end)

-- ВКЛАДКА 3: ТЕЛЕПОРТ (Точки)
MakeSection(PageTP, "sec_tp")
local tpRow = Instance.new("Frame")
tpRow.Size = UDim2.new(1, 0, 0, 44)
tpRow.BackgroundTransparency = 1
tpRow.Parent = PageTP

local TPNameBox = Instance.new("TextBox")
TPNameBox.Size = UDim2.new(1, -90, 1, 0)
TPNameBox.BackgroundColor3 = Theme.Input
TPNameBox.TextColor3 = Theme.Text
TPNameBox.Font = Enum.Font.Gotham
TPNameBox.TextSize = 13
TPNameBox.Text = ""
TPNameBox.ClearTextOnFocus = false
TPNameBox.TextXAlignment = Enum.TextXAlignment.Left
TPNameBox.Parent = tpRow
corner(TPNameBox, 10)
stroke(TPNameBox, Theme.Stroke, 1)
RegisterLang(TPNameBox, "tp_placeholder", "PlaceholderText")

local TPPad = Instance.new("UIPadding")
TPPad.PaddingLeft = UDim.new(0, 12)
TPPad.Parent = TPNameBox

local TPSaveBtn = Instance.new("TextButton")
TPSaveBtn.Size = UDim2.new(0, 82, 1, 0)
TPSaveBtn.Position = UDim2.new(1, -82, 0, 0)
TPSaveBtn.BackgroundColor3 = Theme.Accent
TPSaveBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
TPSaveBtn.Font = Enum.Font.GothamBold
TPSaveBtn.TextSize = 12
TPSaveBtn.AutoButtonColor = false
TPSaveBtn.Parent = tpRow
corner(TPSaveBtn, 10)
gradient(TPSaveBtn, Theme.Accent, Theme.Accent2, 45)
RegisterLang(TPSaveBtn, "save")

local TPList = Instance.new("Frame")
TPList.Size = UDim2.new(1, 0, 0, 42)
TPList.BackgroundColor3 = Theme.Panel
TPList.BorderSizePixel = 0
TPList.ClipsDescendants = false
TPList.Parent = PageTP
corner(TPList, 10)
stroke(TPList, Theme.Stroke, 1)

local TPListLayout = Instance.new("UIListLayout")
TPListLayout.Padding = UDim.new(0, 4)
TPListLayout.SortOrder = Enum.SortOrder.LayoutOrder
TPListLayout.Parent = TPList

local TPListPad = Instance.new("UIPadding")
TPListPad.PaddingTop = UDim.new(0, 6)
TPListPad.PaddingBottom = UDim.new(0, 6)
TPListPad.PaddingLeft = UDim.new(0, 6)
TPListPad.PaddingRight = UDim.new(0, 6)
TPListPad.Parent = TPList

local TPEmptyLbl = Instance.new("TextLabel")
TPEmptyLbl.Size = UDim2.new(1, 0, 0, 30)
TPEmptyLbl.BackgroundTransparency = 1
TPEmptyLbl.TextColor3 = Theme.SubText
TPEmptyLbl.Font = Enum.Font.Gotham
TPEmptyLbl.TextSize = 11
TPEmptyLbl.Parent = TPList
RegisterLang(TPEmptyLbl, "empty_points")

local function RefreshTPList()
    for _, c in ipairs(TPList:GetChildren()) do
        if c:IsA("Frame") then c:Destroy() end
    end
    local names = {}
    for n in pairs(Points) do table.insert(names, n) end
    table.sort(names)
    if #names == 0 then
        TPEmptyLbl.Visible = true
        TPList.Size = UDim2.new(1, 0, 0, 42)
        return
    end
    TPEmptyLbl.Visible = false
    local totalH = 0
    for _, name in ipairs(names) do
        local pos = Points[name]
        local row = Instance.new("Frame")
        row.Size = UDim2.new(1, -12, 0, 40)
        row.BackgroundColor3 = Theme.Card
        row.BorderSizePixel = 0
        row.Parent = TPList
        corner(row, 8)
        stroke(row, Theme.Stroke, 1)

        local dot = Instance.new("Frame")
        dot.Size = UDim2.new(0, 6, 0, 6)
        dot.Position = UDim2.new(0, 8, 0.5, -3)
        dot.BackgroundColor3 = Theme.Accent
        dot.BorderSizePixel = 0
        dot.Parent = row
        corner(dot, 3)

        local nameBtn = Instance.new("TextButton")
        nameBtn.Size = UDim2.new(1, -110, 1, 0)
        nameBtn.Position = UDim2.new(0, 20, 0, 0)
        nameBtn.BackgroundTransparency = 1
        nameBtn.TextColor3 = Theme.Text
        nameBtn.Font = Enum.Font.GothamMedium
        nameBtn.TextSize = 12
        nameBtn.Text = name
        nameBtn.TextXAlignment = Enum.TextXAlignment.Left
        nameBtn.TextTruncate = Enum.TextTruncate.AtEnd
        nameBtn.AutoButtonColor = false
        nameBtn.Parent = row

        nameBtn.MouseButton1Click:Connect(function()
            local hrp = GetHRP()
            if hrp then
                hrp.CFrame = CFrame.new(Vector3.new(pos.x, pos.y, pos.z))
                ShowToast(T("toast_tp"), Theme.Success)
            end
        end)

        local delBtn = Instance.new("TextButton")
        delBtn.Size = UDim2.new(0, 30, 0, 28)
        delBtn.Position = UDim2.new(1, -34, 0.5, -14)
        delBtn.BackgroundColor3 = Color3.fromRGB(50, 25, 32)
        delBtn.TextColor3 = Theme.Danger
        delBtn.Font = Enum.Font.GothamBold
        delBtn.TextSize = 14
        delBtn.Text = "X"
        delBtn.AutoButtonColor = false
        delBtn.Parent = row
        corner(delBtn, 6)

        delBtn.MouseButton1Click:Connect(function()
            Points[name] = nil
            SavePoints()
            RefreshTPList()
        end)

        totalH += 44
    end
    TPList.Size = UDim2.new(1, 0, 0, totalH + 12)
end

TPSaveBtn.MouseButton1Click:Connect(function()
    local name = TPNameBox.Text
    if name == "" then name = "point_" .. tostring(os.time()) end
    local hrp = GetHRP()
    if not hrp then return end
    Points[name] = {x = hrp.Position.X, y = hrp.Position.Y, z = hrp.Position.Z}
    SavePoints()
    RefreshTPList()
    TPNameBox.Text = ""
    ShowToast(T("toast_saved"), Theme.Accent)
end)

MakeButton(PageTP, T("tp_up"), Theme.Card, function()
    local hrp = GetHRP()
    if hrp then hrp.CFrame += Vector3.new(0, 50, 0) end
end)
MakeButton(PageTP, T("tp_sky"), Color3.fromRGB(50, 80, 150), function()
    local hrp = GetHRP()
    if hrp then hrp.CFrame = CFrame.new(hrp.Position + Vector3.new(0, 500, 0)) end
end)

-- ВКЛАДКА 4: ИГРОКИ
MakeSection(PagePlayers, "sec_players")

local hoverPlayer = nil
local hoverConn = nil
local hoverBodyPos = nil
local hoverBodyGyro = nil

local function StopHover()
    if hoverConn then hoverConn:Disconnect() hoverConn = nil end
    if hoverBodyPos then hoverBodyPos:Destroy() hoverBodyPos = nil end
    if hoverBodyGyro then hoverBodyGyro:Destroy() hoverBodyGyro = nil end
    hoverPlayer = nil
end

local function StartHover(target)
    StopHover()
    local char = LocalPlayer.Character
    local hrp = char and char:FindFirstChild("HumanoidRootPart")
    if not hrp then return end

    hoverPlayer = target
    
    -- Телепорт к цели
    local tChar = target.Character
    local tHrp = tChar and tChar:FindFirstChild("HumanoidRootPart")
    if tHrp then
        hrp.CFrame = tHrp.CFrame * CFrame.new(0, 6, 0)
    end

    -- Физика зависания (BodyPosition + BodyGyro)
    hoverBodyPos = Instance.new("BodyPosition")
    hoverBodyPos.MaxForce = Vector3.new(math.huge, math.huge, math.huge)
    hoverBodyPos.D = 100
    hoverBodyPos.P = 10000
    hoverBodyPos.Parent = hrp

    hoverBodyGyro = Instance.new("BodyGyro")
    hoverBodyGyro.MaxTorque = Vector3.new(math.huge, math.huge, math.huge)
    hoverBodyGyro.P = 10000
    hoverBodyGyro.Parent = hrp

    hoverConn = RunService.Heartbeat:Connect(function()
        if not hoverBodyPos or not hoverBodyPos.Parent or not hoverPlayer then return end
        local curTChar = hoverPlayer.Character
        local curTHrp = curTChar and curTChar:FindFirstChild("HumanoidRootPart")
        if curTHrp then
            hoverBodyPos.Position = curTHrp.Position + Vector3.new(0, 6, 0)
            hoverBodyGyro.CFrame = curTHrp.CFrame
        else
            StopHover()
            ShowToast("Игрок умер или вышел", Theme.Danger)
        end
    end)
    ShowToast(T("toast_hover") .. " " .. target.Name, Theme.Success)
end

local StopHoverBtn = MakeButton(PagePlayers, T("stop_hover"), Theme.Danger, function()
    StopHover()
    ShowToast("Зависание отменено", Theme.Accent)
end)
StopHoverBtn.Size = UDim2.new(1, 0, 0, 36)

local PlayerScroll = Instance.new("ScrollingFrame")
PlayerScroll.Size = UDim2.new(1, 0, 0, 300)
PlayerScroll.BackgroundColor3 = Theme.Panel
PlayerScroll.BorderSizePixel = 0
PlayerScroll.ScrollBarThickness = 4
PlayerScroll.ScrollBarImageColor3 = Theme.Accent
PlayerScroll.AutomaticCanvasSize = Enum.AutomaticSize.Y
PlayerScroll.CanvasSize = UDim2.new(0, 0, 0, 0)
PlayerScroll.Parent = PagePlayers
corner(PlayerScroll, 10)
stroke(PlayerScroll, Theme.Stroke, 1)

local PlayerLayout = Instance.new("UIListLayout")
PlayerLayout.Padding = UDim.new(0, 4)
PlayerLayout.SortOrder = Enum.SortOrder.Name
PlayerLayout.Parent = PlayerScroll

local PlayerPad = Instance.new("UIPadding")
PlayerPad.PaddingTop = UDim.new(0, 6)
PlayerPad.PaddingBottom = UDim.new(0, 6)
PlayerPad.PaddingLeft = UDim.new(0, 6)
PlayerPad.PaddingRight = UDim.new(0, 6)
PlayerPad.Parent = PlayerScroll

local function RefreshPlayerList()
    for _, c in ipairs(PlayerScroll:GetChildren()) do
        if c:IsA("TextButton") then c:Destroy() end
    end
    for _, plr in ipairs(Players:GetPlayers()) do
        if plr ~= LocalPlayer then
            local btn = Instance.new("TextButton")
            btn.Size = UDim2.new(1, -6, 0, 40)
            btn.BackgroundColor3 = Theme.Card
            btn.Text = plr.Name .. " (Нажми для зависания)"
            btn.TextColor3 = Theme.Text
            btn.Font = Enum.Font.GothamMedium
            btn.TextSize = 12
            btn.AutoButtonColor = false
            btn.Parent = PlayerScroll
            corner(btn, 8)
            stroke(btn, Theme.Stroke, 1)
            
            btn.MouseButton1Click:Connect(function()
                StartHover(plr)
            end)
        end
    end
end

Players.PlayerAdded:Connect(RefreshPlayerList)
Players.PlayerRemoving:Connect(function(plr)
    if hoverPlayer == plr then StopHover() end
    task.wait(0.5)
    RefreshPlayerList()
end)

-- ВКЛАДКА 5: НАСТРОЙКИ
MakeSection(PageSettings, "lang_title")
local LangButtons = {}

local function CreateLangBtn(langCode, text, y)
    local btn = Instance.new("TextButton")
    btn.Size = UDim2.new(1, 0, 0, 44)
    btn.Position = UDim2.new(0, 0, 0, y)
    btn.BackgroundColor3 = Theme.Card
    btn.TextColor3 = Theme.Text
    btn.Font = Enum.Font.GothamBold
    btn.TextSize = 13
    btn.Text = text
    btn.AutoButtonColor = false
    btn.Parent = PageSettings
    corner(btn, 10)
    stroke(btn, Theme.Stroke, 1)
    
    btn.MouseButton1Click:Connect(function()
        Config.Language = langCode
        SaveConfig()
        ApplyLanguage()
        for code, b in pairs(LangButtons) do
            b.BackgroundColor3 = (code == Config.Language) and Theme.Accent or Theme.Card
            b.TextColor3 = (code == Config.Language) and Color3.fromRGB(255,255,255) or Theme.Text
        end
    end)
    
    LangButtons[langCode] = btn
    return btn
end

CreateLangBtn("ru", "Русский", 0)
CreateLangBtn("en", "English", 50)

MakeSection(PageSettings, "phys_sec")
MakeSlider(PageSettings, "jump_power", 50, 500, Config.JumpPower, function(v)
    Config.JumpPower = v
    local hum = GetHum()
    if hum then
        hum.UseJumpPower = true
        hum.JumpPower = v
    end
end)

MakeSection(PageSettings, "ui_sec")
MakeSlider(PageSettings, "ui_opacity", 0, 80, Config.UI.Transparency, function(v)
    Config.UI.Transparency = v
    local t = v / 100
    Frame.BackgroundTransparency = t
    TopBar.BackgroundTransparency = t
    Sidebar.BackgroundTransparency = t
end)

-- ОСТАЛЬНАЯ ЛОГИКА
RunService.Stepped:Connect(function()
    if Config.Noclip then
        local char = LocalPlayer.Character
        if char then
            for _, p in ipairs(char:GetDescendants()) do
                if p:IsA("BasePart") and p.CanCollide then pcall(function() p.CanCollide = false end) end
            end
        end
    end
end)

RunService.Heartbeat:Connect(function()
    local hum = GetHum()
    if hum then
        if Config.Speed.Enabled and hum.WalkSpeed ~= Config.Speed.Value then 
            hum.WalkSpeed = Config.Speed.Value 
        end
        if hum.JumpPower ~= Config.JumpPower then
            hum.UseJumpPower = true
            hum.JumpPower = Config.JumpPower
        end
    end
end)

UserInputService.JumpRequest:Connect(function()
    if Config.InfiniteJump then
        local hum = GetHum()
        if hum then hum:ChangeState(Enum.HumanoidStateType.Jumping) end
    end
end)

local ESPObjects = {}
local function ClearESP()
    for _, d in pairs(ESPObjects) do
        if d.highlight then d.highlight:Destroy() end
        if d.gui then d.gui:Destroy() end
    end
    ESPObjects = {}
end

local function CreateESP(plr, char, head, hum, dist)
    local highlight = Instance.new("Highlight"); highlight.Adornee = char; highlight.FillColor = Color3.fromRGB(255, 60, 80); highlight.OutlineColor = Color3.fromRGB(255, 255, 255); highlight.FillTransparency = 0.75; highlight.OutlineTransparency = 0; highlight.DepthMode = Enum.HighlightDepthMode.AlwaysOnTop; highlight.Parent = char
    local gui = Instance.new("BillboardGui"); gui.Adornee = head; gui.Size = UDim2.new(0, 220, 0, 70); gui.StudsOffset = Vector3.new(0, 2.8, 0); gui.AlwaysOnTop = true; gui.Parent = char
    local container = Instance.new("Frame"); container.Size = UDim2.new(1, 0, 1, 0); container.BackgroundTransparency = 1; container.Parent = gui
    local nameLbl = Instance.new("TextLabel"); nameLbl.Size = UDim2.new(1, 0, 0, 22); nameLbl.BackgroundTransparency = 1; nameLbl.Text = plr.Name; nameLbl.TextColor3 = Color3.fromRGB(255, 255, 255); nameLbl.TextStrokeTransparency = 0; nameLbl.TextStrokeColor3 = Color3.fromRGB(0, 0, 0); nameLbl.Font = Enum.Font.GothamBold; nameLbl.TextSize = 14; nameLbl.Parent = container
    local hpBg = Instance.new("Frame"); hpBg.Size = UDim2.new(0, 100, 0, 6); hpBg.Position = UDim2.new(0.5, -50, 0, 26); hpBg.BackgroundColor3 = Color3.fromRGB(40, 40, 50); hpBg.BorderSizePixel = 0; hpBg.Parent = container; corner(hpBg, 3)
    local hpBar = Instance.new("Frame"); hpBar.Size = UDim2.new(1, 0, 1, 0); hpBar.BackgroundColor3 = Color3.fromRGB(80, 220, 120); hpBar.BorderSizePixel = 0; hpBar.Parent = hpBg; corner(hpBar, 3)
    local distLbl = Instance.new("TextLabel"); distLbl.Size = UDim2.new(1, 0, 0, 16); distLbl.Position = UDim2.new(0, 0, 0, 34); distLbl.BackgroundTransparency = 1; distLbl.Text = string.format("%dm", math.floor(dist)); distLbl.TextColor3 = Color3.fromRGB(200, 220, 255); distLbl.TextStrokeTransparency = 0; distLbl.TextStrokeColor3 = Color3.fromRGB(0, 0, 0); distLbl.Font = Enum.Font.GothamMedium; distLbl.TextSize = 12; distLbl.Parent = container
    ESPObjects[plr] = { highlight = highlight, gui = gui, hpBar = hpBar, distLbl = distLbl, nameLbl = nameLbl, char = char }
end

RunService.RenderStepped:Connect(function()
    ClearESP()
    if not Config.ESP.Enabled then return end
    for _, plr in ipairs(Players:GetPlayers()) do
        if plr ~= LocalPlayer then
            local char = plr.Character
            if char then
                local hrp = char:FindFirstChild("HumanoidRootPart")
                local head = char:FindFirstChild("Head")
                local hum = char:FindFirstChildOfClass("Humanoid")
                if hrp and head and hum and hum.Health > 0 then
                    local dist = (Camera.CFrame.Position - hrp.Position).Magnitude
                    if dist <= 1000 then CreateESP(plr, char, head, hum, dist) end
                end
            end
        end
    end
end)

RunService.RenderStepped:Connect(function()
    for plr, data in pairs(ESPObjects) do
        local char = plr.Character
        if char and char == data.char then
            local hum = char:FindFirstChildOfClass("Humanoid")
            local head = char:FindFirstChild("Head")
            if hum and data.hpBar and data.hpBar.Parent then
                local hpP = math.clamp(hum.Health / hum.MaxHealth, 0, 1)
                data.hpBar.Size = UDim2.new(hpP, 0, 1, 0)
                if hpP > 0.5 then data.hpBar.BackgroundColor3 = Color3.fromRGB(80, 220, 120)
                elseif hpP > 0.25 then data.hpBar.BackgroundColor3 = Color3.fromRGB(255, 200, 60)
                else data.hpBar.BackgroundColor3 = Color3.fromRGB(240, 80, 90) end
            end
            if head and data.distLbl then
                data.distLbl.Text = string.format("%dm", math.floor((Camera.CFrame.Position - head.Position).Magnitude))
            end
            if data.nameLbl then data.nameLbl.Visible = Config.ESP.Names end
            if data.distLbl then data.distLbl.Visible = Config.ESP.Distance end
        end
    end
end)

UserInputService.InputBegan:Connect(function(input, gpe)
    if gpe then return end
    if input.KeyCode == Enum.KeyCode.RightShift then
        Frame.Visible = not Frame.Visible
    end
end)

RefreshTPList()
RefreshPlayerList()
SetTab(1)
ApplyLanguage()

for code, b in pairs(LangButtons) do
    b.BackgroundColor3 = (code == Config.Language) and Theme.Accent or Theme.Card
    b.TextColor3 = (code == Config.Language) and Color3.fromRGB(255,255,255) or Theme.Text
end

if Config.Fly.Enabled then StartFly() end
if Config.Speed.Enabled then local hum = GetHum() if hum then hum.WalkSpeed = Config.Speed.Value end end
if GetHum() then local hum = GetHum() hum.UseJumpPower = true hum.JumpPower = Config.JumpPower end
