-- Onload & Click Functionality -------------------------------------------------------------------------
    WindowWidth = 350

    function ConsumesManager_OnLoad(self)
        self:RegisterForDrag("LeftButton")
        self:SetScript("OnDragStart", function() ConsumesManager_OnDragStart(self) end)
        self:SetScript("OnDragStop", function() ConsumesManager_OnDragStop(self) end)
         self:SetScript("OnClick", ConsumesManager_HandleClick)
    end

    function ConsumesManager_HandleClick(self, button)
        -- Only respond to left-clicks without the Shift key pressed
        if button == "LeftButton" and not IsShiftKeyDown() then
            -- Toggle the visibility of the main frame
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


    if not ConsumesManager_Options then
        ConsumesManager_Options = {}
    end
    if not ConsumesManager_SelectedItems then
        ConsumesManager_SelectedItems = {}
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

        local isDefaultBankVisible = BankFrame and BankFrame:IsVisible()
        local isOneBankVisible = OneBankFrame and OneBankFrame:IsVisible()

        if event == "BANKFRAME_OPENED" then
            isBankOpen = true
        elseif event == "MAIL_SHOW" then
            isMailOpen = true
        elseif event == "MAIL_CLOSED" then
            isMailOpen = false
        elseif not (isDefaultBankVisible or isOneBankVisible) then
            isBankOpen = false
        end

        if event == "PLAYER_LOGIN" then


        function ConsumesManager_CheckVersionUpdate()
            -- Initialize options if needed
            ConsumesManager_Options = ConsumesManager_Options or {}
            
            -- Check if we've already shown the popup for this version
            if not ConsumesManager_Options.LastVersionReset or ConsumesManager_Options.LastVersionReset ~= GetAddOnMetadata("ConsumesManager", "Version") then
                -- Show the popup with a slight delay to ensure UI is loaded
                local delayFrame = CreateFrame("Frame")
                delayFrame:SetScript("OnUpdate", function()
                    local elapsed = 0
                    elapsed = elapsed + arg1
                    if elapsed >= 1 then
                        ConsumesManager_ShowVersionUpdatePopup()
                        delayFrame:SetScript("OnUpdate", nil)
                    end
                end)
            end
        end

        -- Find this in your existing code, typically in a function that runs when the addon loads
        local ConsumesManager_EventFrame = CreateFrame("Frame")
        ConsumesManager_EventFrame:RegisterEvent("PLAYER_LOGIN")
        ConsumesManager_EventFrame:SetScript("OnEvent", function()
            if event == "PLAYER_LOGIN" then
                -- Your existing code...
                
                -- Add this line to check for version updates
                ConsumesManager_CheckVersionUpdate()
                
                -- Continue with your existing code...
            end
        end)




            if ConsumesManager_Options and ConsumesManager_Options.Channel and ConsumesManager_Options.Password then
                local channelName = DecodeMessage(ConsumesManager_Options.Channel)
                local channelPassword = DecodeMessage(ConsumesManager_Options.Password)
                JoinChannelByName(channelName, channelPassword)
                SetChannelPassword(channelName, channelPassword)
                MultiAccountChannelAnnounce = "|cffffffff" .. GetAddOnMetadata("ConsumesManager", "Title") .. ":|r |cffffffffJoined|r |cffffc0c0[" .. channelName .. "]|r|cffffffff. Multi-account synchronization |cff00ff00enabled|r|cffffffff.|r"
                ReadData("start")
            else
                MultiAccountChannelAnnounce = "|cffffffff" .. GetAddOnMetadata("ConsumesManager", "Title") .. ":|r Multi-account synchronization |cffff0000disabled|r|cffffffff. Check the addon options for setup.|r"
                ReadData("stop")
            end

            local delayFrame = CreateFrame("Frame")
            local elapsed = 0
            local delay = 1

            delayFrame:SetScript("OnUpdate", function()
                elapsed = elapsed + arg1 -- arg1 provides the time since the last frame
                if elapsed >= delay then
                    DEFAULT_CHAT_FRAME:AddMessage("|cff00ff00" .. GetAddOnMetadata("ConsumesManager", "Title") .. "|r |cffaaaaaa(v" .. GetAddOnMetadata("ConsumesManager", "Version") .. ")|r |cffffffffLoaded!|r")
                    DEFAULT_CHAT_FRAME:AddMessage(MultiAccountChannelAnnounce)
                    delayFrame:SetScript("OnUpdate", nil) -- Stop the OnUpdate script
                end
            end)

            ConsumesManager_ScanPlayerInventory()
            ConsumesManager_ScanPlayerBank()
            ConsumesManager_ScanPlayerMail()
        elseif event == "BAG_UPDATE" then
            ConsumesManager_ScanPlayerInventory()
            if isBankOpen == true then
                ConsumesManager_ScanPlayerBank()
            end
            if isMailOpen == true then
                ConsumesManager_ScanPlayerMail()
            end
        elseif event == "BANKFRAME_OPENED" then
            ConsumesManager_ScanPlayerBank()
        elseif event == "PLAYERBANKSLOTS_CHANGED" then
            ConsumesManager_ScanPlayerBank()
            ConsumesManager_ScanPlayerInventory()
        elseif event == "ITEM_LOCK_CHANGED" then
            if isBankOpen == true then
                ConsumesManager_ScanPlayerInventory()
                ConsumesManager_ScanPlayerBank()
            end
            if isMailOpen == true then
                ConsumesManager_ScanPlayerInventory()
                ConsumesManager_ScanPlayerMail()
            end
        elseif event == "MAIL_SHOW" or event == "MAIL_INBOX_UPDATE" then
            ConsumesManager_ScanPlayerMail()
        end
    end)


-- Plugin Reset on New Version

function ConsumesManager_ShowVersionUpdatePopup()
    -- Check if a popup already exists
    if ConsumesManager_VersionUpdateFrame then
        return
    end
    
    -- Create the popup frame
    local popup = CreateFrame("Frame", "ConsumesManager_VersionUpdateFrame", UIParent)
    popup:SetWidth(400)
    popup:SetHeight(200)
    popup:SetPoint("CENTER", UIParent, "CENTER", 0, 0)
    popup:SetFrameStrata("DIALOG")
    popup:SetBackdrop({
        bgFile = "Interface\\DialogFrame\\UI-DialogBox-Background",
        edgeFile = "Interface\\DialogFrame\\UI-DialogBox-Border",
        tile = true, tileSize = 32, edgeSize = 32,
        insets = { left = 11, right = 12, top = 12, bottom = 11 }
    })
    popup:SetBackdropColor(0, 0, 0, 1)
    popup:EnableMouse(true)
    popup:SetMovable(true)
    popup:RegisterForDrag("LeftButton")
    popup:SetScript("OnDragStart", function() this:StartMoving() end)
    popup:SetScript("OnDragStop", function() this:StopMovingOrSizing() end)
    
    -- Add a title
    local title = popup:CreateFontString(nil, "OVERLAY", "GameFontNormalLarge")
    title:SetPoint("TOP", popup, "TOP", 0, -20)
    title:SetText("ConsumesManager Update " .. GetAddOnMetadata("ConsumesManager", "Version"))
    title:SetTextColor(1, 0.8, 0)
    
    -- Add a message
    local message = popup:CreateFontString(nil, "OVERLAY", "GameFontNormal")
    message:SetPoint("TOP", title, "BOTTOM", 0, -20)
    message:SetWidth(360)
    message:SetText("This version adds cross-faction support, allowing you to track and trade consumables with characters from both factions.\n\nYou need to reset the addon to update the data structure. Don't worry, your settings will be preserved!")
    message:SetJustifyH("CENTER")
    
    -- Create Reset Button
    local resetButton = CreateFrame("Button", nil, popup, "UIPanelButtonTemplate")
    resetButton:SetWidth(100)
    resetButton:SetHeight(24)
    resetButton:SetPoint("BOTTOM", popup, "BOTTOM", 0, 40)
    resetButton:SetText("Reset Now")
    resetButton:SetScript("OnClick", function()
        -- Store that we've shown this version popup
        ConsumesManager_Options = ConsumesManager_Options or {}
        ConsumesManager_Options.LastVersionReset = GetAddOnMetadata("ConsumesManager", "Version")
        
        -- Reset the addon data structures, preserving important settings
        local channelInfo = nil
        local passwordInfo = nil
        local characterOptions = nil
        local enableCategories = nil
        local showUseButton = nil
        local selectedItems = nil
        
        -- Backup important settings
        if ConsumesManager_Options then
            channelInfo = ConsumesManager_Options.Channel
            passwordInfo = ConsumesManager_Options.Password
            characterOptions = ConsumesManager_Options.Characters
            enableCategories = ConsumesManager_Options.enableCategories
            showUseButton = ConsumesManager_Options.showUseButton
        end
        
        if ConsumesManager_SelectedItems then
            selectedItems = {}
            for id, selected in pairs(ConsumesManager_SelectedItems) do
                selectedItems[id] = selected
            end
        end
        
        -- Reset data
        ConsumesManager_Data = {}
        
        -- Restore important settings
        ConsumesManager_Options = {
            Channel = channelInfo,
            Password = passwordInfo,
            Characters = characterOptions,
            enableCategories = enableCategories,
            showUseButton = showUseButton,
            LastVersionReset = GetAddOnMetadata("ConsumesManager", "Version")
        }
        
        ConsumesManager_SelectedItems = selectedItems or {}
        
        -- Close the popup
        popup:Hide()
        
        -- Reload UI
        ReloadUI()
    end)
    
    -- Create Later Button
    local laterButton = CreateFrame("Button", nil, popup, "UIPanelButtonTemplate")
    laterButton:SetWidth(100)
    laterButton:SetHeight(24)
    laterButton:SetPoint("BOTTOMLEFT", popup, "BOTTOMLEFT", 30, 40)
    laterButton:SetText("Later")
    laterButton:SetScript("OnClick", function()
        popup:Hide()
    end)
    
    -- Create Skip Button (never show again)
    local skipButton = CreateFrame("Button", nil, popup, "UIPanelButtonTemplate")
    skipButton:SetWidth(100)
    skipButton:SetHeight(24)
    skipButton:SetPoint("BOTTOMRIGHT", popup, "BOTTOMRIGHT", -30, 40)
    skipButton:SetText("Skip")
    skipButton:SetScript("OnClick", function()
        -- Store that we've shown this version popup even if they didn't reset
        ConsumesManager_Options = ConsumesManager_Options or {}
        ConsumesManager_Options.LastVersionReset = GetAddOnMetadata("ConsumesManager", "Version")
        popup:Hide()
    end)
    
    -- Close button in corner
    local closeButton = CreateFrame("Button", nil, popup, "UIPanelCloseButton")
    closeButton:SetPoint("TOPRIGHT", popup, "TOPRIGHT", -5, -5)
    closeButton:SetScript("OnClick", function()
        popup:Hide()
    end)
    
    popup:Show()
end

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

    -- Progress Bar for Syncing
    ProgressBarFrame = CreateFrame("Frame", "ConsumesManager_ProgressBar", ConsumesManager_MainFrame, BackdropTemplateMixin and "BackdropTemplate")
    ProgressBarFrame:SetWidth(20)
    ProgressBarFrame:SetHeight(496)
    ProgressBarFrame:SetPoint("TOPRIGHT", ConsumesManager_MainFrame, "TOPRIGHT", 10, -8)
    ProgressBarFrame:SetBackdrop({
        bgFile = "Interface\\Buttons\\WHITE8x8",
        edgeFile = "Interface\\Buttons\\WHITE8x8",
        edgeSize = 1,
    })
    ProgressBarFrame:SetBackdropColor(0,0,0,1)
    ProgressBarFrame:SetBackdropBorderColor(0.5,0.5,0.5,1)
    ProgressBarFrame:SetFrameLevel(ConsumesManager_MainFrame:GetFrameLevel() - 1)
    ProgressBarFrame:Hide()

    ProgressBarFrame_fill = CreateFrame("Frame", "ConsumesManager_ProgressBarFill", ProgressBarFrame, BackdropTemplateMixin and "BackdropTemplate")
    ProgressBarFrame_fill:SetWidth(17)
    ProgressBarFrame_fill:SetHeight(0)
    ProgressBarFrame_fill:SetPoint("BOTTOMLEFT", ProgressBarFrame, "BOTTOMLEFT", 1, 2)
    ProgressBarFrame_fill:SetBackdrop({
        bgFile = "Interface\\Buttons\\WHITE8x8"
    })
    ProgressBarFrame_fill:SetBackdropColor(0,0.6,0,1)
    ProgressBarFrame_fill:Hide()
    ProgressBarFrame_fill:SetFrameLevel(ProgressBarFrame:GetFrameLevel() + 1)


    ProgressBarFrame_Text = ProgressBarFrame_fill:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
    ProgressBarFrame_Text:SetText("S\n\nY\n\nN\n\nC\n\nI\n\nN\n\nG")
    ProgressBarFrame_Text:SetPoint("CENTER", ProgressBarFrame, "CENTER", 1, 0)
    ProgressBarFrame_Text:SetTextColor(1,1,1)
    ProgressBarFrame_Text:Hide()


    -- Title Text
    local titleText = ConsumesManager_MainFrame:CreateFontString(nil, "OVERLAY", "GameFontNormalLarge")
    titleText:SetText("Consumes Manager")
    titleText:SetPoint("TOP", ConsumesManager_MainFrame, "TOP", 0, -2)

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
    ConsumesManagerTooltip = CreateFrame("Frame", "ConsumesManagerTooltip", UIParent)
    ConsumesManagerTooltip:SetWidth(100)
    ConsumesManagerTooltip:SetHeight(40)
    ConsumesManagerTooltip:SetFrameStrata("TOOLTIP")
    ConsumesManagerTooltip:SetBackdrop({
        bgFile = "Interface\\Tooltips\\UI-Tooltip-Background",
        edgeFile = "Interface\\Tooltips\\UI-Tooltip-Border",
        tile = true, tileSize = 16, edgeSize = 16,
        insets = { left = 4, right = 4, top = 4, bottom = 4 }
    })
    ConsumesManagerTooltip:SetBackdropColor(0, 0, 0, 1)
    ConsumesManagerTooltip:Hide()

    -- Tooltip text
    local tooltipText = ConsumesManagerTooltip:CreateFontString(nil, "OVERLAY", "GameFontNormal")
    tooltipText:SetPoint("CENTER", ConsumesManagerTooltip, "CENTER", 0, 0)
    ConsumesManagerTooltip.text = tooltipText

    -- Tabs
    local tabs = {}
    ConsumesManager_Tabs = {}
    -- Adjusted CreateTab function
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
        tab.hoverTexture = hoverTexture  -- Store hoverTexture in tab

        -- Active Highlight
        local activeHighlight = tab:CreateTexture(nil, "OVERLAY")
        activeHighlight:SetTexture("Interface\\Buttons\\CheckButtonHilight")
        activeHighlight:SetBlendMode("ADD")
        activeHighlight:SetAllPoints(tab)
        activeHighlight:SetWidth(36)
        activeHighlight:SetHeight(36)
        activeHighlight:Hide()
        tab.activeHighlight = activeHighlight

        -- Store tooltip text
        tab.tooltipText = tooltipText

        -- Custom Tooltip Handlers
        tab:SetScript("OnEnter", function()
            ShowTooltip(tab, tab.tooltipText)
        end)
        tab:SetScript("OnLeave", HideTooltip)

        -- Initialize as enabled
        tab.isEnabled = true

        -- Store tab in global table
        ConsumesManager_Tabs[tabIndex] = tab

        return tab
    end

   

    -- Manager Tab
    local tab1 = CreateTab("ConsumesManager_MainFrameTab1", "Interface\\AddOns\\ConsumesManager\\images\\minimap_icon", 30, "Tracker", 1)
    tab1.originalOnClick = function()
        ConsumesManager_ShowTab(1)
    end
    tab1:SetScript("OnClick", tab1.originalOnClick)

    -- Items Tab
    local tab2 = CreateTab("ConsumesManager_MainFrameTab2", "Interface\\Icons\\Inv_misc_book_03", 80, "Items", 2)
    tab2.originalOnClick = function()
        ConsumesManager_ShowTab(2)
    end
    tab2:SetScript("OnClick", tab2.originalOnClick)

    -- Presets Tab
    local tab3 = CreateTab("ConsumesManager_MainFrameTab3", "Interface\\Icons\\inv_misc_note_06", 130, "Presets", 3)
    tab3.originalOnClick = function()
        ConsumesManager_ShowTab(3)
    end
    tab3:SetScript("OnClick", tab3.originalOnClick)

    -- Settings Tab
    local tab4 = CreateTab("ConsumesManager_MainFrameTab4", "Interface\\Icons\\INV_Misc_Gear_01", 180, "Settings", 4)
    tab4.originalOnClick = function()
        ConsumesManager_ShowTab(4)
    end
    tab4:SetScript("OnClick", tab4.originalOnClick)


    -- Send Data Button
    sendDataButton = CreateTab("ConsumesManager_sendDataButton", "Interface\\Icons\\inv_misc_punchcards_prismatic", 280, "Push Data", 5)
    function updateSenDataButtonState()
        if ConsumesManager_Options.Channel == nil or ConsumesManager_Options.Channel == "" or ConsumesManager_Options.Password == nil or ConsumesManager_Options.Password == "" then
            sendDataButton:Hide()
            ReadData("stop")
        else
            sendDataButton:Show()
            ReadData("start")
        end
    end
    updateSenDataButtonState()
    sendDataButton.originalOnClick = function()
        PushData()
    end
    sendDataButton:SetScript("OnClick", sendDataButton.originalOnClick)


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

    local tab4Content = CreateFrame("Frame", nil, ConsumesManager_MainFrame)
    tab4Content:SetWidth(WindowWidth - 50)
    tab4Content:SetHeight(380)
    tab4Content:SetPoint("TOPLEFT", ConsumesManager_MainFrame, "TOPLEFT", 30, -80)
    ConsumesManager_MainFrame.tabs[4] = tab4Content

    -- Footer Button to Push Database
    local footerText = ConsumesManager_MainFrame:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
    footerText:SetText("Made by Horyoshi (v" .. GetAddOnMetadata("ConsumesManager", "Version") .. ")")
    footerText:SetTextColor(0.6, 0.6, 0.6)
    footerText:SetPoint("BOTTOM", ConsumesManager_MainFrame, "BOTTOM", 0, 15)


    -- Add Grey Line Above Footer
    local footerLine = ConsumesManager_MainFrame:CreateTexture(nil, "ARTWORK")
    footerLine:SetHeight(1)
    footerLine:SetPoint("BOTTOMLEFT", ConsumesManager_MainFrame, "BOTTOMLEFT", 12, 30)
    footerLine:SetPoint("BOTTOMRIGHT", ConsumesManager_MainFrame, "BOTTOMRIGHT", -12, 30)
    footerLine:SetTexture("Interface\\Buttons\\WHITE8x8")
    footerLine:SetVertexColor(0.4, 0.4, 0.4, 1)

    -- Set Default Tab
    ConsumesManager_ShowTab(1)

    -- Add Custom Content for Tabs
    ConsumesManager_CreateManagerContent(tab1Content)
    ConsumesManager_CreateItemsContent(tab2Content)
    ConsumesManager_CreatePresetsContent(tab3Content)
    ConsumesManager_CreateSettingsContent(tab4Content)

    ConsumesManager_UpdateTabStates()
