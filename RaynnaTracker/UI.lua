-- Tracker window. Owns layout, rows, scaling, resizing, reset dialogs and commands.
-- Dimensions, labels and callback order deliberately match the existing interface.

local _, Addon = ...
local trackerFrame, monsterRows, scrollOffset = nil, {}, 0
local contentRegions, resizeHandles = {}, {}
local visibleRows = 7
local expandedWidth, expandedHeight = 300, 424
local titleColor = Addon.Theme.gold

-- Text and control construction
local function moneyText(amount)
    local formatter = C_CurrencyInfo and C_CurrencyInfo.GetCoinTextureString or GetCoinTextureString
    if formatter then
        return formatter(amount)
    end
    return string.format(
        '%dg %ds %dc',
        math.floor(amount / 10000),
        math.floor(amount / 100) % 100,
        amount % 100
    )
end
local function createText(parent, size, x, y, value)
    local fontString = parent:CreateFontString(nil, 'OVERLAY', 'GameFontNormal')
    fontString:SetFont(STANDARD_TEXT_FONT, size)
    fontString:SetPoint('TOPLEFT', x, y)
    fontString:SetText(value or '')
    fontString:SetTextColor(unpack(Addon.Theme.text))
    if parent == trackerFrame and y <= -43 then
        table.insert(contentRegions, fontString)
    end
    return fontString
end
local function button(parent, label, width, x, y, callback)
    local control = CreateFrame('Button', nil, parent, 'UIPanelButtonTemplate')
    control:SetSize(width, 22)
    control:SetPoint('TOPLEFT', x, y)
    control:SetText(label)
    control:SetScript('OnClick', callback)
    if parent == trackerFrame and y <= -43 then
        table.insert(contentRegions, control)
    end
    return control
end

-- Visibility, scale and reset actions
local function toggleVisibility()
    Addon.db.hidden = not Addon.db.hidden
    trackerFrame:SetShown(not Addon.db.hidden)
end
local function setScale(value)
    local oldEffective = trackerFrame:GetEffectiveScale()
    local left, top = trackerFrame:GetLeft() * oldEffective, trackerFrame:GetTop() * oldEffective
    Addon.db.scale = math.max(0.4, math.min(1.8, value))
    trackerFrame:SetScale(Addon.db.scale)
    local effective = trackerFrame:GetEffectiveScale()
    trackerFrame:ClearAllPoints()
    trackerFrame:SetPoint('TOPLEFT', UIParent, 'BOTTOMLEFT', left / effective, top / effective)
    Addon.db.position =
        { point = 'TOPLEFT', relative = 'BOTTOMLEFT', x = left / effective, y = top / effective }
    if trackerFrame.scaleInput then
        trackerFrame.scaleInput:SetText(math.floor(Addon.db.scale * 100 + 0.5) .. '%')
    end
    Addon.HideDrops()
end
local function showResetConfirmation(kind)
    Addon.SetCollapsed(false)
    Addon.HideDrops()
    trackerFrame.confirm.kind = kind
    trackerFrame.confirm.entry = nil
    trackerFrame.confirm.action:SetText('Reset')
    trackerFrame.confirm.label:SetText(
        kind == 'all' and 'Reset all tracker totals?\nKills, loot, quests, money and XP.'
            or kind == 'money' and 'Reset money gained?'
            or kind == 'xp' and 'Reset XP gained?'
            or 'Reset kills and collected loot?'
    )
    trackerFrame.confirm:Show()
end
local function handleScaleWheel(_, delta)
    if IsControlKeyDown() then
        setScale(Addon.db.scale + delta * 0.05)
        return true
    end
end
local function positionRegion(region, x, y)
    region:ClearAllPoints()
    region:SetPoint('TOPLEFT', x, y)
end

