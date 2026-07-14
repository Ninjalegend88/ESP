-- ESP + Teleport + Bring | The Invisible Man
-- Key: Zkiller

-- ─── ANTI-CHEAT BYPASS ──────────────────────────────────────────────────

local function BypassAntiCheat()
    pcall(function()
        local oldKick = game.Players.LocalPlayer.Kick
        game.Players.LocalPlayer.Kick = function(self, msg)
            if msg and (msg:find("tamper") or msg:find("cheat") or msg:find("exploit") or msg:find("detect") or msg:find("ban")) then
                warn("[AC] Blocked kick: " .. msg)
                return
            end
            return oldKick(self, msg)
        end
        
        local acNames = {"AntiCheat", "BanEvent", "DetectionEvent", "ReportEvent", "KickEvent", "LogEvent", "Watchdog", "SecurityCheck", "FileIntegrityCheck", "IntegrityCheck", "HashCheck"}
        for _, name in ipairs(acNames) do
            local r = game.ReplicatedStorage:FindFirstChild(name)
            if r then r:Destroy() end
            local r2 = game.ReplicatedFirst:FindFirstChild(name)
            if r2 then r2:Destroy() end
        end
        
        for i, v in ipairs(game:GetDescendants()) do
            if v:IsA("Script") or v:IsA("LocalScript") then
                local name = v.Name:lower()
                if name:find("anticheat") or name:find("watchdog") or name:find("security") or name:find("detect") then
                    v.Disabled = true
                end
            end
        end
        
        for i, v in ipairs(getgc(true)) do
            if type(v) == "function" and isclosure(v) then
                local info = debug.getinfo(v)
                if info and info.name then
                    local name = info.name:lower()
                    if name:find("detect") or name:find("ban") or name:find("kick") or name:find("report") or name:find("check") then
                        hookfunction(v, function() return end)
                    end
                end
            end
        end
    end)
end

BypassAntiCheat()

-- ─── LOAD RAYFIELD ──────────────────────────────────────────────────────

local Rayfield = nil
pcall(function()
    Rayfield = loadstring(game:HttpGet('https://sirius.menu/rayfield'))()
end)

if not Rayfield then
    pcall(function()
        Rayfield = loadstring(game:HttpGet("https://raw.githubusercontent.com/UI-Interface/CustomFIeld/main/RayField.lua"))()
    end)
end

if not Rayfield then
    game.StarterGui:SetCore("SendNotification", {
        Title = "Error",
        Text = "Failed to load UI",
        Duration = 5
    })
    return
end

getgenv().SecureMode = true

-- ─── SERVICES ────────────────────────────────────────────────────────────

local Players = game:GetService("Players")
local LP = Players.LocalPlayer
local RunService = game:GetService("RunService")
local Workspace = game:GetService("Workspace")
local TweenService = game:GetService("TweenService")
local UserInputService = game:GetService("UserInputService")
local Mouse = LP:GetMouse()
local Camera = workspace.CurrentCamera

-- ─── VARIABLES ───────────────────────────────────────────────────────────

local ESPEnabled = false
local ESPObjects = {}
local ESPColor = Color3.fromRGB(255, 0, 0)
local ESPSize = 5
local SelectedPlayerName = nil
local SetPosition = nil
local TeleportTargetName = nil
local BringTargetName = nil

-- ─── FUNCTIONS ───────────────────────────────────────────────────────────

local function GetCharacter(player)
    return player and player.Character
end

local function GetHumanoid(character)
    return character and character:FindFirstChildOfClass("Humanoid")
end

local function GetRootPart(character)
    return character and (character:FindFirstChild("HumanoidRootPart") or character:FindFirstChild("Torso"))
end

local function IsAlive(player)
    local char = GetCharacter(player)
    local hum = GetHumanoid(char)
    return hum and hum.Health > 0
end

-- ─── ESP SYSTEM ──────────────────────────────────────────────────────────

local function CreateESP(player)
    if ESPObjects[player] then return end
    if player == LP then return end
    
    local char = GetCharacter(player)
    if not char then return end
    
    local root = GetRootPart(char)
    if not root then return end
    
    -- Highlight
    local highlight = Instance.new("Highlight")
    highlight.FillColor = ESPColor
    highlight.FillTransparency = 0.7
    highlight.OutlineColor = ESPColor
    highlight.OutlineTransparency = 0.2
    highlight.Adornee = char
    highlight.Parent = char
    highlight.Enabled = ESPEnabled
    
    -- ESP Sphere (scalable)
    local sphere = Instance.new("Part")
    sphere.Name = "ESP_Sphere"
    sphere.Size = Vector3.new(ESPSize, ESPSize, ESPSize)
    sphere.Shape = Enum.PartType.Ball
    sphere.Material = Enum.Material.Neon
    sphere.Color = ESPColor
    sphere.Transparency = 0.5
    sphere.CanCollide = false
    sphere.Anchored = false
    sphere.Parent = root
    sphere.CFrame = root.CFrame
    
    -- Weld sphere to root
    local weld = Instance.new("Weld")
    weld.Part0 = root
    weld.Part1 = sphere
    weld.C0 = CFrame.new(0, 0, 0)
    weld.Parent = sphere
    
    ESPObjects[player] = {
        Highlight = highlight,
        Sphere = sphere,
        Weld = weld,
        Player = player
    }
