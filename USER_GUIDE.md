# Panduan Penggunaan (User Guide) Aplikasi Gudangs

**Versi:** 1.0
**Target Pengguna:** Kepala Gudang & Admin Operasional

Selamat datang di panduan penggunaan aplikasi **Gudangs**! Aplikasi ini dirancang khusus untuk mempermudah pekerjaan Anda di gudang, mulai dari mencatat barang masuk (bahan baku), proses produksi, hingga pengiriman barang jadi. Aplikasi ini dapat berjalan 100% tanpa internet (offline), sehingga Anda tidak perlu khawatir kehilangan data saat susah sinyal.

---

## Daftar Isi
1. [Memulai Aplikasi (Login & Keamanan)](#1-memulai-aplikasi-login--keamanan)
2. [Persiapan Data Awal (Setup)](#2-persiapan-data-awal-setup)
3. [Alur 1: Inbound (Barang Masuk)](#3-alur-1-inbound-barang-masuk)
4. [Alur 2: Produksi (BOM & Konversi Barang)](#4-alur-2-produksi-bom--konversi-barang)
5. [Alur 3: Outbound (Pengiriman Barang Keluar)](#5-alur-3-outbound-pengiriman-barang-keluar)
6. [Manajemen Karyawan & Aktivitas](#6-manajemen-karyawan--aktivitas)
7. [Koreksi Stok & Audit](#7-koreksi-stok--audit)
8. [Laporan & Ekspor Data](#8-laporan--ekspor-data)
9. [Daftar Istilah (Glossary)](#9-daftar-istilah-glossary)
10. [Troubleshooting (FAQ)](#10-troubleshooting-faq)

---

## 1. Memulai Aplikasi (Login & Keamanan)

Untuk menjaga keamanan data gudang, Gudangs dilengkapi dengan sistem login otomatis.
- **Login Cepat:** Buka aplikasi, lalu tempelkan jari Anda ke sensor sidik jari HP (Fingerprint) atau gunakan pemindai wajah (Face ID).
- **Login PIN (Alternatif):** Jika sensor biometrik gagal membaca atau tangan Anda kotor, Anda akan diminta memasukkan PIN 6 angka.
- **Ubah PIN:** Anda dapat mengubah PIN kapan saja di menu **Pengaturan > Pengaturan PIN**.

---

## 2. Persiapan Data Awal (Setup)

Sebelum mencatat transaksi masuk/keluar, pastikan Anda mendaftarkan barang-barang di gudang Anda terlebih dahulu. Di aplikasi ini, barang dibagi menjadi dua: **Bahan Baku** (yang dibeli) dan **Barang Jadi** (yang diproduksi dan dijual).

### A. Menambah Bahan Baku & Barang Jadi
1. Buka menu **Inventori**.
2. Pilih tab **Bahan Baku** atau **Barang Jadi**.
3. Tekan tombol **(+) Tambah Produk Baru**.
4. Isi kelengkapan data seperti Nama Produk, SKU (Kode Barang), Kategori, Satuan (misal: kg, pcs, liter), dan Jumlah Awal.
5. Simpan data.

### B. Menambah Daftar Karyawan & Jenis Pekerjaan
1. Buka menu **Karyawan**.
2. Tekan **(+) Tambah Karyawan** untuk mendaftarkan nama karyawan gudang harian.
3. Buka menu **Pengaturan > Manajemen Pekerjaan** untuk menambah **Jenis Pekerjaan** beserta **Tarif upah per unit/pekerjaan**. (Ini penting untuk menghitung estimasi gaji nanti).

---

## 3. Alur 1: Inbound (Barang Masuk)

Gunakan fitur ini setiap kali truk *supplier* datang membawa bahan baku.
1. Buka menu **Inbound**.
2. Tekan **(+) Catat Barang Masuk**.
3. Pilih nama **Bahan Baku** dari daftar.
4. Masukkan **Jumlah** barang yang diterima.
5. Masukkan **Harga Beli per Unit**. Aplikasi akan otomatis menghitung total biaya pembelian.
6. Simpan transaksi. Otomatis, stok bahan baku akan bertambah.

---

## 4. Alur 2: Produksi (BOM & Konversi Barang)

Fitur produksi membantu Anda mengubah Bahan Baku menjadi Barang Jadi menggunakan *resep* (Bill of Materials/BOM).

### A. Membuat "Resep" / BOM Baru (Satu kali di awal)
1. Buka menu **BOM / Resep Produksi**.
2. Tekan **(+) Tambah BOM**.
3. Pilih produk sasaran (Barang Jadi).
4. Tambahkan bahan-bahan baku apa saja dan berapa jumlah yang dibutuhkan untuk membuat 1 unit barang jadi tersebut.
5. Simpan BOM.

### B. Menjalankan Proses Produksi (Setiap hari/minggu)
1. Buka menu **Produksi**.
2. Tekan **Jalankan Produksi**.
3. Pilih **BOM** (Barang Jadi yang ingin diproduksi).
4. Masukkan **Jumlah Unit** yang akan dibuat.
5. **Validasi Otomatis:** Sistem akan memeriksa apakah stok bahan baku di gudang Anda cukup. Jika ada bahan baku yang kurang, aplikasi akan memberi tahu bahan apa yang kurang dan tidak mengizinkan produksi.
6. Jika bahan mencukupi, tekan **Konfirmasi Produksi**.
7. Sistem otomatis akan **mengurangi** stok bahan baku, **menambah** stok barang jadi, dan **menghitung Harga Pokok Produksi (HPP)** secara otomatis.

---

## 5. Alur 3: Outbound (Pengiriman Barang Keluar)

Gunakan fitur ini setiap kali Anda mengirim/menjual Barang Jadi ke pelanggan.
1. Buka menu **Outbound**.
2. Tekan **(+) Catat Pengiriman**.
3. Pilih **Barang Jadi**, isi **Jumlah**, masukkan nama/lokasi **Tujuan Pengiriman**, dan tentukan **Tanggal**.
4. Masukkan **Harga Jual per Unit** (sistem otomatis menghitung total nilai pesanan).
5. Pilih Status Pengiriman (misal: `Pending`).
6. Simpan transaksi. Stok barang jadi akan otomatis berkurang.
7. Anda bisa masuk kembali ke pesanan ini untuk mengubah status menjadi `Terkirim` apabila kurir sudah sampai.

---

## 6. Manajemen Karyawan & Aktivitas

Gudangs memungkinkan Anda mencatat absensi kerja borongan karyawan dan menghitung gajinya secara otomatis.
1. **Catat Aktivitas Harian:** Masuk ke menu **Karyawan > Aktivitas Harian**. Pilih karyawan, pilih jenis pekerjaan, dan masukkan jumlah unit pekerjaan (misal: Pekerjaan Angkut Karung -> 50 karung).
2. **Estimasi Gaji:** Masuk ke menu **Estimasi Gaji**. Pilih nama karyawan dan tentukan rentang tanggal (mingguan/bulanan). Sistem akan memunculkan nominal upah otomatis yang harus dibayarkan berdasarkan tarif yang disetel di awal.

---

## 7. Koreksi Stok & Audit

Pernah mengalami stok fisik di gudang berbeda dengan stok di aplikasi? Jangan panik, gunakan fitur koreksi.
1. **Penyesuaian Stok (Stock Adjustment):** Masuk ke detail produk tertentu, tekan tombol **Sesuaikan Stok**. Masukkan jumlah koreksi (tambah atau kurang) beserta alasannya (misal: barang rusak, tikus, dll).
2. **Stock Opname:** Fitur ini ada di menu **Pengaturan > Stock Opname** untuk menyesuaikan stok fisik dalam jumlah banyak sekaligus (audit bulanan).
3. **Log Aktivitas:** Masuk ke **Pengaturan > Log Aktivitas Sistem** untuk melihat riwayat *"Siapa yang menghapus barang X?"* atau *"Kapan stok Y diubah?"* (sangat berguna untuk pelacakan kesalahan).

---

## 8. Laporan & Ekspor Data

Pemilik (Owner) biasanya meminta laporan operasional gudang. Anda bisa melakukannya dalam beberapa ketukan.
1. Buka menu **Laporan**.
2. Pilih jenis laporan yang ingin dibuat (Laporan Stok, Laporan Inbound, Laporan Outbound, Laporan Keuangan/Margin, Laporan Gaji).
3. Tentukan periode waktu (Hari ini, Minggu ini, Bulan ini).
4. Tekan **Ekspor PDF** (bagus untuk diprint/dikirim ke WhatsApp) atau **Ekspor Excel** (jika bos Anda ingin menghitung ulang di komputer).

---

## 9. Daftar Istilah (Glossary)

Bagi Anda yang baru pertama kali menggunakan aplikasi pergudangan, berikut penjelasan istilah yang sering muncul:
*   **SKU (Stock Keeping Unit):** Kode unik untuk sebuah barang (contoh: KRG-Beras-01).
*   **Bahan Baku (Raw Material):** Barang mentah yang baru dibeli dan belum diproses (contoh: kain, terigu).
*   **Barang Jadi (Finished Good):** Barang yang sudah diproduksi dan siap dijual.
*   **Inbound:** Proses masuknya barang ke dalam gudang dari supplier.
*   **Outbound:** Proses keluarnya barang dari gudang ke pembeli/tujuan akhir.
*   **BOM (Bill of Materials):** Resep atau daftar bahan baku yang wajib disiapkan untuk membuat 1 buah barang jadi.
*   **HPP (Harga Pokok Produksi):** Modal asli atau biaya riil dari pembuatan suatu barang jadi (diambil otomatis dari harga beli bahan bakunya).
*   **Gross Margin (Margin Kotor):** Keuntungan kasar yang didapat dari (Total Penjualan Barang Keluar - Total Pembelian Barang Masuk).
*   **Stock Opname:** Kegiatan menghitung ulang seluruh fisik barang di gudang untuk disamakan dengan data di aplikasi.

---

## 10. Troubleshooting (FAQ)

**Q: Mengapa saya tidak bisa melakukan proses Produksi?**
A: Kemungkinan besar stok Bahan Baku Anda tidak cukup. Baca pesan error di layar, aplikasi akan memberitahu bahan baku mana yang kurang. Solusinya: Lakukan proses *Inbound* (pembelian bahan baku tersebut) terlebih dahulu, baru ulangi proses Produksi.

**Q: Saya salah memasukkan jumlah di Inbound, apa yang harus saya lakukan?**
A: Anda bisa membuka histori Inbound, lalu mengeditnya (jika masih memungkinkan). Jika tidak, gunakan fitur *Penyesuaian Stok (Stock Adjustment)* untuk mengurangi/menambah kelebihan stok tersebut secara manual, dan tambahkan catatan "Koreksi karena salah ketik Inbound".

**Q: Saya tidak ingat PIN untuk masuk aplikasi, bagaimana ini?**
A: Karena keamanan ketat aplikasi ini bekerja 100% secara offline, tidak ada fitur "Lupa Password" via email. Pastikan Anda mencatat PIN di tempat rahasia. Jika Anda mengatur Fingerprint/Face ID di HP Anda, Anda tetap bisa masuk menggunakan metode tersebut dan mengganti PIN Anda di dalam Pengaturan.

**Q: Apakah data saya akan hilang jika HP dimatikan atau internet mati?**
A: **Tidak.** Aplikasi ini dirancang "Offline First", yang berarti semua data disimpan langsung di memori penyimpanan internal HP Anda, bukan di internet. Namun, sangat disarankan secara berkala mengekspor *Backup Data* dari menu Pengaturan ke komputer untuk berjaga-jaga jika HP Anda rusak/hilang.

**Q: Mengapa karyawan yang sudah dipecat/berhenti tidak bisa dihapus dari sistem?**
A: Kami menggunakan sistem *Soft Delete*, yang artinya karyawan bisa dinonaktifkan tanpa menghapus riwayat datanya (agar riwayat laporan kerja & gajinya di masa lalu tetap ada dan tidak merusak perhitungan gaji bulan-bulan sebelumnya).

---
*Panduan ini dibuat secara eksklusif untuk Admin Operasional Gudangs. Jika ada kendala lebih lanjut, silakan hubungi tim dukungan IT internal.*
