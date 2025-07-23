-- Advanced Roblox UI Library v2.0 - Fixed Version
-- All visibility issues resolved + Enhanced features

local UILibrary = {}
UILibrary.__index = UILibrary

-- Services
local TweenService = game:GetService("TweenService")
local UserInputService = game:GetService("UserInputService")
local HttpService = game:GetService("HttpService")
local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local CoreGui = game:GetService("CoreGui")
local StarterGui = game:GetService("StarterGui")

-- Configuration
local CONFIG = {
    KeyAPI = "https://your-domain.com/api/verify", -- Replace with your deployed website
    AnimationSpeed = 0.25,
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
        Accent = Color3.fromRGB(255, 107, 107)
    },
    Fonts = {
        Bold = Enum.Font.GothamBold,
        SemiBold = Enum.Font.GothamSemibold,
        Regular = Enum.Font.Gotham,
        Light = Enum.Font.GothamLight
    }
}

-- Utility Functions
local function createTween(object, properties, duration, style, direction)
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

local function createShadow(parent)
    local shadow = Instance.new("Frame")
    shadow.Name = "Shadow"
    shadow.Size = UDim2.new(1, 6, 1, 6)
    shadow.Position = UDim2.new(0, -3, 0, -3)
    shadow.BackgroundColor3 = Color3.fromRGB(0, 0, 0)
    shadow.BackgroundTransparency = 0.8
    shadow.BorderSizePixel = 0
    shadow.ZIndex = parent.ZIndex - 1
    shadow.Parent = parent.Parent
    
    createCorner(shadow, 12)
    return shadow
end

-- Key System with Enhanced Security
function UILibrary:VerifyKey(key)
    local success, result = pcall(function()
        local response = HttpService:RequestAsync({
            Url = CONFIG.KeyAPI,
            Method = "POST",
            Headers = {
                ["Content-Type"] = "application/json",
                ["User-Agent"] = "RobloxUILibrary/2.0"
            },
            Body = HttpService:JSONEncode({
                key = key,
                userId = Players.LocalPlayer.UserId,
                username = Players.LocalPlayer.Name,
                timestamp = os.time(),
                hwid = game:GetService("RbxAnalyticsService"):GetClientId()
            })
        })
        
        if response.StatusCode == 200 then
            local data = HttpService:JSONDecode(response.Body)
            return data.valid == true, data.message or "Key verified"
        end
        return false, "Invalid response from server"
    end)
    
    if success then
        return result
    else
        return false, "Connection failed"
    end
end