end

function ConsumesManager_ShowMainWindow()
    if not ConsumesManager_MainFrame then
        ConsumesManager_CreateMainWindow()
    end
    ConsumesManager_MainFrame:Show()
    
    -- Scan inventory when the window is opened
    ConsumesManager_ScanPlayerInventory()
    
    -- Only scan bank and mail if they are open
    if event == "BANKFRAME_OPENED" then
        ConsumesManager_ScanPlayerBank()
    end
    if event == "MAIL_SHOW" or event == "MAIL_INBOX_UPDATE" then
        ConsumesManager_ScanPlayerMail()
    end
    
    -- Update the tabs based on whether bank and mail have been scanned
    ConsumesManager_UpdateTabStates()
    
    -- Update the Manager content
    ConsumesManager_UpdateManagerContent()
    
    -- Update the Presets content
    ConsumesManager_UpdatePresetsConsumables()
    
    -- Update Settings content
    ConsumesManager_UpdateSettingsContent()
end

function ConsumesManager_ShowTab(tabIndex)
    if not ConsumesManager_MainFrame or not ConsumesManager_MainFrame.tabs then return end

    -- Check if the tab is enabled
    local tabButton = ConsumesManager_Tabs[tabIndex]
    if tabButton and not tabButton.isEnabled then
        return  -- Do not switch to disabled tabs
    end

    for i, tabContent in pairs(ConsumesManager_MainFrame.tabs) do
        if i == tabIndex then
            tabContent:Show()
            -- Set the tab button to active
            local tabButton = ConsumesManager_Tabs[i]
            if tabButton then
                tabButton:SetNormalTexture("Interface\\ItemsFrame\\UI-ItemsFrame-ActiveTab")
                tabButton.activeHighlight:Show()
            end
        else
            tabContent:Hide()
            -- Set the tab button to inactive
            local tabButton = ConsumesManager_Tabs[i]
            if tabButton then
                tabButton:SetNormalTexture("Interface\\ItemsFrame\\UI-ItemsFrame-InActiveTab")
                tabButton.activeHighlight:Hide()
            end
        end
    end
end



-- Tracker Window -----------------------------------------------------------------------------------
function ConsumesManager_CreateManagerContent(parentFrame)
    -- Initialize sort order if not set
    ConsumesManager_Options.sortOrder = ConsumesManager_Options.sortOrder or "name"
    ConsumesManager_Options.sortDirection = ConsumesManager_Options.sortDirection or "asc"


    -- Create buttons for sorting
    local orderByNameButton = CreateFrame("Button", "ConsumesManager_OrderByNameButton", parentFrame, "UIPanelButtonTemplate")
    orderByNameButton:SetWidth(100)
    orderByNameButton:SetHeight(24)
    orderByNameButton:SetText("Order by Name")
    orderByNameButton:GetFontString():SetFont("Fonts\\FRIZQT__.TTF", 10, "NORMAL")
    orderByNameButton:SetPoint("TOPLEFT", parentFrame, "TOPLEFT", 0, -5)
    orderByNameButton:SetScript("OnClick", function()
        if ConsumesManager_Options.sortOrder == "name" then
            -- Toggle sort direction
            if ConsumesManager_Options.sortDirection == "asc" then
                ConsumesManager_Options.sortDirection = "desc"
            else
                ConsumesManager_Options.sortDirection = "asc"
            end
        else
            ConsumesManager_Options.sortOrder = "name"
            ConsumesManager_Options.sortDirection = "asc"
        end
        ConsumesManager_UpdateManagerContent()
    end)

    local orderByAmountButton = CreateFrame("Button", "ConsumesManager_OrderByAmountButton", parentFrame, "UIPanelButtonTemplate")
    orderByAmountButton:SetWidth(100)
    orderByAmountButton:SetHeight(24)
    orderByAmountButton:SetText("Order by Amount")
    orderByAmountButton:GetFontString():SetFont("Fonts\\FRIZQT__.TTF", 10, "NORMAL")
    orderByAmountButton:SetPoint("LEFT", orderByNameButton, "RIGHT", 10, 0)
    orderByAmountButton:SetScript("OnClick", function()
        if ConsumesManager_Options.sortOrder == "amount" then
            -- Toggle sort direction
            if ConsumesManager_Options.sortDirection == "desc" then
                ConsumesManager_Options.sortDirection = "asc"
            else
                ConsumesManager_Options.sortDirection = "desc"
            end
        else
            ConsumesManager_Options.sortOrder = "amount"
            ConsumesManager_Options.sortDirection = "desc"
        end
        ConsumesManager_UpdateManagerContent()
    end)

    parentFrame.orderByNameButton = orderByNameButton
    parentFrame.orderByAmountButton = orderByAmountButton

    -- Initially hide the order buttons
    orderByNameButton:Hide()
    orderByAmountButton:Hide()

    -- Scroll Frame
    local scrollFrame = CreateFrame("ScrollFrame", "ConsumesManager_ManagerScrollFrame", parentFrame)
    scrollFrame:SetPoint("TOPLEFT", parentFrame, "TOPLEFT", 0, -35) -- Adjusted to be below the buttons
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

        local numItemsInCategory = 0  -- Counter for items in this category

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
            itemFrame:Hide()
            itemFrame:EnableMouse(true)  -- Enable mouse events for OnEnter and OnLeave

            -- Create the 'Use' button inside the itemFrame
            local useButton = CreateFrame("Button", "ConsumesManager_UseButton" .. index, itemFrame, "UIPanelButtonTemplate")
            useButton:SetWidth(40)
            useButton:SetHeight(16)
            useButton:SetPoint("LEFT", itemFrame, "LEFT", 0, 0)
            useButton:SetText("Use")

            -- Initially show or hide the use button based on settings
            if ConsumesManager_Options.showUseButton then
                useButton:Show()
            else
                useButton:Hide()
            end

            -- Create FontString for label
            local label = itemFrame:CreateFontString(nil, "OVERLAY", "GameFontNormal")
            if ConsumesManager_Options.showUseButton then
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
            numItemsInCategory = numItemsInCategory + 1  -- Increment item count
        end

        -- Position the category label above its items
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
    scrollBar:SetPoint("TOPRIGHT", parentFrame, "TOPRIGHT", -2, -35) -- Adjusted to be below the buttons
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

    -- Initially hide the scrollbar
    scrollBar:Hide()
end

function ConsumesManager_UpdateManagerContent()
    if not ConsumesManager_MainFrame or not ConsumesManager_MainFrame.tabs or not ConsumesManager_MainFrame.tabs[1] then
        return
    end

    local ManagerFrame = ConsumesManager_MainFrame.tabs[1]
    local realmName = GetRealmName()
    local playerName = UnitName("player")

    -- Ensure data structure exists
    if not ConsumesManager_Data[realmName] then
        ConsumesManager_Data[realmName] = {}
    end
    
    -- Hide the message label and order buttons by default
    ManagerFrame.messageLabel:Hide()
    ManagerFrame.orderByNameButton:Hide()
    ManagerFrame.orderByAmountButton:Hide()

    -- Hide all item frames and category labels
    for _, categoryInfo in ipairs(ManagerFrame.categoryInfo) do
        categoryInfo.label:Hide()
        for _, itemInfo in ipairs(categoryInfo.Items) do
            itemInfo.frame:Hide()
        end
    end

    -- Reset the scrollChild height
    ManagerFrame.scrollChild.contentHeight = 0
    ManagerFrame.scrollChild:SetHeight(0)

    -- Check if bank and mail have been scanned for current character
    local currentCharData = ConsumesManager_Data[realmName][playerName]
    local bankScanned = currentCharData and currentCharData["bank"] ~= nil
    local mailScanned = currentCharData and currentCharData["mail"] ~= nil

    if not bankScanned or not mailScanned then
        -- Show message
        ManagerFrame.messageLabel:SetText("|cffff0000This character is not scanned yet|r\n\n|cffffffffOpen your |rBank|cffffffff and |rMail|cffffffff to get started|r")
        ManagerFrame.messageLabel:Show()

        -- Update the Manager scrollbar
        ConsumesManager_UpdateManagerScrollBar()

        return
    end

    -- Proceed with normal content update
    local index = 0  -- Positioning index for items
    local hasAnyVisibleItems = false  -- Track if any items are visible
    local lineHeight = 18

    -- Get the current sort order and direction
    local sortOrder = ConsumesManager_Options.sortOrder or "name"
    local sortDirection = ConsumesManager_Options.sortDirection or "asc"

    local enableCategories = ConsumesManager_Options.enableCategories or false
    local showUseButton = ConsumesManager_Options.showUseButton or false

    -- Check if categories are enabled
    if ConsumesManager_Options.enableCategories then
        -- Iterate over categories
        for _, categoryInfo in ipairs(ManagerFrame.categoryInfo) do
            local anyItemVisible = false

            -- First, collect the enabled items and their counts
            local enabledItems = {}

            for _, itemInfo in ipairs(categoryInfo.Items) do
                local itemID = itemInfo.itemID
                if ConsumesManager_SelectedItems[itemID] then
                    -- Sum counts across all selected characters
                    local totalCount = 0
                    for character, _ in pairs(ConsumesManager_Data[realmName]) do
                        if type(ConsumesManager_Data[realmName][character]) == "table" and ConsumesManager_Options["Characters"][character] == true then
                            -- Make sure it's not a special field like "faction"
                            if character ~= "faction" then
                                local inventory = ConsumesManager_Data[realmName][character]["inventory"] and ConsumesManager_Data[realmName][character]["inventory"][itemID] or 0
                                local bank = ConsumesManager_Data[realmName][character]["bank"] and ConsumesManager_Data[realmName][character]["bank"][itemID] or 0
                                local mail = ConsumesManager_Data[realmName][character]["mail"] and ConsumesManager_Data[realmName][character]["mail"][itemID] or 0
                                totalCount = totalCount + inventory + bank + mail
                            end
                        end
                    end
                    table.insert(enabledItems, {itemInfo = itemInfo, totalCount = totalCount})
                    anyItemVisible = true
                else
                    itemInfo.frame:Hide()
                end
            end

            -- If any items are visible, handle category label
            if anyItemVisible then
                categoryInfo.label:SetPoint("TOPLEFT", ManagerFrame.scrollChild, "TOPLEFT", 0, - (index) * lineHeight)
                categoryInfo.label:Show()
                index = index + 1

                -- Sort enabled items based on sort order and direction
                if sortOrder == "name" then
                    if sortDirection == "asc" then
                        table.sort(enabledItems, function(a, b) return a.itemInfo.name < b.itemInfo.name end)
                    else
                        table.sort(enabledItems, function(a, b) return a.itemInfo.name > b.itemInfo.name end)
                    end
                elseif sortOrder == "amount" then
                    if sortDirection == "desc" then
                        table.sort(enabledItems, function(a, b) return a.totalCount > b.totalCount end)
                    else
                        table.sort(enabledItems, function(a, b) return a.totalCount < b.totalCount end)
                    end
                end

                -- Now, position and show the enabled items
                for _, itemData in ipairs(enabledItems) do
                    local itemInfo = itemData.itemInfo
                    local itemID = itemInfo.itemID
                    local itemName = itemInfo.name
                    local label = itemInfo.label
                    local button = itemInfo.button
                    local frame = itemInfo.frame
                    local totalCount = itemData.totalCount

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
                    local playerInventory = ConsumesManager_Data[realmName][playerName]["inventory"] or {}
                    local countInInventory = playerInventory[itemID] or 0

                    if ConsumesManager_Options.showUseButton then
                        button:Show()
                        if countInInventory > 0 then
                            button:Enable()
                        else
                            button:Disable()
                        end
                        label:SetPoint("LEFT", button, "RIGHT", 4, 0)
                    else
                        button:Disable()
                        button:Hide()
                        label:SetPoint("LEFT", frame, "LEFT", 0, 0)
                    end

                    -- Show and position the item frame
                    frame:SetPoint("TOPLEFT", ManagerFrame.scrollChild, "TOPLEFT", 0, - (index) * lineHeight)
                    frame:Show()
                    index = index + 1
                    hasAnyVisibleItems = true
                end

                -- Add extra spacing after the category
                index = index + 1  -- Add one extra line of spacing between categories
            else
                categoryInfo.label:Hide()
                -- Hide all items under this category
                for _, itemInfo in ipairs(categoryInfo.Items) do
                    itemInfo.frame:Hide()
                end
            end
        end
    else
        -- Categories are disabled
        -- Collect all enabled items into a single list with their counts
        local allItems = {}
        for _, categoryInfo in ipairs(ManagerFrame.categoryInfo) do
            categoryInfo.label:Hide()
            for _, itemInfo in ipairs(categoryInfo.Items) do
                local itemID = itemInfo.itemID
                if ConsumesManager_SelectedItems[itemID] then
                    -- Sum counts across all selected characters
                    local totalCount = 0
                    for character, charData in pairs(ConsumesManager_Data[realmName]) do
                        if type(charData) == "table" and ConsumesManager_Options["Characters"][character] == true then
                            if character ~= "faction" then
                                local inventory = charData["inventory"] and charData["inventory"][itemID] or 0
                                local bank = charData["bank"] and charData["bank"][itemID] or 0
                                local mail = charData["mail"] and charData["mail"][itemID] or 0
                                totalCount = totalCount + inventory + bank + mail
                            end
                        end
                    end
                    table.insert(allItems, {itemInfo = itemInfo, totalCount = totalCount})
                    hasAnyVisibleItems = true
                else
                    itemInfo.frame:Hide()
                end
            end
        end

        -- Sort allItems based on sort order and direction
        if sortOrder == "name" then
            if sortDirection == "asc" then
                table.sort(allItems, function(a, b) return a.itemInfo.name < b.itemInfo.name end)
            else
                table.sort(allItems, function(a, b) return a.itemInfo.name > b.itemInfo.name end)
            end
        elseif sortOrder == "amount" then
            if sortDirection == "desc" then
                table.sort(allItems, function(a, b) return a.totalCount > b.totalCount end)
            else
                table.sort(allItems, function(a, b) return a.totalCount < b.totalCount end)
            end
        end

        -- Display all items
        for _, itemData in ipairs(allItems) do
            local itemInfo = itemData.itemInfo
            local itemID = itemInfo.itemID
            local itemName = itemInfo.name
            local label = itemInfo.label
            local button = itemInfo.button
            local frame = itemInfo.frame
            local totalCount = itemData.totalCount

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
            local playerInventory = ConsumesManager_Data[realmName][playerName]["inventory"] or {}
            local countInInventory = playerInventory[itemID] or 0

            if showUseButton then
                button:Show()
                if countInInventory > 0 then
                    button:Enable()
                else
                    button:Disable()
                end
                label:SetPoint("LEFT", button, "RIGHT", 4, 0)
            else
                button:Disable()
                button:Hide()
                label:SetPoint("LEFT", frame, "LEFT", 0, 0)
            end

            -- Show and position the item frame
            frame:SetPoint("TOPLEFT", ManagerFrame.scrollChild, "TOPLEFT", 0, - (index) * lineHeight)
            frame:Show()
            index = index + 1
        end
    end

    -- Adjust the scroll child height
    ManagerFrame.scrollChild.contentHeight = index * lineHeight
    ManagerFrame.scrollChild:SetHeight(ManagerFrame.scrollChild.contentHeight)

    -- Update the scrollbar
    ConsumesManager_UpdateManagerScrollBar()

    if not hasAnyVisibleItems then
        -- Hide the order buttons
        ManagerFrame.orderByNameButton:Hide()
        ManagerFrame.orderByAmountButton:Hide()
        -- Show message when no items are selected
        ManagerFrame.messageLabel:SetText("|cffff0000No consumables selected|r\n\n|cffffffffClick on |rItems|cffffffff to get started|r")
        ManagerFrame.messageLabel:Show()

        -- Reset the scrollChild height
        ManagerFrame.scrollChild.contentHeight = 0
        ManagerFrame.scrollChild:SetHeight(0)

        -- Update the scrollbar
        ConsumesManager_UpdateManagerScrollBar()
    else
        -- Show the order buttons
        ManagerFrame.orderByNameButton:Show()
        ManagerFrame.orderByAmountButton:Show()
        -- Hide the message label as we have content to display
        ManagerFrame.messageLabel:Hide()
    end