end

local function RemoveESP(player)
    if ESPObjects[player] then
        if ESPObjects[player].Highlight then
            ESPObjects[player].Highlight:Destroy()
        end
        if ESPObjects[player].Sphere then
            ESPObjects[player].Sphere:Destroy()
        end
        if ESPObjects[player].Weld then
            ESPObjects[player].Weld:Destroy()
        end
        ESPObjects[player] = nil
    end
end

local function UpdateESPVisuals()
    for player, data in pairs(ESPObjects) do
        if data.Highlight then
            data.Highlight.FillColor = ESPColor
            data.Highlight.OutlineColor = ESPColor
            data.Highlight.Enabled = ESPEnabled
        end
        if data.Sphere then
            data.Sphere.Color = ESPColor
            data.Sphere.Size = Vector3.new(ESPSize, ESPSize, ESPSize)
            data.Sphere.Transparency = 0.5
            data.Sphere.Visible = ESPEnabled
        end
    end
end

local function UpdateESP()
    for player, data in pairs(ESPObjects) do
        if player and player.Character then
            local root = GetRootPart(player.Character)
            if root and data.Sphere then
                data.Sphere.CFrame = root.CFrame
            end
            if data.Highlight then
                data.Highlight.Adornee = player.Character
            end
        else
            data.Highlight.Enabled = false
            data.Sphere.Visible = false
        end
    end
end

-- ─── TELEPORT FUNCTIONS ─────────────────────────────────────────────────

local function TeleportToPosition(position)
    local char = LP.Character
    if not char then return false end
    local root = GetRootPart(char)
    if not root then return false end
    
    root.CFrame = CFrame.new(position)
    
    pcall(function()
        local tweenInfo = TweenInfo.new(0.3, Enum.EasingStyle.Quad, Enum.EasingDirection.Out)
        local tween = TweenService:Create(root, tweenInfo, {CFrame = CFrame.new(position)})
        tween:Play()
        tween.Completed:Wait()
    end)
    
    return true
end

local function TeleportToPlayer(playerName)
    local target = nil
    for _, p in ipairs(Players:GetPlayers()) do
        if p.Name == playerName then
            target = p
            break
        end
    end
    if not target then return false, "Player not found" end
    if not IsAlive(target) then return false, "Player is dead" end
    
    local char = GetCharacter(target)
    if not char then return false, "Character not found" end
    local root = GetRootPart(char)
    if not root then return false, "Root part not found" end
    
    return TeleportToPosition(root.Position), nil
end

local function BringPlayer(playerName)
    local target = nil
    for _, p in ipairs(Players:GetPlayers()) do
        if p.Name == playerName then
            target = p
            break
        end
    end
    if not target then return false, "Player not found" end
    if not IsAlive(target) then return false, "Player is dead" end
    
    local targetChar = GetCharacter(target)
    if not targetChar then return false, "Character not found" end
    local targetRoot = GetRootPart(targetChar)
    if not targetRoot then return false, "Root part not found" end
    
    local myChar = LP.Character
    if not myChar then return false, "Your character not found" end
    local myRoot = GetRootPart(myChar)
    if not myRoot then return false, "Your root part not found" end
    
    local myPos = myRoot.Position
    targetRoot.CFrame = CFrame.new(myPos + Vector3.new(0, 3, 0))
    
    pcall(function()
        local tweenInfo = TweenInfo.new(0.3, Enum.EasingStyle.Quad, Enum.EasingDirection.Out)
        local tween = TweenService:Create(targetRoot, tweenInfo, {CFrame = CFrame.new(myPos + Vector3.new(0, 3, 0))})
        tween:Play()
        tween.Completed:Wait()
    end)
    
    return true, nil
end

-- ─── SET POSITION VIA MOUSE CLICK ──────────────────────────────────────

local function SetPositionFromClick()
    local hit = Mouse.Hit
    if hit and hit.Position then
        SetPosition = hit.Position
        Rayfield:Notify({
            Title = "Position Set",
            Content = "X: " .. math.floor(SetPosition.X) .. " Y: " .. math.floor(SetPosition.Y) .. " Z: " .. math.floor(SetPosition.Z),
            Duration = 2
        })
    end
