-- Metadata ---------------------------------------------------------------------------------------------
AddonName = "Consumes Manager"
Version = "1.6"
VState = "release"
WindowWidth = 350

-- Onload & Click Functionality -------------------------------------------------------------------------
function ConsumesManager_OnLoad(self)
    self:RegisterForDrag("LeftButton")
    self:SetScript("OnDragStart", function() ConsumesManager_OnDragStart(self) end)
    self:SetScript("OnDragStop", function() ConsumesManager_OnDragStop(self) end)

    -- Create a frame for the delay
    local delayFrame = CreateFrame("Frame")
    local elapsed = 0
    local delay = 1

    delayFrame:SetScript("OnUpdate", function()
        elapsed = elapsed + arg1 -- arg1 provides the time since the last frame
        if elapsed >= delay then
            DEFAULT_CHAT_FRAME:AddMessage("|cff00ff00" .. AddonName .. "|r |cffaaaaaa(v" .. Version .. "-" .. VState .. ")|r |cffffffffLoaded!|r  |cffaaaaaa- Made by Horyoshi|r")
            delayFrame:SetScript("OnUpdate", nil) -- Stop the OnUpdate script
        end
    end)
end

function ConsumesManager_HandleClick(self, button)
    if not self then return end
    if button == "LeftButton" and not IsShiftKeyDown() then
        if ConsumesManager_MainFrame and ConsumesManager_MainFrame:IsShown() then
            ConsumesManager_MainFrame:Hide()
        else
            ConsumesManager_ShowMainWindow()
        end
    end
end

function ConsumesManager_OnDragStart(self)
    if IsShiftKeyDown() then
        self:StartMoving()
        self.isMoving = true
    end
end

function ConsumesManager_OnDragStop(self)
    if self and self.isMoving then
        self:StopMovingOrSizing()
        self.isMoving = false
    end
end

-- Initialize SavedVariables ----------------------------------------------------------------------------
    if not ConsumesManager_Settings then
        ConsumesManager_Settings = {}
    end
    if not ConsumesManager_Data then
        ConsumesManager_Data = {}
    end

-- Event frame for updating data ------------------------------------------------------------------------
    local ConsumesManager_EventFrame = CreateFrame("Frame")
    ConsumesManager_EventFrame:RegisterEvent("PLAYER_LOGIN")
    ConsumesManager_EventFrame:RegisterEvent("BAG_UPDATE")
    ConsumesManager_EventFrame:RegisterEvent("BANKFRAME_OPENED")
    ConsumesManager_EventFrame:RegisterEvent("PLAYERBANKSLOTS_CHANGED")
    ConsumesManager_EventFrame:RegisterEvent("ITEM_LOCK_CHANGED")
    ConsumesManager_EventFrame:RegisterEvent("MAIL_SHOW")
    ConsumesManager_EventFrame:RegisterEvent("MAIL_INBOX_UPDATE")
    ConsumesManager_EventFrame:RegisterEvent("MAIL_CLOSED")

    ConsumesManager_EventFrame:SetScript("OnEvent", function()
        if event == "PLAYER_LOGIN" then
            ConsumesManager_ScanPlayerInventory()
            ConsumesManager_ScanPlayerBank()
            ConsumesManager_ScanPlayerMail()
        elseif event == "BAG_UPDATE" then
            ConsumesManager_ScanPlayerInventory()
            if BankFrame and BankFrame:IsShown() then
                ConsumesManager_ScanPlayerBank()
            end
            if MailFrame and MailFrame:IsShown() then
                ConsumesManager_ScanPlayerMail()
            end
        elseif event == "BANKFRAME_OPENED" then
            ConsumesManager_ScanPlayerBank()
        elseif event == "PLAYERBANKSLOTS_CHANGED" then  
            ConsumesManager_ScanPlayerBank()
            ConsumesManager_ScanPlayerInventory()
        elseif event == "ITEM_LOCK_CHANGED" then
            if BankFrame and BankFrame:IsShown() then
                ConsumesManager_ScanPlayerInventory()
                ConsumesManager_ScanPlayerBank()
            end
            if MailFrame and MailFrame:IsShown() then
                ConsumesManager_ScanPlayerInventory()
                ConsumesManager_ScanPlayerMail()
            end
        elseif event == "MAIL_SHOW" or event == "MAIL_INBOX_UPDATE" then
            ConsumesManager_ScanPlayerMail()
        end
    end)


