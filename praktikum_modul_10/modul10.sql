-- =====================================================================
-- Praktikum Modul 10  : DBMS dan Aplikasi Basis Data
-- Studi Kasus         : Penyaluran Bantuan Tepat Sasar – SDG 1 “TANPA KEMISKINAN”
-- DBMS                : MySQL 8.0 (Community Server GPL),
-- Storage Engine      : InnoDB
-- Software Pengelola  : phpMyAdmin 5.2.3
-- Kelas		           : TRPL 1C
-- Dosen               : Bayu Prasetiyo Utomo, S.Kom., M.Eng.
-- Anggota Kelompok    : - Evan Bhagaskara            (264311068)
--                       - Ikhzaniero Ardyana Juniar  (264311070)
--                       - Muhammad Andy Dwi Subandi  (264311076)
--
-- Catatan             : Kredensial disimulasikan menggunakan hash SHA256.
-- =====================================================================

-- =====================================================================
-- TAHAP 1: EKSPLORASI DBMS
-- =====================================================================

SELECT VERSION();
SELECT @@version_comment;
SELECT @@default_storage_engine;
SHOW ENGINES;
SHOW DATABASES;

-- =====================================================================
-- TAHAP 2: IMPLEMENTASI BASIS DATA
-- =====================================================================
-- Jalankan baris DROP hanya bila ingin mengulang dari nol:
-- DROP DATABASE IF EXISTS tepatsasar_modul10;

CREATE DATABASE tepatsasar_modul10
  CHARACTER SET utf8mb4 COLLATE utf8mb4_general_ci;
USE tepatsasar_modul10;

