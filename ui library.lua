-- 🎮 Advanced Roblox UI Library v3.0 - No Key System
-- 🚀 Enhanced Features & Improved Stability
-- 📱 Mobile Responsive Design

local UILibrary = {}
UILibrary.__index = UILibrary

-- Services
local TweenService = game:GetService("TweenService")
local UserInputService = game:GetService("UserInputService")
local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local CoreGui = game:GetService("CoreGui")
local StarterGui = game:GetService("StarterGui")
local TextService = game:GetService("TextService")
local SoundService = game:GetService("SoundService")

-- Configuration
local CONFIG = {
    AnimationSpeed = 0.25,
    SoundEnabled = true,
    AutoSave = true,
    Colors = {
        Primary = Color3.fromRGB(88, 101, 242),
        Secondary = Color3.fromRGB(114, 137, 218),
        Success = Color3.fromRGB(87, 242, 135),
        Warning = Color3.fromRGB(255, 193, 7),
        Danger = Color3.fromRGB(220, 53, 69),
        Info = Color3.fromRGB(23, 162, 184),
        Dark = Color3.fromRGB(32, 34, 37),
        Light = Color3.fromRGB(255, 255, 255),
        Background = Color3.fromRGB(54, 57, 63),
        Surface = Color3.fromRGB(64, 68, 75),
        Accent = Color3.fromRGB(255, 107, 107),
        Text = Color3.fromRGB(255, 255, 255),
        TextSecondary = Color3.fromRGB(200, 200, 200)
    },
    Fonts = {
        Bold = Enum.Font.GothamBold,
        SemiBold = Enum.Font.GothamSemibold,
        Regular = Enum.Font.Gotham,
        Light = Enum.Font.GothamLight
    },
    Themes = {
        Dark = {
            Background = Color3.fromRGB(54, 57, 63),
            Surface = Color3.fromRGB(64, 68, 75),
            Text = Color3.fromRGB(255, 255, 255)
        },
        Light = {
            Background = Color3.fromRGB(240, 242, 247),
            Surface = Color3.fromRGB(255, 255, 255),
            Text = Color3.fromRGB(32, 34, 37)
        },
        Purple = {
            Background = Color3.fromRGB(44, 47, 51),
            Surface = Color3.fromRGB(54, 57, 63),
            Text = Color3.fromRGB(255, 255, 255)
        }
    }
}

-- Utility Functions
local function createTween(object, properties, duration, style, direction)
    if not object or not object.Parent then return end
    duration = duration or CONFIG.AnimationSpeed
    style = style or Enum.EasingStyle.Quad
    direction = direction or Enum.EasingDirection.Out
    local tweenInfo = TweenInfo.new(duration, style, direction)
    return TweenService:Create(object, tweenInfo, properties)
end

local function createCorner(parent, radius)
    local corner = Instance.new("UICorner")
    corner.CornerRadius = UDim.new(0, radius or 8)
    corner.Parent = parent
    return corner
end

local function createGradient(parent, colors, rotation, transparency)
    local gradient = Instance.new("UIGradient")
    gradient.Color = ColorSequence.new(colors)
    gradient.Rotation = rotation or 0
    if transparency then
        gradient.Transparency = NumberSequence.new(transparency)
    end
    gradient.Parent = parent
    return gradient
end

local function createStroke(parent, thickness, color, transparency)
    local stroke = Instance.new("UIStroke")
    stroke.Thickness = thickness or 1
    stroke.Color = color or CONFIG.Colors.Primary
    stroke.Transparency = transparency or 0
    stroke.Parent = parent
    return stroke
end

local function createShadow(parent, intensity)
    intensity = intensity or 0.8
    local shadow = Instance.new("Frame")
    shadow.Name = "Shadow"
    shadow.Size = UDim2.new(1, 6, 1, 6)
    shadow.Position = UDim2.new(0, -3, 0, -3)
    shadow.BackgroundColor3 = Color3.fromRGB(0, 0, 0)
    shadow.BackgroundTransparency = intensity
    shadow.BorderSizePixel = 0
    shadow.ZIndex = (parent.ZIndex or 1) - 1
    shadow.Parent = parent.Parent
    
    createCorner(shadow, 12)
    return shadow
end

local function playSound(soundId, volume)
    if not CONFIG.SoundEnabled then return end
    
    local sound = Instance.new("Sound")
    sound.SoundId = "rbxasset://sounds/" .. soundId
    sound.Volume = volume or 0.5
    sound.Parent = SoundService
    sound:Play()
    
    sound.Ended:Connect(function()
        sound:Destroy()
    end)
end

local function saveSettings(library)
    if not CONFIG.AutoSave then return end
    
    local settings = {
        theme = library.currentTheme,
        position = {
            X = library.mainFrame.Position.X.Scale,
            Y = library.mainFrame.Position.Y.Scale
        },
        size = {
            X = library.mainFrame.Size.X.Offset,
            Y = library.mainFrame.Size.Y.Offset
        },
        minimized = library.minimized
    }
    
    -- Save to datastore or local storage
    _G.UILibrarySettings = settings
end

local function loadSettings(library)
    if not _G.UILibrarySettings then return end
    
    local settings = _G.UILibrarySettings
    
    if settings.theme then
        library:SetTheme(settings.theme)
    end
    
    if settings.position then
        library.mainFrame.Position = UDim2.new(
            settings.position.X, 0,
            settings.position.Y, 0
        )
    end
    
    if settings.size then
        library.mainFrame.Size = UDim2.new(0, settings.size.X, 0, settings.size.Y)
    end
end

-- Main Library Constructor
function UILibrary.new(title, theme, config)
    local self = setmetatable({}, UILibrary)
    
    self.title = title or "Advanced UI Library"
    self.currentTheme = theme or "Dark"
    self.minimized = false
    self.maximized = false
    self.components = {}
    self.tabs = {}
    self.currentTab = nil
    self.notifications = {}
    self.keybinds = {}
    self.dragData = {}
    
    -- Apply custom config
    if config then
        for key, value in pairs(config) do
            if CONFIG[key] then
                for subKey, subValue in pairs(value) do
                    CONFIG[key][subKey] = subValue
                end
            end
        end
    end
    
    self:CreateMainGUI()
    self:InitializeComponents()
    loadSettings(self)
    
    return self
end

