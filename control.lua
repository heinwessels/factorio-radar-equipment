---@type string
local highest_quality
local highest_level = -100
for quality, prototype in pairs(prototypes.quality) do
    if prototype.level > highest_level then
        highest_quality = quality
        highest_level = prototype.level
    end
end
assert(highest_quality)

---@class (exact) Tracker
---@field unit_number uint of the entity
---@field unique_id uint of the grid
---@field owner LuaEntity
---@field equipment LuaEquipment
---@field radar LuaEntity?

---@param entity LuaEntity
---@param equipment LuaEquipment
---@param unique_id uint
---@return Tracker
local function create(entity, equipment, unique_id)
    ---@type Tracker
    local tracker = storage.tracked_by_entity[entity.unit_number]
    if tracker then return tracker end

    tracker = {
        unit_number = entity.unit_number,
        unique_id = unique_id,
        owner = entity,
        equipment = equipment,
    }

    storage.tracked_by_entity[entity.unit_number] = tracker
    storage.tracked_by_grid[unique_id] = tracker

    return tracker
end

---@param tracker Tracker
local function destroy(tracker)
    if tracker.radar and tracker.radar.valid then
        tracker.radar.destroy()
    end

    local unique_id = tracker.unique_id
    storage.tracked_by_entity[tracker.unit_number] = nil
    storage.tracked_by_grid[unique_id] = nil
end

---@param tracker Tracker
local function update(tracker)
    local owner = tracker.owner
    local equipment = tracker.equipment
    local radar = tracker.radar

    if not (owner.valid and equipment.valid) then
        destroy(tracker)
        return
    end

    local has_energy = equipment.energy ~= 0 and not equipment.to_be_removed

    if has_energy and not (radar and radar.valid) then
        tracker.radar = owner.surface.create_entity{
            name = "hidden-equipment-radar-friend",
            position = owner.position,
            force = owner.force,
            quality = highest_quality, -- To make your friend speedy
        }
        radar = tracker.radar
        if not radar then
            -- A mod could've destroyed the hidden radar.
            destroy(tracker)
            return
        end
        radar.destructible = false
        radar.follow_target = owner -- Set your spider friend to follow the owner

    elseif not has_energy and radar then
        radar.destroy()
        tracker.radar = nil
    end

    if not has_energy then return end

    if radar then
        if radar.surface ~= owner.surface then
            radar.destroy()
            tracker.radar = nil
            return -- Friend will catch up on the next update
        end
    end
end

---@param event EventData.on_tick
script.on_event(defines.events.on_tick, function(event)
    for unit_number, tracker in pairs(storage.tracked_by_entity) do
        if (event.tick + unit_number) % (60 * 5) == 0 then
            update(tracker)
        end
    end
end)

---@param event EventData.on_equipment_inserted
script.on_event(defines.events.on_equipment_inserted, function (event)
    local entity = event.grid.entity_owner
    if not entity then return end -- Will only happen when player, which we don't care about

    local equipment = event.equipment
    if equipment.name ~= "radar-equipment" then return end

    create(entity, equipment, event.grid.unique_id)
end)

---@param event EventData.on_equipment_inserted
script.on_event(defines.events.on_equipment_removed, function (event)
    local tracker = storage.tracked_by_grid[event.grid.unique_id]
    if not tracker then return end
    local entity = tracker.owner
    if not entity.valid then destroy(tracker) end
    if not (entity.grid and entity.grid.find("radar-equipment")) then
        destroy(tracker)  -- Only destroy the tracker if if the last equipment is removed
    end
end)

---@param event EventData.on_player_mined_entity|EventData.on_robot_mined_entity|EventData.on_entity_died|EventData.script_raised_destroy|EventData.on_space_platform_mined_entity
local on_entity_destroyed = function(event)
    local entity = event.entity
    local unit_number = entity.unit_number
    if not unit_number then return end
    local tracker = storage.tracked_by_entity[entity.unit_number]
    if not tracker then return end

    if not entity.valid then destroy(tracker) end
    if not (entity.grid and entity.grid.find("radar-equipment")) then
        destroy(tracker) -- Only destroy the tracker if if the last equipment is removed
    end
end
script.on_event(defines.events.on_player_mined_entity, on_entity_destroyed)
script.on_event(defines.events.on_robot_mined_entity, on_entity_destroyed)
script.on_event(defines.events.on_entity_died, on_entity_destroyed)
script.on_event(defines.events.script_raised_destroy, on_entity_destroyed)
script.on_event(defines.events.on_space_platform_mined_entity, on_entity_destroyed)

---@param event EventData.on_entity_cloned
script.on_event(defines.events.on_entity_cloned, function (event)
    local unit_number = event.source.unit_number
    if not unit_number then return end
    local tracker = storage.tracked_by_entity[unit_number]
    if not tracker then return end

    local new_entity = event.destination
    local new_grid = new_entity.grid
    if not new_grid then return end -- That should never happen?
    local new_equipment = new_grid.find("radar-equipment")
    if not new_equipment then return end -- That should never happe?
    create(event.destination, new_equipment, new_grid.unique_id)
end)

local function init()
    ---@type table<uint, Tracker> by unit_number
    storage.tracked_by_entity = storage.tracked_by_entity or { }
    ---@type table<uint, Tracker> by unique_id
    storage.tracked_by_grid = storage.tracked_by_grid or { }
end

script.on_init(init)
script.on_configuration_changed(init)