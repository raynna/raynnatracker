"""Run with Python + lupa: python tests/test_addon.py. No game required."""
from pathlib import Path
from lupa.lua51 import LuaRuntime

root = Path(__file__).resolve().parents[1]
lua = LuaRuntime(unpack_returned_tuples=True)
lua.execute(r'''
NOW, MONEY = 100, 10000
function IsControlKeyDown() return CTRL or false end
function SetCursor(value) CURSOR = value end
function ResetCursor() CURSOR = nil; CURSOR_MODE = nil end
Enum = {Cursormode = {NoCursor = 0}, TooltipDataType = {Item = 0}}
TooltipDataProcessor = {AddTooltipPostCall = function(_, fn) ITEM_TOOLTIP_CALLBACK = fn end}
function SetCursorByMode(mode) CURSOR_MODE = mode end
function GetTime() return NOW end
function GetMoney() return MONEY end
function issecretvalue() return false end
C_CurrencyInfo = {GetCoinTextureString = function(n) return tostring(n) end}
function UnitGUID(u) if u == 'player' then return 'Player-1' elseif u == 'pet' then return 'Pet-1' else return 'Creature-0-1-2-3-100-1' end end
ALT_DOWN = false
function IsAltKeyDown() return ALT_DOWN end
function UnitName() return 'Forest Wolf' end
XP, XPMAX, PLAYERLEVEL = 100, 1000, 8
function UnitXP() return XP end
function UnitXPMax() return XPMAX end
function UnitLevel(u) return u == 'player' and PLAYERLEVEL or 8 end
local methods = {}
Frames = {}
function methods:RegisterEvent(e) assert(e ~= 'COMBAT_LOG_EVENT_UNFILTERED' and e ~= 'COMBAT_LOG_EVENT', 'forbidden event registration'); self.events = self.events or {}; self.events[e] = true end
function methods:SetParent(parent) self.parent = parent end
function methods:SetText(t) self.labelText = t end
function methods:GetText() return self.labelText end
function methods:SetSize(w,h) self.width = w; self.height = h end
function methods:SetScale(s) self.scale = s end
function methods:GetEffectiveScale() return self.scale or 1 end
function methods:GetFrameLevel() return 1 end
function methods:GetLeft() return 100 end
function methods:GetTop() return 500 end
function methods:GetRight() return 400 end
function methods:GetWidth() return self.width or 1920 end
function methods:GetHeight() return self.height or 1080 end
function methods:SetWidth(w) self.width = w end
function methods:SetHeight(h) self.height = h end
function methods:IsShown() return self.shown end
function methods:IsMouseOver() return self.hovered end
function methods:SetTexture(t) self.texture = t end
function methods:SetHyperlink(t) self.link = t end
function methods:Hide() self.shown = false; if rawget(self, 'OnHide') then self.OnHide(self) end end
function methods:Show() self.shown = true end
function methods:SetShown(s) if s then self:Show() else self:Hide() end end
function methods:SetPoint(p, ...) self.anchor = p; self.pointArgs = {...} end
CURSOR_X, CURSOR_Y = 100, 100
function GetCursorPosition() return CURSOR_X, CURSOR_Y end
function IsMouseButtonDown() return true end
function methods:SetScript(k, f) self[k] = f end
function methods:GetScript(k) return rawget(self,k) end
function methods:GetPoint() return 'CENTER', nil, 'CENTER', 0, 0 end
function methods:CreateFontString() return CreateFrame() end
function methods:CreateTexture() return CreateFrame() end
function CreateFrame(kind, name, parent)
    local frame = setmetatable({kind = kind, parent = parent}, {__index = function(_, k) if k:match('^[A-Z]') then return methods[k] or function() end end end})
    table.insert(Frames, frame)
    if name then _G[name] = frame end
    return frame
end
C_Timer = {NewTicker = function() end, After = function(_, callback) callback() end}
bit = {band = function(a,b) return a % (b + 1) end}
COMBATLOG_XPGAIN_FIRSTPERSON = '%s dies, you gain %d experience.'
COMBATLOG_XPGAIN_FIRSTPERSON_GROUP = '%s dies, you gain %d experience. (+%d group bonus)'
COMBATLOG_XPGAIN_EXHAUSTION1 = '%s dies, you gain %d experience. (%s exp %s bonus)'
YOU_LOOT_MONEY = 'You loot %s'
LOOT_MONEY_SPLIT = 'Your share of the loot is %s.'
GOLD_AMOUNT, SILVER_AMOUNT, COPPER_AMOUNT = '%d Gold', '%d Silver', '%d Copper'
LOOT_ITEM_SELF = 'You receive loot: %s.'
LOOT_ITEM_SELF_MULTIPLE = 'You receive loot: %sx%d.'
UIParent, Minimap, GameTooltip = CreateFrame(), CreateFrame(), CreateFrame()
StaticPopupDialogs, SlashCmdList = {}, {}
STANDARD_TEXT_FONT = 'font'
Settings = {
    RegisterCanvasLayoutCategory = function(panel, name)
        SETTINGS_PANEL, SETTINGS_NAME = panel, name
        return {GetID = function() return 123 end}
    end,
    RegisterAddOnCategory = function() SETTINGS_REGISTERED = true end,
    OpenToCategory = function(id) SETTINGS_OPENED = id end,
}
A = {}
function GetNumLootItems() return 1 end
SLOT_TYPE = 2
function GetLootSlotType() return SLOT_TYPE end
function GetLootSlotLink() return '|cffffffff|Hitem:123:0|h[Wolf Fur]|h|r' end
function GetLootSourceInfo() return UnitGUID('target'), 3 end
''')
for filename in ('SettingsRegistry.lua', 'Core.lua', 'Theme.lua', 'Widgets.lua', 'Demo.lua', 'Drops.lua', 'LootReference.lua', 'Metadata.lua', 'MetadataQueries.lua', 'ForeverReference.lua', 'LootSources.lua', 'PortraitDisplays.lua', 'Portraits.lua', 'Bestiary.lua', 'UI.lua', 'Settings.lua'):
    lua.execute('assert(loadstring(...))("RaynnaTracker", A)', (root / 'RaynnaTracker' / filename).read_text())
