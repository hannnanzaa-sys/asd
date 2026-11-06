-- HANX HUB v17.5 | Sidebar Text Layout Fix (FIXED GEN & TEXTBOX)
-- Catatan: gunakan hanya di experience milik sendiri atau yang mengizinkan pengujian.
local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local UIS = game:GetService("UserInputService")
local TweenService = game:GetService("TweenService")
local LP = Players.LocalPlayer
local FastVaultEnabled = false

-- ============================================================
-- FAST VAULT (V35 ENGINE)
-- ============================================================
local V35_Code = [[
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local LP = Players.LocalPlayer
local FastVaultEnabled = false
local ControllerModule

task.spawn(function()
    if not game:IsLoaded() then game.Loaded:Wait() end
    local controller
    for attempt = 1, 10 do
        local success, result = pcall(function()
            local modules = ReplicatedStorage:WaitForChild("Modules", 5)
            if not modules then return nil end
            local survivors = modules:WaitForChild("Survivors", 5)
            if not survivors then return nil end
            local module = survivors:WaitForChild("SurvivorAnimationsController", 5)
            if not module then return nil end
            return require(module)
        end)
        if success and result then controller = result break end
        task.wait(1)
    end
    if not controller then return end
    ControllerModule = controller

    local OriginalFacing = controller._isFacingStraightEnough
    local OriginalVault = controller._onVaultAnimation

    controller._isFacingStraightEnough = function(self, part1, part2, angle)
        if not FastVaultEnabled then return OriginalFacing(self, part1, part2, angle) end
        self.characterspeed = 30
        return true, 0
    end

    controller._onVaultAnimation = function(self, vaultPoint, sprinting, requestId)
        if not FastVaultEnabled then return OriginalVault(self, vaultPoint, sprinting, requestId) end
        if self.isVaulting then return end
        self.isSlideingPallet = false
        if self.character then self.character:SetAttribute("vaultspeed", 2.0) end
        local result = table.pack(pcall(function()
            return OriginalVault(self, vaultPoint, true, requestId)
        end))
        task.delay(0.15, function()
            if self.isVaulting then
                if self.activeVaultTrack then pcall(function() self.activeVaultTrack:Stop() end) end
                if self.humanoidRootPart and vaultPoint then
                    local targetCFrame = vaultPoint.CFrame * CFrame.new(0, 2, -1)
                    self.humanoidRootPart.CFrame = targetCFrame
                end
                if self.VaultCompleteEvent then
                    pcall(function() self.VaultCompleteEvent:FireServer(vaultPoint, true, requestId, self.character) end)
                end
                self.isVaulting = false
                self.humanoid.AutoRotate = true
                self:_finishVaultOrSlideSpeed(true)
                self:_checkConditions()
            end
        end)
        task.delay(1.0, function() if self.character then self.character:SetAttribute("vaultspeed", 1) end end)
        return table.unpack(result, 2, result.n)
    end
end)

_G.HANX_V35_ENABLED = false
local LastState = false
RunService.Heartbeat:Connect(function()
    if _G.HANX_V35_ENABLED ~= LastState then
        LastState = _G.HANX_V35_ENABLED
        FastVaultEnabled = LastState
    end
end)
]]

task.spawn(function()
    local ls = loadstring or (syn and syn.loadstring) or (secure_loadstring) or nil
    if not ls then
        warn("[HANX HUB] loadstring tidak tersedia — Fast Vault nonaktif")
        return
    end
    local func, err = ls(V35_Code)
    if func then pcall(func) else warn("[HANX HUB] Gagal load V35:", err) end
end)

task.spawn(function()
    local remotes = game:GetService("ReplicatedStorage"):WaitForChild("Remotes")
    local windowFolder = remotes:WaitForChild("Window")
    local fastVaultEvent = windowFolder:WaitForChild("fastvault")
    while task.wait(0.5) do
        if FastVaultEnabled then
            pcall(function() fastVaultEvent:FireServer(LP) end)
        end
    end
end)

-- ============================================================
-- AUTO PARRY ENGINE
-- ============================================================
local AutoParryEnabled = false
local AutoParry = { Pending = false, Seen = setmetatable({}, {__mode = "k"}), LastParry = 0, Cooldown = 0.15, Delay = 0.01, Range = 15, Conn = nil }

local function AP_IsAttack(track)
    if track.Looped then return false end
    local priority = track.Priority
    if not (priority == Enum.AnimationPriority.Action or priority == Enum.AnimationPriority.Action2) then return false end
    local n = track.Name:lower()
    if n:find("aim") or n:find("shoot") or n:find("throw") or n:find("spear") or n:find("gun") or n:find("range") or n:find("cast") then return false end
    if n:find("pallet") or n:find("break") or n:find("vault") or n:find("stun") then return false end
    return true
end

local function AP_Press()
    if not AutoParryEnabled then return end
    local char = LP.Character
    if not char then return end
    local remotes = game:GetService("ReplicatedStorage"):FindFirstChild("Remotes")
    local items = remotes and remotes:FindFirstChild("Items")
    local dagger = items and items:FindFirstChild("Parrying Dagger")
    local parryEvent = dagger and dagger:FindFirstChild("parry")
    if parryEvent then pcall(function() parryEvent:FireServer(char) end) return end
    
    local tool = char:FindFirstChildOfClass("Tool")
    if tool and tool.Name:lower():find("parry") then
        pcall(function() tool:Activate() end)
        return 
    end

    pcall(function()
        game:GetService("VirtualInputManager"):SendKeyEvent(true, Enum.KeyCode.F, false, game)
        task.wait(0.01)
        game:GetService("VirtualInputManager"):SendKeyEvent(false, Enum.KeyCode.F, false, game)
    end)
end

local function AP_Start()
    if AutoParry.Conn then AutoParry.Conn:Disconnect() end
    AutoParry.Conn = RunService.Heartbeat:Connect(function()
        if not AutoParryEnabled or AutoParry.Pending then return end
        local char = LP.Character
        local root = char and char:FindFirstChild("HumanoidRootPart")
        if not root then return end
        for _, p in ipairs(Players:GetPlayers()) do
            if p ~= LP and p.Character and p.Team and p.Team.Name:lower():find("killer") then
                local tr = p.Character:FindFirstChild("HumanoidRootPart")
                local hum = p.Character:FindFirstChildOfClass("Humanoid")
                if tr and hum and (tr.Position - root.Position).Magnitude <= AutoParry.Range then
                    for _, track in ipairs(hum:GetPlayingAnimationTracks()) do
                        if not AutoParry.Seen[track] then
                            AutoParry.Seen[track] = true
                            if track.TimePosition <= 0.2 and AP_IsAttack(track) and os.clock() - AutoParry.LastParry >= AutoParry.Cooldown then
                                AutoParry.LastParry = os.clock(); AutoParry.Pending = true
                                task.delay(AutoParry.Delay, function() AP_Press(); AutoParry.Pending = false end)
                            end
                        end
                    end
                end
            end
        end
    end)