end

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



-- Items Window -----------------------------------------------------------------------------------
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
                ConsumesManager_SelectedItems[currentItemID] = checkbox:GetChecked()
                ConsumesManager_UpdateManagerContent()
            end)
            -- Load saved setting
            if ConsumesManager_SelectedItems[currentItemID] then
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
            ConsumesManager_SelectedItems[itemID] = true
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
            ConsumesManager_SelectedItems[itemID] = false
        end
        ConsumesManager_UpdateManagerContent()
    end)
end

function ConsumesManager_UpdateItemsScrollBar()
    local ItemsFrame = ConsumesManager_MainFrame.tabs[2]
    if not ItemsFrame then
        print("Error: ItemsFrame (tabs[2]) is nil in UpdateItemsScrollBar")
        return
    end
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



-- Presets Window -----------------------------------------------------------------------------------

    local classColors = {
        ["Rogue"] = "fff569",
        ["Mage"] = "69ccf0",
        ["Warrior"] = "c79c6e",
        ["Hunter"] = "abd473",
        ["Druid"] = "ff7d0a",
        ["Priest"] = "ffffff",
        ["Warlock"] = "9482c9",
        ["Shaman"] = "0070dd",
        ["Paladin"] = "f58cba"
    }

    -- Manually ordered raids (adjust as needed)
    local orderedRaids = {
        "Molten Core",
        "Blackwing Lair",
        "Emerald Sanctum",
        "Temple of Ahn'Qiraj",
        "Naxxramas",
        "The Tower of Karazhan"
    }

    local function GetLastWord(str)
        local spacePos = 0
        while true do
            local found = string.find(str, " ", spacePos + 1)
            if found then
                spacePos = found
            else
                break
            end
        end
        if spacePos == 0 then
            return str
        else
            return string.sub(str, spacePos + 1)
        end
    end

    local function SortClassesByLastWord(t)
        local n = table.getn(t)
        local i = 1
        while i < n do
            local j = i + 1
            while j <= n do
                local lwA = GetLastWord(t[i])
                local lwB = GetLastWord(t[j])
                if lwA > lwB then
                    t[i], t[j] = t[j], t[i]
                end
                j = j + 1
            end
            i = i + 1
        end
    end

function ConsumesManager_CreatePresetsContent(parentFrame)
    local lineHeight = 18

    local raidDropdown = CreateFrame("Frame", "ConsumesManager_PresetsRaidDropdown", parentFrame, "UIDropDownMenuTemplate")
    raidDropdown:SetPoint("TOPLEFT", parentFrame, "TOPLEFT", -20, 0)
    UIDropDownMenu_SetWidth(120, raidDropdown)
    UIDropDownMenu_SetText("Select |cffffff00Raid|r", raidDropdown)

    local raidDropdownText = getglobal("ConsumesManager_PresetsRaidDropdownText")
    if raidDropdownText then
        raidDropdownText:SetJustifyH("LEFT")
    end

    local classDropdown = CreateFrame("Frame", "ConsumesManager_PresetsClassDropdown", parentFrame, "UIDropDownMenuTemplate")
    classDropdown:SetPoint("LEFT", raidDropdown, "RIGHT", -20, 0)
    UIDropDownMenu_SetWidth(120, classDropdown)
    UIDropDownMenu_SetText("Select |cffffff00Class|r", classDropdown)

    local classDropdownText = getglobal("ConsumesManager_PresetsClassDropdownText")
    if classDropdownText then
        classDropdownText:SetJustifyH("LEFT")
    end

    local classes = {}
    for className, _ in pairs(classPresets) do
        table.insert(classes, className)
    end

    SortClassesByLastWord(classes)

    UIDropDownMenu_Initialize(classDropdown, function()
        local idx = 1
        while classes[idx] do
            local cName = classes[idx]
            local cIndex = idx
            local info = {}
            local lastWord = GetLastWord(cName)
            local color = classColors[lastWord] or "ffffff"
            info.text = "|cff" .. color .. cName .. "|r"
            info.func = function()
                UIDropDownMenu_SetSelectedID(classDropdown, cIndex)
                ConsumesManager_SelectedClass = cName
                ConsumesManager_UpdateRaidsDropdown()
                ConsumesManager_UpdatePresetsConsumables()
            end
            UIDropDownMenu_AddButton(info)
            idx = idx + 1
        end
    end)

    -- Build initial raid list from the first class, but we won't sort them automatically
    -- We rely on our manual "orderedRaids" list
    local uniqueRaids, seen = {}, {}
    local count = 0
    local firstClass = next(classPresets)
    if firstClass then
        local classList = classPresets[firstClass]
        local i = 1
        while classList[i] do
            local rName = classList[i].raid
            if not seen[rName] then
                count = count + 1
                uniqueRaids[count] = rName
                seen[rName] = true
            end
            i = i + 1
        end
    end

    UIDropDownMenu_Initialize(raidDropdown, function()
        if count == 0 then
            local info = {}
            info.text = "No Raids Available"
            info.disabled = true
            UIDropDownMenu_AddButton(info)
            UIDropDownMenu_SetText("Select |cffffff00Raid|r", raidDropdown)
            return
        end
        local i = 1
        while orderedRaids[i] do
            local orName = orderedRaids[i]
            if seen[orName] then
                local cIndex = i
                local cRaidName = orName
                local info = {}
                info.text = orName
                info.func = function()
                    UIDropDownMenu_SetSelectedID(raidDropdown, cIndex)
                    ConsumesManager_SelectedRaid = cRaidName
                    ConsumesManager_UpdatePresetsConsumables()
                end
                UIDropDownMenu_AddButton(info)
            end
            i = i + 1
        end
        UIDropDownMenu_SetText("Select |cffffff00Raid|r", raidDropdown)
    end)

    UIDropDownMenu_SetSelectedID(raidDropdown, 0)

    local scrollFrame = CreateFrame("ScrollFrame", "ConsumesManager_PresetsScrollFrame", parentFrame)
    scrollFrame:SetPoint("TOPLEFT", classDropdown, "BOTTOMLEFT", -135, -40)
    scrollFrame:SetPoint("BOTTOMRIGHT", parentFrame, "BOTTOMRIGHT", -25, -5)
    scrollFrame:EnableMouseWheel(true)

    local scrollChild = CreateFrame("Frame", nil, scrollFrame)
    scrollChild:SetWidth(parentFrame:GetWidth() - 40)
    scrollChild:SetHeight(1)
    scrollFrame:SetScrollChild(scrollChild)
    parentFrame.scrollChild = scrollChild
    parentFrame.scrollFrame = scrollFrame

    local scrollBar = CreateFrame("Slider", "ConsumesManager_PresetsScrollBar", parentFrame)
    scrollBar:SetPoint("TOPRIGHT", parentFrame, "TOPRIGHT", -2, -35)
    scrollBar:SetPoint("BOTTOMRIGHT", parentFrame, "BOTTOMRIGHT", -2, 16)
    scrollBar:SetWidth(16)
    scrollBar:SetOrientation('VERTICAL')
    scrollBar:SetThumbTexture("Interface\\Buttons\\UI-ScrollBar-Knob")
    scrollBar:SetBackdrop({
        bgFile = "Interface\\Buttons\\UI-SliderBar-Background",
        edgeFile = "Interface\\Buttons\\UI-SliderBar-Border",
        tile = 1, tileSize = 8, edgeSize = 8,
        insets = { left = 3, right = 3, top = 3, bottom = 3 }
    })
    scrollBar:SetScript("OnValueChanged", function()
        local val = this:GetValue()
        parentFrame.scrollFrame:SetVerticalScroll(val)
    end)
    parentFrame.scrollBar = scrollBar
    scrollBar:Hide()

    scrollFrame:SetScript("OnMouseWheel", function()
        local d = arg1
        local cur = this:GetVerticalScroll()
        local mx = this.range or 0
        local new = 0
        if d < 0 then
            new = math.min(cur + 20, mx)
        else
            new = math.max(cur - 20, 0)
        end
        this:SetVerticalScroll(new)
        parentFrame.scrollBar:SetValue(new)
    end)

    local orderByNameButton = CreateFrame("Button", "ConsumesManager_PresetsOrderByNameButton", parentFrame, "UIPanelButtonTemplate")
    orderByNameButton:SetWidth(100)
    orderByNameButton:SetHeight(24)
    orderByNameButton:SetText("Order by Name")
    orderByNameButton:GetFontString():SetFont("Fonts\\FRIZQT__.TTF", 10, "NORMAL")
    orderByNameButton:SetPoint("TOPLEFT", ConsumesManager_MainFrame.tabs[3], "TOPLEFT", -4, -35)
    orderByNameButton:SetScript("OnClick", function()
        if ConsumesManager_Options.presetsSortOrder == "name" then
            if ConsumesManager_Options.presetsSortDirection == "asc" then
                ConsumesManager_Options.presetsSortDirection = "desc"
            else
                ConsumesManager_Options.presetsSortDirection = "asc"
            end
        else
            ConsumesManager_Options.presetsSortOrder = "name"
            ConsumesManager_Options.presetsSortDirection = "asc"
        end
        ConsumesManager_UpdatePresetsConsumables()
    end)

    local orderByAmountButton = CreateFrame("Button", "ConsumesManager_PresetsOrderByAmountButton", parentFrame, "UIPanelButtonTemplate")
    orderByAmountButton:SetWidth(120)
    orderByAmountButton:SetHeight(24)
    orderByAmountButton:SetText("Order by Amount")
    orderByAmountButton:GetFontString():SetFont("Fonts\\FRIZQT__.TTF", 10, "NORMAL")
    orderByAmountButton:SetPoint("LEFT", orderByNameButton, "RIGHT", 10, 0)
    orderByAmountButton:SetScript("OnClick", function()
        if ConsumesManager_Options.presetsSortOrder == "amount" then
            if ConsumesManager_Options.presetsSortDirection == "desc" then
                ConsumesManager_Options.presetsSortDirection = "asc"
            else
                ConsumesManager_Options.presetsSortDirection = "desc"
            end
        else
            ConsumesManager_Options.presetsSortOrder = "amount"
            ConsumesManager_Options.presetsSortDirection = "desc"
        end
        ConsumesManager_UpdatePresetsConsumables()
    end)

    parentFrame.orderByNameButton = orderByNameButton
    parentFrame.orderByAmountButton = orderByAmountButton
    orderByNameButton:Hide()
    orderByAmountButton:Hide()

    parentFrame.presetsConsumables = {}
    local messageLabel = parentFrame:CreateFontString(nil, "OVERLAY", "GameFontNormal")
    messageLabel:SetText("|cffff0000Please select both a Raid and a Class.|r")
    messageLabel:SetPoint("CENTER", parentFrame, "CENTER", 0, 0)
    messageLabel:Hide()
    parentFrame.messageLabel = messageLabel
end

function ConsumesManager_UpdateRaidsDropdown()
    local raidDropdown = getglobal("ConsumesManager_PresetsRaidDropdown")
    if not raidDropdown then
        return
    end
    local prevRaid = ConsumesManager_SelectedRaid
    UIDropDownMenu_ClearAll(raidDropdown)

    local uniqueRaids, seen = {}, {}
    local c = 0
    if ConsumesManager_SelectedClass and classPresets[ConsumesManager_SelectedClass] then
        local clList = classPresets[ConsumesManager_SelectedClass]
        local i = 1
        while clList[i] do
            local rName = clList[i].raid
            if not seen[rName] then
                c = c + 1
                uniqueRaids[c] = rName
                seen[rName] = true
            end
            i = i + 1
        end
    end

    UIDropDownMenu_Initialize(raidDropdown, function()
        if c == 0 then
            local info = {}
            info.text = "No Raids Available"
            info.disabled = 1
            UIDropDownMenu_AddButton(info)
            UIDropDownMenu_SetText("Select |cffffff00Raid|r", raidDropdown)
            return
        end
        local i = 1
        local selectedIndex = 0
        while orderedRaids[i] do
            local raidName = orderedRaids[i]
            if seen[raidName] then
                local currentIndex = i
                local currentRaidName = raidName
                local info = {}
                info.text = raidName
                info.func = function()
                    UIDropDownMenu_SetSelectedID(raidDropdown, currentIndex)
                    ConsumesManager_SelectedRaid = currentRaidName
                    ConsumesManager_UpdatePresetsConsumables()
                end
                UIDropDownMenu_AddButton(info)
                if raidName == prevRaid then
                    selectedIndex = i
                end
            end
            i = i + 1
        end
        if selectedIndex > 0 then
            UIDropDownMenu_SetSelectedID(raidDropdown, selectedIndex)
        else
            UIDropDownMenu_SetSelectedID(raidDropdown, 0)
            UIDropDownMenu_SetText("Select |cffffff00Raid|r", raidDropdown)
            ConsumesManager_SelectedRaid = nil
        end
    end)
end


function ConsumesManager_UpdatePresetsScrollBar()
    local PresetsFrame = ConsumesManager_MainFrame.tabs[3]
    if not PresetsFrame then
        return
    end

    local scrollFrame = PresetsFrame.scrollFrame
    local scrollChild = PresetsFrame.scrollChild
    local scrollBar = PresetsFrame.scrollBar

    if not scrollFrame or not scrollChild or not scrollBar then
        return
    end

    local totalHeight = scrollChild:GetHeight()
    local shownHeight = PresetsFrame:GetHeight() - 20  -- Account for padding/margins

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

