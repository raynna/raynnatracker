-- Character-specific options for Raynna's installed tracker and bestiary.
local _, Addon = ...
local panel, category
local refreshers = {}

local function label(text, x, y, heading)
    local textRegion =
        panel:CreateFontString(nil, 'OVERLAY', heading and 'GameFontNormalLarge' or 'GameFontHighlight')
    textRegion:SetPoint('TOPLEFT', x, y)
    textRegion:SetText(text)
    return textRegion
end

local function checkbox(text, x, y, get, set)
    local control = CreateFrame('CheckButton', nil, panel, 'UICheckButtonTemplate')
    control:SetSize(26, 26)
    control:SetPoint('TOPLEFT', x, y)
    label(text, x + 30, y - 6)
    local function refresh()
        control:SetChecked(get())
    end
    control:SetScript('OnClick', function(self)
        set(self:GetChecked() and true or false)
    end)
    refreshers[#refreshers + 1] = refresh
end

local function button(text, x, y, callback)
    local control = CreateFrame('Button', nil, panel, 'UIPanelButtonTemplate')
    control:SetPoint('TOPLEFT', x, y)
    control:SetSize(150, 24)
    control:SetText(text)
    control:SetScript('OnClick', callback)
end

local function percentage(text, y, get, set, minimum, maximum)
    label(text, 24, y - 5)
    local input = CreateFrame('EditBox', nil, panel, 'InputBoxTemplate')
    input:SetPoint('TOPLEFT', 245, y)
    input:SetSize(65, 24)
    input:SetAutoFocus(false)
    input:SetMaxLetters(5)
    local function refresh()
        input:SetText(math.floor(get() * 100 + 0.5) .. '%')
    end
    local function apply(value)
        if value then
            set(math.max(minimum, math.min(maximum, value)))
        end
        refresh()
    end
    input:SetScript('OnEnterPressed', function(self)
        apply(tonumber((self:GetText() or ''):match('^%s*(%d+)%s*%%?%s*$')))
        self:ClearFocus()
    end)
    input:SetScript('OnEscapePressed', function(self)
        refresh()
        self:ClearFocus()
    end)
    input:SetScript('OnEditFocusLost', refresh)
    for index, delta in ipairs({ -5, 5 }) do
        local control = CreateFrame('Button', nil, panel, 'UIPanelButtonTemplate')
        control:SetPoint('TOPLEFT', index == 1 and 212 or 318, y)
        control:SetSize(24, 24)
        control:SetText(delta < 0 and '-' or '+')
        control:SetScript('OnClick', function()
            apply(math.floor(get() * 100 + 0.5) + delta)
        end)
    end
    refreshers[#refreshers + 1] = refresh
end

function Addon.OpenSettings()
    RaynnaModsSettingsRegistry:Open('foreverhunt')
end

function Addon.BuildSettings()
    Addon.db.appearance = Addon.db.appearance or {}
    RaynnaModsSettingsRegistry:RegisterAppearance('foreverhunt', function()
        return Addon.db.appearance
    end, function(key, value)
        Addon.db.appearance[key] = value
        Addon.ApplyAppearance()
    end)
    RaynnaModsSettingsRegistry:Register('foreverhunt', 'Tracker & Bestiary', function(host)
        panel = host
        label("Raynna's mods", 24, -20, true)
        label('Changes apply immediately and are saved for this character.', 24, -48)
        label("Raynna's Tracker", 24, -83, true)
        checkbox('Show tracker', 24, -108, function()
            return not Addon.db.hidden
        end, function(value)
            SlashCmdList.FOREVERHUNT(value and 'show' or 'hide')
        end)
        checkbox('Minimize tracker', 280, -108, function()
            return Addon.db.collapsed
        end, Addon.SetCollapsed)
        checkbox('Show minimap button', 24, -138, function()
            return not Addon.db.hideMinimap
        end, Addon.SetMinimapVisible)
        percentage('Tracker scale', -174, function()
            return Addon.db.scale
        end, function(value)
            Addon.SetTrackerScale(value / 100)
        end, 40, 180)
        button('Center and show', 365, -174, function()
            SlashCmdList.FOREVERHUNT('center')
        end)
        label('Reopen any time: /rt show   |   Settings: /rt settings', 24, -210)

        label("Raynna's Bestiary", 24, -248, true)
        checkbox('Alt-hover monsters', 24, -274, function()
            return Addon.db.bestiary.npcHover ~= false
        end, function(value)
            Addon.db.bestiary.npcHover = value
        end)
        checkbox('Alt-hover inventory items', 280, -274, function()
            return Addon.db.bestiary.itemHover ~= false
        end, function(value)
            Addon.db.bestiary.itemHover = value
        end)
        percentage('Bestiary scale', -310, function()
            return Addon.db.bestiary.scale or 1
        end, function(value)
            Addon.SetBestiaryScale(value / 100)
        end, 40, 180)
        button('Open bestiary', 365, -310, function()
            SlashCmdList.RAYNNABESTIARY('')
        end)

        label('Appearance - all installed Raynna addons', 24, -365, true)
        checkbox('Parchment background texture', 24, -392, function()
            return Addon.db.appearance.paper ~= false
        end, function(value)
            RaynnaModsSettingsRegistry:SetAppearance('paper', value)
        end)
        percentage('Background opacity', -430, function()
            return Addon.db.appearance.opacity or 0.97
        end, function(value)
            RaynnaModsSettingsRegistry:SetAppearance('opacity', value / 100)
        end, 20, 100)
        panel:SetScript('OnShow', function()
            for _, refresh in ipairs(refreshers) do
                refresh()
            end
        end)
        return function()
            for _, refresh in ipairs(refreshers) do
                refresh()
            end
        end
    end)
end