end

-- ============================================================
-- AUTO SKILLCHECK GENERATOR (FIXED)
-- ============================================================
_G.HanxAutoGen = false
task.spawn(function()
    local remotes = game:GetService("ReplicatedStorage"):WaitForChild("Remotes")
    local healing = remotes:WaitForChild("Healing")
    while task.wait(0.005) do
        if _G.HanxAutoGen then
            local char = LP.Character
            if char then
                local gui = LP.PlayerGui:FindFirstChild("SkillCheckPromptGui") or game:GetService("CoreGui"):FindFirstChild("SkillCheckPromptGui")
                if gui then
                    local check = gui:FindFirstChild("Check")
                    if check and check.Visible then
                        local line = check:FindFirstChild("Line")
                        local goal = check:FindFirstChild("Goal")
                        if line and goal then
                            line.Rotation = goal.Rotation
                            pcall(function()
                                game:GetService("VirtualInputManager"):SendKeyEvent(true, Enum.KeyCode.Space, false, game)
                                task.wait(0.02)
                                game:GetService("VirtualInputManager"):SendKeyEvent(false, Enum.KeyCode.Space, false, game)
                            end)
                        end
                    end
                end
            end
        end
    end
end)

local KEY_URL = "https://pastebin.com/raw/SRq2TniP"
local AD_LINK = "https:///move2link.com/hanxhub"
local YOUTUBE_LINK = "https://youtube.com/@hannxhub"
local SAWERIA_LINK = "https://saweria.co/hanxhub"
local DISCORD_LINK = "https://discord.gg/hanxhub"

local HanxUI = {}
HanxUI.__index = HanxUI

HanxUI.Theme = {
    Bg = Color3.fromRGB(12, 12, 14),
    Sidebar = Color3.fromRGB(18, 18, 20),
    Card = Color3.fromRGB(22, 22, 26),
    Accent = Color3.fromRGB(200, 30, 30),
    Text = Color3.fromRGB(240, 240, 240),
    TextDim = Color3.fromRGB(140, 140, 150),
    ToggleBg = Color3.fromRGB(45, 45, 50),
    Font = Enum.Font.GothamMedium,
    FontBold = Enum.Font.GothamBold,
    FontBlack = Enum.Font.GothamBlack
}

local function create(className, props)
    local obj = Instance.new(className)
    for key, value in pairs(props or {}) do
        obj[key] = value
    end
    return obj
end

local function round(obj, radius)
    create("UICorner", {
        CornerRadius = UDim.new(0, radius or 6),
        Parent = obj
    })
end

local function dragify(frame, handle)
    local dragging = false
    local dragInput
    local dragStart
    local startPos

    handle.InputBegan:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1
        or input.UserInputType == Enum.UserInputType.Touch then
            dragging = true
            dragStart = input.Position
            startPos = frame.Position

            input.Changed:Connect(function()
                if input.UserInputState == Enum.UserInputState.End then
                    dragging = false
                end
            end)
        end
    end)

    handle.InputChanged:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseMovement
        or input.UserInputType == Enum.UserInputType.Touch then
            dragInput = input
        end
    end)

    UIS.InputChanged:Connect(function(input)
        if input == dragInput and dragging then
            local delta = input.Position - dragStart
            frame.Position = UDim2.new(
                startPos.X.Scale,
                startPos.X.Offset + delta.X,
                startPos.Y.Scale,
                startPos.Y.Offset + delta.Y
            )
        end
    end)
end

