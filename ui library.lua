-- Advanced Roblox UI Library with Key System
-- Created by v0

local UILibrary = {}
UILibrary.__index = UILibrary

-- Services
local TweenService = game:GetService("TweenService")
local UserInputService = game:GetService("UserInputService")
local HttpService = game:GetService("HttpService")
local Players = game:GetService("Players")
local RunService = game:GetService("RunService")

-- Configuration
local CONFIG = {
    KeyAPI = "https://your-key-website.com/api/verify", -- Replace with your website URL
    AnimationSpeed = 0.3,
    Colors = {
        Primary = Color3.fromRGB(88, 101, 242),
        Secondary = Color3.fromRGB(114, 137, 218),
        Success = Color3.fromRGB(87, 242, 135),
        Warning = Color3.fromRGB(255, 193, 7),
        Danger = Color3.fromRGB(220, 53, 69),
        Dark = Color3.fromRGB(32, 34, 37),
        Light = Color3.fromRGB(255, 255, 255),
        Background = Color3.fromRGB(54, 57, 63),
        Surface = Color3.fromRGB(64, 68, 75)
    }
}

-- Utility Functions
local function createTween(object, properties, duration)
    duration = duration or CONFIG.AnimationSpeed
    local tweenInfo = TweenInfo.new(duration, Enum.EasingStyle.Quad, Enum.EasingDirection.Out)
    return TweenService:Create(object, tweenInfo, properties)
end

local function createCorner(parent, radius)
    local corner = Instance.new("UICorner")
    corner.CornerRadius = UDim.new(0, radius or 8)
    corner.Parent = parent
    return corner
end

local function createGradient(parent, colors, rotation)
    local gradient = Instance.new("UIGradient")
    gradient.Color = ColorSequence.new(colors)
    gradient.Rotation = rotation or 0
    gradient.Parent = parent
    return gradient
end

-- Key System
function UILibrary:VerifyKey(key)
    local success, result = pcall(function()
        local response = HttpService:RequestAsync({
            Url = CONFIG.KeyAPI,
            Method = "POST",
            Headers = {
                ["Content-Type"] = "application/json"
            },
            Body = HttpService:JSONEncode({
                key = key,
                userId = Players.LocalPlayer.UserId,
                username = Players.LocalPlayer.Name
            })
        })
        
        if response.StatusCode == 200 then
            local data = HttpService:JSONDecode(response.Body)
            return data.valid == true
        end
        return false
    end)
    
    return success and result
end

-- Main Library Constructor
function UILibrary.new(title, keyRequired)
    local self = setmetatable({}, UILibrary)
    
    self.title = title or "UI Library"
    self.keyRequired = keyRequired or false
    self.authenticated = not keyRequired
    self.minimized = false
    self.components = {}
    
    self:CreateMainGUI()
    
    if keyRequired then
        self:ShowKeyPrompt()
    end
    
    return self
end

