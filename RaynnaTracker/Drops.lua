-- Collected-loot popup for a tracker row. This displays personal history, not source probabilities.

local _, Addon = ...
local lootPopup, hoveredMonsterRow, selectedMonster, dropEntries, scrollOffset, elapsedOutside =
    nil, nil, nil, {}, 0, 0
local dropRows, requestedItems = {}, {}
local function createLabel(parent, x, y, width)
    local font = parent:CreateFontString(nil, 'OVERLAY', 'GameFontNormal')
    font:SetPoint('TOPLEFT', x, y)
    font:SetWidth(width)
    font:SetJustifyH('LEFT')
    font:SetWordWrap(false)
    return font
end

-- Render collected drops
local function refreshPopup()
    if not selectedMonster then
        return
    end
    dropEntries = {}
    for id, drop in pairs(selectedMonster.drops) do
        table.insert(dropEntries, { id = tonumber(id), drop = drop })
    end
    table.sort(dropEntries, function(a, b)
        if a.drop.count ~= b.drop.count then
            return a.drop.count > b.drop.count
        end
        return (a.id or 0) < (b.id or 0)
    end)
    scrollOffset = math.max(0, math.min(scrollOffset, #dropEntries - 8))
    Addon.SetBestiaryPortrait(lootPopup.portrait, Addon.TrackerPortraitID(selectedMonster))
    lootPopup.title:SetText(selectedMonster.name)
    lootPopup.subtitle:SetText(
        'Level '
            .. Addon.LevelText(selectedMonster)
            .. ' / '
            .. Addon.Number(selectedMonster.count)
            .. ' kills / '
            .. Addon.Number(selectedMonster.xp)
            .. ' XP'
    )
    local amount = selectedMonster.money or 0
    local formatter = C_CurrencyInfo and C_CurrencyInfo.GetCoinTextureString or GetCoinTextureString
    lootPopup.money:SetText(
        'Coins: '
            .. (
                formatter and formatter(amount)
                or string.format(
                    '%dg %ds %dc',
                    math.floor(amount / 10000),
                    math.floor(amount / 100) % 100,
                    amount % 100
                )
            )
    )
    lootPopup.footer:SetText(
        #dropEntries == 0 and 'No collected drops yet.'
            or #dropEntries > 8 and 'Scroll for more / hover items for details'
            or 'Hover items for details'
    )
    lootPopup:SetHeight(100 + math.min(8, #dropEntries) * 30)
    lootPopup.scrollbar:Update(#dropEntries, 8, scrollOffset, math.min(8, #dropEntries) * 30)
    for i, row in ipairs(dropRows) do
        local entry = dropEntries[scrollOffset + i]
        row.entry = entry
        row:SetShown(entry ~= nil)
        if entry then
            local dropRecord = entry.drop
            local name, link, _, _, _, _, _, _, _, texture
            if C_Item and C_Item.GetItemInfo then
                name, link, _, _, _, _, _, _, _, texture = C_Item.GetItemInfo(entry.id)
            end
            if not texture and C_Item and C_Item.GetItemIconByID then
                texture = C_Item.GetItemIconByID(entry.id)
            end
            row.icon:SetTexture(texture or 'Interface\\Icons\\INV_Misc_QuestionMark')
            row.name:SetText(link or dropRecord.name or dropRecord.link)
            row.count:SetText('x' .. Addon.Number(dropRecord.count))
            if
                not name
                and entry.id
                and not requestedItems[entry.id]
                and C_Item
                and C_Item.RequestLoadItemDataByID
            then
                requestedItems[entry.id] = true
                C_Item.RequestLoadItemDataByID(entry.id)
            end
        end
    end
end

-- Popup lifetime
function Addon.HideDrops(preserveTooltip)
    if lootPopup then
        lootPopup:Hide()
    end
    if not preserveTooltip then
        GameTooltip:Hide()
    end
    hoveredMonsterRow, selectedMonster = nil, nil
end
function Addon.RefreshDrops()
    if lootPopup and lootPopup:IsShown() then
        refreshPopup()
    end
end

-- Construct or reuse the interactive popup
function Addon.ShowDrops(anchor, monster)
    if not lootPopup then
        lootPopup = CreateFrame('Frame', 'RaynnaTrackerDrops', UIParent, 'BackdropTemplate')
        lootPopup:SetSize(300, 320)
        lootPopup:SetFrameStrata('DIALOG')
        lootPopup:SetClampedToScreen(true)
        lootPopup:EnableMouse(true)
        lootPopup:EnableMouseWheel(true)
        Addon.SkinPanel(lootPopup, true)
        lootPopup.portrait = CreateFrame('Frame', nil, lootPopup)
        lootPopup.portrait:SetSize(30, 30)
        lootPopup.portrait:SetPoint('TOPLEFT', 10, -31)
        lootPopup.title = createLabel(lootPopup, 10, -10, 280)
        lootPopup.subtitle = createLabel(lootPopup, 48, -32, 242)
        lootPopup.money = createLabel(lootPopup, 48, -49, 242)
        lootPopup.footer = createLabel(lootPopup, 10, -55, 280)
        lootPopup.footer:ClearAllPoints()
        lootPopup.footer:SetPoint('BOTTOMLEFT', 10, 10)
        lootPopup.scrollbar = Addon.Scrollbar(lootPopup, function(value)
            scrollOffset = value
            GameTooltip:Hide()
            refreshPopup()
        end)
        lootPopup.scrollbar:SetPoint('TOPRIGHT', lootPopup, 'TOPRIGHT', -4, -72)
        for i = 1, 8 do
            local row = CreateFrame('Button', nil, lootPopup)
            row:SetPoint('TOPLEFT', 8, -72 - (i - 1) * 30)
            row:SetSize(270, 30)
            row:SetHighlightTexture('Interface\\QuestFrame\\UI-QuestTitleHighlight', 'ADD')
            row.icon = row:CreateTexture(nil, 'ARTWORK')
            row.icon:SetSize(24, 24)
            row.icon:SetPoint('LEFT', 0, 0)
            row.name = createLabel(row, 30, -7, 186)
            row.count = createLabel(row, 220, -7, 54)
            row:SetScript('OnEnter', function(self)
                if not self.entry then
                    return
                end
                GameTooltip:SetOwner(self, 'ANCHOR_RIGHT')
                GameTooltip:SetHyperlink(self.entry.drop.link or ('item:' .. self.entry.id))
                GameTooltip:Show()
            end)
            row:SetScript('OnLeave', function()
                GameTooltip:Hide()
            end)
            dropRows[i] = row
        end
        lootPopup:SetScript('OnMouseWheel', function(_, delta)
            scrollOffset = scrollOffset - delta
            GameTooltip:Hide()
            refreshPopup()
        end)
        lootPopup:SetScript('OnUpdate', function(_, elapsed)
            if
                lootPopup.scrollbar.dragging
                or lootPopup:IsMouseOver()
                or (hoveredMonsterRow and hoveredMonsterRow:IsMouseOver())
            then
                elapsedOutside = 0
            else
                elapsedOutside = elapsedOutside + elapsed
            end
            if elapsedOutside > 0.4 then
                Addon.HideDrops()
            end
        end)
        lootPopup:RegisterEvent('GET_ITEM_INFO_RECEIVED')
        lootPopup:SetScript('OnEvent', function()
            Addon.RefreshDrops()
        end)
    end
    hoveredMonsterRow, selectedMonster, scrollOffset, elapsedOutside = anchor, monster, 0, 0
    lootPopup:SetScale(Addon.db.scale)
    lootPopup:ClearAllPoints()
    local right = ForeverHuntFrame:GetRight() * ForeverHuntFrame:GetEffectiveScale()
    local screen = UIParent:GetWidth() * UIParent:GetEffectiveScale()
    if right + 304 * lootPopup:GetEffectiveScale() > screen then
        lootPopup:SetPoint('TOPRIGHT', ForeverHuntFrame, 'TOPLEFT', -2, -43)
    else
        lootPopup:SetPoint('TOPLEFT', ForeverHuntFrame, 'TOPRIGHT', 2, -43)
    end
    refreshPopup()
    lootPopup:Show()
end