lua.execute(r'''
local bundledMetadata = A.ReferenceMetadata
A.events.OnEvent(nil, 'ADDON_LOADED', 'RaynnaTracker')
A.events.OnEvent(nil, 'PLAYER_LOGIN')
assert(SETTINGS_REGISTERED and SETTINGS_NAME == "Raynna's mods", 'native addon settings registered')
SETTINGS_PANEL.OnShow()
SlashCmdList.FOREVERHUNT('settings')
assert(SETTINGS_OPENED == 123, 'settings shortcut opens registered category')
A.SetBestiaryScale(0.75)
assert(A.db.bestiary.scale == 0.75, 'bestiary scale persisted')
A.SetBestiaryScale(1)
A.SetMinimapVisible(false)
assert(A.db.hideMinimap, 'minimap toggle persisted')
A.SetMinimapVisible(true)
assert(A.events.events.CHAT_MSG_LOOT and A.events.events.PARTY_KILL, 'tracking initialized without legacy money API')
local guid = UnitGUID('target')
A.events.OnEvent(nil, 'PARTY_KILL', 'Player-1', guid)
A.events.OnEvent(nil, 'PARTY_KILL', 'Player-1', guid)
local row = next(A.db.mobs) and A.db.mobs[next(A.db.mobs)]
assert(row.count == 1 and A.LevelText(row) == '8', 'kill dedup / level')
A.ScanLoot()
assert(next(row.drops) == nil, 'opening corpse must not count loot')
A.Loot('Other receives loot: ' .. GetLootSlotLink() .. '.')
assert(next(row.drops) == nil, 'other player loot ignored')
A.Loot('You receive loot: ' .. GetLootSlotLink() .. 'x2.')
assert(row.drops['123'].count == 2, 'stack count')
A.Loot('You receive loot: ' .. GetLootSlotLink() .. '.')
assert(row.drops['123'].count == 3, 'single pickup')
A.Loot('You receive loot: ' .. GetLootSlotLink() .. '.')
assert(row.drops['123'].count == 3, 'source quantities cannot be consumed twice')
MONEY = 10500; A.Money(); MONEY = 10200; A.Money(); MONEY = 10300; A.Money()
assert(A.db.money == 600, 'gross income ignores spending')
A.Reset('money'); assert(A.db.money == 0 and row.count == 1, 'independent money reset')
MONEY = 10350; A.Money(); assert(A.db.money == 50, 'money baseline after reset')
A.Reset('kills'); A.Kill(guid, 'Forest Wolf')
assert(next(A.db.mobs) == nil and A.db.money == 50, 'reset cannot recount dead corpse')
NOW = NOW + 1
A.Kill('Creature-0-1-2-3-100-2', 'Forest Wolf')
assert(A.LevelText(A.db.mobs[next(A.db.mobs)]) == '?', 'unknown level stays unknown')
SlashCmdList.FOREVERHUNT('scale 9'); assert(A.db.scale == 1.8)
SlashCmdList.FOREVERHUNT('hide'); assert(A.db.hidden)
SlashCmdList.FOREVERHUNT('show'); assert(not A.db.hidden)
SlashCmdList.FOREVERHUNT('center')
local function findButton(label, parent)
    for _, frame in ipairs(Frames) do
        if frame.kind == 'Button' and frame.labelText == label and (not parent or frame.parent == parent) then return frame end
    end
    error('Missing button ' .. label)
end
local close = findButton('x')
close.OnClick(close); assert(A.db.hidden and not ForeverHuntFrame.shown, 'close click hides')
ForeverHuntMinimapButton.OnClick(); assert(not A.db.hidden and ForeverHuntFrame.shown, 'minimap restores')
SlashCmdList.FOREVERHUNT('scale 1')
ForeverHuntFrame.minus.OnClick(); assert(A.db.collapsed and A.db.scale == 1 and not ForeverHuntFrame.money.shown, 'minus hides contents without scaling')
ForeverHuntFrame.plus.OnClick(); assert(not A.db.collapsed and A.db.scale == 1 and ForeverHuntFrame.money.shown, 'plus restores contents')
local confirm = ForeverHuntFrame.confirm
findButton('Reset all').OnClick(); assert(confirm.shown)
findButton('Cancel', confirm).OnClick(); assert(not confirm.shown and A.db.money == 50, 'cancel preserves money')
A.Reset('money')
assert(not confirm.shown and A.db.money == 0 and next(A.db.mobs), 'money confirmation closes and only clears money')
A.Reset('kills')
assert(not confirm.shown and next(A.db.mobs) == nil, 'kill confirmation clears and closes')
local handles = 0
for _, frame in ipairs(Frames) do
    if frame.parent == ForeverHuntFrame and rawget(frame, 'OnMouseDown') then
        SlashCmdList.FOREVERHUNT('scale 1')
        CURSOR_X, CURSOR_Y = 100, 100
        frame.OnEnter(frame); assert(CURSOR_MODE == 0 and RaynnaResizeIndicator.shown, 'native NoCursor mode and replacement arrow'); frame.OnLeave(frame); assert(CURSOR == nil, 'cursor restored on leave')
        frame.OnMouseDown(frame, 'LeftButton')
        local left, bottom = frame.direction:find('LEFT'), frame.direction:find('BOTTOM')
        local beforeWidth, beforeHeight = ForeverHuntFrame.width, ForeverHuntFrame.height
        CURSOR_X = left and 70 or 130; CURSOR_Y = bottom and 70 or 130
        frame.OnUpdate()
        assert(A.db.scale == 1, 'resize leaves text scale unchanged')
        local horizontal = frame.direction:find('LEFT') or frame.direction:find('RIGHT')
        local vertical = frame.direction:find('TOP') or frame.direction:find('BOTTOM')
        assert(ForeverHuntFrame.width == beforeWidth + (horizontal and 30 or 0), 'independent horizontal resize')
        assert(ForeverHuntFrame.height == beforeHeight + (vertical and 30 or 0), 'independent vertical resize')
        frame.OnMouseUp(frame); assert(not rawget(frame, 'OnUpdate') and A.db.position, 'resize stops and saves')
        handles = handles + 1
    end
end
assert(handles == 8, 'four edges and four corners')
C_CurrencyInfo = nil
A.Draw(); assert(ForeverHuntFrame.money.labelText == '0g 0s 0c', 'no-API fallback')
XP = 250; A.events.OnEvent(nil, 'PLAYER_XP_UPDATE', 'player')
assert(A.db.xp == 150, 'XP gained')
XP = 50; XPMAX = 1200; PLAYERLEVEL = 9
A.events.OnEvent(nil, 'PLAYER_LEVEL_UP', 9)
A.events.OnEvent(nil, 'PLAYER_XP_UPDATE', 'player')
assert(A.db.xp == 950, 'XP level-up rollover and duplicate events')
A.Reset('xp')
assert(A.db.xp == 0 and not confirm.shown, 'XP reset confirmation')
XP = 75; A.XP(); assert(A.db.xp == 25, 'XP reset baseline')
local merged = A.MergeMobs({
    one = {name = 'Tiger', level = 32, count = 2, drops = {['123'] = {link = 'fur', count = 2}}},
    two = {name = 'Tiger', level = 35, count = 3, drops = {['123'] = {link = 'fur', count = 4}}},
    three = {name = 'Tiger', level = '?', count = 1, drops = {}},
})
assert(A.LevelText(merged.Tiger) == '32-35' and merged.Tiger.count == 6 and merged.Tiger.drops['123'].count == 6, 'migration preserves and merges kills/loot')
assert(A.LevelText(A.MergeMobs(merged).Tiger) == '32-35', 'migration idempotent')
A.db.mobs = merged
A.Draw()
assert(A.db.xp == 25, 'kill data migration preserves XP')
-- Coins belong only to a known corpse with a money slot, not later sales.
A.Kill('Creature-0-1-2-3-100-3', 'Forest Wolf')
SLOT_TYPE = 1; A.ScanLoot(true); MONEY = MONEY + 64; A.Money(); A.MonsterMoney('You loot 64 Copper')
assert(A.db.mobs['Forest Wolf'].money == 64, 'corpse coins assigned')
MONEY = MONEY + 500; A.Money()
assert(A.db.mobs['Forest Wolf'].money == 64, 'sales not assigned to last corpse')
A.ScanLoot(); A.events.OnEvent(nil, 'LOOT_CLOSED'); MONEY = MONEY + 100; A.Money()
assert(A.db.mobs['Forest Wolf'].money == 64, 'abandoned coin window clears source')
local realMobs, realMoney, realXP = A.db.mobs, A.db.money, A.db.xp
SlashCmdList.FOREVERHUNT('demo')
local n = 0; for _, monster in pairs(A.demo.mobs) do n = n + 1; assert(next(monster.drops) and monster.money > 0) end
assert(n == 20 and A.demo.xp > 0, 'demo fills 20 monsters and counters')
assert(A.db.mobs == realMobs and A.db.money == realMoney and A.db.xp == realXP, 'demo isolates saved data')
local anchor = CreateFrame('Button'); anchor.hovered = true
A.ShowDrops(anchor, A.demo.mobs['Bloodscalp Warrior'])
assert(RaynnaTrackerDrops.shown, 'interactive drops opened')
local itemRow
for _, f in ipairs(Frames) do if f.parent == RaynnaTrackerDrops and f.kind == 'Button' and f.entry then itemRow = f; break end end
assert(itemRow and itemRow.icon.texture and itemRow.name.labelText, 'icon and name rendered')
itemRow.OnEnter(itemRow); assert(GameTooltip.link == itemRow.entry.drop.link, 'item hyperlink tooltip')
itemRow.OnLeave(itemRow)
local oldItem = itemRow.entry.id
RaynnaTrackerDrops.OnMouseWheel(nil, -1)
assert(itemRow.entry.id ~= oldItem, 'drop list scrolls')
RaynnaTrackerDrops.hovered = true; anchor.hovered = false
RaynnaTrackerDrops.OnUpdate(nil, 1); assert(RaynnaTrackerDrops.shown, 'can move into popup')
RaynnaTrackerDrops.hovered = false; RaynnaTrackerDrops.OnUpdate(nil, 1)
assert(not RaynnaTrackerDrops.shown, 'popup closes on leaving')
ForeverHuntFrame.minus.OnClick()
assert(ForeverHuntFrame.width == 179 and ForeverHuntFrame.height == 72 and ForeverHuntFrame.plus.shown and not ForeverHuntFrame.minus.shown and not ForeverHuntFrame.close.shown and not ForeverHuntFrame.subtitle.shown, 'collapsed compact summary')
ForeverHuntFrame.plus.OnClick(); assert(not ForeverHuntFrame.plus.shown and ForeverHuntFrame.minus.shown, 'expanded minus only')
A.Reset('money'); A.Reset('xp'); A.Reset('kills')
assert(A.demo.money == 0 and A.demo.xp == 0 and not next(A.demo.mobs), 'demo resets')
assert(A.db.mobs == realMobs and A.db.money == realMoney and A.db.xp == realXP, 'demo reset preserves real data')
SlashCmdList.FOREVERHUNT('demo'); assert(next(A.demo.mobs), 'demo command refills')
SlashCmdList.FOREVERHUNT('demo off'); assert(not A.demo and A.DisplayData() == A.db, 'demo off restores live display')
local wolf = A.db.mobs['Forest Wolf']
local xpBefore = A.db.xp
A.events.OnEvent(nil, 'CHAT_MSG_COMBAT_XP_GAIN', 'Forest Wolf dies, you gain 210 experience.')
A.MonsterXP('Forest Wolf dies, you gain 220 experience. (+20 group bonus)')
A.MonsterXP('Forest Wolf dies, you gain 420 experience. (210 exp Rested bonus)')
A.MonsterXP('You gain 1000 experience.')
assert(wolf.xp == 850 and A.db.xp == xpBefore, 'named XP attributed, bonuses parsed, unnamed gains ignored, no total double count')
A.MonsterXP('New Beast dies, you gain 150 experience.')
A.Kill('Creature-0-1-2-3-100-123', 'New Beast')
assert(A.db.mobs['New Beast'].xp == 150, 'XP before kill event reconciled')
local restored = A.MergeMobs(A.db.mobs)
assert(restored['Forest Wolf'].xp == 850, 'saved XP migration')
A.Reset('xp'); assert(wolf.xp == 850, 'overall XP reset independent of monster history')
SlashCmdList.FOREVERHUNT('demo')
local sum = 0; for _, monster in pairs(A.demo.mobs) do assert(monster.xp > 0); sum = sum + monster.xp end
assert(sum == A.demo.xp, 'demo monster XP totals match')
for i = 1, 3 do
    ForeverHuntFrame.minus.OnClick()
    assert(ForeverHuntFrame.anchor == 'TOPLEFT' and ForeverHuntFrame.pointArgs[2] == 'BOTTOMLEFT' and ForeverHuntFrame.pointArgs[3] == 100 and ForeverHuntFrame.pointArgs[4] == 500, 'collapse pins original screen top-left')
    ForeverHuntFrame.plus.OnClick()
    assert(A.db.position.x == 100 and A.db.position.y == 500, 'expand preserves position')
end
SlashCmdList.FOREVERHUNT('demo off')
assert(A.Number(999) == '999' and A.Number(10000) == '10,000' and A.Number(1234567) == '1,234,567', 'number separators')
local bar = A.Scrollbar(UIParent, function(value) SCROLL_VALUE = value end)
bar:Update(20, 5, 0, 150); assert(bar.shown and bar.maximum == 15 and bar.thumbHeight == 37.5)
bar.OnMouseWheel(nil, -1); assert(SCROLL_VALUE == 1, 'scrollbar wheel')
CURSOR_Y = 400; bar.thumb.OnMouseDown(nil, 'LeftButton')
CURSOR_Y = 350; bar.thumb.OnUpdate()
assert(SCROLL_VALUE > 0 and bar.dragging, 'thumb drag scrolls')
bar.thumb.OnMouseUp(); assert(not bar.dragging, 'thumb drag stops')
bar:Update(4, 5, 0, 150); assert(not bar.shown, 'scrollbar hidden when contents fit')
SlashCmdList.FOREVERHUNT('demo'); assert(ForeverHuntFrame.scrollbar.shown, 'main scrollbar visible for overflow')
A.ShowDrops(CreateFrame(), A.demo.mobs['Bloodscalp Warrior']); assert(RaynnaTrackerDrops.scrollbar.shown, 'drop scrollbar visible for overflow')
SlashCmdList.FOREVERHUNT('demo off')
local sourceRow = A.db.mobs['Forest Wolf']
local coinsBefore = sourceRow.money
A.ScanLoot(true); A.events.OnEvent(nil, 'LOOT_CLOSED')
NOW = NOW + 0.5
A.events.OnEvent(nil, 'CHAT_MSG_MONEY', 'You loot 73 Copper')
assert(sourceRow.money == coinsBefore + 73, 'coin confirmation after loot closes')
A.events.OnEvent(nil, 'CHAT_MSG_MONEY', 'You loot 73 Copper')
assert(sourceRow.money == coinsBefore + 73, 'confirmation consumed once')
A.ScanLoot(true); A.MonsterMoney('You loot 1 Gold, 2 Silver, 3 Copper')
assert(sourceRow.money == coinsBefore + 73 + 10203, 'gold silver copper parsing')
A.ScanLoot(true); A.events.OnEvent(nil, 'LOOT_CLOSED'); NOW = NOW + 4
A.MonsterMoney('You loot 99 Copper')
assert(sourceRow.money == coinsBefore + 73 + 10203, 'expired corpse does not receive money')
local shapes = {LEFT='Horizontal', RIGHT='Horizontal', TOP='Vertical', BOTTOM='Vertical', TOPLEFT='DiagonalDown', BOTTOMRIGHT='DiagonalDown', TOPRIGHT='DiagonalUp', BOTTOMLEFT='DiagonalUp'}
for direction, shape in pairs(shapes) do
    local owner = {}
    A.ShowResizeCursor(owner, direction)
    assert(CURSOR_MODE == 0 and RaynnaResizeIndicator.icon.texture:find(shape .. '.tga', 1, true), 'normal cursor replaced by directional arrow')
    assert(RaynnaResizeIndicator.width == 18 and RaynnaResizeIndicator.pointArgs[3] == CURSOR_X and RaynnaResizeIndicator.pointArgs[4] == CURSOR_Y, 'small replacement centered exactly at hotspot')
    A.HideResizeCursor(owner)
    assert(CURSOR_MODE == nil and not RaynnaResizeIndicator.shown, 'normal pointer restored on leave')
end
local scaleInput = ForeverHuntFrame.scaleInput
scaleInput:SetText('75%'); scaleInput.OnEnterPressed(scaleInput)
assert(A.db.scale == 0.75 and scaleInput.labelText == '75%', 'typed scale percent')
ForeverHuntFrame.scaleDown.OnClick(); assert(math.abs(A.db.scale - 0.7) < 0.001, 'scale minus')
ForeverHuntFrame.scaleUp.OnClick(); assert(math.abs(A.db.scale - 0.75) < 0.001, 'scale plus')
scaleInput:SetText('10'); scaleInput.OnEnterPressed(scaleInput); assert(A.db.scale == 0.4, '40 percent minimum')
scaleInput:SetText('oops'); scaleInput.OnEnterPressed(scaleInput); assert(scaleInput.labelText == '40%', 'invalid input restored')
CTRL = true
local beforeScale = A.db.scale
ForeverHuntFrame.scroll.OnMouseWheel(ForeverHuntFrame.scroll, 1)
assert(math.abs(A.db.scale - beforeScale - 0.05) < 0.001, 'Ctrl wheel scales over list')
A.SetCollapsed(true)
assert(ForeverHuntFrame.compactMoney.shown and ForeverHuntFrame.compactXP.shown, 'collapsed totals visible')
assert(ForeverHuntFrame.compactXP.labelText:find(A.Number(A.DisplayData().xp), 1, true), 'collapsed XP reflects displayed data')
ForeverHuntFrame.title.OnMouseWheel(ForeverHuntFrame.title, -1)
assert(math.abs(A.db.scale - beforeScale) < 0.001, 'Ctrl wheel scales collapsed title')
CTRL = false
ForeverHuntFrame.scroll.OnMouseWheel(ForeverHuntFrame.scroll, 1)
assert(math.abs(A.db.scale - beforeScale) < 0.001, 'normal scrolling preserves scale')
A.SetCollapsed(false)
assert(not ForeverHuntFrame.compactMoney.shown and not ForeverHuntFrame.compactXP.shown, 'expanded hides compact totals')
A.BestiaryDemo()
assert(RaynnaBestiaryFrame.shown and RaynnaBestiaryFrame.context.labelText:find('Preview'), 'bestiary sourced preview explicitly marked')
assert(RaynnaBestiaryFrame.scrollbar.shown, 'bestiary overflow scrollbar')
local entryRow
for _, f in ipairs(Frames) do if f.parent == RaynnaBestiaryFrame and rawget(f,'entry') then entryRow = f; break end end
assert(entryRow and entryRow.icon.texture, 'bestiary item icon')
entryRow.OnEnter(entryRow); assert(GameTooltip.link == entryRow.entry.drop.link, 'bestiary item details tooltip')
assert(RaynnaBestiaryFrame.width == 300 and RaynnaBestiaryFrame.height == 284, 'compact bestiary dimensions')
assert(rawget(entryRow, 'star') == nil and rawget(RaynnaBestiaryFrame, 'filter') == nil, 'wishlist controls removed')
RaynnaBestiaryFrame.pin.OnClick(); ALT_DOWN = true
RaynnaBestiaryFrame.OnEvent(nil, 'UPDATE_MOUSEOVER_UNIT')
assert(RaynnaBestiaryFrame.context.labelText:find('Classic reference') and RaynnaBestiaryFrame.name.labelText == 'Forest Wolf', 'Alt hover shows external reference even in demo mode')
RaynnaBestiaryFrame.pin.OnClick(); ALT_DOWN = false
RaynnaBestiaryFrame.OnUpdate(nil, 2); assert(RaynnaBestiaryFrame.shown, 'pin keeps bestiary open')
RaynnaBestiaryFrame.close.OnClick(); assert(not RaynnaBestiaryFrame.shown, 'bestiary close')
A.ShowBestiary(A.ReferenceMonster(100), false, false)
ALT_DOWN = false
RaynnaBestiaryFrame.OnUpdate(nil, 0)
assert(not RaynnaBestiaryFrame.shown, 'no linger after releasing Alt outside panel')
A.ShowBestiary(A.ReferenceMonster(100), false, false)
ALT_DOWN = true
local originalGUID = UnitGUID
UnitGUID = function() return nil end
RaynnaBestiaryFrame.OnEvent(nil, 'UPDATE_MOUSEOVER_UNIT')
assert(RaynnaBestiaryFrame.shown, 'Alt keeps bestiary visible after leaving monster')
A.ShowBestiary(A.ReferenceMonster(100), false, false)
RaynnaBestiaryFrame.hovered = true
RaynnaBestiaryFrame.OnUpdate(nil, 0)
assert(RaynnaBestiaryFrame.shown, 'hovering panel allows item inspection')
RaynnaBestiaryFrame.hovered = false
ALT_DOWN = false
RaynnaBestiaryFrame.OnLeave()
assert(not RaynnaBestiaryFrame.shown, 'leaving panel hides immediately')
UnitGUID = originalGUID
ALT_DOWN = false
print('PASS: compact bestiary, no wishlist, immediate dismiss, pinning and item tooltips')
local reference = A.ReferenceMonster(587)
assert(reference.drops[4306] and reference.drops[4306].rate > 0, 'Bloodscalp Warrior has sourced Silk Cloth chance')
local unknown = A.ReferenceMonster(99999999, 'Saved Beast', 8)
assert(next(unknown.drops) == nil, 'unknown NPC never falls back to personal history')
A.LootReference.refs[999999] = {{4306, 50, 0, 1, 1, 0}}
A.LootReference.loot[999998] = {{0, 20, 0, -999999, 1, 0}, {2592, -37, 0, 1, 1, 0}}
A.LootReference.creatures[999998] = {999998, 'Reference test', 1, 1}
local resolved = A.ReferenceMonster(999998)
assert(math.abs(resolved.drops[4306].rate - 10) < 0.001, 'reference chance multiplied by item chance')
assert(resolved.drops[2592].rate == 37 and resolved.drops[2592].conditional, 'quest chance marked conditional')
A.LootReference.loot[999997] = {{0, 20, 0, -999999, 2, 0}}
A.LootReference.creatures[999997] = {999997, 'Repeated pool', 1, 1}
assert(A.ReferenceMonster(999997).drops[4306].rate == nil, 'repeat pool does not invent precise chance')
for _, control in ipairs({ForeverHuntFrame.scaleDown, ForeverHuntFrame.scaleUp, ForeverHuntFrame.scaleInput, ForeverHuntFrame.minus, ForeverHuntFrame.plus}) do
    control.OnEnter(control)
    assert(GameTooltip.labelText:find('Ctrl + scroll', 1, true), 'scale shortcut hint')
    control.OnLeave(control)
    assert(not GameTooltip.shown, 'hint hides on leave')
end
A.SetCollapsed(true)
local smallWidth = ForeverHuntFrame.width
ForeverHuntFrame.compactMoney.GetStringWidth = function() return 280 end
A.Draw()
assert(ForeverHuntFrame.width == 304 and ForeverHuntFrame.width > smallWidth, 'compact frame grows to fit large totals')
assert(ForeverHuntFrame.plus.pointArgs[1] == 148, 'plus stays beside title even when totals widen frame')
ForeverHuntFrame.compactMoney.GetStringWidth = function() return 100 end
A.Draw(); assert(ForeverHuntFrame.width == smallWidth, 'compact frame shrinks to fit again')
A.SetCollapsed(false)
print('PASS: sourced loot probabilities, unknown coverage, compact width and shortcut hints')
local itemSource = A.ReferenceItem(4306)
assert(itemSource.drops[587], 'inventory Silk Cloth finds Bloodscalp Warrior')
assert(math.abs(itemSource.drops[587].rate - reference.drops[4306].rate) < 0.0001, 'reverse and forward chances agree')
local ear = A.ReferenceItem(1519)
assert(ear.quest and ear.drops[587].quest, 'Bloodscalp Ear identified as quest-only')
GameTooltip.GetItem = function() return 'Silk Cloth', 'item:4306' end
GameTooltip:Show(); ALT_DOWN = true
ITEM_TOOLTIP_CALLBACK(GameTooltip)
assert(RaynnaBestiaryFrame.section.labelText:find('SOURCES') and GameTooltip.shown, 'Alt item tooltip opens reverse view without hiding original tooltip')
local lastRate = math.huge
for _, f in ipairs(Frames) do
    if f.parent == RaynnaBestiaryFrame and rawget(f, 'entry') and f.shown then
        assert((f.entry.drop.rate or -1) <= lastRate, 'item sources highest rate first')
        lastRate = f.entry.drop.rate or -1
    end
end
GameTooltip.GetItem = function() return 'Bloodscalp Ear', 'item:1519' end
ITEM_TOOLTIP_CALLBACK(GameTooltip)
assert(not RaynnaBestiaryFrame.context.labelText:find('Quest item'), 'crossing another bag item keeps original list locked')
RaynnaBestiaryFrame.hovered = true
RaynnaBestiaryFrame.OnMouseWheel(nil, -1)
assert(not RaynnaBestiaryFrame.context.labelText:find('Quest item'), 'locked list remains scrollable')
RaynnaBestiaryFrame.hovered = false
ALT_DOWN = false
RaynnaBestiaryFrame.OnEvent(nil, 'MODIFIER_STATE_CHANGED')
ALT_DOWN = true
GameTooltip:Show()
ITEM_TOOLTIP_CALLBACK(GameTooltip)
assert(RaynnaBestiaryFrame.context.labelText:find('Quest item'), 'quest item source header')
GameTooltip.GetItem = function() return nil end
RaynnaBestiaryFrame.OnUpdate(nil, 0)
assert(RaynnaBestiaryFrame.shown, 'Alt retains item view after mouse leaves')
ALT_DOWN = false; RaynnaBestiaryFrame.OnUpdate(nil, 0)
assert(not RaynnaBestiaryFrame.shown, 'item view dismisses when neither hovered nor Alt held')
print('PASS: reverse item lookup, descending chances, quest labels and Alt retention')
A.ReferenceMetadata = {Npc={Get=function(id, field)
    if field == 'spawns' then return {[33]={{50,50}}, [40]={{10,10}}} end
end}}
C_Map = {GetAreaInfo=function(id) return ({[33]='Stranglethorn Vale', [40]='Westfall'})[id] end}
assert(A.MonsterZones(587) == 'Stranglethorn Vale, Westfall', 'all known farming zones named')
RaynnaBestiaryFrame.SetFrameLevel = function(self, value) self.actualLevel = value end
ShoppingTooltip1 = {GetFrameLevel=function() return 50 end}
CURSOR_X, CURSOR_Y = 700, 600
A.ShowBestiary(A.ReferenceItem(4306), false, false)
assert(RaynnaBestiaryFrame.actualLevel > 50, 'bestiary raised above comparison tooltip')
assert(RaynnaBestiaryFrame.pointArgs[3] == 716 and RaynnaBestiaryFrame.pointArgs[4] == 588, 'hover panel anchored next to cursor')
for _, f in ipairs(Frames) do
    if f.parent == RaynnaBestiaryFrame and rawget(f, 'entry') and f.shown then
        assert(f.location.shown and f.location.labelText:find('Lv ') and f.location.labelText:find('Stranglethorn Vale'), 'source row includes level and zone')
    end
end
A.ReferenceMetadata = nil
assert(A.MonsterZones(587) == 'Zone unavailable', 'missing location provider handled')
GameTooltip.SetFrameLevel = function(self, value) self.actualLevel = value end
GameTooltip.GetFrameLevel = function(self) return self.actualLevel or 1 end
GameTooltip.actualLevel = 7
local hoverRow
for _, f in ipairs(Frames) do
    if f.parent == RaynnaBestiaryFrame and rawget(f, 'entry') and f.shown then hoverRow = f; break end
end
hoverRow.OnEnter(hoverRow)
assert(GameTooltip.actualLevel > RaynnaBestiaryFrame:GetFrameLevel(), 'row tooltip above bestiary')
hoverRow.OnLeave(hoverRow)
assert(GameTooltip.actualLevel == 7 and not GameTooltip.shown, 'tooltip layer restored after leaving row')
print('PASS: farming levels/zones, cursor position and tooltip layering/restoration')
A.ReferenceMetadata = {
    Item={Get=function(_, field) if field == 'relatedQuests' then return {10, 20, 10} end end},
    Quest={Get=function(id) return ({[10]='A Test Quest', [20]='Another Quest'})[id] end}
}
A.ShowBestiary(A.ReferenceItem(1519), false, true)
assert(RaynnaBestiaryFrame.name.labelText:find('[Quest]', 1, true), 'inventory title has visible quest marker')
assert(RaynnaBestiaryFrame.questLine.shown and RaynnaBestiaryFrame.questLine.labelText == 'Quest: A Test Quest (+1)', 'quest names displayed without duplicates')
A.ReferenceMetadata = nil
A.ShowBestiary(A.ReferenceItem(1519), false, true)
assert(not RaynnaBestiaryFrame.questLine.shown, 'missing quest names do not invent association')
print('PASS: inventory quest marker and associated quest names')
local staff = A.ReferenceItem(279844)
assert(staff.drops['quest:96984'].name == 'Heart of Disruption' and not staff.drops['quest:96984'].rate, 'Forever staff has reward source without invented chance')
A.ReferenceMetadata = {
    Item={Get=function(_, field) return ({npcDrops={999001}, questRewards={123}, vendors={456}})[field] end},
    Npc={Get=function(id, field) if field == 'name' then return 'Source NPC ' .. id end end},
    Quest={Get=function() return 'Reward Quest' end}
}
local expanded = A.ReferenceItem(999000)
assert(expanded.drops[999001] and expanded.drops[999001].rate == nil, 'additional monster source has unknown chance')
assert(expanded.drops['quest:123'].kind == 'Quest' and expanded.drops['vendor:456'].kind == 'Vendor', 'quest and vendor sources included')
A.ShowBestiary(expanded, false, true)
assert(not RaynnaBestiaryFrame.empty.shown, 'non-monster sources render in item panel')
A.ReferenceMetadata = nil
print('PASS: Forever reward correction and additional QuestieDB sources')
SetPortraitTextureFromCreatureDisplayID = function(texture, id) texture.displayID = id end
local portraitHost = CreateFrame()
A.SetBestiaryPortrait(portraitHost, 587)
assert(portraitHost.picture.displayID == A.PortraitDisplays[587] and portraitHost.placeholder.shown, 'NPC portrait staged with correct display ID')
A.UpdatePortraitCache(3)
assert(not portraitHost.placeholder.shown and portraitHost.picture.shown, 'portrait revealed after staging')
A.SetBestiaryPortrait(portraitHost, nil, 4306)
assert(portraitHost.picture.shown and rawget(portraitHost, 'OnUpdate') == nil, 'item icon replaces portrait and cancels pending updates')
local cachedPicture = portraitHost.portraitEntry
A.SetBestiaryPortrait(portraitHost, 587)
assert(not portraitHost.placeholder.shown, 'loaded portrait instantly reused after item view')
local originalPicture = portraitHost.picture
A.SetBestiaryPortrait(portraitHost, 100)
A.SetBestiaryPortrait(portraitHost, 587)
assert(portraitHost.picture == originalPicture and not portraitHost.placeholder.shown, 'scroll-back reuses rendered texture without delay')
print('PASS: NPC portrait staging, session cache and item header icons')
portraitHost.picture:Hide(); portraitHost.placeholder:Show()
A.SetBestiaryPortrait(portraitHost, 587)
assert(portraitHost.picture.shown and not portraitHost.placeholder.shown, 'same-key refresh restores cached portrait')
portraitHost.picture:Hide(); portraitHost.placeholder:Show()
portraitHost.OnShow(portraitHost)
assert(portraitHost.picture.shown and not portraitHost.placeholder.shown, 'row show restores portrait without new load')
A.ReferenceMetadata = bundledMetadata
LibQuestieDB = setmetatable({}, {__index=function() error('External Questie dependency accessed') end})
assert(A.ReferenceMetadata.Npc.Get(587, 'name') == 'Bloodscalp Warrior', 'bundled NPC names')
assert(A.MonsterZones(587):find('Stranglethorn Vale'), 'bundled farming zones')
assert(#A.ItemQuests(1519) > 0, 'bundled quest associations')
UnitFactionGroup = function() return 'Horde' end
assert(A.ReferenceMetadata.Item.Get(3713, 'npcDrops')[1] == 2397, 'bundled Horde source overlay')
UnitFactionGroup = function() return 'Alliance' end
assert(A.ReferenceMetadata.Item.Get(3713, 'npcDrops')[1] == 2381, 'bundled Alliance source overlay')
UnitFactionGroup = nil
local knife = A.ReferenceItem(7005)
local vendors = 0
for _, source in pairs(knife.drops) do if source.kind == 'Vendor' then vendors = vendors + 1 end end
assert(vendors > 0, 'standalone vendor sources')
A.ShowDrops(CreateFrame(), {name='Bloodscalp Warrior',npcID=587,count=1,xp=1,money=1,drops={}})
assert(RaynnaTrackerDrops.portrait.width == 30 and RaynnaTrackerDrops.portrait.portraitKey, 'collected loot popup has cached monster portrait')
print('PASS: standalone metadata, faction sources, vendors, quests and loot-popup portrait')
local previousAddons = C_AddOns
local installedVersion = '1.0.14'
C_AddOns = {GetAddOnMetadata=function() return installedVersion end}
LibQuestieDB = {Npc={Get=function(_, field)
    if field == 'name' then return 'New source name' end
    if field == 'spawns' then return {} end
    if field == 'zoneID' then error('provider not ready') end
end}}
assert(A.ReferenceMetadata.Npc.Get(587, 'name') == 'New source name', 'newer installed metadata preferred')
assert(A.ReferenceMetadata.Npc.Get(587, 'minLevel') == 33, 'missing live field falls back')
assert(next(A.ReferenceMetadata.Npc.Get(587, 'spawns')) == nil, 'explicit empty live correction preserved')
assert(A.ReferenceMetadata.Npc.Get(587, 'zoneID') == 33, 'failed live query falls back')
installedVersion = '1.0.13'
assert(A.ReferenceMetadata.Npc.Get(587, 'name') == 'Bloodscalp Warrior', 'equal version uses bundled snapshot')
installedVersion = '1.0.9'
assert(A.ReferenceMetadata.Npc.Get(587, 'name') == 'Bloodscalp Warrior', 'older version never overrides snapshot')
installedVersion = '1.1.0'; LibQuestieDB = nil
assert(A.ReferenceMetadata.Npc.Get(587, 'name') == 'Bloodscalp Warrior', 'installed but disabled provider falls back')
C_AddOns = previousAddons
print('PASS: optional newer provider, version comparison and per-field fallback')
print('PASS: editable percentage and independent scale buttons')
print('PASS: delayed corpse coins, confirmation deduplication, currency parsing, small directional cursors')
print('PASS: native resize cursor, scrollbar visibility/dragging, comma number formatting')
print('PASS: per-monster XP, XP message order, demo XP and fixed collapse anchoring')
print('PASS: demo isolation, interactive item icons/tooltips, popup scrolling, compact controls, per-monster coins')
print('PASS: XP gains, level-up rollover, reset; merged monster levels and saved loot')
print('PASS: UI construction, kills, deduplication, loot ownership and quantities, income, resets, slash controls')
print('PASS: missing legacy money API, actual button callbacks, reset/cancel dialogs, all eight resize handles')
''')

