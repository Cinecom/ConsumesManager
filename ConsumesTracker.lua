-- ConsumesTracker.lua

-- Metadata -------------------------------------------------------------------------------------------
AddonName = "Consumes Tracker"
Version = "1.3"
VState = "multi character (beta)"
WindowWidth = 310

-- Onload & Click/Drag Functionality ------------------------------------------------------------------
function ConsumesTracker_OnLoad(self)
    self:RegisterForDrag("LeftButton")
    self:SetScript("OnDragStart", function() ConsumesTracker_OnDragStart(self) end)
    self:SetScript("OnDragStop", function() ConsumesTracker_OnDragStop(self) end)
    DEFAULT_CHAT_FRAME:AddMessage("|cff00ff00" .. AddonName .. " Loaded! (version " .. Version .. "-" .. VState .. ")|r |cff808080[Made by Horyoshi]|r")
end

-- Click Handling -------------------------------------------------------------------------------------
function ConsumesTracker_HandleClick(self, button)
    if not self then return end
    if button == "LeftButton" and not IsShiftKeyDown() then
        if ConsumeTracker_MainFrame and ConsumeTracker_MainFrame:IsShown() then
            ConsumeTracker_MainFrame:Hide()
        else
            ConsumeTracker_ShowMainWindow()
        end
    end
end

-- Drag Functions -------------------------------------------------------------------------------------
function ConsumesTracker_OnDragStart(self)
    if IsShiftKeyDown() then
        self:StartMoving()
        self.isMoving = true
    end
end

function ConsumesTracker_OnDragStop(self)
    if self and self.isMoving then
        self:StopMovingOrSizing()
        self.isMoving = false
    end
end

-- Initialize SavedVariables ----------------------------------------------------------------------------
if not ConsumeTracker_Settings then
    ConsumeTracker_Settings = {}
end
if not ConsumeTracker_Data then
    ConsumeTracker_Data = {}
end

-- Event frame for updating data ----------------------------------------------------------------------
local ConsumeTracker_EventFrame = CreateFrame("Frame")
ConsumeTracker_EventFrame:RegisterEvent("PLAYER_LOGIN")
ConsumeTracker_EventFrame:RegisterEvent("BAG_UPDATE")
ConsumeTracker_EventFrame:RegisterEvent("BANKFRAME_OPENED")
ConsumeTracker_EventFrame:RegisterEvent("PLAYERBANKSLOTS_CHANGED")
ConsumeTracker_EventFrame:RegisterEvent("ITEM_LOCK_CHANGED")
ConsumeTracker_EventFrame:RegisterEvent("MAIL_SHOW")
ConsumeTracker_EventFrame:RegisterEvent("MAIL_INBOX_UPDATE")
ConsumeTracker_EventFrame:RegisterEvent("MAIL_CLOSED")

ConsumeTracker_EventFrame:SetScript("OnEvent", function()
    if event == "PLAYER_LOGIN" then
        ConsumeTracker_ScanPlayerInventory()
        ConsumeTracker_ScanPlayerBank()
        ConsumeTracker_ScanPlayerMail()
    elseif event == "BAG_UPDATE" then
        ConsumeTracker_ScanPlayerInventory()
        if BankFrame and BankFrame:IsShown() then
            ConsumeTracker_ScanPlayerBank()
        end
        if MailFrame and MailFrame:IsShown() then
            ConsumeTracker_ScanPlayerMail()
        end
    elseif event == "BANKFRAME_OPENED" then
        ConsumeTracker_ScanPlayerBank()
    elseif event == "PLAYERBANKSLOTS_CHANGED" then  
        ConsumeTracker_ScanPlayerBank()
        ConsumeTracker_ScanPlayerInventory()
    elseif event == "ITEM_LOCK_CHANGED" then
        if BankFrame and BankFrame:IsShown() then
            ConsumeTracker_ScanPlayerInventory()
            ConsumeTracker_ScanPlayerBank()
        end
        if MailFrame and MailFrame:IsShown() then
            ConsumeTracker_ScanPlayerInventory()
            ConsumeTracker_ScanPlayerMail()
        end
    elseif event == "MAIL_SHOW" or event == "MAIL_INBOX_UPDATE" then
        ConsumeTracker_ScanPlayerMail()
    end
end)