-- Expanded layout and compact-mode positioning
function Addon.Layout()
    if Addon.db.collapsed then
        return
    end
    local width, height = trackerFrame:GetWidth(), trackerFrame:GetHeight()
    expandedWidth, expandedHeight = width, height
    Addon.db.width, Addon.db.height = width, height
    local questHeight = 36
    trackerFrame.questSummary:Show()
    trackerFrame.questSummary:SetWidth(width - 24)
    visibleRows = math.max(1, math.min(#monsterRows, math.floor((height - 214 - questHeight) / 30)))
    trackerFrame.title:SetWidth(width - 70)
    positionRegion(trackerFrame.minus, width - 57, -6)
    positionRegion(trackerFrame.close, width - 33, -6)
    positionRegion(trackerFrame.monsterHeader, 12, -53 - questHeight)
    positionRegion(trackerFrame.levelHeader, width - 96, -53 - questHeight)
    positionRegion(trackerFrame.killHeader, width - 71, -53 - questHeight)
    positionRegion(trackerFrame.scroll, 8, -70 - questHeight)
    trackerFrame.scroll:SetSize(width - 16, visibleRows * 30)
    for _, row in ipairs(monsterRows) do
        row:SetWidth(width - 30)
        row.name:SetWidth(width - 154)
        positionRegion(row.level, width - 117, -4)
        positionRegion(row.count, width - 79, -4)
        positionRegion(row.xp, math.max(155, width - 145), -18)
    end
    positionRegion(trackerFrame.page, 12, -(height - 137))
    positionRegion(trackerFrame.moneyLabel, 12, -(height - 112))
    positionRegion(trackerFrame.money, 116, -(height - 113))
    positionRegion(trackerFrame.xpLabel, 12, -(height - 89))
    positionRegion(trackerFrame.xp, 116, -(height - 90))
    positionRegion(trackerFrame.scaleLabel, 12, -(height - 59))
    positionRegion(trackerFrame.scaleDown, 108, -(height - 64))
    positionRegion(trackerFrame.scaleInput, 141, -(height - 64))
    positionRegion(trackerFrame.scaleUp, 204, -(height - 64))
    positionRegion(trackerFrame.bestiary, width - 70, -(height - 64))
    local buttonWidth = width - 24
    for i, control in ipairs(trackerFrame.resetButtons) do
        control:SetWidth(buttonWidth)
        positionRegion(control, 12 + (i - 1) * (buttonWidth + 2), -(height - 34))
    end
end
function Addon.SetCollapsed(collapsed)
    -- A center/bottom anchor shifts the title when the frame height changes.
    -- Preserve its current top-left point before changing the dimensions.
    local left, top = trackerFrame:GetLeft(), trackerFrame:GetTop()
    if left and top then
        trackerFrame:ClearAllPoints()
        trackerFrame:SetPoint('TOPLEFT', UIParent, 'BOTTOMLEFT', left, top)
        Addon.db.position = { point = 'TOPLEFT', relative = 'BOTTOMLEFT', x = left, y = top }
    end
    Addon.db.collapsed = collapsed
    trackerFrame:SetSize(collapsed and 205 or expandedWidth, collapsed and 72 or expandedHeight)
    trackerFrame.title:SetWidth(collapsed and 165 or 207)
    trackerFrame.subtitle:SetShown(not collapsed)
    trackerFrame.close:SetShown(not collapsed)
    trackerFrame.minus:SetShown(not collapsed)
    trackerFrame.plus:SetShown(collapsed)
    trackerFrame.plus:ClearAllPoints()
    trackerFrame.plus:SetPoint('TOPLEFT', 175, -6)
    for _, region in ipairs(contentRegions) do
        region:SetShown(not collapsed)
    end
    trackerFrame.compactMoney:SetShown(collapsed)
    trackerFrame.compactXP:SetShown(collapsed)
    if collapsed then
        trackerFrame.confirm:Hide()
        Addon.HideDrops()
    end
    for _, handle in ipairs(resizeHandles) do
        handle:SetShown(not collapsed)
    end
    Addon.Layout()
    Addon.Draw()
end

-- Refresh visible records and summary values
function Addon.Draw()
    if not trackerFrame then
        return
    end
    local data = Addon.DisplayData()
    Addon.Layout()
    local quests = data.quests or { count = 0, xp = 0 }
    trackerFrame.questSummary.count:SetText('Quests completed: ' .. Addon.Number(quests.count))
    trackerFrame.questSummary.xp:SetText(
        'Quest XP: ' .. Addon.Number(quests.xp) .. ((quests.unknownXP or 0) > 0 and ' + unknown' or '')
    )
    trackerFrame.questSummary.xp:Show()
    trackerFrame.questSummary.hideXP:SetChecked(Addon.db.includeQuestXP ~= false)
    local sortedMonsters, totalKills = {}, 0
    for _, mob in pairs(data.mobs) do
        table.insert(sortedMonsters, mob)
        totalKills = totalKills + mob.count
    end
    table.sort(sortedMonsters, function(a, control)
        if (a.lastKillOrder or 0) ~= (control.lastKillOrder or 0) then
            return (a.lastKillOrder or 0) > (control.lastKillOrder or 0)
        end
        if a.count ~= control.count then
            return a.count > control.count
        end
        if a.name ~= control.name then
            return a.name < control.name
        end
        return false
    end)
    scrollOffset = math.max(0, math.min(scrollOffset, #sortedMonsters - visibleRows))
    trackerFrame.subtitle:SetText(
        (Addon.demo and 'DEMO / ' or '')
            .. Addon.Number(totalKills)
            .. ' kills  /  '
            .. #sortedMonsters
            .. ' monster types'
    )
    trackerFrame.money:SetText(moneyText(data.money))
    trackerFrame.xp:SetText(Addon.Number(Addon.TrackerXP(data)))
    trackerFrame.compactMoney:SetText(
        (Addon.demo and 'Demo money: ' or 'Money gained: ') .. moneyText(data.money)
    )
    trackerFrame.compactXP:SetText(
        (Addon.demo and 'Demo XP: ' or 'XP gained: ') .. Addon.Number(Addon.TrackerXP(data))
    )
    if Addon.db.collapsed then
        local plusX = 12 + (trackerFrame.titleLabel:GetStringWidth() or 130) + 6
        local width = math.max(
            plusX + 23 + 8,
            (trackerFrame.compactMoney:GetStringWidth() or 0) + 24,
            (trackerFrame.compactXP:GetStringWidth() or 0) + 24
        )
        trackerFrame:SetWidth(width)
        trackerFrame.title:SetWidth(plusX - 6)
        positionRegion(trackerFrame.plus, plusX, -6)
    end
    trackerFrame.empty:SetShown(#sortedMonsters == 0 and not Addon.db.collapsed)
    trackerFrame.page:SetText(
        #sortedMonsters > visibleRows
                and (scrollOffset + 1 .. '-' .. math.min(scrollOffset + visibleRows, #sortedMonsters) .. ' / ' .. #sortedMonsters .. '  (scroll)')
            or 'Hover a monster for collected drops'
    )
    for i, row in ipairs(monsterRows) do
        row.mob = i <= visibleRows and sortedMonsters[scrollOffset + i] or nil
        row.remove:SetShown(row.mob ~= nil and (row:IsMouseOver() or row.remove:IsMouseOver()))
        row:SetShown(row.mob ~= nil)
        if row.mob then
            Addon.SetBestiaryPortrait(row.portrait, Addon.TrackerPortraitID(row.mob))
            row.name:SetText(row.mob.name)
            row.level:SetText(Addon.LevelText(row.mob))
            row.count:SetText(Addon.Number(row.mob.count))
            row.money:SetText(moneyText(row.mob.money or 0))
            row.xp:SetText(Addon.Number(row.mob.xp) .. ' XP')
        end
    end
    trackerFrame.scrollbar:Update(#sortedMonsters, visibleRows, scrollOffset, visibleRows * 30)
    Addon.RefreshDrops()
end

-- Construct the tracker window and wire controls
function Addon.BuildUI()
    expandedWidth = math.max(300, math.min(800, Addon.db.width or expandedWidth))
    expandedHeight = math.max(304, math.min(900, Addon.db.height or expandedHeight))
    trackerFrame = CreateFrame('Frame', 'ForeverHuntFrame', UIParent, 'BackdropTemplate')
    trackerFrame:SetSize(expandedWidth, expandedHeight)
    trackerFrame:SetScale(Addon.db.scale)
    trackerFrame:SetClampedToScreen(true)
    trackerFrame:SetMovable(true)
    trackerFrame:EnableMouse(true)
    trackerFrame:EnableMouseWheel(true)
    trackerFrame:SetScript('OnMouseWheel', handleScaleWheel)
    trackerFrame:SetFrameStrata('MEDIUM')
    Addon.SkinPanel(trackerFrame, true)
    local savedPosition = Addon.db.position
    if savedPosition then
        trackerFrame:SetPoint(
            savedPosition.point,
            UIParent,
            savedPosition.relative,
            savedPosition.x,
            savedPosition.y
        )
    else
        trackerFrame:SetPoint('CENTER', 260, 0)
    end

    -- Title bar and dragging
    local title = CreateFrame('Frame', nil, trackerFrame)
    trackerFrame.title = title
    title:SetPoint('TOPLEFT', 6, -4)
    title:SetSize(207, 39)
    title:EnableMouse(true)
    title:RegisterForDrag('LeftButton')
    title:EnableMouseWheel(true)
    title:SetScript('OnMouseWheel', handleScaleWheel)
    title:SetScript('OnDragStart', function()
        trackerFrame:StartMoving()
    end)
    title:SetScript('OnDragStop', function()
        trackerFrame:StopMovingOrSizing()
        local point, _, relative, x, y = trackerFrame:GetPoint()
        Addon.db.position = { point = point, relative = relative, x = x, y = y }
    end)
    trackerFrame.titleLabel = createText(title, 13, 6, -6, "Raynna's Tracker")
    trackerFrame.titleLabel:SetTextColor(unpack(titleColor))
    trackerFrame.subtitle = createText(title, 10, 12, -29)
    trackerFrame.compactMoney = createText(title, 11, 6, -27)
    trackerFrame.compactXP = createText(title, 11, 6, -45)
    trackerFrame.compactXP:SetTextColor(0.55, 0.75, 1)
    trackerFrame.minus = button(trackerFrame, '-', 23, 243, -8, function()
        Addon.SetCollapsed(true)
    end)
    trackerFrame.plus = button(trackerFrame, '+', 23, 175, -6, function()
        Addon.SetCollapsed(false)
    end)
    trackerFrame.close = button(trackerFrame, 'x', 23, 267, -6, toggleVisibility)
    trackerFrame.minus:SetHeight(18)
    trackerFrame.plus:SetHeight(18)
    trackerFrame.close:SetHeight(18)
    local questSummary = CreateFrame('Frame', nil, trackerFrame)
    trackerFrame.questSummary = questSummary
    table.insert(contentRegions, questSummary)
    questSummary:SetPoint('TOPLEFT', 12, -49)
    questSummary:SetSize(276, 32)
    questSummary.count = createText(questSummary, 11, 0, 0)
    questSummary.count:SetTextColor(unpack(titleColor))
    questSummary.xp = createText(questSummary, 10, 0, -16)
    questSummary.hideXP = CreateFrame('CheckButton', nil, questSummary, 'UICheckButtonTemplate')
    questSummary.hideXP:SetSize(20, 20)
    questSummary.hideXP:SetPoint('TOPRIGHT', -102, 4)
    createText(questSummary.hideXP, 10, 21, -5, 'Include quest XP')
    questSummary.hideXP:SetScript('OnClick', function(self)
        Addon.db.includeQuestXP = self:GetChecked() and true or false
        Addon.Draw()
    end)
    trackerFrame.monsterHeader = createText(trackerFrame, 10, 12, -53, 'MONSTER')
    trackerFrame.levelHeader = createText(trackerFrame, 10, 216, -53, 'LVL')
    trackerFrame.killHeader = createText(trackerFrame, 10, 257, -53, 'KILLS')

    -- Scrollable monster rows
    local scroll = CreateFrame('Frame', nil, trackerFrame)
    trackerFrame.scroll = scroll
    table.insert(contentRegions, scroll)
    scroll:SetPoint('TOPLEFT', 8, -70)
    scroll:SetSize(284, 210)
    scroll:EnableMouseWheel(true)
    local function listWheel(self, delta)
        if handleScaleWheel(self, delta) then
            return
        end
        scrollOffset = scrollOffset - delta
        Addon.HideDrops()
        Addon.Draw()
    end
    scroll:SetScript('OnMouseWheel', listWheel)
    trackerFrame.scrollbar = Addon.Scrollbar(scroll, function(value)
        scrollOffset = value
        Addon.HideDrops()
        Addon.Draw()
    end)
    trackerFrame.scrollbar:SetScript('OnMouseWheel', listWheel)
    trackerFrame.scrollbar:SetPoint('TOPRIGHT', scroll, 'TOPRIGHT', 0, 0)
    for i = 1, 24 do
        local row = CreateFrame('Button', nil, scroll)
        row:SetPoint('TOPLEFT', 0, -(i - 1) * 30)
        row:SetSize(284, 30)
        row:SetHighlightTexture('Interface\\QuestFrame\\UI-QuestTitleHighlight', 'ADD')
        row.portrait = CreateFrame('Frame', nil, row)
        row.portrait:SetSize(24, 24)
        row.portrait:SetPoint('TOPLEFT', 3, -3)
        row.name = createText(row, 12, 32, -4)
        row.name:SetWidth(158)
        row.name:SetJustifyH('LEFT')
        row.name:SetWordWrap(false)
        row.level = createText(row, 11, 195, -4)
        row.count = createText(row, 12, 249, -4)
        row.count:SetWidth(28)
        row.money = createText(row, 10, 32, -18)
        row.xp = createText(row, 10, 155, -18)
        row.xp:SetTextColor(0.55, 0.75, 1)
        row.remove = button(row, 'x', 18, 0, 0, function()
            if not row.mob then
                return
            end
            Addon.HideDrops()
            trackerFrame.confirm.kind = 'entry'
            trackerFrame.confirm.entry = row.mob
            trackerFrame.confirm.data = Addon.DisplayData()
            trackerFrame.confirm.label:SetText(
                'Remove ' .. row.mob.name .. '?\nClears this entry and its collected loot.'
            )
            trackerFrame.confirm.action:SetText('Remove')
            trackerFrame.confirm:Show()
        end)
        row.remove:ClearAllPoints()
        row.remove:SetPoint('TOPRIGHT', row, 'TOPRIGHT', 0, -1)
        row.remove:SetHeight(18)
        row.remove:Hide()
        local function hideRemove()
            C_Timer.After(0, function()
                if not row:IsMouseOver() and not row.remove:IsMouseOver() then
                    row.remove:Hide()
                end
            end)
        end
        row:SetScript('OnLeave', hideRemove)
        row.remove:SetScript('OnLeave', hideRemove)
        row.remove:SetScript('OnEnter', function()
            row.remove:Show()
        end)
        row:SetScript('OnHide', function()
            row.remove:Hide()
        end)
        row:SetScript('OnEnter', function(self)
            if self.mob then
                self.remove:Show()
                Addon.ShowDrops(self, self.mob)
            end
        end)
        monsterRows[i] = row
    end
    trackerFrame.empty = createText(trackerFrame, 12, 25, -125, 'Your next hunt starts here.')
    trackerFrame.page = createText(trackerFrame, 10, 12, -287)
    trackerFrame.moneyLabel = createText(trackerFrame, 11, 12, -312, 'Money gained')
    trackerFrame.money = createText(trackerFrame, 12, 116, -311)
    trackerFrame.xpLabel = createText(trackerFrame, 11, 12, -335, 'XP gained')
    trackerFrame.xp = createText(trackerFrame, 12, 116, -334)

    -- Editable scale controls and shortcut hints
    trackerFrame.scaleLabel = createText(trackerFrame, 11, 12, -365, 'UI scale')
    trackerFrame.scaleDown = button(trackerFrame, '-', 24, 108, -360, function()
        setScale(Addon.db.scale - 0.05)
    end)
    trackerFrame.scaleUp = button(trackerFrame, '+', 24, 204, -360, function()
        setScale(Addon.db.scale + 0.05)
    end)
    trackerFrame.bestiary = button(trackerFrame, 'Bestiary', 60, 230, -360, function()
        if Addon.BestiaryDemo then
            Addon.BestiaryDemo()
        end
    end)
    local input = CreateFrame('EditBox', 'RaynnaTrackerScaleInput', trackerFrame, 'InputBoxTemplate')
    trackerFrame.scaleInput = input
    table.insert(contentRegions, input)
    input:SetSize(54, 22)
    input:SetPoint('TOPLEFT', 141, -360)
    input:SetAutoFocus(false)
    input:SetMaxLetters(6)
    input:SetJustifyH('CENTER')
    input:SetText(math.floor(Addon.db.scale * 100 + 0.5) .. '%')
    input:SetScript('OnEnterPressed', function(self)
        local value = tonumber((self:GetText():gsub('%%', '')))
        if value then
            setScale(value / 100)
        end
        self:SetText(math.floor(Addon.db.scale * 100 + 0.5) .. '%')
        self:ClearFocus()
    end)
    input:SetScript('OnEscapePressed', function(self)
        self:SetText(math.floor(Addon.db.scale * 100 + 0.5) .. '%')
        self:ClearFocus()
    end)
    input:SetScript('OnEditFocusLost', function(self)
        self:SetText(math.floor(Addon.db.scale * 100 + 0.5) .. '%')
    end)
    for _, control in ipairs({
        trackerFrame.scaleDown,
        trackerFrame.scaleUp,
        input,
        trackerFrame.minus,
        trackerFrame.plus,
    }) do
        control:EnableMouseWheel(true)
        control:SetScript('OnMouseWheel', handleScaleWheel)
        control:SetScript('OnEnter', function(self)
            GameTooltip:SetOwner(self, 'ANCHOR_RIGHT')
            GameTooltip:SetText('Hold Ctrl + scroll to rescale', 0.35, 0.87, 0.73)
            GameTooltip:AddLine('5% per step, from 40% to 180%.', 0.85, 0.89, 0.93)
            if self == input then
                GameTooltip:AddLine('Type a percentage and press Enter.', 0.85, 0.89, 0.93)
            end
            GameTooltip:Show()
        end)
        control:SetScript('OnLeave', function()
            GameTooltip:Hide()
        end)
        control:SetScript('OnHide', function()
            GameTooltip:Hide()
        end)
    end
    trackerFrame.resetButtons = {}
    trackerFrame.resetButtons[1] = button(trackerFrame, 'Reset all', 276, 12, -362, function()
        showResetConfirmation('all')
    end)

    -- Reset confirmation overlay
    local confirm = CreateFrame('Frame', nil, trackerFrame, 'BackdropTemplate')
    trackerFrame.confirm = confirm
    confirm:SetAllPoints(trackerFrame)
    confirm:SetFrameLevel(trackerFrame:GetFrameLevel() + 20)
    confirm:EnableMouse(true)
    Addon.SkinPanel(confirm, false)
    confirm.label = createText(confirm, 13, 16, -112)
    confirm.label:SetWidth(268)
    trackerFrame.confirm.action = button(confirm, 'Reset', 100, 40, -170, function()
        local kind = confirm.kind
        confirm:Hide()
        if kind == 'entry' then
            Addon.RemoveTrackerEntry(confirm.data, confirm.entry)
            confirm.entry, confirm.data = nil, nil
        else
            Addon.Reset(kind)
        end
    end)
    button(confirm, 'Cancel', 100, 160, -170, function()
        confirm:Hide()
    end)
    confirm:Hide()
    trackerFrame:SetScript('OnHide', function()
        confirm:Hide()
        Addon.HideDrops()
    end)
    -- Independent-axis resizing tracks the cursor without scaling fonts or snapping dimensions.
    local function savePosition()
        local point, _, relative, x, y = trackerFrame:GetPoint()
        Addon.db.position = { point = point, relative = relative, x = x, y = y }
    end
    for _, direction in ipairs({
        'LEFT',
        'RIGHT',
        'TOP',
        'BOTTOM',
        'TOPLEFT',
        'TOPRIGHT',
        'BOTTOMLEFT',
        'BOTTOMRIGHT',
    }) do
        local handle = CreateFrame('Frame', nil, trackerFrame)
        table.insert(resizeHandles, handle)
        handle.direction = direction
        handle:SetFrameLevel(trackerFrame:GetFrameLevel() + 10)
        handle:EnableMouse(true)
        handle:SetScript('OnEnter', function(self)
            Addon.ShowResizeCursor(self, direction)
        end)
        handle:SetScript('OnLeave', function(self)
            if not self.resizing then
                Addon.HideResizeCursor(self)
            end
        end)
        local horizontal = direction:find('LEFT') and -1 or direction:find('RIGHT') and 1 or 0
        local vertical = direction:find('BOTTOM') and -1 or direction:find('TOP') and 1 or 0
        if horizontal ~= 0 and vertical ~= 0 then
            handle:SetSize(10, 10)
            handle:SetPoint(direction)
        elseif horizontal ~= 0 then
            handle:SetWidth(6)
            handle:SetPoint('TOP' .. direction, 0, -10)
            handle:SetPoint('BOTTOM' .. direction, 0, 10)
        else
            handle:SetHeight(6)
            handle:SetPoint(direction .. 'LEFT', 10, 0)
            handle:SetPoint(direction .. 'RIGHT', -10, 0)
        end
        local function finish(self)
            self.resizing = false
            self:SetScript('OnUpdate', nil)
            Addon.HideResizeCursor(self)
            savePosition()
        end
        handle:SetScript('OnMouseDown', function(self, mouseButton)
            if mouseButton ~= 'LeftButton' then
                return
            end
            self.resizing = true
            Addon.ShowResizeCursor(self, direction)
            local startX, startY = GetCursorPosition()
            local effective = trackerFrame:GetEffectiveScale()
            local left, top = trackerFrame:GetLeft(), trackerFrame:GetTop()
            local width, height = trackerFrame:GetWidth(), trackerFrame:GetHeight()
            Addon.HideDrops()
            self:SetScript('OnUpdate', function()
                local x, y = GetCursorPosition()
                local dx, dy = (x - startX) / effective, (y - startY) / effective
                local newWidth = math.max(300, math.min(800, width + horizontal * dx))
                local newHeight = math.max(304, math.min(900, height + vertical * dy))
                local newLeft = horizontal == -1 and left + width - newWidth or left
                local newTop = vertical == 1 and top - height + newHeight or top
                trackerFrame:ClearAllPoints()
                trackerFrame:SetPoint('TOPLEFT', UIParent, 'BOTTOMLEFT', newLeft, newTop)
                if newWidth ~= trackerFrame:GetWidth() or newHeight ~= trackerFrame:GetHeight() then
                    trackerFrame:SetSize(newWidth, newHeight)
                    Addon.Layout()
                    Addon.Draw()
                end
                if not IsMouseButtonDown('LeftButton') then
                    finish(self)
                end
            end)
        end)
        handle:SetScript('OnMouseUp', finish)
        handle:SetScript('OnHide', finish)
    end

    -- Minimap launcher
    local mini = CreateFrame('Button', 'ForeverHuntMinimapButton', Minimap, 'BackdropTemplate')
    mini:SetSize(30, 30)
    mini:SetFrameStrata('MEDIUM')
    mini:SetBackdrop({
        bgFile = 'Interface\\Buttons\\WHITE8X8',
        edgeFile = 'Interface\\Buttons\\WHITE8X8',
        edgeSize = 1,
    })
    mini:SetBackdropColor(0.12, 0.08, 0.03, 1)
    mini:SetBackdropBorderColor(unpack(titleColor))
    local icon = mini:CreateTexture(nil, 'ARTWORK')
    icon:SetAllPoints()
    icon:SetTexture('Interface\\Icons\\Ability_Hunter_SniperShot')
    local function positionMinimapButton()
        local a = math.rad(Addon.db.minimapAngle or 220)
        mini:ClearAllPoints()
        mini:SetPoint('CENTER', Minimap, 'CENTER', math.cos(a) * 82, math.sin(a) * 82)
    end
    mini:RegisterForDrag('LeftButton')
    mini:SetScript('OnDragStart', function(self)
        self:SetScript('OnUpdate', function()
            local x, y = GetCursorPosition()
            local mx, my = Minimap:GetCenter()
            local s = Minimap:GetEffectiveScale()
            Addon.db.minimapAngle = math.deg(math.atan2(y / s - my, x / s - mx))
            positionMinimapButton()
        end)
    end)
    mini:SetScript('OnDragStop', function(self)
        self:SetScript('OnUpdate', nil)
    end)
    mini:SetScript('OnClick', toggleVisibility)
    mini:SetScript('OnEnter', function(self)
        GameTooltip:SetOwner(self, 'ANCHOR_LEFT')
        GameTooltip:AddLine("Raynna's Tracker", unpack(titleColor))
        GameTooltip:AddLine('Click: show / hide\nDrag: move this button', 1, 1, 1)
        GameTooltip:Show()
    end)
    mini:SetScript('OnLeave', function()
        GameTooltip:Hide()
    end)
    positionMinimapButton()
    mini:SetShown(not Addon.db.hideMinimap)
    Addon.SetMinimapVisible = function(visible)
        Addon.db.hideMinimap = not visible
        mini:SetShown(visible)
    end
    Addon.SetTrackerScale = setScale

    -- Slash commands and initial visibility
    SLASH_FOREVERHUNT1, SLASH_FOREVERHUNT2, SLASH_FOREVERHUNT3 = '/fh', '/foreverhunt', '/rt'
    SlashCmdList.FOREVERHUNT = function(msg)
        local command, value = msg:match('^(%S*)%s*(.-)$')
        command = command:lower()
        if command == 'settings' then
            Addon.OpenSettings()
        elseif command == 'scale' and tonumber(value) then
            setScale(tonumber(value))
        elseif command == 'demo' then
            Addon.HideDrops()
            scrollOffset = 0
            trackerFrame.confirm:Hide()
            Addon.Demo(value:lower() ~= 'off')
            Addon.db.hidden = false
            trackerFrame:Show()
            Addon.SetCollapsed(false)
        elseif command == 'reset' then
            showResetConfirmation(
                value == 'money' and 'money'
                    or value == 'xp' and 'xp'
                    or value == 'kills' and 'kills'
                    or 'all'
            )
        elseif command == 'show' then
            Addon.db.hidden = false
            trackerFrame:Show()
        elseif command == 'hide' then
            Addon.db.hidden = true
            trackerFrame:Hide()
        elseif command == 'center' then
            Addon.db.position = nil
            trackerFrame:ClearAllPoints()
            trackerFrame:SetPoint('CENTER')
            Addon.db.hidden = false
            trackerFrame:Show()
        elseif command == '' then
            toggleVisibility()
        else
            print(
                "Raynna's Tracker: /rt | show | hide | scale 0.4-1.8 | center | reset kills | reset money | reset xp | demo | demo off"
            )
        end
    end
    trackerFrame:SetShown(not Addon.db.hidden)
    Addon.SetCollapsed(Addon.db.collapsed or false)
end