# Serialize the saved-variable table and load it into a fresh Lua environment,
# matching WoW's logout/login persistence boundary.
lua.execute("A.db.mobs['Saved Beast'] = {name='Saved Beast', count=9, money=73, xp=220, minLevel=32, maxLevel=35, drops={['4306']={link='item:4306',count=4}}}; A.db.money=12345; A.db.xp=67890; A.Demo(true)")
saved = lua.execute(r'''
local function serialize(v)
    if type(v) == 'table' then
        local result = '{'
        for k, value in pairs(v) do result = result .. '[' .. serialize(k) .. ']=' .. serialize(value) .. ',' end
        return result .. '}'
    elseif type(v) == 'string' then return string.format('%q', v)
    else return tostring(v) end
end
return serialize(RaynnaTrackerDB)
''')
restored = LuaRuntime(unpack_returned_tuples=True)
restored.execute("function CreateFrame() return {RegisterEvent=function() end, SetScript=function(self,k,v) self[k]=v end} end; A={}; RaynnaTrackerDB=" + saved)
restored.execute('assert(loadstring(...))("RaynnaTracker", A)', (root / 'RaynnaTracker/Core.lua').read_text())
restored.execute("A.events.OnEvent(nil,'ADDON_LOADED','RaynnaTracker'); local m=A.db.mobs['Saved Beast']; assert(m.count==9 and m.money==73 and m.xp==220 and m.drops['4306'].count==4 and m.minLevel==32 and m.maxLevel==35); assert(A.db.money==12345 and A.db.xp==67890); assert(A.demo==A.db.demoPreview and A.demo.mobs['Bloodscalp Warrior']); print('PASS: fresh-login serialization preserves real kills, loot, coins, XP, levels and separate demo')")
assert 'SetCursor(' not in (root / 'RaynnaTracker/Widgets.lua').read_text()







