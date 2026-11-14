--[[
    ================================================================
    Project: LK Ultimate Hub (Premium UI Framework)
    Author: LK Team
    Version: v11.5 (最终完美分块版)
    Description: 
        - 顶级付费级别通用 UI 框架，适配 PC 端与移动端。
        - 极低功耗，修复所有已知内存泄漏、相机死锁、换肤同步漏洞。
        - 内置反踢、防传送、极速提帧等底层防封机制。
    ================================================================
]]

-- ==================== 1. 全局配置区 ====================
getgenv().LK_Config = {
    ToggleKey = Enum.KeyCode.RightShift,
    DefaultTheme = "LK_Purple",
    EnableAntiKick = true,
    EnableAntiTP = true,
    WatermarkText = "LK PREMIUM"
}

-- ==================== 2. 环境清理与安全隔离 ====================
if getgenv().LK_Cleanup then pcall(getgenv().LK_Cleanup) end
for _, name in pairs({"LK_UI", "LK_Watermark", "LK_MiniGui", "Network_Stats"}) do
    local coreGui = game:GetService("CoreGui")
    local existing = coreGui:FindFirstChild(name)
    if existing then pcall(function() existing:Destroy() end) end
end

getgenv().LK_Env = { 
    Connections = {}, 
    ThemeColor = Color3.fromHex("#A855F7"), 
    IsMobile = game:GetService("UserInputService").TouchEnabled,
    IsDraggingSlider = false,
    ActiveSliderFills = {} -- 用于同步换肤
}
local Env = getgenv().LK_Env
local Config = getgenv().LK_Config

local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local UserInputService = game:GetService("UserInputService")
local TweenService = game:GetService("TweenService")
local Lighting = game:GetService("Lighting")
local LocalPlayer = Players.LocalPlayer
local Camera = workspace.CurrentCamera
local function addConn(conn) table.insert(Env.Connections, conn); return conn end

-- ==================== 3. 底层防封护盾 ====================
if Config.EnableAntiKick then
    pcall(function()
        if hookmetamethod and getnamecallmethod and not getgenv().LK_OldNamecall then
            getgenv().LK_OldNamecall = hookmetamethod(game, "__namecall", function(self, ...)
                local method = getnamecallmethod()
                if method == "Kick" and self == LocalPlayer then return nil end
                if typeof(self) == "Instance" and self:IsA("RemoteEvent") then
                    local name = string.lower(self.Name)
                    if name:find("anticheat") or name:find("kick") or name:find("ban") or name:find("report") then return nil end
                end
                return getgenv().LK_OldNamecall(self, ...)
            end)
        end
    end)
end

if Config.EnableAntiTP then
    getgenv().LK_AntiTP = true
    local lastSafePos = nil
    local canRecord = false
    
    LocalPlayer.CharacterAdded:Connect(function() 
        canRecord = false 
        task.wait(1) 
        canRecord = true 
    end)
    if LocalPlayer.Character then canRecord = true end

    addConn(RunService.Heartbeat:Connect(function()
        if not getgenv().LK_AntiTP or not canRecord then return end
        pcall(function()
            local char = LocalPlayer.Character
            local hrp = char and char:FindFirstChild("HumanoidRootPart")
            local hum = char and char:FindFirstChildOfClass("Humanoid")
            if not hrp or not hum or hum.Health <= 0 then lastSafePos = nil; return end
            
            local state = hum:GetState()
            if state ~= Enum.HumanoidStateType.Jumping and state ~= Enum.HumanoidStateType.Freefall and state ~= Enum.HumanoidStateType.Flying then
                if not lastSafePos or (hrp.Position - lastSafePos.Position).Magnitude < 100 then
                    lastSafePos = hrp.CFrame
                end
            end
            
            if lastSafePos then
                if (hrp.Position - lastSafePos.Position).Magnitude > 800 then hrp.CFrame = lastSafePos
                elseif hrp.Position.Y < -50 then hrp.CFrame = CFrame.new(0, 50, 0) end
            end
        end)
    end))
end-- ==================== 4. 水印与 UI 引擎初始化 ====================
getgenv().LK_Watermark = Instance.new("ScreenGui")
getgenv().LK_Watermark.Name = "Network_Stats_Overlay"
getgenv().LK_Watermark.ResetOnSpawn = false
getgenv().LK_Watermark.Parent = game:GetService("CoreGui")