function ConsumesManager_UpdatePresetsConsumables()
    -- References to necessary frames
    local parentFrame = ConsumesManager_MainFrame and ConsumesManager_MainFrame.tabs and ConsumesManager_MainFrame.tabs[3]
    if not parentFrame then
        -- Presets tab is not initialized yet
        return
    end

    local scrollChild = parentFrame.scrollChild
    local scrollFrame = parentFrame.scrollFrame
    local scrollBar = parentFrame.scrollBar

    -- Initialize presetsConsumables table if not already
    if not parentFrame.presetsConsumables then
        parentFrame.presetsConsumables = {}
    end

    -- Function to get the number of elements in a table
    local function GetTableLength(t)
        local count = 0
        if type(t) == "table" then
            for _ in pairs(t) do
                count = count + 1
            end
        end
        return count
    end

    -- Clear existing consumables
    local consumablesCount = GetTableLength(parentFrame.presetsConsumables)
    for i = 1, consumablesCount do
        local consumable = parentFrame.presetsConsumables[i]
        if consumable and consumable.frame and consumable.frame.Hide then
            consumable.frame:Hide()
        end
    end
    parentFrame.presetsConsumables = {}

    -- Hide "No items" message if it exists
    if parentFrame.noItemsMessage then
        parentFrame.noItemsMessage:Hide()
    end

    -- Check if both Raid and Class are selected
    if not ConsumesManager_SelectedRaid or not ConsumesManager_SelectedClass then
        -- Show a message prompting the user to select both
        parentFrame.messageLabel:SetText("|cffffffffSelect both a |rRaid|cffffffff and a |rClass|cffffffff.|r")
        parentFrame.messageLabel:Show()
        parentFrame.orderByNameButton:Hide()
        parentFrame.orderByAmountButton:Hide()
        return
    else
        parentFrame.messageLabel:Hide()
    end

    -- Retrieve the selected preset based on Class and Raid
    local selectedPreset = nil
    if classPresets and classPresets[ConsumesManager_SelectedClass] and type(classPresets[ConsumesManager_SelectedClass]) == "table" then
        local presetListLength = GetTableLength(classPresets[ConsumesManager_SelectedClass])
        for i = 1, presetListLength do
            local preset = classPresets[ConsumesManager_SelectedClass][i]
            if preset and preset.raid == ConsumesManager_SelectedRaid then
                selectedPreset = preset
                break
            end
        end
    end

    -- Handle case where no preset is found
    if not selectedPreset then
        parentFrame.messageLabel:SetText("|cffff0000No presets found for this combination.|r")
        parentFrame.messageLabel:Show()
        parentFrame.orderByNameButton:Hide()
        parentFrame.orderByAmountButton:Hide()
        return
    end

    -- Get the consumable IDs from selectedPreset
    local presetIDs = selectedPreset.id
    if not presetIDs or type(presetIDs) ~= "table" then
        parentFrame.messageLabel:SetText("|cffff0000Invalid preset data.|r")
        parentFrame.messageLabel:Show()
        parentFrame.orderByNameButton:Hide()
        parentFrame.orderByAmountButton:Hide()
        return
    end

    -- Ensure data structure exists
    local realmName = GetRealmName()
    local playerName = UnitName("player")

    -- Populate the consumables list based on presetIDs
    -- Initialize tables
    local consumablesList = {}
    local consumablesNameToID = {}
    local consumablesTexture = {}
    local consumablesDescription = {}

    -- Populate consumablesList and other lookup tables
    for categoryName, consumables in pairs(consumablesCategories) do
        for _, consumable in ipairs(consumables) do
            consumablesList[consumable.id] = consumable.name
            consumablesNameToID[consumable.name] = consumable.id
            consumablesTexture[consumable.id] = consumable.texture
            consumablesDescription[consumable.id] = consumable.description
        end
    end

    -- Create a mapping from consumable ID to category name
    local consumablesIDToCategory = {}
    for categoryName, consumables in pairs(consumablesCategories) do
        for _, consumable in ipairs(consumables) do
            consumablesIDToCategory[consumable.id] = categoryName
        end
    end

    -- Main loop to gather consumables to show
    local consumablesToShow = {}
    local presetIDsLength = GetTableLength(presetIDs)
    for i = 1, presetIDsLength do
        local id = presetIDs[i]
        if id and consumablesList[id] then
            -- Calculate total count across selected characters
            local totalCount = 0
            if ConsumesManager_Data[realmName] and ConsumesManager_SelectedItems and ConsumesManager_Options.Characters and type(ConsumesManager_Options.Characters) == "table" then
                for character, isSelected in pairs(ConsumesManager_Options.Characters) do
                    if isSelected and ConsumesManager_Data[realmName][character] and type(ConsumesManager_Data[realmName][character]) == "table" then
                        local charInventory = ConsumesManager_Data[realmName][character].inventory or {}
                        local charBank = ConsumesManager_Data[realmName][character].bank or {}
                        local charMail = ConsumesManager_Data[realmName][character].mail or {}
                        totalCount = totalCount + (charInventory[id] or 0) + (charBank[id] or 0) + (charMail[id] or 0)
                    end
                end
            end

            -- Assign category using the mapping table
            local category = consumablesIDToCategory[id] or "Uncategorized"

            -- Insert consumable with additional data
            table.insert(consumablesToShow, {
                id = id,
                name = consumablesList[id],
                texture = consumablesTexture[id],
                description = consumablesDescription[id],
                totalCount = totalCount,
                category = category
            })
        else
            -- Optional: Handle the else case if needed
        end
    end

    -- Apply sorting based on settings
    local sortOrder = ConsumesManager_Options.presetsSortOrder or "name"
    local sortDirection = ConsumesManager_Options.presetsSortDirection or "asc"

    -- Sorting function
    local function SortConsumables(a, b)
        if sortOrder == "name" then
            if sortDirection == "asc" then
                return a.name < b.name
            else
                return a.name > b.name
            end
        elseif sortOrder == "amount" then
            if sortDirection == "asc" then
                return a.totalCount < b.totalCount
            else
                return a.totalCount > b.totalCount
            end
        else
            -- Default to name ascending
            return a.name < b.name
        end
    end

    -- Sort consumablesToShow
    if table and table.sort then
        table.sort(consumablesToShow, SortConsumables)
    else
        -- Implement a simple bubble sort if table.sort is unavailable
        local n = GetTableLength(consumablesToShow)
        for i = 1, n - 1 do
            for j = 1, n - i do
                if not SortConsumables(consumablesToShow[j], consumablesToShow[j + 1]) then
                    -- Swap
                    consumablesToShow[j], consumablesToShow[j + 1] = consumablesToShow[j + 1], consumablesToShow[j]
                end
            end
        end
    end

    -- Initialize variables for display
    local index = 0
    local lineHeight = 18
    local hasAnyVisibleItems = false

    -- Get settings
    local enableCategories = ConsumesManager_Options.enableCategories or false
    local showUseButton = ConsumesManager_Options.showUseButton or false

    if enableCategories then
        -- Group consumables by category
        local categories = {}
        local consumablesToShowLength = GetTableLength(consumablesToShow)
        for i = 1, consumablesToShowLength do
            local consumable = consumablesToShow[i]
            local category = consumable.category or "Uncategorized"
            if not categories[category] then
                categories[category] = {}
            end
            table.insert(categories[category], consumable)
        end

        -- Sort category names alphabetically
        local sortedCategoryNames = {}
        for categoryName in pairs(categories) do
            table.insert(sortedCategoryNames, categoryName)
        end
        if table and table.sort then
            table.sort(sortedCategoryNames)
        else
            -- Simple bubble sort if table.sort is unavailable
            local n = GetTableLength(sortedCategoryNames)
            for i = 1, n - 1 do
                for j = 1, n - i do
                    if sortedCategoryNames[j] > sortedCategoryNames[j + 1] then
                        sortedCategoryNames[j], sortedCategoryNames[j + 1] = sortedCategoryNames[j + 1], sortedCategoryNames[j]
                    end
                end
            end
        end

        -- Iterate over each category
        local sortedCategoryNamesLength = GetTableLength(sortedCategoryNames)
        for i = 1, sortedCategoryNamesLength do
            local categoryName = sortedCategoryNames[i]
            local items = categories[categoryName]

            if items and GetTableLength(items) > 0 then
                -- Create and display category label
                index = index + 1
                local categoryFrame = CreateFrame("Frame", "ConsumesManager_CategoryFrame" .. index, scrollChild)
                categoryFrame:SetWidth(scrollChild:GetWidth() - 10)
                categoryFrame:SetHeight(lineHeight)
                categoryFrame:SetPoint("TOPLEFT", scrollChild, "TOPLEFT", 0, - ((index - 1) * lineHeight))
                categoryFrame:Show()

                local categoryLabel = categoryFrame:CreateFontString(nil, "OVERLAY", "GameFontNormalLarge")
                categoryLabel:SetPoint("LEFT", categoryFrame, "LEFT", 0, 0)
                categoryLabel:SetText(categoryName)
                categoryLabel:SetJustifyH("LEFT")
                categoryLabel:SetTextColor(1, 1, 1)


                -- Store the category frame
                table.insert(parentFrame.presetsConsumables, {
                    frame = categoryFrame,
                    label = categoryLabel,
                    isCategory = true
                })

                -- Increment index for items under the category
                index = index + 1

                -- Sort items within the category
                if table and table.sort then
                    table.sort(items, SortConsumables)
                else
                    -- Simple bubble sort if table.sort is unavailable
                    local m = GetTableLength(items)
                    for p = 1, m - 1 do
                        for q = 1, m - p do
                            if not SortConsumables(items[q], items[q + 1]) then
                                items[q], items[q + 1] = items[q + 1], items[q]
                            end
                        end
                    end
                end

                -- Iterate through each consumable in the category
                local itemsLength = GetTableLength(items)
                for j = 1, itemsLength do
                    local consumable = items[j]
                    if consumable then
                        -- Create consumable frame
                        local frame = CreateFrame("Frame", "ConsumesManager_PresetsConsumableFrame" .. index, scrollChild)
                        frame:SetWidth(scrollChild:GetWidth() - 10)
                        frame:SetHeight(lineHeight)
                        frame:SetPoint("TOPLEFT", scrollChild, "TOPLEFT", 0, - ((index - 1) * lineHeight))
                        frame:Show()
                        frame:EnableMouse(true)  -- Enable mouse for tooltip

                        -- Create "Use" button if enabled
                        local useButton = nil
                        if showUseButton then
                            useButton = CreateFrame("Button", "ConsumesManager_PresetsUseButton" .. index, frame, "UIPanelButtonTemplate")
                            useButton:SetWidth(40)
                            useButton:SetHeight(16)
                            useButton:SetPoint("LEFT", frame, "LEFT", 0, 0)
                            useButton:SetText("Use")
                            useButton:SetScript("OnClick", function()
                                local bag, slot = ConsumesManager_FindItemInBags(consumable.id)
                                if bag and slot then
                                    UseContainerItem(bag, slot)
                                else
                                    DEFAULT_CHAT_FRAME:AddMessage("Item not found in bags.")
                                end
                            end)
                        end

                        -- Create label with count
                        local label = frame:CreateFontString(nil, "OVERLAY", "GameFontNormal")
                        if showUseButton and useButton then
                            label:SetPoint("LEFT", useButton, "RIGHT", 4, 0)
                        else
                            label:SetPoint("LEFT", frame, "LEFT", 0, 0)
                        end
                        label:SetText(consumable.name .. " (" .. consumable.totalCount .. ")")
                        label:SetJustifyH("LEFT")

                        -- Adjust label color based on count
                        if consumable.totalCount == 0 then
                            label:SetTextColor(1, 0, 0) -- Red
                        elseif consumable.totalCount < 10 then
                            label:SetTextColor(1, 0.4, 0) -- Orange
                        elseif consumable.totalCount <= 20 then
                            label:SetTextColor(1, 0.85, 0) -- Yellow
                        else
                            label:SetTextColor(0, 1, 0) -- Green
                        end

                        -- Tooltip handling
                        frame:SetScript("OnEnter", function()
                            ConsumesManager_ShowConsumableTooltip(consumable.id)
                        end)
                        frame:SetScript("OnLeave", function()
                            if ConsumesManager_CustomTooltip and ConsumesManager_CustomTooltip.Hide then
                                ConsumesManager_CustomTooltip:Hide()
                            end
                        end)

                        -- Enable or disable "Use" button based on inventory
                        if useButton then
                            local playerInventory = (ConsumesManager_Data[realmName] and 
                                                   ConsumesManager_Data[realmName][playerName] and 
                                                   ConsumesManager_Data[realmName][playerName].inventory) or {}
                            local countInInventory = playerInventory[consumable.id] or 0

                            if countInInventory > 0 then
                                useButton:Enable()
                            else
                                useButton:Disable()
                            end
                        end

                        -- Store the consumable frame
                        table.insert(parentFrame.presetsConsumables, {
                            frame = frame,
                            label = label,
                            useButton = useButton,
                            id = consumable.id
                        })

                        index = index + 1
                        hasAnyVisibleItems = true
                    end
                end
                
            end
        end
    else
        -- Categories are disabled; display all consumables in a single list
        local consumablesToShowLength = GetTableLength(consumablesToShow)
        for i = 1, consumablesToShowLength do
            local consumable = consumablesToShow[i]
            if consumable then
                -- Create consumable frame
                index = index + 1

                local frame = CreateFrame("Frame", "ConsumesManager_PresetsConsumableFrame" .. index, scrollChild)
                frame:SetWidth(scrollChild:GetWidth() - 10)
                frame:SetHeight(lineHeight)
                frame:SetPoint("TOPLEFT", scrollChild, "TOPLEFT", 5, - ((index - 1) * lineHeight))
                frame:Show()
                frame:EnableMouse(true)  -- Enable mouse for tooltip

                -- Create "Use" button if enabled
                local useButton = nil
                if showUseButton then
                    useButton = CreateFrame("Button", "ConsumesManager_PresetsUseButton" .. index, frame, "UIPanelButtonTemplate")
                    useButton:SetWidth(40)
                    useButton:SetHeight(16)
                    useButton:SetPoint("LEFT", frame, "LEFT", 0, 0)
                    useButton:SetText("Use")
                    useButton:SetScript("OnClick", function()
                        local bag, slot = ConsumesManager_FindItemInBags(consumable.id)
                        if bag and slot then
                            UseContainerItem(bag, slot)
                        else
                            DEFAULT_CHAT_FRAME:AddMessage("Item not found in bags.")
                        end
                    end)
                end

                -- Create label with count
                local label = frame:CreateFontString(nil, "OVERLAY", "GameFontNormal")
                if showUseButton and useButton then
                    label:SetPoint("LEFT", useButton, "RIGHT", 4, 0)
                else
                    label:SetPoint("LEFT", frame, "LEFT", 0, 0)
                end
                label:SetText(consumable.name .. " (" .. consumable.totalCount .. ")")
                label:SetJustifyH("LEFT")

                -- Adjust label color based on count
                if consumable.totalCount == 0 then
                    label:SetTextColor(1, 0, 0) -- Red
                elseif consumable.totalCount < 10 then
                    label:SetTextColor(1, 0.4, 0) -- Orange
                elseif consumable.totalCount <= 20 then
                    label:SetTextColor(1, 0.85, 0) -- Yellow
                else
                    label:SetTextColor(0, 1, 0) -- Green
                end

                -- Tooltip handling
                frame:SetScript("OnEnter", function()
                    ConsumesManager_ShowConsumableTooltip(consumable.id)
                end)
                frame:SetScript("OnLeave", function()
                    if ConsumesManager_CustomTooltip and ConsumesManager_CustomTooltip.Hide then
                        ConsumesManager_CustomTooltip:Hide()
                    end
                end)

                -- Enable or disable "Use" button based on inventory
                if useButton then
                    local playerInventory = (ConsumesManager_Data[realmName] and 
                                           ConsumesManager_Data[realmName][playerName] and 
                                           ConsumesManager_Data[realmName][playerName].inventory) or {}
                    local countInInventory = playerInventory[consumable.id] or 0

                    if countInInventory > 0 then
                        useButton:Enable()
                    else
                        useButton:Disable()
                    end
                end

                -- Store the consumable frame
                table.insert(parentFrame.presetsConsumables, {
                    frame = frame,
                    label = label,
                    useButton = useButton,
                    id = consumable.id
                })

               
                hasAnyVisibleItems = true
            end
        end
    end

    -- Adjust the scroll child height based on the number of items
    scrollChild:SetHeight(index * lineHeight + 40)

    -- Show sorting order buttons
    parentFrame.orderByNameButton:Show()
    parentFrame.orderByAmountButton:Show()

    -- Update the scrollbar to reflect new content
    ConsumesManager_UpdatePresetsScrollBar()

    -- Handle the case where no consumables are visible
    if not hasAnyVisibleItems then
        -- Create and show a "No consumables available" message if it doesn't exist
        if not parentFrame.noItemsMessage then
            parentFrame.noItemsMessage = parentFrame.messageLabel
            
            parentFrame.noItemsMessage:SetText("|cffff0000This preset is not available yet.|r")

            parentFrame.orderByNameButton:Hide()
            parentFrame.orderByAmountButton:Hide()


        end
        parentFrame.noItemsMessage:Show()
    else
        -- Hide the message if it exists
        if parentFrame.noItemsMessage then
            parentFrame.noItemsMessage:Hide()
        end

    end
end

function ConsumesManager_IsItemInPresets(itemID)
    for className, presets in pairs(classPresets) do
        for _, preset in ipairs(presets) do
            for _, id in ipairs(preset.id) do
                if id == itemID then
                    return true
                end
            end
        end
    end
    return false
end