-- Main Library Constructor
function UILibrary.new(title, keyRequired, theme)
    local self = setmetatable({}, UILibrary)
    
    self.title = title or "Advanced UI Library"
    self.keyRequired = keyRequired or false
    self.authenticated = not keyRequired
    self.minimized = false
    self.components = {}
    self.theme = theme or "dark"
    self.notifications = {}
    self.tabs = {}
    self.currentTab = nil
    
    -- Apply theme
    if self.theme == "light" then
        CONFIG.Colors.Background = Color3.fromRGB(240, 242, 247)
        CONFIG.Colors.Surface = Color3.fromRGB(255, 255, 255)
        CONFIG.Colors.Dark = Color3.fromRGB(255, 255, 255)
        CONFIG.Colors.Light = Color3.fromRGB(32, 34, 37)
    end
    
    self:CreateMainGUI()
    
    if keyRequired then
        self:ShowKeyPrompt()
    else
        self:InitializeComponents()
    end
    
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
    self.screenGui.Parent = parent
    
    -- Main Frame
    self.mainFrame = Instance.new("Frame")
    self.mainFrame.Name = "MainFrame"
    self.mainFrame.Size = UDim2.new(0, 600, 0, 450)
    self.mainFrame.Position = UDim2.new(0.5, -300, 0.5, -225)
    self.mainFrame.BackgroundColor3 = CONFIG.Colors.Background
    self.mainFrame.BorderSizePixel = 0
    self.mainFrame.Active = true
    self.mainFrame.ZIndex = 1
    self.mainFrame.Parent = self.screenGui
    
    createCorner(self.mainFrame, 15)
    createShadow(self.mainFrame)
    
    -- Make draggable
    self:MakeDraggable(self.mainFrame)
    
    -- Title Bar
    self.titleBar = Instance.new("Frame")
    self.titleBar.Name = "TitleBar"
    self.titleBar.Size = UDim2.new(1, 0, 0, 45)
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
    
    -- Title Label
    self.titleLabel = Instance.new("TextLabel")
    self.titleLabel.Name = "TitleLabel"
    self.titleLabel.Size = UDim2.new(1, -120, 1, 0)
    self.titleLabel.Position = UDim2.new(0, 15, 0, 0)
    self.titleLabel.BackgroundTransparency = 1
    self.titleLabel.Text = self.title
    self.titleLabel.TextColor3 = CONFIG.Colors.Light
    self.titleLabel.TextSize = 18
    self.titleLabel.Font = CONFIG.Fonts.Bold
    self.titleLabel.TextXAlignment = Enum.TextXAlignment.Left
    self.titleLabel.ZIndex = 3
    self.titleLabel.Parent = self.titleBar
    
    -- Control Buttons
    self.minimizeBtn = self:CreateControlButton("−", UDim2.new(1, -90, 0, 8), CONFIG.Colors.Warning)
    self.minimizeBtn.MouseButton1Click:Connect(function()
        self:ToggleMinimize()
    end)
    
    self.maximizeBtn = self:CreateControlButton("□", UDim2.new(1, -60, 0, 8), CONFIG.Colors.Info)
    self.maximizeBtn.MouseButton1Click:Connect(function()
        self:ToggleMaximize()
    end)
    
    self.closeBtn = self:CreateControlButton("×", UDim2.new(1, -30, 0, 8), CONFIG.Colors.Danger)
    self.closeBtn.MouseButton1Click:Connect(function()
        self:Close()
    end)
    
    -- Tab System
    self.tabFrame = Instance.new("Frame")
    self.tabFrame.Name = "TabFrame"
    self.tabFrame.Size = UDim2.new(1, -20, 0, 35)
    self.tabFrame.Position = UDim2.new(0, 10, 0, 55)
    self.tabFrame.BackgroundColor3 = CONFIG.Colors.Surface
    self.tabFrame.BorderSizePixel = 0
    self.tabFrame.ZIndex = 2
    self.tabFrame.Parent = self.mainFrame
    
    createCorner(self.tabFrame, 8)
    
    local tabLayout = Instance.new("UIListLayout")
    tabLayout.FillDirection = Enum.FillDirection.Horizontal
    tabLayout.SortOrder = Enum.SortOrder.LayoutOrder
    tabLayout.Padding = UDim.new(0, 5)
    tabLayout.Parent = self.tabFrame
    
    -- Content Frame
    self.contentFrame = Instance.new("ScrollingFrame")
    self.contentFrame.Name = "ContentFrame"
    self.contentFrame.Size = UDim2.new(1, -20, 1, -110)
    self.contentFrame.Position = UDim2.new(0, 10, 0, 100)
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
    self.statusBar.Size = UDim2.new(1, 0, 0, 25)
    self.statusBar.Position = UDim2.new(0, 0, 1, -25)
    self.statusBar.BackgroundColor3 = CONFIG.Colors.Dark
    self.statusBar.BorderSizePixel = 0
    self.statusBar.ZIndex = 2
    self.statusBar.Parent = self.mainFrame
    
    createCorner(self.statusBar, 8)
    
    self.statusLabel = Instance.new("TextLabel")
    self.statusLabel.Size = UDim2.new(1, -10, 1, 0)
    self.statusLabel.Position = UDim2.new(0, 5, 0, 0)
    self.statusLabel.BackgroundTransparency = 1
    self.statusLabel.Text = "Ready"
    self.statusLabel.TextColor3 = CONFIG.Colors.Light
    self.statusLabel.TextSize = 12
    self.statusLabel.Font = CONFIG.Fonts.Regular
    self.statusLabel.TextXAlignment = Enum.TextXAlignment.Left
    self.statusLabel.ZIndex = 3
    self.statusLabel.Parent = self.statusBar
end

function UILibrary:CreateControlButton(text, position, color)
    local button = Instance.new("TextButton")
    button.Size = UDim2.new(0, 25, 0, 25)
    button.Position = position
    button.BackgroundColor3 = color
    button.BorderSizePixel = 0
    button.Text = text
    button.TextColor3 = CONFIG.Colors.Light
    button.TextSize = 16
    button.Font = CONFIG.Fonts.Bold
    button.ZIndex = 3
    button.Parent = self.titleBar
    
    createCorner(button, 4)
    
    -- Hover effects
    button.MouseEnter:Connect(function()
        createTween(button, {BackgroundColor3 = Color3.new(
            math.min(color.R + 0.1, 1),
            math.min(color.G + 0.1, 1),
            math.min(color.B + 0.1, 1)
        )}):Play()
    end)
    
    button.MouseLeave:Connect(function()
        createTween(button, {BackgroundColor3 = color}):Play()
    end)
    
    return button
end

function UILibrary:MakeDraggable(frame)
    local dragging = false
    local dragStart = nil
    local startPos = nil
    
    frame.InputBegan:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1 then
            dragging = true
            dragStart = input.Position
            startPos = frame.Position
        end
    end)
    
    frame.InputChanged:Connect(function(input)
        if dragging and input.UserInputType == Enum.UserInputType.MouseMovement then
            local delta = input.Position - dragStart
            frame.Position = UDim2.new(startPos.X.Scale, startPos.X.Offset + delta.X, startPos.Y.Scale, startPos.Y.Offset + delta.Y)
        end
    end)
    
    frame.InputEnded:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1 then
            dragging = false
        end
    end)
end

