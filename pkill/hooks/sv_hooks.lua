--[[
    Parallax Framework
    Copyright (c) 2025 Parallax Framework Contributors

    This file is part of the Parallax Framework and is licensed under the MIT License.
    You may use, copy, modify, merge, publish, distribute, and sublicense this file
    under the terms of the LICENSE file included with this project.

    Attribution is required. If you use or modify this file, you must retain this notice.
]]

local MODULE = MODULE

function MODULE:PlayerDeath(client)
    if ( !ax.config:Get("permakill.enabled") ) then return end

    local character = client:GetCharacter()
    if ( !character ) then return end

    local result = hook.Run("PreCharacterPermaKill", client, character)
    if ( result == false ) then return end

    ax.character:Delete(character:GetID(), function(query)
        if ( query == false ) then return end

        client:Notify("Your character has been permanently killed and cannot be used again.")
    end)
end

function MODULE:PreCharacterPermaKill(client, character)
    return true
end