function ConsumeTracker_CreateMainWindow()
    -- Main Frame
    ConsumeTracker_MainFrame = CreateFrame("Frame", "ConsumeTracker_MainFrame", UIParent)
    ConsumeTracker_MainFrame:SetWidth(WindowWidth)
    ConsumeTracker_MainFrame:SetHeight(512)
    ConsumeTracker_MainFrame:SetPoint("CENTER", UIParent, "CENTER")
    ConsumeTracker_MainFrame:SetFrameStrata("DIALOG")
    ConsumeTracker_MainFrame:SetMovable(true)
    ConsumeTracker_MainFrame:EnableMouse(true)
    ConsumeTracker_MainFrame:RegisterForDrag("LeftButton")
    ConsumeTracker_MainFrame:SetScript("OnDragStart", function()
        this:StartMoving()
    end)
    ConsumeTracker_MainFrame:SetScript("OnDragStop", function()
        this:StopMovingOrSizing()
    end)

    -- Background Texture
    local background = ConsumeTracker_MainFrame:CreateTexture(nil, "BACKGROUND")
    background:SetTexture("Interface\\DialogFrame\\UI-DialogBox-Background")
    background:SetPoint("TOPLEFT", ConsumeTracker_MainFrame, "TOPLEFT", 12, -12)
    background:SetPoint("BOTTOMRIGHT", ConsumeTracker_MainFrame, "BOTTOMRIGHT", -12, 12)

    -- Border
    ConsumeTracker_MainFrame:SetBackdrop({
        bgFile = "Interface\\Tooltips\\UI-Tooltip-Background",
        edgeFile = "Interface\\DialogFrame\\UI-DialogBox-Border",
        tile = true, tileSize = 32, edgeSize = 32,
        insets = { left = 11, right = 12, top = 12, bottom = 11 }
    })
    ConsumeTracker_MainFrame:SetBackdropColor(0.1, 0.1, 0.1, 1)

    -- Title Frame
    local titleBg = ConsumeTracker_MainFrame:CreateTexture(nil, "ARTWORK")
    titleBg:SetTexture("Interface\\DialogFrame\\UI-DialogBox-Header")
    titleBg:SetWidth(266)
    titleBg:SetHeight(64)
    titleBg:SetPoint("TOP", ConsumeTracker_MainFrame, "TOP", 0, 12)

    -- Title Text
    local titleText = ConsumeTracker_MainFrame:CreateFontString(nil, "OVERLAY", "GameFontNormalLarge")
    titleText:SetText("Consumes Tracker")
    titleText:SetPoint("TOP", titleBg, "TOP", 0, -14)

    -- Close Button
    local closeButton = CreateFrame("Button", nil, ConsumeTracker_MainFrame, "UIPanelCloseButton")
    closeButton:SetWidth(32)
    closeButton:SetHeight(32)
    closeButton:SetPoint("TOPRIGHT", ConsumeTracker_MainFrame, "TOPRIGHT", -5, -5)
    closeButton:SetScript("OnClick", function()
        ConsumeTracker_MainFrame:Hide()
    end)

    -- Create a custom tooltip frame
    local tooltipFrame = CreateFrame("Frame", "ConsumeTrackerTooltip", UIParent)
    tooltipFrame:SetWidth(150)
    tooltipFrame:SetHeight(40)
    tooltipFrame:SetFrameStrata("TOOLTIP")
    tooltipFrame:SetBackdrop({
        bgFile = "Interface\\Tooltips\\UI-Tooltip-Background",
        edgeFile = "Interface\\Tooltips\\UI-Tooltip-Border",
        tile = true, tileSize = 16, edgeSize = 16,
        insets = { left = 4, right = 4, top = 4, bottom = 4 }
    })
    tooltipFrame:SetBackdropColor(0, 0, 0, 1)
    tooltipFrame:Hide()

    -- Tooltip text
    local tooltipText = tooltipFrame:CreateFontString(nil, "OVERLAY", "GameFontNormal")
    tooltipText:SetPoint("CENTER", tooltipFrame, "CENTER", 0, 0)
    tooltipFrame.text = tooltipText

    local function ShowTooltip(tab, text)
        tooltipFrame.text:SetText(text)
        tooltipFrame:SetPoint("BOTTOMLEFT", tab, "TOPLEFT", 0, 0)
        tooltipFrame:Show()
    end

    local function HideTooltip()
        tooltipFrame:Hide()
    end

    -- Tabs
    local tabs = {}
    local function CreateTab(name, texture, xOffset, tooltipText, tabIndex)
        local tab = CreateFrame("Button", name, ConsumeTracker_MainFrame)
        tab:SetWidth(36)
        tab:SetHeight(36)
        tab:SetPoint("TOPLEFT", ConsumeTracker_MainFrame, "TOPLEFT", xOffset, -30)

        -- Tab Icon
        local icon = tab:CreateTexture(nil, "ARTWORK")
        icon:SetTexture(texture)
        icon:SetWidth(36)
        icon:SetHeight(36)
        icon:SetPoint("CENTER", tab, "CENTER", 0, 0)

        tab.icon = icon

        -- Hover Glow
        local hoverTexture = tab:CreateTexture(nil, "HIGHLIGHT")
        hoverTexture:SetTexture("Interface\\Buttons\\CheckButtonHilight")
        hoverTexture:SetBlendMode("ADD")
        hoverTexture:SetAllPoints(tab)

        -- Active Highlight
        local activeHighlight = tab:CreateTexture(nil, "OVERLAY")
        activeHighlight:SetTexture("Interface\\Buttons\\CheckButtonHilight")
        activeHighlight:SetBlendMode("ADD")
        activeHighlight:SetAllPoints(tab)
        activeHighlight:SetWidth(36)
        activeHighlight:SetHeight(36)
        activeHighlight:Hide()
        tab.activeHighlight = activeHighlight

        -- Custom Tooltip Handlers
        tab:SetScript("OnEnter", function()
            ShowTooltip(tab, tooltipText)
        end)
        tab:SetScript("OnLeave", HideTooltip)

        -- Store tab for later
        tabs[tabIndex] = tab

        return tab
    end

    -- Tracker Tab
    local tab1 = CreateTab("ConsumeTracker_MainFrameTab1", "Interface\\Icons\\INV_Potion_93", 30, "Consumables Tracker", 1)
    tab1:SetScript("OnClick", function()
        ConsumeTracker_ShowTab(1)
    end)

    -- Options Tab
    local tab2 = CreateTab("ConsumeTracker_MainFrameTab2", "Interface\\Icons\\INV_Misc_Gear_01", 80, "Options", 2)
    tab2:SetScript("OnClick", function()
        ConsumeTracker_ShowTab(2)
    end)

    -- Characters Tab
    local tab3 = CreateTab("ConsumeTracker_MainFrameTab3", "Interface\\Icons\\Ability_Rogue_Disguise", 130, "Characters", 3)
    tab3:SetScript("OnClick", function()
        ConsumeTracker_ShowTab(3)
    end)

    -- Add Grey Line Under Tabs
    local tabsLine = ConsumeTracker_MainFrame:CreateTexture(nil, "ARTWORK")
    tabsLine:SetHeight(1)
    tabsLine:SetPoint("TOPLEFT", ConsumeTracker_MainFrame, "TOPLEFT", 12, -72)
    tabsLine:SetPoint("TOPRIGHT", ConsumeTracker_MainFrame, "TOPRIGHT", -12, -72)
    tabsLine:SetTexture("Interface\\Buttons\\WHITE8x8")
    tabsLine:SetVertexColor(0.4, 0.4, 0.4, 1)

    -- Tab Content
    ConsumeTracker_MainFrame.tabs = {}
    local tab1Content = CreateFrame("Frame", nil, ConsumeTracker_MainFrame)
    tab1Content:SetWidth(WindowWidth - 50)
    tab1Content:SetHeight(380)
    tab1Content:SetPoint("TOPLEFT", ConsumeTracker_MainFrame, "TOPLEFT", 30, -80)
    ConsumeTracker_MainFrame.tabs[1] = tab1Content

    local tab2Content = CreateFrame("Frame", nil, ConsumeTracker_MainFrame)
    tab2Content:SetWidth(WindowWidth - 50)
    tab2Content:SetHeight(380)
    tab2Content:SetPoint("TOPLEFT", ConsumeTracker_MainFrame, "TOPLEFT", 30, -80)
    ConsumeTracker_MainFrame.tabs[2] = tab2Content

    local tab3Content = CreateFrame("Frame", nil, ConsumeTracker_MainFrame)
    tab3Content:SetWidth(WindowWidth - 50)
    tab3Content:SetHeight(380)
    tab3Content:SetPoint("TOPLEFT", ConsumeTracker_MainFrame, "TOPLEFT", 30, -80)
    ConsumeTracker_MainFrame.tabs[3] = tab3Content

    -- Footer Text
    local footerText = ConsumeTracker_MainFrame:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
    footerText:SetText("Made by Horyoshi (v" .. Version .. "-" .. VState .. ")")
    footerText:SetTextColor(0.6, 0.6, 0.6)
    footerText:SetPoint("BOTTOM", ConsumeTracker_MainFrame, "BOTTOM", 0, 15)

    -- Add Grey Line Above Footer
    local footerLine = ConsumeTracker_MainFrame:CreateTexture(nil, "ARTWORK")
    footerLine:SetHeight(1)
    footerLine:SetPoint("BOTTOMLEFT", ConsumeTracker_MainFrame, "BOTTOMLEFT", 12, 30)
    footerLine:SetPoint("BOTTOMRIGHT", ConsumeTracker_MainFrame, "BOTTOMRIGHT", -12, 30)
    footerLine:SetTexture("Interface\\Buttons\\WHITE8x8")
    footerLine:SetVertexColor(0.4, 0.4, 0.4, 1)

    -- Tab Switching Function
    function ConsumeTracker_ShowTab(tabIndex)
        for index, content in pairs(ConsumeTracker_MainFrame.tabs) do
            if index == tabIndex then
                content:Show()
                tabs[index].activeHighlight:Show()
            else
                content:Hide()
                tabs[index].activeHighlight:Hide()
            end
        end
    end

    -- Set Default Tab
    ConsumeTracker_ShowTab(1)

    -- Add Custom Content for Tabs
    ConsumeTracker_CreateTrackerContent(tab1Content)
    ConsumeTracker_CreateOptionsContent(tab2Content)
    ConsumeTracker_CreateCharactersContent(tab3Content)
end



-- Function to show the main window
function ConsumeTracker_ShowMainWindow()
    if not ConsumeTracker_MainFrame then
        ConsumeTracker_CreateMainWindow()
    end
    ConsumeTracker_MainFrame:Show()
    -- Scan inventory when the window is opened
    ConsumeTracker_ScanPlayerInventory()
    -- Only scan bank and mail if they are open
    if BankFrame and BankFrame:IsShown() then
        ConsumeTracker_ScanPlayerBank()
    end
    if MailFrame and MailFrame:IsShown() then
        ConsumeTracker_ScanPlayerMail()
    end
    -- Update the tracker content
    ConsumeTracker_UpdateTrackerContent()
