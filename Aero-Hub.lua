local WindUI = loadstring(game:HttpGet("https://github.com/Footagesus/WindUI/releases/latest/download/main.lua"))()

local Window = WindUI:CreateWindow({
Title = "Aero Hub",
Icon = "rbxassetid://4483345998",
Author = "by Void HackerX",
Folder = "MyWindUIConfig",
Size = UDim2.fromOffset(580, 460),
Transparent = true,
Theme = "Dark",
Resizable = true,
})

local Tab = Window:Tab({
Title = "공격탭",
Icon = "home",
})

local Tab2 = Window:Tab({
Title = "시각/방어탭",
Icon = "home",
})

local RagebotSource = [[
local repS = cloneref(game:GetService("ReplicatedStorage"))
local plrs = cloneref(game:GetService("Players"))
local runS = cloneref(game:GetService("RunService"))
local ws = cloneref(game:GetService("Workspace"))
local lplr = plrs.LocalPlayer
local util = require(repS.Modules.Utility)
local enum = require(repS.Modules.EnumLibrary)
local FighterController = require(lplr.PlayerScripts.Controllers.FighterController)
local SpectateController = require(lplr.PlayerScripts.Controllers:WaitForChild("SpectateController"))

getgenv().Config = {
Enabled = true,
FireRate = 0.0005,
WeaponSlot = "Primary"
}

local slots = {
Primary = 1,
Secondary = 2,
Melee = 3
}

local function getSlotNumber()
return slots[getgenv().Config.WeaponSlot] or 3
end

local function equipItem()
local localFighter = FighterController.LocalFighter
if localFighter then
pcall(function()
localFighter:EquipItem(getSlotNumber())
end)
end
end

task.spawn(function()
local localFighter = FighterController.LocalFighter
while not localFighter do
task.wait(0.1)
localFighter = FighterController.LocalFighter
end
equipItem()
end)

task.spawn(function()
while true do
task.wait(1)
if not getgenv().Config.Enabled then continue end
equipItem()
end
end)

local lastFire = 0
local deflecting = {}
plrs.PlayerRemoving:Connect(function(player)
deflecting[player] = nil
end)

local function updateDeflection()
if not FighterController or not FighterController.Objects then return end
for _, fighterObj in FighterController.Objects do
local player = fighterObj.Player
if not player then continue end
if not fighterObj.Entity or not fighterObj.Entity:IsAlive() or fighterObj:Get("IsSpectating") then
deflecting[player] = false
continue
end
local equipped = fighterObj.EquippedItem
local isKatana = equipped and equipped.ViewModel and equipped.ViewModel.Name == "Katana"
local isDeflecting = false
if isKatana and typeof(equipped._attack_cooldown) == "number" then
isDeflecting = equipped._attack_cooldown > tick()
end
deflecting[player] = isDeflecting
end
end

local function isEnemy(player)
if player == lplr then return false end
local duel = SpectateController.CurrentDuelSubject
local localDueler = duel and duel:GetDueler(lplr)
local localTeam = localDueler and localDueler:Get("TeamID") or nil
if localTeam and duel and duel.Duelers then
for _, dueler in duel.Duelers do
if dueler.Player == player then
local team = dueler:Get("TeamID")
return team ~= localTeam
end
end
end
local pTeam = player:GetAttribute("TeamID")
local lTeam = lplr:GetAttribute("TeamID")
if pTeam and lTeam then
return pTeam ~= lTeam
end
return true
end

local function getClosestTarget()
local char = lplr.Character
if not char then return nil, nil, nil end
local myRoot = char:FindFirstChild("HumanoidRootPart")
if not myRoot then return nil, nil, nil end
local closestPlayer, closestRoot, closestHead = nil, nil, nil
local closestDist = 500
for _, player in plrs:GetPlayers() do
if not isEnemy(player) then continue end
local pChar = player.Character
if not pChar then continue end
local pRoot = pChar:FindFirstChild("HumanoidRootPart")
local pHead = pChar:FindFirstChild("Head")
local pHum = pChar:FindFirstChildWhichIsA("Humanoid")
if not (pRoot and pHead and pHum and pHum.Health > 0) then continue end
local dist = (myRoot.Position - pRoot.Position).Magnitude
if dist < closestDist then
closestDist = dist
closestPlayer = player
closestRoot = pRoot
closestHead = pHead
end
end
return closestPlayer, closestRoot, closestHead
end

local function hasKnifeViewModel(targetPlayer)
if not targetPlayer then return false end
local viewModels = ws:FindFirstChild("ViewModels")
if not viewModels then return false end
local targetName = targetPlayer.Name
for _, model in viewModels:GetChildren() do
if model:IsA("Model")
and string.sub(model.Name, 1, #targetName) == targetName
and string.find(model.Name, "Knife", 1, true) then
return true
end
end
return false
end

local restoreBindName = "restore" .. tostring(math.random(1e6, 1e9))

local heartbeatConn
heartbeatConn = runS.Heartbeat:Connect(function()
updateDeflection()
local targetPlayer, targetRoot, targetHead = getClosestTarget()
local desyncCF = nil

if targetRoot and targetHead then
local desyncPos
if hasKnifeViewModel(targetPlayer) then
desyncPos = (targetRoot.CFrame * CFrame.new(0, 6, 0)).Position
else
desyncPos = (targetRoot.CFrame * CFrame.new(0, 1, 2)).Position
end
desyncCF = CFrame.lookAt(desyncPos, targetHead.Position)
end

if desyncCF and lplr.Character then
local myRoot = lplr.Character:FindFirstChild("HumanoidRootPart")
if myRoot then
local oldCF = myRoot.CFrame
local oldVel = myRoot.Velocity
local oldRotVel = myRoot.RotVelocity
myRoot.CFrame = desyncCF
pcall(function() runS:UnbindFromRenderStep(restoreBindName) end)
runS:BindToRenderStep(restoreBindName, 101, function()
if myRoot then
myRoot.CFrame = oldCF
myRoot.Velocity = oldVel
myRoot.RotVelocity = oldRotVel
end
pcall(function() runS:UnbindFromRenderStep(restoreBindName) end)
end)
end
end

if not getgenv().Config.Enabled then return end
if not targetPlayer or not targetHead or not targetRoot then return end
if deflecting[targetPlayer] then return end
if not lplr.Character or not lplr.Character:FindFirstChild("HumanoidRootPart") then return end
if not FighterController or not FighterController.LocalFighter then return end
local item = FighterController.LocalFighter.EquippedItem
if not item then return end
if tick() - lastFire < getgenv().Config.FireRate then return end
lastFire = tick()
local originPos = desyncCF and desyncCF.Position or targetRoot.Position
local targetPos = targetHead.Position
local aimCF = CFrame.lookAt(originPos, targetPos)
local targetCF = targetHead.CFrame
local randomOffset = Vector3.new(
(math.random() - 0.5) * 0.1,
(math.random() - 0.5) * 0.1,
(math.random() - 0.5) * 0.1
)
local aimedPos = targetPos + randomOffset
local objSpaceHeadOffset = targetHead.CFrame:ToObjectSpace(CFrame.new(aimedPos))
local cameradata = {}
cameradata[utf8.char(1)] = {
[utf8.char(0)] = util:EncodeCFrame(aimCF),
[utf8.char(1)] = util:EncodeCFrame(targetCF),
[utf8.char(2)] = targetHead,
[utf8.char(3)] = util:EncodeCFrame(objSpaceHeadOffset)
}
repS.Remotes.Replication.Fighter.UseItem:FireServer(
item:Get("ObjectID"),
enum:ToEnum("StartShooting"),
cameradata,
nil
)
end)

getgenv().AimHub = {
Unload = function()
getgenv().Config.Enabled = false
if heartbeatConn then heartbeatConn:Disconnect() end
pcall(function() runS:UnbindFromRenderStep(restoreBindName) end)
getgenv().AimHub = nil
end
}
]]

local SilentAimSource = [[
local reps = cloneref(game:GetService("ReplicatedStorage"))
local plrs = cloneref(game:GetService("Players"))
local runs = cloneref(game:GetService("RunService"))
local cs = cloneref(game:GetService("CollectionService"))
local lplr = plrs.LocalPlayer
local cam = workspace.CurrentCamera

if not getgenv().Config then
getgenv().Config = {}
end
getgenv().Config.FOVRadius = getgenv().Config.FOVRadius or 150
getgenv().Config.ShowFOV = getgenv().Config.ShowFOV or false
getgenv().Config.HitPart = getgenv().Config.HitPart or "Head"

local U = require(reps.Modules.Utility)
local EL = require(reps.Modules.EnumLibrary)
local GU = require(reps.Modules.GameplayUtility)

local e, gun = pcall(require, lplr.PlayerScripts.Modules.ItemTypes.Gun)
if e and gun and gun.IsFullyAiming then
gun.IsFullyAiming = function() return true end
end

local FOV = Drawing.new("Circle")
FOV.Color = Color3.fromRGB(255, 255, 255)
FOV.Thickness = 1
FOV.Filled = false

local fovConn
fovConn = runs.RenderStepped:Connect(function()
FOV.Position = cam.ViewportSize / 2
FOV.Radius = getgenv().Config.FOVRadius
FOV.Visible = getgenv().Config.ShowFOV
end)

local function target()
local center = cam.ViewportSize / 2
local bestPart, bestDist = nil, getgenv().Config.FOVRadius
for _, entity in cs:GetTagged("Entity") do
if entity == lplr.Character then continue end
local part = entity:FindFirstChild(getgenv().Config.HitPart, true)
if not part or not part:IsA("BasePart") then continue end
local sp, onScreen = cam:WorldToViewportPoint(part.Position)
if not onScreen then continue end
local d = (Vector2.new(sp.X, sp.Y) - center).Magnitude
if d < bestDist then bestDist, bestPart = d, part end
end
return bestPart
end

local function CFD(origin, part)
local cf = part.CFrame
local d = {}
d[utf8.char(1)] = {
[utf8.char(0)] = U:EncodeCFrame(CFrame.lookAt(origin, part.Position)),
[utf8.char(1)] = U:EncodeCFrame(cf),
[utf8.char(2)] = part,
[utf8.char(3)] = U:EncodeCFrame(cf:ToObjectSpace(CFrame.new(part.Position))),
}
return d
end

local originalRaycast = GU.GetEntitiesFromRaycast
GU.GetEntitiesFromRaycast = function(self, envID, params, origin, dir, maxDist, ...)
local t = target()
if t then
local dist = (t.Position - origin).Magnitude
dir = (t.Position - origin).Unit
if dist > maxDist then maxDist = dist + 5 end
end
return originalRaycast(self, envID, params, origin, dir, maxDist, ...)
end

local UseItem = reps.Remotes.Replication.Fighter.UseItem
local hookedFire = UseItem.FireServer
local hookFn
hookFn = hookfunction(UseItem.FireServer, newcclosure(function(self, objID, enumVal, camdata, extra)
if getgenv().SilentAimOn and enumVal == EL:ToEnum("StartShooting") then
local root = lplr.Character and lplr.Character:FindFirstChild("HumanoidRootPart")
local t = target()
if root and t then camdata = CFD(root.Position, t) end
end
return hookFn(self, objID, enumVal, camdata, extra)
end))

getgenv().SilentAimOn = true

getgenv().SilentAim = {
Unload = function()
getgenv().SilentAimOn = false
GU.GetEntitiesFromRaycast = originalRaycast
pcall(function()
hookfunction(UseItem.FireServer, hookedFire)
end)
if fovConn then fovConn:Disconnect() end
pcall(function() FOV:Remove() end)
getgenv().SilentAim = nil
end
}
]]

local AimbotSource = [[
local plrs = cloneref(game:GetService("Players"))
local runS = cloneref(game:GetService("RunService"))
local uis = cloneref(game:GetService("UserInputService"))
local lplr = plrs.LocalPlayer

getgenv().AimbotConfig = {
Enabled = true,
FOV = 100,
Smoothing = 0.25,
TargetPart = "Head",
HoldKey = nil,
TeamCheck = true
}

local function isEnemy(player)
if player == lplr then return false end
local pTeam = player:GetAttribute("TeamID")
local lTeam = lplr:GetAttribute("TeamID")
if pTeam and lTeam then
return pTeam ~= lTeam
end
return true
end

local function getTarget()
local cam = workspace.CurrentCamera
if not cam then return nil end
local mousePos = uis:GetMouseLocation()
local best, bestDist = nil, getgenv().AimbotConfig.FOV
for _, player in plrs:GetPlayers() do
if player == lplr then continue end
if getgenv().AimbotConfig.TeamCheck and not isEnemy(player) then continue end
local pChar = player.Character
if not pChar then continue end
local part = pChar:FindFirstChild(getgenv().AimbotConfig.TargetPart)
local pHum = pChar:FindFirstChildWhichIsA("Humanoid")
if not (part and pHum and pHum.Health > 0) then continue end
local screenPos, onScreen = cam:WorldToViewportPoint(part.Position)
if not onScreen then continue end
local dist = (Vector2.new(screenPos.X, screenPos.Y) - Vector2.new(mousePos.X, mousePos.Y)).Magnitude
if dist < bestDist then
bestDist = dist
best = part
end
end
return best
end

local renderConn
renderConn = runS.RenderStepped:Connect(function()
local cfg = getgenv().AimbotConfig
if not cfg.Enabled then return end
if cfg.HoldKey and not uis:IsKeyDown(cfg.HoldKey) then return end
local target = getTarget()
if not target then return end
local cam = workspace.CurrentCamera
if not cam then return end
local targetPos = target.Position
local currentLook = cam.CFrame.LookVector
local direction = (targetPos - cam.CFrame.Position).Unit
local smoothed = currentLook:Lerp(direction, 1 - cfg.Smoothing)
cam.CFrame = CFrame.lookAt(cam.CFrame.Position, cam.CFrame.Position + smoothed)
end)

getgenv().Aimbot = {
Unload = function()
getgenv().AimbotConfig.Enabled = false
if renderConn then renderConn:Disconnect() end
getgenv().Aimbot = nil
end
}
]]

local AntiAimSource = [[
local plrs = cloneref(game:GetService("Players"))
local runS = cloneref(game:GetService("RunService"))
local lplr = plrs.LocalPlayer

getgenv().AntiAimConfig = {
Enabled = true,
Range = 1000,
Radius = 8,
Height = 5,
Interval = 0.1,
FacingTarget = true,
ForceAirborne = true
}

local heartbeatConn
local lastMove = 0

local function getEnemyInRange()
local char = lplr.Character
if not char then return nil end
local myRoot = char:FindFirstChild("HumanoidRootPart")
if not myRoot then return nil end
local closest, closestDist = nil, getgenv().AntiAimConfig.Range
for _, player in plrs:GetPlayers() do
if player == lplr then continue end
local pChar = player.Character
if not pChar then continue end
local pRoot = pChar:FindFirstChild("HumanoidRootPart")
local pHum = pChar:FindFirstChildWhichIsA("Humanoid")
if not (pRoot and pHum and pHum.Health > 0) then continue end
local dist = (myRoot.Position - pRoot.Position).Magnitude
if dist < closestDist then
closestDist = dist
closest = pRoot
end
end
return closest
end

local function applyAntiAim()
local cfg = getgenv().AntiAimConfig
if not cfg.Enabled then return end
local char = lplr.Character
if not char then return end
local myRoot = char:FindFirstChild("HumanoidRootPart")
local hum = char:FindFirstChildWhichIsA("Humanoid")
if not (myRoot and hum) then return end

local center = getEnemyInRange()
local basePos = center and center.Position or myRoot.Position

local ang = math.rad(math.random(0, 359))
local offset = Vector3.new(math.cos(ang) * cfg.Radius, cfg.Height, math.sin(ang) * cfg.Radius)
local newPos = basePos + offset

if cfg.FacingTarget and center then
myRoot.CFrame = CFrame.lookAt(newPos, Vector3.new(center.Position.X, newPos.Y, center.Position.Z))
else
myRoot.CFrame = CFrame.new(newPos)
end

if cfg.ForceAirborne then
local vel = myRoot.Velocity
myRoot.Velocity = Vector3.new(vel.X, math.max(vel.Y, 10), vel.Z)
hum:ChangeState(Enum.HumanoidStateType.Freefall)
end
end

heartbeatConn = runS.Heartbeat:Connect(function()
if not getgenv().AntiAimConfig.Enabled then return end
if tick() - lastMove < getgenv().AntiAimConfig.Interval then return end
lastMove = tick()
applyAntiAim()
end)

getgenv().AntiAim = {
Unload = function()
getgenv().AntiAimConfig.Enabled = false
if heartbeatConn then heartbeatConn:Disconnect() end
getgenv().AntiAim = nil
end
}
]]

local ESPSource = [[
local Players = cloneref(game:GetService("Players"))
local RunService = cloneref(game:GetService("RunService"))
local LocalPlayer = Players.LocalPlayer

local BOX_COLOR = Color3.fromRGB(255, 0, 0)
local MAX_DISTANCE = 1000

local espObjects = {}
local renderConn

local function removeESP(player)
local data = espObjects[player]
if data then
pcall(function()
data.box:Destroy()
data.outline:Destroy()
data.gui:Destroy()
end)
espObjects[player] = nil
end
end

local function createESP(player)
if player == LocalPlayer then return end
local box = Instance.new("BoxHandleAdornment")
box.Name = "ESPBox"
box.AlwaysOnTop = true
box.ZIndex = 5
box.Transparency = 1
box.Color3 = BOX_COLOR
box.Size = Vector3.new(4, 6, 2)
box.Parent = workspace

local outline = Instance.new("SelectionBox")
outline.Name = "ESPOutline"
outline.LineThickness = 0.05
outline.SurfaceTransparency = 1
outline.Color3 = BOX_COLOR
outline.Parent = workspace

local gui = Instance.new("BillboardGui")
gui.Name = "Distance"
gui.Size = UDim2.fromOffset(120, 30)
gui.StudsOffset = Vector3.new(0, -4, 0)
gui.AlwaysOnTop = true
gui.Parent = workspace

local text = Instance.new("TextLabel")
text.Size = UDim2.fromScale(1, 1)
text.BackgroundTransparency = 1
text.TextColor3 = BOX_COLOR
text.TextStrokeTransparency = 0
text.TextScaled = true
text.Font = Enum.Font.GothamBold
text.Text = "0 studs"
text.Parent = gui

espObjects[player] = { box = box, outline = outline, gui = gui }
end

local function updateESP(player, data)
local character = player.Character
local myCharacter = LocalPlayer.Character
local ok = character and myCharacter
and character:FindFirstChild("HumanoidRootPart")
and myCharacter:FindFirstChild("HumanoidRootPart")

if not ok then
data.box.Adornee = nil
data.outline.Adornee = nil
data.gui.Adornee = nil
return
end

local distance = (myCharacter.HumanoidRootPart.Position - character.HumanoidRootPart.Position).Magnitude
if distance > MAX_DISTANCE then
data.box.Adornee = nil
data.outline.Adornee = nil
data.gui.Adornee = nil
return
end

local humanoidRoot = character.HumanoidRootPart
data.box.Adornee = humanoidRoot
data.outline.Adornee = character
data.gui.Adornee = humanoidRoot
data.gui.TextLabel.Text = string.format("%d studs", math.floor(distance))
end

for _, player in ipairs(Players:GetPlayers()) do
createESP(player)
end

local addedConn = Players.PlayerAdded:Connect(createESP)
local removedConn = Players.PlayerRemoving:Connect(removeESP)

renderConn = RunService.RenderStepped:Connect(function()
for player, data in pairs(espObjects) do
updateESP(player, data)
end
end)

getgenv().AeroESP = {
Unload = function()
if addedConn then addedConn:Disconnect() end
if removedConn then removedConn:Disconnect() end
if renderConn then renderConn:Disconnect() end
for player in pairs(espObjects) do
removeESP(player)
end
getgenv().AeroESP = nil
end
}
]]

local NoRecoilSource = [[
local Players = cloneref(game:GetService("Players"))
local LocalPlayer = Players.LocalPlayer
local PlayerScripts = LocalPlayer.PlayerScripts

local clientItemModule = require(PlayerScripts.Modules.ClientReplicatedClasses.ClientFighter.ClientItem)

if not getgenv().NoRecoilHooked then
local originalInput = clientItemModule.Input

getgenv().NoRecoilOriginal = originalInput
getgenv().NoRecoilModule = clientItemModule

clientItemModule.Input = function(self, ...)
if getgenv().NoRecoilConfig and getgenv().NoRecoilConfig.Enabled
and self
and type(self) == "table"
and self.Info then
self.Info.ShootRecoil = 0
self.Info.ShootSpread = 0
self.Info.ProjectileSpeed = 99999999
self.Info.ShootCooldown = 0
self.Info.QuickShotCooldown = 0
end

return getgenv().NoRecoilOriginal(self, ...)
end

getgenv().NoRecoilHooked = true
end

getgenv().NoRecoil = {
Enable = function()
if getgenv().NoRecoilModule and getgenv().NoRecoilOriginal then
getgenv().NoRecoilModule.Input = getgenv().NoRecoilOriginal
end
getgenv().NoRecoilConfig.Enabled = true
getgenv().NoRecoilHooked = true
end,
Disable = function()
if getgenv().NoRecoilModule and getgenv().NoRecoilOriginal then
getgenv().NoRecoilModule.Input = getgenv().NoRecoilOriginal
end
if getgenv().NoRecoilConfig then
getgenv().NoRecoilConfig.Enabled = false
end
getgenv().NoRecoilHooked = false
getgenv().NoRecoilOriginal = nil
end,
Unload = function()
getgenv().NoRecoil.Disable()
getgenv().NoRecoil = nil
end
}
]]

local function loadModule(envKey, configKey, source, state)
if state then
if not getgenv()[envKey] then
local fn, err = loadstring(source)
if fn then
fn()
else
WindUI:Notify({
Title = "Aero Hub",
Content = envKey .. " 로드 실패: " .. tostring(err),
Duration = 3
})
end
else
if configKey and getgenv()[configKey] then
getgenv()[configKey].Enabled = true
end
end
else
if getgenv()[envKey] and getgenv()[envKey].Unload then
getgenv()[envKey].Unload()
end
end
end

Tab:Toggle({
Title = "레이지봇",
Desc = "1초컷하는 기능",
Default = false,
Callback = function(State)
loadModule("AimHub", "Config", RagebotSource, State)
end,
})

Tab:Toggle({
Title = "사일런트 에임봇",
Desc = "조용히 총알이 적에게 따라가는 에임봇",
Default = false,
Callback = function(State)
loadModule("SilentAim", nil, SilentAimSource, State)
end,
})

Tab:Toggle({
Title = "에임봇",
Desc = "화면 중심 근처 적 머리 자동 조준",
Default = false,
Callback = function(State)
loadModule("Aimbot", "AimbotConfig", AimbotSource, State)
end,
})

Tab:Toggle({
Title = "총알 속도 극대화",
Desc = "무반동·무탄퍼짐·연사무제한·투사체 증속 (OFF 시 원본 복원)",
Default = false,
Callback = function(State)
if State then
if not getgenv().NoRecoil then
getgenv().NoRecoilConfig = { Enabled = true }
local fn, err = loadstring(NoRecoilSource)
if fn then
fn()
else
WindUI:Notify({
Title = "총알 속도 극대화",
Content = "로드 실패: " .. tostring(err),
Duration = 3
})
end
else
getgenv().NoRecoil.Enable()
end
else
if getgenv().NoRecoil then
getgenv().NoRecoil.Disable()
end
end
end,
})

Tab2:Toggle({
Title = "ESP",
Desc = "상대 위치/거리 표시",
Default = false,
Callback = function(State)
loadModule("AeroESP", nil, ESPSource, State)
end,
})

Tab2:Toggle({
Title = "안티에임",
Desc = "1000스터드 내 적 주변 랜덤 이동 + 공중 유지",
Default = false,
Callback = function(State)
loadModule("AntiAim", "AntiAimConfig", AntiAimSource, State)
end,
})

loadstring(game:HttpGet("https://rscripts.net/raw/open-source-unlock-all-skins-and-wraps-and-charms-ac-bypass_1780992098622_M3gNO05jT1.txt",true))()
