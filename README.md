# Gudangs

**Gudangs** adalah aplikasi mobile berbasis Flutter yang dirancang untuk membantu usaha kecil dan menengah (UKM) dalam mengelola operasional gudang secara mandiri, tanpa bergantung pada koneksi internet (Offline-First). 

Aplikasi ini menyediakan solusi terintegrasi yang mencakup manajemen inventori, pencatatan barang masuk (*inbound*) dan barang keluar (*outbound*), alur manufaktur (produksi bahan baku menjadi barang jadi), manajemen karyawan, hingga pelaporan keuangan sederhana.

## Fitur Utama

- 🔒 **Keamanan Biometrik**: Login menggunakan Fingerprint/Face ID (fallback ke PIN).
- 📦 **Manajemen Inventori**: Pemisahan stok (Bahan Baku & Barang Jadi) yang memudahkan pencatatan keluar-masuk.
- 🏭 **Modul Produksi (BOM)**: Konversi bahan baku menjadi barang jadi, lengkap dengan auto-kalkulasi Harga Pokok Produksi (HPP) berdasarkan *Weighted Average*.
- 📥 **Inbound & Outbound**: Pencatatan transaksi stok, lengkap dengan riwayat/histori.
- 👥 **Manajemen Karyawan**: Memudahkan perhitungan upah karyawan harian berdasarkan aktivitas borongan.
- 📊 **Laporan & Ekspor Data**: Fitur mencetak laporan (Stok, Keuangan, Karyawan) ke format PDF atau Excel.
- 📴 **100% Offline-First**: Tidak butuh internet. Semua data disimpan aman menggunakan database lokal (Hive).

## Dokumentasi

Untuk pemahaman sistem dan pengoperasian, silakan lihat dokumen berikut:
- 📖 [Panduan Pengguna (User Guide)](USER_GUIDE.md) - Panduan cara pemakaian (step-by-step) untuk Kepala Gudang.
- 📄 [Product Requirements Document (PRD)](PRD_Gudangs.md) - Spesifikasi produk dan fitur.
- 📋 [Software Requirements Specification (SRS)](SRS_Gudangs.md) - Detail teknis aplikasi.

## Memulai Pengembangan (Getting Started)

Proyek ini menggunakan Flutter. Untuk mulai menjalankan proyek di lokal:

1. **Instalasi:**
   Pastikan Anda sudah menginstal Flutter SDK, lalu jalankan perintah berikut di terminal:
   ```bash
   flutter pub get
   ```

2. **Jalankan Aplikasi:**
   ```bash
   flutter run
   ```

Untuk panduan lebih lanjut tentang Flutter, Anda bisa mengunjungi [dokumentasi resminya](https://docs.flutter.dev/).
