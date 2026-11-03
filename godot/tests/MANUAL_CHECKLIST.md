# Checklist Pengujian Manual — Growmax Godot 4

Jalankan semua item ini di editor (F5) dan, setelah ekspor web, di browser
(Chrome + satu browser lain). Centang hanya setelah benar-benar teruji.

## Boot & dunia
- [ ] Game dimulai tanpa error di panel Output/Monitor
- [ ] Ikon di assets/icons/*.svg terimpor tanpa error saat project dibuka
- [ ] Dunia "starter" muncul: rumput, pantai pasir, pohon, batu, pulau melayang
- [ ] Kolam air (bila ada) berwarna biru transparan
- [ ] Kolam lava (bila ada) menyala oranye dan menurunkan HP saat diinjak

## Player
- [ ] WASD & tombol panah menggerakkan karakter (relatif kamera)
- [ ] SPACE melompat; bisa naik ke atas blok 1 tingkat
- [ ] Tahan klik kanan memutar kamera; scroll men-zoom; kamera mengikuti player
- [ ] Klik kiri pada rumput menggarap tanah (+2 XP)
- [ ] R respawn ke titik awal
- [ ] HP turun di lava, pulih perlahan, pingsan → auto respawn

## Farming
- [ ] E menanam seed terpilih di tanah garap; stok hotbar berkurang
- [ ] Tanaman tumbuh (visual membesar); matang → mahkota menyala
- [ ] Klik kiri memanen: +gem +seed +XP; sisa waktu ditampilkan bila belum matang
- [ ] Q menyiram; panen setelah disiram mendapat +25% gem
- [ ] F men-toggle demo 60x; tanaman langsung siap
- [ ] Tumbuh berdasarkan timestamp: tutup game 1 menit, buka lagi, progres tetap jalan

## Blok & bangunan
- [ ] E / klik kanan memasang blok terpilih (Kayu/Bata/Batu/Pasir/Kaca)
- [ ] Kaca transparan; blok bisa ditumpuk hingga 6 tingkat; bisa berdiri di atasnya
- [ ] Klik kiri menghancurkan blok teratas → kembali ke ransel (+1 XP)
- [ ] Blok yang dipasang tersimpan: restart game, blok tetap ada

## UI & sistem
- [ ] Hotbar 18 slot: klik & tombol 1-9 memilih; jumlah item tampil benar
- [ ] Ikon tampil benar: chips stat, tombol samping & menu, tombol close panel, slot hotbar (tint warna item, kaca semi-transparan)
- [ ] Toko [B]: filter rarity, beli seed/blok; saldo tidak bisa negatif
- [ ] Ransel [I]: tab Benih/Blok/Alat/Statistik; Pakai & Jual berfungsi (jual = 1/2 harga)
- [ ] Analisis Level: XP bar, log XP, zona terbuka/terkunci
- [ ] Pindah World [P]: nama valid dibuat (terrain beda per nama), -1 WL, chips world
- [ ] World invalid ditolak (huruf besar, <3 char, spasi)
- [ ] World Lock: kunci (-1 WL) & lepas kunci; status & pemilik tampil
- [ ] Chat (Enter): kirim pesan, /help /who /world, Escape menutup
- [ ] WASD tidak menggerakkan karakter saat mengetik di chat/input world
- [ ] Menu: Simpan, Demo 60x, Bantuan, Reset (konfirmasi) berfungsi
- [ ] Autosave 20 detik; save JSON ada di user://growmax_save_v2.json
- [ ] Save lama format HTML (tiles di root) dimigrasi ke world starter
- [ ] UI tidak bertumpuk pada 1280x720 dan jendela di-resize
- [ ] Tidak ada error runtime di konsol selama 5 menit bermain

## Ekspor web
- [ ] Workflow CI menghasilkan branch `godot-web` tanpa error
- [ ] Build terbuka di Chrome: semua item di atas diuji ulang di browser
- [ ] Pointer lock/mouse kanan berfungsi; fullscreen resize mulus