function HanxUI.new(title, subtitle)
    local playerGui = LP:WaitForChild("PlayerGui")
    local oldGui = playerGui:FindFirstChild("HanxUI_Main")
    if oldGui then oldGui:Destroy() end

    local window = setmetatable({}, HanxUI)
    window.Tabs = {}

    local gui = create("ScreenGui", {
        Name = "HanxUI_Main",
        ResetOnSpawn = false,
        ZIndexBehavior = Enum.ZIndexBehavior.Sibling,
        Parent = playerGui
    })

    create("TextLabel", {
        Size = UDim2.new(0, 200, 0, 30),
        Position = UDim2.new(0, 20, 0, 20),
        BackgroundTransparency = 1,
        Text = "HANX HUB",
        TextColor3 = HanxUI.Theme.Accent,
        Font = HanxUI.Theme.FontBlack,
        TextSize = 20,
        TextXAlignment = Enum.TextXAlignment.Left,
        Parent = gui
    })

    local main = create("Frame", {
        Name = "Main",
        Size = UDim2.new(0, 680, 0, 460),
        Position = UDim2.new(0.5, -340, 0.5, -230),
        BackgroundColor3 = HanxUI.Theme.Bg,
        BorderSizePixel = 0,
        Parent = gui
    })
    round(main, 12)

    create("UIStroke", {
        Color = HanxUI.Theme.Accent,
        Thickness = 1.5,
        Transparency = 0.5,
        Parent = main
    })

    local header = create("Frame", {
        Size = UDim2.new(1, 0, 0, 60),
        BackgroundTransparency = 1,
        Parent = main,
        ZIndex = 5
    })

    local dragArea = create("TextButton", {
        Size = UDim2.new(1, -100, 1, 0),
        BackgroundTransparency = 1,
        Text = "",
        Parent = header,
        ZIndex = 5
    })

    create("TextLabel", {
        Size = UDim2.new(1, -60, 0, 30),
        Position = UDim2.new(0, 20, 0, 12),
        BackgroundTransparency = 1,
        Text = title or "HANX HUB",
        TextColor3 = HanxUI.Theme.Text,
        Font = HanxUI.Theme.FontBlack,
        TextSize = 24,
        TextXAlignment = Enum.TextXAlignment.Left,
        Parent = header,
        ZIndex = 5
    })

    create("TextLabel", {
        Size = UDim2.new(1, -60, 0, 15),
        Position = UDim2.new(0, 20, 0, 38),
        BackgroundTransparency = 1,
        Text = subtitle or "",
        TextColor3 = HanxUI.Theme.Accent,
        Font = HanxUI.Theme.Font,
        TextSize = 11,
        TextXAlignment = Enum.TextXAlignment.Left,
        Parent = header,
        ZIndex = 5
    })

    local btnContainer = create("Frame", {
        Size = UDim2.new(0, 60, 0, 30),
        Position = UDim2.new(1, -65, 0, 15),
        BackgroundTransparency = 1,
        Parent = header,
        ZIndex = 10
    })

    local minBtn = create("TextButton", {
        Size = UDim2.new(0, 25, 0, 25),
        BackgroundTransparency = 1,
        Text = "—",
        TextColor3 = HanxUI.Theme.TextDim,
        Font = HanxUI.Theme.FontBold,
        TextSize = 16,
        Parent = btnContainer,
        ZIndex = 10
    })

    local closeBtn = create("TextButton", {
        Size = UDim2.new(0, 25, 0, 25),
        Position = UDim2.new(0, 30, 0, 0),
        BackgroundTransparency = 1,
        Text = "×",
        TextColor3 = HanxUI.Theme.TextDim,
        Font = HanxUI.Theme.FontBold,
        TextSize = 20,
        Parent = btnContainer,
        ZIndex = 10
    })

    local tray = create("TextButton", {
        Size = UDim2.new(0, 220, 0, 45),
        Position = UDim2.new(0.5, -110, 0, 20),
        BackgroundColor3 = HanxUI.Theme.Card,
        Text = "HANX HUB  |  Click to open",
        TextColor3 = HanxUI.Theme.Text,
        Font = HanxUI.Theme.FontBold,
        TextSize = 12,
        Visible = false,
        Parent = gui,
        ZIndex = 10
    })
    round(tray, 25)
    create("UIStroke", {
        Color = HanxUI.Theme.Accent,
        Thickness = 1,
        Parent = tray
    })
    dragify(tray, tray)

    local minimized = false
    local function toggleMinimize()
        minimized = not minimized
        main.Visible = not minimized
        tray.Visible = minimized
    end

    minBtn.MouseButton1Click:Connect(toggleMinimize)
    tray.MouseButton1Click:Connect(toggleMinimize)
    closeBtn.MouseButton1Click:Connect(function()
        gui:Destroy()
    end)

    local sidebar = create("Frame", {
        Name = "Sidebar",
        Size = UDim2.new(0, 135, 1, -70),
        Position = UDim2.new(0, 10, 0, 65),
        BackgroundColor3 = HanxUI.Theme.Sidebar,
        BorderSizePixel = 0,
        ZIndex = 5,
        Parent = main
    })
    round(sidebar, 10)
    create("UIStroke", {
        Color = Color3.fromRGB(40, 40, 45),
        Thickness = 1,
        Parent = sidebar
    })
    create("UIListLayout", {
        Padding = UDim.new(0, 10),
        SortOrder = Enum.SortOrder.LayoutOrder,
        HorizontalAlignment = Enum.HorizontalAlignment.Center,
        Parent = sidebar
    })
    create("UIPadding", {
        PaddingTop = UDim.new(0, 20),
        PaddingLeft = UDim.new(0, 6),
        PaddingRight = UDim.new(0, 6),
        Parent = sidebar
    })

    local content = create("Frame", {
        Name = "Content",
        Size = UDim2.new(1, -165, 1, -80),
        Position = UDim2.new(0, 155, 0, 65),
        BackgroundTransparency = 1,
        ZIndex = 1,
        Parent = main
    })

    dragify(main, dragArea)

    window.Gui = gui
    window.Main = main

    function window:SelectTab(tab)
        for _, item in ipairs(self.Tabs) do
            item.Frame.Visible = false
            TweenService:Create(item.Btn, TweenInfo.new(0.15), {
                BackgroundColor3 = HanxUI.Theme.Sidebar,
                TextColor3 = HanxUI.Theme.TextDim
            }):Play()
        end

        tab.Frame.Visible = true
        TweenService:Create(tab.Btn, TweenInfo.new(0.15), {
            BackgroundColor3 = HanxUI.Theme.Accent,
            TextColor3 = HanxUI.Theme.Text
        }):Play()
        self.ActiveTab = tab
    end

    function window:AddTab(iconText, name)
        local btn = create("TextButton", {
            Size = UDim2.new(1, 0, 0, 40),
            BackgroundColor3 = HanxUI.Theme.Sidebar,
            Text = tostring(iconText) .. "   " .. string.upper(name),
            TextColor3 = HanxUI.Theme.TextDim,
            Font = HanxUI.Theme.FontBold,
            TextSize = 12,
            TextXAlignment = Enum.TextXAlignment.Left,
            AutoButtonColor = false,
            ZIndex = 6,
            Parent = sidebar
        })
        round(btn, 8)
        create("UIPadding", {
            PaddingLeft = UDim.new(0, 10),
            Parent = btn
        })

        btn.MouseEnter:Connect(function()
            if self.ActiveTab ~= nil and self.ActiveTab.Btn ~= btn then
                TweenService:Create(btn, TweenInfo.new(0.1), {
                    BackgroundColor3 = Color3.fromRGB(30, 30, 35)
                }):Play()
            end
        end)

        btn.MouseLeave:Connect(function()
            if self.ActiveTab ~= nil and self.ActiveTab.Btn ~= btn then
                TweenService:Create(btn, TweenInfo.new(0.1), {
                    BackgroundColor3 = HanxUI.Theme.Sidebar
                }):Play()
            end
        end)

        local tabFrame = create("ScrollingFrame", {
            Size = UDim2.new(1, 0, 1, 0),
            BackgroundTransparency = 1,
            BorderSizePixel = 0,
            ScrollBarThickness = 3,
            ScrollBarImageColor3 = HanxUI.Theme.Accent,
            CanvasSize = UDim2.new(0, 0, 0, 0),
            AutomaticCanvasSize = Enum.AutomaticSize.Y,
            Visible = false,
            ZIndex = 1,
            Parent = content
        })

        create("UIPadding", {
            PaddingTop = UDim.new(0, 5),
            PaddingBottom = UDim.new(0, 10),
            PaddingRight = UDim.new(0, 10),
            Parent = tabFrame
        })

        create("UIListLayout", {
            Padding = UDim.new(0, 15),
            SortOrder = Enum.SortOrder.LayoutOrder,
            Parent = tabFrame
        })

        local tabObj = {
            Frame = tabFrame,
            Btn = btn,
            Name = name
        }

        btn.MouseButton1Click:Connect(function()
            self:SelectTab(tabObj)
        end)

        table.insert(self.Tabs, tabObj)

        if #self.Tabs == 1 then
            self:SelectTab(tabObj)
        end

        return tabObj
    end

    return window
end