# Background preloading must preserve staging and reuse the exact warmed texture.
lua.execute(r'''
local savedMobs, savedDemo, savedRecent = A.db.mobs, A.demo, A.db.recentPortraitNPCs
A.db.recentPortraitNPCs = {}
A.demo = nil
A.PortraitDisplays[9999901] = 9999901
A.PortraitDisplays[9999902] = 9999901
A.db.mobs = {
    first = {name='Preload test', npcID=9999901},
    duplicate = {name='Shared display', npcID=9999902},
}
local requests = 0
SetPortraitTextureFromCreatureDisplayID = function(texture, id)
    texture.displayID = id
    if id == 9999901 then requests = requests + 1 end
end
A.PreloadTrackerPortraits()
A.PreloadTrackerPortraits()
A.UpdatePortraitCache(0)
assert(requests == 1, 'preloading deduplicates repeated requests and shared displays')
local host = CreateFrame()
A.SetBestiaryPortrait(host, 9999901)
local picture = host.picture
assert(requests == 1 and host.placeholder.shown, 'visible host claims in-flight preload')
A.UpdatePortraitCache(2.9)
assert(host.placeholder.shown and picture.parent ~= host, 'unfinished render stays off-screen')
A.UpdatePortraitCache(0.11)
assert(not host.placeholder.shown and picture.parent == host, 'warmed preload attaches')
A.SetBestiaryPortrait(host, nil, 4306)
local nextHost = CreateFrame()
A.SetBestiaryPortrait(nextHost, 9999902)
assert(nextHost.picture == picture and not nextHost.placeholder.shown and requests == 1,
    'new row reuses preload instantly without rendering again')
A.db.mobs, A.demo, A.db.recentPortraitNPCs = savedMobs, savedDemo, savedRecent
print('PASS: deduplicated background preload, safety interval and immediate cache reuse')
''')



