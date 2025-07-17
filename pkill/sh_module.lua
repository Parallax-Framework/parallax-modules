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