-- ---- Tabel petugas ----
CREATE TABLE petugas (
  id_petugas INT UNSIGNED NOT NULL AUTO_INCREMENT,
  nama       VARCHAR(100) NOT NULL,
  username   VARCHAR(50)  NOT NULL,
  password   VARCHAR(255) NOT NULL,
  peran      ENUM('kader_rt','staf_kelurahan') NOT NULL,
  PRIMARY KEY (id_petugas),
  UNIQUE KEY uk_petugas_username (username)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

-- ---- Tabel warga ----
CREATE TABLE warga (
  id_warga            INT UNSIGNED NOT NULL AUTO_INCREMENT,
  id_petugas          INT UNSIGNED NOT NULL,
  nik                 CHAR(16)     NOT NULL,
  nama                VARCHAR(100) NOT NULL,
  alamat              VARCHAR(255) NOT NULL,
  kategori_kerentanan VARCHAR(50)  DEFAULT NULL,
  kondisi_ekonomi     VARCHAR(100) DEFAULT NULL,
  tanggal_dicatat     DATE         NOT NULL,
  jumlah_pengajuan    INT UNSIGNED NOT NULL DEFAULT 0,
  PRIMARY KEY (id_warga),
  UNIQUE KEY uk_warga_nik (nik),
  KEY idx_warga_petugas (id_petugas),
  CONSTRAINT fk_warga_petugas FOREIGN KEY (id_petugas)
    REFERENCES petugas (id_petugas)
    ON UPDATE CASCADE ON DELETE RESTRICT
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

-- ---- Tabel verifikasi_lapangan ----
CREATE TABLE verifikasi_lapangan (
  id_verifikasi      INT UNSIGNED NOT NULL AUTO_INCREMENT,
  id_warga           INT UNSIGNED NOT NULL,
  id_petugas         INT UNSIGNED NOT NULL,
  tanggal_verifikasi DATE NOT NULL,
  hasil_verifikasi   ENUM('layak','tidak_layak','perlu_tinjau') NOT NULL,
  catatan            VARCHAR(255) DEFAULT NULL,
  PRIMARY KEY (id_verifikasi),
  KEY idx_verif_warga (id_warga),
  KEY idx_verif_petugas (id_petugas),
  CONSTRAINT fk_verif_warga FOREIGN KEY (id_warga)
    REFERENCES warga (id_warga)
    ON UPDATE CASCADE ON DELETE RESTRICT,
  CONSTRAINT fk_verif_petugas FOREIGN KEY (id_petugas)
    REFERENCES petugas (id_petugas)
    ON UPDATE CASCADE ON DELETE RESTRICT
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

-- ---- Tabel pengajuan_bantuan ----
CREATE TABLE pengajuan_bantuan (
  id_pengajuan      INT UNSIGNED NOT NULL AUTO_INCREMENT,
  id_warga          INT UNSIGNED NOT NULL,
  jenis_bantuan     VARCHAR(50) NOT NULL,
  tanggal_pengajuan DATE NOT NULL,
  status_pengajuan  ENUM('diajukan','diverifikasi','disetujui','ditolak')
                    NOT NULL DEFAULT 'diajukan',
  PRIMARY KEY (id_pengajuan),
  KEY idx_pengajuan_warga (id_warga),
  CONSTRAINT fk_pengajuan_warga FOREIGN KEY (id_warga)
    REFERENCES warga (id_warga)
    ON UPDATE CASCADE ON DELETE RESTRICT
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

-- ---- Trigger sinkronisasi warga.jumlah_pengajuan (lanjutan Modul 9) ----
CREATE TRIGGER trg_pengajuan_after_insert
AFTER INSERT ON pengajuan_bantuan FOR EACH ROW
  UPDATE warga SET jumlah_pengajuan = jumlah_pengajuan + 1
  WHERE id_warga = NEW.id_warga;

CREATE TRIGGER trg_pengajuan_after_delete
AFTER DELETE ON pengajuan_bantuan FOR EACH ROW
  UPDATE warga SET jumlah_pengajuan = jumlah_pengajuan - 1
  WHERE id_warga = OLD.id_warga;

-- ---- Data awal ----
-- Menggunakan SHA2 untuk hashing password demi keamanan simulasi
INSERT INTO petugas (id_petugas, nama, username, password, peran) VALUES
(1, 'Kader Contoh', 'kader1', SHA2('kader123', 256), 'kader_rt'),
(2, 'Staf Kelurahan Contoh', 'staf1', SHA2('staf123', 256), 'staf_kelurahan');

INSERT INTO warga
 (id_warga, id_petugas, nik, nama, alamat, kategori_kerentanan, kondisi_ekonomi, tanggal_dicatat)
VALUES
(1, 1, '3577010101010001', 'Budi', 'RT 01 RW 01', 'lansia', 'tidak berpenghasilan tetap', '2026-10-01'),
(2, 1, '3577010101010002', 'Siti', 'RT 01 RW 02', 'disabilitas', 'buruh harian', '2026-10-01'),
(3, 1, '3577010101010003', 'Joko', 'RT 02 RW 01', 'keluarga miskin', 'pedagang kecil', '2026-10-02'),
(4, 1, '3577010101010004', 'Rina', 'RT 02 RW 02', 'keluarga miskin', 'tidak bekerja', '2026-10-02');

INSERT INTO verifikasi_lapangan
 (id_warga, id_petugas, tanggal_verifikasi, hasil_verifikasi, catatan) VALUES
(1, 1, '2026-10-03', 'layak', 'Rumah semi permanen'),
(2, 1, '2026-10-03', 'layak', 'Penyandang disabilitas'),
(3, 2, '2026-10-04', 'perlu_tinjau', 'Penghasilan perlu dicek ulang');

INSERT INTO pengajuan_bantuan
 (id_pengajuan, id_warga, jenis_bantuan, tanggal_pengajuan, status_pengajuan) VALUES
(1, 1, 'PKH',  '2026-10-05', 'diajukan'),
(2, 1, 'BPNT', '2026-10-06', 'diverifikasi'),
(3, 2, 'BLT',  '2026-10-06', 'diajukan'),
(4, 3, 'PKH',  '2026-10-07', 'disetujui'),
(5, 3, 'BPNT', '2026-10-07', 'diajukan'),
(6, 3, 'BLT',  '2026-10-08', 'diverifikasi'),
(7, 1, 'BLT',  '2026-10-20', 'diajukan'),
(8, 1, 'PKH',  '2026-10-21', 'diajukan');

-- Cek sinkronisasi (harus: Budi 4, Siti 1, Joko 3, Rina 0)
SELECT w.nama, COUNT(pb.id_pengajuan) AS hitung_join, w.jumlah_pengajuan AS tersimpan
FROM warga w
LEFT JOIN pengajuan_bantuan pb ON pb.id_warga = w.id_warga
GROUP BY w.id_warga, w.nama, w.jumlah_pengajuan;

-- ---- Memeriksa relasi tabel ----
SHOW TABLES;
SHOW CREATE TABLE petugas;
SHOW CREATE TABLE warga;
SHOW CREATE TABLE verifikasi_lapangan;
SHOW CREATE TABLE pengajuan_bantuan;

-- =====================================================================
-- TAHAP 3: OPERASI CRUD
-- =====================================================================
USE tepatsasar_modul10;

-- CREATE
INSERT INTO warga
 (id_petugas, nik, nama, alamat, kategori_kerentanan, kondisi_ekonomi, tanggal_dicatat)
VALUES
 (1, '3577010101010005', 'Darto', 'RT 03 RW 01', 'lansia', 'tidak bekerja', '2026-11-06');

-- READ
SELECT id_warga, nik, nama, alamat FROM warga;

-- UPDATE
UPDATE warga SET alamat = 'RT 03 RW 02' WHERE nik = '3577010101010005';

-- DELETE (Darto belum punya pengajuan/verifikasi, jadi boleh dihapus)
DELETE FROM warga WHERE nik = '3577010101010005';

-- ---- Uji integritas referensial dan constraint ----
-- SETIAP QUERY DI BAWAH DIHARAPKAN GAGAL KARENA CONSTRAINT DATABASE. 
-- Dikomentari agar file ini dapat dijalankan sekaligus tanpa terhenti.
-- Hapus tanda "-- " pada salah satu query untuk mendemonstrasikan penolakan DBMS.

-- (a) FK: warga tidak ada                       -> Error #1452
-- INSERT INTO pengajuan_bantuan (id_warga, jenis_bantuan, tanggal_pengajuan) VALUES (999, 'PKH', '2026-11-06');

-- (b) ON DELETE RESTRICT: induk masih dipakai   -> Error #1451
-- DELETE FROM warga WHERE id_warga = 1;

-- =====================================================================
-- TAHAP 4: PENGUJIAN TRANSAKSI
-- =====================================================================
-- ---- COMMIT: verifikasi + pengajuan Rina disimpan bersama ----
START TRANSACTION;
INSERT INTO verifikasi_lapangan (id_warga, id_petugas, tanggal_verifikasi, hasil_verifikasi, catatan)
VALUES (4, 1, '2026-11-06', 'layak', 'Survei rumah Rina');
INSERT INTO pengajuan_bantuan (id_warga, jenis_bantuan, tanggal_pengajuan, status_pengajuan)
VALUES (4, 'PKH', '2026-11-06', 'diajukan');
COMMIT;

-- ---- ROLLBACK: pengajuan Siti dibatalkan ----
START TRANSACTION;
INSERT INTO pengajuan_bantuan (id_warga, jenis_bantuan, tanggal_pengajuan, status_pengajuan)
VALUES (2, 'BPNT', '2026-11-07', 'diajukan');
ROLLBACK;

-- =====================================================================
-- TAHAP 5: ANALISIS PERFORMA
-- =====================================================================
USE tepatsasar_modul10;

-- MENGHASILKAN DATA DUMMY (DATA TESTING) DALAM JUMLAH BANYAK UNTUK PENGUJIAN EXPLAIN
-- Menggunakan Stored Procedure agar tidak bergantung pada file SQL lain.
DELIMITER $$
CREATE PROCEDURE GenerateDummyData()
BEGIN
    DECLARE i INT DEFAULT 1;
    WHILE i <= 2000 DO
        INSERT INTO pengajuan_bantuan (id_warga, jenis_bantuan, tanggal_pengajuan, status_pengajuan)
        VALUES (
            (i % 4) + 1, 
            IF(i % 2 = 0, 'PKH', 'BLT'), 
            DATE_ADD('2026-01-01', INTERVAL (i % 365) DAY), 
            IF(i % 3 = 0, 'disetujui', 'diajukan')
        );
        SET i = i + 1;
    END WHILE;
END$$
DELIMITER ;

CALL GenerateDummyData();
-- Selesai membuat data dummy.

-- ---- EXPLAIN SEBELUM index (jalankan sebelum CREATE INDEX di bawah) ----
EXPLAIN SELECT COUNT(*) FROM pengajuan_bantuan
WHERE tanggal_pengajuan >= '2026-10-01' AND tanggal_pengajuan < '2026-10-08';

-- ---- Membuat index ----
CREATE INDEX idx_pengajuan_tanggal        ON pengajuan_bantuan (tanggal_pengajuan);
CREATE INDEX idx_warga_nama               ON warga (nama);
CREATE INDEX idx_pengajuan_status_tanggal ON pengajuan_bantuan (status_pengajuan, tanggal_pengajuan);
CREATE INDEX idx_pengajuan_jenis_status   ON pengajuan_bantuan (jenis_bantuan, status_pengajuan);

ANALYZE TABLE warga, pengajuan_bantuan;

-- ---- EXPLAIN SESUDAH index (query persis sama dengan sebelumnya) ----
EXPLAIN SELECT COUNT(*) FROM pengajuan_bantuan
WHERE tanggal_pengajuan >= '2026-10-01' AND tanggal_pengajuan < '2026-10-08';

-- ---- BAGIAN B: backup kecil dipulihkan ke database terpisah ----
DROP DATABASE IF EXISTS tepatsasar_restore;
CREATE DATABASE tepatsasar_restore CHARACTER SET utf8mb4 COLLATE utf8mb4_general_ci;
USE tepatsasar_restore;

-- ======================================================================================================================================
-- VERSI KECIL dari backup tepatsasar_modul10 (data dikurangi dari 708 ribu baris menjadi 29 baris, termasuk 10 baris tabel bantu angka).
-- Struktur, indeks, foreign key, dan trigger tetap lengkap.
-- phpMyAdmin SQL Dump
-- version 5.2.3
-- https://www.phpmyadmin.net/
--
-- Host: localhost:3306
-- Generation Time: Nov 08, 2026 at 11:02 AM
-- Server version: 8.4.3
-- PHP Version: 8.3.33
-- =======================================================================================================================================
SET SQL_MODE = "NO_AUTO_VALUE_ON_ZERO";
START TRANSACTION;
SET time_zone = "+00:00";


/*!40101 SET @OLD_CHARACTER_SET_CLIENT=@@CHARACTER_SET_CLIENT */;
/*!40101 SET @OLD_CHARACTER_SET_RESULTS=@@CHARACTER_SET_RESULTS */;
/*!40101 SET @OLD_COLLATION_CONNECTION=@@COLLATION_CONNECTION */;
/*!40101 SET NAMES utf8mb4 */;

--
-- Database: `tepatsasar_modul10`
--

-- --------------------------------------------------------

--
-- Table structure for table `angka`
--

CREATE TABLE `angka` (
  `n` tinyint UNSIGNED NOT NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_general_ci;

--
-- Dumping data for table `angka`
--

INSERT INTO `angka` (`n`) VALUES
(0),
(1),
(2),
(3),
(4),
(5),
(6),
(7),
(8),
(9);

-- --------------------------------------------------------

--
-- Table structure for table `pengajuan_bantuan`
--

CREATE TABLE `pengajuan_bantuan` (
  `id_pengajuan` int UNSIGNED NOT NULL,
  `id_warga` int UNSIGNED NOT NULL,
  `jenis_bantuan` varchar(50) NOT NULL,
  `tanggal_pengajuan` date NOT NULL,
  `status_pengajuan` enum('diajukan','diverifikasi','disetujui','ditolak') NOT NULL DEFAULT 'diajukan'
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_0900_ai_ci;

--
-- Dumping data for table `pengajuan_bantuan`
--

INSERT INTO `pengajuan_bantuan` (`id_pengajuan`, `id_warga`, `jenis_bantuan`, `tanggal_pengajuan`, `status_pengajuan`) VALUES
(1, 1, 'PKH', '2026-10-05', 'diajukan'),
(2, 1, 'BPNT', '2026-10-06', 'diverifikasi'),
(3, 2, 'BLT', '2026-10-06', 'diajukan'),
(4, 3, 'PKH', '2026-10-07', 'disetujui'),
(5, 3, 'BPNT', '2026-10-07', 'diajukan'),
(6, 3, 'BLT', '2026-10-08', 'diverifikasi'),
(7, 1, 'BLT', '2026-10-20', 'diajukan'),
(8, 1, 'PKH', '2026-10-21', 'diajukan'),
(10, 4, 'PKH', '2026-11-06', 'diajukan');

--
-- Triggers `pengajuan_bantuan`
--
DELIMITER $$
CREATE TRIGGER `trg_pengajuan_after_delete` AFTER DELETE ON `pengajuan_bantuan` FOR EACH ROW UPDATE warga SET jumlah_pengajuan = jumlah_pengajuan - 1 WHERE id_warga = OLD.id_warga
$$
DELIMITER ;
DELIMITER $$
CREATE TRIGGER `trg_pengajuan_after_insert` AFTER INSERT ON `pengajuan_bantuan` FOR EACH ROW UPDATE warga SET jumlah_pengajuan = jumlah_pengajuan + 1 WHERE id_warga = NEW.id_warga
$$
DELIMITER ;

-- --------------------------------------------------------

--
-- Table structure for table `petugas`
--

CREATE TABLE `petugas` (
  `id_petugas` int UNSIGNED NOT NULL,
  `nama` varchar(100) NOT NULL,
  `username` varchar(50) NOT NULL,
  `password` varchar(255) NOT NULL,
  `peran` enum('kader_rt','staf_kelurahan') NOT NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_0900_ai_ci;

--
-- Dumping data for table `petugas`
--

INSERT INTO `petugas` (`id_petugas`, `nama`, `username`, `password`, `peran`) VALUES
(1, 'Kader Contoh', 'kader1', 'hash_contoh', 'kader_rt'),
(2, 'Staf Kelurahan Contoh', 'staf1', 'hash_contoh', 'staf_kelurahan');

-- --------------------------------------------------------

--
-- Table structure for table `verifikasi_lapangan`
--

CREATE TABLE `verifikasi_lapangan` (
  `id_verifikasi` int UNSIGNED NOT NULL,
  `id_warga` int UNSIGNED NOT NULL,
  `id_petugas` int UNSIGNED NOT NULL,
  `tanggal_verifikasi` date NOT NULL,
  `hasil_verifikasi` enum('layak','tidak_layak','perlu_tinjau') NOT NULL,
  `catatan` varchar(255) DEFAULT NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_0900_ai_ci;

--
-- Dumping data for table `verifikasi_lapangan`
--

INSERT INTO `verifikasi_lapangan` (`id_verifikasi`, `id_warga`, `id_petugas`, `tanggal_verifikasi`, `hasil_verifikasi`, `catatan`) VALUES
(1, 1, 1, '2026-10-03', 'layak', 'Rumah semi permanen'),
(2, 2, 1, '2026-10-03', 'layak', 'Penyandang disabilitas'),
(3, 3, 2, '2026-10-04', 'perlu_tinjau', 'Penghasilan perlu dicek ulang'),
(4, 4, 1, '2026-11-06', 'layak', 'Survei rumah Rina');

-- --------------------------------------------------------

--
-- Table structure for table `warga`
--

CREATE TABLE `warga` (
  `id_warga` int UNSIGNED NOT NULL,
  `id_petugas` int UNSIGNED NOT NULL,
  `nik` char(16) NOT NULL,
  `nama` varchar(100) NOT NULL,
  `alamat` varchar(255) NOT NULL,
  `kategori_kerentanan` varchar(50) DEFAULT NULL,
  `kondisi_ekonomi` varchar(100) DEFAULT NULL,
  `tanggal_dicatat` date NOT NULL,
  `jumlah_pengajuan` int UNSIGNED NOT NULL DEFAULT '0'
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_0900_ai_ci;

--
-- Dumping data for table `warga`
--

INSERT INTO `warga` (`id_warga`, `id_petugas`, `nik`, `nama`, `alamat`, `kategori_kerentanan`, `kondisi_ekonomi`, `tanggal_dicatat`, `jumlah_pengajuan`) VALUES
(1, 1, '3577010101010001', 'Budi', 'RT 01 RW 01', 'lansia', 'tidak berpenghasilan tetap', '2026-10-01', 4),
(2, 1, '3577010101010002', 'Siti', 'RT 01 RW 02', 'disabilitas', 'buruh harian', '2026-10-01', 1),
(3, 1, '3577010101010003', 'Joko', 'RT 02 RW 01', 'keluarga miskin', 'pedagang kecil', '2026-10-02', 3),
(4, 1, '3577010101010004', 'Rina', 'RT 02 RW 02', 'keluarga miskin', 'tidak bekerja', '2026-10-02', 1);

--
-- Indexes for dumped tables
--

--
-- Indexes for table `angka`
--
ALTER TABLE `angka`
  ADD PRIMARY KEY (`n`);

--
-- Indexes for table `pengajuan_bantuan`
--
ALTER TABLE `pengajuan_bantuan`
  ADD PRIMARY KEY (`id_pengajuan`),
  ADD KEY `idx_pengajuan_warga` (`id_warga`),
  ADD KEY `idx_pengajuan_tanggal` (`tanggal_pengajuan`),
  ADD KEY `idx_pengajuan_status_tanggal` (`status_pengajuan`,`tanggal_pengajuan`),
  ADD KEY `idx_pengajuan_jenis_status` (`jenis_bantuan`,`status_pengajuan`);

--
-- Indexes for table `petugas`
--
ALTER TABLE `petugas`
  ADD PRIMARY KEY (`id_petugas`),
  ADD UNIQUE KEY `uk_petugas_username` (`username`);

--
-- Indexes for table `verifikasi_lapangan`
--
ALTER TABLE `verifikasi_lapangan`
  ADD PRIMARY KEY (`id_verifikasi`),
  ADD KEY `idx_verif_warga` (`id_warga`),
  ADD KEY `idx_verif_petugas` (`id_petugas`);

--
-- Indexes for table `warga`
--
ALTER TABLE `warga`
  ADD PRIMARY KEY (`id_warga`),
  ADD UNIQUE KEY `uk_warga_nik` (`nik`),
  ADD KEY `idx_warga_petugas` (`id_petugas`),
  ADD KEY `idx_warga_nama` (`nama`);

--
-- AUTO_INCREMENT for dumped tables
--

--
-- AUTO_INCREMENT for table `pengajuan_bantuan`
--
ALTER TABLE `pengajuan_bantuan`
  MODIFY `id_pengajuan` int UNSIGNED NOT NULL AUTO_INCREMENT, AUTO_INCREMENT=11;

--
-- AUTO_INCREMENT for table `petugas`
--
ALTER TABLE `petugas`
  MODIFY `id_petugas` int UNSIGNED NOT NULL AUTO_INCREMENT, AUTO_INCREMENT=3;

--
-- AUTO_INCREMENT for table `verifikasi_lapangan`
--
ALTER TABLE `verifikasi_lapangan`
  MODIFY `id_verifikasi` int UNSIGNED NOT NULL AUTO_INCREMENT, AUTO_INCREMENT=5;

--
-- AUTO_INCREMENT for table `warga`
--
ALTER TABLE `warga`
  MODIFY `id_warga` int UNSIGNED NOT NULL AUTO_INCREMENT, AUTO_INCREMENT=5;

--
-- Constraints for dumped tables
--

--
-- Constraints for table `pengajuan_bantuan`
--
ALTER TABLE `pengajuan_bantuan`
  ADD CONSTRAINT `fk_pengajuan_warga` FOREIGN KEY (`id_warga`) REFERENCES `warga` (`id_warga`) ON DELETE RESTRICT ON UPDATE CASCADE;

--
-- Constraints for table `verifikasi_lapangan`
--
ALTER TABLE `verifikasi_lapangan`
  ADD CONSTRAINT `fk_verif_petugas` FOREIGN KEY (`id_petugas`) REFERENCES `petugas` (`id_petugas`) ON DELETE RESTRICT ON UPDATE CASCADE,
  ADD CONSTRAINT `fk_verif_warga` FOREIGN KEY (`id_warga`) REFERENCES `warga` (`id_warga`) ON DELETE RESTRICT ON UPDATE CASCADE;

--
-- Constraints for table `warga`
--
ALTER TABLE `warga`
  ADD CONSTRAINT `fk_warga_petugas` FOREIGN KEY (`id_petugas`) REFERENCES `petugas` (`id_petugas`) ON DELETE RESTRICT ON UPDATE CASCADE;
COMMIT;

/*!40101 SET CHARACTER_SET_CLIENT=@OLD_CHARACTER_SET_CLIENT */;
/*!40101 SET CHARACTER_SET_RESULTS=@OLD_CHARACTER_SET_RESULTS */;
/*!40101 SET COLLATION_CONNECTION=@OLD_COLLATION_CONNECTION */;



-- ===========================================================================================================================================
-- PEMBUKTIAN HASIL RESTORE
-- Bagian ini hanya SELECT (dan satu pengujian trigger yang di-ROLLBACK), sehingga tidak mengubah data. Berlaku untuk database mana pun tempat
-- file ini diimpor (memakai DATABASE(), tanpa nama database tetap).
-- ===========================================================================================================================================


-- 1. Jumlah baris tiap tabel
-- Hasil yang benar: petugas 2, warga 4, pengajuan_bantuan 9, verifikasi_lapangan 4
SELECT 'petugas' AS tabel, COUNT(*) AS jumlah FROM `petugas`
UNION ALL SELECT 'warga', COUNT(*) FROM `warga`
UNION ALL SELECT 'pengajuan_bantuan', COUNT(*) FROM `pengajuan_bantuan`
UNION ALL SELECT 'verifikasi_lapangan', COUNT(*) FROM `verifikasi_lapangan`;

-- 2. Trigger terpulihkan
-- Hasil yang benar: 2 baris (trg_pengajuan_after_delete, trg_pengajuan_after_insert)
SELECT TRIGGER_NAME, EVENT_MANIPULATION AS event, EVENT_OBJECT_TABLE AS tabel, ACTION_TIMING AS timing
FROM information_schema.TRIGGERS
WHERE TRIGGER_SCHEMA = DATABASE();

-- 3. Indeks terpulihkan (jumlah indeks per tabel)
-- Hasil yang benar: angka 1, pengajuan_bantuan 5, petugas 2, verifikasi_lapangan 3, warga 4
SELECT TABLE_NAME AS tabel, COUNT(DISTINCT INDEX_NAME) AS jumlah_indeks
FROM information_schema.STATISTICS
WHERE TABLE_SCHEMA = DATABASE()
GROUP BY TABLE_NAME;

-- 4. Foreign key terpulihkan
-- Hasil yang benar: 4 baris (fk_pengajuan_warga, fk_verif_petugas, fk_verif_warga, fk_warga_petugas)
SELECT CONSTRAINT_NAME, TABLE_NAME AS tabel_anak, REFERENCED_TABLE_NAME AS tabel_induk
FROM information_schema.REFERENTIAL_CONSTRAINTS
WHERE CONSTRAINT_SCHEMA = DATABASE();

-- 5. Tidak ada data yatim (setiap relasi punya induknya)
-- Hasil yang benar: keempat nilai = 0
SELECT 'pengajuan tanpa warga' AS pemeriksaan, COUNT(*) AS jumlah
FROM `pengajuan_bantuan` p LEFT JOIN `warga` w ON w.id_warga = p.id_warga WHERE w.id_warga IS NULL
UNION ALL
SELECT 'verifikasi tanpa warga', COUNT(*)
FROM `verifikasi_lapangan` v LEFT JOIN `warga` w ON w.id_warga = v.id_warga WHERE w.id_warga IS NULL
UNION ALL
SELECT 'verifikasi tanpa petugas', COUNT(*)
FROM `verifikasi_lapangan` v LEFT JOIN `petugas` t ON t.id_petugas = v.id_petugas WHERE t.id_petugas IS NULL
UNION ALL
SELECT 'warga tanpa petugas', COUNT(*)
FROM `warga` w LEFT JOIN `petugas` t ON t.id_petugas = w.id_petugas WHERE t.id_petugas IS NULL;

-- 6. Kolom warga.jumlah_pengajuan (diisi trigger) cocok dengan jumlah pengajuan sebenarnya
-- Hasil yang benar: warga_tidak_sinkron = 0, total_jumlah_pengajuan = 9
SELECT
  (SELECT COUNT(*) FROM `warga` w
   WHERE w.jumlah_pengajuan <> (SELECT COUNT(*) FROM `pengajuan_bantuan` p WHERE p.id_warga = w.id_warga)) AS warga_tidak_sinkron,
  (SELECT SUM(jumlah_pengajuan) FROM `warga`) AS total_jumlah_pengajuan;

-- 7. Pengujian trigger (dibatalkan dengan ROLLBACK, data tidak berubah)
-- Hasil yang benar: awal 4, sesudah_insert 5, sesudah_delete 4
START TRANSACTION;
SET @awal = (SELECT jumlah_pengajuan FROM `warga` WHERE id_warga = 1);
INSERT INTO `pengajuan_bantuan` (`id_warga`, `jenis_bantuan`, `tanggal_pengajuan`, `status_pengajuan`)
VALUES (1, 'PKH', CURDATE(), 'diajukan');
SET @sesudah_insert = (SELECT jumlah_pengajuan FROM `warga` WHERE id_warga = 1);
DELETE FROM `pengajuan_bantuan` WHERE id_pengajuan = LAST_INSERT_ID();
SET @sesudah_delete = (SELECT jumlah_pengajuan FROM `warga` WHERE id_warga = 1);
ROLLBACK;
SELECT @awal AS awal, @sesudah_insert AS sesudah_insert, @sesudah_delete AS sesudah_delete;