function UILibrary:CreateMainGUI()
    -- Main ScreenGui
    self.screenGui = Instance.new("ScreenGui")
    self.screenGui.Name = "AdvancedUILibrary"
    self.screenGui.ResetOnSpawn = false
    self.screenGui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
    self.screenGui.Parent = Players.LocalPlayer:WaitForChild("PlayerGui")
    
    -- Main Frame
    self.mainFrame = Instance.new("Frame")
    self.mainFrame.Name = "MainFrame"
    self.mainFrame.Size = UDim2.new(0, 500, 0, 400)
    self.mainFrame.Position = UDim2.new(0.5, -250, 0.5, -200)
    self.mainFrame.BackgroundColor3 = CONFIG.Colors.Background
    self.mainFrame.BorderSizePixel = 0
    self.mainFrame.Active = true
    self.mainFrame.Draggable = true
    self.mainFrame.Parent = self.screenGui
    
    createCorner(self.mainFrame, 12)
    
    -- Drop Shadow
    local shadow = Instance.new("ImageLabel")
    shadow.Name = "Shadow"
    shadow.Size = UDim2.new(1, 20, 1, 20)
    shadow.Position = UDim2.new(0, -10, 0, -10)
    shadow.BackgroundTransparency = 1
    shadow.Image = "rbxasset://textures/ui/GuiImagePlaceholder.png"
    shadow.ImageColor3 = Color3.fromRGB(0, 0, 0)
    shadow.ImageTransparency = 0.8
    shadow.ZIndex = -1
    shadow.Parent = self.mainFrame
    
    -- Title Bar
    self.titleBar = Instance.new("Frame")
    self.titleBar.Name = "TitleBar"
    self.titleBar.Size = UDim2.new(1, 0, 0, 40)
    self.titleBar.Position = UDim2.new(0, 0, 0, 0)
    self.titleBar.BackgroundColor3 = CONFIG.Colors.Primary
    self.titleBar.BorderSizePixel = 0
    self.titleBar.Parent = self.mainFrame
    
    createCorner(self.titleBar, 12)
    createGradient(self.titleBar, {CONFIG.Colors.Primary, CONFIG.Colors.Secondary}, 45)
    
    -- Title Label
    self.titleLabel = Instance.new("TextLabel")
    self.titleLabel.Name = "TitleLabel"
    self.titleLabel.Size = UDim2.new(1, -80, 1, 0)
    self.titleLabel.Position = UDim2.new(0, 10, 0, 0)
    self.titleLabel.BackgroundTransparency = 1
    self.titleLabel.Text = self.title
    self.titleLabel.TextColor3 = CONFIG.Colors.Light
    self.titleLabel.TextScaled = true
    self.titleLabel.Font = Enum.Font.GothamBold
    self.titleLabel.TextXAlignment = Enum.TextXAlignment.Left
    self.titleLabel.Parent = self.titleBar
    
    -- Minimize Button
    self.minimizeBtn = self:CreateButton("_", UDim2.new(0, 30, 0, 30), UDim2.new(1, -70, 0, 5), self.titleBar)
    self.minimizeBtn.BackgroundColor3 = CONFIG.Colors.Warning
    self.minimizeBtn.MouseButton1Click:Connect(function()
        self:ToggleMinimize()
    end)
    
    -- Close Button
    self.closeBtn = self:CreateButton("X", UDim2.new(0, 30, 0, 30), UDim2.new(1, -35, 0, 5), self.titleBar)
    self.closeBtn.BackgroundColor3 = CONFIG.Colors.Danger
    self.closeBtn.MouseButton1Click:Connect(function()
        self:Close()
    end)
    
    -- Content Frame
    self.contentFrame = Instance.new("ScrollingFrame")
    self.contentFrame.Name = "ContentFrame"
    self.contentFrame.Size = UDim2.new(1, -20, 1, -60)
    self.contentFrame.Position = UDim2.new(0, 10, 0, 50)
    self.contentFrame.BackgroundColor3 = CONFIG.Colors.Surface
    self.contentFrame.BorderSizePixel = 0
    self.contentFrame.ScrollBarThickness = 6
    self.contentFrame.ScrollBarImageColor3 = CONFIG.Colors.Primary
    self.contentFrame.CanvasSize = UDim2.new(0, 0, 0, 0)
    self.contentFrame.Parent = self.mainFrame
    
    createCorner(self.contentFrame, 8)
    
    -- Auto-resize canvas
    local layout = Instance.new("UIListLayout")
    layout.SortOrder = Enum.SortOrder.LayoutOrder
    layout.Padding = UDim.new(0, 10)
    layout.Parent = self.contentFrame
    
    layout:GetPropertyChangedSignal("AbsoluteContentSize"):Connect(function()
        self.contentFrame.CanvasSize = UDim2.new(0, 0, 0, layout.AbsoluteContentSize.Y + 20)
    end)
end

