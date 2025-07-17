--[[
    Parallax Framework
    Copyright (c) 2025 Parallax Framework Contributors

    This file is part of the Parallax Framework and is licensed under the MIT License.
    You may use, copy, modify, merge, publish, distribute, and sublicense this file
    under the terms of the LICENSE file included with this project.

    Attribution is required. If you use or modify this file, you must retain this notice.
]]

local MODULE = MODULE

MODULE.Name = "Perma Kill"
MODULE.Author = "bloodycop6385"
MODULE.Description = "Allows player's characters to be permanently killed upon death."

ax.config:Register("permakill.enabled", {
    Name = "config.permakill.enabled",
    Description = "config.permakill.enabled.help",
    Category = "config.permakill",
    Type = ax.types.bool,
    Default = true,
})