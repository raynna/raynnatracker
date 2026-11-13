-- Isolated tracker preview data. Real tracking continues in Addon.db while the preview is shown.

local _, Addon = ...

-- Choose the displayed dataset without changing tracking ownership
function Addon.DisplayData()
    return Addon.demo or Addon.db
end

-- Create or dismiss the saved preview
function Addon.Demo(enabled)
    if not enabled then
        Addon.demo = nil
        Addon.db.demoPreview = nil
        Addon.Refresh()
        return
    end
    local monsterNames = {
        'Bloodscalp Warrior',
        'Bloodscalp Axe Thrower',
        'Stranglethorn Tiger',
        'Elder Stranglethorn Tiger',
        'Jungle Stalker',
        'Lashtail Raptor',
        'Panther',
        'Young Panther',
        'River Crocolisk',
        'Bristleback Boar',
        'Forest Wolf',
        'Defias Bandit',
        'Kobold Miner',
        'Murloc Raider',
        'Skeleton Warrior',
        'Venture Co. Geologist',
        'Boulderfist Ogre',
        'Saltstone Basilisk',
        'Feral Mountain Lion',
        'Giant Buzzard',
    }
    local sampleItems = {
        { 2589, 'Linen Cloth' },
        { 2592, 'Wool Cloth' },
        { 4306, 'Silk Cloth' },
        { 4338, 'Mageweave Cloth' },
        { 2318, 'Light Leather' },
        { 2319, 'Medium Leather' },
        { 4234, 'Heavy Leather' },
        { 2835, 'Rough Stone' },
        { 2770, 'Copper Ore' },
        { 2771, 'Tin Ore' },
        { 929, 'Healing Potion' },
        { 1708, 'Sweet Nectar' },
        { 1206, 'Moss Agate' },
        { 1210, 'Shadowgem' },
        { 1529, 'Jade' },
        { 1710, 'Greater Healing Potion' },
        { 3385, 'Lesser Mana Potion' },
        { 4538, 'Snapvine Watermelon' },
        { 4607, 'Delicious Cave Mold' },
        { 4608, 'Raw Black Truffle' },
    }
    Addon.demo = { mobs = {}, money = 0, xp = 0 }
    for i, name in ipairs(monsterNames) do
        local low = math.random(28, 36)
        local mob = {
            name = name,
            minLevel = low,
            maxLevel = low + math.random(0, 3),
            count = math.random(4, 80),
            money = math.random(50, 95000),
            drops = {},
        }
        Addon.demo.mobs[name] = mob
        mob.xp = mob.count * math.random(140, 300)
        Addon.demo.xp = Addon.demo.xp + mob.xp
        Addon.demo.money = Addon.demo.money + mob.money
        -- Every row has drops; the first also exercises drop-list scrolling.
        local count = i == 1 and #sampleItems or math.random(3, 9)
        local start = math.random(1, #sampleItems)
        for j = 1, count do
            local item = sampleItems[(start + j - 2) % #sampleItems + 1]
            mob.drops[tostring(item[1])] =
                { link = 'item:' .. item[1], name = item[2], count = math.random(1, 35) }
        end
    end
    Addon.db.demoPreview = Addon.demo
    Addon.Refresh()
end