function UILibrary:CreateMainGUI()
    -- Try CoreGui first, fallback to PlayerGui
    local parent = CoreGui
    local success = pcall(function()
        local test = Instance.new("ScreenGui", CoreGui)
        test:Destroy()
    end)
    
    if not success then
        parent = Players.LocalPlayer:WaitForChild("PlayerGui")
    end
    
    -- Main ScreenGui
    self.screenGui = Instance.new("ScreenGui")
    self.screenGui.Name = "AdvancedUILibrary_" .. math.random(1000, 9999)
    self.screenGui.ResetOnSpawn = false
    self.screenGui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
    self.screenGui.DisplayOrder = 100
    self.screenGui.IgnoreGuiInset = true
    self.screenGui.Parent = parent
    
    -- Main Frame
    self.mainFrame = Instance.new("Frame")
    self.mainFrame.Name = "MainFrame"
    self.mainFrame.Size = UDim2.new(0, 650, 0, 500)
    self.mainFrame.Position = UDim2.new(0.5, -325, 0.5, -250)
    self.mainFrame.BackgroundColor3 = CONFIG.Colors.Background
    self.mainFrame.BorderSizePixel = 0
    self.mainFrame.Active = true
    self.mainFrame.ZIndex = 1
    self.mainFrame.ClipsDescendants = true
    self.mainFrame.Parent = self.screenGui
    
    createCorner(self.mainFrame, 15)
    createShadow(self.mainFrame, 0.7)
    
    -- Make draggable
    self:MakeDraggable(self.mainFrame)
    
    -- Title Bar
    self.titleBar = Instance.new("Frame")
    self.titleBar.Name = "TitleBar"
    self.titleBar.Size = UDim2.new(1, 0, 0, 50)
    self.titleBar.Position = UDim2.new(0, 0, 0, 0)
    self.titleBar.BackgroundColor3 = CONFIG.Colors.Primary
    self.titleBar.BorderSizePixel = 0
    self.titleBar.ZIndex = 2
    self.titleBar.Parent = self.mainFrame
    
    createCorner(self.titleBar, 15)
    createGradient(self.titleBar, {CONFIG.Colors.Primary, CONFIG.Colors.Secondary}, 45)
    
    -- Fix corner clipping
    local titleBarFix = Instance.new("Frame")
    titleBarFix.Size = UDim2.new(1, 0, 0, 15)
    titleBarFix.Position = UDim2.new(0, 0, 1, -15)
    titleBarFix.BackgroundColor3 = CONFIG.Colors.Secondary
    titleBarFix.BorderSizePixel = 0
    titleBarFix.ZIndex = 2
    titleBarFix.Parent = self.titleBar
    
    -- Title Label with Icon
    self.titleLabel = Instance.new("TextLabel")
    self.titleLabel.Name = "TitleLabel"
    self.titleLabel.Size = UDim2.new(1, -150, 1, 0)
    self.titleLabel.Position = UDim2.new(0, 15, 0, 0)
    self.titleLabel.BackgroundTransparency = 1
    self.titleLabel.Text = "🎮 " .. self.title
    self.titleLabel.TextColor3 = CONFIG.Colors.Light
    self.titleLabel.TextSize = 20
    self.titleLabel.Font = CONFIG.Fonts.Bold
    self.titleLabel.TextXAlignment = Enum.TextXAlignment.Left
    self.titleLabel.ZIndex = 3
    self.titleLabel.Parent = self.titleBar
    
    -- Version Label
    self.versionLabel = Instance.new("TextLabel")
    self.versionLabel.Size = UDim2.new(0, 100, 0, 20)
    self.versionLabel.Position = UDim2.new(1, -250, 0, 5)
    self.versionLabel.BackgroundTransparency = 1
    self.versionLabel.Text = "v3.0"
    self.versionLabel.TextColor3 = CONFIG.Colors.Light
    self.versionLabel.TextSize = 12
    self.versionLabel.Font = CONFIG.Fonts.Regular
    self.versionLabel.TextTransparency = 0.5
    self.versionLabel.ZIndex = 3
    self.versionLabel.Parent = self.titleBar
    
    -- Control Buttons
    self.minimizeBtn = self:CreateControlButton("−", UDim2.new(1, -120, 0, 10), CONFIG.Colors.Warning)
    self.minimizeBtn.MouseButton1Click:Connect(function()
        self:ToggleMinimize()
        playSound("button_click.mp3", 0.3)
    end)
    
    self.maximizeBtn = self:CreateControlButton("□", UDim2.new(1, -80, 0, 10), CONFIG.Colors.Info)
    self.maximizeBtn.MouseButton1Click:Connect(function()
        self:ToggleMaximize()
        playSound("button_click.mp3", 0.3)
    end)
    
    self.closeBtn = self:CreateControlButton("×", UDim2.new(1, -40, 0, 10), CONFIG.Colors.Danger)
    self.closeBtn.MouseButton1Click:Connect(function()
        self:Close()
        playSound("button_click.mp3", 0.3)
    end)
    
    -- Tab System
    self.tabFrame = Instance.new("ScrollingFrame")
    self.tabFrame.Name = "TabFrame"
    self.tabFrame.Size = UDim2.new(1, -20, 0, 40)
    self.tabFrame.Position = UDim2.new(0, 10, 0, 60)
    self.tabFrame.BackgroundColor3 = CONFIG.Colors.Surface
    self.tabFrame.BorderSizePixel = 0
    self.tabFrame.ZIndex = 2
    self.tabFrame.ScrollBarThickness = 4
    self.tabFrame.ScrollBarImageColor3 = CONFIG.Colors.Primary
    self.tabFrame.CanvasSize = UDim2.new(0, 0, 0, 0)
    self.tabFrame.Parent = self.mainFrame
    
    createCorner(self.tabFrame, 8)
    
    local tabLayout = Instance.new("UIListLayout")
    tabLayout.FillDirection = Enum.FillDirection.Horizontal
    tabLayout.SortOrder = Enum.SortOrder.LayoutOrder
    tabLayout.Padding = UDim.new(0, 5)
    tabLayout.Parent = self.tabFrame
    
    -- Auto-resize tab canvas
    tabLayout:GetPropertyChangedSignal("AbsoluteContentSize"):Connect(function()
        self.tabFrame.CanvasSize = UDim2.new(0, tabLayout.AbsoluteContentSize.X + 10, 0, 0)
    end)
    
    -- Content Frame
    self.contentFrame = Instance.new("ScrollingFrame")
    self.contentFrame.Name = "ContentFrame"
    self.contentFrame.Size = UDim2.new(1, -20, 1, -140)
    self.contentFrame.Position = UDim2.new(0, 10, 0, 110)
    self.contentFrame.BackgroundColor3 = CONFIG.Colors.Surface
    self.contentFrame.BorderSizePixel = 0
    self.contentFrame.ScrollBarThickness = 8
    self.contentFrame.ScrollBarImageColor3 = CONFIG.Colors.Primary
    self.contentFrame.CanvasSize = UDim2.new(0, 0, 0, 0)
    self.contentFrame.ZIndex = 2
    self.contentFrame.Parent = self.mainFrame
    
    createCorner(self.contentFrame, 8)
    
    -- Content Layout
    self.contentLayout = Instance.new("UIListLayout")
    self.contentLayout.SortOrder = Enum.SortOrder.LayoutOrder
    self.contentLayout.Padding = UDim.new(0, 8)
    self.contentLayout.Parent = self.contentFrame
    
    -- Auto-resize canvas
    self.contentLayout:GetPropertyChangedSignal("AbsoluteContentSize"):Connect(function()
        self.contentFrame.CanvasSize = UDim2.new(0, 0, 0, self.contentLayout.AbsoluteContentSize.Y + 20)
    end)
    
    -- Status Bar
    self.statusBar = Instance.new("Frame")
    self.statusBar.Name = "StatusBar"
    self.statusBar.Size = UDim2.new(1, 0, 0, 30)
    self.statusBar.Position = UDim2.new(0, 0, 1, -30)
    self.statusBar.BackgroundColor3 = CONFIG.Colors.Dark
    self.statusBar.BorderSizePixel = 0
    self.statusBar.ZIndex = 2
    self.statusBar.Parent = self.mainFrame
    
    createCorner(self.statusBar, 8)
    
    self.statusLabel = Instance.new("TextLabel")
    self.statusLabel.Size = UDim2.new(1, -100, 1, 0)
    self.statusLabel.Position = UDim2.new(0, 10, 0, 0)
    self.statusLabel.BackgroundTransparency = 1
    self.statusLabel.Text = "🚀 Ready - All systems operational"
    self.statusLabel.TextColor3 = CONFIG.Colors.Light
    self.statusLabel.TextSize = 12
    self.statusLabel.Font = CONFIG.Fonts.Regular
    self.statusLabel.TextXAlignment = Enum.TextXAlignment.Left
    self.statusLabel.ZIndex = 3
    self.statusLabel.Parent = self.statusBar
    
    -- FPS Counter
    self.fpsLabel = Instance.new("TextLabel")
    self.fpsLabel.Size = UDim2.new(0, 80, 1, 0)
    self.fpsLabel.Position = UDim2.new(1, -90, 0, 0)
    self.fpsLabel.BackgroundTransparency = 1
    self.fpsLabel.Text = "FPS: 60"
    self.fpsLabel.TextColor3 = CONFIG.Colors.Success
    self.fpsLabel.TextSize = 12
    self.fpsLabel.Font = CONFIG.Fonts.Regular
    self.fpsLabel.TextXAlignment = Enum.TextXAlignment.Right
    self.fpsLabel.ZIndex = 3
    self.fpsLabel.Parent = self.statusBar
    
    -- FPS Counter Logic
    local lastTime = tick()
    local frameCount = 0
    RunService.Heartbeat:Connect(function()
        frameCount = frameCount + 1
        if tick() - lastTime >= 1 then
            local fps = math.floor(frameCount / (tick() - lastTime))
            self.fpsLabel.Text = "FPS: " .. fps
            self.fpsLabel.TextColor3 = fps >= 50 and CONFIG.Colors.Success or fps >= 30 and CONFIG.Colors.Warning or CONFIG.Colors.Danger
            frameCount = 0
            lastTime = tick()
        end
    end)
    
    -- Resize Handle
    self.resizeHandle = Instance.new("Frame")
    self.resizeHandle.Size = UDim2.new(0, 20, 0, 20)
    self.resizeHandle.Position = UDim2.new(1, -20, 1, -20)
    self.resizeHandle.BackgroundColor3 = CONFIG.Colors.Primary
    self.resizeHandle.BorderSizePixel = 0
    self.resizeHandle.ZIndex = 5
    self.resizeHandle.Parent = self.mainFrame
    
    createCorner(self.resizeHandle, 10)
    
    -- Make resizable
    self:MakeResizable(self.mainFrame, self.resizeHandle)
