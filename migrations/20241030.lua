for _, tracker in pairs(storage.tracked_by_entity) do
    -- We need to destroy the legendary spiders and replace them
    -- with normal ones which has legendary equipment.
    tracker.radar.destroy()
end