-- Settings Window -----------------------------------------------------------------------------------
function ConsumesManager_CreateSettingsContent(parentFrame)
    -- Scroll Frame Setup
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

    local scrollChild = CreateFrame("Frame", nil, scrollFrame)
    scrollChild:SetWidth(WindowWidth - 10)
    scrollChild:SetHeight(1)
    scrollFrame:SetScrollChild(scrollChild)
    parentFrame.scrollChild = scrollChild
    parentFrame.scrollFrame = scrollFrame

    parentFrame.checkboxes = {}
    local index = 0
    local lineHeight = 20

    ConsumesManager_Options["Characters"] = ConsumesManager_Options["Characters"] or {}
    ConsumesManager_Options.enableCategories = (ConsumesManager_Options.enableCategories == nil) and true or ConsumesManager_Options.enableCategories
    ConsumesManager_Options.showUseButton = (ConsumesManager_Options.showUseButton == nil) and true or ConsumesManager_Options.showUseButton

    local realmName = GetRealmName()
    local playerName = UnitName("player")
    local playerFaction = UnitFactionGroup("player")

    -- Build character list with faction info
    local characterList = {}
    if ConsumesManager_Data[realmName] then
        for characterName, charData in pairs(ConsumesManager_Data[realmName]) do
            if type(charData) == "table" then
                table.insert(characterList, {
                    name = characterName,
                    faction = charData.faction or "Unknown"
                })
            end
        end
    end

    local playerInList = false
    for _, charInfo in ipairs(characterList) do
        if charInfo.name == playerName then
            playerInList = true
            break
        end
    end
    if not playerInList then
        table.insert(characterList, {
            name = playerName,
            faction = playerFaction
        })
    end

    -- Create faction-specific character lists
    local allianceCharacters = {}
    local hordeCharacters = {}
    
    for _, charInfo in ipairs(characterList) do
        if charInfo.faction == "Alliance" then
            table.insert(allianceCharacters, charInfo)
        elseif charInfo.faction == "Horde" then
            table.insert(hordeCharacters, charInfo)
        else
            -- For characters with unknown faction, add to both lists
            table.insert(allianceCharacters, charInfo)
            table.insert(hordeCharacters, charInfo)
        end
    end
    
    -- Sort characters by name
    table.sort(allianceCharacters, function(a, b) return a.name < b.name end)
    table.sort(hordeCharacters, function(a, b) return a.name < b.name end)

    -- Title
    local title = scrollChild:CreateFontString(nil, "OVERLAY", "GameFontNormalLarge")
    title:SetPoint("TOPLEFT", scrollChild, "TOPLEFT", 0, 0)
    title:SetText("Select Characters To Track")
    title:SetTextColor(1, 1, 1)

    local startYOffset = -20
    local currentYOffset = startYOffset

    -- Track whether we have characters from each faction
    local hasAlliance = table.getn(allianceCharacters) > 0
    local hasHorde = table.getn(hordeCharacters) > 0

    -- First add Alliance section if there are Alliance characters
    if hasAlliance then
        -- Alliance Header
        local allianceHeader = scrollChild:CreateFontString(nil, "OVERLAY", "GameFontNormal")
        allianceHeader:SetPoint("TOPLEFT", scrollChild, "TOPLEFT", 0, currentYOffset)
        allianceHeader:SetText("|cff0078ffAlliance Characters:|r")
        allianceHeader:SetJustifyH("LEFT")
        currentYOffset = currentYOffset - lineHeight

        -- Alliance Characters
        for i, charInfo in ipairs(allianceCharacters) do
            local currentCharacterName = charInfo.name
            
            local itemFrame = CreateFrame("Frame", "ConsumesManager_AllianceCharFrame" .. i, scrollChild)
            itemFrame:SetWidth(WindowWidth - 10)
            itemFrame:SetHeight(18)
            itemFrame:SetPoint("TOPLEFT", scrollChild, "TOPLEFT", 20, currentYOffset)

            local checkbox = CreateFrame("CheckButton", "ConsumesManager_AllianceCharCheckbox" .. i, itemFrame)
            checkbox:SetWidth(16)
            checkbox:SetHeight(16)
            checkbox:SetPoint("LEFT", itemFrame, "LEFT", 0, 0)

            checkbox:SetNormalTexture("Interface\\Buttons\\UI-CheckBox-Up")
            checkbox:SetPushedTexture("Interface\\Buttons\\UI-CheckBox-Down")
            checkbox:SetHighlightTexture("Interface\\Buttons\\UI-CheckBox-Highlight")
            checkbox:SetCheckedTexture("Interface\\Buttons\\UI-CheckBox-Check")

            local label = itemFrame:CreateFontString(nil, "OVERLAY", "GameFontNormal")
            label:SetPoint("LEFT", checkbox, "RIGHT", 4, 0)
            label:SetText(currentCharacterName)
            label:SetTextColor(0, 0.48, 1) -- Blue for Alliance
            label:SetJustifyH("LEFT")

            checkbox:SetScript("OnClick", function()
                ConsumesManager_Options["Characters"][currentCharacterName] = (checkbox:GetChecked() == 1)
                ConsumesManager_UpdateAllContent()
            end)

            if ConsumesManager_Options["Characters"][currentCharacterName] == nil then
                checkbox:SetChecked(true)
                ConsumesManager_Options["Characters"][currentCharacterName] = true
            else
                checkbox:SetChecked(ConsumesManager_Options["Characters"][currentCharacterName] == true)
            end

            parentFrame.checkboxes[currentCharacterName] = checkbox
            itemFrame:EnableMouse(true)
            itemFrame:SetScript("OnMouseDown", function()
                checkbox:Click()
            end)
            
            currentYOffset = currentYOffset - lineHeight
            index = index + 1
        end
        
        -- Add extra spacing after Alliance section
        currentYOffset = currentYOffset - lineHeight / 2
    end

    -- Then add Horde section if there are Horde characters
    if hasHorde then
        -- Horde Header
        local hordeHeader = scrollChild:CreateFontString(nil, "OVERLAY", "GameFontNormal")
        hordeHeader:SetPoint("TOPLEFT", scrollChild, "TOPLEFT", 0, currentYOffset)
        hordeHeader:SetText("|cffb30000Horde Characters:|r")
        hordeHeader:SetJustifyH("LEFT")
        currentYOffset = currentYOffset - lineHeight

        -- Horde Characters
        for i, charInfo in ipairs(hordeCharacters) do
            local currentCharacterName = charInfo.name
            
            local itemFrame = CreateFrame("Frame", "ConsumesManager_HordeCharFrame" .. i, scrollChild)
            itemFrame:SetWidth(WindowWidth - 10)
            itemFrame:SetHeight(18)
            itemFrame:SetPoint("TOPLEFT", scrollChild, "TOPLEFT", 20, currentYOffset)

            local checkbox = CreateFrame("CheckButton", "ConsumesManager_HordeCharCheckbox" .. i, itemFrame)
            checkbox:SetWidth(16)
            checkbox:SetHeight(16)
            checkbox:SetPoint("LEFT", itemFrame, "LEFT", 0, 0)

            checkbox:SetNormalTexture("Interface\\Buttons\\UI-CheckBox-Up")
            checkbox:SetPushedTexture("Interface\\Buttons\\UI-CheckBox-Down")
            checkbox:SetHighlightTexture("Interface\\Buttons\\UI-CheckBox-Highlight")
            checkbox:SetCheckedTexture("Interface\\Buttons\\UI-CheckBox-Check")

            local label = itemFrame:CreateFontString(nil, "OVERLAY", "GameFontNormal")
            label:SetPoint("LEFT", checkbox, "RIGHT", 4, 0)
            label:SetText(currentCharacterName)
            label:SetTextColor(0.7, 0, 0) -- Red for Horde
            label:SetJustifyH("LEFT")

            checkbox:SetScript("OnClick", function()
                ConsumesManager_Options["Characters"][currentCharacterName] = (checkbox:GetChecked() == 1)
                ConsumesManager_UpdateAllContent()
            end)

            if ConsumesManager_Options["Characters"][currentCharacterName] == nil then
                checkbox:SetChecked(true)
                ConsumesManager_Options["Characters"][currentCharacterName] = true
            else
                checkbox:SetChecked(ConsumesManager_Options["Characters"][currentCharacterName] == true)
            end

            parentFrame.checkboxes[currentCharacterName] = checkbox
            itemFrame:EnableMouse(true)
            itemFrame:SetScript("OnMouseDown", function()
                checkbox:Click()
            end)
            
            currentYOffset = currentYOffset - lineHeight
            index = index + 1
        end
        
        -- Add extra spacing after Horde section
        currentYOffset = currentYOffset - lineHeight / 2
    end

    -- Ensure we have a good spacing after character lists
    currentYOffset = currentYOffset - lineHeight / 2

    -- General Settings Title
    local generalSettingsTitle = scrollChild:CreateFontString(nil, "OVERLAY", "GameFontNormalLarge")
    generalSettingsTitle:SetPoint("TOPLEFT", scrollChild, "TOPLEFT", 0, currentYOffset)
    generalSettingsTitle:SetText("General Settings")
    generalSettingsTitle:SetTextColor(1, 1, 1)
    currentYOffset = currentYOffset - lineHeight

    -- Enable Categories Checkbox
    local enableCategoriesFrame = CreateFrame("Frame", "ConsumesManager_EnableCategoriesFrame", scrollChild)
    enableCategoriesFrame:SetWidth(WindowWidth - 10)
    enableCategoriesFrame:SetHeight(18)
    enableCategoriesFrame:SetPoint("TOPLEFT", scrollChild, "TOPLEFT", 0, currentYOffset)
    enableCategoriesFrame:EnableMouse(true)

    local enableCategoriesCheckbox = CreateFrame("CheckButton", "ConsumesManager_EnableCategoriesCheckbox", enableCategoriesFrame)
    enableCategoriesCheckbox:SetWidth(16)
    enableCategoriesCheckbox:SetHeight(16)
    enableCategoriesCheckbox:SetPoint("LEFT", enableCategoriesFrame, "LEFT", 0, 0)
    enableCategoriesCheckbox:SetNormalTexture("Interface\\Buttons\\UI-CheckBox-Up")
    enableCategoriesCheckbox:SetPushedTexture("Interface\\Buttons\\UI-CheckBox-Down")
    enableCategoriesCheckbox:SetHighlightTexture("Interface\\Buttons\\UI-CheckBox-Highlight")
    enableCategoriesCheckbox:SetCheckedTexture("Interface\\Buttons\\UI-CheckBox-Check")
    enableCategoriesCheckbox:SetChecked(ConsumesManager_Options.enableCategories)

    enableCategoriesCheckbox:SetScript("OnClick", function()
        if enableCategoriesCheckbox:GetChecked() then
            ConsumesManager_Options.enableCategories = true
        else
            ConsumesManager_Options.enableCategories = false 
        end
        ConsumesManager_UpdateManagerContent()
        ConsumesManager_UpdatePresetsConsumables()
    end)

    local enableCategoriesLabel = enableCategoriesFrame:CreateFontString(nil, "OVERLAY", "GameFontNormal")
    enableCategoriesLabel:SetPoint("LEFT", enableCategoriesCheckbox, "RIGHT", 4, 0)
    enableCategoriesLabel:SetText("Enable Categories")
    enableCategoriesLabel:SetJustifyH("LEFT")
    enableCategoriesFrame:SetScript("OnMouseDown", function()
        enableCategoriesCheckbox:Click()
    end)

    currentYOffset = currentYOffset - lineHeight

    -- Show Use Button Checkbox
    local showUseButtonFrame = CreateFrame("Frame", "ConsumesManager_ShowUseButtonFrame", scrollChild)
    showUseButtonFrame:SetWidth(WindowWidth - 10)
    showUseButtonFrame:SetHeight(18)
    showUseButtonFrame:SetPoint("TOPLEFT", scrollChild, "TOPLEFT", 0, currentYOffset)
    showUseButtonFrame:EnableMouse(true)

    local showUseButtonCheckbox = CreateFrame("CheckButton", "ConsumesManager_ShowUseButtonCheckbox", showUseButtonFrame)
    showUseButtonCheckbox:SetWidth(16)
    showUseButtonCheckbox:SetHeight(16)
    showUseButtonCheckbox:SetPoint("LEFT", showUseButtonFrame, "LEFT", 0, 0)
    showUseButtonCheckbox:SetNormalTexture("Interface\\Buttons\\UI-CheckBox-Up")
    showUseButtonCheckbox:SetPushedTexture("Interface\\Buttons\\UI-CheckBox-Down")
    showUseButtonCheckbox:SetHighlightTexture("Interface\\Buttons\\UI-CheckBox-Highlight")
    showUseButtonCheckbox:SetCheckedTexture("Interface\\Buttons\\UI-CheckBox-Check")
    showUseButtonCheckbox:SetChecked(ConsumesManager_Options.showUseButton)

    showUseButtonCheckbox:SetScript("OnClick", function()
        if showUseButtonCheckbox:GetChecked() then
            ConsumesManager_Options.showUseButton = true
        else
            ConsumesManager_Options.showUseButton = false 
        end
        ConsumesManager_UpdateManagerContent()
        ConsumesManager_UpdatePresetsConsumables()
    end)

    local showUseButtonLabel = showUseButtonFrame:CreateFontString(nil, "OVERLAY", "GameFontNormal")
    showUseButtonLabel:SetPoint("LEFT", showUseButtonCheckbox, "RIGHT", 4, 0)
    showUseButtonLabel:SetText("Show Use Button")
    showUseButtonLabel:SetJustifyH("LEFT")
    showUseButtonFrame:SetScript("OnMouseDown", function()
        showUseButtonCheckbox:Click()
    end)

    currentYOffset = currentYOffset - lineHeight - 20

    -- Multi-Account Setup
    local multiAccountTitle = scrollChild:CreateFontString(nil, "OVERLAY", "GameFontNormalLarge")
    multiAccountTitle:SetPoint("TOPLEFT", scrollChild, "TOPLEFT", 0, currentYOffset)
    multiAccountTitle:SetText("Multi-Account Setup |cffff0000(BETA!)|r")
    multiAccountTitle:SetTextColor(1, 1, 1)
    currentYOffset = currentYOffset - lineHeight

    local multiAccountInfo = scrollChild:CreateFontString(nil, "OVERLAY", "GameFontNormal")
    multiAccountInfo:SetPoint("TOPLEFT", scrollChild, "TOPLEFT", 0, currentYOffset)
    multiAccountInfo:SetText("Set a unique channel name and password. \nRepeat this setup for each of your alt-accounts.")
    multiAccountInfo:SetJustifyH("LEFT")
    currentYOffset = currentYOffset - lineHeight * 2

    -- More Info Button
    local popup = MultiAccountInfoPopup()
    local MoreInfoBtn = CreateFrame("Button", "ConsumesManager_MoreInfoBtn", scrollChild, "UIPanelButtonTemplate")
    MoreInfoBtn:SetWidth(70)
    MoreInfoBtn:SetHeight(20)
    MoreInfoBtn:SetText("More Info")
    MoreInfoBtn:SetPoint("TOPLEFT", scrollChild, "TOPLEFT", 0, currentYOffset)
    MoreInfoBtn:SetScript("OnClick", function()
        if popup:IsShown() then
            popup:Hide()
        else
            popup:Show()
        end
    end)
    currentYOffset = currentYOffset - lineHeight - 10

    -- Channel Input
    local channelLabel = scrollChild:CreateFontString(nil, "OVERLAY", "GameFontNormal")
    channelLabel:SetPoint("TOPLEFT", scrollChild, "TOPLEFT", 0, currentYOffset)
    channelLabel:SetText("Channel:")
    channelLabel:SetWidth(60)
    channelLabel:SetJustifyH("LEFT")
    channelLabel:SetTextColor(1, 1, 1)

    -- Create a frame to hold the editbox so the sub-textures stay aligned
    local channelFrame = CreateFrame("Frame", nil, scrollChild)
    channelFrame:SetHeight(20)
    channelFrame:SetWidth(140)
    channelFrame:SetPoint("LEFT", channelLabel, "RIGHT", 10, 0)

    local channelEditBox = CreateFrame("EditBox", "ConsumesManager_ChannelEditBox", channelFrame, "InputBoxTemplate")
    channelEditBox:SetAutoFocus(false)
    channelEditBox:SetMaxLetters(50)
    channelEditBox:SetAllPoints(channelFrame) -- Fill the entire holding frame

    local leftTex = getglobal(channelEditBox:GetName().."Left")
    local midTex  = getglobal(channelEditBox:GetName().."Middle")
    local rightTex= getglobal(channelEditBox:GetName().."Right")

    -- Anchor them so they move with the EditBox
    if leftTex then
        leftTex:ClearAllPoints()
        leftTex:SetPoint("LEFT", channelEditBox, "LEFT", -5, 0)
    end
    if midTex then
        midTex:ClearAllPoints()
        midTex:SetPoint("LEFT", leftTex, "RIGHT", 0, 0)
        midTex:SetPoint("RIGHT", rightTex, "LEFT", 0, 0)
    end
    if rightTex then
        rightTex:ClearAllPoints()
        rightTex:SetPoint("RIGHT", channelEditBox, "RIGHT", 5, 0)
    end

    -- Retrieve stored channel
    local stored_channel = ""
    if ConsumesManager_Options.Channel and ConsumesManager_Options.Channel ~= "" then
        stored_channel = DecodeMessage(ConsumesManager_Options.Channel)
    end
    channelEditBox:SetText(stored_channel)
    currentYOffset = currentYOffset - lineHeight

    -- Password Input
    local passwordLabel = scrollChild:CreateFontString(nil, "OVERLAY", "GameFontNormal")
    passwordLabel:SetPoint("TOPLEFT", scrollChild, "TOPLEFT", 0, currentYOffset)
    passwordLabel:SetText("Password:")
    passwordLabel:SetWidth(60)
    passwordLabel:SetJustifyH("LEFT")
    passwordLabel:SetTextColor(1, 1, 1)

    -- Same holding frame approach
    local passwordFrame = CreateFrame("Frame", nil, scrollChild)
    passwordFrame:SetHeight(20)
    passwordFrame:SetWidth(140)
    passwordFrame:SetPoint("LEFT", passwordLabel, "RIGHT", 10, 0)

    local passwordEditBox = CreateFrame("EditBox", "ConsumesManager_PasswordEditBox", passwordFrame, "InputBoxTemplate")
    passwordEditBox:SetAutoFocus(false)
    passwordEditBox:SetMaxLetters(50)
    passwordEditBox:SetAllPoints(passwordFrame)

    local pLeft = getglobal(passwordEditBox:GetName().."Left")
    local pMid  = getglobal(passwordEditBox:GetName().."Middle")
    local pRight= getglobal(passwordEditBox:GetName().."Right")

    if pLeft then
        pLeft:ClearAllPoints()
        pLeft:SetPoint("LEFT", passwordEditBox, "LEFT", -5, 0)
    end
    if pMid then
        pMid:ClearAllPoints()
        pMid:SetPoint("LEFT", pLeft, "RIGHT", 0, 0)
        pMid:SetPoint("RIGHT", pRight, "LEFT", 0, 0)
    end
    if pRight then
        pRight:ClearAllPoints()
        pRight:SetPoint("RIGHT", passwordEditBox, "RIGHT", 5, 0)
    end

    local stored_password = ""
    if ConsumesManager_Options.Password and ConsumesManager_Options.Password ~= "" then
        stored_password = DecodeMessage(ConsumesManager_Options.Password)
    end
    passwordEditBox:SetText(stored_password)
    currentYOffset = currentYOffset - lineHeight - 10

    -- Join and Leave Channel Buttons
    joinChannelButton = CreateFrame("Button", "ConsumesManager_JoinChannelButton", scrollChild, "UIPanelButtonTemplate")
    joinChannelButton:SetWidth(140)
    joinChannelButton:SetHeight(24)
    joinChannelButton:SetText("Save & Join Channel")
    joinChannelButton:SetPoint("TOPLEFT", scrollChild, "TOPLEFT", 0, currentYOffset)

    LeaveChannelButton = CreateFrame("Button", "ConsumesManager_LeaveChannelButton", scrollChild, "UIPanelButtonTemplate")
    LeaveChannelButton:SetWidth(140)
    LeaveChannelButton:SetHeight(24)
    LeaveChannelButton:SetText("Leave Channel")
    LeaveChannelButton:SetPoint("TOPLEFT", scrollChild, "TOPLEFT", 140, currentYOffset)

    -- Function to Update Leave Button State
    local function UpdateLeaveButtonState()
        if ConsumesManager_Options.Channel == "" or ConsumesManager_Options.Channel == nil then
            LeaveChannelButton:Disable()
            LeaveChannelButton:SetAlpha(0.5)
            channelEditBox:SetText("")
            passwordEditBox:SetText("")
        else
            LeaveChannelButton:Enable()
            LeaveChannelButton:SetAlpha(1)
        end
    end

    UpdateLeaveButtonState()

    -- Leave Channel Button Script
    LeaveChannelButton:SetScript("OnClick", function()
        if ConsumesManager_Options.Channel == "" or ConsumesManager_Options.Channel == nil then
            UpdateLeaveButtonState()
            updateSenDataButtonState()
        else
            local decoded_channel = DecodeMessage(ConsumesManager_Options.Channel)
            DEFAULT_CHAT_FRAME:AddMessage("|cffffffff" .. GetAddOnMetadata("ConsumesManager", "Title") .. ":|r |cffffffffYou left|r |cffffc0c0[" .. decoded_channel .. "]|r|cffffffff. Multi-account sync |cffff0000disabled|r|cffffffff.|r")
            LeaveChannelByName(decoded_channel)
            ConsumesManager_Options.Channel = nil
            ConsumesManager_Options.Password = nil
            UpdateLeaveButtonState()
            updateSenDataButtonState()
        end
    end)

    -- Channel Error Message
    local channelErrorMessage = scrollChild:CreateFontString(nil, "OVERLAY", "GameFontNormal")
    channelErrorMessage:SetPoint("TOPLEFT", joinChannelButton, "BOTTOMLEFT", 0, -5)
    channelErrorMessage:SetTextColor(1, 0, 0)
    channelErrorMessage:SetText("Failed to join channel. Read chat for more info.")
    channelErrorMessage:Hide()
    currentYOffset = currentYOffset - lineHeight - 30

    -- Function to Update Join Button State
    local function UpdateJoinButtonState()
        local ctext = channelEditBox:GetText()
        local ptext = passwordEditBox:GetText()
        if ctext ~= "" and ptext ~= "" then
            joinChannelButton:Enable()
            joinChannelButton:SetAlpha(1)
        else
            joinChannelButton:Disable()
            joinChannelButton:SetAlpha(0.5)
        end
    end

    channelEditBox:SetScript("OnTextChanged", UpdateJoinButtonState)
    passwordEditBox:SetScript("OnTextChanged", UpdateJoinButtonState)

    UpdateJoinButtonState()

    -- Function to Handle Channel Join Failures
    function ConsumesManager_ChannelJoinFailed(error_message)
        ConsumesManager_Options.Channel = nil
        ConsumesManager_Options.Password = nil
        channelEditBox:SetText("")
        passwordEditBox:SetText("")
        UpdateJoinButtonState()
        channelErrorMessage:Show()
        channelErrorMessage:SetText(error_message)
    end

    -- Danger Zone Title
    local DangerZonTitle = scrollChild:CreateFontString(nil, "OVERLAY", "GameFontNormalLarge")
    DangerZonTitle:SetPoint("TOPLEFT", scrollChild, "TOPLEFT", 0, currentYOffset)
    DangerZonTitle:SetText("Danger Zone")
    DangerZonTitle:SetTextColor(1, 1, 1)
    currentYOffset = currentYOffset - lineHeight * 2

    -- Reset Addon Button
    resetButton = CreateFrame("Button", "ConsumesManager_ResetButton", scrollChild, "UIPanelButtonTemplate")
    resetButton:SetWidth(120)
    resetButton:SetHeight(24)
    resetButton:SetText("Reset Addon")
    resetButton:SetPoint("TOPLEFT", scrollChild, "TOPLEFT", 0, currentYOffset)
    resetButton:SetScript("OnClick", function()
        if ConsumesManager_Options.Channel then 
            local decoded_channel = DecodeMessage(ConsumesManager_Options.Channel)
            LeaveChannelByName(decoded_channel)
        end
        ConsumesManager_Options = {}
        ConsumesManager_SelectedItems = {}
        ConsumesManager_Data = {}
        ReloadUI()
    end)

    -- Set the scroll child height to accommodate all content
    scrollChild.contentHeight = math.abs(startYOffset - currentYOffset) + 100
    scrollChild:SetHeight(scrollChild.contentHeight)

    -- Scroll Bar Setup
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
        local value = this:GetValue()
        scrollFrame:SetVerticalScroll(value)
    end)
    parentFrame.scrollBar = scrollBar

    ConsumesManager_UpdateSettingsScrollBar()

    if not ConsumesManager_ChannelFrame then
        ConsumesManager_ChannelFrame = CreateFrame("Frame", "ConsumesManager_ChannelFrame")
    end

    local channelmsg = ""

    joinChannelButton:SetScript("OnClick", function()

        ConsumesManager_ChannelFrame:RegisterEvent("CHAT_MSG_CHANNEL_NOTICE")

        channelErrorMessage:Hide()
        local ctext = channelEditBox:GetText()
        local ptext = passwordEditBox:GetText()
        local final_result = nil
        local try_again = false

         ConsumesManager_ChannelFrame:SetScript("OnEvent", function()
            local noticeType = string.upper(arg1 or "")
            local channelName = string.upper(arg9 or "")
            local inputChannelName = string.upper(ctext or "")

            if noticeType == "WRONG_PASSWORD" and channelName == inputChannelName then
                channelmsg = "WRONG_PASSWORD"
                --DEFAULT_CHAT_FRAME:AddMessage(noticeType)
            elseif noticeType == "NOT_MODERATOR" and channelName == inputChannelName then
                channelmsg = "NOT_MODERATOR"
                --DEFAULT_CHAT_FRAME:AddMessage(noticeType)
            elseif noticeType == "YOU_JOINED" and channelName == inputChannelName then
                channelmsg = "YOU_JOINED"
                --DEFAULT_CHAT_FRAME:AddMessage(noticeType)
            end

        end)


        -- Don't join same channel
        if ConsumesManager_Options.Channel then
            if DecodeMessage(ConsumesManager_Options.Channel) == ctext then
                channelErrorMessage:SetText("Already in this channel")
                channelErrorMessage:Show()
                return
            end
        end

        -- Block attempts to join big system channels
        local blocked = { "world", "general", "localdefense", "hardcore", "lft", "trade" }
        local lowerChannel = string.lower(ctext)
        for _, b in pairs(blocked) do
            if lowerChannel == b then
                ConsumesManager_ChannelJoinFailed("You cannot use a global channel")
                return
            end
        end

        JoinChannelByName(ctext, ptext)

        joinChannelButton:SetText("Connecting... (4)")
        joinChannelButton:Disable()
        joinChannelButton:SetAlpha(0.5)


        local delayFrame = CreateFrame("Frame")
        delayFrame:Show()
        local elapsed = 0
        local delay = 5
        local one_attempt = 0

        delayFrame:SetScript("OnUpdate", function()
            

            if elapsed > 1 and elapsed < 2 then

                joinChannelButton:SetText("Connecting... (3)")

                if one_attempt == 0 then

                    DEFAULT_CHAT_FRAME:AddMessage("message: " .. channelmsg)

                    if channelmsg == "WRONG_PASSWORD" then
                        final_result = "WRONG_PASSWORD"
                    elseif channelmsg == "YOU_JOINED" then
                        DEFAULT_CHAT_FRAME:AddMessage("setting password")
                        SetChannelPassword(ctext, ptext)
                    end
                end

                one_attempt = 1


            elseif elapsed > 2 and elapsed < 3 then
                joinChannelButton:SetText("Connecting... (2)")


                if one_attempt == 1 then

                    DEFAULT_CHAT_FRAME:AddMessage("message: " .. channelmsg)

                    if channelmsg == "YOU_JOINED" then
                        final_result = "SUCCESS"
                    elseif channelmsg == "NOT_MODERATOR" then
                        LeaveChannelByName(ctext)
                        try_again = true
                    end
                end

                one_attempt = 2



            elseif elapsed > 3 and elapsed < 4 then
                joinChannelButton:SetText("Connecting... (1)")

                if one_attempt == 2 then

                    DEFAULT_CHAT_FRAME:AddMessage("message: " .. channelmsg)

                    if try_again == true then

                        JoinChannelByName(ctext, ptext)

                    end
                 end

                one_attempt = 3

            elseif elapsed > 4 and elapsed < 5 then
                joinChannelButton:SetText("Connecting... (0)")

                if one_attempt == 3 then

                    DEFAULT_CHAT_FRAME:AddMessage("message: " .. channelmsg)

                    if try_again == true then

                        if channelmsg == "YOU_JOINED" then
                            final_result = "SUCCESS"
                        elseif channelmsg == "NOT_MODERATOR" then
                            final_result = "NOT_MODERATOR"
                        end
                    end
                 end

                one_attempt = 4

            end



            elapsed = elapsed + arg1

            if elapsed >= delay then

                delayFrame:SetScript("OnUpdate", nil)
                delayFrame:Hide()


                -- ACTION AFTER 3 SECONDS


                if final_result == "SUCCESS" then

                    ConsumesManager_Options.Channel = EncodeMessage(ctext)
                    ConsumesManager_Options.Password = EncodeMessage(ptext)

                    DEFAULT_CHAT_FRAME:AddMessage("|cffffffff" .. GetAddOnMetadata("ConsumesManager", "Title") ..
                    ":|r |cffffffffYou joined|r |cffffc0c0[" .. ctext ..
                    "]|r|cffffffff. Multi-account sync |cff00ff00enabled|r|cffffffff.|r")

                elseif final_result == "WRONG_PASSWORD" then

                    ConsumesManager_ChannelJoinFailed("Wrong password. Try again.")

                    DEFAULT_CHAT_FRAME:AddMessage("|cffffffff" .. GetAddOnMetadata("ConsumesManager", "Title") ..
                    ":|r |cffffffffWrong password for|r |cffffc0c0[" .. ctext ..
                    "]|r|cffffffff. Multi-account sync |cffff0000disabled|r|cffffffff.|r")

                elseif final_result == "NOT_MODERATOR" then

                    ConsumesManager_ChannelJoinFailed("This is not your channel.")
                    DEFAULT_CHAT_FRAME:AddMessage("|cffffffff" .. GetAddOnMetadata("ConsumesManager", "Title") ..
                    ":|r |cffffffffYou don't own|r |cffffc0c0[" .. ctext ..
                    "]|r|cffffffff. Multi-account sync |cffff0000disabled|r|cffffffff.|r")

                else
                    LeaveChannelByName(ctext)
                    ConsumesManager_ChannelJoinFailed("Unknown error")
                    DEFAULT_CHAT_FRAME:AddMessage("|cffffffff" .. GetAddOnMetadata("ConsumesManager", "Title") ..
                    ":|r |cffffffffFailed to join|r |cffffc0c0[" .. ctext ..
                    "]|r|cffffffff. Multi-account sync |cffff0000disabled|r|cffffffff.|r")
                end

                joinChannelButton:SetText("Save & Join Channel")
                joinChannelButton:Enable()
                joinChannelButton:SetAlpha(1)
                updateSenDataButtonState()
                UpdateLeaveButtonState()

                ConsumesManager_ChannelFrame:UnregisterEvent("CHAT_MSG_CHANNEL_NOTICE")

            end
            delayFrame:Show()
        end)
    end)
