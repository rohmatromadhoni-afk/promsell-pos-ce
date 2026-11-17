# Progres PromSell POS — Barokah Karangsari

Catatan lanjutan (terakhir diperbarui: 17 Nov 2026).

- Repo: `rohmatromadhoni-afk/promsell-pos-ce` (fork, lisensi AGPL-3.0)
- Workflow build: `.github/workflows/build-apk.yml` (tab Actions → Build APK)
- Artifact: `promsell-release-apk` → `app-prod-release.apk` (APK release bertanda tangan)
- Perintah build: `flutter build apk --release --flavor prod --build-number=<nomor run>`
- Flutter dikunci **3.47.9** (stable 3.50.0 merusak `flutter pub get`)

## Cara update APK (sudah pakai kunci tetap)

1. Build release memakai **keystore tetap** dari 4 GitHub Secrets
   (`KEYSTORE_BASE64`, `KEYSTORE_PASSWORD`, `KEY_ALIAS`, `KEY_PASSWORD`),
   ditulis sementara ke `android/app/keystore.jks` saat CI berjalan.
2. **Sekali saja**: uninstall aplikasi debug lama → install APK release ini.
   Setelah itu semua update cukup **install di atas aplikasi lama**, data aman.
3. Version code naik otomatis tiap build (`github.run_number`), jadi Android
   selalu menganggapnya versi lebih baru.
4. Cadangan keystore ada di HP (folder `~/.barokah-keys`) — **salin ke Google
   Drive**. Kalau keystore + kata sandi hilang, update bertanda tangan sama
   tidak bisa dibuat lagi dan aplikasi harus di-uninstall sekali lagi.

## Sudah selesai

| Tanggal | Commit | Isi |
|---|---|---|
| 17 Nov | `4784a4a` | Perbaikan build: placeholder `searchResultsCount` disamakan (`{n}`) di 3 file bahasa |
| 17 Nov | `1490cf6` | Workflow dikunci ke Flutter 3.47.9 |
| 17 Nov | `e3f342f` | Bahasa: pilihan English + Indonesia, Thailand dihapus dari pilihan, default English, tanggal format Indonesia, onboarding mata uang Rupiah |
| 17 Nov | `a044254` | Auto-rotate layar; promosi & PromptPay dihapus dari UI; desimal `.00` dihapus di semua tampilan harga |
| 17 Nov | `ef359cd` | Landscape: keranjang selalu tampil menetap di kanan (katalog + panel keranjang), lebar 40% layar (min 280dp, maks 380dp) |
| 17 Nov | `1a31dc7` | Nama aplikasi jadi **Barokah Karangsari**; akun owner/pegawai dengan login PIN sekali di awal + menu Kelola Pegawai |
| 17 Nov | `e3954a6` | Build **release bertanda tangan tetap** (keystore di GitHub Secrets); artifact `promsell-release-apk`; version code naik tiap build |

Catatan penting:
- **Impor katalog berhasil** (3 bagian: 1.798 + 1.798 + 340 ≈ 3.936 produk).
- Mata uang Rupiah sudah aktif di aplikasi.
- Promosi & PromptPay: kode masih ada di dalam, hanya pintu masuk UI yang dihapus.
- Struk: ucapan terima kasih bisa diedit + toggle tampilkan info toko sudah ada
  (Pengaturan → Struk). Nomor struk selalu tampil dan tersimpan di riwayat.
- File `app_th.arb` masih dipakai sebagai template Flutter (tidak boleh dihapus
  tanpa memindah template ke `app_en.arb`).

## Pembagian resmi: versi dasar vs versi perbaikan

Status per 17 Nov 2026: ✅ selesai · 🟡 sebagian · ⬜ belum

