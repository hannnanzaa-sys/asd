
    
  
        local connection
        connection = TeleportService.TeleportInitFailed:Connect(
            function(failedPlayer, result, message)
                if failedPlayer ~= player or failed then
                    return
                end

                failed = true
                warn("[HANX HUB] Teleport failed:", result, message)

                txt.Text = "Teleport Failed"
                txt.TextColor3 = Color3.fromRGB(255, 70, 70)

                if connection then
                    connection:Disconnect()
                end
            end
        )

        local success, err = pcall(function()
            TeleportService:Teleport(game.PlaceId, player)
        end)

        if not success then
            warn("[HANX HUB] Rejoin error:", err)
            txt.Text = "Rejoin Failed"
            txt.TextColor3 = Color3.fromRGB(255, 70, 70)

            if connection then
                connection:Disconnect()
            end
        end
    end
)

-- ISI TAB SOCIAL MEDIA
CreateLabel(SocialPage, "Join Our Community")
CreateLabel(SocialPage, "Follow for updates and more scripts!")

CreateMimiwButton(SocialPage, "DISCORD SERVER", Theme.Card, "Click to open invite link", function(btn, txt)
    if setclipboard then setclipboard("https://discord.gg/p6RrUTr8V"); txt.Text = "Opening Link..."; txt.TextColor3 = Theme.Neon
        local success = pcall(function() if openbrowser then openbrowser("https://discord.gg/p6RrUTr8V") elseif request then request({Url = "https://discord.gg/p6RrUTr8V", Method = "GET"}) end end)
        if not success then txt.Text = "Link Copied! Paste di browser." end
        task.wait(2); txt.Text = "DISCORD SERVER"; txt.TextColor3 = Theme.Text end
end)

CreateMimiwButton(SocialPage, "YOUTUBE CHANNEL", Theme.Card, "Subscribe for more scripts!", function(btn, txt)
    if setclipboard then setclipboard("https://youtube.com/@hanxhub"); txt.Text = "Opening Link..."; txt.TextColor3 = Theme.Neon
        local success = pcall(function() if openbrowser then openbrowser("https://youtube.com/@hanxhub") elseif request then request({Url = "https://youtube.com/@hanxhub", Method = "GET"}) end end)
        if not success then txt.Text = "Link Copied! Paste di browser." end
        task.wait(2); txt.Text = "YOUTUBE CHANNEL"; txt.TextColor3 = Theme.Text end
end)

CreateMimiwButton(SocialPage, "TIKTOK", Theme.Card, "Follow for tips & tricks", function(btn, txt)
    if setclipboard then setclipboard("https://tiktok.com/@whoohnbro_"); txt.Text = "Opening Link..."; txt.TextColor3 = Theme.Neon
        local success = pcall(function() if openbrowser then openbrowser("https://tiktok.com/@whoohnbro_") elseif request then request({Url = "https://tiktok.com/@whoohnbro_", Method = "GET"}) end end)
        if not success then txt.Text = "Link Copied! Paste di browser." end
        task.wait(2); txt.Text = "TIKTOK"; txt.TextColor3 = Theme.Text end
end)

CreateMimiwButton(SocialPage, "SAWERIA", Theme.Card, "Support for more content!", function(btn, txt)
    if setclipboard then setclipboard("https://saweria.co/hanxhub"); txt.Text = "Opening Link..."; txt.TextColor3 = Theme.Neon
        local success = pcall(function() if openbrowser then openbrowser("https://saweria.co/hanxhub") elseif request then request({Url = "https://saweria.co/hanxhub", Method = "GET"}) end end)
        if not success then txt.Text = "Link Copied! Paste di browser." end
        task.wait(2); txt.Text = "SAWERIA"; txt.TextColor3 = Theme.Text end
end)

-- WATERMARK & KEYBINDS
local WatermarkGui = Instance.new("ScreenGui")
WatermarkGui.Name = "HANX_Watermark"
WatermarkGui.ResetOnSpawn = false
WatermarkGui.Parent = CoreGui
local Watermark = Instance.new("TextLabel")
Watermark.Size = UDim2.fromOffset(150, 20); Watermark.Position = UDim2.new(0, 10, 0, 10); Watermark.BackgroundTransparency = 1; Watermark.Text = "HANX HUB | Free User"; Watermark.TextColor3 = Theme.Neon; Watermark.TextStrokeTransparency = 0; Watermark.Font = Enum.Font.GothamBold; Watermark.TextSize = 12; Watermark.Parent = WatermarkGui

