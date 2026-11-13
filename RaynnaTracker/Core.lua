-- Tracking and persistence. Receives game events and updates per-character history.
-- Public Addon methods and SavedVariables field names are compatibility contracts.

local _, Addon = ...
local observedCreatures, pendingKills, countedKills, lootSources = {}, {}, {}, {}
local moneyBaseline, isInitialized
local xpBaseline, xpMaximum, xpLevel, xpUpdateQueued
local pendingCoinSource
local unmatchedKillXP = {}

-- Value guards and monster identity
local function isReadableValue(value)
    return not issecretvalue or not issecretvalue(value)
end
local function isCreatureGUID(guid)
    return isReadableValue(guid) and type(guid) == 'string' and guid:match('^Creature%-')
end
local function getMonsterKey(name)
    return name
end
local function includeLevel(row, level)
    if type(level) ~= 'number' or level <= 0 then
        return
    end
    row.minLevel = math.min(row.minLevel or level, level)
    row.maxLevel = math.max(row.maxLevel or level, level)
end

-- Saved monster records and level ranges
function Addon.LevelText(row)
    if not row.minLevel then
        return '?'
    end
    if row.minLevel == row.maxLevel then
        return tostring(row.minLevel)
    end
    return row.minLevel .. '-' .. row.maxLevel
end
function Addon.MergeMobs(mobs)
    local merged = {}
    for _, old in pairs(mobs) do
        local row = merged[old.name] or { name = old.name, count = 0, money = 0, xp = 0, drops = {} }
        merged[old.name] = row
        row.npcID = row.npcID or old.npcID
        row.count = row.count + old.count
        row.lastKillOrder = math.max(row.lastKillOrder or 0, old.lastKillOrder or 0)
        row.money = row.money + (old.money or 0)
        row.xp = row.xp + (old.xp or 0)
        includeLevel(row, old.minLevel or old.level)
        includeLevel(row, old.maxLevel or old.level)
        for id, drop in pairs(old.drops) do
            local mergedDrop = row.drops[id] or { link = drop.link, count = 0 }
            mergedDrop.count = mergedDrop.count + drop.count
            row.drops[id] = mergedDrop
        end
    end
    return merged
end
function Addon.Refresh()
    if Addon.Draw then
        Addon.Draw()
    end
end

-- Creature observations and kill attribution
function Addon.Observe(unit)
    local guid = UnitGUID(unit)
    if not isCreatureGUID(guid) then
        return
    end
    local name, level = UnitName(unit), UnitLevel(unit)
    if not isReadableValue(name) or not isReadableValue(level) or not name then
        return
    end
    observedCreatures[guid] = { name = name, level = level and level > 0 and level or '?', time = GetTime() }
    if pendingKills[guid] then
        pendingKills[guid] = nil
        Addon.Kill(guid, name)
    end
end
local function getOrCreateMonster(guid, name)
    local info = observedCreatures[guid] or { name = name, level = '?' }
    if not info.name then
        return
    end
    local monsterKey = getMonsterKey(info.name, info.level)
    local row = Addon.db.mobs[monsterKey]
    if not row then
        row = { name = info.name, count = 0, money = 0, xp = 0, drops = {} }
        Addon.db.mobs[monsterKey] = row
    end
    includeLevel(row, info.level)
    row.npcID = row.npcID or tonumber(guid:match('^Creature%-%d+%-%d+%-%d+%-%d+%-(%d+)%-'))
    return row, monsterKey
end
function Addon.Kill(guid, name)
    if not isCreatureGUID(guid) or countedKills[guid] then
        return
    end
    local row = getOrCreateMonster(guid, name)
    if not row then
        return
    end
    countedKills[guid] = GetTime()
    row.count = row.count + 1
    Addon.db.killOrder = (Addon.db.killOrder or 0) + 1
    row.lastKillOrder = Addon.db.killOrder
    local waiting = unmatchedKillXP[row.name]
    if waiting then
        if GetTime() - waiting.time < 5 then
            row.xp = (row.xp or 0) + waiting.amount
        end
        unmatchedKillXP[row.name] = nil
    end
    Addon.Refresh()