end

-- Function to switch tabs
function ConsumeTracker_ShowTab(tabIndex)
    if not ConsumeTracker_MainFrame or not ConsumeTracker_MainFrame.tabs then return end
    for i, tabContent in pairs(ConsumeTracker_MainFrame.tabs) do
        if i == tabIndex then
            tabContent:Show()
            -- Set the tab button to active
            local tabButton = getglobal("ConsumeTracker_MainFrameTab" .. i)
            tabButton:SetNormalTexture("Interface\\OptionsFrame\\UI-OptionsFrame-ActiveTab")
        else
            tabContent:Hide()
            -- Set the tab button to inactive
            local tabButton = getglobal("ConsumeTracker_MainFrameTab" .. i)
            tabButton:SetNormalTexture("Interface\\OptionsFrame\\UI-OptionsFrame-InActiveTab")
        end
    end
end

-- Function to create the content of the Tracker tab
function ConsumeTracker_CreateTrackerContent(parentFrame)
    -- Scroll Frame
    local scrollFrame = CreateFrame("ScrollFrame", "ConsumeTracker_ConsumablesScrollFrame", parentFrame)
    scrollFrame:SetPoint("TOPLEFT", parentFrame, "TOPLEFT", 0, 0)
    scrollFrame:SetPoint("BOTTOMRIGHT", parentFrame, "BOTTOMRIGHT", -20, 0)
    scrollFrame:EnableMouseWheel(true)

    -- Define the OnMouseWheelHandler method
    function scrollFrame:OnMouseWheelHandler(delta)
        local current = self:GetVerticalScroll()
        local maxScroll = self.range or 0
        local newScroll = math.max(0, math.min(current - (delta * 10), maxScroll))
        self:SetVerticalScroll(newScroll)
        parentFrame.scrollBar:SetValue(newScroll)
    end

    -- Set the OnMouseWheel script
    scrollFrame:SetScript("OnMouseWheel", function()
        local delta = arg1
        this:OnMouseWheelHandler(delta)
    end)

    -- Scroll Child Frame
    local scrollChild = CreateFrame("Frame", nil, scrollFrame)
    scrollChild:SetWidth(WindowWidth - 10)
    scrollChild:SetHeight(1)  -- Will adjust later
    scrollFrame:SetScrollChild(scrollChild)

    -- Initialize tables to store category and consumable labels
    parentFrame.categoryLabels = {}
    parentFrame.labels = {}

    -- Sort categories by name for consistent order
    local sortedCategories = {}
    for categoryName, _ in pairs(consumablesCategories) do
        table.insert(sortedCategories, categoryName)
    end
    table.sort(sortedCategories, function(a, b) return a < b end)

    local index = 0  -- Initialize index for positioning

    for _, categoryName in ipairs(sortedCategories) do
        local consumables = consumablesCategories[categoryName]

        -- Create category label
        local categoryLabel = scrollChild:CreateFontString(nil, "OVERLAY", "GameFontNormalLarge")
        categoryLabel:SetText(categoryName)
        categoryLabel:SetTextColor(1, 1, 1)
        categoryLabel:SetPoint("TOPLEFT", scrollChild, "TOPLEFT", 0, -index * 16)
        categoryLabel:Hide()  -- Initially hidden
        parentFrame.categoryLabels[categoryName] = categoryLabel
        index = index + 1  -- Reserve space for category label

        -- Sort consumables by name
        table.sort(consumables, function(a, b) return a.name < b.name end)

        for _, consumable in ipairs(consumables) do
            local itemID = consumable.id
            local itemName = consumable.name

            -- Create consumable label
            local label = scrollChild:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
            label:SetText(itemName)
            label:SetTextColor(1, 1, 1)  -- White color
            label:SetPoint("TOPLEFT", scrollChild, "TOPLEFT", 20, -index * 16)  -- Indent consumables
            label:Hide()  -- Initially hidden
            parentFrame.labels[itemID] = label

            -- Create a frame for tooltip
            local tooltipFrame = CreateFrame("Frame", nil, scrollChild)
            tooltipFrame:SetWidth(220)
            tooltipFrame:SetHeight(16)
            tooltipFrame:SetPoint("TOPLEFT", scrollChild, "TOPLEFT", 20, -index * 16)
            tooltipFrame:EnableMouse(true)
            tooltipFrame:SetScript("OnEnter", function()
                ConsumeTracker_ShowConsumableTooltip(itemID)
            end)
            tooltipFrame:SetScript("OnLeave", function()
                    if ConsumeTracker_CustomTooltip then
                        ConsumeTracker_CustomTooltip:Hide()
                    end
            end)

            -- Enable mouse wheel and pass events to the scroll frame
            tooltipFrame:EnableMouseWheel(true)
            tooltipFrame:SetScript("OnMouseWheel", function()
                local delta = arg1
                local scrollFrame = parentFrame.scrollFrame
                if scrollFrame and scrollFrame:IsVisible() then
                    scrollFrame:OnMouseWheelHandler(delta)
                end
            end)

            -- Associate tooltip frame with the label
            label.tooltipFrame = tooltipFrame

            index = index + 1  -- Increment index for next label
        end

        -- Add spacing after each category
        index = index + 1
    end

    -- Adjust the height of the scroll child
    scrollChild.contentHeight = index * 16
    scrollChild:SetHeight(scrollChild.contentHeight)

    -- Message Label
    local messageLabel = scrollChild:CreateFontString(nil, "OVERLAY", "GameFontNormal")
    messageLabel:SetText("|cffff0000No consumables selected|r\n\n|cffffffffClick on |roptions|cffffffff to get started|r")
    messageLabel:SetPoint("CENTER", ConsumeTracker_MainFrame, "CENTER", 0, 0)
    messageLabel:Hide()  -- Initially hidden
    parentFrame.messageLabel = messageLabel

    -- Scroll Bar
    local scrollBar = CreateFrame("Slider", "ConsumeTracker_TrackerScrollBar", parentFrame)
    scrollBar:SetPoint("TOPRIGHT", parentFrame, "TOPRIGHT", -2, -16)
    scrollBar:SetPoint("BOTTOMRIGHT", parentFrame, "BOTTOMRIGHT", -2, 16)
    scrollBar:SetWidth(16)
    scrollBar:SetOrientation('VERTICAL')
    scrollBar:SetThumbTexture("Interface\\Buttons\\UI-ScrollBar-Knob")
    scrollBar:SetBackdrop({
        bgFile = "Interface\\Buttons\\UI-SliderBar-Background",
        edgeFile = "Interface\\Buttons\\UI-SliderBar-Border",
        tile = true, tileSize = 8, edgeSize = 8,
        insets = { left = 3, right = 3, top = 3, bottom = 3 }
    })
    scrollBar:SetScript("OnValueChanged", function()
        local value = this:GetValue()
        parentFrame.scrollFrame:SetVerticalScroll(value)
    end)
    parentFrame.scrollBar = scrollBar
    parentFrame.scrollFrame = scrollFrame
    parentFrame.scrollChild = scrollChild

    -- Update the scrollbar
    ConsumeTracker_UpdateTrackerScrollBar()
end