function HanxUI:AddCard(tab, title)
    local card = create("Frame", {
        Size = UDim2.new(1, 0, 0, 0),
        AutomaticSize = Enum.AutomaticSize.Y,
        BackgroundColor3 = HanxUI.Theme.Card,
        BorderSizePixel = 0,
        Parent = tab.Frame
    })
    round(card, 8)
    create("UIStroke", {
        Color = Color3.fromRGB(40, 40, 45),
        Thickness = 1,
        Parent = card
    })

    create("UIPadding", {
        PaddingTop = UDim.new(0, 12),
        PaddingLeft = UDim.new(0, 15),
        PaddingRight = UDim.new(0, 15),
        PaddingBottom = UDim.new(0, 12),
        Parent = card
    })

    create("UIListLayout", {
        Padding = UDim.new(0, 7),
        SortOrder = Enum.SortOrder.LayoutOrder,
        Parent = card
    })

    create("TextLabel", {
        Size = UDim2.new(1, 0, 0, 20),
        BackgroundTransparency = 1,
        Text = string.upper(title),
        TextColor3 = HanxUI.Theme.Text,
        Font = HanxUI.Theme.FontBold,
        TextSize = 12,
        TextXAlignment = Enum.TextXAlignment.Left,
        Parent = card
    })

    create("Frame", {
        Size = UDim2.new(1, 0, 0, 1),
        BackgroundColor3 = HanxUI.Theme.Accent,
        BackgroundTransparency = 0.5,
        BorderSizePixel = 0,
        Parent = card
    })

    return card
end

function HanxUI:AddToggle(parentCard, labelText, default, callback)
    local frame = create("Frame", {
        Size = UDim2.new(1, 0, 0, 25),
        BackgroundTransparency = 1,
        Parent = parentCard
    })

    create("TextLabel", {
        Size = UDim2.new(1, -50, 1, 0),
        BackgroundTransparency = 1,
        Text = labelText,
        TextColor3 = HanxUI.Theme.Text,
        Font = HanxUI.Theme.Font,
        TextSize = 12,
        TextXAlignment = Enum.TextXAlignment.Left,
        Parent = frame
    })

    local state = default == true
    local toggle = create("Frame", {
        Size = UDim2.new(0, 36, 0, 20),
        Position = UDim2.new(1, -36, 0.5, -10),
        BackgroundColor3 = state and HanxUI.Theme.Accent or HanxUI.Theme.ToggleBg,
        Parent = frame
    })
    round(toggle, 10)

    local circle = create("Frame", {
        Size = UDim2.new(0, 16, 0, 16),
        Position = state and UDim2.new(1, -18, 0.5, -8) or UDim2.new(0, 2, 0.5, -8),
        BackgroundColor3 = state and HanxUI.Theme.Text or HanxUI.Theme.TextDim,
        Parent = toggle
    })
    round(circle, 10)

    local hitbox = create("TextButton", {
        Size = UDim2.new(1, 0, 1, 0),
        BackgroundTransparency = 1,
        Text = "",
        Parent = frame
    })

    hitbox.MouseButton1Click:Connect(function()
        state = not state
        TweenService:Create(toggle, TweenInfo.new(0.2), {
            BackgroundColor3 = state and HanxUI.Theme.Accent or HanxUI.Theme.ToggleBg
        }):Play()
        TweenService:Create(circle, TweenInfo.new(0.2), {
            Position = state and UDim2.new(1, -18, 0.5, -8) or UDim2.new(0, 2, 0.5, -8),
            BackgroundColor3 = state and HanxUI.Theme.Text or HanxUI.Theme.TextDim
        }):Play()

        if callback then callback(state) end
    end)
end

-- SLIDER DIUBAH JADI TEXTBOX (Ketik Angka)
function HanxUI:AddInput(parentCard, labelText, defaultValue, callback)
    local frame = create("Frame", {
        Size = UDim2.new(1, 0, 0, 30),
        BackgroundTransparency = 1,
        Parent = parentCard
    })

    local label = create("TextLabel", {
        Size = UDim2.new(1, -80, 1, 0),
        BackgroundTransparency = 1,
        Text = labelText,
        TextColor3 = HanxUI.Theme.Text,
        Font = HanxUI.Theme.Font,
        TextSize = 12,
        TextXAlignment = Enum.TextXAlignment.Left,
        Parent = frame
    })

    local boxFrame = create("Frame", {
        Size = UDim2.new(0, 60, 0, 24),
        Position = UDim2.new(1, -60, 0.5, -12),
        BackgroundColor3 = HanxUI.Theme.ToggleBg,
        Parent = frame
    })
    round(boxFrame, 6)

    local box = create("TextBox", {
        Size = UDim2.new(1, 0, 1, 0),
        BackgroundTransparency = 1,
        Text = tostring(defaultValue),
        TextColor3 = HanxUI.Theme.Text,
        Font = HanxUI.Theme.FontBold,
        TextSize = 12,
        TextXAlignment = Enum.TextXAlignment.Center,
        ClearTextOnFocus = false,
        Parent = boxFrame
    })

    box.FocusLost:Connect(function()
        local num = tonumber(box.Text)
        if num then
            if callback then callback(num) end
        else
            box.Text = tostring(defaultValue) -- Balikin ke angka awal kalau bukan angka
        end
    end)
end

function HanxUI:AddSlider(parentCard, labelText, minValue, maxValue, defaultValue, callback)
    local frame = create("Frame", {
        Size = UDim2.new(1, 0, 0, 42),
        BackgroundTransparency = 1,
        Parent = parentCard
    })

    local label = create("TextLabel", {
        Size = UDim2.new(1, 0, 0, 20),
        BackgroundTransparency = 1,
        Text = labelText .. ": " .. tostring(defaultValue),
        TextColor3 = HanxUI.Theme.Text,
        Font = HanxUI.Theme.Font,
        TextSize = 12,
        TextXAlignment = Enum.TextXAlignment.Left,
        Parent = frame
    })

    local bar = create("Frame", {
        Size = UDim2.new(1, 0, 0, 5),
        Position = UDim2.new(0, 0, 0, 27),
        BackgroundColor3 = HanxUI.Theme.ToggleBg,
        Parent = frame
    })
    round(bar, 3)

    local initial = math.clamp((defaultValue - minValue) / (maxValue - minValue), 0, 1)
    local fill = create("Frame", {
        Size = UDim2.new(initial, 0, 1, 0),
        BackgroundColor3 = HanxUI.Theme.Accent,
        Parent = bar
    })
    round(fill, 3)

    local dragging = false

    local function update(input)
        if bar.AbsoluteSize.X <= 0 then return end
        local pos = math.clamp(
            (input.Position.X - bar.AbsolutePosition.X) / bar.AbsoluteSize.X,
            0,
            1
        )
        local value = math.floor(minValue + ((maxValue - minValue) * pos))
        fill.Size = UDim2.new(pos, 0, 1, 0)
        label.Text = labelText .. ": " .. tostring(value)
        if callback then callback(value) end
    end

    bar.InputBegan:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1
        or input.UserInputType == Enum.UserInputType.Touch then
            dragging = true
            update(input)
        end
    end)

    UIS.InputChanged:Connect(function(input)
        if dragging and (
            input.UserInputType == Enum.UserInputType.MouseMovement
            or input.UserInputType == Enum.UserInputType.Touch
        ) then
            update(input)
        end
    end)

    UIS.InputEnded:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1
        or input.UserInputType == Enum.UserInputType.Touch then
            dragging = false
        end
    end)
