-- Command to open friend's GUI
--  /c __radar-equipment__ game.player.opened = storage.tracked_by_entity[game.player.selected.unit_number].radar

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

---@param owner LuaEntity
---@return LuaEntity?
local function create_radar(owner)
    local radar = owner.surface.create_entity{
        name = "hidden-equipment-radar-friend",
        position = owner.position,
        force = owner.force,
        -- Not making quality, because no way to hide the quality icon.
    }
    if not radar then return end
    radar.destructible = false
    radar.follow_target = owner -- Set your spider friend to follow the owner

    -- Add some high quality equipment to make radar faster
    local grid = radar.grid
    if not grid then return end
    grid.put{ name = "fission-reactor-equipment", quality = highest_quality, position = { 0, 0 }, }    
    grid.put{ name = "exoskeleton-equipment", quality = highest_quality, position = { 4, 0 }, }    
    grid.put{ name = "exoskeleton-equipment", quality = highest_quality, position = { 6, 0 }, }    
    grid.put{ name = "exoskeleton-equipment", quality = highest_quality, position = { 8, 0 }, }

    return radar
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
        tracker.radar = create_radar(owner)
        radar = tracker.radar
        if radar then
            radar.destructible = false
            radar.follow_target = owner -- Set your spider friend to follow the owner
        end

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

        radar.follow_target = owner -- Make sure it wasn't lost somehow
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
    if not (entity.valid and entity.grid) then destroy(tracker) end
    local remaining_equipment = entity.grid.find("radar-equipment")
    if remaining_equipment then
        tracker.equipment = remaining_equipment
    else
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

    if not entity.grid then destroy(tracker) return end
    local remaining_equipment = entity.grid.find("radar-equipment")
    if remaining_equipment then
        tracker.equipment = remaining_equipment
    else
        destroy(tracker)  -- Only destroy the tracker if if the last equipment is removed
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

---@param event EventData.on_player_selected_area 
script.on_event(defines.events.on_player_selected_area , function(event)
    -- Workaroud for https://forums.factorio.com/117889
    -- And the selection tool doesn't curly obey "not-selectable-in-game"
    if event.item ~= "spidertron-remote" and event.item ~= "sp-spidertron-patrol-remote" then return end
    local player = game.get_player(event.player_index)
    if not player then return end

    local selected_our_friend = false
    local new_list = { }
    for _, spider in pairs(player.spidertron_remote_selection or { }) do
        if spider.name == "hidden-equipment-radar-friend" then
            selected_our_friend = true
        else
            table.insert(new_list, spider)
        end
    end

    if selected_our_friend then
        player.spidertron_remote_selection = new_list
    end
end)

local function init()
    ---@type table<uint, Tracker> by unit_number
    storage.tracked_by_entity = storage.tracked_by_entity or { }
    ---@type table<uint, Tracker> by unique_id
    storage.tracked_by_grid = storage.tracked_by_grid or { }
end

script.on_init(init)
script.on_configuration_changed(init)