-- Main Windows Setup -----------------------------------------------------------------------------------
function ConsumesManager_CreateMainWindow()
    -- Main Frame
    ConsumesManager_MainFrame = CreateFrame("Frame", "ConsumesManager_MainFrame", UIParent)
    ConsumesManager_MainFrame:SetWidth(WindowWidth)
    ConsumesManager_MainFrame:SetHeight(512)
    ConsumesManager_MainFrame:SetPoint("CENTER", UIParent, "CENTER")
    ConsumesManager_MainFrame:SetFrameStrata("DIALOG")
    ConsumesManager_MainFrame:SetMovable(true)
    ConsumesManager_MainFrame:EnableMouse(true)
    ConsumesManager_MainFrame:RegisterForDrag("LeftButton")
    ConsumesManager_MainFrame:SetScript("OnDragStart", function()
        this:StartMoving()
    end)
    ConsumesManager_MainFrame:SetScript("OnDragStop", function()
        this:StopMovingOrSizing()
    end)

    table.insert(UISpecialFrames, "ConsumesManager_MainFrame")

    -- Background Texture
    local background = ConsumesManager_MainFrame:CreateTexture(nil, "BACKGROUND")
    background:SetTexture("Interface\\DialogFrame\\UI-DialogBox-Background")
    background:SetPoint("TOPLEFT", ConsumesManager_MainFrame, "TOPLEFT", 12, -12)
    background:SetPoint("BOTTOMRIGHT", ConsumesManager_MainFrame, "BOTTOMRIGHT", -12, 12)

    -- Border
    ConsumesManager_MainFrame:SetBackdrop({
        bgFile = "Interface\\Tooltips\\UI-Tooltip-Background",
        edgeFile = "Interface\\DialogFrame\\UI-DialogBox-Border",
        tile = true, tileSize = 32, edgeSize = 32,
        insets = { left = 11, right = 12, top = 12, bottom = 11 }
    })
    ConsumesManager_MainFrame:SetBackdropColor(0.1, 0.1, 0.1, 1)

    -- Title Text
    local titleText = ConsumesManager_MainFrame:CreateFontString(nil, "OVERLAY", "GameFontNormalLarge")
    titleText:SetText(AddonName)
    titleText:SetPoint("TOP", ConsumesManager_MainFrame, "TOP", 0, 0)

    -- Calculate the width of the title text and adjust the title background accordingly
    local titleWidth = titleText:GetStringWidth() + 200 

    -- Title Background
    local titleBg = ConsumesManager_MainFrame:CreateTexture(nil, "ARTWORK")
    titleBg:SetTexture("Interface\\DialogFrame\\UI-DialogBox-Header")
    titleBg:SetWidth(titleWidth)
    titleBg:SetHeight(64)
    titleBg:SetPoint("TOP", ConsumesManager_MainFrame, "TOP", 0, 12)

    -- Close Button
    local closeButton = CreateFrame("Button", nil, ConsumesManager_MainFrame, "UIPanelCloseButton")
    closeButton:SetWidth(32)
    closeButton:SetHeight(32)
    closeButton:SetPoint("TOPRIGHT", ConsumesManager_MainFrame, "TOPRIGHT", -5, -5)
    closeButton:SetScript("OnClick", function()
        ConsumesManager_MainFrame:Hide()
    end)

    -- Create a custom tooltip frame
    local tooltipFrame = CreateFrame("Frame", "ConsumesManagerTooltip", UIParent)
    tooltipFrame:SetWidth(100)
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
        local tab = CreateFrame("Button", name, ConsumesManager_MainFrame)
        tab:SetWidth(36)
        tab:SetHeight(36)
        tab:SetPoint("TOPLEFT", ConsumesManager_MainFrame, "TOPLEFT", xOffset, -30)

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

    -- Manager Tab
    local tab1 = CreateTab("ConsumesManager_MainFrameTab1", "Interface\\AddOns\\ConsumesManager\\images\\minimap_icon", 30, "Tracker", 1)
    tab1:SetScript("OnClick", function()
        ConsumesManager_ShowTab(1)
    end)

    -- Items Tab
    local tab2 = CreateTab("ConsumesManager_MainFrameTab2", "Interface\\Icons\\Inv_misc_book_03", 80, "Items", 2)
    tab2:SetScript("OnClick", function()
        ConsumesManager_ShowTab(2)
    end)

    -- Options Tab
    local tab3 = CreateTab("ConsumesManager_MainFrameTab3", "Interface\\Icons\\INV_Misc_Gear_01", 130, "Settings", 3)
    tab3:SetScript("OnClick", function()
        ConsumesManager_ShowTab(3)
    end)

    -- Add Grey Line Under Tabs
    local tabsLine = ConsumesManager_MainFrame:CreateTexture(nil, "ARTWORK")
    tabsLine:SetHeight(1)
    tabsLine:SetPoint("TOPLEFT", ConsumesManager_MainFrame, "TOPLEFT", 12, -72)
    tabsLine:SetPoint("TOPRIGHT", ConsumesManager_MainFrame, "TOPRIGHT", -12, -72)
    tabsLine:SetTexture("Interface\\Buttons\\WHITE8x8")
    tabsLine:SetVertexColor(0.4, 0.4, 0.4, 1)

    -- Tab Content
    ConsumesManager_MainFrame.tabs = {}
    local tab1Content = CreateFrame("Frame", nil, ConsumesManager_MainFrame)
    tab1Content:SetWidth(WindowWidth - 50)
    tab1Content:SetHeight(380)
    tab1Content:SetPoint("TOPLEFT", ConsumesManager_MainFrame, "TOPLEFT", 30, -80)
    ConsumesManager_MainFrame.tabs[1] = tab1Content

    local tab2Content = CreateFrame("Frame", nil, ConsumesManager_MainFrame)
    tab2Content:SetWidth(WindowWidth - 50)
    tab2Content:SetHeight(380)
    tab2Content:SetPoint("TOPLEFT", ConsumesManager_MainFrame, "TOPLEFT", 30, -80)
    ConsumesManager_MainFrame.tabs[2] = tab2Content

    local tab3Content = CreateFrame("Frame", nil, ConsumesManager_MainFrame)
    tab3Content:SetWidth(WindowWidth - 50)
    tab3Content:SetHeight(380)
    tab3Content:SetPoint("TOPLEFT", ConsumesManager_MainFrame, "TOPLEFT", 30, -80)
    ConsumesManager_MainFrame.tabs[3] = tab3Content

    -- Footer Text
    local footerText = ConsumesManager_MainFrame:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
    footerText:SetText("Made by Horyoshi (v" .. Version .. "-" .. VState .. ")")
    footerText:SetTextColor(0.6, 0.6, 0.6)
    footerText:SetPoint("BOTTOM", ConsumesManager_MainFrame, "BOTTOM", 0, 15)

    -- Add Grey Line Above Footer
    local footerLine = ConsumesManager_MainFrame:CreateTexture(nil, "ARTWORK")
    footerLine:SetHeight(1)
    footerLine:SetPoint("BOTTOMLEFT", ConsumesManager_MainFrame, "BOTTOMLEFT", 12, 30)
    footerLine:SetPoint("BOTTOMRIGHT", ConsumesManager_MainFrame, "BOTTOMRIGHT", -12, 30)
    footerLine:SetTexture("Interface\\Buttons\\WHITE8x8")
    footerLine:SetVertexColor(0.4, 0.4, 0.4, 1)

    -- Tab Switching Function
    function ConsumesManager_ShowTab(tabIndex)
        for index, content in pairs(ConsumesManager_MainFrame.tabs) do
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
    ConsumesManager_ShowTab(1)

    -- Add Custom Content for Tabs
    ConsumesManager_CreateManagerContent(tab1Content)
    ConsumesManager_CreateItemsContent(tab2Content)
    ConsumesManager_CreateSettingsContent(tab3Content)
end


function ConsumesManager_ShowMainWindow()
    if not ConsumesManager_MainFrame then
        ConsumesManager_CreateMainWindow()
    end
    ConsumesManager_MainFrame:Show()
    -- Scan inventory when the window is opened
    ConsumesManager_ScanPlayerInventory()
    -- Only scan bank and mail if they are open
    if BankFrame and BankFrame:IsShown() then
        ConsumesManager_ScanPlayerBank()
    end
    if MailFrame and MailFrame:IsShown() then
        ConsumesManager_ScanPlayerMail()
    end
    -- Update the Manager content
    ConsumesManager_UpdateManagerContent()
end


function ConsumesManager_ShowTab(tabIndex)
    if not ConsumesManager_MainFrame or not ConsumesManager_MainFrame.tabs then return end
    for i, tabContent in pairs(ConsumesManager_MainFrame.tabs) do
        if i == tabIndex then
            tabContent:Show()
            -- Set the tab button to active
            local tabButton = getglobal("ConsumesManager_MainFrameTab" .. i)
            tabButton:SetNormalTexture("Interface\\ItemsFrame\\UI-ItemsFrame-ActiveTab")
        else
            tabContent:Hide()
            -- Set the tab button to inactive
            local tabButton = getglobal("ConsumesManager_MainFrameTab" .. i)
            tabButton:SetNormalTexture("Interface\\ItemsFrame\\UI-ItemsFrame-InActiveTab")
        end
    end
end



