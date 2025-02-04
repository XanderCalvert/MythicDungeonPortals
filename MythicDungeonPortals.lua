-- MythicDungeonPortals.lua
local addonName, addon = ...
local constants = addon.constants

local currentTab = nil
local totalTabs = 0

local MDPFrame = CreateFrame("Frame", "MDPFrame", UIParent, "BasicFrameTemplate")

MDPFrame:SetSize(350, 500)
MDPFrame:SetPoint("CENTER")
MDPFrame:SetMovable(true)
MDPFrame:EnableMouse(true)
MDPFrame:SetClampedToScreen(true)
MDPFrame:RegisterForDrag("LeftButton")
MDPFrame:SetScript("OnDragStart", MDPFrame.StartMoving)
MDPFrame:SetScript("OnDragStop", MDPFrame.StopMovingOrSizing)

MDPFrame.background = MDPFrame:CreateTexture(nil, "BACKGROUND")
MDPFrame.background:SetAllPoints(MDPFrame)
MDPFrame.background:Hide() -- Initially hide the background

MDPFrame.title = MDPFrame:CreateFontString(nil, "OVERLAY")
MDPFrame.title:SetFontObject("GameFontHighlight")
MDPFrame.title:SetPoint("CENTER", MDPFrame.TitleBg, "CENTER")
MDPFrame.title:SetText("Mythic Dungeon Portals")
MDPFrame.TitleBg:SetColorTexture(0, 0, 0)  -- RGB for black

local contentFrames = {}

local function HasLearnedSpell(spellID)
    return IsSpellKnown(spellID)
end

local function AddSpellIcons(tabFrame, mapIDs)
    local buttonSize = 40 -- Size of each spell icon button
    local padding = 5    -- Padding between buttons
    local numColumns = 1 -- Number of buttons per row
    local topPadding = 35 -- the first buttons padding from top
    local leftPadding = 20 -- pad the buttons by a set 20px
    local textOffset = 5 -- Offset for the text from the button

    for index, mapID in ipairs(mapIDs) do
        local spellID = constants.mapIDtoSpellID[mapID]
        local dungeonName = constants.mapIDtoDungeonName[mapID]
        if spellID then
            local button = CreateFrame("Button", nil, tabFrame, "SecureActionButtonTemplate")
            button:SetSize(buttonSize, buttonSize)

            -- Calculate position
            local row = math.floor((index - 1) / numColumns)
            local col = (index - 1) % numColumns
            button:SetPoint("TOPLEFT", tabFrame, "TOPLEFT", col * (buttonSize + padding) + leftPadding, -row * (buttonSize + padding) - topPadding)

            -- Create and set icon texture
            local icon = button:CreateTexture(nil, "ARTWORK")
            icon:SetAllPoints(button)
            local spellTexture = GetSpellTexture(spellID)
            icon:SetTexture(spellTexture)

            -- Check if the spell is learned
            if not HasLearnedSpell(spellID) then
                icon:SetDesaturated(true)
                button:Disable()
            else
                button:RegisterForClicks("LeftButtonUp", "LeftButtonDown")
                button:SetAttribute("type", "spell")
                button:SetAttribute("unit", "player")
                button:SetAttribute("spell", spellID)
            end

            button:SetScript("OnEnter", function(self)
                GameTooltip:SetOwner(self, "ANCHOR_RIGHT")
                GameTooltip:SetSpellByID(spellID)
                GameTooltip:Show()
            end)
            button:SetScript("OnLeave", function(self)
                GameTooltip:Hide()
            end)

            local dungeonText = tabFrame:CreateFontString(nil, "ARTWORK", "GameFontNormal")
            dungeonText:SetPoint("LEFT", button, "RIGHT", textOffset, 0)
            dungeonText:SetText(dungeonName)
        end
    end
end

local function UpdateMDPTabs(selectedTabName)
    for name, tabFrame in pairs(contentFrames) do
        if name == selectedTabName then
            tabFrame:Show()
        else
            tabFrame:Hide()
        end
    end
    currentTab = selectedTabName
end

local function UpdateFrameBackground(selectedTabName)
    local texturePath = constants.mapExpansionToBackground[selectedTabName]
    if texturePath then
        MDPFrame.background:SetTexture(texturePath)
        MDPFrame.background:Show()
    else
        MDPFrame.background:Hide()
    end
end

-- Function to create tabs
local function CreateTab(expansionName, mapIDs)
    local topPadding = 30
    totalTabs = totalTabs + 1
    local tabButton = CreateFrame("Button", "TabButtons", MDPFrame, "UIPanelButtonTemplate")

    tabButton:SetSize(120, 30)
    tabButton:SetPoint("TOPRIGHT", MDPFrame, "TOPRIGHT", -20, -(topPadding + (totalTabs - 1) * 30))
    tabButton:SetText(expansionName)
    tabButton:SetNormalFontObject("GameFontNormal")
    tabButton:SetHighlightFontObject("GameFontHighlight")

    if expansionName == "War Within" then 
        tabButton:Disable()
    end

    local tabFrame = CreateFrame("Frame", "TabFrame", MDPFrame)
    tabFrame:SetAllPoints()
    tabFrame:Hide()

    contentFrames[expansionName] = tabFrame
    AddSpellIcons(tabFrame, mapIDs)

    -- Event handler for tab click
    tabButton:SetScript("OnClick", function()
        UpdateMDPTabs(expansionName)
        UpdateFrameBackground(expansionName)
    end)

    -- Initially show content of the first tab
    if totalTabs == 1 then
        UpdateMDPTabs(expansionName)
        UpdateFrameBackground(expansionName)
    end

    print("Tab created for " .. expansionName) 
end

local function InitializeTabs()
    for _, expansion in ipairs(constants.orderedExpansions) do
        local mapIDs = constants.mapExpansionToMapID[expansion]
        if mapIDs then
            CreateTab(expansion, mapIDs)
        end
    end
end

local function ToggleFrame()
    if MDPFrame:IsShown() then
        MDPFrame:Hide()
    else
        MDPFrame:Show()
    end
end

local function SlashCmdHandler(msg, editbox)
    ToggleFrame()
end

local function LoadDefaultSettings(addonName)
    if not MythicDungeonPortalsSettings then
        MythicDungeonPortalsSettings = {}
    end
    MythicDungeonPortalsSettings.isMinimapEnabled = true
end

MDPFrame:SetScript("OnEvent", function(self, event, addonNameLoaded)
    if event == "ADDON_LOADED" and addonNameLoaded == addonName then
        LoadDefaultSettings()
        print("Mythic Dungeon Portals loaded. Waiting for player to enter the world...")
    elseif event == "PLAYER_ENTERING_WORLD" then
        print("Initializing Mythic Dungeon Portals")
        InitializeTabs()
        MDPFrame:Hide()
        self:UnregisterEvent("PLAYER_ENTERING_WORLD")
    end
end)

MDPFrame:RegisterEvent("ADDON_LOADED")
MDPFrame:RegisterEvent("PLAYER_ENTERING_WORLD")

SLASH_MDP1 = "/mdp"
SlashCmdList["MDP"] = SlashCmdHandler