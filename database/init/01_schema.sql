-- =============================================================
-- GrowCraft 3D — PostgreSQL schema
-- Mencerminkan master prompt section K (database design)
-- =============================================================

-- ---------- USERS & PROFILES ----------
CREATE TABLE IF NOT EXISTS users (
    id            uuid PRIMARY KEY DEFAULT gen_random_uuid(),
    username      varchar(32)  NOT NULL UNIQUE,
    password_hash text         NOT NULL,
    role          varchar(20)  NOT NULL DEFAULT 'player',
    created_at    timestamptz  NOT NULL DEFAULT now(),
    updated_at    timestamptz  NOT NULL DEFAULT now()
);

CREATE TABLE IF NOT EXISTS player_profiles (
    id             uuid PRIMARY KEY DEFAULT gen_random_uuid(),
    user_id        uuid NOT NULL UNIQUE REFERENCES users(id) ON DELETE CASCADE,
    display_name   varchar(32) NOT NULL,
    level          integer     NOT NULL DEFAULT 1,
    xp             integer     NOT NULL DEFAULT 0,
    gems           bigint      NOT NULL DEFAULT 20,
    harvested_count integer    NOT NULL DEFAULT 0,
    planted_count  integer     NOT NULL DEFAULT 0,
    created_at     timestamptz NOT NULL DEFAULT now(),
    updated_at     timestamptz NOT NULL DEFAULT now()
);

-- ---------- ITEM & SEED DEFINITIONS ----------
-- block_type: 1 grass, 2 dirt, 3 stone, 4 bedrock, 5 wood, 6 sand, 7 farm_soil
CREATE TABLE IF NOT EXISTS item_definitions (
    id       varchar(48) PRIMARY KEY,
    name     varchar(64) NOT NULL,
    category varchar(24) NOT NULL,
    rarity   varchar(16) NOT NULL DEFAULT 'common',
    metadata jsonb       NOT NULL DEFAULT '{}'
);

CREATE TABLE IF NOT EXISTS seed_definitions (
    id             varchar(48) PRIMARY KEY,
    name           varchar(64) NOT NULL,
    rarity         varchar(16) NOT NULL,
    growth_seconds integer     NOT NULL,
    gem_min        integer     NOT NULL,
    gem_max        integer     NOT NULL,
    seed_min       integer     NOT NULL,
    seed_max       integer     NOT NULL,
    price          integer     NOT NULL DEFAULT 0
);

-- ---------- WORLDS ----------
CREATE TABLE IF NOT EXISTS worlds (
    id         uuid PRIMARY KEY DEFAULT gen_random_uuid(),
    name       varchar(24) NOT NULL UNIQUE,
    owner_id   uuid REFERENCES player_profiles(id) ON DELETE SET NULL,
    is_public  boolean     NOT NULL DEFAULT true,
    width      integer     NOT NULL DEFAULT 24,
    depth      integer     NOT NULL DEFAULT 24,
    height     integer     NOT NULL DEFAULT 6,
    created_at timestamptz NOT NULL DEFAULT now(),
    updated_at timestamptz NOT NULL DEFAULT now()
);

CREATE TABLE IF NOT EXISTS world_blocks (
    id         bigserial PRIMARY KEY,
    world_id   uuid    NOT NULL REFERENCES worlds(id) ON DELETE CASCADE,
    x          integer NOT NULL,
    y          integer NOT NULL,
    z          integer NOT NULL,
    block_type smallint NOT NULL,
    UNIQUE (world_id, x, y, z)
);

-- ---------- FARMING ----------
-- Pertumbuhan dihitung dari planted_at UTC -> tetap jalan saat pemain offline
CREATE TABLE IF NOT EXISTS plants (
    id         uuid PRIMARY KEY DEFAULT gen_random_uuid(),
    world_id   uuid    NOT NULL REFERENCES worlds(id) ON DELETE CASCADE,
    x          integer NOT NULL,
    y          integer NOT NULL,
    z          integer NOT NULL,
    seed_id    varchar(48) NOT NULL REFERENCES seed_definitions(id),
    planted_at timestamptz NOT NULL DEFAULT now(),
    water      integer     NOT NULL DEFAULT 100,
    watered_at timestamptz NOT NULL DEFAULT now(),
    harvested  boolean     NOT NULL DEFAULT false,
    UNIQUE (world_id, x, z)
);

-- ---------- INVENTORY ----------
CREATE TABLE IF NOT EXISTS player_inventory (
    id       bigserial PRIMARY KEY,
    player_id uuid    NOT NULL REFERENCES player_profiles(id) ON DELETE CASCADE,
    item_id  varchar(48) NOT NULL,
    quantity integer NOT NULL DEFAULT 0,
    UNIQUE (player_id, item_id)
);

-- ---------- ECONOMY & AUDIT ----------
CREATE TABLE IF NOT EXISTS harvest_logs (
    id           bigserial PRIMARY KEY,
    player_id    uuid    NOT NULL REFERENCES player_profiles(id) ON DELETE CASCADE,
    plant_id     uuid,
    seed_id      varchar(48) NOT NULL,
    seeds_gained integer NOT NULL,
    gems_gained  bigint  NOT NULL,
    created_at   timestamptz NOT NULL DEFAULT now()
);

CREATE TABLE IF NOT EXISTS transactions (
    id          bigserial PRIMARY KEY,
    player_id   uuid    NOT NULL REFERENCES player_profiles(id) ON DELETE CASCADE,
    kind        varchar(24) NOT NULL, -- harvest | store_purchase | trade | admin_grant
    amount      bigint  NOT NULL,
    balance     bigint  NOT NULL,
    note        text,
    created_at timestamptz NOT NULL DEFAULT now()
);

-- ---------- INDEXES ----------
CREATE INDEX IF NOT EXISTS idx_world_blocks_world ON world_blocks (world_id);
CREATE INDEX IF NOT EXISTS idx_plants_world        ON plants (world_id);
CREATE INDEX IF NOT EXISTS idx_plants_ready        ON plants (world_id, planted_at);
CREATE INDEX IF NOT EXISTS idx_inventory_player    ON player_inventory (player_id);
CREATE INDEX IF NOT EXISTS idx_harvest_player      ON harvest_logs (player_id);
CREATE INDEX IF NOT EXISTS idx_txn_player          ON transactions (player_id, created_at);