end
-- Forever exposes this event directly; combat-log registration is forbidden.
function Addon.PartyKill(attacker, victim)
    if not isReadableValue(attacker) or not isCreatureGUID(victim) then
        return
    end
    Addon.Observe('target')
    Addon.Observe('mouseover')
    local info = observedCreatures[victim]
    if info then
        Addon.Kill(victim, info.name)
    else
        pendingKills[victim] = GetTime()
    end
end
-- Snapshot corpse provenance before auto-loot removes slots. Only self loot
-- chat confirmations consume these entries; merely opening a corpse adds nothing.

-- Loot snapshots and confirmed item/coin receipts
function Addon.ScanLoot(newWindow)
    if newWindow then
        pendingCoinSource = nil
    end
    if not GetLootSourceInfo then
        return
    end
    Addon.Observe('target')
    local snapshot = {}
    local unique, ambiguous, sourceSeen
    for slot = 1, GetNumLootItems() do
        local slotSources = { GetLootSourceInfo(slot) }
        for i = 1, #slotSources, 2 do
            sourceSeen = true
            local guid = slotSources[i]
            if not isCreatureGUID(guid) or (unique and unique ~= guid) then
                ambiguous = true
            else
                unique = guid
            end
        end
        local link = GetLootSlotLink(slot)
        if isReadableValue(link) and link then
            local id = link:match('item:(%d+)')
            local src = { GetLootSourceInfo(slot) }
            if id then
                snapshot[id] = snapshot[id] or {}
                for i = 1, #src, 2 do
                    local guid, quantity = src[i], src[i + 1]
                    if isCreatureGUID(guid) and isReadableValue(quantity) and quantity and quantity > 0 then
                        local info = observedCreatures[guid]
                        local monsterKey = info and getMonsterKey(info.name, info.level)
                        -- Do not guess a source using the last target or last kill.
                        if monsterKey and Addon.db.mobs[monsterKey] then
                            table.insert(snapshot[id], {
                                key = monsterKey,
                                quantity = quantity,
                                link = link,
                                time = GetTime(),
                            })
                        end
                    end
                end
            end
        end
    end
    -- Money confirmation can arrive after LOOT_CLOSED. Remember the actual
    -- single corpse, not a wallet delta or an assumed coin-slot numeric ID.
    if not sourceSeen then
        local target = UnitGUID('target')
        local isDead = UnitIsDead and UnitIsDead('target')
        if isCreatureGUID(target) and isReadableValue(isDead) and isDead and countedKills[target] then
            unique = target
        end
    end
    local info = unique and observedCreatures[unique]
    if ambiguous then
        pendingCoinSource = nil
    elseif info and Addon.db.mobs[info.name] then
        if not pendingCoinSource or pendingCoinSource.guid ~= unique then
            pendingCoinSource = { guid = unique, key = info.name, time = GetTime() }
        end
    end
    for id, entries in pairs(snapshot) do
        lootSources[id] = entries
    end
end

-- Localized message parsing
local function makeMessagePattern(format)
    if not format then
        return
    end
    local messagePattern = format:gsub('([%^%$%(%)%%%.%[%]%*%+%-%?])', '%%%1')
    messagePattern = messagePattern:gsub('%%%%s', '(.+)'):gsub('%%%%d', '(%%d+)')
    return '^' .. messagePattern .. '$'