local WM_Frame = Instance.new("Frame", getgenv().LK_Watermark)
WM_Frame.Size = UDim2.new(0, 160, 0, 22); WM_Frame.Position = UDim2.new(0, 15, 0, 15)
WM_Frame.BackgroundColor3 = Color3.fromHex("#0F0F13"); WM_Frame.BackgroundTransparency = 0.3
Instance.new("UICorner", WM_Frame).CornerRadius = UDim.new(0, 4)

Env.WM_Stroke = Instance.new("UIStroke", WM_Frame)
Env.WM_Stroke.Color = Env.ThemeColor; Env.WM_Stroke.Transparency = 0.5; Env.WM_Stroke.Thickness = 1

local WM = Instance.new("TextLabel", WM_Frame)
WM.Size = UDim2.new(1, 0, 1, 0); WM.BackgroundTransparency = 1
WM.TextColor3 = Color3.fromRGB(255,255,255); WM.Font = Enum.Font.GothamBold; WM.TextSize = 11; WM.TextXAlignment = Enum.TextXAlignment.Center
WM.Text = Config.WatermarkText .. " | 运行中"

-- 低功耗 FPS 刷新
task.spawn(function()
    local frameC = 0
    local fpsT = tick()
    while task.wait(0.1) do
        frameC = frameC + 1
        if tick() - fpsT >= 1 then
            pcall(function() WM.Text = Config.WatermarkText .. " | FPS: " .. math.floor(frameC / (tick() - fpsT)) end)
            frameC = 0; fpsT = tick()
        end
    end
end)

-- 安全加载 WindUI
local success, WindUI = pcall(function()
    return loadstring(game:HttpGet("https://github.com/Footagesus/WindUI/releases/latest/download/main.lua"))()
end)
if not success or not WindUI then return warn("[LK HUB] UI库加载失败，请检查网络") end

-- 注册四大护眼主题
WindUI:AddTheme({ Name = "LK_Purple", Accent = Color3.fromHex("#A855F7"), Background = Color3.fromHex("#0A0A0C"), BackgroundSecondary = Color3.fromHex("#121216"), Text = Color3.fromHex("#FFFFFF"), SubText = Color3.fromHex("#A1A1AA"), Outline = Color3.fromHex("#27272A"), Button = Color3.fromHex("#18181B"), ButtonHover = Color3.fromHex("#27272A") })
WindUI:AddTheme({ Name = "LK_Blue", Accent = Color3.fromHex("#3B82F6"), Background = Color3.fromHex("#0F172A"), BackgroundSecondary = Color3.fromHex("#1E293B"), Text = Color3.fromHex("#F8FAFC"), SubText = Color3.fromHex("#94A3B8"), Outline = Color3.fromHex("#334155"), Button = Color3.fromHex("#1E293B"), ButtonHover = Color3.fromHex("#334155") })
WindUI:AddTheme({ Name = "LK_Green", Accent = Color3.fromHex("#10B981"), Background = Color3.fromHex("#0A120E"), BackgroundSecondary = Color3.fromHex("#121C17"), Text = Color3.fromHex("#ECFDF5"), SubText = Color3.fromHex("#86EFAC"), Outline = Color3.fromHex("#1E3A2B"), Button = Color3.fromHex("#121C17"), ButtonHover = Color3.fromHex("#1E3A2B") })
WindUI:AddTheme({ Name = "LK_Orange", Accent = Color3.fromHex("#F97316"), Background = Color3.fromHex("#140F0A"), BackgroundSecondary = Color3.fromHex("#1C1611"), Text = Color3.fromHex("#FFF7ED"), SubText = Color3.fromHex("#FDBA74"), Outline = Color3.fromHex("#3A2A1E"), Button = Color3.fromHex("#1C1611"), ButtonHover = Color3.fromHex("#3A2A1E") })

WindUI:SetTheme(Config.DefaultTheme)

local Window = WindUI:CreateWindow({
    Title = "LK Premium", Icon = "shield", Author = "LK Team", 
    Size = UDim2.fromOffset(540, 400), ToggleKey = Config.ToggleKey, Transparent = true
})