-- Function to create the content of the Options tab
function ConsumeTracker_CreateOptionsContent(parentFrame)
    -- Scroll Frame
    local scrollFrame = CreateFrame("ScrollFrame", "ConsumeTracker_OptionsScrollFrame", parentFrame)
    scrollFrame:SetPoint("TOPLEFT", parentFrame, "TOPLEFT", 0, 0)
    scrollFrame:SetPoint("BOTTOMRIGHT", parentFrame, "BOTTOMRIGHT", -20, 0)
    scrollFrame:EnableMouseWheel(true)
    scrollFrame:SetScript("OnMouseWheel", function()
        local delta = arg1
        local current = this:GetVerticalScroll()
        local maxScroll = this.maxScroll or 0
        local newScroll = math.max(0, math.min(current - (delta * 20), maxScroll))
        this:SetVerticalScroll(newScroll)
        parentFrame.scrollBar:SetValue(newScroll)
    end)

    -- Scroll Child Frame
    local scrollChild = CreateFrame("Frame", nil, scrollFrame)
    scrollChild:SetWidth(WindowWidth-10)
    scrollChild:SetHeight(1)  -- Will adjust later
    scrollFrame:SetScrollChild(scrollChild)

    -- Sort categories alphabetically for consistent order
    local sortedCategories = {}
    for categoryName, _ in pairs(consumablesCategories) do
        table.insert(sortedCategories, categoryName)
    end
    table.sort(sortedCategories, function(a, b) return a < b end)

    -- Checkboxes
    parentFrame.checkboxes = {}
    local index = 0 -- Position index

    -- Iterate over sorted categories in tracker order
    for _, categoryName in ipairs(sortedCategories) do
        local consumables = consumablesCategories[categoryName]

        -- Create category label
        index = index + 1
        local categoryLabel = scrollChild:CreateFontString(nil, "OVERLAY", "GameFontNormalLarge")
        categoryLabel:SetPoint("TOPLEFT", scrollChild, "TOPLEFT", 0, - (index - 1) * 18)
        categoryLabel:SetText(categoryName)
        categoryLabel:SetTextColor(1, 1, 1)

        -- Sort the consumables by name
        table.sort(consumables, function(a, b) return a.name < b.name end)

        -- For each consumable in the category
        for _, consumable in ipairs(consumables) do
            index = index + 1

            local currentItemID = consumable.id
            local itemName = consumable.name

            -- Create a frame that encompasses the checkbox and label
            local optionFrame = CreateFrame("Frame", "ConsumeTracker_OptionsFrame" .. index, scrollChild)
            optionFrame:SetWidth(WindowWidth-10)
            optionFrame:SetHeight(18)
            optionFrame:SetPoint("TOPLEFT", scrollChild, "TOPLEFT", 0, - (index - 1) * 18)

            -- Create the checkbox inside the optionFrame
            local checkbox = CreateFrame("CheckButton", "ConsumeTracker_OptionsCheckbox" .. index, optionFrame)
            checkbox:SetWidth(16)
            checkbox:SetHeight(16)
            checkbox:SetPoint("LEFT", optionFrame, "LEFT", 0, 0)

            -- Create Textures for the checkbox
            checkbox:SetNormalTexture("Interface\\Buttons\\UI-CheckBox-Up")
            checkbox:SetPushedTexture("Interface\\Buttons\\UI-CheckBox-Down")
            checkbox:SetHighlightTexture("Interface\\Buttons\\UI-CheckBox-Highlight")
            checkbox:SetCheckedTexture("Interface\\Buttons\\UI-CheckBox-Check")

            -- Create FontString for label
            local label = optionFrame:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
            label:SetPoint("LEFT", checkbox, "RIGHT", 4, 0)
            label:SetText(itemName)

            -- Set up the checkbox OnClick handler
            checkbox:SetScript("OnClick", function()
                ConsumeTracker_Settings[currentItemID] = checkbox:GetChecked()
                ConsumeTracker_UpdateTrackerContent()
            end)
            -- Load saved setting
            if ConsumeTracker_Settings[currentItemID] then
                checkbox:SetChecked(true)
            end
            parentFrame.checkboxes[currentItemID] = checkbox

            -- Make the optionFrame clickable (so clicking on the label checks/unchecks the box)
            optionFrame:EnableMouse(true)
            optionFrame:SetScript("OnMouseDown", function()
                checkbox:Click()
            end)

            -- Mouseover Tooltip
            optionFrame:SetScript("OnEnter", function()
                ConsumeTracker_ShowOptionsTooltip(currentItemID)
            end)
            optionFrame:SetScript("OnLeave", function()
                if ConsumeTracker_OptionsTooltip then
                    ConsumeTracker_OptionsTooltip:Hide()
                end
            end)
        end

        -- Add some spacing after each category
        index = index + 1
    end

    -- Adjust the scroll child height
    scrollChild.contentHeight = index * 18
    scrollChild:SetHeight(scrollChild.contentHeight)

    -- Scroll Bar
    local scrollBar = CreateFrame("Slider", "ConsumeTracker_OptionsScrollBar", parentFrame)
    scrollBar:SetPoint("TOPRIGHT", parentFrame, "TOPRIGHT", -2, -16)
    scrollBar:SetPoint("BOTTOMRIGHT", parentFrame, "BOTTOMRIGHT", -2, 16)
    scrollBar:SetWidth(16)
    scrollBar:SetOrientation('VERTICAL')
    scrollBar:SetThumbTexture("Interface\\Buttons\\UI-ScrollBar-Knob")
    scrollBar:SetBackdrop({
        bgFile = "Interface\\Buttons\\UI-SliderBar-Background",
        edgeFile = "Interface\\Buttons\\UI-SliderBar-Border",
        tile = true, tileSize = 8, edgeSize = 8,
        insets = { left = 3, right = 3, top = 3, bottom = 3 }
    })
    scrollBar:SetScript("OnValueChanged", function()
        local value = this:GetValue()
        parentFrame.scrollFrame:SetVerticalScroll(value)
    end)
    parentFrame.scrollBar = scrollBar
    parentFrame.scrollFrame = scrollFrame
    parentFrame.scrollChild = scrollChild

    -- Update the scrollbar
    ConsumeTracker_UpdateOptionsScrollBar()
end