end
function Addon.MonsterMoney(message)
    if not isReadableValue(message) or type(message) ~= 'string' or not pendingCoinSource then
        return
    end
    local age = GetTime() - (pendingCoinSource.closed or pendingCoinSource.time)
    if age > (pendingCoinSource.closed and 3 or 120) or pendingCoinSource.used then
        return
    end
    local amountText
    for _, token in ipairs({
        'YOU_LOOT_MONEY',
        'LOOT_MONEY_SPLIT',
        'YOU_LOOT_MONEY_GUILD',
        'LOOT_MONEY_SPLIT_GUILD',
    }) do
        if _G[token] then
            amountText = message:match(makeMessagePattern(_G[token]))
            if amountText then
                break
            end
        end
    end
    if not amountText then
        return
    end
    local amount = 0
    for _, unit in ipairs({ { 'GOLD_AMOUNT', 10000 }, { 'SILVER_AMOUNT', 100 }, { 'COPPER_AMOUNT', 1 } }) do
        local format = _G[unit[1]]
        if format then
            local messagePattern = makeMessagePattern(format):sub(2, -2)
            amount = amount + (tonumber(amountText:match(messagePattern)) or 0) * unit[2]
        end
    end
    if amount <= 0 then
        return
    end
    local row = Addon.db.mobs[pendingCoinSource.key]
    if row then
        row.money = (row.money or 0) + amount
    end
    pendingCoinSource.used = true
    Addon.Refresh()
end
-- Named XP chat messages identify the actual recipient monster; quest and
-- exploration gains remain exclusively in the overall XP counter.
function Addon.MonsterXP(message)
    if not isReadableValue(message) or type(message) ~= 'string' then
        return
    end
    for _, suffix in ipairs({
        'FIRSTPERSON',
        'FIRSTPERSON_GROUP',
        'FIRSTPERSON_RAID',
        'EXHAUSTION1',
        'EXHAUSTION2',
        'EXHAUSTION4',
        'EXHAUSTION5',
        'EXHAUSTION1_GROUP',
        'EXHAUSTION2_GROUP',
        'EXHAUSTION4_GROUP',
        'EXHAUSTION5_GROUP',
        'EXHAUSTION1_RAID',
        'EXHAUSTION2_RAID',
        'EXHAUSTION4_RAID',
        'EXHAUSTION5_RAID',
    }) do
        local format = _G['COMBATLOG_XPGAIN_' .. suffix]
        if format then
            local name, amount = message:match(makeMessagePattern(format))
            amount = tonumber(amount)
            if name and amount then
                local row = Addon.db.mobs[name]
                if row then
                    row.xp = (row.xp or 0) + amount
                else
                    local old = unmatchedKillXP[name]
                    unmatchedKillXP[name] = {
                        amount = amount + (old and GetTime() - old.time < 5 and old.amount or 0),
                        time = GetTime(),
                    }
                end
                Addon.Refresh()
                return
            end
        end
    end
end
function Addon.Loot(message)
    if not isReadableValue(message) then
        return
    end
    local link, amount
    for _, format in ipairs({ LOOT_ITEM_SELF_MULTIPLE or '', LOOT_ITEM_SELF or '' }) do
        local l, n = message:match(makeMessagePattern(format))
        if l then
            link, amount = l, tonumber(n) or 1
            break
        end
    end
    if not link then
        return
    end
    local id = link:match('item:(%d+)')
    local entries = id and lootSources[id]
    if not entries then
        return
    end
    for _, entry in ipairs(entries) do
        if amount <= 0 then
            break
        end
        if GetTime() - entry.time < 120 then
            local n = math.min(amount, entry.quantity)
            local row = Addon.db.mobs[entry.key]
            if row and n > 0 then
                local drop = row.drops[id] or { link = entry.link, count = 0 }
                row.drops[id] = drop
                drop.count = drop.count + n
                entry.quantity = entry.quantity - n
                amount = amount - n
            end
        end
    end
    Addon.Refresh()
end

-- Quest rewards are reported directly, independently of overall XP deltas.
function Addon.QuestTurnedIn(questID, xpReward)
    if not isReadableValue(questID) or type(questID) ~= 'number' or questID <= 0 then
        return
    end
    local quests = Addon.db.quests or { count = 0, xp = 0, unknownXP = 0 }
    Addon.db.quests = quests
    quests.count = quests.count + 1
    if isReadableValue(xpReward) and type(xpReward) == 'number' and xpReward >= 0 then
        quests.xp = quests.xp + xpReward
    else
        quests.unknownXP = (quests.unknownXP or 0) + 1
    end
    Addon.Refresh()
end