local keybindState = { ESP = false }
UserInputService.InputBegan:Connect(function(input, gameProcessed)
    if gameProcessed then return end
    if input.KeyCode == Enum.KeyCode.V then
        keybindState.ESP = not keybindState.ESP
        ESP_Status.Survivor = keybindState.ESP; ESP_Status.Killer = keybindState.ESP
    end
end)

-- SPLASH SCREEN
local SplashGui = Instance.new("ScreenGui"); SplashGui.Name = "HANX_HUB_Splash"; SplashGui.ResetOnSpawn = false; SplashGui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling; SplashGui.IgnoreGuiInset = true; SplashGui.DisplayOrder = 999; SplashGui.Parent = CoreGui
local SplashBg = Instance.new("Frame"); SplashBg.Size = UDim2.fromScale(1, 1); SplashBg.BackgroundColor3 = Color3.new(0,0,0); SplashBg.BackgroundTransparency = 1; SplashBg.BorderSizePixel = 0; SplashBg.Parent = SplashGui
local SplashBox = Instance.new("Frame"); SplashBox.Size = UDim2.fromOffset(280, 120); SplashBox.Position = UDim2.new(0.5, -140, 0.5, -60); SplashBox.BackgroundColor3 = Color3.fromRGB(15, 15, 18); SplashBox.BackgroundTransparency = 0.2; SplashBox.BorderSizePixel = 0; SplashBox.Parent = SplashGui; corner(SplashBox, 10); addStroke(SplashBox, Theme.Neon, 1, 0.5)
local SplashTitle = Instance.new("TextLabel"); SplashTitle.Size = UDim2.new(1, 0, 0, 40); SplashTitle.Position = UDim2.new(0, 0, 0, 20); SplashTitle.BackgroundTransparency = 1; SplashTitle.Text = "HANX HUB"; SplashTitle.TextColor3 = Theme.Neon; SplashTitle.Font = Enum.Font.GothamBlack; SplashTitle.TextSize = 24; SplashTitle.Parent = SplashBox
local SplashSub = Instance.new("TextLabel"); SplashSub.Size = UDim2.new(1, 0, 0, 20); SplashSub.Position = UDim2.new(0, 0, 0, 55); SplashSub.BackgroundTransparency = 1; SplashSub.Text = "Loading scripts..."; SplashSub.TextColor3 = Theme.SubText; SplashSub.Font = Enum.Font.Gotham; SplashSub.TextSize = 12; SplashSub.Parent = SplashBox
local BarBg = Instance.new("Frame"); BarBg.Size = UDim2.new(1, -40, 0, 6); BarBg.Position = UDim2.new(0, 20, 1, -20); BarBg.BackgroundColor3 = Theme.Sidebar; BarBg.BorderSizePixel = 0; BarBg.Parent = SplashBox; corner(BarBg, 3)
local BarFill = Instance.new("Frame"); BarFill.Size = UDim2.fromScale(0, 1); BarFill.BackgroundColor3 = Theme.Neon; BarFill.BorderSizePixel = 0; BarFill.Parent = BarBg; corner(BarFill, 3)

task.spawn(function()
    TweenService:Create(BarFill, TweenInfo.new(1.5, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {Size = UDim2.fromScale(1, 1)}):Play()
    task.wait(1.6)
    TweenService:Create(SplashBox, TweenInfo.new(0.3), {BackgroundTransparency = 1}):Play()
    TweenService:Create(SplashTitle, TweenInfo.new(0.3), {TextTransparency = 1}):Play()
    TweenService:Create(SplashSub, TweenInfo.new(0.3), {TextTransparency = 1}):Play()
    TweenService:Create(BarBg, TweenInfo.new(0.3), {BackgroundTransparency = 1}):Play()
    TweenService:Create(BarFill, TweenInfo.new(0.3), {BackgroundTransparency = 1}):Play()
    task.wait(0.3)
    SplashGui:Destroy()
    
    Screen.Enabled = true
    Window.Size = UDim2.fromOffset(0, 0)
    task.wait(0.1)
    TweenService:Create(Window, TweenInfo.new(0.4, Enum.EasingStyle.Back, Enum.EasingDirection.Out), {Size = UDim2.fromOffset(580, 420)}):Play()
    
    task.wait(0.4)
    SelectTab(1)
    print("[HANX HUB] Loaded.")
end)