end

-- ─── GET PLAYER LIST ────────────────────────────────────────────────────

local function GetPlayerList()
    local list = {}
    for _, player in ipairs(Players:GetPlayers()) do
        if player ~= LP then
            table.insert(list, player.Name)
        end
    end
    return list
end

-- ─── CREATE UI ──────────────────────────────────────────────────────────

local Window = Rayfield:CreateWindow({
    Name = "ESP + Teleport",
    Icon = 0,
    LoadingTitle = "ESP Hub",
    LoadingSubtitle = "by The Invisible Man",
    ConfigurationSaving = {
        Enabled = true,
        FolderName = "ESPHub",
        FileName = "Config"
    },
    KeySystem = true,
    KeySettings = {
        Title = "Key System",
        Subtitle = "Enter Key Below",
        Note = "Key: Zkiller",
        FileName = "Key",
        SaveKey = false,
        GrabKeyFromSite = false,
        Key = {"Zkiller"}
    }
})

local ESPTab = Window:CreateTab("ESP")
local TeleportTab = Window:CreateTab("Teleport")
local BringTab = Window:CreateTab("Bring")
local SettingsTab = Window:CreateTab("Settings")

-- ─── ESP TAB ────────────────────────────────────────────────────────────

local ESPToggle = ESPTab:CreateToggle({
    Name = "Enable ESP",
    CurrentValue = false,
    Flag = "ESPToggle",
    Callback = function(Value)
        ESPEnabled = Value
        if Value then
            for _, player in ipairs(Players:GetPlayers()) do
                if player ~= LP then
                    CreateESP(player)
                end
            end
            Rayfield:Notify({
                Title = "ESP",
                Content = "Enabled",
                Duration = 2
            })
        else
            for player, _ in pairs(ESPObjects) do
                RemoveESP(player)
            end
            Rayfield:Notify({
                Title = "ESP",
                Content = "Disabled",
                Duration = 2
            })
        end
    end
})

local ColorPicker = ESPTab:CreateColorPicker({
    Name = "ESP Color",
    Color = Color3.fromRGB(255, 0, 0),
    Flag = "ESPColor",
    Callback = function(Color)
        ESPColor = Color
        UpdateESPVisuals()
    end
})

local ESPSizeSlider = ESPTab:CreateSlider({
    Name = "ESP Size",
    Range = {2, 30},
    Increment = 0.5,
    Suffix = " studs",
    CurrentValue = 5,
    Flag = "ESPSize",
    Callback = function(Value)
        ESPSize = Value
        UpdateESPVisuals()
    end
})

local RefreshESP = ESPTab:CreateButton({
    Name = "Refresh ESP",
    Callback = function()
        if ESPEnabled then
            for player, _ in pairs(ESPObjects) do
                RemoveESP(player)
            end
            for _, player in ipairs(Players:GetPlayers()) do
                if player ~= LP then
                    CreateESP(player)
                end
            end
            Rayfield:Notify({
                Title = "ESP",
                Content = "Refreshed",
                Duration = 2
            })
        end
    end
})

-- ─── TELEPORT TAB ───────────────────────────────────────────────────────

local TeleportSection = TeleportTab:CreateSection("Teleport to Player")

local PlayerDropdown = TeleportTab:CreateDropdown({
    Name = "Select Player",
    Options = GetPlayerList(),
    CurrentOption = "",
    Flag = "PlayerDropdown",
    Callback = function(Option)
        TeleportTargetName = Option
    end
})

local TeleportToPlayerButton = TeleportTab:CreateButton({
    Name = "Teleport to Player",
    Callback = function()
        if TeleportTargetName then
            local success, err = TeleportToPlayer(TeleportTargetName)
            if success then
                Rayfield:Notify({
                    Title = "Teleported",
                    Content = "Teleported to " .. TeleportTargetName,
                    Duration = 2
                })
            else
                Rayfield:Notify({
                    Title = "Error",
                    Content = err or "Could not teleport",
                    Duration = 2
                })
            end
        else
            Rayfield:Notify({
                Title = "Error",
                Content = "Select a player first",
                Duration = 2
            })
        end
    end
})

local RefreshPlayers = TeleportTab:CreateButton({
    Name = "Refresh Player List",
    Callback = function()
        PlayerDropdown:SetOptions(GetPlayerList())
        BringDropdown:SetOptions(GetPlayerList())
        Rayfield:Notify({
            Title = "Players",
            Content = "Refreshed",
            Duration = 2
        })
    end
})

-- ─── SET POSITION ───────────────────────────────────────────────────────

local SetPosSection = TeleportTab:CreateSection("Set Position")