end

function HanxUI:AddButton(parentCard, labelText, callback)
    local btn = create("TextButton", {
        Size = UDim2.new(1, 0, 0, 35),
        BackgroundColor3 = HanxUI.Theme.Accent,
        Text = labelText,
        TextColor3 = HanxUI.Theme.Text,
        Font = HanxUI.Theme.FontBold,
        TextSize = 12,
        AutoButtonColor = false,
        Parent = parentCard
    })
    round(btn, 6)

    create("UIStroke", {
        Color = Color3.fromRGB(255, 255, 255),
        Transparency = 0.8,
        Parent = btn
    })

    btn.MouseEnter:Connect(function()
        TweenService:Create(btn, TweenInfo.new(0.1), {
            BackgroundColor3 = Color3.fromRGB(220, 40, 40)
        }):Play()
    end)

    btn.MouseLeave:Connect(function()
        TweenService:Create(btn, TweenInfo.new(0.1), {
            BackgroundColor3 = HanxUI.Theme.Accent
        }):Play()
    end)

    btn.MouseButton1Click:Connect(function()
        if callback then callback() end
    end)
end

-- KEY SYSTEM
local function ShowKeyPrompt(callback)
    local playerGui = LP:WaitForChild("PlayerGui")
    local oldAuth = playerGui:FindFirstChild("HanxAuth")
    if oldAuth then oldAuth:Destroy() end

    local authGui = create("ScreenGui", {
        Name = "HanxAuth",
        ResetOnSpawn = false,
        Parent = playerGui
    })

    local frame = create("Frame", {
        Size = UDim2.new(0, 340, 0, 240),
        Position = UDim2.new(0.5, -170, 0.5, -120),
        BackgroundColor3 = HanxUI.Theme.Bg,
        Parent = authGui
    })
    round(frame, 12)
    create("UIStroke", {
        Thickness = 1.5,
        Color = HanxUI.Theme.Accent,
        Parent = frame
    })

    create("TextLabel", {
        Size = UDim2.new(1, 0, 0, 45),
        BackgroundTransparency = 1,
        Text = "HANX HUB",
        TextColor3 = HanxUI.Theme.Text,
        Font = Enum.Font.GothamBlack,
        TextSize = 22,
        Parent = frame
    })

    create("TextLabel", {
        Size = UDim2.new(1, 0, 0, 15),
        Position = UDim2.new(0, 0, 0, 40),
        BackgroundTransparency = 1,
        Text = "Premium Script Access",
        TextColor3 = HanxUI.Theme.Accent,
        Font = Enum.Font.Gotham,
        TextSize = 10,
        Parent = frame
    })

    local getKeyBtn = create("TextButton", {
        Size = UDim2.new(0.85, 0, 0, 36),
        Position = UDim2.new(0.075, 0, 0.25, 0),
        BackgroundColor3 = Color3.fromRGB(35, 160, 35),
        Text = "GET KEY HERE",
        TextColor3 = HanxUI.Theme.Text,
        Font = Enum.Font.GothamBold,
        TextSize = 13,
        AutoButtonColor = false,
        Parent = frame
    })
    round(getKeyBtn, 8)

    getKeyBtn.MouseButton1Click:Connect(function()
        if setclipboard then
            setclipboard(AD_LINK)
            getKeyBtn.Text = "LINK COPIED!"
        else
            getKeyBtn.Text = "CLIPBOARD NOT SUPPORTED"
        end
        task.delay(2, function()
            if getKeyBtn and getKeyBtn.Parent then
                getKeyBtn.Text = "GET KEY HERE"
            end
        end)
    end)

    local inputFrame = create("Frame", {
        Size = UDim2.new(0.85, 0, 0, 40),
        Position = UDim2.new(0.075, 0, 0.45, 0),
        BackgroundColor3 = HanxUI.Theme.Card,
        Parent = frame
    })
    round(inputFrame, 8)

    local input = create("TextBox", {
        Size = UDim2.new(1, -20, 1, 0),
        Position = UDim2.new(0, 10, 0, 0),
        BackgroundTransparency = 1,
        Text = "",
        PlaceholderText = "Masukkan Key...",
        PlaceholderColor3 = Color3.fromRGB(150, 150, 160),
        TextColor3 = HanxUI.Theme.Text,
        Font = Enum.Font.Gotham,
        TextSize = 14,
        TextXAlignment = Enum.TextXAlignment.Left,
        ClearTextOnFocus = false,
        Parent = inputFrame
    })

    local verifyBtn = create("TextButton", {
        Size = UDim2.new(0.85, 0, 0, 36),
        Position = UDim2.new(0.075, 0, 0.65, 0),
        BackgroundColor3 = HanxUI.Theme.Accent,
        Text = "VERIFY ACCESS",
        TextColor3 = HanxUI.Theme.Text,
        Font = Enum.Font.GothamBold,
        TextSize = 13,
        AutoButtonColor = false,
        Parent = frame
    })
    round(verifyBtn, 8)

    create("TextLabel", {
        Size = UDim2.new(1, 0, 0, 20),
        Position = UDim2.new(0, 0, 1, -25),
        BackgroundTransparency = 1,
        Text = "Protected by Move2Link | HANX HUB",
        TextColor3 = Color3.fromRGB(80, 80, 90),
        Font = Enum.Font.Gotham,
        TextSize = 10,
        Parent = frame
    })

    verifyBtn.MouseButton1Click:Connect(function()
        verifyBtn.Text = "CHECKING..."
        verifyBtn.BackgroundColor3 = Color3.fromRGB(40, 40, 40)

        local success, result = pcall(function()
            if syn and syn.request then
                local r = syn.request({Url = KEY_URL, Method = "GET"})
                return r and r.Body or nil
            elseif http and http.request then
                local r = http.request({Url = KEY_URL, Method = "GET"})
                return r and r.Body or nil
            elseif request then
                local r = request({Url = KEY_URL, Method = "GET"})
                return r and r.Body or nil
            else
                return game:HttpGet(KEY_URL)
            end
        end)

        if not success or type(result) ~= "string" then
            verifyBtn.Text = "NETWORK ERROR"
            verifyBtn.BackgroundColor3 = Color3.fromRGB(200, 40, 40)
            return
        end

        local rawKey = ""
        for line in string.gmatch(result, "[^\r\n]+") do
            local cleaned = string.match(line, "^%s*(.-)%s*$")
            if cleaned and cleaned ~= "" then
                rawKey = cleaned
            end
        end

        local cleanKey = string.lower(string.gsub(rawKey, "[^%w%-]", ""))
        local userInput = string.lower(string.gsub(input.Text, "[^%w%-]", ""))

        if cleanKey ~= "" and userInput == cleanKey then
            verifyBtn.Text = "ACCESS GRANTED"
            verifyBtn.BackgroundColor3 = Color3.fromRGB(35, 160, 35)
            task.wait(0.5)
            authGui:Destroy()
            callback()
        else
            verifyBtn.Text = "WRONG KEY!"
            verifyBtn.BackgroundColor3 = Color3.fromRGB(200, 40, 40)
            task.delay(1, function()
                if verifyBtn and verifyBtn.Parent then
                    verifyBtn.Text = "VERIFY ACCESS"
                    verifyBtn.BackgroundColor3 = HanxUI.Theme.Accent
                end
            end)
        end
    end)
