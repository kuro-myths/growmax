# Growmax — Klien Godot 4 (Migrasi dari Three.js)

Klien aktif Growmax. Seluruh gameplay dimigrasikan dari prototipe `web/index.html`
(arsip spesifikasi: `docs/reference/growmax-threejs-prototype-2026-11-03.html`) ke
Godot 4.3 GDScript. Proyek `game-client/` (Godot 4.4 + C#, fase backend monorepo)
tetap ada sebagai arsip — klien inilah yang dikembangkan sekarang.

## Menjalankan di editor

1. Pasang [Godot 4.3+](https://godotengine.org) (paket standar, bukan .NET).
2. Buka folder `godot/` dari Godot editor → tekan F5.
3. Kontrol: WASD/panah jalan · SPACE lompat · tahan **klik kanan** putar kamera ·
   scroll zoom · **klik kiri** punch (garap/panen/hancurkan blok) · **E / klik kanan**
   tanam/pasang · **Q** siram · **1-9** hotbar · **P** world · **B** toko ·
   **I** ransel · **F** demo 60x · **R** respawn · **Enter** chat · **Esc** tutup panel.

## Pemetaan fitur HTML → Godot

| Fitur HTML lama | Implementasi Godot | Status |
|---|---|---|
| World generation (hashSeed/mulberry32, biome, kolam, pohon, batu, pulau) | `WorldGen` + `WorldManager._build_terrain/_build_features` | Selesai |
| Kolam lava (baru, hazard) | `WorldGen` (seeded) + `Player._apply_hazards` | Selesai |
| Player movement & collision (WASD, lompat, berdiri di atas blok) | `CharacterBody3D` + `player.gd` | Selesai |
| Block interaction (raycast pointer) | `PhysicsRayQueryParameters3D` dari kamera ke mouse | Selesai |
| Seed catalog 13 item + rarity 1-100 | `Catalog.SEEDS/RARITY_TIERS` | Selesai |
| Planting & tree growth (timestamp, tumbuh offline) | `WorldManager._plant_seed` + `PlantNode` | Selesai |
| Harvesting (seed+gem, bonus level 3%/lvl, siram +25%) | `WorldManager._harvest` | Selesai |
| Inventory + hotbar 18 slot (seed+blok) | `GameState` + `HUD` + `InventoryPanel` | Selesai |
| Shop (filter rarity, beli seed & blok, validasi saldo) | `ShopPanel` + `GameState.spend_gems` | Selesai |
| Currency gems/WL/DL/BGL | `GameState` | Selesai |
| World lock & permissions (validasi build) | `LockPanel` + `WorldManager._can_build` | Selesai |
| Chat lokal (/help /who /world) | `ChatSystem` + `ChatPanel` | Selesai |
| Pindah/buat world (regex, biaya 1 WL, per-world save) | `WorldPanel` + `Main.switch_world` | Selesai |
| Save/load (growmax-world-v2, autosave 20 dtk, migrasi format lama) | `SaveSystem` + `GameState.to_dict/from_dict` | Selesai |
| Analisis level, zona, XP log | `AnalysisPanel` | Selesai |
| HP + damage + respawn (baru) | `Player` + HUD HP bar | Selesai |

## Struktur

```
godot/
├── project.godot            # autoload: Catalog, GameState, SaveSystem, ChatSystem
├── export_presets.cfg        # preset ekspor Web (GL Compatibility, tanpa threads)
├── scenes/                   # Main.tscn, world/World.tscn, player/Player.tscn
└── scripts/
    ├── core/                 # Main.gd, game_state.gd, save_system.gd, chat_system.gd
    ├── data/                 # catalog.gd (katalog seed/blok/rarity — 1:1 dari HTML)
    ├── world/                # world_manager.gd, world_gen.gd
    ├── player/               # player.gd
    ├── farming/              # plant.gd
    └── ui/                   # HUD.gd + 7 panel (modal, shop, inventory, world, lock, chat, analysis, help)
```

## Ekspor Web (deploy Vercel)

- Renderer: **GL Compatibility**, threads dimatikan (aman di browser tanpa header COOP/COEP).
- Ekspor manual: Godot editor → Project → Export → **Web** → Export.
- Ekspor otomatis: workflow `.github/workflows/godot-web-export.yml` mengekspor
  build web dan mendorongnya ke branch `godot-web`. Arahkan project Vercel ke
  branch tersebut (root directory: `.`) — setiap push ke `main` akan otomatis
  memperbarui build.
- `web/index.html` (versi Three.js) tetap dipertahankan sampai build Godot web
  terverifikasi di browser, sesuai aturan: jangan hapus fitur lama sebelum
  penggantinya berfungsi.

## Catatan desain

- **Ikon warna, bukan emoji**: font default Godot tidak memuat glyph emoji dan
  system font fallback tidak tersedia di ekspor web, jadi UI memakai kotak warna
  item + teks. Data emoji tetap disimpan di katalog (paritas data HTML).
- **Lava** adalah tambahan Godot (dibutuhkan HP/hazard): worldgen tetap seeded,
  tetapi urutan RNG sedikit bergeser dari HTML karena kolam lava — layout world
  sama persis nama-antara-engine tidak dijamin identik.
- **Save kompatibel**: format JSON mengikuti struktur `growmax-world-v2`. Save
  HTML bisa diimpor manual dengan menyalin isinya ke
  `user://growmax_save_v2.json` (migrasi `tiles` di root otomatis didukung).
- Multiplayer belum aktif — chat & permission disiapikan server-authoritative,
  tapi sinkronisasi jaringan belum diimplementasikan dan tidak diklaim jalan.
