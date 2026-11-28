# Laporan Praktikum Basis Data Lanjut: Migrasi Database Relasional (MySQL) ke Wide-Column NoSQL (Apache Cassandra)

| Informasi Praktikum | Keterangan |
| :--- | :--- |
| **Studi Kasus** | Sistem Pendataan & Verifikasi Bantuan Sosial (`tepatsasar_modul10`) |
| **Database Sumber** | MySQL (RDBMS) — `tepatsasar_modul10` |
| **Database Target** | Apache Cassandra 5.0 (Wide-Column NoSQL) — `tepatsasar_cassandra` |
| **Volume Data** | 708.350 baris (250.004 warga, 375.009 pengajuan, 83.337 verifikasi) |
| **Nama / NIM** | Evan Bhagaskara — 264311068<br>Ikhzaniero Ardyana Juniar — 264311070<br>Muhammad Andy Dwi Subandi — 264311076 |
| **Kelas / Kelompok** | *(IC / Kelompok 7)* |

---

## Daftar Isi

1. [Latar Belakang & Tujuan Migrasi](#1-latar-belakang--tujuan-migrasi)
2. [Arsitektur Sistem & Teknologi yang Digunakan](#2-arsitektur-sistem--teknologi-yang-digunakan)
3. [Struktur Direktori Proyek](#3-struktur-direktori-proyek)
4. [Desain Skema & Strategi Denormalisasi](#4-desain-skema--strategi-denormalisasi)
5. [Implementasi Pipeline ETL](#5-implementasi-pipeline-etl-extract-transform-load)
6. [Pengujian CRUD & Workload Query](#6-pengujian-crud--workload-query)
7. [Hasil Validasi & Bukti Eksekusi](#7-hasil-validasi--bukti-eksekusi)
8. [Kendala Teknis & Solusi](#8-kendala-teknis--solusi-troubleshooting)
9. [Kesimpulan](#9-kesimpulan)

---

## 1. Latar Belakang & Tujuan Migrasi

### 1.1 Permasalahan pada Model Relasional (MySQL)
Sistem pendataan bantuan sosial (`tepatsasar_modul10`) menyimpan data kependudukan warga rentan, riwayat pengajuan bantuan, serta catatan verifikasi lapangan dalam skema relasional ternormalisasi. Pada skala dataset mencapai **708.350 baris**, beberapa pola pembacaan utama mengalami penurunan efisiensi:
1. **Ketergantungan Operasi `JOIN`:** Menampilkan riwayat pengajuan bantuan beserta identitas lengkap warga (`nik`, `nama`, `kategori_kerentanan`) mewajibkan penggabungan tabel `pengajuan_bantuan` dan `warga` pada setiap permintaan baca.
2. **Pengurutan Kronologis Berulang:** Riwayat pengajuan dan hasil verifikasi lapangan harus selalu diurutkan dari tanggal terbaru (*descending*), yang membebani indeks B-Tree saat volume transaksi bertambah.
3. **Skalabilitas Horizontal:** Arsitektur *single-node* RDBMS memiliki keterbatasan ketika beban penulisan (*write-heavy*) dari banyak petugas lapangan meningkat secara bersamaan.

### 1.2 Tujuan Penerapan Apache Cassandra
Migrasi ke **Apache Cassandra 5.0** bertujuan untuk:
- Menerapkan **Query-Driven Data Modeling** dan **Denormalisasi** sehingga setiap kebutuhan query aplikasi dapat dilayani oleh satu tabel spesifik tanpa `JOIN`.
- Memanfaatkan **Partition Key** dan **Clustering Column** untuk memastikan pembacaan data berlangsung cepat ($O(1)$ pencarian partisi) dan terurut secara fisik di disk.
- Membangun *pipeline* migrasi **ETL (Extract, Transform, Load)** yang terstruktur, *fault-tolerant*, dan tervalidasi secara matematis.

---

## 2. Arsitektur Sistem & Teknologi yang Digunakan

```text
+-------------------+       Extract        +-----------------------+
|   MySQL Server    | ===================> |  01_extract_mysql.py  |
| (tepatsasar_      |    (mysql-connector) |   (raw_mysql.json)    |
|     modul10)      |                      +-----------+-----------+
+-------------------+                                  |
                                                       v Transform & Denormalisasi
+-------------------+    Load (Batching)   +-----------------------+
| Apache Cassandra  | <=================== | 02_transform_         |
|  5.0 (Docker)     |  (cassandra-driver)  |     cassandra.py      |
| (tepatsasar_      |                      +-----------------------+
|    cassandra)     |
+---------+---------+
          |
          +-----> DDL, CRUD & Workload : jalankan_cql.py (.cql files)
          +-----> Validasi Integritas  : 07_validasi_migrasi.py
```

### Lingkungan Teknologi

- **DBMS Sumber:** MySQL via Laragon (`localhost:3306`)
- **DBMS Target:** Apache Cassandra 5.0 berjalan di Docker Container `cassandra-db` (`127.0.0.1:9042`, cluster `datacenter1`, status node `UN`)
- **Runtime & Driver:** Python 3.13 dengan pustaka `mysql-connector-python`, `cassandra-driver`, dan `pyasyncore`
- **CQL Runner Kustom (`jalankan_cql.py`):** Utilitas berbasis Python (CQL Binary Protocol) untuk mengeksekusi berkas `.cql` langsung ke port 9042 tanpa bergantung pada driver Java/JDBC eksternal.

## 3. Struktur Direktori Proyek

```plaintext
praktikum-basis-data
├── .vscode/
│   ├── extensions.json             # Rekomendasi ekstensi VS Code
│   ├── settings.json               # Konfigurasi auto-save dan Python terminal
│   └── tasks.json                  # Otomatisasi task pipeline migrasi
├── jalankan_cql.py                 # Eksekutor query CQL native ke server Cassandra
├── mysql/
│   └── source-schema-and-data/
│       └── modul10.sql             # Dump skema & data sumber MySQL (708.350 baris)
├── migration/
│   ├── extraction/
│   │   └── 01_extract_mysql.py     # Tahap 1: Ekstraksi 3 tabel dari MySQL
│   ├── transformation/
│   │   └── 02_transform_cassandra.py # Tahap 2: Pembersihan NULL & denormalisasi
│   ├── loading/
│   │   └── 03_load_cassandra.py    # Tahap 3: Pemuatan konkuren ke Cassandra
│   └── validation/
│       └── 07_validasi_migrasi.py  # Tahap 4: Audit jumlah baris MySQL vs Cassandra
├── target-dbms/
│   ├── structure/
│   │   └── 04_struktur_keyspace.cql # DDL Keyspace & 3 Tabel Cassandra
│   ├── crud/
│   │   └── 05_crud_pengajuan.cql   # Pengujian INSERT, SELECT, UPDATE, DELETE
│   └── workload-query/
│       └── 06_workload_query.cql   # Pengujian 3 pola query utama aplikasi
├── evidence/
│   └── screenshots/                # Bukti tangkapan layar seluruh tahapan
└── README.md                       # Laporan dokumentasi proyek
```

## 4. Desain Skema & Strategi Denormalisasi

Berbeda dengan MySQL yang berfokus pada normalisasi (3NF) untuk menghindari duplikasi data, pemodelan di Cassandra dirancang berdasarkan pola query aplikasi (**Query-First Design**).

### 4.1 Pemetaan Tabel Sumber ke Target

| Tabel Sumber (MySQL) | Baris | Tabel Target (Cassandra) | Struktur Primary Key | Perubahan Model Data |
|---|---:|---|---|---|
| `warga` | 250.004 | `warga_by_rt` | `PRIMARY KEY ((id_rt), id_warga)` | Partisi dibagi berdasarkan wilayah `id_rt` agar daftar warga per RT dibaca dalam satu partisi. |
| `pengajuan_bantuan` + `warga` | 375.009 | `pengajuan_by_warga` | `PRIMARY KEY ((id_warga), tanggal_pengajuan, id_pengajuan)` | **Denormalisasi:** kolom `nik`, `nama_warga`, dan `kategori_kerentanan` disalin dari tabel `warga` agar riwayat bantuan tampil utuh tanpa JOIN. |
| `verifikasi_lapangan` | 83.337 | `verifikasi_by_warga` | `PRIMARY KEY ((id_warga), tanggal_verifikasi, id_verifikasi)` | Dikelompokkan per `id_warga` dengan urutan kronologis terbaru (DESC). |

### 4.2 Detail Definisi Skema Cassandra (`04_struktur_keyspace.cql`)

- **Keyspace `tepatsasar_cassandra`:** menggunakan strategi replikasi `SimpleStrategy` dengan `replication_factor: 1` (menyesuaikan lingkungan single-node pengembangan lokal).
- **Tabel `warga_by_rt`:** menggunakan `id_rt` sebagai *Partition Key* dan `id_warga` sebagai *Clustering Column* untuk menjamin keunikan tiap warga di dalam satu wilayah RT.
- **Tabel `pengajuan_by_warga`:** menggunakan *Composite Clustering Key* `(tanggal_pengajuan, id_pengajuan)` dengan klausa `WITH CLUSTERING ORDER BY (tanggal_pengajuan DESC, id_pengajuan DESC)` sehingga riwayat pengajuan terbaru selalu berada di urutan teratas partisi.
- **Tabel `verifikasi_by_warga`:** menggunakan struktur partisi serupa dengan `pengajuan_by_warga` untuk mempercepat penelusuran riwayat survei kelayakan penerima bantuan.

## 5. Implementasi Pipeline ETL (Extract, Transform, Load)

### Extraction (`01_extract_mysql.py`)

- Menghubungkan Python ke database `tepatsasar_modul10` menggunakan kursor berbasis kamus (`dictionary=True`).
- Mengonversi objek `datetime.date` dari MySQL menjadi string standar ISO-8601 (`YYYY-MM-DD`) agar kompatibel dengan tipe data `date` pada Cassandra.

### Transformation (`02_transform_cassandra.py`)

- **Penanganan nilai NULL:** kolom `id_rt` yang bernilai `NULL` pada tabel sumber diubah menjadi nilai default `0`, karena kolom bagian dari Partition Key di Cassandra tidak boleh bernilai `NULL`.
- **Denormalisasi berbasis in-memory lookup:** membangun indeks kamus `warga_lookup` di memori (`id_warga -> (nik, nama, kategori_kerentanan)`) untuk menggabungkan 375.009 baris `pengajuan_bantuan` dengan data warga dalam kompleksitas waktu $O(1)$ tanpa melakukan query berulang ke database.

### Loading (`03_load_cassandra.py`)

- Menggunakan **Prepared Statements** (`session.prepare`) agar server Cassandra tidak perlu mem-parsing ulang string query CQL pada setiap baris.
- Mengirimkan data dalam potongan (*batch*) berukuran **2.000 baris** menggunakan eksekusi konkuren (`execute_concurrent_with_args` dengan `concurrency=50`).
- Seluruh 708.350 baris berhasil dimuat dalam waktu **264,19 detik** (kecepatan rata-rata ~2.681 baris/detik).

## 6. Pengujian CRUD & Workload Query

### 6.1 Pengujian Operasi CRUD (`05_crud_pengajuan.cql`)

| Operasi | Deskripsi |
|---|---|
| **CREATE (INSERT)** | Menambahkan satu transaksi pengajuan baru (`id_warga=1`, `id_pengajuan=999001`, jenis bantuan BLT) beserta atribut denormalisasi warga. |
| **READ (SELECT)** | Mengambil kembali baris uji menggunakan spesifikasi lengkap Partition Key dan Clustering Column. |
| **UPDATE** | Memperbarui `status_pengajuan` dari `'diajukan'` menjadi `'disetujui'`. Di Cassandra, UPDATE wajib menyertakan seluruh komponen Primary Key (`id_warga`, `tanggal_pengajuan`, `id_pengajuan`) pada klausa `WHERE`. |
| **DELETE** | Menghapus data uji `id_pengajuan=999001` menggunakan Primary Key lengkap sehingga dataset kembali bersih sebelum tahap validasi akhir. |

### 6.2 Pengujian Workload Query (`06_workload_query.cql`)

1. **Workload 1 — Pencarian Warga per Wilayah:** mengambil daftar warga pada `id_rt = 1` dari tabel `warga_by_rt` tanpa pemindaian seluruh tabel (*full table scan*).
2. **Workload 2 — Riwayat Pengajuan Terpadu:** menampilkan riwayat pengajuan bantuan beserta `nama_warga` dan `nik` milik `id_warga = 1` dari `pengajuan_by_warga` dalam satu kali pembacaan partisi tanpa JOIN.
3. **Workload 3 — Riwayat Verifikasi Lapangan:** menampilkan catatan hasil survei petugas untuk `id_warga = 1` dari `verifikasi_by_warga` yang sudah terurut otomatis dari tanggal terbaru.

## 7. Hasil Validasi & Bukti Eksekusi

### 7.1 Perbandingan Jumlah Baris (MySQL vs Cassandra)

| Tabel Sumber (MySQL) | Jumlah Baris MySQL | Tabel Target (Cassandra) | Jumlah Baris Cassandra | Status Validasi |
|---|---:|---|---:|---|
| `warga` | 250.004 | `warga_by_rt` | 250.004 | ✅ VALID (COCOK) |
| `pengajuan_bantuan` | 375.009 | `pengajuan_by_warga` | 375.009 | ✅ VALID (COCOK) |
| `verifikasi_lapangan` | 83.337 | `verifikasi_by_warga` | 83.337 | ✅ VALID (COCOK) |
| **Total Keseluruhan** | **708.350** | **Total Keseluruhan** | **708.350** | **100% VALID** |

### 7.2 Dokumentasi Tangkapan Layar (Screenshots)

Seluruh bukti tersimpan di folder `evidence/screenshots/`:

1. Pembuatan Keyspace & Struktur Tabel Cassandra (`04_struktur_keyspace.cql`)
2. Eksekusi Pipeline Extract, Transform, dan Load (708.350 baris)
3. Pengujian Query CRUD & Workload tanpa JOIN
4. Validasi kecocokan data akhir MySQL vs Cassandra

## 8. Kendala Teknis & Solusi (Troubleshooting)

| No | Kendala yang Ditemukan | Penyebab | Solusi yang Diterapkan |
|:--:|---|---|---|
| 1 | `DependencyException: Unable to import asyncore module` saat menjalankan `cassandra-driver` | Modul bawaan `asyncore` telah dihapus pada Python 3.12 ke atas (lingkungan menggunakan Python 3.13). | Menginstal pustaka pengganti `pyasyncore` melalui `pip install pyasyncore`. |
| 2 | Ekstensi VS Code *Database Client* gagal terhubung (`cassandra-jdbc-driver-1.4.jar not exists`) | Ekstensi memerlukan perantara driver JDBC berbasis Java yang gagal diunduh otomatis. | Membuat script eksekutor CQL kustom (`jalankan_cql.py`) yang terhubung langsung ke port 9042 melalui protokol biner asli Cassandra. |
| 3 | Potensi kegagalan `INSERT` akibat `id_rt` bernilai `NULL` pada sebagian baris sumber | Cassandra melarang nilai `NULL` pada kolom yang menjadi bagian dari Primary Key. | Melakukan transformasi nilai `NULL` menjadi `0` pada tahap `02_transform_cassandra.py`. |

## 9. Kesimpulan

1. Proses migrasi database dari MySQL (`tepatsasar_modul10`) ke Apache Cassandra 5.0 (`tepatsasar_cassandra`) berhasil memindahkan seluruh **708.350 baris** data dengan tingkat akurasi **100% valid** pada ketiga tabel utama.
2. Penerapan *Query-Driven Modeling* dan denormalisasi terbukti menghilangkan kebutuhan operasi JOIN dalam menampilkan riwayat pengajuan bantuan beserta identitas warga, sekaligus menjaga performa pembacaan data tetap cepat dan terurut secara kronologis.
3. Kombinasi *prepared statements*, *batching* (2.000 baris/siklus), dan eksekusi konkuren (`concurrency=50`) mampu menyelesaikan pemuatan ratusan ribu data secara stabil tanpa kehabisan memori.