end

function UILibrary:CreateControlButton(text, position, color)
    local button = Instance.new("TextButton")
    button.Size = UDim2.new(0, 30, 0, 30)
    button.Position = position
    button.BackgroundColor3 = color
    button.BorderSizePixel = 0
    button.Text = text
    button.TextColor3 = CONFIG.Colors.Light
    button.TextSize = 18
    button.Font = CONFIG.Fonts.Bold
    button.ZIndex = 3
    button.Parent = self.titleBar
    
    createCorner(button, 6)
    
    -- Enhanced hover effects
    button.MouseEnter:Connect(function()
        createTween(button, {
            BackgroundColor3 = Color3.new(
                math.min(color.R + 0.15, 1),
                math.min(color.G + 0.15, 1),
                math.min(color.B + 0.15, 1)
            ),
            Size = UDim2.new(0, 32, 0, 32)
        }, 0.15):Play()
    end)
    
    button.MouseLeave:Connect(function()
        createTween(button, {
            BackgroundColor3 = color,
            Size = UDim2.new(0, 30, 0, 30)
        }, 0.15):Play()
    end)
    
    return button
end

function UILibrary:MakeDraggable(frame)
    local dragging = false
    local dragStart = nil
    local startPos = nil
    
    self.titleBar.InputBegan:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1 then
            dragging = true
            dragStart = input.Position
            startPos = frame.Position
            
            self.dragData.dragging = true
            playSound("button_click.mp3", 0.2)
        end
    end)
    
    UserInputService.InputChanged:Connect(function(input)
        if dragging and input.UserInputType == Enum.UserInputType.MouseMovement then
            local delta = input.Position - dragStart
            local newPos = UDim2.new(
                startPos.X.Scale, 
                startPos.X.Offset + delta.X, 
                startPos.Y.Scale, 
                startPos.Y.Offset + delta.Y
            )
            
            -- Boundary checking
            local screenSize = workspace.CurrentCamera.ViewportSize
            local frameSize = frame.AbsoluteSize
            
            if newPos.X.Offset < 0 then
                newPos = UDim2.new(0, 0, newPos.Y.Scale, newPos.Y.Offset)
            elseif newPos.X.Offset + frameSize.X > screenSize.X then
                newPos = UDim2.new(0, screenSize.X - frameSize.X, newPos.Y.Scale, newPos.Y.Offset)
            end
            
            if newPos.Y.Offset < 0 then
                newPos = UDim2.new(newPos.X.Scale, newPos.X.Offset, 0, 0)
            elseif newPos.Y.Offset + frameSize.Y > screenSize.Y then
                newPos = UDim2.new(newPos.X.Scale, newPos.X.Offset, 0, screenSize.Y - frameSize.Y)
            end
            
            frame.Position = newPos
        end
    end)
    
    UserInputService.InputEnded:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1 then
            dragging = false
            self.dragData.dragging = false
            saveSettings(self)
        end
    end)
end

function UILibrary:MakeResizable(frame, handle)
    local resizing = false
    local resizeStart = nil
    local startSize = nil
    
    handle.InputBegan:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1 then
            resizing = true
            resizeStart = input.Position
            startSize = frame.Size
        end
    end)
    
    UserInputService.InputChanged:Connect(function(input)
        if resizing and input.UserInputType == Enum.UserInputType.MouseMovement then
            local delta = input.Position - resizeStart
            local newSize = UDim2.new(
                0, math.max(400, startSize.X.Offset + delta.X),
                0, math.max(300, startSize.Y.Offset + delta.Y)
            )
            frame.Size = newSize
        end
    end)
    
    UserInputService.InputEnded:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1 then
            resizing = false
            saveSettings(self)
        end
    end)
end