function UILibrary:ShowKeyPrompt()
    local keyFrame = Instance.new("Frame")
    keyFrame.Name = "KeyFrame"
    keyFrame.Size = UDim2.new(1, 0, 1, 0)
    keyFrame.Position = UDim2.new(0, 0, 0, 0)
    keyFrame.BackgroundColor3 = Color3.fromRGB(0, 0, 0)
    keyFrame.BackgroundTransparency = 0.5
    keyFrame.Parent = self.screenGui
    
    local keyPrompt = Instance.new("Frame")
    keyPrompt.Size = UDim2.new(0, 300, 0, 200)
    keyPrompt.Position = UDim2.new(0.5, -150, 0.5, -100)
    keyPrompt.BackgroundColor3 = CONFIG.Colors.Background
    keyPrompt.BorderSizePixel = 0
    keyPrompt.Parent = keyFrame
    
    createCorner(keyPrompt, 12)
    
    local keyTitle = Instance.new("TextLabel")
    keyTitle.Size = UDim2.new(1, -20, 0, 40)
    keyTitle.Position = UDim2.new(0, 10, 0, 10)
    keyTitle.BackgroundTransparency = 1
    keyTitle.Text = "Enter Access Key"
    keyTitle.TextColor3 = CONFIG.Colors.Light
    keyTitle.TextScaled = true
    keyTitle.Font = Enum.Font.GothamBold
    keyTitle.Parent = keyPrompt
    
    local keyInput = Instance.new("TextBox")
    keyInput.Size = UDim2.new(1, -40, 0, 40)
    keyInput.Position = UDim2.new(0, 20, 0, 60)
    keyInput.BackgroundColor3 = CONFIG.Colors.Surface
    keyInput.BorderSizePixel = 0
    keyInput.Text = ""
    keyInput.PlaceholderText = "Enter your key here..."
    keyInput.TextColor3 = CONFIG.Colors.Light
    keyInput.TextScaled = true
    keyInput.Font = Enum.Font.Gotham
    keyInput.Parent = keyPrompt
    
    createCorner(keyInput, 8)
    
    local submitBtn = self:CreateButton("Submit", UDim2.new(0, 100, 0, 35), UDim2.new(0.5, -50, 0, 120), keyPrompt)
    submitBtn.BackgroundColor3 = CONFIG.Colors.Success
    
    local getKeyBtn = self:CreateButton("Get Key", UDim2.new(0, 100, 0, 25), UDim2.new(0.5, -50, 0, 165), keyPrompt)
    getKeyBtn.BackgroundColor3 = CONFIG.Colors.Primary
    getKeyBtn.TextScaled = true
    
    submitBtn.MouseButton1Click:Connect(function()
        local key = keyInput.Text
        if self:VerifyKey(key) then
            self.authenticated = true
            keyFrame:Destroy()
            self:ShowNotification("Key verified successfully!", "success")
        else
            self:ShowNotification("Invalid key! Please try again.", "error")
            keyInput.Text = ""
        end
    end)
    
    getKeyBtn.MouseButton1Click:Connect(function()
        -- Open key website (you'll need to implement this based on your setup)
        self:ShowNotification("Visit the website to get your key!", "info")
    end)
end

-- Button Creation with Advanced Features
function UILibrary:CreateButton(text, size, position, parent, buttonType)
    buttonType = buttonType or "default"
    
    local button = Instance.new("TextButton")
    button.Size = size
    button.Position = position
    button.BackgroundColor3 = self:GetButtonColor(buttonType)
    button.BorderSizePixel = 0
    button.Text = text
    button.TextColor3 = CONFIG.Colors.Light
    button.TextScaled = true
    button.Font = Enum.Font.GothamSemibold
    button.Parent = parent or self.contentFrame
    
    createCorner(button, 8)
    
    -- Hover Effects
    button.MouseEnter:Connect(function()
        createTween(button, {BackgroundColor3 = self:GetButtonColor(buttonType, true)}):Play()
    end)
    
    button.MouseLeave:Connect(function()
        createTween(button, {BackgroundColor3 = self:GetButtonColor(buttonType)}):Play()
    end)
    
    -- Click Animation
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
        secondary = CONFIG.Colors.Secondary
    }
    
    local color = colors[buttonType] or colors.default
    
    if hover then
        return Color3.new(
            math.min(color.R + 0.1, 1),
            math.min(color.G + 0.1, 1),
            math.min(color.B + 0.1, 1)
        )
    end
    
    return color
end

