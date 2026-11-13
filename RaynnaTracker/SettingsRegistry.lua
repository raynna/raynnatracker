-- Shared bootstrap v1, bundled identically by independent Raynna addons.
if RaynnaModsSettingsRegistry then
    return
end
local Registry = { version = 1, pages = {}, providers = {} }
RaynnaModsSettingsRegistry = Registry

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
    root:SetScript('OnShow', function()
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