end

function ConsumesManager_UpdateSettingsContent()
    local parentFrame = ConsumesManager_MainFrame and ConsumesManager_MainFrame.tabs and ConsumesManager_MainFrame.tabs[4]
    if not parentFrame or not parentFrame.scrollFrame then
        return
    end

    -- Remove existing child
    local oldChild = parentFrame.scrollFrame:GetScrollChild()
    if oldChild then
        oldChild:Hide()
        oldChild:SetParent(nil)
        parentFrame.scrollFrame:SetScrollChild(nil)
    end

    -- Remove old scrollbar
    if parentFrame.scrollBar then
        parentFrame.scrollBar:Hide()
        parentFrame.scrollBar:SetParent(nil)
        parentFrame.scrollBar = nil
    end

    -- New scroll child
    local newScrollChild = CreateFrame("Frame", nil, parentFrame.scrollFrame)
    newScrollChild:SetWidth(WindowWidth - 10)
    newScrollChild:SetHeight(1)
    newScrollChild.contentHeight = 0
    parentFrame.scrollFrame:SetScrollChild(newScrollChild)
    parentFrame.scrollChild = newScrollChild

    -- Build content
    ConsumesManager_CreateSettingsContent(parentFrame)

    -- Reset scroll
    if parentFrame.scrollBar then
        parentFrame.scrollBar:SetValue(0)
    end
end

function ConsumesManager_UpdateSettingsScrollBar()
    local OptionsFrame = ConsumesManager_MainFrame and ConsumesManager_MainFrame.tabs and ConsumesManager_MainFrame.tabs[4]
    if not OptionsFrame then
        return
    end
    local scrollBar = OptionsFrame.scrollBar
    local scrollFrame = OptionsFrame.scrollFrame
    local scrollChild = OptionsFrame.scrollChild

    local totalHeight = scrollChild.contentHeight
    local shownHeight = 420

    local maxScroll = math.max(0, totalHeight - shownHeight)
    scrollFrame.maxScroll = maxScroll

    if totalHeight > shownHeight then
        scrollBar:SetMinMaxValues(0, maxScroll)
        scrollBar:SetValue(math.min(scrollBar:GetValue(), maxScroll))
        scrollBar:Show()
    else
        scrollFrame.maxScroll = 0
        scrollBar:SetMinMaxValues(0, 0)
        scrollBar:SetValue(0)
        scrollBar:Hide()
    end
end



-- Global Functions -----------------------------------------------------------------------------
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

            if ConsumesManager_SelectedItems[itemID] then
                local count = inventory[itemID] or 0
                if count > 0 then
                    if ConsumesManager_Options.showUseButton then
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