function ConsumeTracker_CreateCharactersContent(parentFrame)
    -- Scroll Frame
    local scrollFrame = CreateFrame("ScrollFrame", "ConsumeTracker_CharactersScrollFrame", parentFrame)
    scrollFrame:SetPoint("TOPLEFT", parentFrame, "TOPLEFT", 0, 0)
    scrollFrame:SetPoint("BOTTOMRIGHT", parentFrame, "BOTTOMRIGHT", -20, 0)
    scrollFrame:EnableMouseWheel(true)
    scrollFrame:SetScript("OnMouseWheel", function()
        local delta = arg1
        local current = scrollFrame:GetVerticalScroll()
        local maxScroll = scrollFrame.maxScroll or 0
        local newScroll = math.max(0, math.min(current - (delta * 20), maxScroll))
        scrollFrame:SetVerticalScroll(newScroll)
        if parentFrame.scrollBar then
            parentFrame.scrollBar:SetValue(newScroll)
        end
    end)

    -- Scroll Child Frame
    local scrollChild = CreateFrame("Frame", nil, scrollFrame)
    scrollChild:SetWidth(WindowWidth - 10)
    scrollChild:SetHeight(1)
    scrollFrame:SetScrollChild(scrollChild)

    -- Initialize variables
    parentFrame.checkboxes = {}
    local index = 0 -- Position index

    -- Ensure settings table for characters exists
    ConsumeTracker_Settings["Characters"] = ConsumeTracker_Settings["Characters"] or {}

    -- Get list of characters
    local realmName = GetRealmName()
    local faction = UnitFactionGroup("player")
    local playerName = UnitName("player")

    local characterList = {}

    -- Ensure data structure exists
    if ConsumeTracker_Data[realmName] and ConsumeTracker_Data[realmName][faction] then
        for characterName, _ in pairs(ConsumeTracker_Data[realmName][faction]) do
            table.insert(characterList, characterName)
        end
    end

    -- Ensure current character is included
    local playerInList = false
    for _, name in ipairs(characterList) do
        if name == playerName then
            playerInList = true
            break
        end
    end
    if not playerInList then
        table.insert(characterList, playerName)
    end

    -- Sort the character list
    table.sort(characterList)

    -- Create FontString for title
    local title = scrollChild:CreateFontString(nil, "OVERLAY", "GameFontNormal")
    title:SetPoint("TOPLEFT", scrollChild, "TOPLEFT", 0, 0) -- Offset from the top
    title:SetText("Select Characters to Track")
    title:SetTextColor(1, 1, 1)

    -- Offset index to start below the title
    local startYOffset = 20

    -- For each character
    for _, characterName in ipairs(characterList) do
        index = index + 1

        -- Create a local copy of characterName for the closure
        local currentCharacterName = characterName

        -- Create a frame that encompasses the checkbox and label
        local optionFrame = CreateFrame("Frame", "ConsumeTracker_CharacterFrame" .. index, scrollChild)
        optionFrame:SetWidth(WindowWidth - 10)
        optionFrame:SetHeight(18)
        optionFrame:SetPoint("TOPLEFT", scrollChild, "TOPLEFT", 0, -(startYOffset + (index - 1) * 20))

        -- Create the checkbox inside the optionFrame
        local checkbox = CreateFrame("CheckButton", "ConsumeTracker_CharacterCheckbox" .. index, optionFrame)
        checkbox:SetWidth(16)
        checkbox:SetHeight(16)
        checkbox:SetPoint("LEFT", optionFrame, "LEFT", 0, 0)

        -- Create Textures for the checkbox
        checkbox:SetNormalTexture("Interface\\Buttons\\UI-CheckBox-Up")
        checkbox:SetPushedTexture("Interface\\Buttons\\UI-CheckBox-Down")
        checkbox:SetHighlightTexture("Interface\\Buttons\\UI-CheckBox-Highlight")
        checkbox:SetCheckedTexture("Interface\\Buttons\\UI-CheckBox-Check")

        -- Create FontString for label
        local label = optionFrame:CreateFontString(nil, "OVERLAY", "GameFontNormal")
        label:SetPoint("LEFT", checkbox, "RIGHT", 4, 0)
        label:SetText(currentCharacterName)

        -- Set up the checkbox OnClick handler
        checkbox:SetScript("OnClick", function()
            if checkbox:GetChecked() then
                ConsumeTracker_Settings["Characters"][currentCharacterName] = true
            else
                ConsumeTracker_Settings["Characters"][currentCharacterName] = false
            end
            ConsumeTracker_UpdateTrackerContent()
        end)
        -- Load saved setting
        if ConsumeTracker_Settings["Characters"][currentCharacterName] == nil then
            -- Default to checked
            checkbox:SetChecked(true)
            ConsumeTracker_Settings["Characters"][currentCharacterName] = true
        else
            checkbox:SetChecked(ConsumeTracker_Settings["Characters"][currentCharacterName])
        end
        parentFrame.checkboxes[currentCharacterName] = checkbox

        -- Make the optionFrame clickable (so clicking on the label checks/unchecks the box)
        optionFrame:EnableMouse(true)
        optionFrame:SetScript("OnMouseDown", function()
            checkbox:Click()
        end)
    end

    -- Adjust the scroll child height
    scrollChild.contentHeight = startYOffset + index * 20
    scrollChild:SetHeight(scrollChild.contentHeight)

    -- Scroll Bar
    local scrollBar = CreateFrame("Slider", "ConsumeTracker_CharactersScrollBar", parentFrame)
    scrollBar:SetPoint("TOPRIGHT", parentFrame, "TOPRIGHT", -2, -16)
    scrollBar:SetPoint("BOTTOMRIGHT", parentFrame, "BOTTOMRIGHT", -2, 16)
    scrollBar:SetWidth(16)
    scrollBar:SetOrientation('VERTICAL')
    scrollBar:SetThumbTexture("Interface\\Buttons\\UI-ScrollBar-Knob")
    scrollBar:SetBackdrop({
        bgFile = "Interface\\Buttons\\UI-SliderBar-Background",
        edgeFile = "Interface\\Buttons\\UI-SliderBar-Border",
        tile = true, tileSize = 8, edgeSize = 8,
        insets = { left = 3, right = 3, top = 3, bottom = 3 }
    })
    scrollBar:SetScript("OnValueChanged", function()
        local value = scrollBar:GetValue()
        scrollFrame:SetVerticalScroll(value)
    end)
    parentFrame.scrollBar = scrollBar
    parentFrame.scrollFrame = scrollFrame
    parentFrame.scrollChild = scrollChild

    -- Update the scrollbar
    ConsumeTracker_UpdateCharactersScrollBar()
end


