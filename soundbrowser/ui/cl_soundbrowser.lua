--[[
    Parallax Framework
    Copyright (c) 2025 Parallax Framework Contributors

    This file is part of the Parallax Framework and is licensed under the MIT License.
    You may use, copy, modify, merge, publish, distribute, and sublicense this file
    under the terms of the LICENSE file included with this project.

    Attribution is required. If you use or modify this file, you must retain this notice.
]]

local PANEL = {}

function PANEL:Init()
    self:SetSize(ScrW() / 2, ScrH() / 1.25)
    self:Center()
    self:SetTitle("Sound Browser")
    self:MakePopup()
    self:SetDeleteOnClose(false) -- Don't delete on close

    -- Current selected sound
    self.selectedSound = nil
    self.currentChannel = nil
    self.loadedDirectories = {} -- Track which directories have been loaded
    self.isSearching = false -- Track if we're currently searching

    -- Create tabs
    self.tabs = self:Add("DPropertySheet")
    self.tabs:Dock(FILL)
    self.tabs:DockMargin(8, 8, 8, 8)
    self.tabs.Paint = function(panel, width, height)
        surface.SetDrawColor(0, 0, 0, 66)
        surface.DrawRect(0, 0, width, height)

        local activeTab = panel:GetActiveTab()
        if ( activeTab ) then
            surface.SetDrawColor(255, 255, 255, 50)
            surface.DrawRect(activeTab:GetX(), activeTab:GetY(), activeTab:GetWide(), activeTab:GetTall())
        end
    end

    -- Create directory browser tab
    self:CreateDirectoryTab()

    -- Create search tab
    self:CreateSearchTab()

    -- Create control panel
    self:CreateControlPanel()

    -- Load root directories only
    self:InitializeRootDirectories()

    for k, v in pairs(self.tabs.Items) do
        v.Tab:SetFont("ax.small")
        v.Tab:SetTextColor(color_white)
        v.Tab.Paint = nil
        v.Tab.ApplySchemeSettings = function(tab)
            local extraInset = ScreenScale(2)
            if ( tab.Image ) then
                extraInset = extraInset + tab.Image:GetWide()
            end

            tab:SetTextInset(extraInset, 2)
            local w, h = tab:GetContentSize()
            h = ScreenScaleH(8)

            tab:SetSize(w + ScreenScale(8), h)
        end
    end
end

-- Override the close function to hide instead of closing
function PANEL:Close()
    self:SetVisible(false)
    self:StopAllSounds() -- Stop sounds when hiding
end

-- Override OnClose to prevent deletion
function PANEL:OnClose()
    self:Close()
    return true -- Prevent default close behavior
end

-- Add a method to show the panel again
function PANEL:Show()
    self:SetVisible(true)
    self:MakePopup()
end

function PANEL:CreateDirectoryTab()
    local panel = vgui.Create("DPanel")
    panel:SetPaintBackground(false)

    -- Refresh button
    local refreshBtn = panel:Add("ax.button.flat")
    refreshBtn:SetText("Refresh")
    refreshBtn:Dock(TOP)
    refreshBtn:DockMargin(0, 0, 0, 8)
    refreshBtn.DoClick = function()
        Derma_Query("Are you sure you want to refresh the sound list?", "Confirm Refresh",
            "Yes", function()
                self:RefreshSoundList()
            end,
            "No", function() end
        )
    end

    -- Directory tree
    self.directoryTree = panel:Add("DTree")
    self.directoryTree:Dock(FILL)
    self.directoryTree:SetLineHeight(draw.GetFontHeight("ax.small"))

    -- Style the tree
    self.directoryTree.Paint = function(tree, w, h)
        surface.SetDrawColor(0, 0, 0, 66)
        surface.DrawRect(0, 0, w, h)
    end

    self.tabs:AddSheet("Directories", panel, "icon16/folder.png")
end