function ConsumesManager_GetConsumableCount(itemID)
    local totalCount = 0
    local realmName = GetRealmName()

    -- Early exit if no data
    if not ConsumesManager_Data[realmName] then 
        return 0 
    end

    -- Loop through all characters regardless of faction
    for character, charData in pairs(ConsumesManager_Data[realmName]) do
        if type(charData) == "table" and ConsumesManager_Options["Characters"] and ConsumesManager_Options["Characters"][character] == true then
            if character ~= "faction" then  -- Skip non-character metadata
                if charData["inventory"] and charData["inventory"][itemID] then
                    totalCount = totalCount + charData["inventory"][itemID]
                end
                if charData["bank"] and charData["bank"][itemID] then
                    totalCount = totalCount + charData["bank"][itemID]
                end
                if charData["mail"] and charData["mail"][itemID] then
                    totalCount = totalCount + charData["mail"][itemID]
                end
            end
        end
    end
    
    return totalCount
end

function ConsumesManager_UpdateAllContent()
    ConsumesManager_UpdateManagerContent()
    ConsumesManager_UpdatePresetsConsumables()
    ConsumesManager_UpdateSettingsContent()
end

function ConsumesManager_DisableTab(tab)
    tab.isEnabled = false
    tab:EnableMouse(true)  -- Keep mouse enabled for tooltip
    tab.icon:SetDesaturated(true)  -- Grey out the icon
    tab:SetScript("OnClick", nil)  -- Remove OnClick handler

    -- Hide highlight effect
    if tab.hoverTexture then
        tab.hoverTexture:SetAlpha(0)
    end

    -- Adjust OnEnter handler to show tooltip only
    tab:SetScript("OnEnter", function()
        ShowTooltip(tab, tab.tooltipText)
    end)
    tab:SetScript("OnLeave", HideTooltip)
end

function ConsumesManager_EnableTab(tab)
    tab.isEnabled = true
    tab:EnableMouse(true)
    tab.icon:SetDesaturated(false)
    tab:SetScript("OnClick", tab.originalOnClick)  -- Restore OnClick handler

    -- Show highlight effect
    if tab.hoverTexture then
        tab.hoverTexture:SetAlpha(1)
    end

    -- Restore original OnEnter and OnLeave handlers
    tab:SetScript("OnEnter", function()
        ShowTooltip(tab, tab.tooltipText)
    end)
    tab:SetScript("OnLeave", HideTooltip)
end

function ConsumesManager_CheckBankAndMailScanned()
    local realmName = GetRealmName()
    local playerName = UnitName("player")

    -- Ensure data structure exists
    if not ConsumesManager_Data[realmName] or not ConsumesManager_Data[realmName][playerName] then
        return false, false
    end
    
    local currentCharData = ConsumesManager_Data[realmName][playerName]
    
    local bankScanned = currentCharData["bank"] ~= nil
    local mailScanned = currentCharData["mail"] ~= nil

    return bankScanned, mailScanned
end


function ConsumesManager_UpdateTabStates()
    if not ConsumesManager_Tabs or not ConsumesManager_Tabs[2] or not ConsumesManager_Tabs[3] then
        -- Tabs have not been created yet; exit the function
        return
    end

    local bankScanned, mailScanned = ConsumesManager_CheckBankAndMailScanned()
    if bankScanned and mailScanned then
        ConsumesManager_EnableTab(ConsumesManager_Tabs[2])  -- Items Tab
        ConsumesManager_EnableTab(ConsumesManager_Tabs[3])  -- Presets Tab
    else
        ConsumesManager_DisableTab(ConsumesManager_Tabs[2])  -- Items Tab
        ConsumesManager_DisableTab(ConsumesManager_Tabs[3])  -- Presets Tab
    end
end

function MultiAccountInfoPopup()
    -- Create the frame
    local popup = CreateFrame("Frame", "MyPopupFrame", UIParent)
    popup:SetHeight(180)
    popup:SetPoint("CENTER", UIParent, "CENTER", 0, 0)
    popup:SetBackdrop({
        bgFile = "Interface\\ChatFrame\\ChatFrameBackground", -- Solid black background
        edgeFile = "Interface\\DialogFrame\\UI-DialogBox-Border",
        tile = false,
        tileSize = 0,
        edgeSize = 32,
        insets = { left = 8, right = 8, top = 8, bottom = 8 }
    })
    popup:SetBackdropColor(0, 0, 0, 1) -- Black background with full opacity
    popup:SetBackdropBorderColor(1, 1, 1, 1) -- White border
    popup:SetFrameStrata("DIALOG")
    popup:SetFrameLevel(1000)
    popup:SetMovable(true)
    popup:EnableMouse(true)
    popup:RegisterForDrag("LeftButton")
    popup:SetScript("OnDragStart", function()
        this:StartMoving()
    end)
    popup:SetScript("OnDragStop", function()
        this:StopMovingOrSizing()
    end)

    -- Add a close button
    local closeButton = CreateFrame("Button", nil, popup, "UIPanelCloseButton")
    closeButton:SetPoint("TOPRIGHT", popup, "TOPRIGHT", -5, -5)

    -- Add a title
    local infotitle = popup:CreateFontString(nil, "OVERLAY", "GameFontNormalLarge")
    infotitle:SetPoint("TOPLEFT", popup, "TOPLEFT", 20, -20)
    infotitle:SetText("How does it work?")
    infotitle:SetTextColor(1,1,1)

    -- Add the infotext
    popup.infotext = popup:CreateFontString(nil, "OVERLAY", "GameFontNormal")
    popup.infotext:SetPoint("TOPLEFT", popup, "TOPLEFT", 20, -35)
    popup.infotext:SetJustifyH("LEFT")
    popup.infotext:SetText(
        "|cffff0000(Beta Feature! Might be glitchy!)|r\n\n" ..
        "To sync accounts, follow these steps:\n\n" ..
        "1. Join a private channel with a unique name and password.\n" ..
        "2. The channel info is saved for all characters on your account.\n" ..
        "3. Log into your alt account on a second client.\n" ..
        "4. Join the same channel via this addon to link both accounts.\n" ..
        "5. Keep one character from your main account online for syncing.\n" ..
        "6. Click on 'Push Data' to send the database from one account to all the other that are online."
    )


    -- Function to adjust width dynamically after text is set
    popup:SetScript("OnShow", function()
        local textWidth = popup.infotext:GetStringWidth() + 40 -- Add padding
        popup:SetWidth(textWidth)
    end)

    popup:Hide()
    return popup
end



-- Tooltip Functions  --------------------------------------------------------------------------------------
function ConsumesManager_ShowConsumableTooltip(itemID)
    -- Ensure item is enabled in settings or part of presets
    if not ConsumesManager_SelectedItems[itemID] and not ConsumesManager_IsItemInPresets(itemID) then
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
        title:SetJustifyH("LEFT")
        tooltipFrame.title = title

        -- Item Total
        local total = tooltipFrame:CreateFontString(nil, "OVERLAY", "GameFontNormal")
        total:SetPoint("TOPLEFT", icon, "TOPRIGHT", 10, -20)
        total:SetJustifyH("LEFT")
        tooltipFrame.total = total

        -- Content text
        local content = tooltipFrame:CreateFontString(nil, "OVERLAY", "GameFontNormal")
        content:SetPoint("TOPLEFT", icon, "BOTTOMLEFT", 0, -10)
        content:SetJustifyH("LEFT")
        tooltipFrame.content = content

        -- Mats text
        local mats = tooltipFrame:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
        mats:SetPoint("TOPLEFT", content, "BOTTOMLEFT", 0, -10)
        mats:SetJustifyH("LEFT")
        tooltipFrame.mats = mats

        ConsumesManager_CustomTooltip = tooltipFrame
    end

    local tooltipFrame = ConsumesManager_CustomTooltip

    -- Get item info
    local itemName = consumablesList[itemID] or "Unknown Item"
    local itemTexture = consumablesTexture[itemID] or "Interface\\Icons\\INV_Misc_QuestionMark"
   
    -- Set icon and title
    tooltipFrame.icon:SetTexture(itemTexture)
    tooltipFrame.title:SetText(itemName)

    local mats = consumablesMats[itemID] or {}
    local matsText = ""

    if type(mats) == "table" and next(mats) then
        local index = 0
        local divider = ""
        for _, mat in ipairs(mats) do
            index = index + 1
            if index > 1 then
                divider = " | "
            else
                divider = ""
            end

            matsText = matsText .. divider .. "|cff4ac9ff" .. mat .. "|r" 
        end
    else
        matsText = "|cff696969No materials specified for this item.|r"
    end

    tooltipFrame.mats:SetText(matsText)

    -- Prepare content text
    local contentText = ""
    local realmName = GetRealmName()
    local playerName = UnitName("player")
    local playerFaction = UnitFactionGroup("player")

    -- Ensure data structure exists
    ConsumesManager_Data[realmName] = ConsumesManager_Data[realmName] or {}

    -- Initialize totals
    local totalInventory, totalBank, totalMail = 0, 0, 0
    local hasItems = false
    local characterList = {}

    -- Ensure character settings exist
    ConsumesManager_Options["Characters"] = ConsumesManager_Options["Characters"] or {}

    -- Collect data for each character
    for character, charData in pairs(ConsumesManager_Data[realmName]) do
        -- Make sure it's a character data table and not metadata
        if type(charData) == "table" and ConsumesManager_Options["Characters"][character] == true then
            -- Get faction info for display
            local charFaction = charData.faction or "Unknown"
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
                    faction = charFaction,
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
        lineHeightAdjust = 10
    else
        lineHeightAdjust = 0
        -- Sort characters alphabetically
        table.sort(characterList, function(a, b) return a.name < b.name end)

        -- Display data for each character
        for _, charInfo in ipairs(characterList) do
            local nameColor = charInfo.isPlayer and "|cff00ff00" or "|cffffffff"  -- Green for player, white for others
            local factionColor = ""
            
            -- Color code by faction
            if charInfo.faction == "Alliance" then
                factionColor = "|cff0078ff"  -- Blue for Alliance
            elseif charInfo.faction == "Horde" then
                factionColor = "|cffb30000"  -- Red for Horde
            else
                factionColor = "|cff808080"  -- Grey for unknown
            end
            
            contentText = contentText .. nameColor .. charInfo.name .. factionColor .. " [" .. charInfo.faction .. "]|r (" .. charInfo.total .. ")\n"

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
    local totalHeight = 60 + (numLines * lineHeightTooltip) + lineHeightAdjust
    tooltipFrame:SetHeight(totalHeight)

    -- Set the width based on content
    local titleWidth = math.max(tooltipFrame.mats:GetStringWidth() + 20, tooltipFrame.title:GetStringWidth() + 60)
    local maxWidth = math.max(titleWidth, tooltipFrame.content:GetStringWidth() + 20)
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

        -- Mats text
        local mats = tooltipFrame:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
        mats:SetPoint("TOPLEFT", description, "BOTTOMLEFT", 0, -10)
        mats:SetJustifyH("LEFT")
        tooltipFrame.mats = mats

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

        local mats = consumablesMats[itemID] or {}
    local matsText = ""

    if type(mats) == "table" and next(mats) then
        local index = 0
        local divider = ""
        for _, mat in ipairs(mats) do
            index = index + 1
            if index > 1 then
                divider = " | "
            else
                divider = ""
            end

            matsText =   matsText .. divider .. "|cff4ac9ff" .. mat .. "|r" 
        end
    else
        matsText = "|cff696969No materials specified for this item.|r"
    end

    tooltipFrame.mats:SetText(matsText)

    -- Adjust the height of the description based on its content
    tooltipFrame.description:SetWidth(maxDescriptionWidth)
    tooltipFrame.description:SetText(itemDescription)
    local descriptionHeight = tooltipFrame.description:GetHeight()

    -- Adjust tooltip height based on content
    local totalHeight = 80 + descriptionHeight
    tooltipFrame:SetHeight(totalHeight)

    -- Set the width of the tooltip
    local titleWidth = math.max(tooltipFrame.title:GetStringWidth() + 70, tooltipFrame.mats:GetStringWidth() + 20)
    local maxWidth = math.max(titleWidth, maxDescriptionWidth + 20)
    tooltipFrame:SetWidth(maxWidth)

    -- Position the tooltip near the cursor
    local x, y = GetCursorPosition()
    local scale = UIParent:GetEffectiveScale()
    tooltipFrame:SetPoint("BOTTOMLEFT", UIParent, "BOTTOMLEFT", x / scale + 10, y / scale - 10)

    tooltipFrame:Show()
end

function ShowTooltip(tab, text)
    ConsumesManagerTooltip.text:SetText(text)
    ConsumesManagerTooltip:SetPoint("BOTTOMLEFT", tab, "TOPLEFT", 0, 0)
    ConsumesManagerTooltip:Show()
end

function HideTooltip()
    ConsumesManagerTooltip:Hide()
end



-- Scan Functions ---------------------------------------------------------------------------------------
function ConsumesManager_ScanPlayerInventory()
    local delayFrameInv = CreateFrame("Frame")
    local delayStartTime = GetTime()
    local delay = 0.5

    delayFrameInv:SetScript("OnUpdate", function()
        if GetTime() - delayStartTime >= delay then
            local playerName = UnitName("player")
            local realmName = GetRealmName()
            local faction = UnitFactionGroup("player")

            -- Initialize data structure without faction separation
            ConsumesManager_Data[realmName] = ConsumesManager_Data[realmName] or {}
            
            -- Store faction information with player data for display purposes
            if not ConsumesManager_Data[realmName][playerName] then
                ConsumesManager_Data[realmName][playerName] = {
                    faction = faction  -- Store faction information with the character
                }
            else
                ConsumesManager_Data[realmName][playerName].faction = faction
            end
            
            -- Initialize inventory data
            ConsumesManager_Data[realmName][playerName]["inventory"] = {}

            -- Scan bags
            for bag = 0, 4 do
                local numSlots = GetContainerNumSlots(bag)
                if numSlots then
                    for slot = 1, numSlots do
                        local link = GetContainerItemLink(bag, slot)
                        if link then
                            local _, _, itemID = string.find(link, "item:(%d+)")
                            if itemID then
                                itemID = tonumber(itemID)
                                if consumablesList[itemID] then
                                    local _, itemCount = GetContainerItemInfo(bag, slot)
                                    if itemCount and itemCount ~= 0 then
                                        if itemCount < 0 then itemCount = -itemCount end
                                        ConsumesManager_Data[realmName][playerName]["inventory"][itemID] = (ConsumesManager_Data[realmName][playerName]["inventory"][itemID] or 0) + itemCount
                                    end
                                end
                            end
                        end
                    end
                end
            end

            ConsumesManager_UpdateUseButtons()
            ConsumesManager_UpdateManagerContent()
            ConsumesManager_UpdateTabStates()
            delayFrameInv:SetScript("OnUpdate", nil)
        end
    end)
end

function ConsumesManager_ScanPlayerBank()
    if not isBankOpen then return end

    local delayFrameBank = CreateFrame("Frame")
    local delayStartTime = GetTime()
    local delay = 0.5

    delayFrameBank:SetScript("OnUpdate", function()
        if GetTime() - delayStartTime >= delay then
            local playerName = UnitName("player")
            local realmName = GetRealmName()
            local faction = UnitFactionGroup("player")

            -- Initialize data structure without faction separation
            ConsumesManager_Data[realmName] = ConsumesManager_Data[realmName] or {}
            
            -- Update faction information (in case it changed or was missing)
            if not ConsumesManager_Data[realmName][playerName] then
                ConsumesManager_Data[realmName][playerName] = {
                    faction = faction
                }
            else
                ConsumesManager_Data[realmName][playerName].faction = faction
            end
            
            -- Initialize bank data if it doesn't exist yet
            ConsumesManager_Data[realmName][playerName]["bank"] = ConsumesManager_Data[realmName][playerName]["bank"] or {}
            
            -- Create a temporary table to track what we find
            local tempBankData = {}

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
                                    if consumablesList[itemID] then
                                        local _, itemCount = GetContainerItemInfo(bag, slot)
                                        if itemCount and itemCount ~= 0 then
                                            if itemCount < 0 then itemCount = -itemCount end
                                            tempBankData[itemID] = (tempBankData[itemID] or 0) + itemCount
                                        end
                                    end
                                end
                            end
                        end
                    end
                end
            end

            -- Update only the items we found, preserve existing data for items we didn't scan
            for itemID, count in pairs(tempBankData) do
                ConsumesManager_Data[realmName][playerName]["bank"][itemID] = count
            end

            ConsumesManager_UpdateManagerContent()
            ConsumesManager_UpdateTabStates()
            delayFrameBank:SetScript("OnUpdate", nil)
        end
    end)
end

