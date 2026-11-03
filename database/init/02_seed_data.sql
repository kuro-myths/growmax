-- =============================================================
-- GrowCraft 3D — Seed data
-- Balancing awal (bukan waktu resmi Growtopia) per master prompt E.1
-- =============================================================

INSERT INTO item_definitions (id, name, category, rarity) VALUES
    ('block_grass',     'Grass Block',   'blocks', 'common'),
    ('block_dirt',      'Dirt Block',    'blocks', 'common'),
    ('block_stone',     'Stone Block',   'blocks', 'common'),
    ('block_bedrock',   'Bedrock Block', 'blocks', 'legendary'),
    ('block_wood',      'Wood Block',    'blocks', 'common'),
    ('block_sand',      'Sand Block',    'blocks', 'common'),
    ('block_farm_soil', 'Tanah Garap',   'blocks', 'common'),
    ('tool_watering_can','Watering Can', 'tools',  'uncommon')
ON CONFLICT (id) DO NOTHING;

-- seed_<id> otomatis jadi item_id di inventory
INSERT INTO seed_definitions (id, name, rarity, growth_seconds, gem_min, gem_max, seed_min, seed_max, price) VALUES
    ('door',      'Door Tree',      'common',     300,   3,    8,   1, 2,     5),
    ('apple',     'Apple Tree',     'uncommon',   900,  10,   20,   1, 3,    25),
    ('pine',      'Pine Tree',      'uncommon',  1200,  12,   26,   1, 3,    30),
    ('crystal',   'Crystal Tree',   'rare',     3600,  40,   70,   2, 4,    80),
    ('diamond',   'Diamond Tree',   'epic',    10800, 120,  250,   3, 5,   250),
    ('legendary', 'Legendary Tree', 'legendary',86400, 400,  900,   5, 9,   800)
ON CONFLICT (id) DO NOTHING;