-- Advanced Button Types
function UILibrary:AddButton(text, callback, buttonType)
    if not self.authenticated then return end
    
    local button = self:CreateButton(text, UDim2.new(1, -20, 0, 40), UDim2.new(0, 0, 0, 0), nil, buttonType)
    button.MouseButton1Click:Connect(callback or function() end)
    
    table.insert(self.components, button)
    return button
end

function UILibrary:AddToggleButton(text, defaultState, callback)
    if not self.authenticated then return end
    
    local button = self:CreateButton(text .. ": " .. (defaultState and "ON" or "OFF"), 
                                   UDim2.new(1, -20, 0, 40), UDim2.new(0, 0, 0, 0))
    
    local state = defaultState
    button.BackgroundColor3 = state and CONFIG.Colors.Success or CONFIG.Colors.Danger
    
    button.MouseButton1Click:Connect(function()
        state = not state
        button.Text = text .. ": " .. (state and "ON" or "OFF")
        button.BackgroundColor3 = state and CONFIG.Colors.Success or CONFIG.Colors.Danger
        
        if callback then callback(state) end
    end)
    
    table.insert(self.components, button)
    return button
end

function UILibrary:AddSlider(text, min, max, default, callback)
    if not self.authenticated then return end
    
    local sliderFrame = Instance.new("Frame")
    sliderFrame.Size = UDim2.new(1, -20, 0, 60)
    sliderFrame.BackgroundColor3 = CONFIG.Colors.Surface
    sliderFrame.BorderSizePixel = 0
    sliderFrame.Parent = self.contentFrame
    
    createCorner(sliderFrame, 8)
    
    local label = Instance.new("TextLabel")
    label.Size = UDim2.new(1, -20, 0, 20)
    label.Position = UDim2.new(0, 10, 0, 5)
    label.BackgroundTransparency = 1
    label.Text = text .. ": " .. default
    label.TextColor3 = CONFIG.Colors.Light
    label.TextScaled = true
    label.Font = Enum.Font.Gotham
    label.TextXAlignment = Enum.TextXAlignment.Left
    label.Parent = sliderFrame
    
    local sliderBG = Instance.new("Frame")
    sliderBG.Size = UDim2.new(1, -40, 0, 6)
    sliderBG.Position = UDim2.new(0, 20, 0, 35)
    sliderBG.BackgroundColor3 = CONFIG.Colors.Dark
    sliderBG.BorderSizePixel = 0
    sliderBG.Parent = sliderFrame
    
    createCorner(sliderBG, 3)
    
    local sliderFill = Instance.new("Frame")
    sliderFill.Size = UDim2.new((default - min) / (max - min), 0, 1, 0)
    sliderFill.Position = UDim2.new(0, 0, 0, 0)
    sliderFill.BackgroundColor3 = CONFIG.Colors.Primary
    sliderFill.BorderSizePixel = 0
    sliderFill.Parent = sliderBG
    
    createCorner(sliderFill, 3)
    
    local sliderButton = Instance.new("TextButton")
    sliderButton.Size = UDim2.new(0, 20, 0, 20)
    sliderButton.Position = UDim2.new((default - min) / (max - min), -10, 0, -7)
    sliderButton.BackgroundColor3 = CONFIG.Colors.Light
    sliderButton.BorderSizePixel = 0
    sliderButton.Text = ""
    sliderButton.Parent = sliderBG
    
    createCorner(sliderButton, 10)
    
    local dragging = false
    local value = default
    
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
            local percentage = math.clamp(relativeX / sliderBG.AbsoluteSize.X, 0, 1)
            
            value = min + (max - min) * percentage
            value = math.floor(value * 100) / 100 -- Round to 2 decimal places
            
            sliderButton.Position = UDim2.new(percentage, -10, 0, -7)
            sliderFill.Size = UDim2.new(percentage, 0, 1, 0)
            label.Text = text .. ": " .. value
            
            if callback then callback(value) end
        end
    end)
    
    table.insert(self.components, sliderFrame)
    return sliderFrame
end