-- Create Window Tabs -----------------------------------------------------------------------------------
function ConsumesManager_CreateManagerContent(parentFrame)
    -- Scroll Frame
    local scrollFrame = CreateFrame("ScrollFrame", "ConsumesManager_ManagerScrollFrame", parentFrame)
    scrollFrame:SetPoint("TOPLEFT", parentFrame, "TOPLEFT", 0, 0)
    scrollFrame:SetPoint("BOTTOMRIGHT", parentFrame, "BOTTOMRIGHT", -20, 0)
    scrollFrame:EnableMouseWheel(true)
    scrollFrame:SetScript("OnMouseWheel", function()
        local delta = arg1
        local current = this:GetVerticalScroll()
        local maxScroll = this.range or 0
        local newScroll = math.max(0, math.min(current - (delta * 20), maxScroll))
        this:SetVerticalScroll(newScroll)
        parentFrame.scrollBar:SetValue(newScroll)
    end)

    -- Scroll Child Frame
    local scrollChild = CreateFrame("Frame", nil, scrollFrame)
    scrollChild:SetWidth(WindowWidth - 10)
    scrollChild:SetHeight(1)  -- Will adjust later
    scrollFrame:SetScrollChild(scrollChild)
    parentFrame.scrollChild = scrollChild
    parentFrame.scrollFrame = scrollFrame

    -- Initialize data structures
    parentFrame.categoryInfo = {}
    local index = 0 -- Position index
    local lineHeight = 18

    -- Sort categories alphabetically
    local sortedCategories = {}
    for categoryName, _ in pairs(consumablesCategories) do
        table.insert(sortedCategories, categoryName)
    end
    table.sort(sortedCategories)

    -- Iterate over sorted categories
    for _, categoryName in ipairs(sortedCategories) do
        local consumables = consumablesCategories[categoryName]

        -- Create category label
        local categoryLabel = scrollChild:CreateFontString(nil, "OVERLAY", "GameFontNormalLarge")
        categoryLabel:SetText(categoryName)
        categoryLabel:SetTextColor(1, 1, 1)
        categoryLabel:Show()

        local categoryInfo = { name = categoryName, label = categoryLabel, Items = {} }

        index = index + 1  -- Position for the category label

        local numItemsInCategory = 0  -- Counter for Items in this category

        -- Sort the consumables by name
        table.sort(consumables, function(a, b) return a.name < b.name end)

        -- For each consumable in the category
        for _, consumable in ipairs(consumables) do
            local itemID = consumable.id
            local itemName = consumable.name

            -- Create a frame that encompasses the button and label
            local itemFrame = CreateFrame("Frame", "ConsumesManager_ManagerItemFrame" .. index, scrollChild)
            itemFrame:SetWidth(WindowWidth - 10)
            itemFrame:SetHeight(lineHeight)
            itemFrame:SetPoint("TOPLEFT", scrollChild, "TOPLEFT", 0, - (index) * lineHeight)
            itemFrame:Show()
            itemFrame:EnableMouse(true)  -- Enable mouse events for OnEnter and OnLeave

            -- Create the 'Use' button inside the itemFrame
            local useButton = CreateFrame("Button", "ConsumesManager_UseButton" .. index, itemFrame, "UIPanelButtonTemplate")
            useButton:SetWidth(40)
            useButton:SetHeight(16)
            useButton:SetPoint("LEFT", itemFrame, "LEFT", 0, 0)
            useButton:SetText("Use")

            -- Initially show or hide the use button based on settings
            if ConsumesManager_Settings.showUseButton then
                useButton:Show()
            else
                useButton:Hide()
            end

            -- Create FontString for label
            local label = itemFrame:CreateFontString(nil, "OVERLAY", "GameFontNormal")
            if ConsumesManager_Settings.showUseButton then
                label:SetPoint("LEFT", useButton, "RIGHT", 4, 0)
            else
                label:SetPoint("LEFT", itemFrame, "LEFT", 0, 0)
            end
            label:SetText(itemName)
            label:SetJustifyH("LEFT")

            -- Set up the button OnClick handler
            useButton:SetScript("OnClick", function()
                local bag, slot = ConsumesManager_FindItemInBags(itemID)
                if bag and slot then
                    UseContainerItem(bag, slot)
                else
                    DEFAULT_CHAT_FRAME:AddMessage("Item not found in bags.")
                end
            end)

            -- Initialize button state
            useButton:Disable()

            -- Mouseover Tooltip
            itemFrame:SetScript("OnEnter", function()
                ConsumesManager_ShowConsumableTooltip(itemID)
            end)
            itemFrame:SetScript("OnLeave", function()
                if ConsumesManager_CustomTooltip then
                    ConsumesManager_CustomTooltip:Hide()
                end
            end)

            -- Store item info
            table.insert(categoryInfo.Items, {
                frame = itemFrame,
                label = label,
                name = itemName,
                itemID = itemID,
                button = useButton
            })

            index = index + 1  -- Increment index after adding item
            numItemsInCategory = numItemsInCategory + 1  -- Increment Items count
        end

        -- Position the category label above its Items
        categoryLabel:SetPoint("TOPLEFT", scrollChild, "TOPLEFT", 0, - (index - numItemsInCategory - 1) * lineHeight)

        -- Store category info
        table.insert(parentFrame.categoryInfo, categoryInfo)

        -- Add extra spacing after the category
        index = index + 1  -- Add one extra line of spacing between categories
    end

    -- Adjust the scroll child height
    scrollChild.contentHeight = (index - 1) * lineHeight
    scrollChild:SetHeight(scrollChild.contentHeight)

    -- Message Label (adjusted to be a child of parentFrame)
    local messageLabel = parentFrame:CreateFontString(nil, "OVERLAY", "GameFontNormal")
    messageLabel:SetText("|cffff0000No consumables selected|r\n\n|cffffffffClick on |rItems|cffffffff to get started|r")
    messageLabel:SetPoint("CENTER", parentFrame, "CENTER", 0, 0)
    messageLabel:Hide()  -- Initially hidden
    parentFrame.messageLabel = messageLabel

    -- Scroll Bar
    local scrollBar = CreateFrame("Slider", "ConsumesManager_ManagerScrollBar", parentFrame)
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

    -- Update the scrollbar
    ConsumesManager_UpdateManagerScrollBar()
end