local SetPosButton = TeleportTab:CreateButton({
    Name = "Set Position (Click on Ground)",
    Callback = function()
        SetPositionFromClick()
    end
})

local PosXInput = TeleportTab:CreateInput({
    Name = "X Coordinate",
    PlaceholderText = "Enter X...",
    Flag = "PosX",
    Callback = function(Text)
        PosX = tonumber(Text) or 0
    end
})

local PosYInput = TeleportTab:CreateInput({
    Name = "Y Coordinate",
    PlaceholderText = "Enter Y...",
    Flag = "PosY",
    Callback = function(Text)
        PosY = tonumber(Text) or 0
    end
})

local PosZInput = TeleportTab:CreateInput({
    Name = "Z Coordinate",
    PlaceholderText = "Enter Z...",
    Flag = "PosZ",
    Callback = function(Text)
        PosZ = tonumber(Text) or 0
    end
})

local TeleportToPosButton = TeleportTab:CreateButton({
    Name = "Teleport to Coordinates",
    Callback = function()
        local pos = Vector3.new(PosX or 0, PosY or 0, PosZ or 0)
        local success = TeleportToPosition(pos)
        if success then
            Rayfield:Notify({
                Title = "Teleported",
                Content = "Teleported to coordinates",
                Duration = 2
            })
        else
            Rayfield:Notify({
                Title = "Error",
                Content = "Could not teleport",
                Duration = 2
            })
        end
    end
})

local TeleportToSetPos = TeleportTab:CreateButton({
    Name = "Teleport to Set Position",
    Callback = function()
        if SetPosition then
            local success = TeleportToPosition(SetPosition)
            if success then
                Rayfield:Notify({
                    Title = "Teleported",
                    Content = "Teleported to set position",
                    Duration = 2
                })
            else
                Rayfield:Notify({
                    Title = "Error",
                    Content = "Could not teleport",
                    Duration = 2
                })
            end
        else
            Rayfield:Notify({
                Title = "Error",
                Content = "No position set. Click 'Set Position' first.",
                Duration = 2
            })
        end
    end
})

-- ─── BRING TAB ──────────────────────────────────────────────────────────

local BringSection = BringTab:CreateSection("Bring Player to You")

local BringDropdown = BringTab:CreateDropdown({
    Name = "Select Player to Bring",
    Options = GetPlayerList(),
    CurrentOption = "",
    Flag = "BringDropdown",
    Callback = function(Option)
        BringTargetName = Option
    end
})

local BringPlayerButton = BringTab:CreateButton({
    Name = "Bring Player",
    Callback = function()
        if BringTargetName then
            local success, err = BringPlayer(BringTargetName)
            if success then
                Rayfield:Notify({
                    Title = "Brought",
                    Content = "Brought " .. BringTargetName .. " to you",
                    Duration = 2
                })
            else
                Rayfield:Notify({
                    Title = "Error",
                    Content = err or "Could not bring player",
                    Duration = 2
                })
            end
        else
            Rayfield:Notify({
                Title = "Error",
                Content = "Select a player first",
                Duration = 2
            })
        end
    end
})

local RefreshBring = BringTab:CreateButton({
    Name = "Refresh Player List",
    Callback = function()
        BringDropdown:SetOptions(GetPlayerList())
        Rayfield:Notify({
            Title = "Players",
            Content = "Refreshed",
            Duration = 2
        })
    end
})

-- ─── SETTINGS TAB ──────────────────────────────────────────────────────

local CreditsLabel = SettingsTab:CreateParagraph({
    Title = "ESP + Teleport + Bring Hub",
    Content = "by The Invisible Man\nKey: Zkiller\nESP highlights players with scalable glow sphere\nTeleport to players or positions\nBring players to you"
})

-- ─── AUTO REFRESH ──────────────────────────────────────────────────────

spawn(function()
    while true do
        wait(5)
        if ESPEnabled then
            UpdateESP()
        end
        local players = GetPlayerList()
        pcall(function()
            PlayerDropdown:SetOptions(players)
            BringDropdown:SetOptions(players)
        end)
    end
end)

-- ─── PLAYER HANDLERS ────────────────────────────────────────────────────

Players.PlayerAdded:Connect(function(player)
    player.CharacterAdded:Connect(function(char)
        task.wait(0.5)
        if ESPEnabled then
            CreateESP(player)
        end
    end)
end)

Players.PlayerRemoving:Connect(function(player)
    RemoveESP(player)
end)

-- ─── NOTIFY ON LOAD ──────────────────────────────────────────────────

Rayfield:Notify({
    Title = "Loaded",
    Content = "ESP + Teleport + Bring | by The Invisible Man",
    Duration = 3
})

print("[ESP] Loaded | Key: Zkiller")