function UILibrary:AddTextBox(placeholder, callback)
    if not self.authenticated then return end
    
    local textBox = Instance.new("TextBox")
    textBox.Size = UDim2.new(1, -20, 0, 40)
    textBox.BackgroundColor3 = CONFIG.Colors.Surface
    textBox.BorderSizePixel = 0
    textBox.Text = ""
    textBox.PlaceholderText = placeholder
    textBox.TextColor3 = CONFIG.Colors.Light
    textBox.TextScaled = true
    textBox.Font = Enum.Font.Gotham
    textBox.Parent = self.contentFrame
    
    createCorner(textBox, 8)
    
    textBox.FocusLost:Connect(function(enterPressed)
        if enterPressed and callback then
            callback(textBox.Text)
        end
    end)
    
    table.insert(self.components, textBox)
    return textBox
end

function UILibrary:AddLabel(text, textSize)
    if not self.authenticated then return end
    
    local label = Instance.new("TextLabel")
    label.Size = UDim2.new(1, -20, 0, textSize or 30)
    label.BackgroundTransparency = 1
    label.Text = text
    label.TextColor3 = CONFIG.Colors.Light
    label.TextScaled = true
    label.Font = Enum.Font.Gotham
    label.TextXAlignment = Enum.TextXAlignment.Left
    label.Parent = self.contentFrame
    
    table.insert(self.components, label)
    return label
end

function UILibrary:AddSeparator()
    if not self.authenticated then return end
    
    local separator = Instance.new("Frame")
    separator.Size = UDim2.new(1, -40, 0, 2)
    separator.BackgroundColor3 = CONFIG.Colors.Primary
    separator.BorderSizePixel = 0
    separator.Parent = self.contentFrame
    
    table.insert(self.components, separator)
    return separator
end

-- Notification System
function UILibrary:ShowNotification(message, type, duration)
    type = type or "info"
    duration = duration or 3
    
    local colors = {
        info = CONFIG.Colors.Primary,
        success = CONFIG.Colors.Success,
        warning = CONFIG.Colors.Warning,
        error = CONFIG.Colors.Danger
    }
    
    local notification = Instance.new("Frame")
    notification.Size = UDim2.new(0, 300, 0, 60)
    notification.Position = UDim2.new(1, -320, 0, 20)
    notification.BackgroundColor3 = colors[type] or colors.info
    notification.BorderSizePixel = 0
    notification.Parent = self.screenGui
    
    createCorner(notification, 8)
    
    local notifText = Instance.new("TextLabel")
    notifText.Size = UDim2.new(1, -20, 1, -20)
    notifText.Position = UDim2.new(0, 10, 0, 10)
    notifText.BackgroundTransparency = 1
    notifText.Text = message
    notifText.TextColor3 = CONFIG.Colors.Light
    notifText.TextScaled = true
    notifText.Font = Enum.Font.Gotham
    notifText.TextWrapped = true
    notifText.Parent = notification
    
    -- Slide in animation
    createTween(notification, {Position = UDim2.new(1, -320, 0, 20)}):Play()
    
    -- Auto-remove after duration
    wait(duration)
    createTween(notification, {Position = UDim2.new(1, 20, 0, 20)}):Play()
    wait(0.5)
    notification:Destroy()
end

-- Minimize/Maximize Functions
function UILibrary:ToggleMinimize()
    self.minimized = not self.minimized
    
    if self.minimized then
        createTween(self.mainFrame, {Size = UDim2.new(0, 500, 0, 40)}):Play()
        self.contentFrame.Visible = false
        self.minimizeBtn.Text = "+"
    else
        createTween(self.mainFrame, {Size = UDim2.new(0, 500, 0, 400)}):Play()
        self.contentFrame.Visible = true
        self.minimizeBtn.Text = "_"
    end
end

function UILibrary:Close()
    createTween(self.mainFrame, {
        Size = UDim2.new(0, 0, 0, 0),
        Position = UDim2.new(0.5, 0, 0.5, 0)
    }):Play()
    
    wait(CONFIG.AnimationSpeed)
    self.screenGui:Destroy()
end

function UILibrary:Show()
    self.screenGui.Enabled = true
end

function UILibrary:Hide()
    self.screenGui.Enabled = false
end

return UILibrary