function PANEL:CreateSearchTab()
    local panel = vgui.Create("DPanel")
    panel:SetPaintBackground(false)

    -- Search bar
    local searchBar = panel:Add("ax.text.entry")
    searchBar:Dock(TOP)
    searchBar:DockMargin(0, 0, 0, 8)
    searchBar:SetFont("ax.small")
    searchBar:SetPlaceholderText("Search sounds...")

    -- Progress bar (initially hidden)
    self.searchProgress = panel:Add("DProgress")
    self.searchProgress:SetTall(ScreenScaleH(16))
    self.searchProgress:Dock(TOP)
    self.searchProgress:DockMargin(0, 0, 0, 8)
    self.searchProgress:SetVisible(false)

    -- Search results
    self.searchResults = panel:Add("DListView")
    self.searchResults:Dock(FILL)
    self.searchResults:SetMultiSelect(false)
    self.searchResults:AddColumn("Sound Path")

    -- Style the search results
    self.searchResults.Paint = function(list, w, h)
        surface.SetDrawColor(0, 0, 0, 66)
        surface.DrawRect(0, 0, w, h)
    end

    -- Search functionality with debounce
    searchBar.OnTextChanged = function(entry)
        if ( timer.Exists("ax.sound.browser.search") ) then
            timer.Remove("ax.sound.browser.search")
        end

        local text = entry:GetValue()
        if ( text == "" or #text < 2 ) then
            self.searchResults:Clear()
            return
        end

        timer.Create("ax.sound.browser.search", 0.3, 1, function()
            self:SearchSounds(text)
        end)
    end

    -- Handle selection
    self.searchResults.OnRowSelected = function(list, index, row)
        local soundPath = row:GetColumnText(1)
        self:SelectSound(soundPath)
    end

    self.tabs:AddSheet("Search", panel, "icon16/magnifier.png")
end

function PANEL:CreateControlPanel()
    local panel = self:Add("DPanel")
    panel:Dock(BOTTOM)
    panel:DockMargin(8, 0, 8, 8)
    panel.Paint = function(pnl, w, h)
        surface.SetDrawColor(0, 0, 0, 66)
        surface.DrawRect(0, 0, w, h)
    end

    -- Selected sound label
    self.selectedLabel = panel:Add("ax.text")
    self.selectedLabel:Dock(TOP)
    self.selectedLabel:DockMargin(8, 8, 8, 0)
    self.selectedLabel:SetText("No sound selected", true)

    -- Button panel
    local buttonPanel = panel:Add("DPanel")
    buttonPanel:Dock(TOP)
    buttonPanel:DockMargin(8, 8, 8, 0)
    buttonPanel:SetPaintBackground(false)

    -- Play button
    self.playBtn = buttonPanel:Add("ax.button.flat")
    self.playBtn:SetText("Play")
    self.playBtn:Dock(LEFT)
    self.playBtn:SetEnabled(false)
    self.playBtn.DoClick = function()
        self:PlaySound()
    end

    -- Stop button
    self.stopBtn = buttonPanel:Add("ax.button.flat")
    self.stopBtn:SetText("Stop All")
    self.stopBtn:Dock(LEFT)
    self.stopBtn.DoClick = function()
        self:StopAllSounds()
    end

    -- Copy button
    self.copyBtn = buttonPanel:Add("ax.button.flat")
    self.copyBtn:SetText("Copy Path")
    self.copyBtn:Dock(LEFT)
    self.copyBtn:SetEnabled(false)
    self.copyBtn.DoClick = function()
        self:CopyPath()
    end

    -- Global play button (admin only)
    if ( LocalPlayer():IsAdmin() ) then
        self.globalBtn = buttonPanel:Add("ax.button.flat")
        self.globalBtn:SetText("Play Global")
        self.globalBtn:Dock(LEFT)
        self.globalBtn:SetEnabled(false)
        self.globalBtn.DoClick = function()
            self:PlayGlobal()
        end
    end

    buttonPanel:SetTall(math.max(self.playBtn:GetTall(), self.stopBtn:GetTall(), self.copyBtn:GetTall(), self.globalBtn and self.globalBtn:GetTall() or 0) / 1.5)

    -- Pitch controls
    local pitchPanel = panel:Add("DPanel")
    pitchPanel:Dock(TOP)
    pitchPanel:DockMargin(8, 0, 8, 8)
    pitchPanel:SetPaintBackground(false)

    self.pitchSlider = pitchPanel:Add("ax.slider")
    self.pitchSlider:Dock(LEFT)
    self.pitchSlider:SetMin(50)
    self.pitchSlider:SetMax(200)
    self.pitchSlider:SetValue(100)
    self.pitchSlider:SetDecimals(0)
    self.pitchSlider:SetTooltip("Adjust the pitch of the sound (50% to 200%)")
    self.pitchSlider:SetWide(self:GetWide() / 2 - 16)

    local pitchPlayBtn = pitchPanel:Add("ax.button.flat")
    pitchPlayBtn:SetText("Play Pitched")
    pitchPlayBtn:SizeToContents()
    pitchPlayBtn:Dock(LEFT)
    pitchPlayBtn:DockMargin(8, 0, 0, 0)
    pitchPlayBtn:SetEnabled(false)
    pitchPlayBtn.DoClick = function()
        self:PlayPitched()
    end

    pitchPanel:SetTall(math.max(self.pitchSlider:GetTall(), pitchPlayBtn:GetTall()) / 1.5)

    self.pitchPlayBtn = pitchPlayBtn

    panel:SetTall(self.selectedLabel:GetTall() + buttonPanel:GetTall() + pitchPanel:GetTall() + 16)
end

function PANEL:InitializeRootDirectories()
    self.loadedDirectories = {}
    self.directoryTree:Clear()

    -- Root sound directory
    local rootNode = self.directoryTree:AddNode("sound", "icon16/folder.png")
    rootNode:SetExpanded(true)
    rootNode.Label:SetTextColor(color_white)
    rootNode.Label:SetFont("ax.small")
    rootNode.path = "sound"
    rootNode.loaded = false

    -- Load only the first level of directories
    self:LoadDirectoryContents("sound", rootNode)
end

function PANEL:LoadDirectoryContents(path, node)
    if ( self.loadedDirectories and self.loadedDirectories[path] ) then
        return -- Already loaded
    end

    local files, folders = file.Find(path .. "/*", "GAME")

    -- Add folders with placeholder content
    for _, folder in pairs(folders) do
        local folderPath = path .. "/" .. folder
        local folderNode = node:AddNode(folder, "icon16/folder.png")
        folderNode:SetExpanded(false)
        folderNode.Label:SetTextColor(color_white)
        folderNode.Label:SetFont("ax.small")
        folderNode.path = folderPath
        folderNode.loaded = false
        folderNode.isDirectory = true

        -- Add a placeholder child to show expansion arrow
        local placeholder = folderNode:AddNode("Loading...", "icon16/hourglass.png")
        placeholder:SetExpanded(false)
        placeholder.Label:SetTextColor(color_white)
        placeholder.Label:SetFont("ax.small")
        placeholder.isPlaceholder = true

        -- Store reference to the panel for the callback
        local panelRef = self

        -- Handle node selection for directories
        folderNode.OnNodeSelected = function(nodeThis)
            if ( !nodeThis.loaded ) then
                -- Remove placeholder
                for _, child in pairs(nodeThis:GetChildNodes()) do
                    if ( child.isPlaceholder ) then
                        child:Remove()
                        break
                    end
                end

                -- Load actual contents using the panel reference
                panelRef:LoadDirectoryContents(nodeThis.path, nodeThis)
                nodeThis.loaded = true
            end
        end
    end

    -- Add sound files
    for _, v in pairs(files) do
        local ext = string.GetExtensionFromFilename(v)
        if ( ext == "wav" or ext == "mp3" or ext == "ogg" ) then
            local soundPath = path .. "/" .. v
            local fileNode = node:AddNode(v, "icon16/sound.png")
            fileNode:SetExpanded(false)
            fileNode:SetIcon("icon16/sound.png")
            fileNode.Label:SetTextColor(color_white)
            fileNode.Label:SetFont("ax.small")
            fileNode.soundPath = soundPath
            fileNode.isDirectory = false

            -- Store reference to the panel for the callback
            local panelRef = self

            fileNode.OnNodeSelected = function(nodeThis)
                panelRef:SelectSound(nodeThis.soundPath)
            end
        end
    end

    -- Mark this directory as loaded
    self.loadedDirectories[path] = true

    -- Sort nodes - directories first, then files
    self:SortNodeChildren(node)
end

function PANEL:SortNodeChildren(node)
    local children = node:GetChildNodes()
    if ( !children or #children == 0 ) then return end

    table.sort(children, function(a, b)
        -- Directories first
        if ( a.isDirectory and !b.isDirectory ) then
            return true
        elseif ( !a.isDirectory and b.isDirectory ) then
            return false
        end

        -- Then alphabetically
        return a:GetText() < b:GetText()
    end)

    -- Reorder in the tree
    for i, child in pairs(children) do
        child:SetZPos(i)
    end
end

function PANEL:RefreshSoundList()
    -- Clear everything and reload
    self.loadedDirectories = {}
    self:InitializeRootDirectories()

    ax.notification:Add("Sound list refreshed.")
end

function PANEL:SearchSounds(query)
    if ( self.isSearching ) then
        return -- Already searching
    end

    self.searchResults:Clear()

    if ( query == "" or #query < 2 ) then
        return
    end

    self.isSearching = true
    self.searchProgress:SetVisible(true)
    self.searchProgress:SetFraction(0)

    query = query:lower()

    -- Get all directories to search
    local dirsToSearch = {}
    self:GetAllDirectories("sound", dirsToSearch)

    local totalDirs = #dirsToSearch
    local processedDirs = 0
    local results = {}

    -- Search function that processes one directory at a time
    local function searchNextDirectory()
        if ( processedDirs >= totalDirs ) then
            -- Search complete
            self.isSearching = false
            self.searchProgress:SetVisible(false)

            -- Add all results to the list
            for _, soundPath in pairs(results) do
                soundPath = string.gsub(soundPath, "^sound/", "")
                soundPath = string.gsub(soundPath, "^sound\\", "")
                soundPath = string.lower(soundPath)

                -- Add to search results
                local line = self.searchResults:AddLine(soundPath)
                line.soundPath = soundPath
            end

            ax.notification:Add("Search complete, " .. #results .. " sounds found.")
            return
        end

        processedDirs = processedDirs + 1
        local currentDir = dirsToSearch[processedDirs]

        -- Update progress
        self.searchProgress:SetFraction(processedDirs / totalDirs)

        -- Search current directory
        local files, _ = file.Find(currentDir .. "/*", "GAME")
        for _, v in pairs(files) do
            local ext = string.GetExtensionFromFilename(v)
            if ( ext == "wav" or ext == "mp3" or ext == "ogg" ) then
                local soundPath = currentDir .. "/" .. v
                if ( soundPath:lower():find(query, 1, true) ) then
                    table.insert(results, soundPath)
                end
            end
        end

        -- Continue with next directory on next frame
        timer.Simple(0.001, searchNextDirectory)
    end

    -- Start the search
    searchNextDirectory()
end

function PANEL:GetAllDirectories(path, dirList)
    table.insert(dirList, path)

    local _, folders = file.Find(path .. "/*", "GAME")
    for _, folder in pairs(folders) do
        self:GetAllDirectories(path .. "/" .. folder, dirList)
    end
end

function PANEL:SelectSound(soundPath)
    if ( !soundPath or soundPath == "" ) then
        self.selectedSound = nil
        self.selectedLabel:SetText("No sound selected")
        self.playBtn:SetEnabled(false)
        self.copyBtn:SetEnabled(false)
        self.pitchPlayBtn:SetEnabled(false)

        if ( self.globalBtn ) then
            self.globalBtn:SetEnabled(false)
        end

        return
    end

    -- Remove sound/ from the path
    soundPath = string.gsub(soundPath, "^sound/", "")
    soundPath = string.gsub(soundPath, "^sound\\", "")
    soundPath = string.lower(soundPath)

    self.selectedSound = soundPath
    self.selectedLabel:SetText("Selected: " .. soundPath)

    -- Enable buttons
    self.playBtn:SetEnabled(true)
    self.copyBtn:SetEnabled(true)
    self.pitchPlayBtn:SetEnabled(true)

    if ( self.globalBtn ) then
        self.globalBtn:SetEnabled(true)
    end
end

function PANEL:PlaySound()
    if ( !self.selectedSound ) then return end

    self:StopAllSounds()

    timer.Simple(0.1, function()
        if ( !IsValid(self) ) then return end -- Check if panel is still valid

        self.currentChannel = CreateSound(LocalPlayer(), self.selectedSound)
        self.currentChannel:Play()
    end)
end

function PANEL:PlayPitched()
    if ( !self.selectedSound ) then return end

    self:StopAllSounds()

    local pitch = self.pitchSlider:GetValue()

    timer.Simple(0.1, function()
        if ( !IsValid(self) ) then return end -- Check if panel is still valid

        self.currentChannel = CreateSound(LocalPlayer(), self.selectedSound)
        self.currentChannel:ChangePitch(pitch)
        self.currentChannel:Play()
    end)
end

function PANEL:StopAllSounds()
    if ( self.currentChannel ) then
        self.currentChannel:Stop()
        self.currentChannel = nil
    end
end

function PANEL:CopyPath()
    if ( !self.selectedSound ) then return end

    SetClipboardText(self.selectedSound)

    ax.notification:Add("Copied \"" .. self.selectedSound .. "\" to clipboard.")
end

function PANEL:PlayGlobal()
    if ( !self.selectedSound or !LocalPlayer():IsAdmin() ) then return end

    net.Start("ax.sound.browser.play.global")
    net.WriteString(self.selectedSound)
    net.SendToServer()
end

function PANEL:OnKeyCodePressed(key)
    if ( key == KEY_SPACE ) then
        self:PlaySound()
    end
end

vgui.Register("ax.sound.browser", PANEL, "ax.frame")