end

-- FEATURE ENGINE
local HanxFeature = {}
HanxFeature.__index = HanxFeature

function HanxFeature.new()
    return setmetatable({
        State = {
            Fly = false,
            FlySpeed = 100,
            Noclip = false,
            InfJump = false,
            ESP_Player = false,
            ESP_Killer = false,
            ESP_Object = false,
            AutoSkillcheckGen = false
        },
        ESPObjects = {}
    }, HanxFeature)
end

function HanxFeature:ToggleFly(state)
    self.State.Fly = state

    local char = LP.Character
    if not char then return end

    local hrp = char:FindFirstChild("HumanoidRootPart")
    local hum = char:FindFirstChildOfClass("Humanoid")
    if not hrp or not hum then return end

    if state then
        if self.FlyConn then self.FlyConn:Disconnect() end

        local att = Instance.new("Attachment")
        att.Name = "HanxFlyAttachment"
        att.Parent = hrp

        local pos = Instance.new("AlignPosition")
        pos.Name = "HanxFlyPosition"
        pos.Attachment0 = att
        pos.Mode = Enum.PositionAlignmentMode.OneAttachment
        pos.MaxForce = 100000
        pos.Position = hrp.Position
        pos.Responsiveness = 50
        pos.Parent = hrp

        local ori = Instance.new("AlignOrientation")
        ori.Name = "HanxFlyOrientation"
        ori.Attachment0 = att
        ori.Mode = Enum.OrientationAlignmentMode.OneAttachment
        ori.MaxTorque = 100000
        ori.Responsiveness = 50
        ori.Parent = hrp

        hum.PlatformStand = true

        self.FlyConn = RunService.Heartbeat:Connect(function(dt)
            if not self.State.Fly or not hrp.Parent then return end

            local cam = workspace.CurrentCamera
            if not cam then return end
            local direction = Vector3.zero

            if UIS:IsKeyDown(Enum.KeyCode.W) then direction += cam.CFrame.LookVector end
            if UIS:IsKeyDown(Enum.KeyCode.S) then direction -= cam.CFrame.LookVector end
            if UIS:IsKeyDown(Enum.KeyCode.A) then direction -= cam.CFrame.RightVector end
            if UIS:IsKeyDown(Enum.KeyCode.D) then direction += cam.CFrame.RightVector end
            if UIS:IsKeyDown(Enum.KeyCode.Space) then direction += Vector3.yAxis end
            if UIS:IsKeyDown(Enum.KeyCode.LeftControl) then direction -= Vector3.yAxis end

            if hum.MoveDirection.Magnitude > 0 then
                direction += hum.MoveDirection
            end

            if direction.Magnitude > 0 then
                pos.Position += direction.Unit * self.State.FlySpeed * dt
            end

            ori.CFrame = cam.CFrame
        end)
    else
        if self.FlyConn then
            self.FlyConn:Disconnect()
            self.FlyConn = nil
        end

        for _, name in ipairs({
            "HanxFlyPosition",
            "HanxFlyOrientation",
            "HanxFlyAttachment"
        }) do
            local object = hrp:FindFirstChild(name)
            if object then object:Destroy() end
        end

        hum.PlatformStand = false
    end
end

function HanxFeature:ToggleNoclip(state)
    self.State.Noclip = state

    if state then
        if self.NoclipConn then self.NoclipConn:Disconnect() end
        self.NoclipConn = RunService.Stepped:Connect(function()
            local char = LP.Character
            if char then
                for _, part in ipairs(char:GetDescendants()) do
                    if part:IsA("BasePart") then
                        part.CanCollide = false
                    end
                end
            end
        end)
    else
        if self.NoclipConn then
            self.NoclipConn:Disconnect()
            self.NoclipConn = nil
        end
        local char = LP.Character
        if char then
            for _, part in ipairs(char:GetDescendants()) do
                if part:IsA("BasePart") and part.Name ~= "HumanoidRootPart" then
                    part.CanCollide = true
                end
            end
        end
    end
end

function HanxFeature:UpdateESP()
    local anyEnabled = self.State.ESP_Player or self.State.ESP_Killer or self.State.ESP_Object

    if self.ESPConn then
        self.ESPConn:Disconnect()
        self.ESPConn = nil
    end

    for inst, highlight in pairs(self.ESPObjects) do
        if highlight and highlight.Parent then
            if not anyEnabled then
                highlight:Destroy()
                self.ESPObjects[inst] = nil
            else
                if inst:IsA("Player") then
                    local isKiller = inst.Team and inst.Team.Name:lower():find("killer")
                    if (isKiller and not self.State.ESP_Killer) or (not isKiller and not self.State.ESP_Player) then
                        highlight:Destroy()
                        self.ESPObjects[inst] = nil
                    end
                elseif not self.State.ESP_Object then
                    highlight:Destroy()
                    self.ESPObjects[inst] = nil
                end
            end
        end
    end

    if not anyEnabled then return end

    self.ESPConn = RunService.RenderStepped:Connect(function()
        for _, player in ipairs(Players:GetPlayers()) do
            if player ~= LP and player.Character then
                local isKiller = player.Team and player.Team.Name:lower():find("killer")
                local shouldRender = (isKiller and self.State.ESP_Killer) or (not isKiller and self.State.ESP_Player)
                
                local highlight = self.ESPObjects[player]
                if shouldRender then
                    if not highlight or not highlight.Parent then
                        highlight = Instance.new("Highlight")
                        highlight.Name = "HanxPlayerESP"
                        highlight.FillColor = isKiller and Color3.fromRGB(255, 50, 50) or Color3.fromRGB(50, 200, 100)
                        highlight.OutlineColor = Color3.fromRGB(255, 255, 255)
                        highlight.FillTransparency = 0.5
                        highlight.Adornee = player.Character
                        highlight.Parent = player.Character
                        self.ESPObjects[player] = highlight
                    elseif highlight.Adornee ~= player.Character then
                        highlight.Adornee = player.Character
                        highlight.Parent = player.Character
                    end
                elseif highlight then
                    highlight:Destroy()
                    self.ESPObjects[player] = nil
                end
            end
        end

        if self.State.ESP_Object then
            local map = workspace:FindFirstChild("Map")
            if map then
                for _, obj in ipairs(map:GetDescendants()) do
                    if (obj.Name == "PrimaryPartPallet" or obj.Name:find("Generator")) and obj:IsA("BasePart") then
                        local highlight = self.ESPObjects[obj]
                        if not highlight or not highlight.Parent then
                            highlight = Instance.new("Highlight")
                            highlight.Name = "HanxObjectESP"
                            highlight.FillColor = Color3.fromRGB(255, 200, 50)
                            highlight.OutlineColor = Color3.fromRGB(0, 0, 0)
                            highlight.FillTransparency = 0.6
                            highlight.Adornee = obj
                            highlight.Parent = obj
                            self.ESPObjects[obj] = highlight
                        end
                    end
                end
            end
        end
    end)