function UILibrary:InitializeComponents()
    -- Create default tab
    self:CreateTab("Home", "🏠")
    self:ShowNotification("🎉 UI Library loaded successfully!", "success", 3)
    self:UpdateStatus("🚀 Ready - All systems operational")
    
    -- Add welcome content
    self:AddLabel("🎮 Welcome to Advanced UI Library v3.0!", 40, "Home")
    self:AddLabel("✨ No key system required - completely free to use!", 25, "Home")
    self:AddSeparator("Home")
    
    self:AddButton("🔔 Test Notification", function()
        self:ShowNotification("Hello from Advanced UI Library! 🚀", "success")
    end, "success", "🔔", "Home")
    
    self:AddButton("🎨 Change Theme", function()
        local themes = {"Dark", "Light", "Purple"}
        local currentIndex = 1
        for i, theme in ipairs(themes) do
            if theme == self.currentTheme then
                currentIndex = i
                break
            end
        end
        local nextTheme = themes[currentIndex % #themes + 1]
        self:SetTheme(nextTheme)
        self:ShowNotification("Theme changed to " .. nextTheme .. "! 🎨", "info")
    end, "info", "🎨", "Home")
end

-- Tab System
function UILibrary:CreateTab(name, icon)
    local tabButton = Instance.new("TextButton")
    tabButton.Size = UDim2.new(0, 120, 1, 0)
    tabButton.BackgroundColor3 = CONFIG.Colors.Dark
    tabButton.BorderSizePixel = 0
    tabButton.Text = (icon or "📄") .. " " .. name
    tabButton.TextColor3 = CONFIG.Colors.Light
    tabButton.TextSize = 14
    tabButton.Font = CONFIG.Fonts.SemiBold
    tabButton.ZIndex = 3
    tabButton.Parent = self.tabFrame
    
    createCorner(tabButton, 6)
    
    local tabContent = Instance.new("ScrollingFrame")
    tabContent.Name = name .. "Content"
    tabContent.Size = UDim2.new(1, 0, 1, 0)
    tabContent.Position = UDim2.new(0, 0, 0, 0)
    tabContent.BackgroundTransparency = 1
    tabContent.BorderSizePixel = 0
    tabContent.ScrollBarThickness = 8
    tabContent.ScrollBarImageColor3 = CONFIG.Colors.Primary
    tabContent.CanvasSize = UDim2.new(0, 0, 0, 0)
    tabContent.ZIndex = 2
    tabContent.Visible = false
    tabContent.Parent = self.contentFrame
    
    local tabLayout = Instance.new("UIListLayout")
    tabLayout.SortOrder = Enum.SortOrder.LayoutOrder
    tabLayout.Padding = UDim.new(0, 8)
    tabLayout.Parent = tabContent
    
    tabLayout:GetPropertyChangedSignal("AbsoluteContentSize"):Connect(function()
        tabContent.CanvasSize = UDim2.new(0, 0, 0, tabLayout.AbsoluteContentSize.Y + 20)
    end)
    
    self.tabs[name] = {
        button = tabButton,
        content = tabContent,
        layout = tabLayout,
        icon = icon
    }
    
    tabButton.MouseButton1Click:Connect(function()
        self:SwitchTab(name)
        playSound("button_click.mp3", 0.3)
    end)
    
    -- Hover effects
    tabButton.MouseEnter:Connect(function()
        if self.currentTab ~= name then
            createTween(tabButton, {BackgroundColor3 = CONFIG.Colors.Primary}, 0.15):Play()
        end
    end)
    
    tabButton.MouseLeave:Connect(function()
        if self.currentTab ~= name then
            createTween(tabButton, {BackgroundColor3 = CONFIG.Colors.Dark}, 0.15):Play()
        end
    end)
    
    -- Auto-select first tab
    if not self.currentTab then
        self:SwitchTab(name)
    end
    
    return tabContent
end

function UILibrary:SwitchTab(name)
    if not self.tabs[name] then return end
    
    -- Hide all tabs
    for tabName, tab in pairs(self.tabs) do
        tab.content.Visible = false
        createTween(tab.button, {BackgroundColor3 = CONFIG.Colors.Dark}, 0.15):Play()
    end
    
    -- Show selected tab
    self.tabs[name].content.Visible = true
    createTween(self.tabs[name].button, {BackgroundColor3 = CONFIG.Colors.Primary}, 0.15):Play()
    self.currentTab = name
    
    self:UpdateStatus("📂 Switched to " .. name .. " tab")
end

function UILibrary:GetCurrentTab()
    if self.currentTab and self.tabs[self.currentTab] then
        return self.tabs[self.currentTab].content
    end
    return self.contentFrame
end

-- Enhanced Component Methods
function UILibrary:AddButton(text, callback, buttonType, icon, tab)
    local parent = tab and self.tabs[tab] and self.tabs[tab].content or self:GetCurrentTab()
    buttonType = buttonType or "default"
    
    local button = Instance.new("TextButton")
    button.Size = UDim2.new(1, -20, 0, 45)
    button.BackgroundColor3 = self:GetButtonColor(buttonType)
    button.BorderSizePixel = 0
    button.Text = (icon or "") .. " " .. text
    button.TextColor3 = CONFIG.Colors.Light
    button.TextSize = 16
    button.Font = CONFIG.Fonts.SemiBold
    button.ZIndex = 3
    button.Parent = parent
    
    createCorner(button, 8)
    createStroke(button, 1, self:GetButtonColor(buttonType), 0.5)
    
    -- Enhanced hover effects with sound
    button.MouseEnter:Connect(function()
        createTween(button, {
            BackgroundColor3 = self:GetButtonColor(buttonType, true),
            Size = UDim2.new(1, -18, 0, 47)
        }, 0.15):Play()
        playSound("hover.mp3", 0.1)
    end)
    
    button.MouseLeave:Connect(function()
        createTween(button, {
            BackgroundColor3 = self:GetButtonColor(buttonType),
            Size = UDim2.new(1, -20, 0, 45)
        }, 0.15):Play()
    end)
    
    -- Click animation with sound
    button.MouseButton1Down:Connect(function()
        createTween(button, {Size = UDim2.new(1, -22, 0, 43)}, 0.1):Play()
        playSound("button_click.mp3", 0.3)
    end)
    
    button.MouseButton1Up:Connect(function()
        createTween(button, {Size = UDim2.new(1, -18, 0, 47)}, 0.1):Play()
    end)
    
    if callback then
        button.MouseButton1Click:Connect(function()
            local success, err = pcall(callback)
            if not success then
                self:ShowNotification("❌ Error: " .. tostring(err), "error")
            end
        end)
    end
    
    table.insert(self.components, button)
    return button
end

function UILibrary:GetButtonColor(buttonType, hover)
    local colors = {
        default = CONFIG.Colors.Primary,
        success = CONFIG.Colors.Success,
        warning = CONFIG.Colors.Warning,
        danger = CONFIG.Colors.Danger,
        secondary = CONFIG.Colors.Secondary,
        info = CONFIG.Colors.Info,
        accent = CONFIG.Colors.Accent
    }
    
    local color = colors[buttonType] or colors.default
    
    if hover then
        return Color3.new(
            math.min(color.R + 0.15, 1),
            math.min(color.G + 0.15, 1),
            math.min(color.B + 0.15, 1)
        )
    end
    
    return color
end

function UILibrary:AddToggleButton(text, defaultState, callback, icon, tab)
    local parent = tab and self.tabs[tab] and self.tabs[tab].content or self:GetCurrentTab()
    local state = defaultState or false
    
    local button = Instance.new("TextButton")
    button.Size = UDim2.new(1, -20, 0, 45)
    button.BackgroundColor3 = state and CONFIG.Colors.Success or CONFIG.Colors.Danger
    button.BorderSizePixel = 0
    button.Text = (icon or "🔘") .. " " .. text .. ": " .. (state and "ON" or "OFF")
    button.TextColor3 = CONFIG.Colors.Light
    button.TextSize = 16
    button.Font = CONFIG.Fonts.SemiBold
    button.ZIndex = 3
    button.Parent = parent
    
    createCorner(button, 8)
    createStroke(button, 1, state and CONFIG.Colors.Success or CONFIG.Colors.Danger, 0.5)
    
    -- Toggle indicator
    local indicator = Instance.new("Frame")
    indicator.Size = UDim2.new(0, 20, 0, 20)
    indicator.Position = UDim2.new(1, -30, 0.5, -10)
    indicator.BackgroundColor3 = CONFIG.Colors.Light
    indicator.BorderSizePixel = 0
    indicator.ZIndex = 4
    indicator.Parent = button
    
    createCorner(indicator, 10)
    
    local function updateToggle()
        button.Text = (icon or "🔘") .. " " .. text .. ": " .. (state and "ON" or "OFF")
        button.BackgroundColor3 = state and CONFIG.Colors.Success or CONFIG.Colors.Danger
        createStroke(button, 1, state and CONFIG.Colors.Success or CONFIG.Colors.Danger, 0.5)
        
        createTween(indicator, {
            BackgroundColor3 = state and CONFIG.Colors.Success or CONFIG.Colors.Danger
        }, 0.2):Play()
    end
    
    button.MouseButton1Click:Connect(function()
        state = not state
        updateToggle()
        playSound("toggle.mp3", 0.4)
        
        if callback then
            local success, err = pcall(callback, state)
            if not success then
                self:ShowNotification("❌ Error: " .. tostring(err), "error")
            end
        end
        
        self:ShowNotification((icon or "🔘") .. " " .. text .. " " .. (state and "enabled" or "disabled"), state and "success" or "info")
    end)
    
    -- Hover effects
    button.MouseEnter:Connect(function()
        createTween(button, {Size = UDim2.new(1, -18, 0, 47)}, 0.15):Play()
    end)
    
    button.MouseLeave:Connect(function()
        createTween(button, {Size = UDim2.new(1, -20, 0, 45)}, 0.15):Play()
    end)
    
    updateToggle()
    table.insert(self.components, button)
    return button
end

function UILibrary:AddSlider(text, min, max, default, callback, tab)
    local parent = tab and self.tabs[tab] and self.tabs[tab].content or self:GetCurrentTab()
    
    local sliderFrame = Instance.new("Frame")
    sliderFrame.Size = UDim2.new(1, -20, 0, 80)
    sliderFrame.BackgroundColor3 = CONFIG.Colors.Surface
    sliderFrame.BorderSizePixel = 0
    sliderFrame.ZIndex = 2
    sliderFrame.Parent = parent
    
    createCorner(sliderFrame, 10)
    createStroke(sliderFrame, 1, CONFIG.Colors.Primary, 0.3)
    
    local label = Instance.new("TextLabel")
    label.Size = UDim2.new(1, -20, 0, 30)
    label.Position = UDim2.new(0, 10, 0, 5)
    label.BackgroundTransparency = 1
    label.Text = text .. ": " .. default
    label.TextColor3 = CONFIG.Colors.Light
    label.TextSize = 16
    label.Font = CONFIG.Fonts.SemiBold
    label.TextXAlignment = Enum.TextXAlignment.Left
    label.ZIndex = 3
    label.Parent = sliderFrame
    
    local valueLabel = Instance.new("TextLabel")
    valueLabel.Size = UDim2.new(0, 60, 0, 30)
    valueLabel.Position = UDim2.new(1, -70, 0, 5)
    valueLabel.BackgroundTransparency = 1
    valueLabel.Text = tostring(default)
    valueLabel.TextColor3 = CONFIG.Colors.Primary
    valueLabel.TextSize = 16
    valueLabel.Font = CONFIG.Fonts.Bold
    valueLabel.TextXAlignment = Enum.TextXAlignment.Right
    valueLabel.ZIndex = 3
    valueLabel.Parent = sliderFrame
    
    local sliderBG = Instance.new("Frame")
    sliderBG.Size = UDim2.new(1, -40, 0, 10)
    sliderBG.Position = UDim2.new(0, 20, 0, 45)
    sliderBG.BackgroundColor3 = CONFIG.Colors.Dark
    sliderBG.BorderSizePixel = 0
    sliderBG.ZIndex = 3
    sliderBG.Parent = sliderFrame
    
    createCorner(sliderBG, 5)
    
    local sliderFill = Instance.new("Frame")
    sliderFill.Size = UDim2.new((default - min) / (max - min), 0, 1, 0)
    sliderFill.Position = UDim2.new(0, 0, 0, 0)
    sliderFill.BackgroundColor3 = CONFIG.Colors.Primary
    sliderFill.BorderSizePixel = 0
    sliderFill.ZIndex = 4
    sliderFill.Parent = sliderBG
    
    createCorner(sliderFill, 5)
    createGradient(sliderFill, {CONFIG.Colors.Primary, CONFIG.Colors.Secondary}, 90)
    
    local sliderButton = Instance.new("TextButton")
    sliderButton.Size = UDim2.new(0, 26, 0, 26)
    sliderButton.Position = UDim2.new((default - min) / (max - min), -13, 0, -8)
    sliderButton.BackgroundColor3 = CONFIG.Colors.Light
    sliderButton.BorderSizePixel = 0
    sliderButton.Text = ""
    sliderButton.ZIndex = 5
    sliderButton.Parent = sliderBG
    
    createCorner(sliderButton, 13)
    createStroke(sliderButton, 3, CONFIG.Colors.Primary)
    
    local dragging = false
    local value = default
    
    local function updateSlider(percentage)
        percentage = math.clamp(percentage, 0, 1)
        value = min + (max - min) * percentage
        value = math.floor(value * 100) / 100
        
        sliderButton.Position = UDim2.new(percentage, -13, 0, -8)
        sliderFill.Size = UDim2.new(percentage, 0, 1, 0)
        label.Text = text .. ": " .. value
        valueLabel.Text = tostring(value)
        
        if callback then
            local success, err = pcall(callback, value)
            if not success then
                self:ShowNotification("❌ Error: " .. tostring(err), "error")
            end
        end
    end
    
    sliderButton.MouseButton1Down:Connect(function()
        dragging = true
        playSound("slider_grab.mp3", 0.3)
    end)
    
    UserInputService.InputEnded:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1 then
            if dragging then
                playSound("slider_release.mp3", 0.3)
            end
            dragging = false
        end
    end)
    
    UserInputService.InputChanged:Connect(function(input)
        if dragging and input.UserInputType == Enum.UserInputType.MouseMovement then
            local mouse = Players.LocalPlayer:GetMouse()
            local relativeX = mouse.X - sliderBG.AbsolutePosition.X
            local percentage = relativeX / sliderBG.AbsoluteSize.X
            updateSlider(percentage)
        end
    end)
    
    -- Hover effects
    sliderButton.MouseEnter:Connect(function()
        createTween(sliderButton, {Size = UDim2.new(0, 28, 0, 28)}, 0.15):Play()
    end)
    
    sliderButton.MouseLeave:Connect(function()
        if not dragging then
            createTween(sliderButton, {Size = UDim2.new(0, 26, 0, 26)}, 0.15):Play()
        end
    end)
    
    table.insert(self.components, sliderFrame)
    return sliderFrame