| # | Area | Versi dasar | Status | Versi perbaikan | Status |
|---|---|---|---|---|---|
| 1 | Dasar | Release build (butuh kunci tanda tangan) | ⬜ | Layout landscape tablet | 🟡 (auto-rotate + keranjang kanan sudah) |
| 1 | Dasar | Mata uang Rupiah saja | ✅ | Terjemahan lengkap (bukan sebagian) | 🟡 |
| 1 | Dasar | Bahasa Indonesia | ✅ | Hapus fitur foto produk | ⬜ |
| 2 | Model produk | Varian lewat nama produk | ✅ | Stok per varian | ⬜ |
| 2 | Model produk | Stok on/off per produk | ✅ | Header & kolom CSV Bahasa Indonesia | ⬜ (setelah impor stabil) |
| 3 | Buka/tutup kas | Sesi baru mulai nol + riwayat per sesi | ⬜ | Uang masuk/keluar + keterangan, saldo awal laci | ⬜ |
| 4 | Struk | Hapus bagian tidak perlu | ⬜ | Toggle alamat + ucapan terima kasih editable | ✅ (sudah ada) |
| 5 | Void per item | Void satu item dari nota | ⬜ | Stok otomatis kembali bila stok aktif | ⬜ (setelah stok per produk benar) |
| 6 | PIN/Akun | Login PIN sekali di awal (tanpa PIN tiap akses) | ✅ | Akun owner/kasir + hak akses per menu | 🟡 (owner+pegawai sudah; pembatasan aksi detail menyusul) |
| 7 | Printer | Cetak struk Bluetooth ESC/POS | ⬜ | — | — |
| 8 | Layar penjualan | Hapus tombol transaksi tertunda dobel | ⬜ | — | — |
| 9 | Ekspor | Ekspor CSV katalog (format sama dengan impor) | ⬜ | Ekspor riwayat + ringkasan sesi | ⬜ |
| 10 | Pembayaran | Hapus PromptPay + QRIS statis konfirmasi manual | 🟡 (PromptPay sudah, QRIS belum) | QRIS via API penyedia | ⬜ |
| 11 | Sinkronisasi | Sementara lewat ekspor/impor CSV | ⬜ | Real-time via server CasaOS/mini PC | ⬜ |

Koreksi dari daftar awal:
- Item 4 (perbaikan) **sudah ada**: toggle "Tampilkan info toko/alamat" dan catatan/
  ucapan terima kasih yang bisa diedit, di Pengaturan → Struk.
- Item 2 (dasar) juga sudah: varian lewat nama dan `lacak_stok` per produk sudah dipakai.
- Item 10 (dasar): PromptPay sudah dihapus; QRIS statis belum.

## Prioritas versi dasar (usulan urutan kerja)

1. ✅ **Kunci tanda tangan + release build** — sudah: update tanpa uninstall, APK lebih kecil.
2. **Ekspor CSV katalog** — pelindung data; tanpa ini setiap uninstall menghapus 3.936 produk.
3. **Void per item** (+ pengembalian stok) — dipakai hampir tiap hari.
4. **Buka/tutup kas per sesi** — untuk tutup toko harian.
5. **Hapus tombol transaksi tertunda dobel** — kecil dan cepat.
6. ✅ **Hapus PIN tiap akses** — sudah diganti akun owner/pegawai (login sekali).
7. **Hapus fitur foto produk** — kecil, ikut mengecilkan APK.
8. **QRIS statis + konfirmasi manual** — bisa ditunda bila tunai/transfer cukup.
9. **Printer Bluetooth ESC/POS** — tunggu printer tersedia.
10. **Sinkronisasi antar HP** — setelah versi dasar dipakai rutin.

## Catatan risiko

- Menghapus PIN tanpa akun pengganti membuat Pengaturan terbuka bagi siapa pun yang
  memegang perangkat. Minimal pertahankan PIN khusus Pengaturan sampai akun selesai.
- Void per item butuh migrasi database (kolom status void per baris barang).
  Sebelum migrasi, buat ekspor CSV/backup dulu.

## Catatan data katalog (Qasir → CSV)

- Sumber: `Katalog_Produk-upahbarokah.xlsx`, header di baris ke-4.
- Kolom: Nama Produk, Nama Varian, Harga Jual (G), Harga Modal (I), Stok,
  Kode/Barcode, Kategori. "Harga Khusus Pusat" diabaikan.
