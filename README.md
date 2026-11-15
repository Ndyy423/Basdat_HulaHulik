# Praktikum Modul 11: Perkembangan DBMS dan Lingkup Penerapan Basis Data

Mata Kuliah Praktik Basis Data (RPL24108), Pertemuan 11.

## Anggota Kelompok

| Nama | NIM |
| --- | --- |
| Evan Bhagaskara           | 264311068 |
| Ikhzaniero Ardyana Juniar | 264311079 |
| Muhammad Andy Dwi Subandi | 264311076 |
## Studi Kasus

**TepatSasar**, aplikasi pendataan dan verifikasi warga prasejahtera di Madiun (SDG 1 Tanpa Kemiskinan). Basis data berasal dari Modul 10 dengan empat tabel: `petugas`, `warga`, `verifikasi_lapangan`, dan `pengajuan_bantuan`. Satu kolom JSON, `detail_kondisi`, ditambahkan pada tabel `warga` untuk menyimpan atribut kondisi warga yang berbeda tiap kategori kerentanan.

## DBMS yang Digunakan

| DBMS | Peran | Pengelola |
| --- | --- | --- |
| MySQL 8 | DBMS utama | phpMyAdmin (Laragon) |
| MariaDB | Pembanding | phpMyAdmin (Laragon) |
| PostgreSQL | Pembanding | DBeaver |

Engine penyimpanan MySQL dan MariaDB: **InnoDB**.

## Struktur Folder

```
praktikum_modul11/
├── sql/
│   └── modul11_json.sql
├── dokumentasi/
├── diagram/
│   └── pemodelan_objek.png
├── screenshot/
└── README.md
```

| Folder | Isi |
| --- | --- |
| `sql/` | Script SQL implementasi penyimpanan JSON |
| `dokumentasi/` | Laporan dan jawaban Post-Test |
| `diagram/` | Diagram pemodelan objek (class, attribute, method, inheritance) |
| `screenshot/` | Bukti hasil praktikum MySQL dan MariaDB |

## Cara Menjalankan

1. Jalankan Laragon, lalu **Start All**.
2. Buka phpMyAdmin dan buat database `tepatsasar_modul11` (collation `utf8mb4_general_ci`).
3. Import backup skema Modul 10 lewat tab **Import**.
4. Buka tab **SQL**, lalu jalankan isi `sql/modul11_json.sql` bagian demi bagian.
5. Untuk MariaDB, ganti versi database di Laragon, buat ulang database dan import backup, lalu ulangi langkah 4.

Catatan: pada MariaDB, ganti `utf8mb4_0900_ai_ci` menjadi `utf8mb4_general_ci` di file backup sebelum Import.

## Ringkasan Isi

- **Penyimpanan JSON:** `ALTER TABLE`, `INSERT`, `SELECT`, `UPDATE`, dan penghapusan atribut dengan `JSON_REMOVE`.
- **Pemodelan objek:** class `Warga` dengan subclass `WargaLansia`, `WargaDisabilitas`, dan `WargaKeluargaMiskin` (inheritance), serta class `Petugas`.
- **Analisis penerapan:** pendataan dan verifikasi bantuan warga prasejahtera, dengan alasan pemilihan MySQL/MariaDB berengine InnoDB.

## Catatan

Repository ini tidak memuat data warga asli, hanya data contoh untuk praktikum.