function UILibrary:ShowKeyPrompt()
    local keyFrame = Instance.new("Frame")
    keyFrame.Name = "KeyFrame"
    keyFrame.Size = UDim2.new(1, 0, 1, 0)
    keyFrame.Position = UDim2.new(0, 0, 0, 0)
    keyFrame.BackgroundColor3 = Color3.fromRGB(0, 0, 0)
    keyFrame.BackgroundTransparency = 0.3
    keyFrame.BorderSizePixel = 0
    keyFrame.ZIndex = 10
    keyFrame.Parent = self.screenGui
    
    local keyPrompt = Instance.new("Frame")
    keyPrompt.Size = UDim2.new(0, 400, 0, 280)
    keyPrompt.Position = UDim2.new(0.5, -200, 0.5, -140)
    keyPrompt.BackgroundColor3 = CONFIG.Colors.Background
    keyPrompt.BorderSizePixel = 0
    keyPrompt.ZIndex = 11
    keyPrompt.Parent = keyFrame
    
    createCorner(keyPrompt, 15)
    createShadow(keyPrompt)
    
    -- Key prompt header
    local keyHeader = Instance.new("Frame")
    keyHeader.Size = UDim2.new(1, 0, 0, 50)
    keyHeader.Position = UDim2.new(0, 0, 0, 0)
    keyHeader.BackgroundColor3 = CONFIG.Colors.Primary
    keyHeader.BorderSizePixel = 0
    keyHeader.ZIndex = 12
    keyHeader.Parent = keyPrompt
    
    createCorner(keyHeader, 15)
    createGradient(keyHeader, {CONFIG.Colors.Primary, CONFIG.Colors.Secondary}, 45)
    
    local keyHeaderFix = Instance.new("Frame")
    keyHeaderFix.Size = UDim2.new(1, 0, 0, 15)
    keyHeaderFix.Position = UDim2.new(0, 0, 1, -15)
    keyHeaderFix.BackgroundColor3 = CONFIG.Colors.Secondary
    keyHeaderFix.BorderSizePixel = 0
    keyHeaderFix.ZIndex = 12
    keyHeaderFix.Parent = keyHeader
    
    local keyTitle = Instance.new("TextLabel")
    keyTitle.Size = UDim2.new(1, -20, 1, 0)
    keyTitle.Position = UDim2.new(0, 10, 0, 0)
    keyTitle.BackgroundTransparency = 1
    keyTitle.Text = "🔐 Enter Access Key"
    keyTitle.TextColor3 = CONFIG.Colors.Light
    keyTitle.TextSize = 20
    keyTitle.Font = CONFIG.Fonts.Bold
    keyTitle.ZIndex = 13
    keyTitle.Parent = keyHeader
    
    local keyDesc = Instance.new("TextLabel")
    keyDesc.Size = UDim2.new(1, -40, 0, 40)
    keyDesc.Position = UDim2.new(0, 20, 0, 70)
    keyDesc.BackgroundTransparency = 1
    keyDesc.Text = "Please enter your access key to continue.\nGet your key from our website."
    keyDesc.TextColor3 = CONFIG.Colors.Light
    keyDesc.TextSize = 14
    keyDesc.Font = CONFIG.Fonts.Regular
    keyDesc.TextWrapped = true
    keyDesc.ZIndex = 12
    keyDesc.Parent = keyPrompt
    
    local keyInput = Instance.new("TextBox")
    keyInput.Size = UDim2.new(1, -40, 0, 45)
    keyInput.Position = UDim2.new(0, 20, 0, 130)
    keyInput.BackgroundColor3 = CONFIG.Colors.Surface
    keyInput.BorderSizePixel = 0
    keyInput.Text = ""
    keyInput.PlaceholderText = "Enter your key here..."
    keyInput.TextColor3 = CONFIG.Colors.Light
    keyInput.TextSize = 16
    keyInput.Font = CONFIG.Fonts.Regular
    keyInput.ZIndex = 12
    keyInput.Parent = keyPrompt
    
    createCorner(keyInput, 8)
    createStroke(keyInput, 2, CONFIG.Colors.Primary, 0.7)
    
    local submitBtn = Instance.new("TextButton")
    submitBtn.Size = UDim2.new(0, 120, 0, 40)
    submitBtn.Position = UDim2.new(0, 20, 0, 190)
    submitBtn.BackgroundColor3 = CONFIG.Colors.Success
    submitBtn.BorderSizePixel = 0
    submitBtn.Text = "✓ Verify Key"
    submitBtn.TextColor3 = CONFIG.Colors.Light
    submitBtn.TextSize = 16
    submitBtn.Font = CONFIG.Fonts.SemiBold
    submitBtn.ZIndex = 12
    submitBtn.Parent = keyPrompt
    
    createCorner(submitBtn, 8)
    
    local getKeyBtn = Instance.new("TextButton")
    getKeyBtn.Size = UDim2.new(0, 120, 0, 40)
    getKeyBtn.Position = UDim2.new(1, -140, 0, 190)
    getKeyBtn.BackgroundColor3 = CONFIG.Colors.Primary
    getKeyBtn.BorderSizePixel = 0
    getKeyBtn.Text = "🌐 Get Key"
    getKeyBtn.TextColor3 = CONFIG.Colors.Light
    getKeyBtn.TextSize = 16
    getKeyBtn.Font = CONFIG.Fonts.SemiBold
    getKeyBtn.ZIndex = 12
    getKeyBtn.Parent = keyPrompt
    
    createCorner(getKeyBtn, 8)
    
    local statusText = Instance.new("TextLabel")
    statusText.Size = UDim2.new(1, -40, 0, 25)
    statusText.Position = UDim2.new(0, 20, 0, 245)
    statusText.BackgroundTransparency = 1
    statusText.Text = ""
    statusText.TextColor3 = CONFIG.Colors.Danger
    statusText.TextSize = 12
    statusText.Font = CONFIG.Fonts.Regular
    statusText.ZIndex = 12
    statusText.Parent = keyPrompt
    
    submitBtn.MouseButton1Click:Connect(function()
        local key = keyInput.Text:gsub("%s+", "") -- Remove whitespace
        if key == "" then
            statusText.Text = "Please enter a key"
            statusText.TextColor3 = CONFIG.Colors.Danger
            return
        end
        
        statusText.Text = "Verifying key..."
        statusText.TextColor3 = CONFIG.Colors.Warning
        submitBtn.Text = "Verifying..."
        submitBtn.BackgroundColor3 = CONFIG.Colors.Warning
        
        local valid, message = self:VerifyKey(key)
        
        if valid then
            statusText.Text = "Key verified successfully!"
            statusText.TextColor3 = CONFIG.Colors.Success
            submitBtn.Text = "✓ Success"
            submitBtn.BackgroundColor3 = CONFIG.Colors.Success
            
            wait(1)
            self.authenticated = true
            keyFrame:Destroy()
            self:InitializeComponents()
            self:ShowNotification("Welcome! Key verified successfully.", "success")
        else
            statusText.Text = message or "Invalid key! Please try again."
            statusText.TextColor3 = CONFIG.Colors.Danger
            submitBtn.Text = "✓ Verify Key"
            submitBtn.BackgroundColor3 = CONFIG.Colors.Success
            keyInput.Text = ""
        end
    end)
    
    getKeyBtn.MouseButton1Click:Connect(function()
        self:ShowNotification("Visit our website to get your access key!", "info", 5)
        -- You can add code here to open a browser or copy website URL
    end)
    
    -- Enter key support
    keyInput.FocusLost:Connect(function(enterPressed)
        if enterPressed then
            submitBtn.MouseButton1Click:Fire()
        end
    end)
