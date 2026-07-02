# PRD — Product Requirements Document
# Aplikasi: **Gudangs**
**Versi Dokumen:** 1.1.0  
**Tanggal:** 2 Juli 2026  
**Status:** Draft untuk Review  
**Penulis:** Tim Product  

---

## Daftar Isi

1. [Executive Summary](#1-executive-summary)
2. [Problem Statement & Goals](#2-problem-statement--goals)
3. [Target Users & Personas](#3-target-users--personas)
4. [Feature Requirements (MoSCoW)](#4-feature-requirements-moscow)
5. [User Stories](#5-user-stories)
6. [Non-Functional Requirements](#6-non-functional-requirements)
7. [Success Metrics](#7-success-metrics)
8. [Out of Scope](#8-out-of-scope)

> **Catatan Versi 1.1.0:** Dokumen ini diperbarui untuk mencakup alur manufaktur — penambahan fitur Bill of Materials (BOM) dan Modul Produksi, serta pemisahan inventori menjadi Bahan Baku dan Barang Jadi.

---

## 1. Executive Summary

**Gudangs** adalah aplikasi mobile berbasis Flutter yang dirancang untuk membantu usaha kecil dan menengah (UKM) dalam mengelola operasional gudang secara mandiri, tanpa bergantung pada koneksi internet. Aplikasi ini menyediakan solusi terintegrasi yang mencakup manajemen inventori, pencatatan barang masuk (*inbound*) dan barang keluar (*outbound*), **alur manufaktur** (produksi bahan baku menjadi barang jadi), manajemen karyawan, pencatatan aktivitas harian, estimasi gaji, serta pelaporan keuangan sederhana.

Dengan pendekatan **offline-first** menggunakan penyimpanan lokal berbasis Hive (NoSQL), Gudangs memastikan seluruh operasional gudang dapat berjalan di lingkungan dengan konektivitas internet yang terbatas atau tidak ada sama sekali. Autentikasi menggunakan **biometrik** (fingerprint / Face ID) dengan fallback PIN memberikan kemudahan akses sekaligus keamanan data yang memadai.

**Alur Manufaktur Gudangs** mengikuti siklus tiga tahap:

```
[INBOUND] Pembelian Bahan Baku
        ↓
[PRODUKSI] Konversi Bahan Baku → Barang Jadi (via Bill of Materials)
        ↓
[OUTBOUND] Penjualan Barang Jadi
```

Inventori dipisah menjadi dua entitas: **Bahan Baku** (Raw Material) dan **Barang Jadi** (Finished Good). Setiap proses produksi menggunakan formula BOM (Bill of Materials) untuk menentukan bahan baku yang dibutuhkan, memvalidasi ketersediaan stok, dan menghitung Harga Pokok Produksi (HPP) secara otomatis.

Gudangs bertujuan menjadi "satu pintu" untuk semua kebutuhan operasional gudang manufaktur UKM — menggantikan pencatatan manual di buku atau spreadsheet yang rentan terhadap kesalahan manusia.

---

## 2. Problem Statement & Goals

### 2.1 Problem Statement

Banyak usaha kecil dan menengah di Indonesia masih menggunakan pencatatan manual (buku tulis atau spreadsheet) untuk operasional gudang mereka. Pendekatan ini menimbulkan beberapa masalah utama:

| No. | Masalah | Dampak |
|-----|---------|--------|
| 1 | **Ketidakakuratan stok** — pencatatan manual sering mengalami selisih antara data dan kondisi fisik | Kerugian finansial, salah pengiriman |
| 2 | **Tidak ada visibilitas real-time** — pemilik harus menghitung manual untuk mengetahui kondisi stok | Keputusan bisnis lambat dan tidak akurat |
| 3 | **Manajemen karyawan tersebar** — absensi, aktivitas, dan gaji dicatat terpisah-pisah | Gaji salah hitung, karyawan tidak puas |
| 4 | **Tidak ada laporan keuangan terintegrasi** — sulit menghitung margin kotor dari operasional gudang | Pemilik tidak tahu profitabilitas bisnis |
| 5 | **Ketergantungan internet** — solusi berbasis cloud tidak bisa dipakai di area minim sinyal | Operasional terganggu |

### 2.2 Goals

**Tujuan Bisnis:**
- Membantu UKM meningkatkan akurasi pengelolaan stok hingga mendekati 100%.
- Memberikan visibilitas keuangan sederhana (biaya inbound vs nilai outbound) kepada pemilik usaha.
- Mengurangi waktu yang dihabiskan untuk rekap manual minimal 70%.

**Tujuan Produk:**
- Menyediakan aplikasi mobile yang dapat digunakan sepenuhnya tanpa koneksi internet.
- Mengintegrasikan manajemen stok, pengiriman, SDM, dan keuangan dalam satu platform.
- Menghasilkan laporan yang dapat diekspor ke PDF dan Excel/CSV untuk keperluan audit atau review pemilik.

### 2.3 Non-Goals

- Gudangs **bukan** sistem akuntansi penuh (tidak menangani laporan laba-rugi, neraca, atau pajak).
- Gudangs **bukan** sistem ERP skala enterprise.
- Gudangs **tidak** memiliki fitur multi-tenant atau multi-gudang dalam versi awal.

---

## 3. Target Users & Personas

### 3.1 Segmentasi Pengguna

Gudangs ditujukan untuk **satu jenis pengguna utama**: Admin/Pemilik Gudang atau Kepala Gudang yang memiliki akses penuh ke seluruh fitur aplikasi. Tidak ada peran multi-pengguna dalam versi awal.

### 3.2 Personas

---

#### Persona 1: Budi Santoso — Pemilik Gudang UKM

| Atribut | Detail |
|---------|--------|
| **Usia** | 38 tahun |
| **Lokasi** | Surabaya, Jawa Timur |
| **Peran** | Pemilik gudang distribusi sembako skala kecil |
| **Pendidikan** | SMA/SMK |
| **Tech Savviness** | Menengah — terbiasa dengan WhatsApp, Excel, dan aplikasi Android |
| **Perangkat** | Android mid-range (Samsung Galaxy A series) |

**Kebutuhan Utama:**
- Melihat kondisi stok secara cepat tanpa harus membuka-buka catatan buku.
- Mengetahui berapa total pengeluaran untuk pembelian bahan baku minggu ini.
- Memastikan gaji karyawan harian dihitung dengan benar berdasarkan jumlah pekerjaan.

**Pain Points:**
- "Sering ada selisih stok di akhir bulan tapi susah dilacak kesalahannya."
- "Menghitung gaji karyawan borongan itu memakan waktu lama kalau manual."
- "Gudang saya di pinggiran kota, sinyal internet sering tidak stabil."

**Quote:** *"Saya butuh aplikasi yang simpel tapi bisa kasih saya semua info yang saya butuhkan dalam satu layar."*

---

#### Persona 2: Sari Wulandari — Kepala Gudang/Admin Operasional

| Atribut | Detail |
|---------|--------|
| **Usia** | 27 tahun |
| **Lokasi** | Bekasi, Jawa Barat |
| **Peran** | Kepala gudang yang ditugaskan pemilik untuk mengelola operasional harian |
| **Pendidikan** | D3 Manajemen Logistik |
| **Tech Savviness** | Menengah-Tinggi — terbiasa dengan aplikasi produktivitas |
| **Perangkat** | Android high-end atau iPhone |

**Kebutuhan Utama:**
- Mencatat barang masuk dan keluar dengan cepat setiap hari.
- Melacak aktivitas dan produktivitas setiap karyawan harian.
- Menghasilkan laporan yang bisa langsung dikirim ke pemilik via WhatsApp.

**Pain Points:**
- "Memasukkan data ke Excel membutuhkan waktu lama dan rawan salah ketik."
- "Susah membuat laporan cepat saat pemilik tiba-tiba minta data."
- "Perlu buka banyak file untuk memverifikasi stok vs pengiriman."

**Quote:** *"Kalau bisa satu aplikasi untuk semua yang saya butuhkan, pekerjaan saya jadi jauh lebih efisien."*

---

## 4. Feature Requirements (MoSCoW)

### Legenda Prioritas MoSCoW
- **M (Must Have):** Wajib ada di versi pertama (MVP).
- **S (Should Have):** Sangat diinginkan, idealnya ada di v1.
- **C (Could Have):** Bagus jika ada, bisa masuk ke rilis berikutnya.
- **W (Won't Have):** Tidak akan dikerjakan dalam siklus ini.

---

### FR-01: Keamanan — Autentikasi Biometrik

| ID | Fitur | Prioritas | Keterangan |
|----|-------|-----------|------------|
| FR-01.1 | Login menggunakan fingerprint | **Must** | Autentikasi biometrik fingerprint |
| FR-01.2 | Login menggunakan Face ID | **Should** | Autentikasi biometrik Face ID |
| FR-01.3 | Fallback ke PIN | **Must** | Harus tersedia jika biometrik gagal/tidak tersedia |
| FR-01.4 | Pengaturan PIN (buat, ubah) | **Must** | Admin dapat mengatur PIN aplikasi |
| FR-01.5 | Auto-lock saat aplikasi background | **Could** | Keamanan tambahan |

---

### FR-02: Dashboard & Statistik

| ID | Fitur | Prioritas | Keterangan |
|----|-------|-----------|------------|
| FR-02.1 | Ringkasan stok (total SKU & unit) | **Must** | Widget kartu di halaman utama |
| FR-02.2 | Ringkasan pengiriman hari ini | **Must** | Total inbound & outbound hari ini |
| FR-02.3 | Aktivitas karyawan hari ini | **Must** | Jumlah aktivitas yang tercatat hari ini |
| FR-02.4 | Grafik tren stok mingguan | **Should** | Grafik garis/batang |
| FR-02.5 | Grafik tren pengiriman mingguan | **Should** | Grafik garis/batang |
| FR-02.6 | Total biaya inbound per periode | **Must** | Total pengeluaran pembelian bahan baku |
| FR-02.7 | Total nilai outbound per periode | **Must** | Total nilai penjualan barang keluar |
| FR-02.8 | Margin kotor (outbound - inbound) | **Must** | Selisih nilai outbound vs biaya inbound |

---

### FR-03: Manajemen Stok/Inventori

| ID | Fitur | Prioritas | Keterangan |
|----|-------|-----------|------------|
| FR-03.1 | Tambah produk baru | **Must** | Form: nama, SKU, kategori, jumlah awal, satuan |
| FR-03.2 | Edit data produk | **Must** | Ubah nama, kategori, satuan |
| FR-03.3 | Hapus produk | **Must** | Dengan konfirmasi |
| FR-03.4 | Lihat daftar produk | **Must** | List dengan search & filter kategori |
| FR-03.5 | Detail produk + riwayat stok | **Must** | Histori perubahan stok masuk/keluar |
| FR-03.6 | Peringatan stok minimum | **Could** | Notifikasi lokal jika stok di bawah threshold |

---

### FR-04: Inbound — Penerimaan Barang Masuk

| ID | Fitur | Prioritas | Keterangan |
|----|-------|-----------|------------|
| FR-04.1 | Catat barang masuk | **Must** | Pilih produk, isi jumlah, tanggal, keterangan |
| FR-04.2 | Input harga per unit (biaya beli) | **Must** | Kalkulasi total biaya otomatis |
| FR-04.3 | Total biaya otomatis terhitung | **Must** | harga per unit x jumlah |
| FR-04.4 | Stok produk otomatis bertambah | **Must** | Sinkronisasi langsung ke inventori |
| FR-04.5 | Daftar histori inbound | **Must** | Riwayat dengan filter tanggal & produk |
| FR-04.6 | Detail & edit record inbound | **Should** | Edit catatan yang sudah ada |

---

### FR-05: Outbound — Pengiriman Barang Keluar

| ID | Fitur | Prioritas | Keterangan |
|----|-------|-----------|------------|
| FR-05.1 | Catat pengiriman baru | **Must** | Pilih produk, jumlah, tujuan, tanggal, status |
| FR-05.2 | Input harga jual per unit | **Must** | Kalkulasi total nilai pengiriman otomatis |
| FR-05.3 | Total nilai pengiriman otomatis | **Must** | harga jual per unit x jumlah |
| FR-05.4 | Stok produk otomatis berkurang | **Must** | Sinkronisasi langsung ke inventori |
| FR-05.5 | Daftar histori outbound | **Must** | Riwayat dengan filter tanggal, produk, tujuan |
| FR-05.6 | Status pengiriman | **Must** | Status: Pending, Terkirim, Dibatalkan |
| FR-05.7 | Edit/update status pengiriman | **Should** | Update status tanpa mengubah data lain |

---

### FR-06: Manajemen Karyawan

| ID | Fitur | Prioritas | Keterangan |
|----|-------|-----------|------------|
| FR-06.1 | Tambah karyawan baru | **Must** | Form: nama lengkap, nomor HP, posisi/jabatan |
| FR-06.2 | Edit data karyawan | **Must** | Ubah info profil karyawan |
| FR-06.3 | Nonaktifkan/hapus karyawan | **Must** | Toggle status aktif/nonaktif |
| FR-06.4 | Daftar karyawan dengan filter | **Must** | Filter berdasarkan status aktif/nonaktif |
| FR-06.5 | Detail profil karyawan | **Should** | Termasuk ringkasan aktivitas |

---

### FR-07: Aktivitas Karyawan (Harian)

| ID | Fitur | Prioritas | Keterangan |
|----|-------|-----------|------------|
| FR-07.1 | Catat aktivitas harian karyawan | **Must** | Input: karyawan, jenis pekerjaan, jumlah unit, tanggal |
| FR-07.2 | Kalkulasi estimasi gaji otomatis | **Must** | jumlah unit x tarif per unit jenis pekerjaan |
| FR-07.3 | Daftar aktivitas per hari | **Must** | Filter tanggal, karyawan, jenis pekerjaan |
| FR-07.4 | Edit/hapus record aktivitas | **Should** | Koreksi data yang salah |

---

### FR-08: Estimasi Gaji

| ID | Fitur | Prioritas | Keterangan |
|----|-------|-----------|------------|
| FR-08.1 | Kalkulasi gaji per karyawan | **Must** | Berdasarkan rentang tanggal custom |
| FR-08.2 | Pilih rentang tanggal (mingguan/bulanan) | **Must** | Date picker custom |
| FR-08.3 | Breakdown per jenis pekerjaan | **Must** | Detail: jenis pekerjaan, unit, tarif, subtotal |
| FR-08.4 | Ringkasan total gaji per karyawan | **Must** | Total estimasi gaji dalam periode tersebut |
| FR-08.5 | Perbandingan antar karyawan | **Could** | Tabel perbandingan produktivitas |

---

### FR-09: Pengaturan

| ID | Fitur | Prioritas | Keterangan |
|----|-------|-----------|------------|
| FR-09.1 | Manajemen jenis pekerjaan | **Must** | CRUD: nama jenis pekerjaan + tarif per unit |
| FR-09.2 | Pengaturan PIN | **Must** | Buat atau ubah PIN |
| FR-09.3 | Info aplikasi | **Must** | Versi, tentang, lisensi |
| FR-09.4 | Backup/restore data lokal | **Could** | Export/import file database Hive |

---

### FR-10: Laporan & Export

| ID | Fitur | Prioritas | Keterangan |
|----|-------|-----------|------------|
| FR-10.1 | Laporan stok inventori | **Must** | Daftar semua produk dengan stok terkini |
| FR-10.2 | Laporan inbound per periode | **Must** | Histori + total biaya pembelian |
| FR-10.3 | Laporan outbound per periode | **Must** | Histori + total nilai penjualan |
| FR-10.4 | Laporan keuangan ringkasan | **Must** | Total inbound cost vs outbound value, margin |
| FR-10.5 | Laporan aktivitas karyawan | **Must** | Per karyawan per periode |
| FR-10.6 | Laporan gaji karyawan | **Must** | Estimasi gaji per periode |
| FR-10.7 | Export ke PDF | **Must** | Format PDF siap cetak |
| FR-10.8 | Export ke Excel/CSV | **Must** | Format xlsx atau csv |

---

### FR-11: Bill of Materials (BOM)

| ID | Fitur | Prioritas | Keterangan |
|----|-------|-----------|------------|
| FR-11.1 | Tambah BOM baru untuk produk jadi | **Must** | Form: nama BOM, pilih barang jadi, daftar komponen bahan baku |
| FR-11.2 | Edit BOM yang sudah ada | **Must** | Ubah formula/komponen BOM |
| FR-11.3 | Hapus BOM | **Must** | Dengan konfirmasi; tidak dapat dihapus jika ada produksi aktif |
| FR-11.4 | Lihat daftar BOM | **Must** | List dengan nama produk jadi dan jumlah komponen |
| FR-11.5 | Tambah/hapus komponen bahan baku dalam BOM | **Must** | Setiap komponen: pilih bahan baku + qty per unit produk jadi |
| FR-11.6 | 1 BOM hanya untuk 1 barang jadi | **Must** | Relasi one-to-one antara BOM dan FinishedGood |

---

### FR-12: Modul Produksi

| ID | Fitur | Prioritas | Keterangan |
|----|-------|-----------|------------|
| FR-12.1 | Jalankan proses produksi | **Must** | Pilih BOM, input jumlah unit yang diproduksi |
| FR-12.2 | Validasi stok bahan baku sebelum produksi | **Must** | Sistem memeriksa ketersediaan semua komponen BOM |
| FR-12.3 | Blokir produksi jika stok tidak cukup | **Must** | Tampilkan pesan detail: bahan mana yang kurang berapa |
| FR-12.4 | Pengurangan stok bahan baku otomatis | **Must** | Saat konfirmasi produksi, stok bahan baku berkurang |
| FR-12.5 | Penambahan stok barang jadi otomatis | **Must** | Saat konfirmasi produksi, stok barang jadi bertambah |
| FR-12.6 | Kalkulasi HPP otomatis per batch | **Must** | HPP = total biaya bahan baku terpakai ÷ jumlah unit diproduksi |
| FR-12.7 | Riwayat produksi tersimpan | **Must** | Tanggal, produk, jumlah, bahan terpakai, HPP per batch |
| FR-12.8 | Catatan produksi (opsional) | **Should** | Field keterangan/catatan per batch produksi |

---

### FR-13: Inventori Terpisah (Bahan Baku & Barang Jadi)

| ID | Fitur | Prioritas | Keterangan |
|----|-------|-----------|------------|
| FR-13.1 | CRUD Bahan Baku (RawMaterial) | **Must** | Entitas terpisah dari barang jadi |
| FR-13.2 | CRUD Barang Jadi (FinishedGood) | **Must** | Entitas terpisah dari bahan baku, memiliki field HPP |
| FR-13.3 | Inbound hanya untuk Bahan Baku | **Must** | Form inbound hanya memilih dari daftar RawMaterial |
| FR-13.4 | Outbound hanya untuk Barang Jadi | **Must** | Form outbound hanya memilih dari daftar FinishedGood |

---

## 5. User Stories

### Autentikasi

> **US-001** — *As an admin, I want to log in using my fingerprint, so that I can quickly access the app without typing a password.*

> **US-002** — *As an admin, I want to use a PIN as a fallback login method, so that I can still access the app when biometric authentication is unavailable.*

> **US-003** — *As an admin, I want to set and change my PIN, so that I can maintain the security of the application.*

### Dashboard

> **US-004** — *As an admin, I want to see a summary of total stock (SKU count and total units) on the dashboard, so that I can quickly assess overall inventory levels.*

> **US-005** — *As an admin, I want to see today's inbound and outbound summary on the dashboard, so that I know the shipping activity at a glance.*

> **US-006** — *As an admin, I want to see total inbound cost and outbound value per period with gross margin, so that I understand the financial performance of the warehouse.*

> **US-007** — *As an admin, I want to view weekly trend charts for stock and shipments, so that I can identify patterns and make better decisions.*

### Inventori

> **US-008** — *As an admin, I want to add new products with SKU, category, unit, and initial stock, so that the system can track inventory for each item.*

> **US-009** — *As an admin, I want to edit or delete a product, so that the product catalog stays accurate.*

> **US-010** — *As an admin, I want to view the stock change history of a product, so that I can trace any discrepancies.*

### Inbound

> **US-011** — *As an admin, I want to record incoming goods with product, quantity, date, and unit cost, so that the system automatically updates stock and calculates total purchase cost.*

> **US-012** — *As an admin, I want to view the inbound history filtered by date and product, so that I can review past purchases.*

### Outbound

> **US-013** — *As an admin, I want to record an outbound shipment with product, quantity, destination, date, selling price, and status, so that the system automatically reduces stock and calculates total shipment value.*

> **US-014** — *As an admin, I want to update the status of an outbound shipment (Pending, Terkirim, Dibatalkan), so that I can track delivery progress.*

> **US-015** — *As an admin, I want to view the outbound history filtered by date, product, and destination, so that I can review past shipments.*

### Karyawan

> **US-016** — *As an admin, I want to add an employee with their name, phone number, and position, so that they can be assigned to daily work activities.*

> **US-017** — *As an admin, I want to deactivate an employee without deleting their record, so that historical data is preserved.*

### Aktivitas Karyawan

> **US-018** — *As an admin, I want to record daily work activities for each employee (job type, units done, date), so that the system can automatically calculate estimated wages.*

> **US-019** — *As an admin, I want to filter activity records by date, employee, and job type, so that I can monitor individual productivity.*

### Estimasi Gaji

> **US-020** — *As an admin, I want to calculate estimated wages for each employee over a custom date range, so that I know how much to pay each worker.*

> **US-021** — *As an admin, I want to see a breakdown of wages per job type for each employee, so that the calculation is transparent and verifiable.*

### Pengaturan

> **US-022** — *As an admin, I want to add job types with their unit rates, so that wage calculations are based on the correct rate for each type of work.*

> **US-023** — *As an admin, I want to edit or delete job types, so that the rate configuration stays up to date.*

### Laporan & Export

> **US-024** — *As an admin, I want to export the inventory stock report to PDF, so that I can share it with the owner or auditors.*

> **US-025** — *As an admin, I want to export inbound and outbound reports per period to Excel/CSV, so that I can do further analysis in a spreadsheet.*

> **US-026** — *As an admin, I want to generate a financial summary report (total costs vs. total sales value and gross margin), so that I can review the warehouse's financial performance.*

> **US-027** — *As an admin, I want to export employee wage reports per period to PDF, so that the payroll summary can be used as a payment reference.*

### Bill of Materials (BOM)

> **US-028** — *Sebagai admin, saya ingin membuat Bill of Materials (BOM) untuk setiap produk jadi dengan mendefinisikan daftar bahan baku dan jumlah yang dibutuhkan per unit, agar formula produksi terdokumentasi secara digital dan dapat digunakan berulang kali.*

> **US-029** — *Sebagai admin, saya ingin mengedit BOM yang sudah ada (menambah, mengubah, atau menghapus komponen), agar formula produksi selalu akurat sesuai kondisi terkini.*

> **US-030** — *Sebagai admin, saya ingin melihat daftar semua BOM beserta komponen bahan bakunya, agar saya dapat dengan mudah meninjau formula produksi yang tersedia sebelum memulai produksi.*

### Modul Produksi

> **US-031** — *Sebagai admin, saya ingin memilih BOM dan menentukan jumlah unit yang akan diproduksi, lalu sistem secara otomatis memvalidasi apakah stok bahan baku mencukupi, agar saya tahu sebelum produksi dimulai apakah bahan tersedia.*

> **US-032** — *Sebagai admin, saya ingin sistem memblokir proses produksi dan menampilkan pesan detail tentang bahan baku mana yang kurang dan berapa jumlah kekurangannya, agar saya dapat segera melakukan pembelian bahan baku yang diperlukan.*

> **US-033** — *Sebagai admin, saya ingin mengkonfirmasi produksi sehingga stok bahan baku otomatis berkurang dan stok barang jadi otomatis bertambah sesuai jumlah produksi, agar inventori selalu akurat tanpa input manual terpisah.*

> **US-034** — *Sebagai admin, saya ingin sistem menghitung HPP (Harga Pokok Produksi) secara otomatis per batch produksi berdasarkan total biaya bahan baku yang digunakan, agar saya mengetahui biaya produksi aktual dan dapat menentukan harga jual yang tepat.*

> **US-035** — *Sebagai admin, saya ingin melihat riwayat produksi lengkap (tanggal, produk, jumlah, bahan terpakai, dan HPP per batch), agar saya dapat melacak histori produksi dan menganalisis tren biaya produksi dari waktu ke waktu.*

---

## 6. Non-Functional Requirements

### 6.1 Performa

| NFR-ID | Persyaratan | Target |
|--------|-------------|--------|
| NFR-P-01 | Waktu startup aplikasi (cold start) | <= 3 detik pada perangkat mid-range |
| NFR-P-02 | Waktu respons navigasi antar halaman | <= 300 ms |
| NFR-P-03 | Waktu penyelesaian operasi CRUD | <= 500 ms |
| NFR-P-04 | Waktu generate laporan PDF | <= 5 detik untuk 500 baris data |
| NFR-P-05 | Waktu generate file Excel/CSV | <= 3 detik untuk 500 baris data |

### 6.2 Keamanan

| NFR-ID | Persyaratan |
|--------|-------------|
| NFR-S-01 | Seluruh data disimpan secara lokal menggunakan Hive dengan enkripsi AES-256 |
| NFR-S-02 | Autentikasi biometrik menggunakan local_auth Flutter (memanfaatkan secure enclave perangkat) |
| NFR-S-03 | PIN di-hash menggunakan algoritma bcrypt sebelum disimpan di Hive |
| NFR-S-04 | Aplikasi tidak mengirim data apapun ke server eksternal |
| NFR-S-05 | Sesi otomatis terkunci setelah periode tidak aktif yang dikonfigurasi |

### 6.3 Keandalan & Ketersediaan

| NFR-ID | Persyaratan |
|--------|-------------|
| NFR-R-01 | Aplikasi harus berfungsi sepenuhnya tanpa koneksi internet (100% offline-first) |
| NFR-R-02 | Tidak ada kehilangan data saat aplikasi ditutup paksa (force close) |
| NFR-R-03 | Crash rate target < 0,5% dari total sesi pengguna |

### 6.4 Kompatibilitas & Platform

| NFR-ID | Persyaratan |
|--------|-------------|
| NFR-C-01 | Android minimum SDK 21 (Android 5.0 Lollipop) |
| NFR-C-02 | iOS minimum 13.0 |
| NFR-C-03 | Mendukung layar 4,7" hingga 7" (smartphone) |
| NFR-C-04 | Responsif terhadap orientasi portrait (landscape opsional) |

### 6.5 Produksi & Validasi Stok

| NFR-ID | Persyaratan | Target |
|--------|-------------|--------|
| NFR-PRD-01 | Waktu validasi stok bahan baku sebelum produksi | <= 500 ms untuk BOM dengan hingga 50 komponen |
| NFR-PRD-02 | Kalkulasi HPP harus akurat hingga 2 desimal | Tidak ada pembulatan yang menyebabkan selisih > Rp 1 |
| NFR-PRD-03 | Atomisitas operasi produksi | Pengurangan stok bahan baku dan penambahan stok barang jadi harus terjadi dalam satu operasi atomik; tidak boleh ada partial update |
| NFR-PRD-04 | Pesan error validasi stok harus informatif | Menyebutkan nama bahan baku, stok tersedia, dan kekurangan untuk setiap komponen yang tidak mencukupi |

### 6.6 Usability

| NFR-ID | Persyaratan |
|--------|-------------|
| NFR-U-01 | Seluruh UI dalam Bahasa Indonesia |
| NFR-U-02 | Pengguna baru dapat menyelesaikan task utama tanpa pelatihan khusus |
| NFR-U-03 | Navigasi utama dapat dicapai dalam maksimal 3 tap dari halaman manapun |
| NFR-U-04 | Tema Light Mode dengan aksen hijau yang konsisten di seluruh aplikasi |

### 6.7 Maintainability

| NFR-ID | Persyaratan |
|--------|-------------|
| NFR-M-01 | Codebase menggunakan arsitektur yang jelas (Riverpod + Repository Pattern) |
| NFR-M-02 | Unit test coverage minimal 60% untuk logika bisnis inti |
| NFR-M-03 | Kode mengikuti Dart/Flutter style guide dan menggunakan linter yang dikonfigurasi |

---

## 7. Success Metrics

### 7.1 Metrics Kualitas Produk (Internal)

| Metric | Target | Cara Mengukur |
|--------|--------|---------------|
| Crash-free sessions | > 99,5% | Laporan crash dari monitoring |
| Akurasi kalkulasi gaji | 100% | Unit testing terhadap formula kalkulasi |
| Akurasi stok update | 100% | Integration testing inbound/outbound |
| Performa cold start | <= 3 detik | Pengujian pada perangkat Android mid-range (4 GB RAM) |

### 7.2 Metrics Adopsi Pengguna (Post-Launch)

| Metric | Target 3 Bulan Pertama |
|--------|------------------------|
| Pengguna aktif harian (DAU) | 50 pengguna |
| Retensi 30 hari | >= 60% |
| Rating aplikasi (Google Play / App Store) | >= 4.3 / 5.0 |
| Pengguna yang menggunakan fitur Export | >= 40% dari DAU |

### 7.3 Metrics Nilai Bisnis

| Metric | Target |
|--------|--------|
| Pengurangan waktu rekap manual per minggu | Minimal 70% dibanding sebelum pakai aplikasi |
| Akurasi stok akhir bulan | Selisih 0% antara data aplikasi dan fisik |
| Kepuasan pengguna (NPS / survey) | NPS >= 30 |

---

## 8. Out of Scope

Fitur dan kapabilitas berikut secara eksplisit **tidak termasuk** dalam lingkup pengembangan Gudangs versi 1.0:

| No. | Item | Alasan |
|-----|------|--------|
| 1 | Sinkronisasi Cloud / Backend Server | Gudangs adalah offline-first. Sinkronisasi cloud dapat dipertimbangkan di v2. |
| 2 | Multi-pengguna / Multi-role | Hanya satu admin. RBAC di luar scope v1. |
| 3 | Multi-gudang | Satu aplikasi untuk satu entitas gudang. |
| 4 | Integrasi dengan sistem POS atau e-commerce | Terlalu kompleks untuk v1. |
| 5 | Laporan Laba-Rugi lengkap / Akuntansi | Hanya margin kotor kasar, bukan laporan akuntansi formal. |
| 6 | Manajemen Pemesanan (Purchase Order / Sales Order) | Bukan bagian dari scope MVP. |
| 7 | Notifikasi Push dari Server | Tidak ada server. |
| 8 | Barcode/QR Scanner untuk produk | Bisa masuk v2 jika ada permintaan pengguna. |
| 9 | Dashboard web/desktop | Platform target adalah mobile saja. |
| 10 | Payroll resmi / integrasi penggajian | Gudangs hanya menyediakan estimasi gaji, bukan sistem penggajian terintegrasi. |
| 11 | Multi-level BOM (BOM di dalam BOM) | Versi ini hanya mendukung BOM satu tingkat (flat BOM). BOM hierarkis di luar scope v1. |
| 12 | Perencanaan produksi / MRP | Sistem tidak membuat jadwal atau rekomendasi produksi otomatis. |

---

*Dokumen ini dibuat berdasarkan spesifikasi awal aplikasi Gudangs. Perubahan pada dokumen ini harus melalui review dan persetujuan Product Owner.*

---
**Akhir Dokumen PRD — Gudangs v1.1.0**
