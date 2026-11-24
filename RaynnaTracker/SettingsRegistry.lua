-- Shared bootstrap v2: responsive wrapped addon navigation.
if RaynnaModsSettingsRegistry and (RaynnaModsSettingsRegistry.version or 1) >= 2 then
    return
end
local Registry = RaynnaModsSettingsRegistry or { pages = {}, providers = {} }
Registry.version = 2
RaynnaModsSettingsRegistry = Registry

function Registry:Layout()
    if not self.root then
        return
    end
    local width = self.root:GetWidth()
    if type(width) ~= 'number' or width < 100 then
        width = 600
    end
    local available = math.max(1, width - 48)
    local columns = math.max(1, math.floor((available + 8) / 180))
    local buttonWidth = math.min(172, (available - (columns - 1) * 8) / columns)
    local ids = {}
    for id in pairs(self.pages) do
        table.insert(ids, id)
    end
    table.sort(ids)
    local rows = math.ceil(#ids / columns)
    for index, id in ipairs(ids) do
        local page = self.pages[id]
        page.button:ClearAllPoints()
        page.button:SetPoint(
            'TOPLEFT',
            24 + ((index - 1) % columns) * (buttonWidth + 8),
            -12 - math.floor((index - 1) / columns) * 30
        )
        page.button:SetSize(buttonWidth, 24)
        page.frame:ClearAllPoints()
        page.frame:SetPoint('TOPLEFT', 0, -(12 + rows * 30))
        page.frame:SetPoint('BOTTOMRIGHT', 0, 0)
    end
end

function Registry:Initialize()
    if self.root then
        return
    end
    local root = CreateFrame('Frame', 'RaynnaModsSettingsRoot', UIParent)
    self.root = root
    root.name = "Raynna's mods"
    root:Hide()
    if Settings and Settings.RegisterCanvasLayoutCategory and Settings.RegisterAddOnCategory then
        self.category = Settings.RegisterCanvasLayoutCategory(root, root.name)
        Settings.RegisterAddOnCategory(self.category)
    elseif InterfaceOptions_AddCategory then
        InterfaceOptions_AddCategory(root)
    end
    root:SetScript('OnSizeChanged', function()
        self:Layout()
    end)
    root:SetScript('OnShow', function()
        self:Layout()
        self:Select(self.selected)
    end)
end

function Registry:Select(id)
    self.selected = id or next(self.pages)
    for key, page in pairs(self.pages) do
        if key == self.selected then
            page.frame:Show()
            if page.refresh then
                page.refresh()
            end
        else
            page.frame:Hide()
        end
    end
end

function Registry:Register(id, title, build)
    if self.pages[id] then
        return self.pages[id].frame
    end
    self:Initialize()
    local frame = CreateFrame('Frame', nil, self.root)
    frame:SetPoint('TOPLEFT', 0, -40)
    frame:SetPoint('BOTTOMRIGHT', 0, 0)
    local count = 0
    for _ in pairs(self.pages) do
        count = count + 1
    end
    local button = CreateFrame('Button', nil, self.root, 'UIPanelButtonTemplate')
    button:SetPoint('TOPLEFT', 24 + count * 180, -12)
    button:SetSize(172, 24)
    button:SetText(title)
    button:SetScript('OnClick', function()
        self:Select(id)
    end)
    local page = { frame = frame, button = button }
    self.pages[id] = page
    page.refresh = build(frame)
    self.root:SetScript('OnSizeChanged', function()
        self:Layout()
    end)
    self:Layout()
    self:Select(self.selected or id)
    return frame
end

function Registry:Open(id)
    self:Initialize()
    self:Select(id)
    if self.category and Settings and Settings.OpenToCategory then
        Settings.OpenToCategory(self.category:GetID())
    elseif InterfaceOptionsFrame_OpenToCategory then
        InterfaceOptionsFrame_OpenToCategory(self.root)
    end
end

function Registry:RegisterAppearance(id, get, set)
    self.providers[id] = { get = get, set = set }
end
function Registry:AppearanceDefaults()
    local _, provider = next(self.providers)
    local value = provider and provider.get() or {}
    return { paper = value.paper ~= false, opacity = value.opacity or 0.97 }
end
function Registry:SetAppearance(key, value)
    for _, provider in pairs(self.providers) do
        provider.set(key, value)
    end
end
