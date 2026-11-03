extends RefCounted
class_name GameCatalog

# Data ported from the original Growmax browser prototype (commit b57eb5c).
# Keep this catalogue as the single source for Godot gameplay and UI.

const SEEDS: Array[Dictionary] = [
    {"id":"door","name":"Pohon Pintu","emoji":"🚪","rarity":2,"time":300,"gems":[3,8],"seeds":[1,2],"price":5,"color":"#6dba4b"},
    {"id":"grass","name":"Pohon Rumput","emoji":"🌾","rarity":5,"time":420,"gems":[4,10],"seeds":[1,2],"price":8,"color":"#86c05a"},
    {"id":"apple","name":"Pohon Apel","emoji":"🍎","rarity":15,"time":900,"gems":[10,20],"seeds":[1,3],"price":25,"color":"#65b84b"},
    {"id":"pine","name":"Pohon Pinus","emoji":"🌲","rarity":17,"time":1200,"gems":[12,26],"seeds":[1,3],"price":30,"color":"#278c58"},
    {"id":"orange","name":"Pohon Jeruk","emoji":"🍊","rarity":19,"time":1500,"gems":[14,30],"seeds":[1,3],"price":40,"color":"#e08a2e"},
    {"id":"cactus","name":"Kaktus Emas","emoji":"🌵","rarity":21,"time":1800,"gems":[18,38],"seeds":[2,3],"price":55,"color":"#3f9e4f"},
    {"id":"coral","name":"Terumbu Karang","emoji":"🪸","rarity":25,"time":2700,"gems":[30,60],"seeds":[2,4],"price":80,"color":"#e06a8a"},
    {"id":"crystal","name":"Pohon Kristal","emoji":"💎","rarity":33,"time":3600,"gems":[40,70],"seeds":[2,4],"price":120,"color":"#54d8d1"},
    {"id":"manggis","name":"Pohon Manggis","emoji":"🫐","rarity":41,"time":5400,"gems":[90,180],"seeds":[3,5],"price":220,"color":"#7a5fb8"},
    {"id":"diamond","name":"Pohon Berlian","emoji":"💠","rarity":52,"time":10800,"gems":[120,250],"seeds":[3,5],"price":350,"color":"#5aa6e8"},
    {"id":"durian","name":"Pohon Durian","emoji":"🌰","rarity":58,"time":14400,"gems":[200,420],"seeds":[4,6],"price":500,"color":"#9aa632"},
    {"id":"legendary","name":"Pohon Legendaris","emoji":"✨","rarity":72,"time":43200,"gems":[400,900],"seeds":[5,9],"price":1200,"color":"#e6c76b"},
    {"id":"naga","name":"Pohon Naga","emoji":"🐉","rarity":88,"time":86400,"gems":[800,2000],"seeds":[6,10],"price":2500,"color":"#d05a5a"}
]

const BLOCKS: Array[Dictionary] = [
    {"id":"wood","name":"Blok Kayu","emoji":"🟫","color":"#9a693a","price":8},
    {"id":"brick","name":"Blok Bata","emoji":"🟥","color":"#b5563f","price":15},
    {"id":"stone","name":"Blok Batu","emoji":"⬜","color":"#8a8f8f","price":12},
    {"id":"sand","name":"Blok Pasir","emoji":"🟨","color":"#d9c27e","price":6},
    {"id":"glass","name":"Blok Kaca","emoji":"🔷","color":"#aad4e0","price":20,"glass":true}
]

const ZONES: Array[Dictionary] = [
    {"name":"Permukaan","level":1},
    {"name":"Bawah Tanah","level":6},
    {"name":"Gua","level":11},
    {"name":"Gua Dalam","level":21},
    {"name":"Magma","level":31}
]

const DEFAULT_STATE := {
    "gems":20,"wl":1,"dl":0,"bgl":0,"level":1,"xp":0,"xp_total":0,
    "harvests":0,"planted":0,"gems_earned":0,"selected":0,
    "inventory":{"door":1},
    "block_inventory":{"wood":60,"brick":30,"stone":40,"sand":20,"glass":20},
    "xp_log":[],
    "world":"starter"
}

static func seed_by_id(seed_id: String) -> Dictionary:
    for seed in SEEDS:
        if seed.id == seed_id:
            return seed
    return SEEDS[0]

static func block_by_id(block_id: String) -> Dictionary:
    for block in BLOCKS:
        if block.id == block_id:
            return block
    return BLOCKS[0]

static func rarity_tier(score: int) -> Dictionary:
    if score >= 70: return {"id":"mythic","name":"Mistis","color":"#d05a5a"}
    if score >= 50: return {"id":"legendary","name":"Legendaris","color":"#e6c76b"}
    if score >= 30: return {"id":"epic","name":"Epik","color":"#a77be8"}
    if score >= 20: return {"id":"rare","name":"Langka","color":"#5aa6e8"}
    if score >= 10: return {"id":"uncommon","name":"Tidak umum","color":"#54d8d1"}
    return {"id":"common","name":"Umum","color":"#86c05a"}