function ConsumeTracker_UpdateTrackerContent()
    if not ConsumeTracker_MainFrame or not ConsumeTracker_MainFrame.tabs or not ConsumeTracker_MainFrame.tabs[1] then
        return
    end

    local trackerFrame = ConsumeTracker_MainFrame.tabs[1]
    local realmName = GetRealmName()
    local faction = UnitFactionGroup("player")
    local playerName = UnitName("player")

    -- Ensure data structure exists
    if not ConsumeTracker_Data[realmName] or not ConsumeTracker_Data[realmName][faction] then
        return
    end
    local data = ConsumeTracker_Data[realmName][faction]

    -- Check if bank and mail have been scanned for current character
    local currentCharData = data[playerName]
    local bankScanned = currentCharData and currentCharData["bank"] ~= nil
    local mailScanned = currentCharData and currentCharData["mail"] ~= nil

    -- If bank and mail have not been scanned, show message and hide item labels
    if not bankScanned or not mailScanned then
        -- Hide all labels
        for _, label in pairs(trackerFrame.labels) do
            label:Hide()
            if label.tooltipFrame then
                label.tooltipFrame:Hide()
            end
        end
        -- Hide category labels
        for _, categoryLabel in pairs(trackerFrame.categoryLabels) do
            categoryLabel:Hide()
        end

        -- Show message
        trackerFrame.messageLabel:SetText("|cffff0000This character is not scanned yet|r\n\n|cffffffffOpen your |rBank|cffffffff and |rMail |cffffffffto get started|r")
        trackerFrame.messageLabel:Show()

        -- Adjust scroll child height
        trackerFrame.scrollChild:SetHeight(50)

        -- Update the tracker scrollbar
        ConsumeTracker_UpdateTrackerScrollBar()

        return
    end

    -- Proceed with normal content update
    local index = 0  -- Positioning index for items
    local totalCounts = {}  -- Track total counts for each item
    local hasAnyVisibleItems = false  -- Track if any items are visible

    -- Sort categories alphabetically for consistent order
    local sortedCategories = {}
    for categoryName, _ in pairs(consumablesCategories) do
        table.insert(sortedCategories, categoryName)
    end
    table.sort(sortedCategories)

    -- Hide all labels initially to ensure proper cleanup
    for _, label in pairs(trackerFrame.labels) do
        label:Hide()
        if label.tooltipFrame then
            label.tooltipFrame:Hide()
        end
    end

    -- Hide all category labels initially
    for _, categoryLabel in pairs(trackerFrame.categoryLabels) do
        categoryLabel:Hide()
    end

    -- Ensure character settings exist
    ConsumeTracker_Settings["Characters"] = ConsumeTracker_Settings["Characters"] or {}

    -- Iterate over categories
    for _, categoryName in ipairs(sortedCategories) do
        local consumables = consumablesCategories[categoryName]
        local hasVisibleItems = false
        local categoryLabel = trackerFrame.categoryLabels[categoryName]

        -- Ensure the category label exists
        if not categoryLabel then
            -- Create category label dynamically if missing
            categoryLabel = trackerFrame.scrollChild:CreateFontString(nil, "OVERLAY", "GameFontNormalLarge")
            categoryLabel:SetText(categoryName)
            categoryLabel:SetTextColor(1, 1, 1)
            trackerFrame.categoryLabels[categoryName] = categoryLabel
        end

        -- Position category label (always above items)
        categoryLabel:SetPoint("TOPLEFT", trackerFrame.scrollChild, "TOPLEFT", 0, -index * 16)
        categoryLabel:Hide() -- Initially hidden

        index = index + 1  -- Reserve space for the category label

        -- Calculate totals and show items if enabled
        for _, consumable in ipairs(consumables) do
            local itemID = consumable.id
            if ConsumeTracker_Settings[itemID] then
                hasVisibleItems = true
                hasAnyVisibleItems = true  -- Set to true when an item is displayed
                totalCounts[itemID] = 0  -- Initialize count

                -- Sum counts across all selected characters
                for character, charData in pairs(data) do
                    if ConsumeTracker_Settings["Characters"][character] == true then
                        -- Proceed with counting
                        local inventory = charData["inventory"] and charData["inventory"][itemID] or 0
                        local bank = charData["bank"] and charData["bank"][itemID] or 0
                        local mail = charData["mail"] and charData["mail"][itemID] or 0
                        totalCounts[itemID] = totalCounts[itemID] + inventory + bank + mail
                    end
                end

                -- Show and position item label
                local label = trackerFrame.labels[itemID]
                if not label then
                    -- Create the label dynamically if missing
                    label = trackerFrame.scrollChild:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
                    trackerFrame.labels[itemID] = label
                    -- Tooltip frame
                    local tooltipFrame = CreateFrame("Frame", nil, trackerFrame.scrollChild)
                    tooltipFrame:SetWidth(WindowWidth - 30)
                    tooltipFrame:SetHeight(16)
                    tooltipFrame:EnableMouse(true)
                    tooltipFrame:SetScript("OnEnter", function() ConsumeTracker_ShowConsumableTooltip(itemID) end)
                    tooltipFrame:SetScript("OnLeave", function()
                        if ConsumeTracker_CustomTooltip then
                            ConsumeTracker_CustomTooltip:Hide()
                        end
                    end)
                    label.tooltipFrame = tooltipFrame
                end

                local totalCount = totalCounts[itemID]
                label:SetText(consumable.name .. " (" .. totalCount .. ")")
                label:SetPoint("TOPLEFT", trackerFrame.scrollChild, "TOPLEFT", 20, -index * 16)
                label:Show()

                -- Adjust label color based on count
                if totalCount == 0 then
                    label:SetTextColor(1, 0, 0)  -- Red
                elseif totalCount < 10 then
                    label:SetTextColor(1, 0.4, 0)  -- Orange
                elseif totalCount <= 20 then
                    label:SetTextColor(1, 0.85, 0)  -- Yellow
                else
                    label:SetTextColor(0, 1, 0)  -- Green
                end

                -- Show tooltip frame
                if label.tooltipFrame then
                    label.tooltipFrame:SetPoint("TOPLEFT", trackerFrame.scrollChild, "TOPLEFT", 20, -index * 16)
                    label.tooltipFrame:SetWidth(label:GetStringWidth())
                    label.tooltipFrame:SetHeight(16)
                    label.tooltipFrame:Show()
                end

                index = index + 1
            end
        end

        -- Show the category label if it has visible items
        if hasVisibleItems then
            categoryLabel:Show()
        else
            index = index - 1  -- Remove extra space if no items
        end
    end

    -- Adjust scroll child height based on the total number of items
    local contentHeight = index * 16
    if contentHeight < 50 then
        contentHeight = 50  -- Minimum height to display the message label
    end
    trackerFrame.scrollChild:SetHeight(contentHeight)

    if not hasAnyVisibleItems then
        -- Show message when no items are selected
        trackerFrame.messageLabel:SetText("|cffff0000No consumables selected|r\n\n|cffffffffClick on |roptions|cffffffff to get started|r")
        trackerFrame.messageLabel:Show()
    else
        -- Hide the message label as we have content to display
        trackerFrame.messageLabel:Hide()
    end

    -- Update the tracker scrollbar
    ConsumeTracker_UpdateTrackerScrollBar()
end



function ConsumeTracker_UpdateTrackerScrollBar()
    local trackerFrame = ConsumeTracker_MainFrame.tabs[1]
    local scrollBar = trackerFrame.scrollBar
    local scrollFrame = trackerFrame.scrollFrame
    local scrollChild = trackerFrame.scrollChild

    local totalHeight = scrollChild:GetHeight()
    local shownHeight = trackerFrame:GetHeight() - 20  -- Account for padding/margins

    if totalHeight > shownHeight then
        local maxScroll = totalHeight - shownHeight
        scrollFrame.range = maxScroll  -- Set the scroll range
        scrollBar:SetMinMaxValues(0, maxScroll)
        scrollBar:SetValue(math.min(scrollBar:GetValue(), maxScroll))
        scrollBar:Show()
    else
        scrollFrame.range = 0  -- Also handle this case
        scrollBar:SetMinMaxValues(0, 0)
        scrollBar:SetValue(0)
        scrollBar:Hide()
    end
end



function ConsumeTracker_UpdateOptionsScrollBar()
    local optionsFrame = ConsumeTracker_MainFrame.tabs[2]
    local scrollBar = optionsFrame.scrollBar
    local scrollFrame = optionsFrame.scrollFrame
    local scrollChild = optionsFrame.scrollChild

    local totalHeight = scrollChild.contentHeight
    local shownHeight = 320  -- Adjust based on your UI

    local maxScroll = math.max(0, totalHeight - shownHeight)
    scrollFrame.maxScroll = maxScroll

    if totalHeight > shownHeight then
        scrollBar:SetMinMaxValues(0, maxScroll)
        scrollBar:SetValue(math.min(scrollBar:GetValue(), maxScroll))
        scrollBar:Show()
    else
        scrollBar:SetMinMaxValues(0, 0)
        scrollBar:SetValue(0)
        scrollBar:Hide()
    end
end


function ConsumeTracker_UpdateCharactersScrollBar()
    local charactersFrame = ConsumeTracker_MainFrame.tabs[3]
    local scrollBar = charactersFrame.scrollBar
    local scrollFrame = charactersFrame.scrollFrame
    local scrollChild = charactersFrame.scrollChild

    local totalHeight = scrollChild.contentHeight
    local shownHeight = 320  -- Adjust based on your UI

    local maxScroll = math.max(0, totalHeight - shownHeight)
    scrollFrame.maxScroll = maxScroll

    if totalHeight > shownHeight then
        scrollBar:SetMinMaxValues(0, maxScroll)
        scrollBar:SetValue(math.min(scrollBar:GetValue(), maxScroll))
        scrollBar:Show()
    else
        scrollBar:SetMinMaxValues(0, 0)
        scrollBar:SetValue(0)
        scrollBar:Hide()
    end
end