-- 换肤同步引擎 (全局函数)
local function SyncThemeColor(newColor)
    Env.ThemeColor = newColor
    pcall(function() Env.WM_Stroke.Color = newColor end)
    pcall(function()
        if Env.MainStroke then Env.MainStroke.Color = newColor end
        if Env.MiniStroke then Env.MiniStroke.Color = newColor end
        if Env.MiniGrad then Env.MiniGrad.Color = ColorSequence.new{ ColorSequenceKeypoint.new(0, newColor), ColorSequenceKeypoint.new(0.5, Color3.fromHex("#FFFFFF")), ColorSequenceKeypoint.new(1, newColor) } end
        for _, fill in pairs(Env.ActiveSliderFills) do
            if fill and fill.Parent then fill.BackgroundColor3 = newColor end
        end
    end)
end-- ==================== 5. 高级 UI 挂载与交互引擎 ====================
local function forceRestoreCamera()
    pcall(function() if Camera.CameraType == Enum.CameraType.Scriptable then Camera.CameraType = Enum.CameraType.Custom end end)
end
addConn(LocalPlayer.CharacterAdded:Connect(function() task.wait(0.5); forceRestoreCamera() end))

task.spawn(function()
    local gui = Window.Gui or Window.MainFrame
    local timeout = tick() + 5
    if not gui then 
        repeat task.wait(0.1) until Window.Gui or Window.MainFrame or tick() > timeout
        gui = Window.Gui or Window.MainFrame
    end
    if not gui then return end
    task.wait(0.2)
    
    pcall(function()
        gui.Name = "Player_Stats_Menu" 
        
        -- 智能屏幕尺寸缩放
        local uis = gui:FindFirstChildOfClass("UIScale") or Instance.new("UIScale", gui)
        if Env.IsMobile then
            local screenSize = workspace.CurrentCamera.ViewportSize
            uis.Scale = math.clamp(screenSize.X / 800, 0.55, 0.8)
        else
            uis.Scale = 0.85
        end
        
        local mainFrame = nil
        for _, v in pairs(gui:GetDescendants()) do if v:IsA("Frame") and v.Size.X.Offset >= 500 then mainFrame = v; break end end
        if mainFrame then
            mainFrame.BackgroundTransparency = 0.1
            Env.MainStroke = Instance.new("UIStroke", mainFrame); Env.MainStroke.Color = Env.ThemeColor; Env.MainStroke.Transparency = 0.7; Env.MainStroke.Thickness = 1.5
            
            -- 主界面拖拽
            local dragging, dragInput, dragStart, startPos
            mainFrame.InputBegan:Connect(function(input)
                if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
                    local mouse = UserInputService:GetMouseLocation()
                    if mouse.Y - mainFrame.AbsolutePosition.Y <= 45 then
                        dragging = true; dragStart = input.Position; startPos = mainFrame.Position
                    end
                end
            end)
            mainFrame.InputChanged:Connect(function(input) 
                if input.UserInputType == Enum.UserInputType.MouseMovement or input.UserInputType == Enum.UserInputType.Touch then dragInput = input end 
            end)
            UserInputService.InputChanged:Connect(function(input)
                if input == dragInput and dragging then
                    local delta = input.Position - dragStart
                    mainFrame.Position = UDim2.new(startPos.X.Scale, startPos.X.Offset + delta.X, startPos.Y.Scale, startPos.Y.Offset + delta.Y)
                end
            end)
        end
        
        -- PC端悬停特效
        if not Env.IsMobile then
            for _, v in pairs(gui:GetDescendants()) do
                if v:IsA("TextButton") then
                    v.MouseEnter:Connect(function() v.BackgroundTransparency = 0.2 end)
                    v.MouseLeave:Connect(function() v.BackgroundTransparency = 0.5 end)
                end
            end
        end

        -- 灵动岛悬浮窗
        getgenv().LK_MiniGui = Instance.new("ScreenGui")
        local MiniGui = getgenv().LK_MiniGui
        MiniGui.Name = "LK_MiniGui"; MiniGui.ResetOnSpawn = false; MiniGui.Parent = game:GetService("CoreGui"); MiniGui.Enabled = false
        
        local MiniFrame = Instance.new("TextButton")
        MiniFrame.Size = UDim2.new(0, 110, 0, 35); MiniFrame.Position = UDim2.new(0.5, -55, 0, 50)
        MiniFrame.BackgroundColor3 = Color3.fromRGB(10, 10, 12); MiniFrame.BackgroundTransparency = 0.05
        MiniFrame.Text = ""; MiniFrame.AutoButtonColor = false; MiniFrame.BorderSizePixel = 0; MiniFrame.Parent = MiniGui
        Instance.new("UICorner", MiniFrame).CornerRadius = UDim.new(1, 0)
        
        Env.MiniStroke = Instance.new("UIStroke", MiniFrame); Env.MiniStroke.Color = Env.ThemeColor; Env.MiniStroke.Transparency = 0.3; Env.MiniStroke.Thickness = 1.5
        Env.MiniGrad = Instance.new("UIGradient", Env.MiniStroke)
        Env.MiniGrad.Color = ColorSequence.new{ColorSequenceKeypoint.new(0, Env.ThemeColor), ColorSequenceKeypoint.new(0.5, Color3.fromHex("#FFFFFF")), ColorSequenceKeypoint.new(1, Env.ThemeColor)}
        
        -- 低功耗流光
        task.spawn(function()
            while task.wait(0.05) do
                if not MiniFrame.Parent then break end
                if MiniGui.Enabled then
                    pcall(function() Env.MiniGrad.Rotation = Env.MiniGrad.Rotation + 4 end)
）结束）
结束
        结束）

        local mtxt = Instance.new("TextLabel", MiniFrame); mtxt.Size = UDim2.new(1, -25, 1, 0); mtxt.Position = UDim2.new(0, 25, 0, 0); mtxt.BackgroundTransparency = 1
        mtxt.Text = "LK ULTRA"; mtxt.TextColor3 = Color3.fromRGB(255,255,255); mtxt.Font = Enum.Font.GothamBold; mtxt.TextSize = 11; mtxt.TextXAlignment = Enum.TextXAlignment.Left

        local isDragging, hasMoved, startPos, dragStart
        MiniFrame.InputBegan:Connect(function(input)
            if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
                isDragging = true; hasMoved = false; dragStart = input.Position; startPos = MiniFrame.Position
                TweenService:Create(MiniFrame, TweenInfo.new(0.15, Enum.EasingStyle.Back, Enum.EasingDirection.Out), {Size = UDim2.new(0, 100, 0, 32)}):Play()
                input.Changed:Connect(function()
                    if input.UserInputState == Enum.UserInputState.End then
                        isDragging = false
                        TweenService:Create(MiniFrame, TweenInfo.new(0.2, Enum.EasingStyle.Back, Enum.EasingDirection.Out), {Size = UDim2.new(0, 110, 0, 35)}):Play()
                        if not hasMoved then gui.Enabled = true; MiniGui.Enabled = false end
                    end
                end)
            结束
        结束）
        MiniFrame.InputChanged:Connect(function(input)
            if (input.UserInputType == Enum.UserInputType.MouseMovement or input.UserInputType == Enum.UserInputType.Touch) and isDragging then
                local delta = input.Position - dragStart
                if delta.Magnitude > 8 then hasMoved = true; MiniFrame.Position = UDim2.new(startPos.X.Scale, startPos.X.Offset + delta.X, startPos.Y.Scale, startPos.Y.Offset + delta.Y) end
            结束
        结束）

        -- 核心优化：精准捕获关闭，放弃全帧轮询
        for _, v in pairs(gui:GetDescendants()) do
            if v:IsA("TextButton") and (v.Name == "Close" or string.find(string.lower(v.Name), "close")) then
                v.MouseButton1Click:Connect(function()
                    task.wait(0.1)
                    if not gui.Enabled then MiniGui.Enabled = true end
                end)
            结束
结束
）结束）
结束
local function CreateSmoothSlider(parentTab, titleText, minVal, maxVal, defaultVal, callback)
    local frame = Instance.new("Frame"); frame.Size = UDim2.new(1, 0, 0, 45); frame.BackgroundTransparency = 1; frame.Parent = parentTab.Container or parentTab
    local label = Instance.new("TextLabel"); label.Size = UDim2.new(0.7, 0, 0, 20); label.BackgroundTransparency = 1; label.Text = titleText; label.TextColor3 = Color3.fromRGB(255, 255, 255); label.TextXAlignment = Enum.TextXAlignment.Left; label.Font = Enum.Font.GothamBold; label.TextSize = 14; label.Parent = frame
    local valLabel = Instance.new("TextLabel"); valLabel.Size = UDim2.new(0.3, 0, 0, 20); valLabel.Position = UDim2.new(0.7, 0, 0, 0); valLabel.BackgroundTransparency = 1; valLabel.Text = tostring(defaultVal); valLabel.TextColor3 = Color3.fromRGB(255, 255, 255); valLabel.TextXAlignment = Enum.TextXAlignment.Right; valLabel.Font = Enum.Font.GothamBold; valLabel.TextSize = 14; valLabel.Parent = frame
    local track = Instance.new("Frame"); track.Size = UDim2.new(1, 0, 0, 4); track.Position = UDim2.new(0, 0, 0, 30); track.BackgroundColor3 = Color3.fromRGB(60, 60, 70); track.BorderSizePixel = 0; track.Parent = frame
    local fill = Instance.new("Frame"); fill.Size = UDim2.new((defaultVal - minVal) / (maxVal - minVal), 0, 1, 0); fill.BackgroundColor3 = Env.ThemeColor; fill.BorderSizePixel = 0; fill.Parent = track
    table.insert(Env.ActiveSliderFills, fill) -- 存入换色数组
    local thumb = Instance.new("TextButton"); thumb.Size = UDim2.new(0, Env.IsMobile and 40 or 20, 0, Env.IsMobile and 40 or 20); thumb.AnchorPoint = Vector2.new(0.5, 0.5); thumb.Position = UDim2.new((defaultVal - minVal) / (maxVal - minVal), 0, 0.5, 0); thumb.BackgroundColor3 = Color3.fromRGB(255, 255, 255); thumb.Text = ""; thumb.Parent = track; Instance.new("UICorner", thumb).CornerRadius = UDim.new(1, 0)
    
    local dragging = false; local activeInput = nil; local oldCamType = Camera.CameraType
    local function updateValue(input)
        local percent = math.clamp((input.Position.X - track.AbsolutePosition.X) / track.AbsoluteSize.X, 0, 1)
        fill.Size = UDim2.new(percent, 0, 1, 0); thumb.Position = UDim2.new(percent, 0, 0.5, 0)
        local value = math.floor(minVal + (maxVal - minVal) * percent)
        valLabel.Text = tostring(value); if callback then callback(value) end
    end
    thumb.InputBegan:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then 
            dragging = true; activeInput = input; updateValue(input) 
            Env.IsDraggingSlider = true 
            oldCamType = Camera.CameraType; pcall(function() Camera.CameraType = Enum.CameraType.Scriptable end) 
        end
    end)
    
    -- 全局底层监听，防止相机永久锁死
    addConn(UserInputService.InputEnded:Connect(function(input) 
        if input == activeInput or (dragging and (input.UserInputType == Enum.UserInputType.Touch or input.UserInputType == Enum.UserInputType.MouseButton1)) then 
            dragging = false; activeInput = nil
            Env.IsDraggingSlider = false
            pcall(function() Camera.CameraType = oldCamType end) 
        end 
    end))
    
    addConn(UserInputService.InputChanged:Connect(function(input) 
        if dragging and input == activeInput and (input.UserInputType == Enum.UserInputType.MouseMovement or input.UserInputType == Enum.UserInputType.Touch) then updateValue(input) end 
    end))
    
    track.InputBegan:Connect(function(input) 
        if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then updateValue(input) end 
    end)
end-- ==================== 7. 功能页面构建 ====================
local SafetyTab = Window:Tab({ Title = "安全护盾", Icon = "shield" })
SafetyTab:Toggle({ Title = "物理隔断防传送", Value = true, Callback = function(state) getgenv().LK_AntiTP = state end })

local ThemeTab = Window:Tab({ Title = "外观设置", Icon = "palette" })
ThemeTab:Paragraph({ Title = "护眼UI换肤", Desc = "所有颜色均经过低饱和度处理，长时间游玩不伤眼。" })
ThemeTab:Button({ Title = "🟣 幻夜紫", Callback = function() WindUI:SetTheme("LK_Purple"); SyncThemeColor(Color3.fromHex("#A855F7")) end })
ThemeTab:Button({ Title = "🔵 极光深蓝", Callback = function() WindUI:SetTheme("LK_Blue"); SyncThemeColor(Color3.fromHex("#3B82F6")) end })
ThemeTab:Button({ Title = “🟢 翡翠暗绿”, Callback =10B981”) ) 结束 })
ThemeTab:Button({ Title = “🟠 落日暖橘”, Callback =function() WindUI:SetTheme(“LK_Orange”); SyncThemeColor(Color3.fromHex(“#F97316”) ) 结束 })

本地 ToolsTab = Window:Tab({ Title = “性能优化”, Icon = “zap” })
ToolsTab:Button({ Title = “极限提帧（去除粒子特效）”, Callback =
pcall(函数())
局部变量count的初始值为0
为了 _，v在……中对game:GetDescendants()进行配对操作。
如果v属于“粒子发射器”类别，或是“烟雾”类别，又是“火焰”类别，或者是“爆炸”类别，那么就将其启用状态设置为虚假；同时，count的值加1。1。1。1。1。1。1。1。1。1。1。1。1。1。1。1。1。1。1。1。1。1。1。1。1。1。1。1。1。1。1。1。1。1。1。1。1。1。1。1。1。1。1。1。1。1。1。1。1。1。1。1。1。1。1。1。1。1。1。1。1。1。1。1。1。1。1。1。1。1。1。1。1。1。1。1。1。1。1。1。1。1。1。1。1。1。1。1。1。1。1。1。1。1。1。1。1。1。1。1。1。1。1。1。1。1。1。1。1。1。1。1。1。1。1。1。1。1。1。1。1。1。1。1。1。1。1。1。1。1。1。1。1。1。1。1。1。1。1。1。1。1。1。1。1。1。1。1。1。1。1。1。1。1。1。1。1。1。1。1。1。1。1。1。1。1。1。1。1。1。1。1。1。1。1。1。1。1。1。1。1。1。1。1。1。1。1。1。1。1。1。1。1。1。1。1。1。1。1。1。1。1。1。1。1。1。1。1。1。1。1。1。1。1。1。1。1。1。1。1。1。1。1。1。1。1。1。1。1。1。1。1。1。1。1。1。1。1。1。1。1。1。1。1。1。1。1。1。1。1。1。1。1。1。1。1。1。1。1。1。1。1。1。1。1。1。1。1。1。1。1。1。1。1。1。1。1。1。1。1。1。1。1。1。1。1。1。1。1。1。1。1。1。1。1。1。1。1。1。1。1。1。1。1。1。1。1。1。1。1。1。1。1。1。1。1。1。1。1。1。1。1。1。1。1。1。1。1。1。1。1。1。1。1。1。1。1。1。1。1。1。1。1。1。1。1。1。1。1。1。1。1。1。1。1。1。1。1。1。1。1。1。1。1。1。1。1。1。1。1。1。1。1。1。1。1。1。1。1。1。1。1。1。1。1。1。1。1。1。1。1。1。1。1。1。1。1。1。1。1。1。1。1。1。1。1。1。1。1。1。1。1。1。1。1。1。1。1。1。1。1。1。1。1。1。1。1。1。1。1。1。1。1。1。1。1。1。1。1。1。1。1。1。1。1。1。1。1。1。1。1。1。1。1。1。1。1。1。1。1。1。1。1。1。1。1。1。1。1。1。1。1。1。1。1。1。1。1。1。1。1。1。1。1。1。1。1。1。1。1。1。1。1。1。1。1。1。1。1。1。1。1。1。1。1。1。1。1。1。1。1。1。1。1。1。1。1。1。1。1。1。1。1。1。1。1。1。1。1。1。1。1。1。1。1。1。1。1。1。1。1。1。1。1。1。1。1。1。1。1。1。1。1。1。1。1。1。1。1。1。1。1。1。1。1。1。1。1。1。1。1。1。1。1。1。1。1。1。1。1。1。1。1。1。1。1。1。1。1。1。1。1。1。1。1。1。1。1。1。1。1。1。1。1。1。1。1。1。1。1。1。1。1。1。1。1。1。1。1。1。1。1。1。1。1。1。1。1。1。1。1。1。1。1。1。1。1。1。1。1。1。1。1。1。1。1。1。1。1。1。1。1。1。1。1。1。1。1。1。1。1。1。1。1。1。1。1。1。1。1。1。1。1。1。1。1。1。1。1。1。1。1。1。1。1。1。1。1。1。1。1。1。1。1。1。1。1。1。1。1。1。1。1。1。1。1。1。1。1。1。1。1。1。1。1。1。1。1。1。1。1。1。1。1。1。1。1。1。1。1。1。1。1。1。1。1。1。1。1。1。1。1。1。1。1。1。1。1。1。1。1。1。1。1。1。1。1。1。1。1。1。1。1。1。1。1。1。1。1。1。1。1。1。1。1。1。1。1。1。1。1。1。1。1。1。1。1。1。1。1。1。1。1。1。1。1。1。1。1。1。1。1。1。1。1。1。1。1。1。1。1。1。1。1。1。1。1。1。1。1。1。1。1。1。1。1。1。1。1。1。1。1。1。1。1。1。1。1。1。1。1。1。1。1。1。1。1。1。1。1。1。1。1。1。1。1。1。1。1。1。1。1。1。1。1。1。1。1。1。1。1。1。1。1。1。1。1。1。1。1。1。1。1。1。1。1。1。1。1。1。1。1。1。1。1。1。1。1。1。1。1。1。1。1。1。1。1。1。1。1。1。1。1。1。1。1。1。1。1。1。1。1。1。1。1。1。1。1。1。1。1。1。1。1。1。1。1。1。1。1。1。1。1。1。1。1。1。1。1。1。1。1。1。1。1。1。1。1。1。1。1。1。1。1。1。1。1。1。1。1。1。1。1。1。1。1。1。1。1。1。1。1。1。1。1。1。1。1。1。1。1。1。1。1。1。1。1。1。1。1。1。1。1。1。1。1。1。1。1。1。1。1。1。1。1。1。1。1。1。1。1。1。1。1。1。1。1。1。1。1。1。1。1。1。1。1。1。1。1。1。1。1。1。1。1。1。1。1。1。1。1。1。1。1。1。1。1。1。1。1。1。1。1。1。1。1。1。1。1。1。1。1。1。1。1。1。1。1。1。1。1。1。1。1。1。1。1。1。1。1。1。1。1。1。1。1。1。1。1。1。1。1。1。1。1。1。1。1。1。1。1。1。1。1。1。1。1。1。1。1。1。1。1。1。1。1。1。1。1。1。1。1。1。1。1。1。1。1。1。1。1。1。1。1。1。1。1。1。1。1。1。1。1。1。1。1。1。1。1。1。1。1。1。1。1。1。1。1。1。1。1。1。1。1。1。1。1。1。1。1。1。1。1。1。1。1。1。1。1。1。1。1。1。1。1。1。1。1。1。1。1。1。1。1。1。1。1。1。1。1。1。1。1。1。1。1。1。1。1。1。1。1。1。1。1。1。1。1。1。1。1。1。1。1。1。1。1。1。1。1。1。1。1。1。1。1。1。1。1。1。1。1。1。1。1。1。1。1。1。1。1。1。1。1。1。1。1。1。1。1。1。1。1。1。1。1。1。1。1。1。1。1。1。1。1。1。1。1。1。1。1。1。1。1。1。1。1。1。1。1。1。1。1。1。1。1。1。1。1。1。1。1。1。1。1。1。1。1。1。1。1。1。1。1。1。1。1。1。1。1。1。1。1。1。1。1。1。1。1。1。1。1。1。1。1。1。1。1。1。1。1。1。1。1。1。1。1。1。1。1。1。1。1。1。1。1。1。1。1。1。1。1。1。1。1。1。1。1。1。1。1。1。1。1。1。1。1。1。1。1。1。1。1。1。1。1。1。1。1。1。1。1。1。1。1。1。1。1。1。1。1。1。1。1。1。1。1。1。1。1。1。1。1。1。1。1。1。1。1。1。1。1。1。1。1。1。1。1。1。1。1。1。1。1。1。1。1。1。1。1。1。1。1。1。1。1。1。1。1。1。1。1。1。1。1。1。1。1。1。1。1。1。1。1。1。1。1。1。1。1。1。1。1。1。1。1。1。1。1。1。1。1。1。1。1。1。1。1。1。1。1。1。1。1。1。1。1。1。1。1。1。1。1。1。1。1。1。1。1。1。1。1。1。1。1。1。1。1。1。1。1。1。1。1。1。1。1。1。1。1。1。1。1。1。1。1。1。1。1。1。1。1。1。1。1。1。1。1。1。1。1。1。1。1。1。1。1。1。1。1。1。1。1。1。1。1。1。1。1。1。1。1。1。1。1。1。1。1。1。1。1。1。1。1。1。1。1。1。1。1。1。1。1。1。1。1。1。1。1。1。1。1。1。1。1。1。1。1。1。1。1。1。1。1。1。1。1。1。1。1。1。1。1。1。1。1。1。1。1。1。1。1。1。1。1。1。1。1。1。1。1。1。1。1。1。1。1。1。1。1。1。1。1。1。1。1。1。1。1。1。1。1。1。1。1。1。1。1。1。1。1。1。1。1。1。1。1。1。1。1。1。1。1。1。1。1。1。1。1。1。1。1。1。1。1。1。1。1。1。1。1。1。1。1。1。1。1。1。1。1。1。1。1。1。1。1。1。1。1。1。1。1。1。1。1。1。1。1。1。1。1。1。1。1。1。1。1。1。1。1。1。1。1。1。1。1。1。1。1。1。1。1。1。1。1。1。1。1。1。1。1。1。1。1。1。1。1。1。1。1。1。1。1。1。1。1。1。1。1。1。1。1。1。1。1。1。1。1。1。1。1。1。1。1。1。1。1。1。1。1。1。1。1。1。1。1。1。1。1。1。1。1。1。1。1。1。1。1。1。1。1。1。1。1。1。1。1。1。1。1。1。1。1。1。1。1。1。1。1。1。1。1。1。1。1。1。1。1。1。1。1。1。1。1。1。1。1。1。1。1。1。1。1。1。1。1。1。1。1。1。1。1。1。1。1。1。1。1。1。1。1。1。1。1。1。1。1。1。1。1。1。1。1。1。1。1。1。1。1。1。1。1。1。1。1。1。1。1。1。1。1。1。1。1。1。1。1。1。1。1。1。1。1。1。1。1。1。1。1。1。1。1。1。1。1。1。1。1。1。1。1。1。1。1。1。1。1。1。1。1。1。1。1。1。1。1。1。1。1。1。1。1。1。1。1。1。1。1。1。1。1。1。1。1。1。1。1。1。1。1。
elseif如果v属于“纹理”类型或“贴花”类型，则将v的透明度设置为1；同时让count的值加1。结束
如果 count %500 == 0，那么执行 task.wait()。
结束
Lighting.GlobalShadows = 假；Lighting.FogEnd =100000
）结束）
WindUI:Notify({标题="优化", 内容="帧率已拉满！", Icon=“zap”})
结束 })
CreateSmoothSlider(ToolsTab, “视角拉远 (FOV)”,70, 120, 70，函数(value) Camera.FieldOfView = value 结束)

本地MainTab = Window:Tab({ Title = “我的功能”, Icon = “gamepad-2” })
MainTab:Button({ Title = “测试接入点”，Callback = 函数() WindUI:Notify({Title:“提示”，Content:“请在这里接入你的作弊功能！”，Icon=“检查”}) 结束 })

-- ==================== 8. 终极清理闭环 ====================
getgenv().LK_Cleanup = 函数()
pcall(函数())
如果 Camera.CameraType 等于 Enum.CameraType.Scriptable，那么就将 Camera.CameraType 设置为 Enum.CameraType.Custom。
）结束）
为了_，conn会在……中通过ipairs(Env.Connections)来调用pcall(函数() conn:Disconnect())，以此结束连接。
table.clear(Env.Connections)
table.clear(Env.ActiveSliderFills)
    
本地cg = game:GetService(“CoreGui”)
“LK_UI”
本地 ui = cg:FindFirstChild(uiName)
如果ui存在，则调用pcall函数，使其执行ui:Destroy()操作。
结束
    
如果getgenv().LK_Env存在，则清除getgenv().LK_Env中的内容；然后将getgenv().LK_Env设置为
getgenv().LK_AntiTP = 无
结束

WindUI：通知({标题 = “LK高级版”，内容 = “极速修复版已成功加载，皮肤主题也已完成同步！”，图标 = “皇冠”，时长 =5})