function ConsumesManager_CreateItemsContent(parentFrame)
    -- Create Search Input
    local searchBox = CreateFrame("EditBox", "ConsumesManager_SearchBox", parentFrame, "InputBoxTemplate")
    searchBox:SetWidth(WindowWidth - 50)
    searchBox:SetHeight(25)
    searchBox:SetPoint("TOPLEFT", parentFrame, "TOPLEFT", 0, -5)
    searchBox:SetAutoFocus(false)
    searchBox:SetText("Search...")
    searchBox:SetTextColor(0.5, 0.5, 0.5) -- Placeholder text color

    searchBox:SetScript("OnEditFocusGained", function()
        if this:GetText() == "Search..." then
            this:SetText("")
            this:SetTextColor(1, 1, 1) -- User input text color
        end
    end)

    searchBox:SetScript("OnEditFocusLost", function()
        if this:GetText() == "" then
            this:SetText("Search...")
            this:SetTextColor(0.5, 0.5, 0.5) -- Placeholder text color
        end
    end)

    -- Function to update the filter
    local function UpdateFilter()
        local filterText = string.lower(searchBox:GetText())
        if filterText == "search..." then filterText = "" end
        local index = 0 -- Position index
        local lineHeight = 18

        -- Iterate over categories
        for _, categoryInfo in ipairs(parentFrame.categoryInfo) do
            local categoryLabel = categoryInfo.label
            local anyitemVisible = false

            -- First, check if any Items in the category match the filter
            for _, itemInfo in ipairs(categoryInfo.Items) do
                local itemNameLower = string.lower(itemInfo.name)

                if filterText == "" or string.find(itemNameLower, filterText, 1, true) then
                    anyitemVisible = true
                    break
                end
            end

            -- If any Items are visible, show the category label
            if anyitemVisible then
                categoryLabel:SetPoint("TOPLEFT", parentFrame.scrollChild, "TOPLEFT", 0, - (index) * lineHeight)
                categoryLabel:Show()
                index = index + 1

                -- Now, position and show the matching Items
                for _, itemInfo in ipairs(categoryInfo.Items) do
                    local itemFrame = itemInfo.frame
                    local itemNameLower = string.lower(itemInfo.name)

                    if filterText == "" or string.find(itemNameLower, filterText, 1, true) then
                        -- Show the item
                        itemFrame:SetPoint("TOPLEFT", parentFrame.scrollChild, "TOPLEFT", 0, - (index) * lineHeight)
                        itemFrame:Show()
                        index = index + 1
                    else
                        itemFrame:Hide()
                    end
                end

                -- Add extra spacing after the category
                index = index + 1  -- Add one extra line of spacing between categories

            else
                categoryLabel:Hide()
                -- Hide all Items under this category
                for _, itemInfo in ipairs(categoryInfo.Items) do
                    itemInfo.frame:Hide()
                end
            end
        end

        -- Adjust the scroll child height
        parentFrame.scrollChild.contentHeight = index * lineHeight
        parentFrame.scrollChild:SetHeight(parentFrame.scrollChild.contentHeight)

        -- Update the scrollbar
        ConsumesManager_UpdateItemsScrollBar()
    end

    searchBox:SetScript("OnTextChanged", function()
        UpdateFilter()
    end)

    -- Adjust the size of the scroll frame to make room for the search box and add extra spacing
    local scrollFrame = CreateFrame("ScrollFrame", "ConsumesManager_ItemsScrollFrame", parentFrame)
    scrollFrame:SetPoint("TOPLEFT", parentFrame, "TOPLEFT", 0, -40)  -- Start below the search box
    scrollFrame:SetPoint("BOTTOMRIGHT", parentFrame, "BOTTOMRIGHT", -20, 60) -- Leave space for buttons
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
    scrollChild:SetWidth(WindowWidth - 10)
    scrollChild:SetHeight(1)  -- Will adjust later
    scrollFrame:SetScrollChild(scrollChild)
    parentFrame.scrollChild = scrollChild
    parentFrame.scrollFrame = scrollFrame

    -- Sort categories alphabetically
    local sortedCategories = {}
    for categoryName, _ in pairs(consumablesCategories) do
        table.insert(sortedCategories, categoryName)
    end
    table.sort(sortedCategories)

    -- Checkboxes
    parentFrame.checkboxes = {}
    parentFrame.categoryInfo = {}
    local index = 0 -- Position index
    local lineHeight = 18

    -- Iterate over sorted categories
    for _, categoryName in ipairs(sortedCategories) do
        local consumables = consumablesCategories[categoryName]

        -- Create category label
        local categoryLabel = scrollChild:CreateFontString(nil, "OVERLAY", "GameFontNormalLarge")
        categoryLabel:SetText(categoryName)
        categoryLabel:SetTextColor(1, 1, 1)
        categoryLabel:Show()
        
        local categoryInfo = { name = categoryName, label = categoryLabel, Items = {} }

        index = index + 1  -- Position for the category label

        local numItemsInCategory = 0  -- Counter for Items in this category

        -- Sort the consumables by name
        table.sort(consumables, function(a, b) return a.name < b.name end)

        -- For each consumable in the category
        for _, consumable in ipairs(consumables) do
            local currentItemID = consumable.id
            local itemName = consumable.name

            -- Create a frame that encompasses the checkbox and label
            local itemFrame = CreateFrame("Frame", "ConsumesManager_ItemsFrame" .. index, scrollChild)
            itemFrame:SetWidth(WindowWidth - 10)
            itemFrame:SetHeight(lineHeight)
            itemFrame:SetPoint("TOPLEFT", scrollChild, "TOPLEFT", 0, - (index) * lineHeight)
            itemFrame:Show()

            -- Create the checkbox inside the itemFrame
            local checkbox = CreateFrame("CheckButton", "ConsumesManager_ItemsCheckbox" .. index, itemFrame)
            checkbox:SetWidth(16)
            checkbox:SetHeight(16)
            checkbox:SetPoint("LEFT", itemFrame, "LEFT", 0, 0)

            -- Create Textures for the checkbox
            checkbox:SetNormalTexture("Interface\\Buttons\\UI-CheckBox-Up")
            checkbox:SetPushedTexture("Interface\\Buttons\\UI-CheckBox-Down")
            checkbox:SetHighlightTexture("Interface\\Buttons\\UI-CheckBox-Highlight")
            checkbox:SetCheckedTexture("Interface\\Buttons\\UI-CheckBox-Check")

            -- Create FontString for label
            local label = itemFrame:CreateFontString(nil, "OVERLAY", "GameFontNormal")
            label:SetPoint("LEFT", checkbox, "RIGHT", 4, 0)
            label:SetText(itemName)

            -- Set up the checkbox OnClick handler
            checkbox:SetScript("OnClick", function()
                ConsumesManager_Settings[currentItemID] = checkbox:GetChecked()
                ConsumesManager_UpdateManagerContent()
            end)
            -- Load saved setting
            if ConsumesManager_Settings[currentItemID] then
                checkbox:SetChecked(true)
            end
            parentFrame.checkboxes[currentItemID] = checkbox

            -- Make the itemFrame clickable
            itemFrame:EnableMouse(true)
            itemFrame:SetScript("OnMouseDown", function()
                checkbox:Click()
            end)

            -- Mouseover Tooltip
            itemFrame:SetScript("OnEnter", function()
                ConsumesManager_ShowItemsTooltip(currentItemID)
            end)
            itemFrame:SetScript("OnLeave", function()
                if ConsumesManager_ItemsTooltip then
                    ConsumesManager_ItemsTooltip:Hide()
                end
            end)

            -- Store item info
            table.insert(categoryInfo.Items, { frame = itemFrame, name = itemName })

            index = index + 1  -- Increment index after adding item
            numItemsInCategory = numItemsInCategory + 1  -- Increment Items count
        end

        -- Position the category label above its Items
        categoryLabel:SetPoint("TOPLEFT", scrollChild, "TOPLEFT", 0, - (index - numItemsInCategory - 1) * lineHeight)

        -- Store category info
        table.insert(parentFrame.categoryInfo, categoryInfo)

        -- Add extra spacing after the category
        index = index + 1  -- Add one extra line of spacing between categories
    end

    -- Adjust the scroll child height
    scrollChild.contentHeight = (index - 1) * lineHeight
    scrollChild:SetHeight(scrollChild.contentHeight)

    -- Scroll Bar
    local scrollBar = CreateFrame("Slider", "ConsumesManager_ItemsScrollBar", parentFrame)
    -- Corrected Y-offsets to prevent overlapping
    scrollBar:SetPoint("TOPRIGHT", parentFrame, "TOPRIGHT", -2, -40)  -- Start below the search box
    scrollBar:SetPoint("BOTTOMRIGHT", parentFrame, "BOTTOMRIGHT", -2, 16) -- End above the buttons
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

    -- Update the scrollbar
    ConsumesManager_UpdateItemsScrollBar()

    -- Create Select All Button
    local selectAllButton = CreateFrame("Button", "ConsumesManager_SelectAllButton", parentFrame, "UIPanelButtonTemplate")
    selectAllButton:SetWidth(100)
    selectAllButton:SetHeight(24)
    selectAllButton:SetText("Select All")
    selectAllButton:SetPoint("BOTTOMLEFT", parentFrame, "BOTTOMLEFT", 20, 10)
    selectAllButton:SetScript("OnClick", function()
        for itemID, checkbox in pairs(parentFrame.checkboxes) do
            checkbox:SetChecked(true)
            ConsumesManager_Settings[itemID] = true
        end
        ConsumesManager_UpdateManagerContent()
    end)

    -- Create Deselect All Button
    local deselectAllButton = CreateFrame("Button", "ConsumesManager_DeselectAllButton", parentFrame, "UIPanelButtonTemplate")
    deselectAllButton:SetWidth(100)
    deselectAllButton:SetHeight(24)
    deselectAllButton:SetText("Deselect All")
    deselectAllButton:SetPoint("BOTTOMRIGHT", parentFrame, "BOTTOMRIGHT", -40, 10)
    deselectAllButton:SetScript("OnClick", function()
        for itemID, checkbox in pairs(parentFrame.checkboxes) do
            checkbox:SetChecked(false)
            ConsumesManager_Settings[itemID] = false
        end
        ConsumesManager_UpdateManagerContent()
    end)
