-- The hidden radar is a spider that follows the tank around

data:extend{
    {
        type = "spider-vehicle",
        name = "hidden-equipment-radar-friend",
        icon = "__base__/graphics/icons/spidertron.png",
        hidden_in_factoriopedia = true,
        weight = 1,
        braking_force = 1,
        friction_force = 1,
        flags = {"not-repairable", "not-on-map", "not-deconstructable", "not-blueprintable", "not-flammable", "not-selectable-in-game", "not-upgradable", "not-in-kill-statistics"},
        max_health = 3000,
        energy_per_hit_point = 1,
        inventory_size = 1,
        height = 1,
        torso_rotation_speed = 0.005,
        chunk_exploration_radius = 3,
        energy_source = { type = "void" },
        movement_energy_consumption = "250kW",
        equipment_grid = "spidertron-equipment-grid",
        chain_shooting_cooldown_modifier = 0.5,
        automatic_weapon_cycling = false,
        allow_passengers = false,
        spider_engine =
        {
            legs =
            {
                { -- 1
                    leg = "hidden-equipment-radar-friend-leg",
                    mount_position = {0, -1},
                    ground_position = {0, -1},
                    walking_group = 1,
                    leg_hit_the_ground_trigger = nil
                },
            },
        },
    },
    {
        type = "spider-leg",
        name = "hidden-equipment-radar-friend-leg",
        hidden = true,
        icon = "__base__/graphics/icons/spidertron.png",
        collision_mask = { layers = { } },
        target_position_randomisation_distance = 0.25,
        minimal_step_size = 4,
        stretch_force_scalar = 1,
        knee_height = 2.5,
        knee_distance_factor = 0.4,
        initial_movement_speed = 100,
        movement_acceleration = 100,
        max_health = 100,
        base_position_selection_distance = 6,
        movement_based_position_selection_distance = 4,
        selectable_in_game = false,
        alert_when_damaged = false,
    },
}