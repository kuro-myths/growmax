-- =============================================================
-- GrowCraft 3D — Seed data
-- Katalog 13 seed, nama Indonesia, rarity score 1-100
-- (skala terinspirasi Rare Seed Pack Growtopia; data orisinal)
-- Tier: 1-12 Umum · 13-24 Tidak Umum · 25-40 Langka · 41-60 Epik
--       61-80 Legendaris · 81-100 Mistis
-- =============================================================

INSERT INTO item_definitions (id, name, category, rarity) VALUES
    ('block_grass',     'Blok Rumput',    'blocks', 'common'),
    ('block_dirt',      'Blok Tanah',     'blocks', 'common'),
    ('block_stone',     'Blok Batu',      'blocks', 'common'),
    ('block_bedrock',   'Blok Bedrock',   'blocks', 'legendary'),
    ('block_wood',      'Blok Kayu',      'blocks', 'common'),
    ('block_sand',      'Blok Pasir',     'blocks', 'common'),
    ('block_farm_soil', 'Tanah Garap',    'blocks', 'common'),
    ('tool_watering_can','Kaleng Penyiram','tools', 'uncommon'),
    ('tool_fist',       'Tinju Dasar',    'tools',  'common'),
    ('tool_analyzer',   'Kaca Analisis',  'tools',  'uncommon')
ON CONFLICT (id) DO NOTHING;

-- seed_<id> otomatis jadi item_id di inventory
INSERT INTO seed_definitions (id, name, rarity, rarity_score, growth_seconds, gem_min, gem_max, seed_min, seed_max, price) VALUES
    ('door',      'Pohon Pintu',     'common',      2,   300,   3,    8,   1, 2,     5),
    ('grass',     'Pohon Rumput',    'common',      5,   420,   4,   10,   1, 2,     8),
    ('apple',     'Pohon Apel',      'uncommon',   15,   900,  10,   20,   1, 3,    25),
    ('pine',      'Pohon Pinus',     'uncommon',   17,  1200,  12,   26,   1, 3,    30),
    ('orange',    'Pohon Jeruk',     'uncommon',   19,  1500,  14,   30,   1, 3,    40),
    ('cactus',    'Kaktus Emas',     'uncommon',   21,  1800,  18,   38,   2, 3,    55),
    ('coral',     'Terumbu Karang',  'rare',       25,  2700,  30,   60,   2, 4,    80),
    ('crystal',   'Pohon Kristal',   'rare',       33,  3600,  40,   70,   2, 4,   120),
    ('manggis',   'Pohon Manggis',   'epic',       41,  5400,  90,  180,   3, 5,   220),
    ('diamond',   'Pohon Berlian',   'epic',       52, 10800, 120,  250,   3, 5,   350),
    ('durian',    'Pohon Durian',    'epic',       58, 14400, 200,  420,   4, 6,   500),
    ('legendary', 'Pohon Legendaris','legendary',  72, 43200, 400,  900,   5, 9,  1200),
    ('naga',      'Pohon Naga',      'mythic',     88, 86400, 800, 2000,   6, 10, 2500)
ON CONFLICT (id) DO NOTHING;