end

function UILibrary:InitializeComponents()
    -- Create default tab
    self:CreateTab("Main", "🏠")
    self:ShowNotification("UI Library loaded successfully!", "success")
    self:UpdateStatus("Ready - All systems operational")
end

-- Tab System
function UILibrary:CreateTab(name, icon)
    local tabButton = Instance.new("TextButton")
    tabButton.Size = UDim2.new(0, 100, 1, 0)
    tabButton.BackgroundColor3 = CONFIG.Colors.Dark
    tabButton.BorderSizePixel = 0
    tabButton.Text = (icon or "") .. " " .. name
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
        layout = tabLayout
    }
    
    tabButton.MouseButton1Click:Connect(function()
        self:SwitchTab(name)
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
        tab.button.BackgroundColor3 = CONFIG.Colors.Dark
    end
    
    -- Show selected tab
    self.tabs[name].content.Visible = true
    self.tabs[name].button.BackgroundColor3 = CONFIG.Colors.Primary
    self.currentTab = name
    
    self:UpdateStatus("Switched to " .. name .. " tab")
end

function UILibrary:GetCurrentTab()
    if self.currentTab and self.tabs[self.currentTab] then
        return self.tabs[self.currentTab].content
    end
    return self.contentFrame
end

-- Enhanced Button Creation
function UILibrary:CreateButton(text, size, position, parent, buttonType, icon)
    if not self.authenticated then return end
    
    buttonType = buttonType or "default"
    
    local button = Instance.new("TextButton")
    button.Size = size
    button.Position = position
    button.BackgroundColor3 = self:GetButtonColor(buttonType)
    button.BorderSizePixel = 0
    button.Text = (icon or "") .. " " .. text
    button.TextColor3 = CONFIG.Colors.Light
    button.TextSize = 16
    button.Font = CONFIG.Fonts.SemiBold
    button.ZIndex = 3
    button.Parent = parent or self:GetCurrentTab()
    
    createCorner(button, 8)
    createStroke(button, 1, self:GetButtonColor(buttonType), 0.5)
    
    -- Enhanced hover effects
    button.MouseEnter:Connect(function()
        createTween(button, {
            BackgroundColor3 = self:GetButtonColor(buttonType, true),
            Size = size + UDim2.new(0, 2, 0, 2)
        }, 0.15):Play()
    end)
    
    button.MouseLeave:Connect(function()
        createTween(button, {
            BackgroundColor3 = self:GetButtonColor(buttonType),
            Size = size
        }, 0.15):Play()
    end)
    
    -- Click animation
    button.MouseButton1Down:Connect(function()
        createTween(button, {Size = size - UDim2.new(0, 4, 0, 4)}, 0.1):Play()
    end)
    
    button.MouseButton1Up:Connect(function()
        createTween(button, {Size = size}, 0.1):Play()
    end)
    
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

-- Enhanced Component Methods
function UILibrary:AddButton(text, callback, buttonType, icon, tab)
    if not self.authenticated then return end
    
    local parent = tab and self.tabs[tab] and self.tabs[tab].content or self:GetCurrentTab()
    local button = self:CreateButton(text, UDim2.new(1, -20, 0, 45), UDim2.new(0, 0, 0, 0), parent, buttonType, icon)
    
    if callback then
        button.MouseButton1Click:Connect(function()
            local success, err = pcall(callback)
            if not success then
                self:ShowNotification("Error: " .. tostring(err), "error")
            end
        end)
    end
    
    table.insert(self.components, button)
    return button
end

function UILibrary:AddToggleButton(text, defaultState, callback, icon, tab)
    if not self.authenticated then return end
    
    local parent = tab and self.tabs[tab] and self.tabs[tab].content or self:GetCurrentTab()
    local state = defaultState or false
    
    local button = self:CreateButton(text .. ": " .. (state and "ON" or "OFF"), 
                                   UDim2.new(1, -20, 0, 45), UDim2.new(0, 0, 0, 0), parent,
                                   state and "success" or "danger", icon)
    
    button.MouseButton1Click:Connect(function()
        state = not state
        button.Text = (icon or "") .. " " .. text .. ": " .. (state and "ON" or "OFF")
        button.BackgroundColor3 = state and CONFIG.Colors.Success or CONFIG.Colors.Danger
        
        if callback then
            local success, err = pcall(callback, state)
            if not success then
                self:ShowNotification("Error: " .. tostring(err), "error")
            end
        end
        
        self:ShowNotification(text .. " " .. (state and "enabled" or "disabled"), state and "success" or "info")
    end)
    
    table.insert(self.components, button)
    return button
end

function UILibrary:AddSlider(text, min, max, default, callback, tab)
    if not self.authenticated then return end
    
    local parent = tab and self.tabs[tab] and self.tabs[tab].content or self:GetCurrentTab()
    
    local sliderFrame = Instance.new("Frame")
    sliderFrame.Size = UDim2.new(1, -20, 0, 70)
    sliderFrame.BackgroundColor3 = CONFIG.Colors.Surface
    sliderFrame.BorderSizePixel = 0
    sliderFrame.ZIndex = 2
    sliderFrame.Parent = parent
    
    createCorner(sliderFrame, 10)
    createStroke(sliderFrame, 1, CONFIG.Colors.Primary, 0.3)
    
    local label = Instance.new("TextLabel")
    label.Size = UDim2.new(1, -20, 0, 25)
    label.Position = UDim2.new(0, 10, 0, 5)
    label.BackgroundTransparency = 1
    label.Text = text .. ": " .. default
    label.TextColor3 = CONFIG.Colors.Light
    label.TextSize = 16
    label.Font = CONFIG.Fonts.SemiBold
    label.TextXAlignment = Enum.TextXAlignment.Left
    label.ZIndex = 3
    label.Parent = sliderFrame
    
    local sliderBG = Instance.new("Frame")
    sliderBG.Size = UDim2.new(1, -40, 0, 8)
    sliderBG.Position = UDim2.new(0, 20, 0, 40)
    sliderBG.BackgroundColor3 = CONFIG.Colors.Dark
    sliderBG.BorderSizePixel = 0
    sliderBG.ZIndex = 3
    sliderBG.Parent = sliderFrame
    
    createCorner(sliderBG, 4)
    
    local sliderFill = Instance.new("Frame")
    sliderFill.Size = UDim2.new((default - min) / (max - min), 0, 1, 0)
    sliderFill.Position = UDim2.new(0, 0, 0, 0)
    sliderFill.BackgroundColor3 = CONFIG.Colors.Primary
    sliderFill.BorderSizePixel = 0
    sliderFill.ZIndex = 4
    sliderFill.Parent = sliderBG
    
    createCorner(sliderFill, 4)
    createGradient(sliderFill, {CONFIG.Colors.Primary, CONFIG.Colors.Secondary}, 90)
    
    local sliderButton = Instance.new("TextButton")
    sliderButton.Size = UDim2.new(0, 24, 0, 24)
    sliderButton.Position = UDim2.new((default - min) / (max - min), -12, 0, -8)
    sliderButton.BackgroundColor3 = CONFIG.Colors.Light
    sliderButton.BorderSizePixel = 0
    sliderButton.Text = ""
    sliderButton.ZIndex = 5
    sliderButton.Parent = sliderBG
    
    createCorner(sliderButton, 12)
    createStroke(sliderButton, 2, CONFIG.Colors.Primary)
    
    local dragging = false
    local value = default
    
    local function updateSlider(percentage)
        percentage = math.clamp(percentage, 0, 1)
        value = min + (max - min) * percentage
        value = math.floor(value * 100) / 100
        
        sliderButton.Position = UDim2.new(percentage, -12, 0, -8)
        sliderFill.Size = UDim2.new(percentage, 0, 1, 0)
        label.Text = text .. ": " .. value
        
        if callback then
            local success, err = pcall(callback, value)
            if not success then
                self:ShowNotification("Error: " .. tostring(err), "error")
            end
        end
    end
    
    sliderButton.MouseButton1Down:Connect(function()
        dragging = true
    end)
    
    UserInputService.InputEnded:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1 then
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
    
    table.insert(self.components, sliderFrame)
    return sliderFrame
end

function UILibrary:AddDropdown(text, options, defaultOption, callback, tab)
    if not self.authenticated then return end
    
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
    dropdownButton.Size = UDim2.new(1, 0, 1, 0)
    dropdownButton.BackgroundTransparency = 1
    dropdownButton.Text = text .. ": " .. selectedOption .. " ▼"
    dropdownButton.TextColor3 = CONFIG.Colors.Light
    dropdownButton.TextSize = 16
    dropdownButton.Font = CONFIG.Fonts.SemiBold
    dropdownButton.TextXAlignment = Enum.TextXAlignment.Left
    dropdownButton.ZIndex = 3
    dropdownButton.Parent = dropdownFrame
    
    local optionsFrame = Instance.new("Frame")
    optionsFrame.Size = UDim2.new(1, 0, 0, #options * 35)
    optionsFrame.Position = UDim2.new(0, 0, 1, 5)
    optionsFrame.BackgroundColor3 = CONFIG.Colors.Surface
    optionsFrame.BorderSizePixel = 0
    optionsFrame.ZIndex = 10
    optionsFrame.Visible = false
    optionsFrame.Parent = dropdownFrame
    
    createCorner(optionsFrame, 8)
    createStroke(optionsFrame, 1, CONFIG.Colors.Primary, 0.3)
    
    local optionsLayout = Instance.new("UIListLayout")
    optionsLayout.SortOrder = Enum.SortOrder.LayoutOrder
    optionsLayout.Parent = optionsFrame
    
    for i, option in ipairs(options) do
        local optionButton = Instance.new("TextButton")
        optionButton.Size = UDim2.new(1, 0, 0, 35)
        optionButton.BackgroundColor3 = CONFIG.Colors.Surface
        optionButton.BorderSizePixel = 0
        optionButton.Text = option
        optionButton.TextColor3 = CONFIG.Colors.Light
        optionButton.TextSize = 14
        optionButton.Font = CONFIG.Fonts.Regular
        optionButton.ZIndex = 11
        optionButton.Parent = optionsFrame
        
        if i == 1 then createCorner(optionButton, 8) end
        if i == #options then createCorner(optionButton, 8) end
        
        optionButton.MouseEnter:Connect(function()
            optionButton.BackgroundColor3 = CONFIG.Colors.Primary
        end)
        
        optionButton.MouseLeave:Connect(function()
            optionButton.BackgroundColor3 = CONFIG.Colors.Surface
        end)
        
        optionButton.MouseButton1Click:Connect(function()
            selectedOption = option
            dropdownButton.Text = text .. ": " .. selectedOption .. " ▼"
            optionsFrame.Visible = false
            isOpen = false
            
            if callback then
                local success, err = pcall(callback, selectedOption)
                if not success then
                    self:ShowNotification("Error: " .. tostring(err), "error")
                end
            end
        end)
    end
    
    dropdownButton.MouseButton1Click:Connect(function()
        isOpen = not isOpen
        optionsFrame.Visible = isOpen
        dropdownButton.Text = text .. ": " .. selectedOption .. (isOpen and " ▲" or " ▼")
    end)
    
    table.insert(self.components, dropdownFrame)
    return dropdownFrame
end

function UILibrary:AddTextBox(placeholder, callback, multiline, tab)
    if not self.authenticated then return end
    
    local parent = tab and self.tabs[tab] and self.tabs[tab].content or self:GetCurrentTab()
    
    local textBox = Instance.new("TextBox")
    textBox.Size = UDim2.new(1, -20, 0, multiline and 80 or 45)
    textBox.BackgroundColor3 = CONFIG.Colors.Surface
    textBox.BorderSizePixel = 0
    textBox.Text = ""
    textBox.PlaceholderText = placeholder
    textBox.TextColor3 = CONFIG.Colors.Light
    textBox.TextSize = 16
    textBox.Font = CONFIG.Fonts.Regular
    textBox.TextXAlignment = Enum.TextXAlignment.Left
    textBox.TextYAlignment = multiline and Enum.TextYAlignment.Top or Enum.TextYAlignment.Center
    textBox.TextWrapped = multiline or false
    textBox.MultiLine = multiline or false
    textBox.ZIndex = 3
    textBox.Parent = parent
    
    createCorner(textBox, 8)
    createStroke(textBox, 1, CONFIG.Colors.Primary, 0.3)
    
    textBox.Focused:Connect(function()
        createStroke(textBox, 2, CONFIG.Colors.Primary, 0)
    end)
    
    textBox.FocusLost:Connect(function(enterPressed)
        createStroke(textBox, 1, CONFIG.Colors.Primary, 0.3)
        if enterPressed and callback then
            local success, err = pcall(callback, textBox.Text)
            if not success then
                self:ShowNotification("Error: " .. tostring(err), "error")
            end
        end
    end)
    
    table.insert(self.components, textBox)
    return textBox
end

function UILibrary:AddLabel(text, textSize, tab)
    if not self.authenticated then return end
    
    local parent = tab and self.tabs[tab] and self.tabs[tab].content or self:GetCurrentTab()
    
    local label = Instance.new("TextLabel")
    label.Size = UDim2.new(1, -20, 0, textSize or 35)
    label.BackgroundTransparency = 1
    label.Text = text
    label.TextColor3 = CONFIG.Colors.Light
    label.TextSize = 16
    label.Font = CONFIG.Fonts.Regular
    label.TextXAlignment = Enum.TextXAlignment.Left
    label.TextWrapped = true
    label.ZIndex = 3
    label.Parent = parent
    
    table.insert(self.components, label)
    return label
end

function UILibrary:AddSeparator(tab)
    if not self.authenticated then return end
    
    local parent = tab and self.tabs[tab] and self.tabs[tab].content or self:GetCurrentTab()
    
    local separator = Instance.new("Frame")
    separator.Size = UDim2.new(1, -40, 0, 2)
    separator.BackgroundColor3 = CONFIG.Colors.Primary
    separator.BorderSizePixel = 0
    separator.ZIndex = 3
    separator.Parent = parent
    
    createCorner(separator, 1)
    
    table.insert(self.components, separator)
    return separator
end

function UILibrary:AddColorPicker(text, defaultColor, callback, tab)
    if not self.authenticated then return end
    
    local parent = tab and self.tabs[tab] and self.tabs[tab].content or self:GetCurrentTab()
    local currentColor = defaultColor or CONFIG.Colors.Primary
    
    local colorFrame = Instance.new("Frame")
    colorFrame.Size = UDim2.new(1, -20, 0, 45)
    colorFrame.BackgroundColor3 = CONFIG.Colors.Surface
    colorFrame.BorderSizePixel = 0
    colorFrame.ZIndex = 2
    colorFrame.Parent = parent
    
    createCorner(colorFrame, 8)
    createStroke(colorFrame, 1, CONFIG.Colors.Primary, 0.3)
    
    local colorLabel = Instance.new("TextLabel")
    colorLabel.Size = UDim2.new(1, -60, 1, 0)
    colorLabel.Position = UDim2.new(0, 10, 0, 0)
    colorLabel.BackgroundTransparency = 1
    colorLabel.Text = text
    colorLabel.TextColor3 = CONFIG.Colors.Light
    colorLabel.TextSize = 16
    colorLabel.Font = CONFIG.Fonts.SemiBold
    colorLabel.TextXAlignment = Enum.TextXAlignment.Left
    colorLabel.ZIndex = 3
    colorLabel.Parent = colorFrame
    
    local colorPreview = Instance.new("Frame")
    colorPreview.Size = UDim2.new(0, 35, 0, 35)
    colorPreview.Position = UDim2.new(1, -45, 0, 5)
    colorPreview.BackgroundColor3 = currentColor
    colorPreview.BorderSizePixel = 0
    colorPreview.ZIndex = 3
    colorPreview.Parent = colorFrame
    
    createCorner(colorPreview, 6)
    createStroke(colorPreview, 2, CONFIG.Colors.Light)
    
    local colorButton = Instance.new("TextButton")
    colorButton.Size = UDim2.new(1, 0, 1, 0)
    colorButton.BackgroundTransparency = 1
    colorButton.Text = ""
    colorButton.ZIndex = 4
    colorButton.Parent = colorPreview
    
    colorButton.MouseButton1Click:Connect(function()
        -- Simple color picker (you can enhance this)
        local colors = {
            CONFIG.Colors.Primary, CONFIG.Colors.Success, CONFIG.Colors.Warning,
            CONFIG.Colors.Danger, CONFIG.Colors.Info, CONFIG.Colors.Accent,
            Color3.fromRGB(255, 255, 255), Color3.fromRGB(0, 0, 0)
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
        colorPreview.BackgroundColor3 = currentColor
        
        if callback then
            local success, err = pcall(callback, currentColor)
            if not success then
                self:ShowNotification("Error: " .. tostring(err), "error")
            end
        end
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
    notification.Size = UDim2.new(0, 350, 0, 70)
    notification.Position = UDim2.new(1, -370, 0, 20 + (#self.notifications * 80))
    notification.BackgroundColor3 = colors[type] or colors.info
    notification.BorderSizePixel = 0
    notification.ZIndex = 50
    notification.Parent = self.screenGui
    
    createCorner(notification, 10)
    createShadow(notification)
    
    local notifIcon = Instance.new("TextLabel")
    notifIcon.Size = UDim2.new(0, 30, 0, 30)
    notifIcon.Position = UDim2.new(0, 10, 0, 10)
    notifIcon.BackgroundTransparency = 1
    notifIcon.Text = icons[type] or icons.info
    notifIcon.TextSize = 20
    notifIcon.ZIndex = 51
    notifIcon.Parent = notification
    
    local notifText = Instance.new("TextLabel")
    notifText.Size = UDim2.new(1, -80, 1, -20)
    notifText.Position = UDim2.new(0, 50, 0, 10)
    notifText.BackgroundTransparency = 1
    notifText.Text = message
    notifText.TextColor3 = CONFIG.Colors.Light
    notifText.TextSize = 14
    notifText.Font = CONFIG.Fonts.SemiBold
    notifText.TextWrapped = true
    notifText.TextXAlignment = Enum.TextXAlignment.Left
    notifText.ZIndex = 51
    notifText.Parent = notification
    
    local closeBtn = Instance.new("TextButton")
    closeBtn.Size = UDim2.new(0, 20, 0, 20)
    closeBtn.Position = UDim2.new(1, -30, 0, 10)
    closeBtn.BackgroundTransparency = 1
    closeBtn.Text = "×"
    closeBtn.TextColor3 = CONFIG.Colors.Light
    closeBtn.TextSize = 16
    closeBtn.Font = CONFIG.Fonts.Bold
    closeBtn.ZIndex = 51
    closeBtn.Parent = notification
    
    table.insert(self.notifications, notification)
    
    -- Slide in animation
    createTween(notification, {Position = UDim2.new(1, -370, 0, 20 + ((#self.notifications - 1) * 80))}, 0.5, Enum.EasingStyle.Back):Play()
    
    local function removeNotification()
        for i, notif in ipairs(self.notifications) do
            if notif == notification then
                table.remove(self.notifications, i)
                break
            end
        end
        
        -- Slide out and destroy
        createTween(notification, {Position = UDim2.new(1, 20, 0, notification.Position.Y.Offset)}, 0.3):Play()
        wait(0.3)
        notification:Destroy()
        
        -- Reposition remaining notifications
        for i, notif in ipairs(self.notifications) do
            createTween(notif, {Position = UDim2.new(1, -370, 0, 20 + ((i - 1) * 80))}, 0.3):Play()
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

-- Window Controls
function UILibrary:ToggleMinimize()
    self.minimized = not self.minimized
    
    if self.minimized then
        createTween(self.mainFrame, {Size = UDim2.new(0, 600, 0, 45)}, 0.3):Play()
        self.tabFrame.Visible = false
        self.contentFrame.Visible = false
        self.statusBar.Visible = false
        self.minimizeBtn.Text = "+"
        self:UpdateStatus("Minimized")
    else
        createTween(self.mainFrame, {Size = UDim2.new(0, 600, 0, 450)}, 0.3):Play()
        self.tabFrame.Visible = true
        self.contentFrame.Visible = true
        self.statusBar.Visible = true
        self.minimizeBtn.Text = "−"
        self:UpdateStatus("Restored")
    end
end

function UILibrary:ToggleMaximize()
    -- Simple maximize toggle (you can enhance this)
    local currentSize = self.mainFrame.Size
    if currentSize.X.Offset == 600 then
        createTween(self.mainFrame, {
            Size = UDim2.new(0, 800, 0, 600),
            Position = UDim2.new(0.5, -400, 0.5, -300)
        }, 0.3):Play()
        self:UpdateStatus("Maximized")
    else
        createTween(self.mainFrame, {
            Size = UDim2.new(0, 600, 0, 450),
            Position = UDim2.new(0.5, -300, 0.5, -225)
        }, 0.3):Play()
        self:UpdateStatus("Restored")
    end
end

function UILibrary:Close()
    self:UpdateStatus("Closing...")
    
    -- Close animation
    createTween(self.mainFrame, {
        Size = UDim2.new(0, 0, 0, 0),
        Position = UDim2.new(0.5, 0, 0.5, 0),
        BackgroundTransparency = 1
    }, 0.5, Enum.EasingStyle.Back, Enum.EasingDirection.In):Play()
    
    wait(0.5)
    self.screenGui:Destroy()
end

function UILibrary:Show()
    self.screenGui.Enabled = true
    self:ShowNotification("UI Library shown", "info")
end

function UILibrary:Hide()
    self.screenGui.Enabled = false
end

function UILibrary:Destroy()
    self:Close()
end

return UILibrary