end


function ConsumesManager_CreateSettingsContent(parentFrame)
    -- Scroll Frame
    local scrollFrame = CreateFrame("ScrollFrame", "ConsumesManager_SettingsScrollFrame", parentFrame)
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
    scrollChild:SetWidth(WindowWidth - 10)
    scrollChild:SetHeight(1)
    scrollFrame:SetScrollChild(scrollChild)
    parentFrame.scrollChild = scrollChild
    parentFrame.scrollFrame = scrollFrame

    -- Initialize variables
    parentFrame.checkboxes = {}
    local index = 0 -- Position index
    local lineHeight = 20 -- Increased to accommodate spacing

    -- Ensure settings table for characters exists
    ConsumesManager_Settings["Characters"] = ConsumesManager_Settings["Characters"] or {}

    -- Get list of characters
    local realmName = GetRealmName()
    local faction = UnitFactionGroup("player")
    local playerName = UnitName("player")

    local characterList = {}

    -- Ensure data structure exists
    if ConsumesManager_Data[realmName] and ConsumesManager_Data[realmName][faction] then
        for characterName, _ in pairs(ConsumesManager_Data[realmName][faction]) do
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
    local title = scrollChild:CreateFontString(nil, "OVERLAY", "GameFontNormalLarge")
    title:SetPoint("TOPLEFT", scrollChild, "TOPLEFT", 0, 0) -- Offset from the top
    title:SetText("Select Characters To Track")
    title:SetTextColor(1, 1, 1)

    -- Offset index to start below the title
    local startYOffset = -20

    -- For each character
    for _, characterName in ipairs(characterList) do
        index = index + 1

        -- Create a local copy of characterName for the closure
        local currentCharacterName = characterName

        -- Create a frame that encompasses the checkbox and label
        local itemFrame = CreateFrame("Frame", "ConsumesManager_CharacterFrame" .. index, scrollChild)
        itemFrame:SetWidth(WindowWidth - 10)
        itemFrame:SetHeight(18)
        itemFrame:SetPoint("TOPLEFT", scrollChild, "TOPLEFT", 0, startYOffset - (index - 1) * lineHeight)

        -- Create the checkbox inside the itemFrame
        local checkbox = CreateFrame("CheckButton", "ConsumesManager_CharacterCheckbox" .. index, itemFrame)
        checkbox:SetWidth(16)
        checkbox:SetHeight(16)
        checkbox:SetPoint("LEFT", itemFrame, "LEFT", 0, 0)

        -- Create Textures for the checkbox
        checkbox:SetNormalTexture("Interface\\Buttons\\UI-CheckBox-Up")
        checkbox:SetPushedTexture("Interface\\Buttons\\UI-CheckBox-Down")
        checkbox:SetHighlightTexture("Interface\\Buttons\\UI-CheckBox-Highlight")
        checkbox:SetCheckedTexture("Interface\\Buttons\\UI-CheckBox-Check")

        -- Create FontString for label
        local label = itemFrame:CreateFontString(nil, "OVERLAY", "GameFontNormal")
        label:SetPoint("LEFT", checkbox, "RIGHT", 4, 0)
        label:SetText(currentCharacterName)
        label:SetJustifyH("LEFT")

        -- Set up the checkbox OnClick handler
        checkbox:SetScript("OnClick", function()
            ConsumesManager_Settings["Characters"][currentCharacterName] = checkbox:GetChecked()
            ConsumesManager_UpdateManagerContent()
        end)
        -- Load saved setting
        if ConsumesManager_Settings["Characters"][currentCharacterName] == nil then
            -- Default to checked
            checkbox:SetChecked(true)
            ConsumesManager_Settings["Characters"][currentCharacterName] = true
        else
            checkbox:SetChecked(ConsumesManager_Settings["Characters"][currentCharacterName])
        end
        parentFrame.checkboxes[currentCharacterName] = checkbox

        -- Make the itemFrame clickable (so clicking on the label checks/unchecks the box)
        itemFrame:EnableMouse(true)
        itemFrame:SetScript("OnMouseDown", function()
            checkbox:Click()
        end)
    end

    -- Add spacing of 20 below the character list
    index = index + 1

    -- Create 'General Settings' title with spacing of 20
    local generalSettingsTitle = scrollChild:CreateFontString(nil, "OVERLAY", "GameFontNormalLarge")
    generalSettingsTitle:SetPoint("TOPLEFT", scrollChild, "TOPLEFT", 0, startYOffset - index * lineHeight)
    generalSettingsTitle:SetText("General Settings")
    generalSettingsTitle:SetTextColor(1, 1, 1)

    -- Move index down for the checkboxes
    index = index + 1

    -- Initialize General Settings if not set
    ConsumesManager_Settings.enableCategories = ConsumesManager_Settings.enableCategories == nil and true or ConsumesManager_Settings.enableCategories
    ConsumesManager_Settings.showUseButton = ConsumesManager_Settings.showUseButton == nil and true or ConsumesManager_Settings.showUseButton

    -- Create 'Enable Categories' checkbox
    local enableCategoriesFrame = CreateFrame("Frame", "ConsumesManager_EnableCategoriesFrame", scrollChild)
    enableCategoriesFrame:SetWidth(WindowWidth - 10)
    enableCategoriesFrame:SetHeight(18)
    enableCategoriesFrame:SetPoint("TOPLEFT", scrollChild, "TOPLEFT", 0, startYOffset - index * lineHeight)
    enableCategoriesFrame:EnableMouse(true)

    local enableCategoriesCheckbox = CreateFrame("CheckButton", "ConsumesManager_EnableCategoriesCheckbox", enableCategoriesFrame)
    enableCategoriesCheckbox:SetWidth(16)
    enableCategoriesCheckbox:SetHeight(16)
    enableCategoriesCheckbox:SetPoint("LEFT", enableCategoriesFrame, "LEFT", 0, 0)

    enableCategoriesCheckbox:SetNormalTexture("Interface\\Buttons\\UI-CheckBox-Up")
    enableCategoriesCheckbox:SetPushedTexture("Interface\\Buttons\\UI-CheckBox-Down")
    enableCategoriesCheckbox:SetHighlightTexture("Interface\\Buttons\\UI-CheckBox-Highlight")
    enableCategoriesCheckbox:SetCheckedTexture("Interface\\Buttons\\UI-CheckBox-Check")

    enableCategoriesCheckbox:SetChecked(ConsumesManager_Settings.enableCategories)

    enableCategoriesCheckbox:SetScript("OnClick", function()
        ConsumesManager_Settings.enableCategories = enableCategoriesCheckbox:GetChecked()
        ConsumesManager_UpdateManagerContent()
    end)

    local enableCategoriesLabel = enableCategoriesFrame:CreateFontString(nil, "OVERLAY", "GameFontNormal")
    enableCategoriesLabel:SetPoint("LEFT", enableCategoriesCheckbox, "RIGHT", 4, 0)
    enableCategoriesLabel:SetText("Enable Categories")
    enableCategoriesLabel:SetJustifyH("LEFT")

    -- Make the frame clickable (so clicking on the label checks/unchecks the box)
    enableCategoriesFrame:SetScript("OnMouseDown", function()
        enableCategoriesCheckbox:Click()
    end)

    index = index + 1  -- Move index down for next checkbox

    -- Create 'Show Use Button' checkbox
    local showUseButtonFrame = CreateFrame("Frame", "ConsumesManager_ShowUseButtonFrame", scrollChild)
    showUseButtonFrame:SetWidth(WindowWidth - 10)
    showUseButtonFrame:SetHeight(18)
    showUseButtonFrame:SetPoint("TOPLEFT", scrollChild, "TOPLEFT", 0, startYOffset - index * lineHeight)
    showUseButtonFrame:EnableMouse(true)

    local showUseButtonCheckbox = CreateFrame("CheckButton", "ConsumesManager_ShowUseButtonCheckbox", showUseButtonFrame)
    showUseButtonCheckbox:SetWidth(16)
    showUseButtonCheckbox:SetHeight(16)
    showUseButtonCheckbox:SetPoint("LEFT", showUseButtonFrame, "LEFT", 0, 0)

    showUseButtonCheckbox:SetNormalTexture("Interface\\Buttons\\UI-CheckBox-Up")
    showUseButtonCheckbox:SetPushedTexture("Interface\\Buttons\\UI-CheckBox-Down")
    showUseButtonCheckbox:SetHighlightTexture("Interface\\Buttons\\UI-CheckBox-Highlight")
    showUseButtonCheckbox:SetCheckedTexture("Interface\\Buttons\\UI-CheckBox-Check")

    showUseButtonCheckbox:SetChecked(ConsumesManager_Settings.showUseButton)

    showUseButtonCheckbox:SetScript("OnClick", function()
        ConsumesManager_Settings.showUseButton = showUseButtonCheckbox:GetChecked()
        ConsumesManager_UpdateManagerContent()
    end)

    local showUseButtonLabel = showUseButtonFrame:CreateFontString(nil, "OVERLAY", "GameFontNormal")
    showUseButtonLabel:SetPoint("LEFT", showUseButtonCheckbox, "RIGHT", 4, 0)
    showUseButtonLabel:SetText("Show Use Button")
    showUseButtonLabel:SetJustifyH("LEFT")

    -- Make the frame clickable (so clicking on the label checks/unchecks the box)
    showUseButtonFrame:SetScript("OnMouseDown", function()
        showUseButtonCheckbox:Click()
    end)

    index = index + 1  -- Move index down after adding General Settings

    -- Adjust the scroll child height
    scrollChild.contentHeight = math.abs(startYOffset) + index * lineHeight
    scrollChild:SetHeight(scrollChild.contentHeight)

    -- Scroll Bar
    local scrollBar = CreateFrame("Slider", "ConsumesManager_SettingsScrollBar", parentFrame)
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

    -- Update the scrollbar
    ConsumesManager_UpdateSettingsScrollBar()
