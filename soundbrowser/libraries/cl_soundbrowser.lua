--[[
    Parallax Framework
    Copyright (c) 2025 Parallax Framework Contributors

    This file is part of the Parallax Framework and is licensed under the MIT License.
    You may use, copy, modify, merge, publish, distribute, and sublicense this file
    under the terms of the LICENSE file included with this project.

    Attribution is required. If you use or modify this file, you must retain this notice.
]]

-- Console command to open sound browser
concommand.Add("ax_sound_browser", function()
    if ( LocalPlayer():IsAdmin() ) then
        if ( !IsValid(soundBrowser) ) then
            soundBrowser = vgui.Create("ax.sound.browser")
        else
            soundBrowser:Show()
        end
    end
end)

if ( IsValid(soundBrowser) ) then
    soundBrowser:Remove()
end