# Simulate a UI reload with a new portrait module and only serializable saved IDs.
lua.execute(r'''
local oldMobs, oldDemo, oldRecent = A.db.mobs, A.demo, A.db.recentPortraitNPCs
A.PortraitDisplays[9999911] = 9999911
A.PortraitDisplays[9999912] = 9999912
A.db.mobs, A.demo, A.db.recentPortraitNPCs = {}, nil, {}
A.SetBestiaryPortrait(CreateFrame(), 9999911)
A.SetBestiaryPortrait(CreateFrame(), 9999912)
assert(A.db.recentPortraitNPCs[1] == 9999912 and A.db.recentPortraitNPCs[2] == 9999911,
    'Bestiary-only header and source portraits recorded without tracker kills')
PORTRAIT_TEST_OLD = {mobs=oldMobs, demo=oldDemo, recent=oldRecent}
''')
lua.execute('assert(loadstring(...))("RaynnaTracker", A)', (root / 'RaynnaTracker/Portraits.lua').read_text())
lua.execute(r'''
local requests = 0
SetPortraitTextureFromCreatureDisplayID = function(texture, id)
    texture.displayID = id
    requests = requests + 1
end
A.PreloadTrackerPortraits()
A.UpdatePortraitCache(0)
A.UpdatePortraitCache(0)
assert(requests == 4, 'reload preloads Bestiary-only IDs plus simultaneous-use reserves')
A.UpdatePortraitCache(3)
local tracker, header, source = CreateFrame(), CreateFrame(), CreateFrame()
A.SetBestiaryPortrait(tracker, 9999911)
A.SetBestiaryPortrait(header, 9999911)
A.SetBestiaryPortrait(source, 9999912)
assert(not tracker.placeholder.shown and not header.placeholder.shown and not source.placeholder.shown,
    'header and source rows immediately acquire warmed reload cache')
assert(tracker.picture ~= header.picture and requests == 4, 'occupied tracker portrait does not force header reload')
for i = 1, 520 do
    A.PortraitDisplays[10000000+i] = 10000000+i
    A.SetBestiaryPortrait(source, 10000000+i)
end
assert(#A.db.recentPortraitNPCs == 512 and A.db.recentPortraitNPCs[1] == 10000520,
    'portrait history bounded with most recent entries retained')
A.db.mobs, A.demo, A.db.recentPortraitNPCs = PORTRAIT_TEST_OLD.mobs, PORTRAIT_TEST_OLD.demo, PORTRAIT_TEST_OLD.recent
print('PASS: Bestiary-only reload history, source rows, concurrent header and bounded preload list')
''')