-- Overall income, XP and independent resets
function Addon.Money()
    local current = GetMoney()
    if not isReadableValue(current) then
        return
    end
    if moneyBaseline and current > moneyBaseline then
        local gained = current - moneyBaseline
        Addon.db.money = Addon.db.money + gained
    end
    moneyBaseline = current
    Addon.Refresh()
end
function Addon.Reset(kind)
    if kind == 'all' then
        Addon.Reset('money')
        Addon.Reset('xp')
        Addon.Reset('kills')
        local data = Addon.demo or Addon.db
        data.quests = { count = 0, xp = 0, unknownXP = 0 }
        data.questXPBaseline = 0
        Addon.Refresh()
        return
    end
    if Addon.demo then
        if kind == 'money' then
            Addon.demo.money = 0
        elseif kind == 'xp' then
            Addon.demo.xp = 0
            Addon.demo.questXPBaseline = Addon.demo.quests and Addon.demo.quests.xp or 0
        else
            Addon.demo.mobs = {}
        end
        Addon.Refresh()
        return
    end
    if kind == 'money' then
        Addon.db.money = 0
        moneyBaseline = GetMoney()
    elseif kind == 'xp' then
        Addon.db.xp = 0
        Addon.db.questXPBaseline = Addon.db.quests and Addon.db.quests.xp or 0
        xpBaseline, xpMaximum, xpLevel = UnitXP('player'), UnitXPMax('player'), UnitLevel('player')
    else
        Addon.db.mobs = {}
        lootSources = {}
        pendingKills = {}
        unmatchedKillXP = {}
        pendingCoinSource = nil
    end
    Addon.Refresh()
end
function Addon.RemoveTrackerEntry(data, entry)
    -- Remove only the selected record; session income and XP remain independent.
    for key, mob in pairs(data.mobs) do
        if mob == entry then
            data.mobs[key] = nil
            break
        end
    end
    Addon.Refresh()
end

function Addon.TrackerXP(data)
    if Addon.db.includeQuestXP == false then
        local questXP = math.max(0, (data.quests and data.quests.xp or 0) - (data.questXPBaseline or 0))
        return math.max(0, (data.xp or 0) - questXP)
    end
    return data.xp or 0
end
function Addon.XP()
    local current, maximum, level = UnitXP('player'), UnitXPMax('player'), UnitLevel('player')
    if not isReadableValue(current) or not isReadableValue(maximum) or not isReadableValue(level) then
        return
    end
    if xpBaseline then
        local gained = current - xpBaseline
        if level > xpLevel then
            gained = gained + xpMaximum
        end
        Addon.db.xp = Addon.db.xp + math.max(0, gained)
    end
    xpBaseline, xpMaximum, xpLevel = current, maximum, level
    Addon.Refresh()
end

-- Initialization, event routing and stale-observation cleanup
local function CopySavedData(value)
    if type(value) ~= 'table' then
        return value
    end
    local copy = {}
    for key, entry in pairs(value) do
        copy[key] = CopySavedData(entry)
    end
    return copy
end

function Addon.MigrateSavedData(current, legacy)
    if type(current) == 'table' then
        return current
    end
    return type(legacy) == 'table' and CopySavedData(legacy) or {}
end