function ConsumeTracker_ShowConsumableTooltip(itemID)
    -- Ensure item is enabled in settings
    if not ConsumeTracker_Settings[itemID] then
        return
    end

    -- Create or reuse custom tooltip frame
    if not ConsumeTracker_CustomTooltip then
        -- Create the frame
        local tooltipFrame = CreateFrame("Frame", "ConsumeTracker_CustomTooltip", UIParent)
        tooltipFrame:SetFrameStrata("TOOLTIP")
        tooltipFrame:SetWidth(200)
        tooltipFrame:SetBackdrop({
            bgFile = "Interface\\Tooltips\\UI-Tooltip-Background",
            edgeFile = "Interface\\Tooltips\\UI-Tooltip-Border",
            tile = true, tileSize = 16, edgeSize = 16,
            insets = { left = 4, right = 4, top = 4, bottom = 4 }
        })
        tooltipFrame:SetBackdropColor(0, 0, 0, 1)

        -- Item icon
        local icon = tooltipFrame:CreateTexture(nil, "ARTWORK")
        icon:SetWidth(32)
        icon:SetHeight(32)
        icon:SetPoint("TOPLEFT", tooltipFrame, "TOPLEFT", 10, -10)
        tooltipFrame.icon = icon

        -- Item name
        local title = tooltipFrame:CreateFontString(nil, "OVERLAY", "GameFontNormal")
        title:SetPoint("TOPLEFT", icon, "TOPRIGHT", 10, -2)
        title:SetPoint("RIGHT", tooltipFrame, "RIGHT", -10, 0)
        title:SetJustifyH("LEFT")
        title:SetTextColor(1,1,1)
        tooltipFrame.title = title

        -- Item Total
        local total = tooltipFrame:CreateFontString(nil, "OVERLAY", "GameFontNormalLarge")
        total:SetPoint("TOPLEFT", icon, "TOPRIGHT", 10, -20)
        total:SetPoint("RIGHT", tooltipFrame, "RIGHT", -10, 0)
        total:SetJustifyH("LEFT")
        tooltipFrame.total = total

        -- Content text
        local content = tooltipFrame:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
        content:SetPoint("TOPLEFT", icon, "BOTTOMLEFT", 0, -10)
        content:SetPoint("RIGHT", tooltipFrame, "RIGHT", -10, 0)
        content:SetJustifyH("LEFT")
        tooltipFrame.content = content

        ConsumeTracker_CustomTooltip = tooltipFrame
    end

    local tooltipFrame = ConsumeTracker_CustomTooltip

    -- Get item info
    local itemName = consumablesList[itemID] or "Unknown Item"
    local itemTexture = consumablesTexture[itemID] or "Interface\\Icons\\INV_Misc_QuestionMark"
    
    -- Set icon and title
    tooltipFrame.icon:SetTexture(itemTexture)
    tooltipFrame.title:SetText(itemName)

    -- Prepare content text
    local contentText = ""

    local realmName = GetRealmName()
    local faction = UnitFactionGroup("player")
    local playerName = UnitName("player")

    -- Ensure data structure exists
    ConsumeTracker_Data[realmName] = ConsumeTracker_Data[realmName] or {}
    ConsumeTracker_Data[realmName][faction] = ConsumeTracker_Data[realmName][faction] or {}

    local data = ConsumeTracker_Data[realmName][faction]

    -- Initialize totals
    local totalInventory, totalBank, totalMail = 0, 0, 0
    local hasItems = false
    local characterList = {}

    -- Ensure character settings exist
    ConsumeTracker_Settings["Characters"] = ConsumeTracker_Settings["Characters"] or {}

    -- Collect data for each character
    for character, charData in pairs(data) do
        if ConsumeTracker_Settings["Characters"][character] == true then
            local inventory = charData["inventory"] and charData["inventory"][itemID] or 0
            local bank = charData["bank"] and charData["bank"][itemID] or 0
            local mail = charData["mail"] and charData["mail"][itemID] or 0
            local total = inventory + bank + mail

            if total > 0 then
                hasItems = true
                totalInventory = totalInventory + inventory
                totalBank = totalBank + bank
                totalMail = totalMail + mail

                table.insert(characterList, {
                    name = character,
                    inventory = inventory,
                    bank = bank,
                    mail = mail,
                    total = total,
                    isPlayer = (character == playerName)
                })
            end
        end
    end

    local totalItems = totalInventory + totalBank + totalMail
    -- Adjust label color based on count
    if totalItems == 0 then
        tooltipFrame.total:SetTextColor(1, 0, 0)  -- Red
    elseif totalItems < 10 then
        tooltipFrame.total:SetTextColor(1, 0.4, 0)  -- Orange
    elseif totalItems <= 20 then
        tooltipFrame.total:SetTextColor(1, 0.85, 0)  -- Yellow
    else
        tooltipFrame.total:SetTextColor(0, 1, 0)  -- Green
    end

    tooltipFrame.total:SetText("Total: " .. totalItems)

    if not hasItems then
        contentText = contentText .. "|cffff0000No items found for this consumable.|r"
    else

        -- Sort characters alphabetically (optional)
        table.sort(characterList, function(a, b) return a.name < b.name end)

        -- Display data for each character
        for _, charInfo in ipairs(characterList) do

            local nameColor = charInfo.isPlayer and "|cff00ff00" or "|cffffffff"  -- Green for player, grey for others
            contentText = contentText .. nameColor .. charInfo.name .. " (" .. charInfo.total .. ")|r\n"

            local detailText = ""
            if charInfo.inventory > 0 then
                detailText = detailText .. "|cffffffffInventory:|r " .. charInfo.inventory .. "  "
            end
            if charInfo.bank > 0 then
                detailText = detailText .. "|cffffffffBank:|r " .. charInfo.bank .. "  "
            end
            if charInfo.mail > 0 then
                detailText = detailText .. "|cffffffffMail:|r " .. charInfo.mail .. "  "
            end

            contentText = contentText .. "  " .. detailText .. "\n\n"
        end
    end

    tooltipFrame.content:SetText(contentText)

    -- Calculate the number of lines in contentText using string.gsub
    local _, numLines = string.gsub(contentText, "\n", "")
    numLines = numLines + 2  -- Add lines for title and padding

    -- Adjust tooltip height based on the number of lines
    local lineHeight = 10
    local totalHeight = 50 + (numLines * lineHeight)
    tooltipFrame:SetHeight(totalHeight)

    -- Set the width based on content
    local maxWidth = math.max(tooltipFrame.title:GetStringWidth() + 70, tooltipFrame.content:GetStringWidth() +20)
    tooltipFrame:SetWidth(maxWidth)

    -- Position the tooltip near the cursor
    local x, y = GetCursorPosition()
    local scale = UIParent:GetEffectiveScale()
    tooltipFrame:SetPoint("BOTTOMLEFT", UIParent, "BOTTOMLEFT", x / scale + 10, y / scale - 10)

    tooltipFrame:Show()
end


