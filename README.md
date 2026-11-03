# 🌱 GrowCraft 3D

> Sandbox farming voxel 3D — konsep **Growtopia** (farming, seed, world, gems) bertemu **Minecraft** (dunia voxel 3D, block placement), dengan arsitektur **hybrid Java × Bedrock inspired**: server-authoritative, modular, dan data-driven.
>
> Dibangun sesuai master prompt: **Godot 4 + C#** · **ASP.NET Core** · **PostgreSQL** · **Redis** · **Docker**.

---

## Klien aktif: godot/ (Godot 4 + GDScript)

> **Migrasi prototipe web ke Godot 4**: seluruh gameplay versi browser (world seed, farming 13 benih + rarity, 5 blok bangunan, toko, ransel, world lock, chat, save) telah dimigrasikan ke folder **`godot/`** — GDScript, renderer GL Compatibility, siap ekspor Web & deploy Vercel. Spesifikasi: `docs/reference/growmax-threejs-prototype-2026-11-03.html`. Detail & checklist uji: `godot/README.md` dan `godot/tests/MANUAL_CHECKLIST.md`.
>
> Folder `game-client/` (Godot 4.4 + C#) & `backend/` tetap dipertahankan sebagai arsitektur server-authoritative. `web/index.html` tetap dilayani Vercel sampai build web Godot terverifikasi di browser.

## 🎮 Gameplay (sesuai konsep visual)

- Dunia voxel 3D: permukaan rumput → tanah → batu → **bedrock**, plus **floating islands** dan pantai pasir
- Karakter voxel blocky 3D, third-person camera
- **Farming ala Growtopia**: punch rumput → **Tanah Garap** → tanam seed → timer real-time → **siap panen** → punch → dapat **seed + gem**!
- **Setiap panen SELALU dapat seed & gem** — jumlah tergantung rarity & level (bonus +3%/lvl), air ≥60% saat panen = **+25% gem**
- Pertumbuhan dari **timestamp** → tanaman **tetap tumbuh saat pemain offline**
- Day/night cycle (4 menit = 1 hari), toko seed, level & XP

## 🗂 Struktur monorepo

```
growmax/
├── godot/                        # Godot 4 + GDScript — KLIEN AKTIF (migrasi dari prototipe web)
│   ├── scenes/Main.tscn
│   ├── scripts/
│   │   ├── core/                 # Main, GameState, SaveSystem, ChatSystem
│   │   ├── data/                 # catalog.gd (13 seed + 5 blok + rarity, 1:1 dari HTML)
│   │   ├── world/                # world_manager, world_gen (seeded)
│   │   ├── player/               # CharacterBody3D, kamera orbit, HP
│   │   ├── farming/              # plant (tumbuh via timestamp)
│   │   └── ui/                   # HUD + 7 panel (toko, ransel, world, lock, chat, dll.)
│   └── tests/MANUAL_CHECKLIST.md
├── game-client/                  # Godot 4.4 + C# — arsip fase monorepo (dunia voxel, player, farming, HUD)
│   ├── Scenes/Main.tscn
│   └── Scripts/
│       ├── Core/Game.cs           # entry: HUD, inventory, reward engine, toko, day/night
│       ├── Voxel/                 # VoxelWorld, BlockType (terrain + floating islands)
│       ├── Player/                # PlayerController (WASD, jump, punch, interact)
│       ├── Farming/               # PlantNode (growth stages + timer), FarmData (balancing)
│       └── Networking/           # ApiClient (REST ke backend)
├── web/index.html                # prototipe Three.js (tetap aktif di Vercel, arsip spesifikasi di docs/reference/)
├── backend/src/
│   ├── GrowCraft.Domain/          # entity murni + HarvestConfig
│   ├── GrowCraft.Infrastructure/  # EF Core DbContext (PostgreSQL, snake_case)
│   └── GrowCraft.Api/             # REST API server-authoritative + Dockerfile
├── database/init/                 # DDL + seed data (dipakai docker-compose)
├── content/behavior_packs/        # config ekonomi data-driven (ala Bedrock)
├── docs/architecture.md
└── docker-compose.yml             # postgres + redis + api
```

## 🚀 Menjalankan

### 1. Klien aktif — godot/ (Godot 4.3, GDScript)

```bash
# buka folder godot/ dari Godot editor (paket standar 4.3+, bukan .NET), tekan F5
```

**Kontrol:** WASD/panah jalan · Space lompat · tahan klik kanan putar kamera · scroll zoom · klik kiri punch (garap/panen/hancurkan) · `E`/klik kanan tanam/pasang · `Q` siram · `1-9` hotbar · `P` pindah/buat world · `B` toko · `I` ransel · `F` demo 60× · `R` respawn · `Enter` chat · `Esc` tutup panel

Ekspor web otomatis: workflow `.github/workflows/godot-web-export.yml` membangun branch `godot-web` setiap push ke `main` — arahkan project Vercel ke branch tersebut.

### 2. Backend (PostgreSQL + Redis + API)

```bash
docker compose up -d --build
# API siap di http://localhost:5000 — schema & seed data otomatis dimuat
```

Coba API:

```bash
# daftar akun
curl -X POST http://localhost:5000/api/auth/register \
  -H "Content-Type: application/json" \
  -d '{"username":"fule","password":"rahasia123"}'
# => {"token":"eyJ..."}

# cek seed yang tersedia
curl http://localhost:5000/api/store/seeds

# (dengan token) buat world, garap, tanam, siram, panen
TOKEN="eyJ..."
curl -X POST http://localhost:5000/api/worlds -H "Authorization: Bearer $TOKEN" \
  -H "Content-Type: application/json" -d '{"name":"kebun-fule","isPublic":true}'
```

### 3. Klien arsip — game-client/ (Godot 4.4 + .NET 8 SDK)

```bash
cd game-client
godot --path .        # buka folder ini dari Godot editor lalu tekan F5
```

## 🔐 Server-authoritative (yang penting!)

| Halusnya | Implementasi |
|---|---|
| Waktu tumbuh | `plants.planted_at` UTC di PostgreSQL — client hanya menampilkan sisa waktu |
| Reward panen | Dihitung server (`POST /api/farming/harvest`) dari `seed_definitions` + bonus level + bonus air |
| Pertumbuhan offline | Otomatis — hanya butuh `now - planted_at` |
| Inventory & gem | Tabel `player_inventory` + `player_profiles.gems`, transaksi EF Core |
| Audit | `harvest_logs` + `transactions` |

> **Status Phase 1:** client menjalankan sim lokal dengan rumus **identik** dengan server (satu sumber balancing di `FarmData` ↔ `harvest_config.json` ↔ `seed_definitions`). Sinkronisasi farming client↔server realtime ada di Phase 5 (ENet/UDP + dedicated server). Endpoint REST-nya **sudah jalan** dan bisa dipakai penuh via curl.

## 🌍 Balancing awal (bukan angka resmi Growtopia)

| Tanaman | Rarity | Waktu | Gem | Seed |
|---|---|---|---|---|
| Door Tree | Common | 5 mnt | 3-8 | 1-2 |
| Apple Tree | Uncommon | 15 mnt | 10-20 | 1-3 |
| Pine Tree | Uncommon | 20 mnt | 12-26 | 1-3 |
| Crystal Tree | Rare | 1 jam | 40-70 | 2-4 |
| Diamond Tree | Epic | 3 jam | 120-250 | 3-5 |
| Legendary Tree | Legendary | 24 jam | 400-900 | 5-9 |

## 🗺️ Roadmap (master prompt A–V)

- [x] **Phase 1 — Foundation**: monorepo, backend API + DB schema + Docker, Godot client playable (world, player, farming, HUD, toko)
- [x] **Migrasi web → Godot 4**: gameplay prototipe Three.js dipindah penuh ke `godot/` (GDScript, GL Compatibility, ekspor web otomatis via CI)
- [ ] **Phase 2 — Voxel Engine**: chunk 16³, greedy meshing, world editor penuh
- [ ] **Phase 3 — Farming penuh server-side**: sync client↔server, snapshot
- [ ] **Phase 4 — Inventory & crafting**
- [ ] **Phase 5 — Multiplayer**: dedicated server ENet/UDP, presence Redis, chat
- [ ] **Phase 6 — Ekonomi**: marketplace P2P, trade, world lock
- [ ] **Phase 7 — Voice chat (WebRTC/LiveKit) + plugin/behavior-pack loader**
- [ ] **Phase 8 — Admin panel Next.js + online store & IAP**
- [ ] **Phase 9 — Optimasi, anti-cheat, CI/CD GitHub Actions**

## 📄 Lisensi

MIT — lihat [LICENSE](./LICENSE).