end

function HanxFeature:TeleportToNearest()
    local char = LP.Character
    local hrp = char and char:FindFirstChild("HumanoidRootPart")
    if not hrp then return end

    local closestRoot
    local shortestDistance = math.huge

    for _, player in ipairs(Players:GetPlayers()) do
        if player ~= LP and player.Character then
            local targetRoot = player.Character:FindFirstChild("HumanoidRootPart")
            if targetRoot then
                local distance = (hrp.Position - targetRoot.Position).Magnitude
                if distance < shortestDistance then
                    shortestDistance = distance
                    closestRoot = targetRoot
                end
            end
        end
    end

    if closestRoot then
        hrp.CFrame = closestRoot.CFrame + Vector3.new(0, 5, 0)
    end
end

-- BUILD UI
ShowKeyPrompt(function()
    local Window = HanxUI.new("HANX HUB", "v17.5 | Premium Edition")

    local TabHome = Window:AddTab("🏠", "Home")
    local TabSurvivor = Window:AddTab("🏃", "Survivor")
    local TabKiller = Window:AddTab("🔪", "Killer")
    local TabESP = Window:AddTab("👁", "ESP")
    local TabSettings = Window:AddTab("⚙", "Settings")
    local TabSocial = Window:AddTab("🌐", "Media Social")

    local Feature = HanxFeature.new()

    local function homeLabel(parent, text, options)
        options = options or {}
        return create("TextLabel", {
            Size = options.size or UDim2.new(1, 0, 0, options.height or 18),
            BackgroundTransparency = 1,
            Text = text,
            TextColor3 = options.color or HanxUI.Theme.TextDim,
            Font = options.font or HanxUI.Theme.Font,
            TextSize = options.textSize or 11,
            TextWrapped = options.wrapped or false,
            TextXAlignment = Enum.TextXAlignment.Left,
            TextYAlignment = Enum.TextYAlignment.Top,
            Parent = parent
        })
    end

    -- PROFILE CARD
    local profileCard = HanxUI:AddCard(TabHome, "ROBLOX PROFILE")

    local profileRow = create("Frame", {
        Size = UDim2.new(1, 0, 0, 85),
        BackgroundTransparency = 1,
        Parent = profileCard
    })

    local avatar = create("ImageLabel", {
        Size = UDim2.new(0, 70, 0, 70),
        Position = UDim2.new(0, 0, 0, 5),
        BackgroundColor3 = HanxUI.Theme.Sidebar,
        Image = "",
        ScaleType = Enum.ScaleType.Crop,
        Parent = profileRow
    })
    round(avatar, 12)

    create("UIStroke", {
        Color = HanxUI.Theme.Accent,
        Thickness = 1.5,
        Parent = avatar
    })

    task.spawn(function()
        local success, imageUrl = pcall(function()
            return Players:GetUserThumbnailAsync(
                LP.UserId,
                Enum.ThumbnailType.HeadShot,
                Enum.ThumbnailSize.Size150x150
            )
        end)

        if success and avatar.Parent then
            avatar.Image = imageUrl
        end
    end)

    create("TextLabel", {
        Size = UDim2.new(1, -90, 0, 25),
        Position = UDim2.new(0, 85, 0, 12),
        BackgroundTransparency = 1,
        Text = LP.DisplayName,
        TextColor3 = HanxUI.Theme.Text,
        Font = HanxUI.Theme.FontBlack,
        TextSize = 17,
        TextXAlignment = Enum.TextXAlignment.Left,
        Parent = profileRow
    })

    create("TextLabel", {
        Size = UDim2.new(1, -90, 0, 20),
        Position = UDim2.new(0, 85, 0, 38),
        BackgroundTransparency = 1,
        Text = "@" .. LP.Name,
        TextColor3 = HanxUI.Theme.TextDim,
        Font = HanxUI.Theme.Font,
        TextSize = 12,
        TextXAlignment = Enum.TextXAlignment.Left,
        Parent = profileRow
    })

    create("TextLabel", {
        Size = UDim2.new(1, -90, 0, 18),
        Position = UDim2.new(0, 85, 0, 60),
        BackgroundTransparency = 1,
        Text = "● ROBLOX PLAYER",
        TextColor3 = Color3.fromRGB(50, 200, 100),
        Font = HanxUI.Theme.FontBold,
        TextSize = 10,
        TextXAlignment = Enum.TextXAlignment.Left,
        Parent = profileRow
    })

    -- ACCOUNT INFORMATION
    local accountCard = HanxUI:AddCard(TabHome, "ACCOUNT INFORMATION")

    homeLabel(accountCard, "Username: " .. LP.Name, {
        color = HanxUI.Theme.Text,
        height = 22
    })

    homeLabel(accountCard, "Display Name: " .. LP.DisplayName, {
        height = 22
    })

    homeLabel(accountCard, "User ID: " .. tostring(LP.UserId), {
        height = 22
    })

    homeLabel(accountCard, "Account Age: " .. tostring(LP.AccountAge) .. " Days", {
        height = 22
    })

    -- SYSTEM STATUS
    local statusCard = HanxUI:AddCard(TabHome, "SYSTEM STATUS")

    homeLabel(statusCard, "HANX HUB Version: v17.6 Premium", {
        color = HanxUI.Theme.Text,
        height = 22
    })

    homeLabel(statusCard, "Executor: " ..
        (identifyexecutor and identifyexecutor() or "Unknown"), {
        height = 22
    })

    homeLabel(statusCard, "Script Status: Active", {
        color = Color3.fromRGB(50, 200, 100),
        height = 22
    })

    homeLabel(statusCard, "Game: " .. game.Name, {
        height = 22
    })

    -- WELCOME CARD
    local welcomeCard = HanxUI:AddCard(TabHome, "WELCOME TO HANX HUB")

    homeLabel(welcomeCard,
        "Welcome back, " .. LP.DisplayName ..
        "!\nThank you for using HANX HUB Premium.\nEnjoy the interface and explore the available menus.",
        {
            color = HanxUI.Theme.Text,
            height = 48,
            wrapped = true
        }
    )

    -- KILLER MENU
    local killerAction = HanxUI:AddCard(TabKiller, "KILLER ACTIONS")

    HanxUI:AddToggle(killerAction, "Noclip", false, function(value)
        Feature:ToggleNoclip(value)
    end)

    HanxUI:AddButton(killerAction, "Teleport to Nearest Player", function()
        Feature:TeleportToNearest()
    end)

    local killerCombat = HanxUI:AddCard(TabKiller, "KILLER COMBAT")

    -- FAST VAULT UI
    local survivorMove = HanxUI:AddCard(TabSurvivor, "SURVIVOR MECHANICS")

    HanxUI:AddToggle(survivorMove, "Fast Vault", false, function(value)
        FastVaultEnabled = value
        _G.HANX_V35_ENABLED = value
    end)

    -- AUTO SKILLCHECK UI
    local survivorSkill = HanxUI:AddCard(TabSurvivor, "SKILLCHECK SETTINGS")
    
    HanxUI:AddToggle(survivorSkill, "Auto Skillcheck Generator", false, function(value)
        _G.HanxAutoGen = value
        Feature.State.AutoSkillcheckGen = value
    end)

    -- AUTO PARRY UI (PAKAI TEXTBOX)
    local cardSurvCombat = HanxUI:AddCard(TabSurvivor, "AUTO COMBAT")

    HanxUI:AddToggle(cardSurvCombat, "Auto Parry", false, function(value)
        AutoParryEnabled = value
        if value then AP_Start() elseif AutoParry.Conn then AutoParry.Conn:Disconnect() end
    end)
    
    HanxUI:AddInput(cardSurvCombat, "Parry Range", AutoParry.Range, function(value)
        if value > 0 then AutoParry.Range = value end
    end)
    
    HanxUI:AddInput(cardSurvCombat, "Parry Delay (ms)", AutoParry.Delay * 1000, function(value)
        if value >= 0 then AutoParry.Delay = value / 1000 end
    end)

    HanxUI:AddInput(cardSurvCombat, "Parry Cooldown (ms)", AutoParry.Cooldown * 1000, function(value)
        if value >= 0 then AutoParry.Cooldown = value / 1000 end
    end)

    -- ESP TAB UI
    local espPlayerCard = HanxUI:AddCard(TabESP, "PLAYER & KILLER")
    
    HanxUI:AddToggle(espPlayerCard, "ESP Survivor (Hijau)", false, function(value)
        Feature.State.ESP_Player = value
        Feature:UpdateESP()
    end)

    HanxUI:AddToggle(espPlayerCard, "ESP Killer (Merah)", false, function(value)
        Feature.State.ESP_Killer = value
        Feature:UpdateESP()
    end)

    local espObjectCard = HanxUI:AddCard(TabESP, "OBJECTIVES")

    HanxUI:AddToggle(espObjectCard, "ESP Pallet / Generator", false, function(value)
        Feature.State.ESP_Object = value
        Feature:UpdateESP()
    end)

    -- SETTINGS
    local settingsCard = HanxUI:AddCard(TabSettings, "INTERFACE SETTINGS")
    HanxUI:AddSlider(settingsCard, "UI Transparency", 0, 100, 0, function(value)
        Window.Main.BackgroundTransparency = value / 100
    end)
    local quickCard = HanxUI:AddCard(TabSettings, "QUICK ACTIONS")
    HanxUI:AddButton(quickCard, "Rejoin Server", function()
        game:GetService("TeleportService"):Teleport(game.PlaceId, LP)
    end)
    HanxUI:AddButton(quickCard, "Copy JobId (Server ID)", function()
        if setclipboard then
            setclipboard(tostring(game.JobId))
        end
    end)

    -- MEDIA SOCIAL
    local socialCard = HanxUI:AddCard(TabSocial, "HANX HUB COMMUNITY")

    create("TextLabel", {
        Size = UDim2.new(1, 0, 0, 32),
        BackgroundTransparency = 1,
        Text = "Join our community and stay updated with the latest releases.",
        TextColor3 = HanxUI.Theme.TextDim,
        Font = HanxUI.Theme.Font,
        TextSize = 11,
        TextWrapped = true,
        TextXAlignment = Enum.TextXAlignment.Left,
        Parent = socialCard
    })

    create("TextLabel", {
        Size = UDim2.new(1, 0, 0, 22),
        BackgroundTransparency = 1,
        Text = "● OFFICIAL COMMUNITY",
        TextColor3 = Color3.fromRGB(50, 200, 100),
        Font = HanxUI.Theme.FontBold,
        TextSize = 10,
        TextXAlignment = Enum.TextXAlignment.Left,
        Parent = socialCard
    })

    local function OpenSocial(url)
        if setclipboard then
            pcall(function()
                setclipboard(url)
            end)
        end

        pcall(function()
            game:GetService("GuiService"):OpenBrowserWindow(url)
        end)
    end

    HanxUI:AddButton(socialCard, "💬  Discord Server", function()
        OpenSocial(DISCORD_LINK)
    end)

    HanxUI:AddButton(socialCard, "▶  YouTube Channel", function()
        OpenSocial(YOUTUBE_LINK)
    end)

    HanxUI:AddButton(socialCard, "♥  Support via Saweria", function()
        OpenSocial(SAWERIA_LINK)
    end)

    LP.CharacterAdded:Connect(function()
        if Feature.State.Noclip then Feature:ToggleNoclip(false) end
        
        Feature.State.ESP_Player = false
        Feature.State.ESP_Killer = false
        Feature.State.ESP_Object = false
        Feature:UpdateESP()
        
        if AutoParry.Conn then AutoParry.Conn:Disconnect() end
        AutoParryEnabled = false
        Feature.State.AutoSkillcheckGen = false
        _G.HanxAutoGen = false

        FastVaultEnabled = false
        _G.HANX_V35_ENABLED = false
    end)
end)
