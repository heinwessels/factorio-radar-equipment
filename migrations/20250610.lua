---@type string?
local old_tech_name = nil
for prototype_name, prototype in pairs(prototypes.technology) do
    for _, effect in pairs(prototype.effects) do
        if effect.type == "unlock-recipe" and effect.recipe == "tank" then
            old_tech_name = prototype_name
            break
        end
    end
end

if not old_tech_name then return end

for _, force in pairs(game.forces) do
    local old_tech = force.technologies[old_tech_name]
    local new_tech = force.technologies["radar-equipment"]
    if not (old_tech and new_tech) then return end
    new_tech.researched = old_tech.researched
end
