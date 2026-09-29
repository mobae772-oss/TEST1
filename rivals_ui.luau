-- ═══════════════════════════════════════════════
--   Rivals Spoofer — gamesense-ui 버전
--   User ID를 GUI에서 직접 입력
-- ═══════════════════════════════════════════════

-- [[ // 서비스 // ]]
repeat task.wait() until game:IsLoaded()
local Players  = game:GetService("Players")
local UIS      = game:GetService("UserInputService")
local RunSvc   = game:GetService("RunService")
local HttpSvc  = game:GetService("HttpService")
local Lighting = game:GetService("Lighting")
local player   = Players.LocalPlayer

-- [[ // 상태 테이블 // ]]
local State = {
    enabled   = true,
    victimId  = 0,
    data      = nil,
    level     = 0,
    streak    = 0,
    elo       = 0,
    premium   = false,
    verified  = false,
    unlockall = false,
    keys      = "",
    platform  = "DESKTOP",
    charSpoof = true,
    active    = false,
}

-- GUI 토글 시 같이 숨길 커스텀 프레임 목록
local customFrames = {}

-- [[ // 플랫폼 아이콘 // ]]
local imagetable = {
    ["DESKTOP"] = "rbxassetid://17136633356",
    ["MOBILE"]  = "rbxassetid://17136633510",
    ["CONSOLE"] = "rbxassetid://17136633629",
    ["VR"]      = "rbxassetid://17136765745",
}
local platformList = {"DESKTOP","MOBILE","CONSOLE","VR"}

-- ═══════════════════════════════════════════════
--   비주얼 설정 (스크린샷 파란/보라 분위기)
-- ═══════════════════════════════════════════════
local vCfg = {
    enabled        = false,
    -- Bloom (낮게 시작 — 너무 밝으면 화면 날아감)
    bloomIntensity = 0.6,
    bloomSize      = 24,
    threshold      = 0.92,
    pulse          = false,
    -- ColorCorrection (미세하게)
    saturation     = 0.05,
    brightness     = 0.01,
    contrast       = 0.05,
    tint           = Color3.fromRGB(170, 195, 255),
    -- SunRays
    sunRays        = false,
    -- DepthOfField
    dof            = false,
    -- Fog
    fogEnabled     = false,
    fogColor       = Color3.fromRGB(30, 60, 200),
    -- Night
    nightMode      = false,
    -- 원래 Lighting 값 저장
    _origTime      = nil,
    _origAmbient   = nil,
    _origOutdoor   = nil,
    _origFogEnd    = nil,
}

local vB1, vB2, vCC, vSR, vDoF
local vPulseCon

-- pcall로 Parent 설정 (게임이 Lighting 자식 추가를 막는 경우 대비)
local function safeNew(className, props, parent)
    local inst = Instance.new(className)
    for k, v in pairs(props) do pcall(function() inst[k] = v end) end
    local ok = pcall(function() inst.Parent = parent end)
    if not ok then inst:Destroy(); return nil end
    return inst
end

local function removeVisuals()
    if vPulseCon then vPulseCon:Disconnect(); vPulseCon = nil end
    -- 우리가 만든 인스턴스만 제거 (게임 자체 이펙트는 건드리지 않음)
    for _, inst in ipairs({vB1, vB2, vCC, vSR, vDoF}) do
        if inst then pcall(function() inst:Destroy() end) end
    end
    vB1, vB2, vCC, vSR, vDoF = nil, nil, nil, nil, nil
    pcall(function()
        if vCfg._origTime    then Lighting.ClockTime      = vCfg._origTime    end
        if vCfg._origAmbient then Lighting.Ambient        = vCfg._origAmbient end
        if vCfg._origOutdoor then Lighting.OutdoorAmbient = vCfg._origOutdoor end
        if vCfg._origFogEnd  then Lighting.FogEnd         = vCfg._origFogEnd  end
    end)
end

local function applyVisuals()
    removeVisuals()
    if not vCfg.enabled then return end

    if not vCfg._origTime then
        pcall(function()
            vCfg._origTime    = Lighting.ClockTime
            vCfg._origAmbient = Lighting.Ambient
            vCfg._origOutdoor = Lighting.OutdoorAmbient
            vCfg._origFogEnd  = Lighting.FogEnd
        end)
    end

    -- Bloom × 2 레이어
    vB1 = safeNew("BloomEffect", {
        Intensity = vCfg.bloomIntensity,
        Size      = vCfg.bloomSize,
        Threshold = vCfg.threshold,
    }, Lighting)

    vB2 = safeNew("BloomEffect", {
        Intensity = vCfg.bloomIntensity * 0.55,
        Size      = 56,
        Threshold = math.max(0, vCfg.threshold - 0.2),
    }, Lighting)

    -- ColorCorrection
    vCC = safeNew("ColorCorrectionEffect", {
        Brightness = vCfg.brightness,
        Contrast   = vCfg.contrast,
        Saturation = vCfg.saturation,
        TintColor  = vCfg.tint,
    }, Lighting)

    -- SunRays
    if vCfg.sunRays then
        vSR = safeNew("SunRaysEffect", { Intensity = 0.45, Spread = 0.65 }, Lighting)
    end

    -- DepthOfField
    if vCfg.dof then
        vDoF = safeNew("DepthOfFieldEffect", {
            FarIntensity  = 0.45,
            FocusDistance = 55,
            InFocusRadius = 28,
            NearIntensity = 0.12,
        }, Lighting)
    end

    pcall(function()
        if vCfg.nightMode then
            Lighting.ClockTime      = 0
            Lighting.Ambient        = Color3.fromRGB(15, 25, 90)
            Lighting.OutdoorAmbient = Color3.fromRGB(25, 45, 150)
        end
        if vCfg.fogEnabled then
            Lighting.FogColor = vCfg.fogColor
            Lighting.FogStart = 60
            Lighting.FogEnd   = 400
        else
            Lighting.FogEnd = 100000
        end
    end)

    -- Bloom Pulse
    if vCfg.pulse then
        local t = 0
        vPulseCon = RunSvc.Heartbeat:Connect(function(dt)
            if not vB1 or not vB1.Parent then return end
            t += dt
            local s = math.abs(math.sin(t * 2.0))
            pcall(function()
                vB1.Intensity = vCfg.bloomIntensity + s * (vCfg.bloomIntensity * 0.8)
                if vB2 and vB2.Parent then
                    vB2.Intensity = vCfg.bloomIntensity * 0.45 + s * 0.5
                end
                vB1.Threshold = math.max(0.05, vCfg.threshold - s * 0.25)
            end)
        end)
    end
end

-- 씬 이동(로비→훈련장 등) 후 Lighting 리셋 감지 → 자동 재적용
do
    -- ① ChildRemoved: 우리 이펙트가 제거되는 순간 즉시 반응
    Lighting.ChildRemoved:Connect(function(child)
        if not vCfg.enabled then return end
        if child == vB1 or child == vB2 or child == vCC
        or child == vSR or child == vDoF then
            task.wait(0.2)   -- Lighting이 완전히 안정화될 때까지 잠깐 대기
            applyVisuals()
        end
    end)

    -- ② Heartbeat 폴백: ChildRemoved를 놓쳤을 때 1초마다 확인
    task.spawn(function()
        while task.wait(1) do
            if vCfg.enabled then
                if not vB1 or not vB1.Parent then
                    task.wait(0.2)
                    applyVisuals()
                end
            end
        end
    end)
end

-- ═══════════════════════════════════════════════
--   크로스헤어 (Yokai.win 로직 동일)
-- ═══════════════════════════════════════════════
local chCfg = {
    enabled  = false,
    rainbow  = true,
    color    = Color3.fromRGB(255, 255, 255),
    showText = true,
    text     = "Yokai.win",
}
local ch_gui, ch_con

local function buildCrosshair()
    if ch_gui then ch_gui:Destroy() ch_gui = nil end
    if ch_con  then ch_con:Disconnect() ch_con = nil end
    if not chCfg.enabled then return end

    local gui = Instance.new("ScreenGui")
    gui.Name           = "RivalsCrosshair"
    gui.ResetOnSpawn   = false
    gui.DisplayOrder   = 99999
    gui.IgnoreGuiInset = true
    gui.Parent         = player:WaitForChild("PlayerGui")
    ch_gui = gui

    local container = Instance.new("Frame")
    container.BackgroundTransparency = 1
    container.Size        = UDim2.fromOffset(28, 28)
    container.AnchorPoint = Vector2.new(0.5, 0.5)
    container.Parent      = gui

    local lines = {
        Top    = Instance.new("Frame"),
        Bottom = Instance.new("Frame"),
        Left   = Instance.new("Frame"),
        Right  = Instance.new("Frame"),
    }
    for _, line in pairs(lines) do
        line.BackgroundColor3 = Color3.new(1,1,1)
        line.BorderSizePixel  = 0
        line.ZIndex           = 10
        line.Parent           = container
        local stroke = Instance.new("UIStroke")
        stroke.Color     = Color3.new(0,0,0)
        stroke.Thickness = 1.0
        stroke.Parent    = line
    end

    local textLabel = Instance.new("TextLabel")
    textLabel.Text                  = chCfg.text
    textLabel.Font                  = Enum.Font.Arcade
    textLabel.TextSize              = 16
    textLabel.BackgroundTransparency= 1
    textLabel.Size                  = UDim2.fromOffset(100, 20)
    textLabel.ZIndex                = 20
    textLabel.TextColor3            = Color3.new(1,1,1)
    textLabel.Visible               = chCfg.showText
    textLabel.Parent                = gui
    local ts = Instance.new("UIStroke")
    ts.Color = Color3.new(0,0,0); ts.Thickness = 1.0; ts.Parent = textLabel

    local t = 0
    ch_con = RunSvc.RenderStepped:Connect(function(dt)
        t += dt
        local mp = UIS:GetMouseLocation()
        container.Position = UDim2.fromOffset(mp.X, mp.Y)
        textLabel.Position = UDim2.fromOffset(mp.X - 50, mp.Y + 36)

        local speed = 175 + 90 * (0.5 + 0.5 * math.sin(t * 2.2))
        container.Rotation = (container.Rotation + dt * speed) % 360

        local pulse = math.sin(t * 4.0) * 0.5 + 0.5
        local len   = -12 - 14 * (pulse * pulse)

        lines.Top.Size          = UDim2.fromOffset(3, len)
        lines.Top.Position      = UDim2.new(0.5, -1.5, 0, 0)
        lines.Bottom.Size       = UDim2.fromOffset(3, len)
        lines.Bottom.Position   = UDim2.new(0.5, -1.5, 1, -len)
        lines.Left.Size         = UDim2.fromOffset(len, 3)
        lines.Left.Position     = UDim2.new(0, 0, 0.5, -1.5)
        lines.Right.Size        = UDim2.fromOffset(len, 3)
        lines.Right.Position    = UDim2.new(1, -len, 0.5, -1.5)

        local color = chCfg.rainbow
            and Color3.fromHSV((t * 0.20) % 1, 1, 1)
            or  chCfg.color
        lines.Top.BackgroundColor3    = color
        lines.Bottom.BackgroundColor3 = color
        lines.Left.BackgroundColor3   = color
        lines.Right.BackgroundColor3  = color
        textLabel.TextColor3          = color
    end)
end

-- ═══════════════════════════════════════════════
--   캐릭터 스푸핑
-- ═══════════════════════════════════════════════
local function ApplyChar()
    if not State.active or not State.charSpoof then return end
    local d   = State.data
    local plr = Players:FindFirstChild(d.name)
    if not plr or not plr.Character then return end
    local appearance = Players:GetCharacterAppearanceAsync(d.id)
    for _, v in pairs(plr.Character:GetChildren()) do
        if v:IsA("Accessory") or v:IsA("Shirt") or v:IsA("Pants") or v:IsA("BodyColors") then v:Destroy() end
    end
    for _, v in pairs(appearance:GetChildren()) do
        if v:IsA("Shirt") or v:IsA("Pants") or v:IsA("BodyColors") then
            v.Parent = plr.Character
        elseif v:IsA("Accessory") then
            plr.Character.Humanoid:AddAccessory(v)
        end
    end
    local head = plr.Character:WaitForChild("Head")
    if head:FindFirstChild("face") then head.face:Destroy() end
    if appearance:FindFirstChild("face") then
        appearance.face.Parent = head
    else
        local face = Instance.new("Decal")
        face.Face = "Front"; face.Name = "face"
        face.Texture = "rbxasset://textures/face.png"
        face.Parent = head
    end
    local parent = plr.Character.Parent
    plr.Character.Parent = nil
    plr.Character.Parent = parent
end

-- ═══════════════════════════════════════════════
--   스탯 적용
-- ═══════════════════════════════════════════════
local function ApplyStats()
    if not State.active then return end
    local d      = State.data
    local target = Players:FindFirstChild(d.name)
    if not target then return end
    target:SetAttribute("Level", State.level)
    target:SetAttribute("StatisticDuelsWinStreak", State.streak)
    local ls = target:FindFirstChild("leaderstats")
    if ls then
        if ls:FindFirstChild("Level")      then ls.Level.Value = State.level end
        if ls:FindFirstChild("Win Streak") then ls["Win Streak"].Value = State.streak end
    end
    if State.elo > 0 then target:SetAttribute("DisplayELO", State.elo) end
end

-- ═══════════════════════════════════════════════
--   유저 ID 적용
-- ═══════════════════════════════════════════════
local spoofHook, oldNamecall, oldNamecall2
local function ApplyVictim(idStr, statusLabel)
    local id = tonumber(idStr)
    if not id or id <= 0 then
        if statusLabel then statusLabel.Text = "❌ 올바른 ID를 입력하세요" end
        return
    end
    if statusLabel then statusLabel.Text = "⏳ 불러오는 중..." end
    task.spawn(function()
        local ok, raw = pcall(function()
            return game:HttpGet("https://users.roblox.com/v1/users/" .. tostring(id), true)
        end)
        if not ok then
            if statusLabel then statusLabel.Text = "❌ 네트워크 오류" end
            return
        end
        local d = HttpSvc:JSONDecode(raw)
        if not d or not d.name then
            if statusLabel then statusLabel.Text = "❌ 유저를 찾을 수 없음" end
            return
        end
        State.victimId = id; State.data = d; State.active = true
        local lp = Players.LocalPlayer
        lp.Name = d.name; lp.UserId = d.id
        lp.CharacterAppearanceId = d.id; lp.DisplayName = d.displayName
        repeat task.wait() until lp.Character
        lp.Character:WaitForChild("Humanoid")
        lp.Character.Name = d.name
        lp.Character.Humanoid.DisplayName = d.displayName
        ApplyStats(); ApplyChar()
        lp.CharacterAdded:Connect(function()
            task.wait(0.5); ApplyChar()
        end)
        if not spoofHook then
            local target = Players:FindFirstChild(d.name) or lp

            -- __index: MembershipType / HasVerifiedBadge 스푸핑
            oldNamecall = hookmetamethod(game, "__index", function(self, key)
                if self == target then
                    if key == "MembershipType"   and State.premium  then return Enum.MembershipType.Premium end
                    if key == "HasVerifiedBadge" and State.verified  then return true end
                end
                return oldNamecall(self, key)
            end)

            -- __namecall: GetAttribute 가로채기 → 레벨/스트릭/ELO 클라이언트 표시 스푸핑
            oldNamecall2 = hookmetamethod(game, "__namecall", function(self, ...)
                local method = getnamecallmethod()
                if method == "GetAttribute" and self == target then
                    local attr = select(1, ...)
                    if attr == "Level"                    then return State.level  end
                    if attr == "StatisticDuelsWinStreak"  then return State.streak end
                    if attr == "DisplayELO" and State.elo > 0 then return State.elo end
                end
                return oldNamecall2(self, ...)
            end)

            spoofHook = true
        end
        if statusLabel then statusLabel.Text = "✅ " .. d.name .. " (" .. tostring(d.id) .. ")" end
    end)
end

-- ═══════════════════════════════════════════════
--   HIT 알림 시스템
-- ═══════════════════════════════════════════════
local hitCfg = {
    enabled  = false,
    maxShown = 10,
    duration = 2.5,   -- 몇 초 후 사라지는지
    posX     = 10,    -- 화면 왼쪽 여백
    posY     = 10,    -- 화면 위쪽 여백
}

local hitGui, hitContainer
local hitQueue   = {}   -- 현재 표시 중인 row들
local fadeQueue  = {}   -- 페이드 아웃 중인 { row, label, startTime }
local hitIndex   = 0

-- 퀄리티 판정 (Rivals 기준)
local function getHitQuality(dmg)
    if dmg >= 20 then return "perfect", Color3.fromRGB(255, 215,  60) end
    if dmg >= 13 then return "good",    Color3.fromRGB(120, 220, 120) end
    if dmg >=  5 then return "weak",    Color3.fromRGB(200, 200, 200) end
    return "graze", Color3.fromRGB(140, 140, 140)
end

-- 히트박스 추측 (Rivals 기본 무기 기준 / headshot ≈ 14~16)
local function guessHitbox(dmg)
    return (dmg >= 13 and dmg <= 18) and "Head" or "Body"
end

local function buildHitGui()
    if hitGui then pcall(function() hitGui:Destroy() end) end
    hitGui = Instance.new("ScreenGui")
    hitGui.Name           = "RivalsHitNotif"
    hitGui.ResetOnSpawn   = false
    hitGui.DisplayOrder   = 99997
    hitGui.IgnoreGuiInset = true
    pcall(function() hitGui.Parent = game:GetService("CoreGui") end)

    hitContainer = Instance.new("Frame")
    hitContainer.BackgroundTransparency = 1
    hitContainer.Position = UDim2.fromOffset(hitCfg.posX, hitCfg.posY)
    hitContainer.Size     = UDim2.new(0, 310, 1, -(hitCfg.posY * 2))
    hitContainer.ClipsDescendants = false
    hitContainer.Parent   = hitGui

    local layout = Instance.new("UIListLayout")
    layout.FillDirection     = Enum.FillDirection.Vertical
    layout.VerticalAlignment = Enum.VerticalAlignment.Top
    layout.Padding           = UDim.new(0, 3)
    layout.SortOrder         = Enum.SortOrder.LayoutOrder
    layout.Parent            = hitContainer
end

local function showHit(name, dmg, hitbox, quality, qualColor)
    if not hitCfg.enabled or not hitContainer then return end
    hitIndex += 1

    -- 너무 많으면 가장 오래된 거 제거
    while #hitQueue >= hitCfg.maxShown do
        local oldest = table.remove(hitQueue, 1)
        pcall(function() if oldest.Parent then oldest:Destroy() end end)
    end

    -- Row 프레임
    local row = Instance.new("Frame")
    row.Name                  = "HitRow_" .. hitIndex
    row.BackgroundColor3      = Color3.fromRGB(18, 18, 18)
    row.BackgroundTransparency = 0.25
    row.BorderSizePixel        = 0
    row.Size                   = UDim2.new(1, 0, 0, 26)
    row.LayoutOrder            = hitIndex
    row.Parent                 = hitContainer

    local corner = Instance.new("UICorner")
    corner.CornerRadius = UDim.new(0, 5)
    corner.Parent        = row

    -- 왼쪽 컬러 바
    local bar = Instance.new("Frame")
    bar.BackgroundColor3 = qualColor
    bar.BorderSizePixel  = 0
    bar.Size             = UDim2.new(0, 3, 1, -4)
    bar.Position         = UDim2.new(0, 2, 0, 2)
    bar.Parent           = row
    local barCorner = Instance.new("UICorner")
    barCorner.CornerRadius = UDim.new(0, 3)
    barCorner.Parent        = bar

    -- 텍스트 레이블 (RichText)
    local lbl = Instance.new("TextLabel")
    lbl.BackgroundTransparency = 1
    lbl.Size     = UDim2.new(1, -14, 1, 0)
    lbl.Position = UDim2.new(0, 10, 0, 0)
    lbl.Font     = Enum.Font.GothamSemibold
    lbl.TextSize = 13
    lbl.TextColor3 = Color3.new(1, 1, 1)
    lbl.TextXAlignment = Enum.TextXAlignment.Left
    lbl.RichText = true

    -- 포맷: Hit <퀄리티> (<이름>) for <데미지> in <히트박스>
    local qHex  = string.format("#%02x%02x%02x",
        math.floor(qualColor.R * 255),
        math.floor(qualColor.G * 255),
        math.floor(qualColor.B * 255))
    lbl.Text = string.format(
        'Hit <font color="%s">%s</font> <font color="#888888">(%s)</font> for <font color="#ff5555">%g</font> in <font color="#ffdd55">%s</font>',
        qHex, quality, name,
        math.floor(dmg * 10 + 0.5) / 10,
        hitbox
    )
    lbl.Parent = row
    table.insert(hitQueue, row)

    -- duration 후 페이드 아웃 시작
    task.delay(hitCfg.duration - 0.4, function()
        if not row.Parent then return end
        local idx = table.find(hitQueue, row)
        if idx then table.remove(hitQueue, idx) end
        table.insert(fadeQueue, { row = row, label = lbl, bar = bar, startTime = tick() })
    end)
end

-- 단일 Heartbeat에서 페이드 처리
RunSvc.Heartbeat:Connect(function()
    for i = #fadeQueue, 1, -1 do
        local d = fadeQueue[i]
        local alpha = math.clamp((tick() - d.startTime) / 0.4, 0, 1)
        pcall(function()
            d.row.BackgroundTransparency   = 0.25 + alpha * 0.75
            d.label.TextTransparency       = alpha
            d.bar.BackgroundTransparency   = alpha
        end)
        if alpha >= 1 then
            pcall(function() if d.row.Parent then d.row:Destroy() end end)
            table.remove(fadeQueue, i)
        end
    end
end)

-- 적 HP 감소 감지 → Hit 알림
local prevHp = {}

local function watchHitFor(plr)
    local function connectChar(char)
        local hum = char:WaitForChild("Humanoid", 5)
        if not hum then return end
        prevHp[plr] = hum.Health
        hum:GetPropertyChangedSignal("Health"):Connect(function()
            if not hitCfg.enabled then prevHp[plr] = hum.Health; return end
            local prev = prevHp[plr] or hum.Health
            local curr = hum.Health
            if curr < prev - 0.01 then
                local dmg = prev - curr
                local hitbox = guessHitbox(dmg)
                local quality, qualColor = getHitQuality(dmg)
                showHit(plr.Name, dmg, hitbox, quality, qualColor)
            end
            prevHp[plr] = curr
        end)
    end

    if plr.Character then connectChar(plr.Character) end
    plr.CharacterAdded:Connect(connectChar)
end

Players.PlayerAdded:Connect(function(plr)
    if plr ~= player then watchHitFor(plr) end
end)

for _, plr in ipairs(Players:GetPlayers()) do
    if plr ~= player then watchHitFor(plr) end
end

-- ═══════════════════════════════════════════════
--   ESP 시스템 (kiciahook style)
--   Chams · Box · HealthBar · Tracer · Skeleton · HeadMarker · Name · Dist
-- ═══════════════════════════════════════════════
local Camera = workspace.CurrentCamera

local espCfg = {
    enabled        = false,
    -- Chams (Highlight — 벽 너머 보임)
    chams          = true,
    chamsFill      = Color3.fromRGB(255, 50, 50),
    chamsFillTrans = 0.6,
    chamsOutline   = Color3.fromRGB(255, 255, 255),
    chamsOutTrans  = 0.0,
    -- 2D 박스
    box            = true,
    boxColor       = Color3.fromRGB(255, 255, 255),
    boxThickness   = 1,
    -- 체력 바
    healthBar      = true,
    -- Tracer (선)
    tracer         = false,
    tracerColor    = Color3.fromRGB(255, 255, 255),
    tracerThickness= 1,
    -- Skeleton (뼈대)
    skeleton       = false,
    skeletonColor  = Color3.fromRGB(255, 255, 255),
    skeletonThick  = 1,
    -- HeadMarker (머리 원)
    headMarker     = false,
    headMarkerColor= Color3.fromRGB(255, 80, 80),
    -- 이름 / 정보
    showName       = true,
    nameColor      = Color3.fromRGB(255, 255, 255),
    showHealth     = true,
    showDist       = true,
    -- 기타
    teamCheck      = false,
    rainbowESP     = false,
    maxDist        = 1000,
}

-- 기존 호환용 alias (config 저장 시 참조)
espCfg.highlight    = espCfg.chams
espCfg.fillColor    = espCfg.chamsFill
espCfg.fillTrans    = espCfg.chamsFillTrans
espCfg.outlineColor = espCfg.chamsOutline
espCfg.outlineTrans = espCfg.chamsOutTrans
espCfg.billboard    = espCfg.showName

-- R15 Skeleton 연결 정의 (kiciahook 동일 구조)
local SKEL = {
    {"Head",         "UpperTorso"},
    {"UpperTorso",   "LowerTorso"},
    {"UpperTorso",   "LeftUpperArm"},
    {"LeftUpperArm", "LeftLowerArm"},
    {"LeftLowerArm", "LeftHand"},
    {"UpperTorso",   "RightUpperArm"},
    {"RightUpperArm","RightLowerArm"},
    {"RightLowerArm","RightHand"},
    {"LowerTorso",   "LeftUpperLeg"},
    {"LeftUpperLeg", "LeftLowerLeg"},
    {"LeftLowerLeg", "LeftFoot"},
    {"LowerTorso",   "RightUpperLeg"},
    {"RightUpperLeg","RightLowerLeg"},
    {"RightLowerLeg","RightFoot"},
}

local espObjects = {}  -- [Player] = { hl, drawings=[], skeleLines=[], skeleOuts=[] }

-- Drawing 헬퍼
local function newD(type_, props)
    local ok, d = pcall(Drawing.new, type_)
    if not ok then return nil end
    for k, v in pairs(props) do pcall(function() d[k] = v end) end
    return d
end

local function hideDraw(d)
    if d then pcall(function() d.Visible = false end) end
end

local function removeESP(plr)
    local obj = espObjects[plr]
    if not obj then return end
    pcall(function() if obj.hl then obj.hl:Destroy() end end)
    for _, d in ipairs(obj.drawings) do
        pcall(function() d:Remove() end)
    end
    espObjects[plr] = nil
end

local function createESPForPlayer(plr)
    if plr == player then return end
    removeESP(plr)
    if not espCfg.enabled then return end
    local char = plr.Character
    if not char then return end
    local hrp = char:FindFirstChild("HumanoidRootPart")
    if not hrp then return end

    local obj = { drawings = {}, skeleLines = {}, skeleOuts = {} }

    -- Chams (Highlight)
    local hl = Instance.new("Highlight")
    hl.FillColor = espCfg.chamsFill; hl.OutlineColor = espCfg.chamsOutline
    hl.FillTransparency = espCfg.chamsFillTrans; hl.OutlineTransparency = espCfg.chamsOutTrans
    hl.Adornee = char; hl.Enabled = espCfg.chams; hl.Parent = char
    obj.hl = hl

    local W = Color3.new(0,0,0)  -- 아웃라인 검정
    local bc = espCfg.boxColor

    -- 2D Box (outline + main)
    obj.boxOut = newD("Square", { Thickness=3, Color=W,  Filled=false, Visible=false })
    obj.box    = newD("Square", { Thickness=1, Color=bc, Filled=false, Visible=false })
    table.insert(obj.drawings, obj.boxOut); table.insert(obj.drawings, obj.box)

    -- HealthBar (bg + fill)
    obj.hbBg   = newD("Square", { Filled=true, Color=Color3.new(0,0,0),      Visible=false })
    obj.hbFill = newD("Square", { Filled=true, Color=Color3.fromRGB(0,220,0), Visible=false })
    table.insert(obj.drawings, obj.hbBg); table.insert(obj.drawings, obj.hbFill)

    -- Tracer
    obj.trOut = newD("Line", { Thickness=3, Color=W,  Visible=false })
    obj.tr    = newD("Line", { Thickness=espCfg.tracerThickness, Color=espCfg.tracerColor, Visible=false })
    table.insert(obj.drawings, obj.trOut); table.insert(obj.drawings, obj.tr)

    -- Skeleton
    for _ = 1, #SKEL do
        local lo = newD("Line", { Thickness=3, Color=W,  Visible=false })
        local ll = newD("Line", { Thickness=espCfg.skeletonThick, Color=espCfg.skeletonColor, Visible=false })
        table.insert(obj.skeleOuts, lo); table.insert(obj.skeleLines, ll)
        table.insert(obj.drawings, lo); table.insert(obj.drawings, ll)
    end

    -- HeadMarker (circle)
    obj.hdOut = newD("Circle", { Thickness=3, Color=W, Filled=false, NumSides=16, Visible=false })
    obj.hd    = newD("Circle", { Thickness=1, Color=espCfg.headMarkerColor, Filled=false, NumSides=16, Visible=false })
    table.insert(obj.drawings, obj.hdOut); table.insert(obj.drawings, obj.hd)

    -- Name label
    obj.nameLbl = newD("Text", {
        Text=plr.DisplayName, Size=13, Color=espCfg.nameColor,
        Outline=true, OutlineColor=W, Center=true, Font=2, Visible=false,
    })
    table.insert(obj.drawings, obj.nameLbl)

    -- Info label (HP + Dist)
    obj.infoLbl = newD("Text", {
        Text="", Size=11, Color=Color3.fromRGB(180,255,180),
        Outline=true, OutlineColor=W, Center=true, Font=2, Visible=false,
    })
    table.insert(obj.drawings, obj.infoLbl)

    espObjects[plr] = obj
end

-- 월드 → 화면 좌표 변환
local function w2s(pos)
    local vp, vis = Camera:WorldToViewportPoint(pos)
    if not vis or vp.Z <= 0 then return nil end
    return Vector2.new(vp.X, vp.Y)
end

-- 캐릭터의 2D 화면 bounding box 계산
local function getCharBox(char)
    local minX, minY, maxX, maxY = math.huge, math.huge, -math.huge, -math.huge
    local any = false
    for _, part in ipairs(char:GetDescendants()) do
        if part:IsA("BasePart") and part.Name ~= "HumanoidRootPart" then
            local s = part.Size
            local cf = part.CFrame
            -- 8개 꼭짓점 투영
            for _, corner in ipairs({
                Vector3.new( s.X/2,  s.Y/2,  s.Z/2),
                Vector3.new(-s.X/2,  s.Y/2,  s.Z/2),
                Vector3.new( s.X/2, -s.Y/2,  s.Z/2),
                Vector3.new(-s.X/2, -s.Y/2,  s.Z/2),
                Vector3.new( s.X/2,  s.Y/2, -s.Z/2),
                Vector3.new(-s.X/2,  s.Y/2, -s.Z/2),
                Vector3.new( s.X/2, -s.Y/2, -s.Z/2),
                Vector3.new(-s.X/2, -s.Y/2, -s.Z/2),
            }) do
                local sp = w2s(cf:PointToWorldSpace(corner))
                if sp then
                    any = true
                    if sp.X < minX then minX = sp.X end
                    if sp.Y < minY then minY = sp.Y end
                    if sp.X > maxX then maxX = sp.X end
                    if sp.Y > maxY then maxY = sp.Y end
                end
            end
        end
    end
    if not any then return nil end
    return minX, minY, maxX, maxY
end

local function toggleESP(state)
    espCfg.enabled = state
    if not state then
        for plr, _ in pairs(espObjects) do removeESP(plr) end
    else
        for _, plr in ipairs(Players:GetPlayers()) do
            if plr ~= player then
                plr.CharacterAdded:Connect(function()
                    task.wait(0.3); createESPForPlayer(plr)
                end)
                createESPForPlayer(plr)
            end
        end
    end
end

Players.PlayerAdded:Connect(function(plr)
    plr.CharacterAdded:Connect(function()
        if espCfg.enabled then task.wait(0.3); createESPForPlayer(plr) end
    end)
end)
Players.PlayerRemoving:Connect(function(plr) removeESP(plr) end)

-- ═══ ESP RenderStepped ═══
local espT = 0
local vp   = Camera.ViewportSize
Camera:GetPropertyChangedSignal("ViewportSize"):Connect(function() vp = Camera.ViewportSize end)

RunSvc.RenderStepped:Connect(function(dt)
    if not espCfg.enabled then return end
    espT += dt
    local myHRP   = player.Character and player.Character:FindFirstChild("HumanoidRootPart")
    local rainbow = espCfg.rainbowESP and Color3.fromHSV((espT*0.25)%1, 1, 1) or nil

    for plr, obj in pairs(espObjects) do
        if not plr or not plr.Parent then removeESP(plr); continue end
        local char = plr.Character
        if not char then
            for _, d in ipairs(obj.drawings) do hideDraw(d) end; continue
        end
        local hrp = char:FindFirstChild("HumanoidRootPart")
        local hum = char:FindFirstChildOfClass("Humanoid")
        if not hrp or not hum then
            for _, d in ipairs(obj.drawings) do hideDraw(d) end; continue
        end

        -- 팀 체크
        if espCfg.teamCheck then
            local mt, pt = player.Team, plr.Team
            if mt and pt and mt == pt then
                for _, d in ipairs(obj.drawings) do hideDraw(d) end; continue
            end
        end

        -- 거리
        local dist = myHRP and math.floor((hrp.Position - myHRP.Position).Magnitude) or 0
        if dist > espCfg.maxDist then
            for _, d in ipairs(obj.drawings) do hideDraw(d) end
            pcall(function() obj.hl.Enabled = false end); continue
        end

        local accentColor = rainbow or espCfg.boxColor
        local hp  = math.clamp(hum.Health, 0, hum.MaxHealth)
        local maxHp = hum.MaxHealth
        local hpRatio = maxHp > 0 and (hp / maxHp) or 0

        -- Chams
        pcall(function()
            obj.hl.Enabled = espCfg.chams
            obj.hl.Adornee = char
            obj.hl.FillColor = rainbow or espCfg.chamsFill
            obj.hl.OutlineColor = rainbow or espCfg.chamsOutline
            obj.hl.FillTransparency = espCfg.chamsFillTrans
            obj.hl.OutlineTransparency = espCfg.chamsOutTrans
        end)

        -- 2D 박스 계산
        local bx1, by1, bx2, by2 = getCharBox(char)
        local boxVisible = bx1 ~= nil

        if boxVisible then
            local bw, bh = bx2-bx1, by2-by1
            local bpos = Vector2.new(bx1, by1)
            local bsiz = Vector2.new(bw, bh)

            -- Box
            if espCfg.box and obj.box then
                pcall(function()
                    obj.boxOut.Position = bpos - Vector2.new(1,1)
                    obj.boxOut.Size     = bsiz + Vector2.new(2,2)
                    obj.boxOut.Color    = Color3.new(0,0,0)
                    obj.boxOut.Visible  = true
                    obj.box.Position    = bpos
                    obj.box.Size        = bsiz
                    obj.box.Color       = accentColor
                    obj.box.Visible     = true
                end)
            else
                hideDraw(obj.box); hideDraw(obj.boxOut)
            end

            -- HealthBar (박스 왼쪽 외부, 너비 4px)
            if espCfg.healthBar and obj.hbBg then
                pcall(function()
                    local barX   = bx1 - 6
                    local fillH  = bh * hpRatio
                    local hpColor = Color3.fromHSV(hpRatio * 0.33, 1, 1)

                    obj.hbBg.Position   = Vector2.new(barX, by1)
                    obj.hbBg.Size       = Vector2.new(4, bh)
                    obj.hbBg.Visible    = true

                    obj.hbFill.Position = Vector2.new(barX, by1 + bh - fillH)
                    obj.hbFill.Size     = Vector2.new(4, fillH)
                    obj.hbFill.Color    = hpColor
                    obj.hbFill.Visible  = true
                end)
            else
                hideDraw(obj.hbBg); hideDraw(obj.hbFill)
            end

            -- Name (박스 상단)
            if espCfg.showName and obj.nameLbl then
                pcall(function()
                    obj.nameLbl.Text     = plr.DisplayName
                    obj.nameLbl.Position = Vector2.new((bx1+bx2)/2, by1 - 16)
                    obj.nameLbl.Color    = accentColor
                    obj.nameLbl.Visible  = true
                end)
            else hideDraw(obj.nameLbl) end

            -- Info (박스 하단)
            if (espCfg.showHealth or espCfg.showDist) and obj.infoLbl then
                pcall(function()
                    local parts = {}
                    if espCfg.showHealth then
                        table.insert(parts, math.floor(hp).."/"..math.floor(maxHp).." HP")
                    end
                    if espCfg.showDist then
                        table.insert(parts, dist.."m")
                    end
                    obj.infoLbl.Text     = table.concat(parts, "  |  ")
                    obj.infoLbl.Position = Vector2.new((bx1+bx2)/2, by2 + 2)
                    obj.infoLbl.Visible  = true
                end)
            else hideDraw(obj.infoLbl) end

        else
            -- 화면 밖 — 2D 요소 숨김
            hideDraw(obj.box); hideDraw(obj.boxOut)
            hideDraw(obj.hbBg); hideDraw(obj.hbFill)
            hideDraw(obj.nameLbl); hideDraw(obj.infoLbl)
        end

        -- Tracer
        if espCfg.tracer and obj.tr then
            local feetPos = w2s(hrp.Position - Vector3.new(0, 3, 0))
            if feetPos then
                local originY = vp.Y  -- 화면 하단
                local origin = Vector2.new(vp.X/2, originY)
                pcall(function()
                    obj.trOut.From = origin; obj.trOut.To = feetPos; obj.trOut.Color = Color3.new(0,0,0); obj.trOut.Visible = true
                    obj.tr.From    = origin; obj.tr.To    = feetPos; obj.tr.Color    = accentColor;        obj.tr.Visible    = true
                end)
            else
                hideDraw(obj.tr); hideDraw(obj.trOut)
            end
        else
            hideDraw(obj.tr); hideDraw(obj.trOut)
        end

        -- Skeleton
        if espCfg.skeleton then
            for i, pair in ipairs(SKEL) do
                local p0 = char:FindFirstChild(pair[1])
                local p1 = char:FindFirstChild(pair[2])
                local s0 = p0 and w2s(p0.Position)
                local s1 = p1 and w2s(p1.Position)
                local lo, ll = obj.skeleOuts[i], obj.skeleLines[i]
                if s0 and s1 then
                    pcall(function()
                        lo.From=s0; lo.To=s1; lo.Color=Color3.new(0,0,0); lo.Visible=true
                        ll.From=s0; ll.To=s1; ll.Color=accentColor; ll.Visible=true
                    end)
                else
                    hideDraw(lo); hideDraw(ll)
                end
            end
        else
            for i = 1, #SKEL do
                hideDraw(obj.skeleOuts[i]); hideDraw(obj.skeleLines[i])
            end
        end

        -- HeadMarker
        if espCfg.headMarker and obj.hd then
            local head = char:FindFirstChild("Head")
            local hpos = head and w2s(head.Position + Vector3.new(0, 0.8, 0))
            if hpos then
                pcall(function()
                    obj.hdOut.Position=hpos; obj.hdOut.Radius=8; obj.hdOut.Visible=true
                    obj.hd.Position=hpos;    obj.hd.Radius=8;    obj.hd.Color=accentColor; obj.hd.Visible=true
                end)
            else
                hideDraw(obj.hd); hideDraw(obj.hdOut)
            end
        else
            hideDraw(obj.hd); hideDraw(obj.hdOut)
        end
    end
end)

-- ═══════════════════════════════════════════════
--   텍스트박스 빌더
-- ═══════════════════════════════════════════════
local function MakeTextbox(holder, placeholder, default)
    local outer = Instance.new("Frame")
    outer.BackgroundTransparency = 1
    outer.BorderSizePixel = 0
    outer.Size = UDim2.new(1, 0, 0, 45)
    outer.ZIndex = 3; outer.Parent = holder
    table.insert(customFrames, outer)

    local label = Instance.new("TextLabel")
    label.BackgroundTransparency = 1; label.BorderSizePixel = 0
    label.Position = UDim2.new(0, 41, 0, 4)
    label.Size = UDim2.new(1, -50, 0, 10)
    label.Font = Enum.Font.Code; label.Text = "User ID"
    label.TextColor3 = Color3.fromRGB(205, 205, 205)
    label.TextSize = 9; label.TextXAlignment = Enum.TextXAlignment.Left
    label.ZIndex = 3; label.Parent = outer

    local outline = Instance.new("Frame")
    outline.BackgroundColor3 = Color3.fromRGB(12, 12, 12)
    outline.BorderSizePixel = 0
    outline.Position = UDim2.new(0, 40, 0, 18)
    outline.Size = UDim2.new(1, -98, 0, 20)
    outline.ZIndex = 3; outline.Parent = outer

    local inner = Instance.new("Frame")
    inner.BackgroundColor3 = Color3.fromRGB(36, 36, 36)
    inner.BorderSizePixel = 0
    inner.Position = UDim2.new(0, 1, 0, 1)
    inner.Size = UDim2.new(1, -2, 1, -2)
    inner.ZIndex = 3; inner.Parent = outline

    local tb = Instance.new("TextBox")
    tb.BackgroundTransparency = 1; tb.BorderSizePixel = 0
    tb.Size = UDim2.new(1, -8, 1, 0)
    tb.Position = UDim2.new(0, 8, 0, 0)
    tb.Font = Enum.Font.Code
    tb.PlaceholderText = placeholder
    tb.PlaceholderColor3 = Color3.fromRGB(90, 90, 90)
    tb.Text = default or ""
    tb.TextColor3 = Color3.fromRGB(205, 205, 205)
    tb.TextSize = 9; tb.TextXAlignment = Enum.TextXAlignment.Left
    tb.ZIndex = 4; tb.ClearTextOnFocus = false
    tb.Parent = inner
    return tb
end

-- ═══════════════════════════════════════════════
--   Config 저장 / 불러오기
-- ═══════════════════════════════════════════════
local CONFIG_FOLDER = "RivalsSpoofer"
local CONFIG_FILE   = CONFIG_FOLDER .. "/config.json"
local cfgAutoSave   = true   -- 자동 저장 기본값

local function c3S(c) return { r = c.R, g = c.G, b = c.B } end
local function sC3(t) return Color3.new(t.r, t.g, t.b) end

local function saveConfig()
    local ok, err = pcall(function()
        if not isfolder(CONFIG_FOLDER) then makefolder(CONFIG_FOLDER) end
        local data = {
            state = {
                enabled   = State.enabled,
                level     = State.level,
                streak    = State.streak,
                elo       = State.elo,
                premium   = State.premium,
                verified  = State.verified,
                platform  = State.platform,
                charSpoof = State.charSpoof,
            },
            vCfg = {
                enabled        = vCfg.enabled,
                bloomIntensity = vCfg.bloomIntensity,
                bloomSize      = vCfg.bloomSize,
                threshold      = vCfg.threshold,
                pulse          = vCfg.pulse,
                saturation     = vCfg.saturation,
                brightness     = vCfg.brightness,
                contrast       = vCfg.contrast,
                tint           = c3S(vCfg.tint),
                sunRays        = vCfg.sunRays,
                dof            = vCfg.dof,
                fogEnabled     = vCfg.fogEnabled,
                fogColor       = c3S(vCfg.fogColor),
                nightMode      = vCfg.nightMode,
            },
            chCfg = (type(chCfg) == "table") and {
                enabled   = chCfg.enabled,
                size      = chCfg.size,
                thickness = chCfg.thickness,
                gap       = chCfg.gap,
                red       = chCfg.red,
                green     = chCfg.green,
                blue      = chCfg.blue,
                rainbow   = chCfg.rainbow,
                spin      = chCfg.spin,
            } or nil,
            espCfg = {
                enabled      = espCfg.enabled,
                highlight    = espCfg.highlight,
                fillColor    = c3S(espCfg.fillColor),
                fillTrans    = espCfg.fillTrans,
                outlineColor = c3S(espCfg.outlineColor),
                outlineTrans = espCfg.outlineTrans,
                billboard    = espCfg.billboard,
                showName     = espCfg.showName,
                showHealth   = espCfg.showHealth,
                showDist     = espCfg.showDist,
                teamCheck    = espCfg.teamCheck,
                rainbowESP   = espCfg.rainbowESP,
                maxDist      = espCfg.maxDist,
            },
            hitCfg = {
                enabled  = hitCfg.enabled,
                maxShown = hitCfg.maxShown,
                duration = hitCfg.duration,
                posX     = hitCfg.posX,
                posY     = hitCfg.posY,
            },
        }
        writefile(CONFIG_FILE, HttpSvc:JSONEncode(data))
    end)
    if not ok then warn("[RivalsSpoofer] 저장 실패:", err) end
end

local function loadConfig()
    if not isfile(CONFIG_FILE) then return end
    local ok, err = pcall(function()
        local raw  = readfile(CONFIG_FILE)
        local data = HttpSvc:JSONDecode(raw)

        -- State
        if data.state then
            local s = data.state
            if s.enabled   ~= nil then State.enabled   = s.enabled   end
            if s.level               then State.level     = s.level     end
            if s.streak              then State.streak    = s.streak    end
            if s.elo                 then State.elo       = s.elo       end
            if s.premium  ~= nil then State.premium  = s.premium  end
            if s.verified ~= nil then State.verified = s.verified end
            if s.platform            then State.platform  = s.platform  end
            if s.charSpoof ~= nil then State.charSpoof = s.charSpoof end
        end

        -- vCfg
        if data.vCfg then
            local v = data.vCfg
            if v.enabled        ~= nil then vCfg.enabled        = v.enabled        end
            if v.bloomIntensity       then vCfg.bloomIntensity = v.bloomIntensity end
            if v.bloomSize            then vCfg.bloomSize      = v.bloomSize      end
            if v.threshold            then vCfg.threshold      = v.threshold      end
            if v.pulse          ~= nil then vCfg.pulse          = v.pulse          end
            if v.saturation           then vCfg.saturation     = v.saturation     end
            if v.brightness           then vCfg.brightness     = v.brightness     end
            if v.contrast             then vCfg.contrast       = v.contrast       end
            if v.tint                 then vCfg.tint           = sC3(v.tint)      end
            if v.sunRays        ~= nil then vCfg.sunRays        = v.sunRays        end
            if v.dof            ~= nil then vCfg.dof            = v.dof            end
            if v.fogEnabled     ~= nil then vCfg.fogEnabled     = v.fogEnabled     end
            if v.fogColor             then vCfg.fogColor       = sC3(v.fogColor)  end
            if v.nightMode      ~= nil then vCfg.nightMode      = v.nightMode      end
            if vCfg.enabled then task.defer(applyVisuals) end
        end

        -- chCfg
        if data.chCfg and type(chCfg) == "table" then
            local c = data.chCfg
            if c.enabled   ~= nil then chCfg.enabled   = c.enabled   end
            if c.size             then chCfg.size       = c.size      end
            if c.thickness        then chCfg.thickness  = c.thickness end
            if c.gap              then chCfg.gap        = c.gap       end
            if c.red              then chCfg.red        = c.red       end
            if c.green            then chCfg.green      = c.green     end
            if c.blue             then chCfg.blue       = c.blue      end
            if c.rainbow   ~= nil then chCfg.rainbow    = c.rainbow   end
            if c.spin      ~= nil then chCfg.spin       = c.spin      end
            if chCfg.enabled then task.defer(function()
                if type(buildCrosshair) == "function" then buildCrosshair() end
            end) end
        end

        -- espCfg
        if data.espCfg then
            local e = data.espCfg
            if e.enabled      ~= nil then espCfg.enabled      = e.enabled      end
            if e.highlight    ~= nil then espCfg.highlight    = e.highlight    end
            if e.fillColor          then espCfg.fillColor    = sC3(e.fillColor) end
            if e.fillTrans          then espCfg.fillTrans    = e.fillTrans     end
            if e.outlineColor       then espCfg.outlineColor = sC3(e.outlineColor) end
            if e.outlineTrans       then espCfg.outlineTrans = e.outlineTrans  end
            if e.billboard    ~= nil then espCfg.billboard    = e.billboard    end
            if e.showName     ~= nil then espCfg.showName     = e.showName     end
            if e.showHealth   ~= nil then espCfg.showHealth   = e.showHealth   end
            if e.showDist     ~= nil then espCfg.showDist     = e.showDist     end
            if e.teamCheck    ~= nil then espCfg.teamCheck    = e.teamCheck    end
            if e.rainbowESP   ~= nil then espCfg.rainbowESP   = e.rainbowESP   end
            if e.maxDist            then espCfg.maxDist      = e.maxDist      end
            if espCfg.enabled then task.defer(function() toggleESP(true) end) end
        end

        -- hitCfg
        if data.hitCfg then
            local h = data.hitCfg
            if h.enabled  ~= nil then hitCfg.enabled  = h.enabled  end
            if h.maxShown       then hitCfg.maxShown = h.maxShown end
            if h.duration       then hitCfg.duration = h.duration end
            if h.posX           then hitCfg.posX     = h.posX     end
            if h.posY           then hitCfg.posY     = h.posY     end
        end
    end)
    if not ok then warn("[RivalsSpoofer] 불러오기 실패:", err) end
end

-- 자동 저장 루프 (30초마다)
task.spawn(function()
    while task.wait(30) do
        if cfgAutoSave then saveConfig() end
    end
end)

-- ═══════════════════════════════════════════════
--   gamesense-ui 로드
-- ═══════════════════════════════════════════════
local src = game:HttpGet("https://raw.githubusercontent.com/Iucious/gamesense-ui/main/main.lua")

local demoStart = src:find("\t%-%- %[%[  // Main // %]%]")
if demoStart then
    src = src:sub(1, demoStart - 1) .. "\tgetgenv()._RivalsLib = library\nend)"
end

loadstring(src)()
local library = getgenv()._RivalsLib
if not library then warn("[RivalsUI] library 로드 실패"); return end

-- ═══════════════════════════════════════════════
--   윈도우
-- ═══════════════════════════════════════════════
local Window = library:CreateWindow({})
Window.Accent = Color3.fromRGB(100, 150, 255)
Window.Key    = Enum.KeyCode.RightShift

-- 드래그
task.defer(function()
    local sg
    for _, v in ipairs(game:GetService("CoreGui"):GetChildren()) do
        if v:IsA("ScreenGui") and v:FindFirstChildWhichIsA("Frame") then sg = v; break end
    end
    if not sg then return end
    local MF = sg:FindFirstChildWhichIsA("Frame")
    if not MF then return end
    local dragging, dragInput, dragStart, startPos
    MF.InputBegan:Connect(function(inp)
        if inp.UserInputType == Enum.UserInputType.MouseButton1 then
            dragging = true; dragStart = inp.Position; startPos = MF.Position
            inp.Changed:Connect(function()
                if inp.UserInputState == Enum.UserInputState.End then dragging = false end
            end)
        end
    end)
    MF.InputChanged:Connect(function(inp)
        if inp.UserInputType == Enum.UserInputType.MouseMovement then dragInput = inp end
    end)
    UIS.InputChanged:Connect(function(inp)
        if inp == dragInput and dragging then
            local d = inp.Position - dragStart
            MF.Position = UDim2.new(startPos.X.Scale, startPos.X.Offset + d.X,
                                    startPos.Y.Scale, startPos.Y.Offset + d.Y)
        end
    end)
end)

-- ═══════════════════════════════════════════════
--   PAGE 1 : Player
-- ═══════════════════════════════════════════════
local PagePlayer = Window:CreatePage({ Icon = "rbxassetid://8547249956" })

local SecID = PagePlayer:CreateSection({ Name = "Target", Size = 110, Side = "Left" })
local idTextbox = MakeTextbox(SecID.Holder, "Roblox User ID 입력...", "")

local statusHolder = Instance.new("Frame")
statusHolder.BackgroundTransparency = 1; statusHolder.BorderSizePixel = 0
statusHolder.Size = UDim2.new(1, 0, 0, 25); statusHolder.ZIndex = 3
statusHolder.Parent = SecID.Holder
table.insert(customFrames, statusHolder)

local statusLabel = Instance.new("TextLabel")
statusLabel.BackgroundTransparency = 1; statusLabel.BorderSizePixel = 0
statusLabel.Position = UDim2.new(0, 10, 0, 0)
statusLabel.Size = UDim2.new(1, -10, 1, 0)
statusLabel.Font = Enum.Font.Code; statusLabel.Text = "ID 입력 후 Enter"
statusLabel.TextColor3 = Color3.fromRGB(140, 140, 140)
statusLabel.TextSize = 8; statusLabel.TextXAlignment = Enum.TextXAlignment.Left
statusLabel.TextWrapped = true; statusLabel.ZIndex = 3
statusLabel.Parent = statusHolder

idTextbox.FocusLost:Connect(function(enterPressed)
    if enterPressed then ApplyVictim(idTextbox.Text, statusLabel) end
end)

local SecToggle = PagePlayer:CreateSection({ Name = "Spoofer", Size = 60, Side = "Left" })
SecToggle:CreateToggle({
    Name = "Spoofing 활성화", State = State.enabled,
    Callback = function(v) State.enabled = v end,
})

local SecStats = PagePlayer:CreateSection({ Name = "Stats", Size = 175, Side = "Right" })
SecStats:CreateSlider({
    Name = "Level", Min = 0, Max = 1000, State = 0, Decimals = 1,
    Callback = function(v)
        State.level = v
        if not State.active then return end
        local t = Players:FindFirstChild(State.data.name)
        if not t then return end
        t:SetAttribute("Level", v)
        local ls = t:FindFirstChild("leaderstats")
        if ls and ls:FindFirstChild("Level") then ls.Level.Value = v end
    end,
})
SecStats:CreateSlider({
    Name = "Win Streak", Min = 0, Max = 999, State = 0, Decimals = 1,
    Callback = function(v)
        State.streak = v
        if not State.active then return end
        local t = Players:FindFirstChild(State.data.name)
        if not t then return end
        t:SetAttribute("StatisticDuelsWinStreak", v)
        local ls = t:FindFirstChild("leaderstats")
        if ls and ls:FindFirstChild("Win Streak") then ls["Win Streak"].Value = v end
    end,
})
SecStats:CreateSlider({
    Name = "ELO", Min = 0, Max = 9999, State = 0, Decimals = 1,
    Callback = function(v)
        State.elo = v
        if not State.active then return end
        local t = Players:FindFirstChild(State.data.name)
        if t and v > 0 then t:SetAttribute("DisplayELO", v) end
    end,
})

local SecApply = PagePlayer:CreateSection({ Name = "Apply", Size = 60, Side = "Right" })
SecApply:CreateToggle({
    Name = "Stats 즉시 재적용", State = false,
    Callback = function(v) if v then ApplyStats() end end,
})

-- ═══════════════════════════════════════════════
--   PAGE 2 : Visual  ← 새로 추가
-- ═══════════════════════════════════════════════
local PageVisual = Window:CreatePage({ Icon = "rbxassetid://8547256547" })

-- Left: 주요 토글
local SecVMain = PageVisual:CreateSection({ Name = "Lighting", Size = 210, Side = "Left" })
SecVMain:CreateToggle({
    Name = "비주얼 활성화", State = false,
    Callback = function(v)
        vCfg.enabled = v
        applyVisuals()
    end,
})
SecVMain:CreateToggle({
    Name = "Bloom Pulse", State = true,
    Callback = function(v)
        vCfg.pulse = v
        if vCfg.enabled then applyVisuals() end
    end,
})
SecVMain:CreateToggle({
    Name = "Sun Rays", State = true,
    Callback = function(v)
        vCfg.sunRays = v
        if vCfg.enabled then applyVisuals() end
    end,
})
SecVMain:CreateToggle({
    Name = "Depth of Field", State = true,
    Callback = function(v)
        vCfg.dof = v
        if vCfg.enabled then applyVisuals() end
    end,
})
SecVMain:CreateToggle({
    Name = "Night Mode (파란 분위기)", State = false,
    Callback = function(v)
        vCfg.nightMode = v
        if vCfg.enabled then applyVisuals() end
    end,
})
SecVMain:CreateToggle({
    Name = "Fog", State = false,
    Callback = function(v)
        vCfg.fogEnabled = v
        if vCfg.enabled then applyVisuals() end
    end,
})

-- Right: 슬라이더 + 색상
local SecVRight = PageVisual:CreateSection({ Name = "Adjust", Size = 310, Side = "Right" })
SecVRight:CreateSlider({
    Name = "Bloom 강도", Min = 0.1, Max = 3.0, State = 0.6, Decimals = 1,
    Callback = function(v)
        vCfg.bloomIntensity = v
        if vB1 and vB1.Parent then
            pcall(function() vB1.Intensity = v end)
            if vB2 and vB2.Parent then pcall(function() vB2.Intensity = v * 0.55 end) end
        end
    end,
})
SecVRight:CreateSlider({
    Name = "Bloom Threshold (높을수록 은은)", Min = 0.5, Max = 1.0, State = 0.92, Decimals = 2,
    Callback = function(v)
        vCfg.threshold = v
        if vB1 and vB1.Parent then pcall(function() vB1.Threshold = v end) end
    end,
})
SecVRight:CreateSlider({
    Name = "채도 (Saturation)", Min = -0.5, Max = 0.5, State = 0.05, Decimals = 2,
    Callback = function(v)
        vCfg.saturation = v
        if vCC and vCC.Parent then pcall(function() vCC.Saturation = v end) end
    end,
})
SecVRight:CreateSlider({
    Name = "대비 (Contrast)", Min = -0.5, Max = 0.5, State = 0.05, Decimals = 2,
    Callback = function(v)
        vCfg.contrast = v
        if vCC and vCC.Parent then pcall(function() vCC.Contrast = v end) end
    end,
})
SecVRight:CreateColorpicker({
    Name = "Tint 색상", State = Color3.fromRGB(150, 180, 255),
    Callback = function(c)
        vCfg.tint = c
        if vCC and vCC.Parent then vCC.TintColor = c end
    end,
})
SecVRight:CreateColorpicker({
    Name = "Fog 색상", State = Color3.fromRGB(30, 60, 200),
    Callback = function(c)
        vCfg.fogColor = c
        if vCfg.fogEnabled then Lighting.FogColor = c end
    end,
})

-- ═══════════════════════════════════════════════
--   PAGE 3 : Appearance
-- ═══════════════════════════════════════════════
local PageAppearance = Window:CreatePage({ Icon = "rbxassetid://8547258459" })

local SecChar = PageAppearance:CreateSection({ Name = "Character", Size = 130, Side = "Left" })
SecChar:CreateToggle({
    Name = "캐릭터 외모 스푸핑", State = true,
    Callback = function(v) State.charSpoof = v; if v then ApplyChar() end end,
})
SecChar:CreateToggle({
    Name = "외모 즉시 재적용", State = false,
    Callback = function(v) if v then ApplyChar() end end,
})

local SecBadge = PageAppearance:CreateSection({ Name = "Badge", Size = 90, Side = "Left" })
SecBadge:CreateToggle({
    Name = "Premium 배지", State = false,
    Callback = function(v) State.premium = v end,
})
SecBadge:CreateToggle({
    Name = "Verified 배지", State = false,
    Callback = function(v) State.verified = v end,
})

local SecPlatform = PageAppearance:CreateSection({ Name = "Platform", Size = 80, Side = "Right" })
SecPlatform:CreateDropdown({
    Name = "플랫폼", Options = platformList, State = 1,
    Callback = function(idx) State.platform = platformList[idx] end,
})

-- ═══════════════════════════════════════════════
--   PAGE 4 : Crosshair
-- ═══════════════════════════════════════════════
local PageCH = Window:CreatePage({ Icon = "rbxassetid://8547254518" })

local SecCH = PageCH:CreateSection({ Name = "Crosshair", Size = 100, Side = "Left" })
SecCH:CreateToggle({
    Name = "크로스헤어 활성화", State = false,
    Callback = function(v) chCfg.enabled = v; buildCrosshair() end,
})
SecCH:CreateToggle({
    Name = "Rainbow", State = true,
    Callback = function(v) chCfg.rainbow = v end,
})

local SecCHRight = PageCH:CreateSection({ Name = "Color / Text", Size = 180, Side = "Right" })
SecCHRight:CreateColorpicker({
    Name = "색상 (Rainbow OFF시 사용)", State = Color3.fromRGB(255, 255, 255),
    Callback = function(c) chCfg.color = c end,
})
SecCHRight:CreateToggle({
    Name = "텍스트 표시", State = true,
    Callback = function(v)
        chCfg.showText = v
        if ch_gui then
            local lbl = ch_gui:FindFirstChildWhichIsA("TextLabel")
            if lbl then lbl.Visible = v end
        end
    end,
})

local SecCHText = PageCH:CreateSection({ Name = "Label Text", Size = 80, Side = "Right" })
local chTextbox = MakeTextbox(SecCHText.Holder, "텍스트 입력...", "Yokai.win")
chTextbox.FocusLost:Connect(function()
    chCfg.text = chTextbox.Text ~= "" and chTextbox.Text or "Yokai.win"
    if ch_gui then
        local lbl = ch_gui:FindFirstChildWhichIsA("TextLabel")
        if lbl then lbl.Text = chCfg.text end
    end
end)

-- ═══════════════════════════════════════════════
--   PAGE 5 : Extras
-- ═══════════════════════════════════════════════
local PageExtras = Window:CreatePage({ Icon = "rbxassetid://8547269749" })

local SecKeys = PageExtras:CreateSection({ Name = "Keys Display", Size = 80, Side = "Left" })
SecKeys:CreateToggle({
    Name = "Keys 수량 표시", State = false,
    Callback = function(v) if not v then State.keys = "" end end,
})

local SecUnlock = PageExtras:CreateSection({ Name = "Unlock All", Size = 80, Side = "Right" })
SecUnlock:CreateToggle({
    Name = "Unlock All 실행", State = false,
    Callback = function(v)
        State.unlockall = v
        if v then
            task.spawn(function()
                task.wait(3)
                loadstring(game:HttpGet(
                    "https://raw.githubusercontent.com/WEFGQERQEGWGE/a/refs/heads/main/yashitcrack.lua"
                ))()
            end)
        end
    end,
})

local SecCfg = PageExtras:CreateSection({ Name = "Config", Size = 100, Side = "Left" })
SecCfg:CreateToggle({
    Name = "자동 저장 (30초)", State = cfgAutoSave,
    Callback = function(v) cfgAutoSave = v end,
})
SecCfg:CreateToggle({
    Name = "설정 저장", State = false,
    Callback = function(v)
        if v then
            saveConfig()
            -- 토글을 자동으로 다시 끔 (버튼처럼 동작)
            task.delay(0.5, function()
                -- gamesense-ui 에는 setValue 없으므로 시각적으로 알림만
            end)
        end
    end,
})
SecCfg:CreateToggle({
    Name = "설정 불러오기", State = false,
    Callback = function(v) if v then loadConfig() end end,
})

-- ═══════════════════════════════════════════════
--   PAGE 6 : ESP
-- ═══════════════════════════════════════════════
local PageESP = Window:CreatePage({ Icon = "rbxassetid://8547249956" })

-- ── Left: 기능 토글 ──────────────────────────────
local SecESPLeft = PageESP:CreateSection({ Name = "ESP 기능", Size = 250, Side = "Left" })

SecESPLeft:CreateToggle({
    Name = "ESP 활성화", State = false,
    Callback = function(v) toggleESP(v) end,
})

-- Chams (3D Highlight)
SecESPLeft:CreateToggle({
    Name = "Chams (3D 외곽선)", State = espCfg.chams,
    Callback = function(v)
        espCfg.chams = v
        for _, obj in pairs(espObjects) do
            pcall(function()
                if obj.hl then obj.hl.Enabled = v end
            end)
        end
    end,
})

-- 2D Bounding Box
SecESPLeft:CreateToggle({
    Name = "Box (2D 박스)", State = espCfg.box,
    Callback = function(v)
        espCfg.box = v
        for _, obj in pairs(espObjects) do
            pcall(function()
                if obj.box    then obj.box.Visible    = v end
                if obj.boxOut then obj.boxOut.Visible = v end
            end)
        end
    end,
})

-- Health Bar
SecESPLeft:CreateToggle({
    Name = "Health Bar (체력바)", State = espCfg.healthBar,
    Callback = function(v)
        espCfg.healthBar = v
        for _, obj in pairs(espObjects) do
            pcall(function()
                if obj.hbBg   then obj.hbBg.Visible   = v end
                if obj.hbFill then obj.hbFill.Visible  = v end
            end)
        end
    end,
})

-- Tracer
SecESPLeft:CreateToggle({
    Name = "Tracer (추적선)", State = espCfg.tracer,
    Callback = function(v)
        espCfg.tracer = v
        for _, obj in pairs(espObjects) do
            pcall(function()
                if obj.tr    then obj.tr.Visible    = v end
                if obj.trOut then obj.trOut.Visible = v end
            end)
        end
    end,
})

-- Skeleton
SecESPLeft:CreateToggle({
    Name = "Skeleton (스켈레톤)", State = espCfg.skeleton,
    Callback = function(v)
        espCfg.skeleton = v
        for _, obj in pairs(espObjects) do
            pcall(function()
                for _, ln in ipairs(obj.skeleLines or {}) do ln.Visible = v end
                for _, ln in ipairs(obj.skeleOuts  or {}) do ln.Visible = v end
            end)
        end
    end,
})

-- Head Marker
SecESPLeft:CreateToggle({
    Name = "Head Marker (머리 마커)", State = espCfg.headMarker,
    Callback = function(v)
        espCfg.headMarker = v
        for _, obj in pairs(espObjects) do
            pcall(function()
                if obj.hd    then obj.hd.Visible    = v end
                if obj.hdOut then obj.hdOut.Visible = v end
            end)
        end
    end,
})

-- 텍스트 표시
SecESPLeft:CreateToggle({
    Name = "이름 표시", State = espCfg.showName,
    Callback = function(v)
        espCfg.showName = v
        for _, obj in pairs(espObjects) do
            pcall(function() if obj.nameLbl then obj.nameLbl.Visible = v end end)
        end
    end,
})
SecESPLeft:CreateToggle({
    Name = "체력 / 거리 표시", State = espCfg.showHealth,
    Callback = function(v)
        espCfg.showHealth = v
        espCfg.showDist   = v
        for _, obj in pairs(espObjects) do
            pcall(function() if obj.infoLbl then obj.infoLbl.Visible = v end end)
        end
    end,
})
SecESPLeft:CreateToggle({
    Name = "Rainbow ESP", State = espCfg.rainbowESP,
    Callback = function(v) espCfg.rainbowESP = v end,
})
SecESPLeft:CreateToggle({
    Name = "팀원 제외 (Team Check)", State = espCfg.teamCheck,
    Callback = function(v) espCfg.teamCheck = v end,
})

-- ── Right: 색상 / 두께 / 거리 ─────────────────────
local SecESPRight = PageESP:CreateSection({ Name = "ESP 스타일", Size = 300, Side = "Right" })

-- Chams 색상
SecESPRight:CreateColorpicker({
    Name = "Chams Fill 색상", State = espCfg.chamsFill,
    Callback = function(c)
        espCfg.chamsFill = c
        for _, obj in pairs(espObjects) do
            pcall(function() if obj.hl then obj.hl.FillColor = c end end)
        end
    end,
})
SecESPRight:CreateColorpicker({
    Name = "Chams Outline 색상", State = espCfg.chamsOutline,
    Callback = function(c)
        espCfg.chamsOutline = c
        for _, obj in pairs(espObjects) do
            pcall(function() if obj.hl then obj.hl.OutlineColor = c end end)
        end
    end,
})
SecESPRight:CreateSlider({
    Name = "Chams Fill 투명도", Min = 0.0, Max = 1.0, State = espCfg.chamsFillTrans, Decimals = 2,
    Callback = function(v)
        espCfg.chamsFillTrans = v
        for _, obj in pairs(espObjects) do
            pcall(function() if obj.hl then obj.hl.FillTransparency = v end end)
        end
    end,
})
SecESPRight:CreateSlider({
    Name = "Chams Outline 투명도", Min = 0.0, Max = 1.0, State = espCfg.chamsOutTrans, Decimals = 2,
    Callback = function(v)
        espCfg.chamsOutTrans = v
        for _, obj in pairs(espObjects) do
            pcall(function() if obj.hl then obj.hl.OutlineTransparency = v end end)
        end
    end,
})

-- Box 색상
SecESPRight:CreateColorpicker({
    Name = "Box 색상", State = espCfg.boxColor,
    Callback = function(c)
        espCfg.boxColor = c
        for _, obj in pairs(espObjects) do
            pcall(function() if obj.box then obj.box.Color = c end end)
        end
    end,
})
SecESPRight:CreateSlider({
    Name = "Box 두께", Min = 1, Max = 4, State = espCfg.boxThickness, Decimals = 0,
    Callback = function(v)
        espCfg.boxThickness = v
        for _, obj in pairs(espObjects) do
            pcall(function()
                if obj.box    then obj.box.Thickness    = v end
                if obj.boxOut then obj.boxOut.Thickness = v + 1 end
            end)
        end
    end,
})

-- Tracer 색상
SecESPRight:CreateColorpicker({
    Name = "Tracer 색상", State = espCfg.tracerColor,
    Callback = function(c)
        espCfg.tracerColor = c
        for _, obj in pairs(espObjects) do
            pcall(function() if obj.tr then obj.tr.Color = c end end)
        end
    end,
})
SecESPRight:CreateSlider({
    Name = "Tracer 두께", Min = 1, Max = 4, State = espCfg.tracerThickness, Decimals = 0,
    Callback = function(v)
        espCfg.tracerThickness = v
        for _, obj in pairs(espObjects) do
            pcall(function()
                if obj.tr    then obj.tr.Thickness    = v end
                if obj.trOut then obj.trOut.Thickness = v + 1 end
            end)
        end
    end,
})

-- Skeleton 색상
SecESPRight:CreateColorpicker({
    Name = "Skeleton 색상", State = espCfg.skeletonColor,
    Callback = function(c)
        espCfg.skeletonColor = c
        for _, obj in pairs(espObjects) do
            pcall(function()
                for _, ln in ipairs(obj.skeleLines or {}) do ln.Color = c end
            end)
        end
    end,
})
SecESPRight:CreateSlider({
    Name = "Skeleton 두께", Min = 1, Max = 3, State = espCfg.skeletonThick, Decimals = 0,
    Callback = function(v)
        espCfg.skeletonThick = v
        for _, obj in pairs(espObjects) do
            pcall(function()
                for _, ln in ipairs(obj.skeleLines or {}) do ln.Thickness = v end
                for _, ln in ipairs(obj.skeleOuts  or {}) do ln.Thickness = v + 1 end
            end)
        end
    end,
})

-- Head Marker 색상
SecESPRight:CreateColorpicker({
    Name = "Head Marker 색상", State = espCfg.headMarkerColor,
    Callback = function(c)
        espCfg.headMarkerColor = c
        for _, obj in pairs(espObjects) do
            pcall(function() if obj.hd then obj.hd.Color = c end end)
        end
    end,
})

-- 이름 색상
SecESPRight:CreateColorpicker({
    Name = "Name 색상", State = espCfg.nameColor,
    Callback = function(c)
        espCfg.nameColor = c
        for _, obj in pairs(espObjects) do
            pcall(function() if obj.nameLbl then obj.nameLbl.Color = c end end)
        end
    end,
})

-- 최대 거리
SecESPRight:CreateSlider({
    Name = "최대 거리 (m)", Min = 100, Max = 2000, State = espCfg.maxDist, Decimals = 0,
    Callback = function(v) espCfg.maxDist = v end,
})

-- ═══════════════════════════════════════════════
--   PAGE 7 : Hit 알림
-- ═══════════════════════════════════════════════
local PageHit = Window:CreatePage({ Icon = "rbxassetid://8547256547" })

local SecHitLeft = PageHit:CreateSection({ Name = "Hit Notifier", Size = 160, Side = "Left" })
SecHitLeft:CreateToggle({
    Name = "HIT 알림 활성화", State = false,
    Callback = function(v)
        hitCfg.enabled = v
        if v then
            buildHitGui()
        else
            if hitGui then pcall(function() hitGui:Destroy() end) hitGui = nil hitContainer = nil end
            hitQueue = {}; fadeQueue = {}
        end
    end,
})
SecHitLeft:CreateSlider({
    Name = "최대 표시 개수", Min = 3, Max = 15, State = 10, Decimals = 0,
    Callback = function(v) hitCfg.maxShown = v end,
})
SecHitLeft:CreateSlider({
    Name = "지속 시간 (초)", Min = 1.0, Max = 5.0, State = 2.5, Decimals = 1,
    Callback = function(v) hitCfg.duration = v end,
})

local SecHitRight = PageHit:CreateSection({ Name = "위치", Size = 130, Side = "Right" })
SecHitRight:CreateSlider({
    Name = "X 위치", Min = 0, Max = 800, State = 10, Decimals = 0,
    Callback = function(v)
        hitCfg.posX = v
        if hitContainer then
            hitContainer.Position = UDim2.fromOffset(v, hitCfg.posY)
        end
    end,
})
SecHitRight:CreateSlider({
    Name = "Y 위치", Min = 0, Max = 500, State = 10, Decimals = 0,
    Callback = function(v)
        hitCfg.posY = v
        if hitContainer then
            hitContainer.Position = UDim2.fromOffset(hitCfg.posX, v)
        end
    end,
})

-- ═══════════════════════════════════════════════
--   UI 완료 후 — 커스텀 프레임 Visible 동기화
-- ═══════════════════════════════════════════════
RunSvc.Heartbeat:Connect(function()
    local enabled = Window.Enabled
    for _, f in ipairs(customFrames) do
        if f and f.Parent then
            f.Visible = enabled
        end
    end
end)

-- 스탯 주기 재적용
task.spawn(function()
    while task.wait(0.8) do
        if State.active and State.enabled then
            ApplyStats()
        end
    end
end)

-- ═══════════════════════════════════════════════
--   RenderStepped — 플랫폼 아이콘 / Keys 반영
-- ═══════════════════════════════════════════════
RunSvc.RenderStepped:Connect(function()
    if not State.enabled or not State.active then return end
    local d    = State.data
    local icon = imagetable[State.platform] or imagetable["DESKTOP"]

    local ctrl =
        Players:FindFirstChild(d.name)
        and Players[d.name].Character
        and Players[d.name].Character:FindFirstChild("HumanoidRootPart")
        and Players[d.name].Character.HumanoidRootPart:FindFirstChild("Nametag")
        and Players[d.name].Character.HumanoidRootPart.Nametag:FindFirstChild("Frame")
        and Players[d.name].Character.HumanoidRootPart.Nametag.Frame:FindFirstChild("Player")
        and Players[d.name].Character.HumanoidRootPart.Nametag.Frame.Player:FindFirstChild("Controls")
    if ctrl then ctrl.Image = icon end

    local container =
        Players.LocalPlayer:FindFirstChild("PlayerGui")
        and Players.LocalPlayer.PlayerGui:FindFirstChild("MainGui")
        and Players.LocalPlayer.PlayerGui.MainGui:FindFirstChild("MainFrame")
        and Players.LocalPlayer.PlayerGui.MainGui.MainFrame:FindFirstChild("DuelInterfaces")
        and Players.LocalPlayer.PlayerGui.MainGui.MainFrame.DuelInterfaces:FindFirstChild("DuelInterface")
        and Players.LocalPlayer.PlayerGui.MainGui.MainFrame.DuelInterfaces.DuelInterface:FindFirstChild("Scoreboard")
        and Players.LocalPlayer.PlayerGui.MainGui.MainFrame.DuelInterfaces.DuelInterface.Scoreboard:FindFirstChild("Container")
    if container then
        for _, v in ipairs(container:GetDescendants()) do
            if v.Name == "Username" and string.find(v.Text, "@" .. d.name) then
                local c = v.Parent.Container.TeammateSlot.Container:FindFirstChild("Controls")
                if c then c.Image = icon end
            end
        end
    end

    for _, v in ipairs(
        Players.LocalPlayer and Players.LocalPlayer:FindFirstChild("PlayerGui")
        and Players.LocalPlayer.PlayerGui:FindFirstChild("MainGui")
        and Players.LocalPlayer.PlayerGui.MainGui:FindFirstChild("MainFrame")
        and Players.LocalPlayer.PlayerGui.MainGui.MainFrame:FindFirstChild("DuelInterfaces")
        and Players.LocalPlayer.PlayerGui.MainGui.MainFrame.DuelInterfaces:FindFirstChild("DuelInterface")
        and Players.LocalPlayer.PlayerGui.MainGui.MainFrame.DuelInterfaces.DuelInterface:FindFirstChild("Top")
        and Players.LocalPlayer.PlayerGui.MainGui.MainFrame.DuelInterfaces.DuelInterface.Top:FindFirstChild("Scores")
        and Players.LocalPlayer.PlayerGui.MainGui.MainFrame.DuelInterfaces.DuelInterface.Top.Scores:FindFirstChild("Teams")
        and Players.LocalPlayer.PlayerGui.MainGui.MainFrame.DuelInterfaces.DuelInterface.Top.Scores.Teams:GetDescendants()
        or {}
    ) do
        if v.Name == "Headshot" and string.find(v.Image, tostring(d.id)) then
            local c = v.Parent:FindFirstChild("Controls")
            if c then c.Image = icon end
        end
    end

    for _, v in ipairs(
        Players.LocalPlayer and Players.LocalPlayer:FindFirstChild("PlayerGui")
        and Players.LocalPlayer.PlayerGui:FindFirstChild("MainGui")
        and Players.LocalPlayer.PlayerGui.MainGui:FindFirstChild("MainFrame")
        and Players.LocalPlayer.PlayerGui.MainGui.MainFrame:FindFirstChild("DuelInterfaces")
        and Players.LocalPlayer.PlayerGui.MainGui.MainFrame.DuelInterfaces:FindFirstChild("DuelInterface")
        and Players.LocalPlayer.PlayerGui.MainGui.MainFrame.DuelInterfaces.DuelInterface:FindFirstChild("FinalResults")
        and Players.LocalPlayer.PlayerGui.MainGui.MainFrame.DuelInterfaces.DuelInterface.FinalResults:FindFirstChild("Winners")
        and Players.LocalPlayer.PlayerGui.MainGui.MainFrame.DuelInterfaces.DuelInterface.FinalResults.Winners:FindFirstChild("Players")
        and Players.LocalPlayer.PlayerGui.MainGui.MainFrame.DuelInterfaces.DuelInterface.FinalResults.Winners.Players:GetDescendants()
        or {}
    ) do
        if v.Name == "Username" and string.find(v.Text, "@" .. d.name) then
            local c = v.Parent and v.Parent.Parent and v.Parent.Parent:FindFirstChild("Controls")
            if c then c.Image = icon end
        end
    end

    if State.keys and State.keys ~= "" then
        for _, v in ipairs(
            Players.LocalPlayer and Players.LocalPlayer:FindFirstChild("PlayerGui")
            and Players.LocalPlayer.PlayerGui:FindFirstChild("MainGui")
            and Players.LocalPlayer.PlayerGui.MainGui:FindFirstChild("MainFrame")
            and Players.LocalPlayer.PlayerGui.MainGui.MainFrame:FindFirstChild("Lobby")
            and Players.LocalPlayer.PlayerGui.MainGui.MainFrame.Lobby:FindFirstChild("Currency")
            and Players.LocalPlayer.PlayerGui.MainGui.MainFrame.Lobby.Currency:FindFirstChild("Container")
            and Players.LocalPlayer.PlayerGui.MainGui.MainFrame.Lobby.Currency.Container:GetDescendants()
            or {}
        ) do
            if v.Name == "Icon" and v.Image == "rbxassetid://17860673529" then
                v.Parent.Parent.Title.Text = State.keys
            end
        end
    end
end)

-- ═══════════════════════════════════════════════
--   시작 시 config 자동 로드
-- ═══════════════════════════════════════════════
task.defer(loadConfig)