lua.execute(r'''
ALT_DOWN = false
RaynnaBestiaryFrame.OnEvent(nil, 'MODIFIER_STATE_CHANGED', 'LALT', 0)
RaynnaBestiaryFrame.hovered = false
A.ShowBestiary(A.ReferenceMonster(587), false, false)
ALT_DOWN = true
GameTooltip:Hide()
GameTooltip.GetItem = function() return nil end
ITEM_TOOLTIP_CALLBACK(GameTooltip, {id=4306})
assert(RaynnaBestiaryFrame.section.labelText:find('SOURCES'),
    'NPC to inventory transition uses post-call data before tooltip show/GetItem')
ITEM_TOOLTIP_CALLBACK(GameTooltip, {id=1519})
assert(not RaynnaBestiaryFrame.context.labelText:find('Quest item'), 'same Alt press still protects list traversal')
RaynnaBestiaryFrame.OnEvent(nil, 'MODIFIER_STATE_CHANGED', 'LALT', 0)
ITEM_TOOLTIP_CALLBACK(GameTooltip, {id=1519})
assert(RaynnaBestiaryFrame.context.labelText:find('Quest item'), 'explicit Alt release clears stale lock even before modifier API updates')
ALT_DOWN = false
RaynnaBestiaryFrame.OnEvent(nil, 'MODIFIER_STATE_CHANGED', 'LALT', 0)
print('PASS: NPC-to-item tooltip timing and explicit Alt-release lock reset')
''')