end

function UILibrary:AddDropdown(text, options, defaultOption, callback, tab)
    local parent = tab and self.tabs[tab] and self.tabs[tab].content or self:GetCurrentTab()
    local isOpen = false
    local selectedOption = defaultOption or options[1] or "None"
    
    local dropdownFrame = Instance.new("Frame")
    dropdownFrame.Size = UDim2.new(1, -20, 0, 45)
    dropdownFrame.BackgroundColor3 = CONFIG.Colors.Surface
    dropdownFrame.BorderSizePixel = 0
    dropdownFrame.ZIndex = 2
    dropdownFrame.Parent = parent
    
    createCorner(dropdownFrame, 8)
    createStroke(dropdownFrame, 1, CONFIG.Colors.Primary, 0.3)
    
    local dropdownButton = Instance.new("TextButton")
    dropdownButton.Size = UDim2.new(1, -10, 1, 0)
    dropdownButton.Position = UDim2.new(0, 5, 0, 0)
    dropdownButton.BackgroundTransparency = 1
    dropdownButton.Text = "📋 " .. text .. ": " .. selectedOption .. " ▼"
    dropdownButton.TextColor3 = CONFIG.Colors.Light
    dropdownButton.TextSize = 16
    dropdownButton.Font = CONFIG.Fonts.SemiBold
    dropdownButton.TextXAlignment = Enum.TextXAlignment.Left
    dropdownButton.ZIndex = 3
    dropdownButton.Parent = dropdownFrame
    
    local optionsFrame = Instance.new("Frame")
    optionsFrame.Size = UDim2.new(1, 0, 0, math.min(#options * 40, 200))
    optionsFrame.Position = UDim2.new(0, 0, 1, 5)
    optionsFrame.BackgroundColor3 = CONFIG.Colors.Surface
    optionsFrame.BorderSizePixel = 0
    optionsFrame.ZIndex = 10
    optionsFrame.Visible = false
    optionsFrame.Parent = dropdownFrame
    
    createCorner(optionsFrame, 8)
    createStroke(optionsFrame, 1, CONFIG.Colors.Primary, 0.3)
    createShadow(optionsFrame, 0.6)
    
    local optionsScroll = Instance.new("ScrollingFrame")
    optionsScroll.Size = UDim2.new(1, 0, 1, 0)
    optionsScroll.BackgroundTransparency = 1
    optionsScroll.ScrollBarThickness = 6
    optionsScroll.ScrollBarImageColor3 = CONFIG.Colors.Primary
    optionsScroll.CanvasSize = UDim2.new(0, 0, 0, #options * 40)
    optionsScroll.ZIndex = 11
    optionsScroll.Parent = optionsFrame
    
    local optionsLayout = Instance.new("UIListLayout")
    optionsLayout.SortOrder = Enum.SortOrder.LayoutOrder
    optionsLayout.Parent = optionsScroll
    
    for i, option in ipairs(options) do
        local optionButton = Instance.new("TextButton")
        optionButton.Size = UDim2.new(1, 0, 0, 40)
        optionButton.BackgroundColor3 = CONFIG.Colors.Surface
        optionButton.BorderSizePixel = 0
        optionButton.Text = "  " .. option
        optionButton.TextColor3 = CONFIG.Colors.Light
        optionButton.TextSize = 14
        optionButton.Font = CONFIG.Fonts.Regular
        optionButton.TextXAlignment = Enum.TextXAlignment.Left
        optionButton.ZIndex = 12
        optionButton.Parent = optionsScroll
        
        optionButton.MouseEnter:Connect(function()
            createTween(optionButton, {BackgroundColor3 = CONFIG.Colors.Primary}, 0.15):Play()
        end)
        
        optionButton.MouseLeave:Connect(function()
            createTween(optionButton, {BackgroundColor3 = CONFIG.Colors.Surface}, 0.15):Play()
        end)
        
        optionButton.MouseButton1Click:Connect(function()
            selectedOption = option
            dropdownButton.Text = "📋 " .. text .. ": " .. selectedOption .. " ▼"
            optionsFrame.Visible = false
            isOpen = false
            playSound("dropdown_select.mp3", 0.4)
            
            if callback then
                local success, err = pcall(callback, selectedOption)
                if not success then
                    self:ShowNotification("❌ Error: " .. tostring(err), "error")
                end
            end
        end)
    end
    
    dropdownButton.MouseButton1Click:Connect(function()
        isOpen = not isOpen
        optionsFrame.Visible = isOpen
        dropdownButton.Text = "📋 " .. text .. ": " .. selectedOption .. (isOpen and " ▲" or " ▼")
        playSound("dropdown_open.mp3", 0.3)
    end)
    
    -- Close dropdown when clicking elsewhere
    UserInputService.InputBegan:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1 and isOpen then
            local mouse = Players.LocalPlayer:GetMouse()
            local mousePos = Vector2.new(mouse.X, mouse.Y)
            local framePos = optionsFrame.AbsolutePosition
            local frameSize = optionsFrame.AbsoluteSize
            
            if mousePos.X < framePos.X or mousePos.X > framePos.X + frameSize.X or
               mousePos.Y < framePos.Y or mousePos.Y > framePos.Y + frameSize.Y then
                optionsFrame.Visible = false
                isOpen = false
                dropdownButton.Text = "📋 " .. text .. ": " .. selectedOption .. " ▼"
            end
        end
    end)
    
    table.insert(self.components, dropdownFrame)
    return dropdownFrame
end

function UILibrary:AddTextBox(placeholder, callback, multiline, tab)
    local parent = tab and self.tabs[tab] and self.tabs[tab].content or self:GetCurrentTab()
    
    local textBox = Instance.new("TextBox")
    textBox.Size = UDim2.new(1, -20, 0, multiline and 80 or 45)
    textBox.BackgroundColor3 = CONFIG.Colors.Surface
    textBox.BorderSizePixel = 0
    textBox.Text = ""
    textBox.PlaceholderText = placeholder
    textBox.PlaceholderColor3 = CONFIG.Colors.TextSecondary
    textBox.TextColor3 = CONFIG.Colors.Light
    textBox.TextSize = 16
    textBox.Font = CONFIG.Fonts.Regular
    textBox.TextXAlignment = Enum.TextXAlignment.Left
    textBox.TextYAlignment = multiline and Enum.TextYAlignment.Top or Enum.TextYAlignment.Center
    textBox.TextWrapped = multiline or false
    textBox.MultiLine = multiline or false
    textBox.ClearTextOnFocus = false
    textBox.ZIndex = 3
    textBox.Parent = parent
    
    createCorner(textBox, 8)
    createStroke(textBox, 1, CONFIG.Colors.Primary, 0.3)
    
    -- Add padding
    local padding = Instance.new("UIPadding")
    padding.PaddingLeft = UDim.new(0, 10)
    padding.PaddingRight = UDim.new(0, 10)
    padding.PaddingTop = UDim.new(0, multiline and 10 or 0)
    padding.PaddingBottom = UDim.new(0, multiline and 10 or 0)
    padding.Parent = textBox
    
    textBox.Focused:Connect(function()
        createStroke(textBox, 2, CONFIG.Colors.Primary, 0)
        createTween(textBox, {BackgroundColor3 = Color3.new(
            CONFIG.Colors.Surface.R + 0.05,
            CONFIG.Colors.Surface.G + 0.05,
            CONFIG.Colors.Surface.B + 0.05
        )}, 0.15):Play()
        playSound("textbox_focus.mp3", 0.2)
    end)
    
    textBox.FocusLost:Connect(function(enterPressed)
        createStroke(textBox, 1, CONFIG.Colors.Primary, 0.3)
        createTween(textBox, {BackgroundColor3 = CONFIG.Colors.Surface}, 0.15):Play()
        
        if enterPressed and callback then
            local success, err = pcall(callback, textBox.Text)
            if not success then
                self:ShowNotification("❌ Error: " .. tostring(err), "error")
            else
                playSound("textbox_submit.mp3", 0.4)
            end
        end
    end)
    
    table.insert(self.components, textBox)
    return textBox
end

function UILibrary:AddLabel(text, textSize, tab)
    local parent = tab and self.tabs[tab] and self.tabs[tab].content or self:GetCurrentTab()
    
    local label = Instance.new("TextLabel")
    label.Size = UDim2.new(1, -20, 0, textSize or 35)
    label.BackgroundTransparency = 1
    label.Text = text
    label.TextColor3 = CONFIG.Colors.Light
    label.TextSize = math.min(textSize or 16, 24)
    label.Font = (textSize and textSize > 20) and CONFIG.Fonts.Bold or CONFIG.Fonts.Regular
    label.TextXAlignment = Enum.TextXAlignment.Left
    label.TextWrapped = true
    label.ZIndex = 3
    label.Parent = parent
    
    -- Add padding
    local padding = Instance.new("UIPadding")
    padding.PaddingLeft = UDim.new(0, 10)
    padding.PaddingRight = UDim.new(0, 10)
    padding.Parent = label
    
    table.insert(self.components, label)
    return label
end

function UILibrary:AddSeparator(tab)
    local parent = tab and self.tabs[tab] and self.tabs[tab].content or self:GetCurrentTab()
    
    local separator = Instance.new("Frame")
    separator.Size = UDim2.new(1, -40, 0, 2)
    separator.BackgroundColor3 = CONFIG.Colors.Primary
    separator.BorderSizePixel = 0
    separator.ZIndex = 3
    separator.Parent = parent
    
    createCorner(separator, 1)
    createGradient(separator, {CONFIG.Colors.Primary, CONFIG.Colors.Secondary}, 90)
    
    table.insert(self.components, separator)
    return separator
end

function UILibrary:AddColorPicker(text, defaultColor, callback, tab)
    local parent = tab and self.tabs[tab] and self.tabs[tab].content or self:GetCurrentTab()
    local currentColor = defaultColor or CONFIG.Colors.Primary
    
    local colorFrame = Instance.new("Frame")
    colorFrame.Size = UDim2.new(1, -20, 0, 50)
    colorFrame.BackgroundColor3 = CONFIG.Colors.Surface
    colorFrame.BorderSizePixel = 0
    colorFrame.ZIndex = 2
    colorFrame.Parent = parent
    
    createCorner(colorFrame, 8)
    createStroke(colorFrame, 1, CONFIG.Colors.Primary, 0.3)
    
    local colorLabel = Instance.new("TextLabel")
    colorLabel.Size = UDim2.new(1, -70, 1, 0)
    colorLabel.Position = UDim2.new(0, 15, 0, 0)
    colorLabel.BackgroundTransparency = 1
    colorLabel.Text = "🎨 " .. text
    colorLabel.TextColor3 = CONFIG.Colors.Light
    colorLabel.TextSize = 16
    colorLabel.Font = CONFIG.Fonts.SemiBold
    colorLabel.TextXAlignment = Enum.TextXAlignment.Left
    colorLabel.ZIndex = 3
    colorLabel.Parent = colorFrame
    
    local colorPreview = Instance.new("Frame")
    colorPreview.Size = UDim2.new(0, 40, 0, 40)
    colorPreview.Position = UDim2.new(1, -50, 0, 5)
    colorPreview.BackgroundColor3 = currentColor
    colorPreview.BorderSizePixel = 0
    colorPreview.ZIndex = 3
    colorPreview.Parent = colorFrame
    
    createCorner(colorPreview, 8)
    createStroke(colorPreview, 2, CONFIG.Colors.Light)
    
    local colorButton = Instance.new("TextButton")
    colorButton.Size = UDim2.new(1, 0, 1, 0)
    colorButton.BackgroundTransparency = 1
    colorButton.Text = ""
    colorButton.ZIndex = 4
    colorButton.Parent = colorPreview
    
    colorButton.MouseButton1Click:Connect(function()
        local colors = {
            CONFIG.Colors.Primary, CONFIG.Colors.Success, CONFIG.Colors.Warning,
            CONFIG.Colors.Danger, CONFIG.Colors.Info, CONFIG.Colors.Accent,
            Color3.fromRGB(255, 255, 255), Color3.fromRGB(0, 0, 0),
            Color3.fromRGB(255, 0, 0), Color3.fromRGB(0, 255, 0),
            Color3.fromRGB(0, 0, 255), Color3.fromRGB(255, 255, 0),
            Color3.fromRGB(255, 0, 255), Color3.fromRGB(0, 255, 255)
        }
        
        local currentIndex = 1
        for i, color in ipairs(colors) do
            if color == currentColor then
                currentIndex = i
                break
            end
        end
        
        currentIndex = currentIndex % #colors + 1
        currentColor = colors[currentIndex]
        
        createTween(colorPreview, {BackgroundColor3 = currentColor}, 0.2):Play()
        playSound("color_change.mp3", 0.3)
        
        if callback then
            local success, err = pcall(callback, currentColor)
            if not success then
                self:ShowNotification("❌ Error: " .. tostring(err), "error")
            end
        end
    end)
    
    -- Hover effects
    colorButton.MouseEnter:Connect(function()
        createTween(colorPreview, {Size = UDim2.new(0, 42, 0, 42)}, 0.15):Play()
    end)
    
    colorButton.MouseLeave:Connect(function()
        createTween(colorPreview, {Size = UDim2.new(0, 40, 0, 40)}, 0.15):Play()
    end)
    
    table.insert(self.components, colorFrame)
    return colorFrame
end

-- Enhanced Notification System
function UILibrary:ShowNotification(message, type, duration)
    type = type or "info"
    duration = duration or 3
    
    local colors = {
        info = CONFIG.Colors.Info,
        success = CONFIG.Colors.Success,
        warning = CONFIG.Colors.Warning,
        error = CONFIG.Colors.Danger
    }
    
    local icons = {
        info = "ℹ️",
        success = "✅",
        warning = "⚠️",
        error = "❌"
    }
    
    local notification = Instance.new("Frame")
    notification.Size = UDim2.new(0, 400, 0, 80)
    notification.Position = UDim2.new(1, -420, 0, 20 + (#self.notifications * 90))
    notification.BackgroundColor3 = colors[type] or colors.info
    notification.BorderSizePixel = 0
    notification.ZIndex = 100
    notification.Parent = self.screenGui
    
    createCorner(notification, 12)
    createShadow(notification, 0.6)
    
    local notifIcon = Instance.new("TextLabel")
    notifIcon.Size = UDim2.new(0, 40, 0, 40)
    notifIcon.Position = UDim2.new(0, 15, 0, 15)
    notifIcon.BackgroundTransparency = 1
    notifIcon.Text = icons[type] or icons.info
    notifIcon.TextSize = 24
    notifIcon.ZIndex = 101
    notifIcon.Parent = notification
    
    local notifText = Instance.new("TextLabel")
    notifText.Size = UDim2.new(1, -100, 1, -20)
    notifText.Position = UDim2.new(0, 65, 0, 10)
    notifText.BackgroundTransparency = 1
    notifText.Text = message
    notifText.TextColor3 = CONFIG.Colors.Light
    notifText.TextSize = 14
    notifText.Font = CONFIG.Fonts.SemiBold
    notifText.TextWrapped = true
    notifText.TextXAlignment = Enum.TextXAlignment.Left
    notifText.TextYAlignment = Enum.TextYAlignment.Top
    notifText.ZIndex = 101
    notifText.Parent = notification
    
    local closeBtn = Instance.new("TextButton")
    closeBtn.Size = UDim2.new(0, 25, 0, 25)
    closeBtn.Position = UDim2.new(1, -35, 0, 10)
    closeBtn.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
    closeBtn.BackgroundTransparency = 0.8
    closeBtn.Text = "×"
    closeBtn.TextColor3 = CONFIG.Colors.Light
    closeBtn.TextSize = 16
    closeBtn.Font = CONFIG.Fonts.Bold
    closeBtn.ZIndex = 101
    closeBtn.Parent = notification
    
    createCorner(closeBtn, 12)
    
    table.insert(self.notifications, notification)
    
    -- Slide in animation
    createTween(notification, {
        Position = UDim2.new(1, -420, 0, 20 + ((#self.notifications - 1) * 90))
    }, 0.5, Enum.EasingStyle.Back):Play()
    
    playSound("notification.mp3", 0.4)
    
    local function removeNotification()
        for i, notif in ipairs(self.notifications) do
            if notif == notification then
                table.remove(self.notifications, i)
                break
            end
        end
        
        -- Slide out and destroy
        createTween(notification, {
            Position = UDim2.new(1, 50, 0, notification.Position.Y.Offset)
        }, 0.3):Play()
        
        spawn(function()
            wait(0.3)
            if notification.Parent then
                notification:Destroy()
            end
        end)
        
        -- Reposition remaining notifications
        for i, notif in ipairs(self.notifications) do
            createTween(notif, {
                Position = UDim2.new(1, -420, 0, 20 + ((i - 1) * 90))
            }, 0.3):Play()
        end
    end
    
    closeBtn.MouseButton1Click:Connect(removeNotification)
    
    -- Auto-remove after duration
    spawn(function()
        wait(duration)
        if notification.Parent then
            removeNotification()
        end
    end)
end

function UILibrary:UpdateStatus(text)
    if self.statusLabel then
        self.statusLabel.Text = text
    end
end

-- Theme System
function UILibrary:SetTheme(themeName)
    if not CONFIG.Themes[themeName] then return end
    
    local theme = CONFIG.Themes[themeName]
    self.currentTheme = themeName
    
    -- Update colors
    CONFIG.Colors.Background = theme.Background
    CONFIG.Colors.Surface = theme.Surface
    CONFIG.Colors.Text = theme.Text
    
    -- Update UI elements
    if self.mainFrame then
        createTween(self.mainFrame, {BackgroundColor3 = theme.Background}, 0.3):Play()
    end
    
    if self.contentFrame then
        createTween(self.contentFrame, {BackgroundColor3 = theme.Surface}, 0.3):Play()
    end
    
    if self.tabFrame then
        createTween(self.tabFrame, {BackgroundColor3 = theme.Surface}, 0.3):Play()
    end
    
    -- Update all components
    for _, component in ipairs(self.components) do
        if component:IsA("Frame") and component.Name ~= "Shadow" then
            createTween(component, {BackgroundColor3 = theme.Surface}, 0.3):Play()
        elseif component:IsA("TextLabel") then
            createTween(component, {TextColor3 = theme.Text}, 0.3):Play()
        elseif component:IsA("TextBox") then
            createTween(component, {
                BackgroundColor3 = theme.Surface,
                TextColor3 = theme.Text
            }, 0.3):Play()
        end
    end
    
    self:ShowNotification("🎨 Theme changed to " .. themeName .. "!", "success")
    saveSettings(self)
end

-- Keybind System
function UILibrary:AddKeybind(key, callback, description)
    local keybind = {
        key = key,
        callback = callback,
        description = description or "No description"
    }
    
    table.insert(self.keybinds, keybind)
    
    UserInputService.InputBegan:Connect(function(input, gameProcessed)
        if gameProcessed then return end
        
        if input.KeyCode == key then
            local success, err = pcall(callback)
            if not success then
                self:ShowNotification("❌ Keybind Error: " .. tostring(err), "error")
            else
                playSound("keybind_activate.mp3", 0.3)
            end
        end
    end)
    
    return keybind
end

-- Window Controls
function UILibrary:ToggleMinimize()
    self.minimized = not self.minimized
    
    if self.minimized then
        createTween(self.mainFrame, {Size = UDim2.new(0, 650, 0, 50)}, 0.3):Play()
        self.tabFrame.Visible = false
        self.contentFrame.Visible = false
        self.statusBar.Visible = false
        self.minimizeBtn.Text = "+"
        self:UpdateStatus("📦 Minimized")
    else
        createTween(self.mainFrame, {Size = UDim2.new(0, 650, 0, 500)}, 0.3):Play()
        self.tabFrame.Visible = true
        self.contentFrame.Visible = true
        self.statusBar.Visible = true
        self.minimizeBtn.Text = "−"
        self:UpdateStatus("📂 Restored")
    end
    
    saveSettings(self)
end

function UILibrary:ToggleMaximize()
    self.maximized = not self.maximized
    
    if self.maximized then
        local screenSize = workspace.CurrentCamera.ViewportSize
        createTween(self.mainFrame, {
            Size = UDim2.new(0, screenSize.X - 100, 0, screenSize.Y - 100),
            Position = UDim2.new(0, 50, 0, 50)
        }, 0.3):Play()
        self.maximizeBtn.Text = "❐"
        self:UpdateStatus("🔳 Maximized")
    else
        createTween(self.mainFrame, {
            Size = UDim2.new(0, 650, 0, 500),
            Position = UDim2.new(0.5, -325, 0.5, -250)
        }, 0.3):Play()
        self.maximizeBtn.Text = "□"
        self:UpdateStatus("🔲 Restored")
    end
    
    saveSettings(self)
end

function UILibrary:Close()
    self:UpdateStatus("👋 Closing...")
    
    -- Save settings before closing
    saveSettings(self)
    
    -- Close animation
    createTween(self.mainFrame, {
        Size = UDim2.new(0, 0, 0, 0),
        Position = UDim2.new(0.5, 0, 0.5, 0),
        BackgroundTransparency = 1
    }, 0.5, Enum.EasingStyle.Back, Enum.EasingDirection.In):Play()
    
    playSound("window_close.mp3", 0.5)
    
    spawn(function()
        wait(0.5)
        self.screenGui:Destroy()
    end)
end

function UILibrary:Show()
    self.screenGui.Enabled = true
    self:ShowNotification("👁️ UI Library shown", "info")
end

function UILibrary:Hide()
    self.screenGui.Enabled = false
end

function UILibrary:Destroy()
    self:Close()
end

-- Utility Methods
function UILibrary:GetComponentCount()
    return #self.components
end

function UILibrary:GetTabCount()
    local count = 0
    for _ in pairs(self.tabs) do
        count = count + 1
    end
    return count
end

function UILibrary:ClearTab(tabName)
    if not self.tabs[tabName] then return end
    
    for _, child in ipairs(self.tabs[tabName].content:GetChildren()) do
        if child:IsA("GuiObject") and child ~= self.tabs[tabName].layout then
            child:Destroy()
        end
    end
    
    self:ShowNotification("🧹 Tab '" .. tabName .. "' cleared!", "info")
end

function UILibrary:RemoveTab(tabName)
    if not self.tabs[tabName] or tabName == "Home" then return end
    
    self.tabs[tabName].button:Destroy()
    self.tabs[tabName].content:Destroy()
    self.tabs[tabName] = nil
    
    -- Switch to Home tab if current tab was removed
    if self.currentTab == tabName then
        self:SwitchTab("Home")
    end
    
    self:ShowNotification("🗑️ Tab '" .. tabName .. "' removed!", "info")
end

return UILibrary