function ConsumesManager_ScanPlayerMail()
    if not isMailOpen then return end

    local delayFrameMail = CreateFrame("Frame")
    local delayStartTime = GetTime()
    local delay = 0.5

    delayFrameMail:SetScript("OnUpdate", function()
        if GetTime() - delayStartTime >= delay then
            local playerName = UnitName("player")
            local realmName = GetRealmName()
            local faction = UnitFactionGroup("player")

            -- Initialize data structure without faction separation
            ConsumesManager_Data[realmName] = ConsumesManager_Data[realmName] or {}
            
            -- Update faction information
            if not ConsumesManager_Data[realmName][playerName] then
                ConsumesManager_Data[realmName][playerName] = {
                    faction = faction
                }
            else
                ConsumesManager_Data[realmName][playerName].faction = faction
            end
            
            -- Initialize mail data
            ConsumesManager_Data[realmName][playerName]["mail"] = {}

            local numInboxItems = GetInboxNumItems()
            if numInboxItems and numInboxItems > 0 then
                for mailIndex = 1, numInboxItems do
                    local itemName, _, itemCount = GetInboxItem(mailIndex)
                    if itemName and itemCount and itemCount > 0 then
                        local itemID = consumablesNameToID[itemName]
                        if itemID and consumablesList[itemID] then
                            ConsumesManager_Data[realmName][playerName]["mail"][itemID] = (ConsumesManager_Data[realmName][playerName]["mail"][itemID] or 0) + itemCount
                        end
                    end
                end
            end

            ConsumesManager_UpdateManagerContent()
            ConsumesManager_UpdateTabStates()
            delayFrameMail:SetScript("OnUpdate", nil)
        end
    end)
end





-- Multi-Account Data Handling --------------------------------------------------------------------------


    local Converter = LibStub("LibCompress", true)


-- SEND DATA
    local countdownFrame = CreateFrame("Frame")
    countdownFrame:Hide()
    local countdownTimer = 0
    local Syncing = false
    local ProgressBar = 0
    local total_time_stored = 0
    local BarHeight = 0

    local function SyncInProgress(syncing, totalTime)
        if syncing then
            sendDataButton:Disable()
            sendDataButton.icon:SetDesaturated(true)
            LeaveChannelButton:Disable()
            LeaveChannelButton:SetAlpha(0.5)
            joinChannelButton:Disable()
            joinChannelButton:SetAlpha(0.5)
            resetButton:Disable()
            resetButton:SetAlpha(0.5)

            ProgressBarFrame:Show()
            ProgressBarFrame_Text:Show()

            ProgressBar = totalTime
            if total_time_stored == 0 then
                total_time_stored = totalTime
            end
            countdownTimer = 0
            BarHeight = 0
            ProgressBarFrame_fill:SetHeight(0)

            countdownFrame:Show()
        else
            sendDataButton:Enable()
            sendDataButton.icon:SetDesaturated(false)
            LeaveChannelButton:Enable()
            LeaveChannelButton:SetAlpha(1)
            joinChannelButton:Enable()
            joinChannelButton:SetAlpha(1)
            resetButton:Enable()
            resetButton:SetAlpha(1)

            ProgressBarFrame:Hide()
            ProgressBarFrame_Text:Hide()
            ProgressBarFrame_fill:SetHeight(0)
            ProgressBar = 0
            total_time_stored = 0
            BarHeight = 0
            ProgressBarFrame_fill:Hide()

            countdownFrame:Hide()
        end
        Syncing = syncing
    end

    countdownFrame:SetScript("OnUpdate", function()
        if Syncing and ProgressBar > 0 then
            countdownTimer = countdownTimer + arg1
            if countdownTimer >= 1 then
                ProgressBar = ProgressBar - 1
                if BarHeight < 492 then
                    BarHeight = 492 - (492 / (total_time_stored - 1)) * (ProgressBar - 1)
                    if BarHeight > 492 then
                        BarHeight = 492
                    end
                end
                ProgressBarFrame_fill:Show()
                ProgressBarFrame_fill:SetHeight(BarHeight)
                countdownTimer = 0
            end
        end
    end)

    function PushData()
        if not ConsumesManager_Options.Channel or ConsumesManager_Options.Channel == "" or
           not ConsumesManager_Options.Password or ConsumesManager_Options.Password == "" then
            return
        end

        local realmName = GetRealmName()
        local dataTable = ConsumesManager_Data[realmName]  -- Send all data, not just current faction
        local serialized = Converter:TableToString(dataTable)
        local compressed = lzw:compress(serialized)
        local data = EncodeMessage(compressed)

        local channelName = DecodeMessage(ConsumesManager_Options.Channel)
        local channelNumber = GetChannelName(channelName)
        local length = string.len(data)
        local chunkSize = 100
        local pos = 1
        local queue = {}
        while pos <= length do
            local chunk = string.sub(data, pos, pos + chunkSize - 1)
            pos = pos + chunkSize
            table.insert(queue, chunk)
        end

        local totalMessages = table.getn(queue)
        DEFAULT_CHAT_FRAME:AddMessage("|cffffffff" .. GetAddOnMetadata("ConsumesManager", "Title") .. ":|r |cffffffffData pushing started in|r |cffffc0c0[" .. DecodeMessage(ConsumesManager_Options.Channel) .. "]|r|cffffffff. Please wait...|r")
        SendChatMessage("CM_SYNC_STARTED", "CHANNEL", nil, channelNumber)
        SyncInProgress(true, totalMessages)

        local receivedChunks = {}
        local sendFrame = CreateFrame("Frame")
        local eventFrame = CreateFrame("Frame")
        eventFrame:RegisterEvent("CHAT_MSG_CHANNEL")

        local state = "IDLE"
        local currentIndex = 0
        local sendTimeout = 2
        local lockoutDuration = 10
        local lockedOutUntil = 0
        local waitingForVerification = false
        local verificationElapsed = 0
        local verificationWaitTime = 1
        local currentStartTime = 0

        eventFrame:SetScript("OnEvent", function()
            if event == "CHAT_MSG_CHANNEL" then
                local msg = arg1
                local iStart, iEnd, msgIndex, chunk = string.find(msg, "^CM_(%d+):(.+)$")
                if msgIndex and chunk then
                    msgIndex = tonumber(msgIndex)
                    receivedChunks[msgIndex] = chunk
                    if state == "WAITING" and msgIndex == currentIndex + 1 then
                        table.remove(queue, 1)
                        currentIndex = currentIndex + 1
                        state = "IDLE"
                    end
                end
            end
        end)

        local function verifyData()
            for i=1, totalMessages do
                if not receivedChunks[i] then
                    DEFAULT_CHAT_FRAME:AddMessage("|cffffffff" .. GetAddOnMetadata("ConsumesManager", "Title") .. ":|r Data validation |cffff0000failed|r|cffffffff!|r")
                    return
                end
            end
            local reconstructed = table.concat(receivedChunks, "")
            if reconstructed == data then
                DEFAULT_CHAT_FRAME:AddMessage("|cffffffff" .. GetAddOnMetadata("ConsumesManager", "Title") .. ":|r Data validation |cff00ff00succeeded|r|cffffffff!|r")
            else
                DEFAULT_CHAT_FRAME:AddMessage("|cffffffff" .. GetAddOnMetadata("ConsumesManager", "Title") .. ":|r Data validation |cffff0000failed|r|cffffffff!|r")
            end
        end

        sendFrame:SetScript("OnUpdate", function()
            local now = GetTime()

            if waitingForVerification then
                verificationElapsed = verificationElapsed + arg1
                if verificationElapsed >= verificationWaitTime then
                    DEFAULT_CHAT_FRAME:AddMessage("|cffffffff" .. GetAddOnMetadata("ConsumesManager", "Title") .. ":|r Data pushing |cff00ff00finished|r|cffffffff!|r")
                    verifyData()
                    SendChatMessage("CM_SYNC_STOPPED", "CHANNEL", nil, channelNumber)
                    SyncInProgress(false, 0)
                    eventFrame:UnregisterEvent("CHAT_MSG_CHANNEL")
                    sendFrame:SetScript("OnUpdate", nil)
                    sendFrame:Hide()
                end
                return
            end

            if table.getn(queue) == 0 then
                waitingForVerification = true
                verificationElapsed = 0
                return
            end

            if state == "LOCKED" then
                if now >= lockedOutUntil then
                    state = "IDLE"
                else
                    return
                end
            end

            if state == "IDLE" then
                local nextMsg = queue[1]
                if nextMsg then
                    SendChatMessage("CM_" .. (currentIndex + 1) .. ":" .. nextMsg, "CHANNEL", nil, channelNumber)
                    currentStartTime = now
                    state = "WAITING"
                end
            elseif state == "WAITING" then
                if now - currentStartTime > sendTimeout then
                    state = "LOCKED"
                    lockedOutUntil = now + lockoutDuration
                end
            end
        end)

        sendFrame:Show()
    end


-- READ DATA


    local collecting = false
    local collectedChunks = {}
    local collectingFrom = ""
    local collectingCount = 0
    local dataComplete = false
    local eventFrame = nil
    local channelName = ""

    local function ResetCollection()
        collecting = false
        collectingFrom = ""
        collectedChunks = {}
        collectingCount = 0
        dataComplete = false
    end

    -- Adjusted to accept 'sender' as a parameter
    local function StopCollecting(sender)
        collecting = false

        if sendDataButton then
            sendDataButton:Enable()
            sendDataButton.icon:SetDesaturated(false)
        end

        local total = table.getn(collectedChunks)
        if total > 0 then
            local i = 1
            local finalString = ""
            while i <= total do
                if collectedChunks[i] then
                    finalString = finalString .. collectedChunks[i]
                end
                i = i + 1
            end
            DEFAULT_CHAT_FRAME:AddMessage(
                "|cffffffff" .. GetAddOnMetadata("ConsumesManager", "Title") .. ":|r |cffffffffData |cff00ff00successfully|r retrieved from|r |cff00ccff" 
                .. sender .. "|r|cffffffff (" 
                .. total .. " chunks & " .. string.len(finalString) .. " data length)|r"
            )
            combineVariableTables(finalString)
        else
            DEFAULT_CHAT_FRAME:AddMessage(
                "|cffffffff" .. GetAddOnMetadata("ConsumesManager", "Title") .. ":|r |cffffffffData transmission |cffff0000failed|r from|r |cff00ccff" 
                .. sender .. "|r"
            )
        end
    end

    local function StartCollecting(sender)
        collecting = true
        collectingFrom = sender
        collectedChunks = {}
        collectingCount = 0
        dataComplete = false

        if sendDataButton then
            sendDataButton:Disable()
            sendDataButton.icon:SetDesaturated(true)
        end

        DEFAULT_CHAT_FRAME:AddMessage(
            "|cffffffff" .. GetAddOnMetadata("ConsumesManager", "Title") 
            .. ":|r |cffffffffReceiving data from|r |cff00ccff" 
            .. sender .. "|r|cffffffff...|r"
        )
    end

    local function OnChatMessage()
        if event == "CHAT_MSG_CHANNEL" then
            local msg = arg1
            local sender = arg2
            local chName = arg9

            if chName == channelName and channelName ~= "" then
                if msg == "CM_SYNC_STARTED" then
                    if sender ~= UnitName("player") and not collecting then
                        StartCollecting(sender)
                    end
                elseif msg == "CM_SYNC_STOPPED" then
                    if collecting and sender == collectingFrom then
                        StopCollecting(sender)   -- Pass 'sender' here
                        ResetCollection()
                    end
                else
                    if collecting and sender == collectingFrom then
                        local iStart, iEnd, msgIndex, chunk = string.find(msg, "^CM_(%d+):(.+)$")
                        if msgIndex and chunk then
                            msgIndex = tonumber(msgIndex)
                            collectedChunks[msgIndex] = chunk
                            collectingCount = collectingCount + 1
                        end
                    end
                end
            end
        end
    end

    function ReadData(mode)
        if not ConsumesManager_Options.Channel or ConsumesManager_Options.Channel == "" then
            return
        end

        channelName = DecodeMessage(ConsumesManager_Options.Channel)
        local channelNumber = GetChannelName(channelName)

        if not channelNumber or channelNumber == 0 then
            return
        end

        if mode == "start" then
            if not eventFrame then
                eventFrame = CreateFrame("Frame")
                eventFrame:SetScript("OnEvent", OnChatMessage)
            end
            eventFrame:RegisterEvent("CHAT_MSG_CHANNEL")
        elseif mode == "stop" then
            if eventFrame then
                eventFrame:UnregisterEvent("CHAT_MSG_CHANNEL")
                if collecting then
                    StopCollecting(collectingFrom)  -- Pass 'collectingFrom'
                    ResetCollection()
                end
            end
        end
    end

    -- Register for PLAYER_LOGIN (or VARIABLES_LOADED in 1.12) to start listening automatically
    local startupFrame = CreateFrame("Frame")
    startupFrame:RegisterEvent("PLAYER_LOGIN")
    startupFrame:SetScript("OnEvent", function()
        if event == "PLAYER_LOGIN" then
            ReadData("start")
        end
    end)


    function combineVariableTables(compressed_message)
        local receivedTable = {}
        local realmName = GetRealmName()

        local decoded = DecodeMessage(compressed_message)
        local uncompressed = lzw:decompress(decoded)
        receivedTable = Converter:StringToTable(uncompressed)

        -- Initialize if needed
        ConsumesManager_Data[realmName] = ConsumesManager_Data[realmName] or {}
        
        -- Auto-select new characters
        ConsumesManager_Options["Characters"] = ConsumesManager_Options["Characters"] or {}
        for characterName, charData in pairs(receivedTable) do
            if type(charData) == "table" and characterName ~= "faction" then
                if ConsumesManager_Options["Characters"][characterName] == nil then
                    ConsumesManager_Options["Characters"][characterName] = true
                end
            end
        end

        local function mergeTables(original, newData)
            for key, value in newData do
                if type(value) == "table" and type(original[key]) == "table" then
                    mergeTables(original[key], value)
                else
                    original[key] = value
                end
            end
        end

        mergeTables(ConsumesManager_Data[realmName], receivedTable)
        ConsumesManager_UpdateAllContent()
    end

-- BASE64 ENCODE AND DECODE --------------------------------------------------------------------------------------------------

    local b = "ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789+/"
    local d = {}
    do
        local i = 1
        while i <= string.len(b) do
            local c = string.sub(b, i, i)
            d[c] = i - 1
            i = i + 1
        end
    end

    function EncodeMessage(data)
        local encoded = {}
        local length = string.len(data)
        local i = 1
        while i <= length do
            local c1 = string.byte(data, i, i) i = i + 1
            local c2 = (i <= length) and string.byte(data, i, i) or nil i = i + 1
            local c3 = (i <= length) and string.byte(data, i, i) or nil i = i + 1

            local o1 = bit.rshift(c1, 2)
            local o2 = bit.bor(bit.lshift(bit.band(c1, 3),4), (c2 and bit.rshift(c2, 4) or 0))
            local o3 = (c2 and bit.bor(bit.lshift(bit.band(c2,15),2), (c3 and bit.rshift(c3,6) or 0)) or 64)
            local o4 = (c3 and bit.band(c3,63) or 64)

            table.insert(encoded, string.sub(b, o1+1, o1+1))
            table.insert(encoded, string.sub(b, o2+1, o2+1))
            if o3 ~= 64 then
                table.insert(encoded, string.sub(b, o3+1, o3+1))
            else
                table.insert(encoded, "=")
            end
            if o4 ~= 64 then
                table.insert(encoded, string.sub(b, o4+1, o4+1))
            else
                table.insert(encoded, "=")
            end
        end
        return table.concat(encoded, "")
    end

    function DecodeMessage(str)
        local decoded = {}
        local length = string.len(str)
        local i = 1
        while i <= length do
            local c1 = string.sub(str, i, i) i = i + 1
            local c2 = string.sub(str, i, i) i = i + 1
            if (not c2) or (c1 == '=') or (c2 == '=') then
                break
            end
            local c3 = string.sub(str, i, i) i = i + 1
            local c4 = string.sub(str, i, i) i = i + 1

            local dc1 = d[c1]
            local dc2 = d[c2]
            local dc3 = (c3 and c3 ~= '=' and d[c3]) or nil
            local dc4 = (c4 and c4 ~= '=' and d[c4]) or nil

            local o1 = bit.bor(bit.lshift(dc1, 2), bit.rshift(dc2, 4))
            table.insert(decoded, string.char(o1))

            if dc3 then
                local o2 = bit.bor(bit.lshift(bit.band(dc2, 15),4), bit.rshift(dc3, 2))
                table.insert(decoded, string.char(o2))
                if dc4 then
                    local o3 = bit.bor(bit.lshift(bit.band(dc3, 3),6), dc4)
                    table.insert(decoded, string.char(o3))
                end
            end
        end
        return table.concat(decoded, "")
    end