end





-- Update Window Tabs -----------------------------------------------------------------------------------
function ConsumesManager_UpdateManagerContent()
    if not ConsumesManager_MainFrame or not ConsumesManager_MainFrame.tabs or not ConsumesManager_MainFrame.tabs[1] then
        return
    end

    local ManagerFrame = ConsumesManager_MainFrame.tabs[1]
    local realmName = GetRealmName()
    local faction = UnitFactionGroup("player")
    local playerName = UnitName("player")

    -- Ensure data structure exists
    if not ConsumesManager_Data[realmName] or not ConsumesManager_Data[realmName][faction] then
        return
    end
    local data = ConsumesManager_Data[realmName][faction]

    -- Check if bank and mail have been scanned for current character
    local currentCharData = data[playerName]
    local bankScanned = currentCharData and currentCharData["bank"] ~= nil
    local mailScanned = currentCharData and currentCharData["mail"] ~= nil

    -- If bank and mail have not been scanned, show message and hide item labels
    if not bankScanned or not mailScanned then
        -- Hide all item frames and category labels
        for _, categoryInfo in ipairs(ManagerFrame.categoryInfo) do
            categoryInfo.label:Hide()
            for _, itemInfo in ipairs(categoryInfo.Items) do
                itemInfo.frame:Hide()
            end
        end

        -- Show message
        ManagerFrame.messageLabel:SetText("|cffff0000This character is not scanned yet|r\n\n|cffffffffOpen your |rBank|cffffffff and |rMail |cffffffffto get started|r")
        ManagerFrame.messageLabel:Show()

        -- Update the Manager scrollbar
        ConsumesManager_UpdateManagerScrollBar()

        return
    end

    -- Proceed with normal content update
    local index = 0  -- Positioning index for items
    local hasAnyVisibleItems = false  -- Track if any items are visible
    local lineHeight = 18

    -- Hide the message label
    ManagerFrame.messageLabel:Hide()

    -- Check if categories are enabled
    if ConsumesManager_Settings.enableCategories then
        -- Iterate over categories
        for _, categoryInfo in ipairs(ManagerFrame.categoryInfo) do
            local anyItemVisible = false

            -- First, check if any Items in the category are enabled
            for _, itemInfo in ipairs(categoryInfo.Items) do
                local itemID = itemInfo.itemID
                if ConsumesManager_Settings[itemID] then
                    anyItemVisible = true
                    break
                end
            end

            -- If any Items are visible, handle category label
            if anyItemVisible then
                categoryInfo.label:SetPoint("TOPLEFT", ManagerFrame.scrollChild, "TOPLEFT", 0, - (index) * lineHeight)
                categoryInfo.label:Show()
                index = index + 1

                -- Now, position and show the enabled Items
                for _, itemInfo in ipairs(categoryInfo.Items) do
                    local itemID = itemInfo.itemID
                    local itemName = itemInfo.name
                    local label = itemInfo.label
                    local button = itemInfo.button
                    local frame = itemInfo.frame

                    if ConsumesManager_Settings[itemID] then
                        -- Sum counts across all selected characters
                        local totalCount = 0
                        for character, charData in pairs(data) do
                            if ConsumesManager_Settings["Characters"][character] == true then
                                local inventory = charData["inventory"] and charData["inventory"][itemID] or 0
                                local bank = charData["bank"] and charData["bank"][itemID] or 0
                                local mail = charData["mail"] and charData["mail"][itemID] or 0
                                totalCount = totalCount + inventory + bank + mail
                            end
                        end

                        -- Update label text with counts
                        label:SetText(itemName .. " (" .. totalCount .. ")")

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

                        -- Enable or disable the 'Use' button based on whether the item is in the player's inventory
                        local playerInventory = data[playerName]["inventory"] or {}
                        local countInInventory = playerInventory[itemID] or 0

                        if ConsumesManager_Settings.showUseButton then
                            button:Show()
                            if countInInventory > 0 then
                                button:Enable()
                            else
                                button:Disable()
                            end
                            label:SetPoint("LEFT", button, "RIGHT", 4, 0)
                        else
                            button:Hide()
                            label:SetPoint("LEFT", frame, "LEFT", 0, 0)
                        end

                        -- Show and position the item frame
                        frame:SetPoint("TOPLEFT", ManagerFrame.scrollChild, "TOPLEFT", 0, - (index) * lineHeight)
                        frame:Show()
                        index = index + 1
                        hasAnyVisibleItems = true
                    else
                        frame:Hide()
                    end
                end

                -- Add extra spacing after the category
                index = index + 1  -- Add one extra line of spacing between categories
            else
                categoryInfo.label:Hide()
                -- Hide all Items under this category
                for _, itemInfo in ipairs(categoryInfo.Items) do
                    itemInfo.frame:Hide()
                end
            end
        end
    else
        -- Categories are disabled
        -- Collect all enabled items into a single list
        local allItems = {}
        for _, categoryInfo in ipairs(ManagerFrame.categoryInfo) do
            categoryInfo.label:Hide()
            for _, itemInfo in ipairs(categoryInfo.Items) do
                local itemID = itemInfo.itemID
                if ConsumesManager_Settings[itemID] then
                    table.insert(allItems, itemInfo)
                else
                    itemInfo.frame:Hide()
                end
            end
        end

        -- Sort allItems by item name
        table.sort(allItems, function(a, b) return a.name < b.name end)

        -- Display all items
        for _, itemInfo in ipairs(allItems) do
            local itemID = itemInfo.itemID
            local itemName = itemInfo.name
            local label = itemInfo.label
            local button = itemInfo.button
            local frame = itemInfo.frame

            -- Sum counts across all selected characters
            local totalCount = 0
            for character, charData in pairs(data) do
                if ConsumesManager_Settings["Characters"][character] == true then
                    local inventory = charData["inventory"] and charData["inventory"][itemID] or 0
                    local bank = charData["bank"] and charData["bank"][itemID] or 0
                    local mail = charData["mail"] and charData["mail"][itemID] or 0
                    totalCount = totalCount + inventory + bank + mail
                end
            end

            -- Update label text with counts
            label:SetText(itemName .. " (" .. totalCount .. ")")

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

            -- Enable or disable the 'Use' button based on whether the item is in the player's inventory
            local playerInventory = data[playerName]["inventory"] or {}
            local countInInventory = playerInventory[itemID] or 0

            if ConsumesManager_Settings.showUseButton then
                button:Show()
                if countInInventory > 0 then
                    button:Enable()
                else
                    button:Disable()
                end
                label:SetPoint("LEFT", button, "RIGHT", 4, 0)
            else
                button:Hide()
                label:SetPoint("LEFT", frame, "LEFT", 0, 0)
            end

            -- Show and position the item frame
            frame:SetPoint("TOPLEFT", ManagerFrame.scrollChild, "TOPLEFT", 0, - (index) * lineHeight)
            frame:Show()
            index = index + 1
            hasAnyVisibleItems = true
        end
    end

    -- Adjust the scroll child height
    ManagerFrame.scrollChild.contentHeight = index * lineHeight
    ManagerFrame.scrollChild:SetHeight(ManagerFrame.scrollChild.contentHeight)

    -- Update the scrollbar
    ConsumesManager_UpdateManagerScrollBar()

    if not hasAnyVisibleItems then
        -- Show message when no items are selected
        ManagerFrame.messageLabel:SetText("|cffff0000No consumables selected|r\n\n|cffffffffClick on |rItems|cffffffff to get started|r")
        ManagerFrame.messageLabel:Show()
    else
        -- Hide the message label as we have content to display
        ManagerFrame.messageLabel:Hide()
    end