local eventFrame = CreateFrame('Frame')
Addon.events = eventFrame
eventFrame:RegisterEvent('ADDON_LOADED')
eventFrame:RegisterEvent('PLAYER_LOGIN')
eventFrame:SetScript('OnEvent', function(_, event, ...)
    if event == 'ADDON_LOADED' then
        if ... ~= 'RaynnaTracker' then
            return
        end
        RaynnaTrackerDB = Addon.MigrateSavedData(RaynnaTrackerDB, ForeverHuntDB)
        Addon.db = RaynnaTrackerDB
        Addon.demo = Addon.db.demoPreview
        Addon.db.mobs = Addon.MergeMobs(Addon.db.mobs or {})
        for _, mob in pairs(Addon.db.mobs) do
            Addon.db.killOrder = math.max(Addon.db.killOrder or 0, mob.lastKillOrder or 0)
        end
        Addon.db.money = Addon.db.money or 0
        Addon.db.xp = Addon.db.xp or 0
        Addon.db.scale = Addon.db.scale or 1
        return
    end
    if event == 'PLAYER_LOGIN' then
        moneyBaseline = GetMoney()
        xpBaseline, xpMaximum, xpLevel = UnitXP('player'), UnitXPMax('player'), UnitLevel('player')
        isInitialized = true
        for _, e in ipairs({
            'CHAT_MSG_MONEY',
            'CHAT_MSG_COMBAT_XP_GAIN',
            'QUEST_TURNED_IN',
            'PLAYER_XP_UPDATE',
            'PLAYER_LEVEL_UP',
            'PLAYER_MONEY',
            'PLAYER_TARGET_CHANGED',
            'UPDATE_MOUSEOVER_UNIT',
            'NAME_PLATE_UNIT_ADDED',
            'PARTY_KILL',
            'LOOT_READY',
            'LOOT_OPENED',
            'LOOT_CLOSED',
            'CHAT_MSG_LOOT',
        }) do
            local ok = pcall(eventFrame.RegisterEvent, eventFrame, e)
            if not ok and e == 'PARTY_KILL' then
                print(
                    "|cff66ddbbRaynna's Tracker:|r This client does not expose PARTY_KILL; kill tracking is unavailable."
                )
            end
        end
        Addon.Observe('target')
        Addon.PreloadTrackerPortraits()
        Addon.BuildUI()
        if Addon.BuildBestiary then
            Addon.BuildBestiary()
        end
        if Addon.BuildSettings then
            Addon.BuildSettings()
        end
        C_Timer.NewTicker(60, function()
            local cutoff = GetTime() - 1800
            for guid, info in pairs(observedCreatures) do
                if info.time < cutoff then
                    observedCreatures[guid] = nil
                end
            end
            for guid, time in pairs(pendingKills) do
                if time < cutoff then
                    pendingKills[guid] = nil
                end
            end
            for guid, time in pairs(countedKills) do
                if time < cutoff then
                    countedKills[guid] = nil
                end
            end
            for name, entry in pairs(unmatchedKillXP) do
                if GetTime() - entry.time > 5 then
                    unmatchedKillXP[name] = nil
                end
            end
            for id, entries in pairs(lootSources) do
                if not entries[1] or entries[1].time < GetTime() - 120 then
                    lootSources[id] = nil
                end
            end
        end)
        return
    end
    if not isInitialized then
        return
    end
    if event == 'PLAYER_MONEY' then
        Addon.Money()
    elseif event == 'CHAT_MSG_MONEY' then
        Addon.MonsterMoney(...)
    elseif event == 'CHAT_MSG_COMBAT_XP_GAIN' then
        Addon.MonsterXP(...)
    elseif event == 'QUEST_TURNED_IN' then
        Addon.QuestTurnedIn(...)
    elseif event == 'PLAYER_XP_UPDATE' or event == 'PLAYER_LEVEL_UP' then
        if event == 'PLAYER_XP_UPDATE' and ... ~= 'player' then
            return
        end
        if not xpUpdateQueued then
            xpUpdateQueued = true
            C_Timer.After(0, function()
                xpUpdateQueued = false
                Addon.XP()
            end)
        end
    elseif event == 'PARTY_KILL' then
        Addon.PartyKill(...)
    elseif event == 'PLAYER_TARGET_CHANGED' then
        Addon.Observe('target')
    elseif event == 'UPDATE_MOUSEOVER_UNIT' then
        Addon.Observe('mouseover')
    elseif event == 'NAME_PLATE_UNIT_ADDED' then
        Addon.Observe(...)
    elseif event == 'LOOT_READY' or event == 'LOOT_OPENED' then
        Addon.ScanLoot(event == 'LOOT_READY')
    elseif event == 'LOOT_CLOSED' then
        if pendingCoinSource then
            pendingCoinSource.closed = GetTime()
        end
    elseif event == 'CHAT_MSG_LOOT' then
        Addon.Loot(...)
    end
end)