- Varian digabung ke nama: `Nama Produk - Varian`.
- 593 baris (jual & modal 0) dikeluarkan.
- 21 baris harga modal > harga jual tetap diimpor, dicatat di
  `cek_harga_jual_lebih_kecil.csv`.
- 4 baris dikeluarkan karena harga tidak masuk akal, perlu input manual:
  Garnier Cream Renteng - Karton, Garnier Foam Renteng - Karton,
  Mitu Baby Wipes 50 Sheet - Karton, Beras Cap Opung 5 Kg - Sak.
- Stok negatif di Qasir = stok dimatikan (`lacak_stok = false`).
- **Harga jual di file ekspor berbeda dari layar Qasir** (6 dari 7 sampel dicek).
  Harga modal hampir selalu cocok. Perlu verifikasi manual sebelum dipercaya.
- Header CSV impor memakai template PromSell Thailand:
  `ชื่อ,ราคา,รหัสสินค้า,บาร์โค้ด,ต้นทุน,สต็อก,หมวดหมู่,ติดตามสต็อก`
- Batas impor: 2.000 baris & 2 MB per file; jangan keluar halaman saat impor.

## Catatan teknis

- Pesan "Failed to read CSV file" adalah pesan umum; penyebab asli tampil lewat
  `state.error` di listener halaman impor (perubahan sementara untuk diagnosis).
- Handler impor: `lib/features/product/presentation/bloc/product_bloc.dart` (`_onImported`).
- Halaman impor: `lib/features/product/presentation/pages/product_csv_import_page.dart`.
- Pencarian kode di GitHub hanya mencari nama file, bukan isi.
- Lebih aman mengubah satu baris langsung di GitHub, lalu kirim log error yang relevan.

## Akun & Pegawai (dipakai mulai 17 Nov)

Cara pakai:
1. Buka aplikasi pertama kali → muncul **Buat akun owner** (nama + PIN 4-6 angka).
   Setelah dibuat, aplikasi langsung masuk sebagai owner.
2. Setiap aplikasi dibuka/di-restart → layar **Masuk**; pilih akun lalu masukkan PIN.
3. **Pengaturan → Akun & Pegawai**:
   - **Kelola pegawai**: tambah pegawai (nama + PIN), atur akses, hapus pegawai.
   - **Ubah PIN saya**: ganti PIN akun yang sedang dipakai.
   - **Keluar**: kembali ke layar Masuk.
4. Akses pegawai yang bisa dicentang: void transaksi, ubah produk, ubah stok,
   ubah harga, lihat laporan, buka/tutup kas, pelanggan. Menjual selalu boleh.
   **Pengaturan selalu hanya owner.**

Yang perlu diketahui:
- Akun disimpan di `app_settings` (key `appUsers`) sebagai hash PIN (PBKDF2),
  bukan PIN mentah. Tidak ada migrasi database, dan ikut backup pengaturan.
- Setelah akun dibuat, **PIN per-akses lama otomatis dimatikan** sehingga
  void/stok/harga tidak lagi bertanya PIN. Halaman App Lock lama tidak dipakai.
- **Belum ada pemulihan PIN**: kalau owner lupa PIN, satu-satunya jalan adalah
  hapus data aplikasi (katalog & transaksi hilang) atau restore backup settings.
  Catat PIN owner di tempat aman.
- Pembatasan saat ini baru di tingkat menu: Laporan & Pengaturan disembunyikan,
  tombol Void disembunyikan, shortcut beranda mengikuti izin. Tombol ubah
  stok/harga/produk belum dicek per aksi — menyusul.
- Pegawai tidak bisa menghapus akun owner; minimal satu owner selalu ada.

Berkas utama:
- `lib/features/accounts/domain/app_user.dart` — entitas + daftar izin.
- `lib/features/accounts/data/account_service.dart` — simpan/verifikasi akun.
- `lib/features/accounts/presentation/pages/account_gate.dart` — gate startup.
- `lib/features/accounts/presentation/pages/auth_pages.dart` — buat owner + login.
- `lib/features/accounts/presentation/pages/account_settings_page.dart` — kelola pegawai.
- `lib/core/shell/main_shell.dart` — menu tab mengikuti izin.
