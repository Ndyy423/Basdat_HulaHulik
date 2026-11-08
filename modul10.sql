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