end




-- Scrollbar Window Updates -----------------------------------------------------------------------------
function ConsumesManager_UpdateManagerScrollBar()
    local ManagerFrame = ConsumesManager_MainFrame.tabs[1]
    local scrollBar = ManagerFrame.scrollBar
    local scrollFrame = ManagerFrame.scrollFrame
    local scrollChild = ManagerFrame.scrollChild

    local totalHeight = scrollChild:GetHeight()
    local shownHeight = ManagerFrame:GetHeight() - 20  -- Account for padding/margins

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

function ConsumesManager_UpdateItemsScrollBar()
    local ItemsFrame = ConsumesManager_MainFrame.tabs[2]
    local scrollBar = ItemsFrame.scrollBar
    local scrollFrame = ItemsFrame.scrollFrame
    local scrollChild = ItemsFrame.scrollChild

    local totalHeight = scrollChild.contentHeight
    local parentHeight = ItemsFrame:GetHeight()
    local searchBoxHeight = 36  -- Adjusted height including padding
    local buttonsHeight = 40      -- Space reserved for Select/Deselect buttons
    local shownHeight = parentHeight - searchBoxHeight - buttonsHeight - 20  -- Additional padding

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


function ConsumesManager_UpdateSettingsScrollBar()
    local OptionsFrame = ConsumesManager_MainFrame.tabs[3]
    local scrollBar = OptionsFrame.scrollBar
    local scrollFrame = OptionsFrame.scrollFrame
    local scrollChild = OptionsFrame.scrollChild

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



-- Functions to USE an item -----------------------------------------------------------------------------

function ConsumesManager_UpdateUseButtons()
    if not ConsumesManager_MainFrame or not ConsumesManager_MainFrame.tabs or not ConsumesManager_MainFrame.tabs[1] then
        return
    end

    local ManagerFrame = ConsumesManager_MainFrame.tabs[1]
    local playerName = UnitName("player")
    local realmName = GetRealmName()
    local faction = UnitFactionGroup("player")

    -- Ensure data structure exists
    if not ConsumesManager_Data[realmName] or not ConsumesManager_Data[realmName][faction] then
        return
    end
    local data = ConsumesManager_Data[realmName][faction]
    local charData = data[playerName]
    if not charData then return end

    local inventory = charData["inventory"] or {}

    -- Iterate over the Items to update the buttons
    for _, categoryInfo in ipairs(ManagerFrame.categoryInfo) do
        for _, itemInfo in ipairs(categoryInfo.Items) do
            local itemID = itemInfo.itemID
            local button = itemInfo.button
            local label = itemInfo.label
            local frame = itemInfo.frame

            if ConsumesManager_Settings[itemID] then
                local count = inventory[itemID] or 0
                if count > 0 then
                    if ConsumesManager_Settings.showUseButton then
                        button:Enable()
                        button:Show()
                        label:SetPoint("LEFT", button, "RIGHT", 4, 0)
                    else
                        button:Disable()
                        button:Hide()
                        label:SetPoint("LEFT", frame, "LEFT", 0, 0)
                    end
                else
                    button:Disable()
                    button:Hide()
                    label:SetPoint("LEFT", frame, "LEFT", 0, 0)
                end
            else
                button:Disable()
                button:Hide()
                label:SetPoint("LEFT", frame, "LEFT", 0, 0)
            end
        end
    end
end


function ConsumesManager_FindItemInBags(itemID)
    for bag = 0, 4 do
        local numSlots = GetContainerNumSlots(bag)
        if numSlots then
            for slot = 1, numSlots do
                local link = GetContainerItemLink(bag, slot)
                if link then
                    local _, _, linkItemID = string.find(link, "item:(%d+)")
                    if linkItemID then
                        linkItemID = tonumber(linkItemID)
                        if linkItemID == itemID then
                            return bag, slot
                        end
                    end
                end
            end
        end
    end
    return nil, nil
end