function ConsumeTracker_ShowOptionsTooltip(itemID)
    -- Set the maximum width for the description text
    local maxDescriptionWidth = 160

    -- Create or reuse the tooltip frame
    if not ConsumeTracker_OptionsTooltip then
        -- Create the frame
        local tooltipFrame = CreateFrame("Frame", "ConsumeTracker_OptionsTooltip", UIParent)
        tooltipFrame:SetFrameStrata("TOOLTIP")
        tooltipFrame:SetBackdrop({
            bgFile = "Interface\\Tooltips\\UI-Tooltip-Background",
            edgeFile = "Interface\\Tooltips\\UI-Tooltip-Border",
            tile = true, tileSize = 16, edgeSize = 16,
            insets = { left = 4, right = 4, top = 4, bottom = 4 }
        })
        tooltipFrame:SetBackdropColor(0, 0, 0, 1)

        -- Item icon
        local icon = tooltipFrame:CreateTexture(nil, "ARTWORK")
        icon:SetWidth(32)
        icon:SetHeight(32)
        icon:SetPoint("TOPLEFT", tooltipFrame, "TOPLEFT", 10, -10)
        tooltipFrame.icon = icon

        -- Item name
        local title = tooltipFrame:CreateFontString(nil, "OVERLAY", "GameFontNormal")
        title:SetPoint("TOPLEFT", icon, "TOPRIGHT", 10, -2)
        title:SetJustifyH("LEFT")
        tooltipFrame.title = title

        -- Item description
        local description = tooltipFrame:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
        description:SetPoint("TOPLEFT", icon, "TOPRIGHT", 10, -16)
        description:SetWidth(maxDescriptionWidth)
        description:SetJustifyH("LEFT")
        description:SetTextColor(1, 1, 1)
        tooltipFrame.description = description

        ConsumeTracker_OptionsTooltip = tooltipFrame
    end

    local tooltipFrame = ConsumeTracker_OptionsTooltip

    -- Get item info
    local itemName = consumablesList[itemID] or "Unknown Item"
    local itemTexture = consumablesTexture[itemID] or "Interface\\Icons\\INV_Misc_QuestionMark"
    local itemDescription = consumablesDescription[itemID] or ""

    -- Function to add line breaks manually
    local function WrapText(text, maxWidth, fontObject)
        local wrappedText = ""
        local currentLine = ""
        local space = " "
        local testString = tooltipFrame:CreateFontString(nil, "OVERLAY", fontObject)
        testString:SetWidth(0)
        testString:SetHeight(0)
        testString:Hide() -- We don't need to display this

        -- Replace \n with spaces to avoid unintended line breaks
        text = string.gsub(text, "\n", " ")

        -- Split the text into words
        for word in string.gfind(text, "%S+") do
            local testLine = currentLine == "" and word or (currentLine .. space .. word)
            testString:SetText(testLine)
            if testString:GetStringWidth() > maxWidth then
                wrappedText = wrappedText == "" and currentLine or (wrappedText .. "\n" .. currentLine)
                currentLine = word
            else
                currentLine = testLine
            end
        end
        wrappedText = wrappedText == "" and currentLine or (wrappedText .. "\n" .. currentLine)
        return wrappedText
    end

    -- Wrap the description text
    local wrappedDescription = WrapText(itemDescription, maxDescriptionWidth, "GameFontNormalSmall")

    -- Set icon, title, and description
    tooltipFrame.icon:SetTexture(itemTexture)
    tooltipFrame.title:SetText(itemName)
    tooltipFrame.description:SetText(wrappedDescription)

    -- Calculate the number of lines in the wrapped description
    local _, lineCount = string.gsub(wrappedDescription, "\n", "")
    lineCount = lineCount + 1 -- Add 1 for the last line

    -- Set the heights for the description and the tooltip frame
    local lineHeight = 12
    tooltipFrame.description:SetHeight(lineCount * lineHeight)

    local totalHeight = 50 + (lineCount * lineHeight)
    tooltipFrame:SetHeight(totalHeight)

    -- Set the width of the tooltip
    local maxWidth = math.max(tooltipFrame.title:GetStringWidth() + 70, tooltipFrame.description:GetStringWidth() + 70)
    tooltipFrame:SetWidth(maxWidth)

    -- Position the tooltip near the cursor
    local x, y = GetCursorPosition()
    local scale = UIParent:GetEffectiveScale()
    tooltipFrame:SetPoint("BOTTOMLEFT", UIParent, "BOTTOMLEFT", x / scale + 10, y / scale - 10)

    tooltipFrame:Show()
end





-- Function to scan player's inventory
function ConsumeTracker_ScanPlayerInventory()
    local playerName = UnitName("player")
    local realmName = GetRealmName()
    local faction = UnitFactionGroup("player")

    ConsumeTracker_Data[realmName] = ConsumeTracker_Data[realmName] or {}
    ConsumeTracker_Data[realmName][faction] = ConsumeTracker_Data[realmName][faction] or {}
    ConsumeTracker_Data[realmName][faction][playerName] = ConsumeTracker_Data[realmName][faction][playerName] or {}
    local data = ConsumeTracker_Data[realmName][faction][playerName]
    data["inventory"] = {}

    for bag = 0, 4 do
        local numSlots = GetContainerNumSlots(bag)
        if numSlots then
            for slot = 1, numSlots do
                local link = GetContainerItemLink(bag, slot)
                if link then
                    local _, _, itemID = string.find(link, "item:(%d+)")
                    if itemID then
                        itemID = tonumber(itemID)
                        if ConsumeTracker_Settings[itemID] then
                            local texture, itemCount = GetContainerItemInfo(bag, slot)
                            data["inventory"][itemID] = (data["inventory"][itemID] or 0) + itemCount
                        end
                    end
                end
            end
        end
    end

    ConsumeTracker_UpdateTrackerContent()
end

-- Function to scan player's bank
function ConsumeTracker_ScanPlayerBank()

     if not BankFrame or not BankFrame:IsShown() then
        return
    end

    local playerName = UnitName("player")
    local realmName = GetRealmName()
    local faction = UnitFactionGroup("player")

    local data = ConsumeTracker_Data[realmName][faction][playerName]
    data["bank"] = {}

    -- Bank bags are -1 and 5 to 10 in WoW 1.12
    for bag = -1, 10 do
        if bag == -1 or (bag >= 5 and bag <= 10) then
            local numSlots = GetContainerNumSlots(bag)
            if numSlots then
                for slot = 1, numSlots do
                    local link = GetContainerItemLink(bag, slot)
                    if link then
                        local _, _, itemID = string.find(link, "item:(%d+)")
                        if itemID then
                            itemID = tonumber(itemID)
                            if ConsumeTracker_Settings[itemID] then
                                local texture, itemCount = GetContainerItemInfo(bag, slot)
                                data["bank"][itemID] = (data["bank"][itemID] or 0) + itemCount
                            end
                        end
                    end
                end
            end
        end
    end

    ConsumeTracker_UpdateTrackerContent()
end

-- Function to scan player's mail
function ConsumeTracker_ScanPlayerMail()
      if not MailFrame or not MailFrame:IsShown() then

        return
    end

    local playerName = UnitName("player")
    local realmName = GetRealmName()
    local faction = UnitFactionGroup("player")

    -- Ensure data tables are initialized
    ConsumeTracker_Data[realmName] = ConsumeTracker_Data[realmName] or {}
    ConsumeTracker_Data[realmName][faction] = ConsumeTracker_Data[realmName][faction] or {}
    ConsumeTracker_Data[realmName][faction][playerName] = ConsumeTracker_Data[realmName][faction][playerName] or {}
    local data = ConsumeTracker_Data[realmName][faction][playerName]
    data["mail"] = {}

    local numInboxItems = GetInboxNumItems()
    if numInboxItems and numInboxItems > 0 then
        for mailIndex = 1, numInboxItems do
            local packageIcon, stationeryIcon, sender, subject, money, CODAmount, daysLeft = GetInboxHeaderInfo(mailIndex)
            local itemName, itemTexture, itemCount, itemQuality = GetInboxItem(mailIndex)
            if itemName and itemCount and itemCount > 0 then
                -- Since GetInboxItemLink is not available, use itemName to get itemID
                local itemID = consumablesNameToID[itemName]
                if itemID and ConsumeTracker_Settings[itemID] then
                    data["mail"][itemID] = (data["mail"][itemID] or 0) + itemCount
                end
            end
        end
    end

    ConsumeTracker_UpdateTrackerContent()
end
