--[[
    Parallax Framework
    Copyright (c) 2025 Parallax Framework Contributors

    This file is part of the Parallax Framework and is licensed under the MIT License.
    You may use, copy, modify, merge, publish, distribute, and sublicense this file
    under the terms of the LICENSE file included with this project.

    Attribution is required. If you use or modify this file, you must retain this notice.
]]

util.AddNetworkString("ax.sound.browser.play.global")

net.Receive("ax.sound.browser.play.global", function(len, ply)
    if ( !ply:IsAdmin() ) then return end

    local soundPath = net.ReadString()
    if ( !soundPath or soundPath == "" ) then return end

    net.Start("ixPlayGlobalSound")
    net.WriteString(soundPath)
    net.Broadcast()
end)