-- Tooltip Windows --------------------------------------------------------------------------------------
function ConsumesManager_ShowConsumableTooltip(itemID)
    -- Ensure item is enabled in settings
    if not ConsumesManager_Settings[itemID] then
        return
    end

    -- Create or reuse custom tooltip frame
    if not ConsumesManager_CustomTooltip then
        -- Create the frame
        local tooltipFrame = CreateFrame("Frame", "ConsumesManager_CustomTooltip", UIParent)
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
        local total = tooltipFrame:CreateFontString(nil, "OVERLAY", "GameFontNormal")
        total:SetPoint("TOPLEFT", icon, "TOPRIGHT", 10, -20)
        total:SetPoint("RIGHT", tooltipFrame, "RIGHT", -10, 0)
        total:SetJustifyH("LEFT")
        tooltipFrame.total = total

        -- Content text
        local content = tooltipFrame:CreateFontString(nil, "OVERLAY", "GameFontNormal")
        content:SetPoint("TOPLEFT", icon, "BOTTOMLEFT", 0, -10)
        content:SetPoint("RIGHT", tooltipFrame, "RIGHT", -10, 0)
        content:SetJustifyH("LEFT")
        tooltipFrame.content = content

        ConsumesManager_CustomTooltip = tooltipFrame
    end

    local tooltipFrame = ConsumesManager_CustomTooltip

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
    ConsumesManager_Data[realmName] = ConsumesManager_Data[realmName] or {}
    ConsumesManager_Data[realmName][faction] = ConsumesManager_Data[realmName][faction] or {}

    local data = ConsumesManager_Data[realmName][faction]

    -- Initialize totals
    local totalInventory, totalBank, totalMail = 0, 0, 0
    local hasItems = false
    local characterList = {}

    -- Ensure character settings exist
    ConsumesManager_Settings["Characters"] = ConsumesManager_Settings["Characters"] or {}

    -- Collect data for each character
    for character, charData in pairs(data) do
        if ConsumesManager_Settings["Characters"][character] == true then
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

        -- Sort characters alphabetically (itemal)
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
    local lineHeightTooltip = 12
    local totalHeight = 50 + (numLines * lineHeightTooltip)
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


function ConsumesManager_ShowItemsTooltip(itemID)
    -- Set the maximum width for the description text
    local maxDescriptionWidth = 200

    -- Create or reuse the tooltip frame
    if not ConsumesManager_ItemsTooltip then
        -- Create the frame
        local tooltipFrame = CreateFrame("Frame", "ConsumesManager_ItemsTooltip", UIParent)
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
        local description = tooltipFrame:CreateFontString(nil, "OVERLAY", "GameFontNormal")
        description:SetPoint("TOPLEFT", icon, "BOTTOMLEFT", 0, -10)
        description:SetWidth(maxDescriptionWidth)
        description:SetJustifyH("LEFT")
        description:SetTextColor(1, 1, 1)
        tooltipFrame.description = description

        ConsumesManager_ItemsTooltip = tooltipFrame
    end

    local tooltipFrame = ConsumesManager_ItemsTooltip

    -- Get item info
    local itemName = consumablesList[itemID] or "Unknown Item"
    local itemTexture = consumablesTexture[itemID] or "Interface\\Icons\\INV_Misc_QuestionMark"
    local itemDescription = consumablesDescription[itemID] or ""

    -- Set icon, title, and description
    tooltipFrame.icon:SetTexture(itemTexture)
    tooltipFrame.title:SetText(itemName)
    tooltipFrame.description:SetText(itemDescription)

    -- Adjust the height of the description based on its content
    tooltipFrame.description:SetWidth(maxDescriptionWidth)
    tooltipFrame.description:SetText(itemDescription)
    local descriptionHeight = tooltipFrame.description:GetHeight()

    -- Adjust tooltip height based on content
    local totalHeight = 70 + descriptionHeight
    tooltipFrame:SetHeight(totalHeight)

    -- Set the width of the tooltip
    local titleWidth = tooltipFrame.title:GetStringWidth() + 70
    local maxWidth = math.max(titleWidth, maxDescriptionWidth + 20)
    tooltipFrame:SetWidth(maxWidth)

    -- Position the tooltip near the cursor
    local x, y = GetCursorPosition()
    local scale = UIParent:GetEffectiveScale()
    tooltipFrame:SetPoint("BOTTOMLEFT", UIParent, "BOTTOMLEFT", x / scale + 10, y / scale - 10)

    tooltipFrame:Show()
end



-- Scan Functions ---------------------------------------------------------------------------------------
function ConsumesManager_ScanPlayerInventory()
    local playerName = UnitName("player")
    local realmName = GetRealmName()
    local faction = UnitFactionGroup("player")

    -- Initialize data structures
    ConsumesManager_Data[realmName] = ConsumesManager_Data[realmName] or {}
    ConsumesManager_Data[realmName][faction] = ConsumesManager_Data[realmName][faction] or {}
    ConsumesManager_Data[realmName][faction][playerName] = ConsumesManager_Data[realmName][faction][playerName] or {}
    local data = ConsumesManager_Data[realmName][faction][playerName]
    data["inventory"] = {}

    -- Scan all bags (0 to 4 represent backpack and additional bags)
    for bag = 0, 4 do
        local numSlots = GetContainerNumSlots(bag)
        if numSlots then
            for slot = 1, numSlots do
                local link = GetContainerItemLink(bag, slot)
                if link then
                    local _, _, itemID = string.find(link, "item:(%d+)")
                    if itemID then
                        itemID = tonumber(itemID)
                        -- Scan all items, regardless of selection
                        local texture, itemCount = GetContainerItemInfo(bag, slot)
                        if itemCount and itemCount > 0 then
                            data["inventory"][itemID] = (data["inventory"][itemID] or 0) + itemCount
                        end
                    end
                end
            end
        end
    end

    -- Update the Manager window and use buttons
    ConsumesManager_UpdateUseButtons()
    ConsumesManager_UpdateManagerContent()
end

function ConsumesManager_ScanPlayerBank()
    -- Ensure the BankFrame is open before scanning
    if not BankFrame or not BankFrame:IsShown() then
        return
    end

    local playerName = UnitName("player")
    local realmName = GetRealmName()
    local faction = UnitFactionGroup("player")

    -- Initialize data structures
    ConsumesManager_Data[realmName] = ConsumesManager_Data[realmName] or {}
    ConsumesManager_Data[realmName][faction] = ConsumesManager_Data[realmName][faction] or {}
    ConsumesManager_Data[realmName][faction][playerName] = ConsumesManager_Data[realmName][faction][playerName] or {}
    local data = ConsumesManager_Data[realmName][faction][playerName]
    data["bank"] = {}

    -- In WoW 1.12, bank bags are -1 and 5 to 10
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
                            -- Scan all items, regardless of selection
                            local texture, itemCount = GetContainerItemInfo(bag, slot)
                            if itemCount and itemCount > 0 then
                                data["bank"][itemID] = (data["bank"][itemID] or 0) + itemCount
                            end
                        end
                    end
                end
            end
        end
    end

    -- Update the Manager window
    ConsumesManager_UpdateManagerContent()
end

function ConsumesManager_ScanPlayerMail()
    -- Ensure the MailFrame is open before scanning
    if not MailFrame or not MailFrame:IsShown() then
        return
    end

    local playerName = UnitName("player")
    local realmName = GetRealmName()
    local faction = UnitFactionGroup("player")

    -- Initialize data structures
    ConsumesManager_Data[realmName] = ConsumesManager_Data[realmName] or {}
    ConsumesManager_Data[realmName][faction] = ConsumesManager_Data[realmName][faction] or {}
    ConsumesManager_Data[realmName][faction][playerName] = ConsumesManager_Data[realmName][faction][playerName] or {}
    local data = ConsumesManager_Data[realmName][faction][playerName]
    data["mail"] = {}

    local numInboxItems = GetInboxNumItems()
    if numInboxItems and numInboxItems > 0 then
        for mailIndex = 1, numInboxItems do
            local itemName, itemTexture, itemCount, itemQuality = GetInboxItem(mailIndex)
            if itemName and itemCount and itemCount > 0 then
                -- Since GetInboxItemLink is not available in 1.12, use itemName to get itemID
                local itemID = consumablesNameToID[itemName]
                if itemID then
                    -- Scan all items, regardless of selection
                    data["mail"][itemID] = (data["mail"][itemID] or 0) + itemCount
                end
            end
        end
    end

    -- Update the Manager window
    ConsumesManager_UpdateManagerContent()
end
