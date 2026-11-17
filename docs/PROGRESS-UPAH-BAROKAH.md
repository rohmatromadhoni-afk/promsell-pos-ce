# Progres PromSell POS — Upah Barokah

Catatan lanjutan (terakhir diperbarui: 17 Nov 2026).

- Repo: `rohmatromadhoni-afk/promsell-pos-ce` (fork, lisensi AGPL-3.0)
- Workflow build: `.github/workflows/build-apk.yml` (tab Actions → Build APK)
- Artifact: `promsell-debug-apk` → `app-prod-debug.apk` (±114 MB)
- Perintah build: `flutter build apk --debug --flavor prod`
- Flutter dikunci **3.47.9** (stable 3.50.0 merusak `flutter pub get`)

## Cara update APK (sementara, sebelum ada kunci tanda tangan)

1. Setiap build dari Actions punya kunci debug baru → **tidak bisa menimpa** aplikasi lama.
2. Jadi: uninstall → install APK baru → impor ulang 3 CSV katalog.
3. Data hanya untuk tester, jadi aman. Setelah kunci tanda tangan tetap dibuat,
   update berikutnya cukup install di atas aplikasi lama (data aman).

## Sudah selesai

| Tanggal | Commit | Isi |
|---|---|---|
| 17 Nov | `4784a4a` | Perbaikan build: placeholder `searchResultsCount` disamakan (`{n}`) di 3 file bahasa |
| 17 Nov | `1490cf6` | Workflow dikunci ke Flutter 3.47.9 |
| 17 Nov | `e3f342f` | Bahasa: pilihan English + Indonesia, Thailand dihapus dari pilihan, default English, tanggal format Indonesia, onboarding mata uang Rupiah |
| 17 Nov | `a044254` | Auto-rotate layar; promosi & PromptPay dihapus dari UI; desimal `.00` dihapus di semua tampilan harga |
| 17 Nov | `ef359cd` | Landscape: keranjang selalu tampil menetap di kanan (katalog + panel keranjang), lebar 40% layar (min 280dp, maks 380dp) |

Catatan penting:
- **Impor katalog berhasil** (3 bagian: 1.798 + 1.798 + 340 ≈ 3.936 produk).
- Mata uang Rupiah sudah aktif di aplikasi.
- Promosi & PromptPay: kode masih ada di dalam, hanya pintu masuk UI yang dihapus.
- Struk: ucapan terima kasih bisa diedit + toggle tampilkan info toko sudah ada
  (Pengaturan → Struk). Nomor struk selalu tampil dan tersimpan di riwayat.
- File `app_th.arb` masih dipakai sebagai template Flutter (tidak boleh dihapus
  tanpa memindah template ke `app_en.arb`).

## Belum dikerjakan (urutan usulan)

1. **Void per item** — sekarang void hanya bisa satu nota penuh.
   Perlu: kolom status void per baris `sale_items`, migrasi DB, pengembalian
   stok per item, hitung ulang total nota, UI pilih barang di riwayat.
2. **Akun owner & staff (pengganti PIN)**
   - Hapus PIN tiap akses; login sekali di awal.
   - 2 akun dulu: owner (akses penuh) dan staff (tanpa pengaturan sensitif).
   - Perlu tabel user, layar login, pembatasan menu.
3. **Kunci tanda tangan tetap** (release build)
   - Buat keystore di Termux (`keytool`), simpan sebagai GitHub Secrets.
   - Ubah workflow: `flutter build apk --release --split-per-abi`.
   - Sekali pindah ke release tetap harus uninstall (tanda tangan berubah),
     setelah itu update aman.
4. **Pengaturan struk tambahan** (opsional, sesuai kebutuhan)
   - Toggle sembunyikan: metode pembayaran, nama kasir, PPN, diskon per item,
     catatan item. Perlu ubah mesin render struk (thermal + PDF).
5. **QRIS statis** + konfirmasi manual (PromptPay sudah dihapus).
6. **Printer Bluetooth thermal (ESC/POS)** — logika sudah ada di fitur label harga.
7. **Ekspor CSV**: katalog, riwayat transaksi, ringkasan sesi (format sama dengan impor).
8. **Buka/tutup kas**: sesi baru mulai dari nol, riwayat per sesi, uang masuk/keluar
   dengan keterangan, saldo awal laci opsional.
9. **Hapus fitur foto produk**; hapus tombol transaksi tertunda ganda.
10. **Sinkronisasi antar perangkat (3–5 HP)** lewat server (belum dirancang;
    rencana STB CasaOS/mini PC, bukan STB Android biasa).
11. **Layout landscape**: cek lagi proporsi panel keranjang di perangkat asli;
    sesuaikan bila terlalu lebar/sempit.

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
