# 🌱 GrowCraft 3D

> Sandbox farming voxel — gabungan konsep **Growtopia** (farming, seed, world, gems) dan **Minecraft** (dunia voxel 3D). Prototipe playable, siap deploy ke **Vercel** sebagai static site.

Play in browser: tanam → siram → tunggu → panen → **selalu dapat seed + gem** sesuai rarity & level! 💎

---

## ✨ Fitur

| Fitur | Status |
|---|---|
| Dunia voxel isometric 3D (grass/dirt/stone/bedrock/wood/sand/soil) | ✅ |
| Player voxel 3D + kontrol WASD / joystick HP | ✅ |
| Garap tanah, pasang & hancurkan block | ✅ |
| Farming: tanam seed → timer real-time → 5 tahap tumbuh → panen | ✅ |
| **Reward system: panen SELALU dapat seed + gem** (rarity + bonus level 3%/lvl) | ✅ |
| Sistem penyiraman 💧 (air ≥ 60% saat panen = bonus gem +25%) | ✅ |
| Toko seed online (beli pakai gems) + rarity (common → legendary) | ✅ |
| Level & XP dengan bonus panen | ✅ |
| Day/night cycle + matahari/bulan/bintang | ✅ |
| Kamera smooth-follow + zoom scroll | ✅ |
| SFX WebAudio tanpa aset | ✅ |
| Autosave localStorage — **tanaman tetap tumbuh saat offline** (timestamp) | ✅ |
| Mobile support (joystick + tombol aksi, double-tap tanam) | ✅ |
| Multiplayer / voice chat / backend server | 🔜 roadmap |

## 🎮 Kontrol

**Desktop**
- `WASD` / arrow — jalan
- Klik kiri — garap rumput / hancurkan block / panen
- Klik kanan — pasang block / tanam seed
- `1-8` — pilih hotbar · `Q` — siram tanaman · `B` — toko · Scroll — zoom

**HP**
- Joystick kiri — jalan · Tap — garap/panen · Double-tap — tanam
- Tombol ⛏️ 🌱 💧 — aksi di tile terakhir

## 🌍 Tanaman & Balancing Awal

| Tanaman | Rarity | Waktu | Gem | Harga toko |
|---|---|---|---|---|
| Door Tree | Common | 20s | 3-8 | 💎 5 |
| Apple Tree | Uncommon | 45s | 10-20 | 💎 25 |
| Crystal Tree | Rare | 90s | 40-70 | 💎 80 |
| Diamond Tree | Epic | 3m | 120-250 | 💎 250 |
| Legendary Tree | Legendary | 7m | 400-900 | 💎 800 |

## 🚀 Deploy ke Vercel

Static site zero-config — cukup push dan import:

1. Push repo ini ke GitHub
2. Buka [vercel.com/new](https://vercel.com/new) → import repo
3. Framework preset: **Other** → **Deploy** selesai 🎉

Atau via CLI:

```bash
npm i -g vercel
vercel --prod
```

## 🧱 Roadmap (Master Prompt GrowCraft 3D)

- [x] **Phase P** — prototype playable (client, localStorage)
- [ ] **Phase 1-2** — Godot 4 + C#, voxel engine chunk-based, greedy meshing
- [ ] **Phase 3** — farming penuh di engine (growth server-side, snapshot DB)
- [ ] **Phase 4** — inventory & crafting
- [ ] **Phase 5** — multiplayer: ASP.NET Core dedicated server + ENet/UDP
- [ ] **Phase 6** — ekonomi: marketplace P2P, harvest reward server-authoritative
- [ ] **Phase 7** — voice chat (WebRTC/LiveKit) + plugin/behavior-pack system
- [ ] **Phase 8** — admin panel Next.js, online store + IAP
- [ ] **Phase 9** — optimasi, anti-cheat, CI/CD

Tech stack target: **Godot 4 + C#** · **ASP.NET Core** · **PostgreSQL** · **Redis** · **Next.js** · **Docker**

## 📄 Lisensi

MIT — lihat [LICENSE](./LICENSE).
