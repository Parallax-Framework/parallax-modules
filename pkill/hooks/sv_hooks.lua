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