lua.execute(r'''
A.demo = nil
A.db.mobs = {}
A.Kill('Creature-0-1-2-3-100-8001', 'Older Beast')
A.Kill('Creature-0-1-2-3-100-8002', 'Older Beast')
A.Kill('Creature-0-1-2-3-100-8003', 'Newest Beast')
local first
for _, frame in ipairs(Frames) do
    if frame.mob then first = frame; break end
end
assert(first and first.mob.name == 'Newest Beast', 'newest entry outranks higher kill count')
A.Kill('Creature-0-1-2-3-100-8004', 'Older Beast')
assert(first.mob.name == 'Older Beast', 'repeat kill moves existing row to top')
local order = first.mob.lastKillOrder
A.db.mobs = A.MergeMobs(A.db.mobs)
A.Draw()
assert(first.mob.lastKillOrder == order and first.mob.name == 'Older Beast', 'saved-record merge preserves latest ordering')
print('PASS: newest-first tracker rows, repeat kills and persisted order')
local legacy = {mobs={Wolf={count=7,drops={item={count=3}}}},money=42,hidden=false}
local migrated = A.MigrateSavedData(nil, legacy)
assert(migrated.mobs.Wolf.count==7 and migrated.money==42 and migrated.hidden==false)
migrated.mobs.Wolf.drops.item.count=9
assert(legacy.mobs.Wolf.drops.item.count==3, 'migration keeps original legacy data intact')
assert(A.MigrateSavedData(migrated, legacy)==migrated, 'existing new saves never overwritten')
assert(next(A.MigrateSavedData(nil,nil))==nil, 'fresh installation initializes safely')
print('PASS: renamed-package migration, nested data preservation and existing-save priority')
A.demo=nil; A.db.quests=nil; A.db.includeQuestXP=nil; A.SetCollapsed(false)
assert(ForeverHuntFrame.questSummary:IsShown(), 'quest checkbox available before first turn-in')
assert(ForeverHuntFrame.questSummary.count.labelText=='Quests completed: 0', 'empty quest history shows zero')
local totalXP=A.db.xp
A.events.OnEvent(nil,'QUEST_TURNED_IN',123,1500,0)
A.events.OnEvent(nil,'QUEST_TURNED_IN',124,0,0)
assert(A.db.quests.count==2 and A.db.quests.xp==1500 and A.db.xp==totalXP, 'quest totals do not double-count overall XP')
assert(ForeverHuntFrame.questSummary:IsShown(), 'completed quest summary visible at top')
local check=ForeverHuntFrame.questSummary.hideXP
check.GetChecked=function() return false end
check.OnClick(check)
assert(A.db.includeQuestXP==false and ForeverHuntFrame.questSummary.xp:IsShown(), 'unchecked excludes quest XP but retains subtotal')
A.events.OnEvent(nil,'QUEST_TURNED_IN',123,250,0)
assert(A.db.quests.count==3 and A.db.quests.xp==1750, 'repeatable quests and hidden XP still counted')
A.SetCollapsed(true)
assert(not ForeverHuntFrame.questSummary:IsShown(), 'quest row hides with collapsed tracker')
A.SetCollapsed(false)
check.GetChecked=function() return true end; check.OnClick(check)
assert(ForeverHuntFrame.questSummary.xp:IsShown(), 'quest XP can be shown again')
local copied=A.MigrateSavedData(nil,A.db)
assert(copied.quests.count==3 and copied.quests.xp==1750 and copied.includeQuestXP==true, 'quest data and preference serializable')
A.db.xp=2000; A.db.questXPBaseline=0
assert(A.TrackerXP(A.db)==2000, 'checked includes quests without adding rewards twice')
check.GetChecked=function() return false end; check.OnClick(check)
assert(A.TrackerXP(A.db)==250 and ForeverHuntFrame.xp.labelText=='250', 'unchecked removes quest subtotal from displayed XP')
A.Reset('xp'); A.db.xp=100
assert(A.TrackerXP(A.db)==100, 'XP reset does not subtract earlier quest history')
local entryRow
for _, frame in ipairs(Frames) do if frame.mob then entryRow=frame; break end end
local target=entryRow.mob
entryRow.OnEnter(entryRow); assert(entryRow.remove:IsShown(), 'hover reveals remove button')
entryRow.remove.OnClick()
local confirmation=ForeverHuntFrame.confirm
assert(confirmation.entry==target and confirmation:IsShown(), 'removal targets the clicked entry')
confirmation.action.OnClick()
for _, mob in pairs(A.db.mobs) do assert(mob~=target, 'selected record removed') end
assert(A.db.xp==100, 'individual removal preserves overall totals')
local scale=A.db.scale
ForeverHuntFrame.resetButtons[1].OnClick(); confirmation.action.OnClick()
assert(next(A.db.mobs)==nil and A.db.money==0 and A.db.xp==0 and A.db.quests.count==0 and A.db.quests.xp==0, 'Reset all clears tracker statistics')
assert(A.db.scale==scale and A.db.includeQuestXP==false, 'Reset all preserves preferences')
print('PASS: quest event rewards, zero XP, repeatable quests, visibility toggle and persistence')
''')

lua.execute(r'''
local brine = A.ReferenceMonster(262397)
local weed = A.ReferenceMonster(269175)
assert(brine.foreverReference and brine.name == 'Brinescale Skirmisher')
assert(brine.drops[270305].quest and brine.drops[270305].conditional)
assert(brine.drops[5524].rate == 29.8 and weed.drops[256037].rate == 81.3)
assert(A.ReferenceItem(5524).drops[262397].rate == brine.drops[5524].rate)
assert(A.ReferenceItem(256037).drops[269175].rate == weed.drops[256037].rate)
assert(A.ReferenceItem(270305).quest)
A.ShowBestiary(weed, false, true)
assert(RaynnaBestiaryFrame.context.labelText:find('Forever reference'))
assert(RaynnaBestiaryFrame.footer.labelText:find('Icy Veins'))
assert(next(A.ReferenceMonster(99999998).drops) == nil)
print('PASS: Forever fallback, reverse rates, quest conditions and accurate source labels')
''')
