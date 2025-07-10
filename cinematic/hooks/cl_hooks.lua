--[[
    Parallax Framework
    Copyright (c) 2025 Parallax Framework Contributors

    This file is part of the Parallax Framework and is licensed under the MIT License.
    You may use, copy, modify, merge, publish, distribute, and sublicense this file
    under the terms of the LICENSE file included with this project.

    Attribution is required. If you use or modify this file, you must retain this notice.
]]

local MODULE = MODULE

function MODULE:CalcView(client, pos, ang, fov)
    if ( !ax.Cinematic.Active ) then return end

    local camPos, camAng, camFov = ax.Cinematic:GetValue()
    if ( !camPos ) then return end

    return {
        origin = camPos,
        angles = camAng,
        fov = camFov,
        drawviewer = true
    }
end

local offsetVector = Vector()

function MODULE:PostDrawTranslucentRenderables()
    if ( !ax.Cinematic.Debug ) then return end

    for id, path in pairs(ax.Cinematic.RenderPaths) do
        for i = 2, #path do
            local prev = path[i - 1]
            local node = path[i]

            local points = table.Copy(node.ctrl or {})
            table.insert(points, 1, prev.pos)
            points[#points + 1] = node.pos

            local last = points[1]
            for j = 1, 60 do
                local t = j / 60
                local pos = ax.Cinematic:Bezier(points, t)

                -- Layered line thickness by offsetting
                for offset = -1, 1 do
                    offsetVector.z = offset

                    render.DrawLine(
                        last + offsetVector,
                        pos + offsetVector,
                        ax.color:Get("orange"), true
                    )
                end

                last = pos
            end

            -- Anchor
            render.DrawSphere(prev.pos, 4, 12, 12, Color(0, 255, 0))
            render.DrawSphere(node.pos, 4, 12, 12, Color(0, 255, 0))

            -- Control handles
            for j = 1, #node.ctrl do
                local ctrl = node.ctrl[j]
                render.DrawSphere(ctrl, 2, 8, 8, Color(255, 0, 0))
                render.DrawLine(node.pos, ctrl, Color(255, 0, 0), true)
            end
        end
    end
end