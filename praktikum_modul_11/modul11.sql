-- =====================================================
-- Praktikum Modul 11 - Perkembangan DBMS dan Lingkup
-- Penerapan Basis Data
-- Studi kasus : TepatSasar
-- DBMS        : MySQL 8 / MariaDB (InnoDB)
-- =====================================================

-- Database dibuat manual lewat phpMyAdmin (B2), lalu dipilih:
-- CREATE DATABASE tepatsasar_modul11 CHARACTER SET utf8mb4 COLLATE utf8mb4_general_ci;
USE tepatsasar_modul11;

-- =====================================================
-- B1. Identifikasi DBMS
-- =====================================================
SELECT VERSION();
SELECT @@version_comment;
SHOW DATABASES;
SHOW ENGINES;
SHOW VARIABLES LIKE 'default_storage_engine';
SHOW VARIABLES LIKE 'character_set_server';
SHOW VARIABLES LIKE 'collation_server';
SELECT JSON_VALID('{"nama":"Budi"}') AS json_valid,
       JSON_EXTRACT('{"nama":"Budi"}', '$.nama') AS nama;

-- =====================================================
-- B3. Tambah kolom JSON dan isi datanya
-- =====================================================
ALTER TABLE warga ADD COLUMN detail_kondisi JSON NULL AFTER kondisi_ekonomi;

UPDATE warga SET detail_kondisi = '{"tinggal_sendiri":true,"kondisi_kesehatan":"sakit menahun","jenis_lantai":"tanah","sumber_air":"sumur"}' WHERE nik = '3577010101010001';
UPDATE warga SET detail_kondisi = '{"jenis_disabilitas":"tuna daksa","alat_bantu":"kursi roda","jumlah_tanggungan":3,"bantuan_sebelumnya":["PKH","BPNT"]}' WHERE nik = '3577010101010002';
UPDATE warga SET detail_kondisi = '{"jumlah_balita":2,"jumlah_tanggungan":5,"penghasilan_per_bulan":1200000,"daya_listrik":"450 VA"}' WHERE nik = '3577010101010003';
UPDATE warga SET detail_kondisi = '{"jumlah_balita":0,"jumlah_tanggungan":4,"penghasilan_per_bulan":0,"daya_listrik":"900 VA","jenis_lantai":"semen"}' WHERE nik = '3577010101010004';

SELECT id_warga, nama, kategori_kerentanan, detail_kondisi FROM warga;
SHOW CREATE TABLE warga;

-- =====================================================
-- B4. Manipulasi data JSON
-- =====================================================

-- B4a. Baca atribut
SELECT nama, kategori_kerentanan, JSON_EXTRACT(detail_kondisi, '$.jumlah_tanggungan') AS tanggungan FROM warga;
SELECT nama, JSON_UNQUOTE(JSON_EXTRACT(detail_kondisi, '$.daya_listrik')) AS daya_listrik FROM warga;

-- B4b. Ubah atribut (tanggungan Joko jadi 6)
UPDATE warga SET detail_kondisi = JSON_SET(detail_kondisi, '$.jumlah_tanggungan', 6) WHERE nik = '3577010101010003';
SELECT nama, JSON_EXTRACT(detail_kondisi, '$.jumlah_tanggungan') AS tanggungan FROM warga WHERE nik = '3577010101010003';

-- B4c. Tambah atribut baru
UPDATE warga SET detail_kondisi = JSON_SET(detail_kondisi, '$.status_rumah', 'Menumpang') WHERE nik = '3577010101010001';
SELECT nama, detail_kondisi FROM warga WHERE nik = '3577010101010001';

-- B4d. Hapus atribut
UPDATE warga SET detail_kondisi = JSON_REMOVE(detail_kondisi, '$.status_rumah') WHERE nik = '3577010101010001';
SELECT nama, detail_kondisi FROM warga WHERE nik = '3577010101010001';

-- B4e. Cari berdasarkan atribut JSON
SELECT nama, kategori_kerentanan FROM warga WHERE JSON_UNQUOTE(JSON_EXTRACT(detail_kondisi, '$.sumber_air')) = 'sumur';
SELECT nama, kategori_kerentanan FROM warga WHERE CAST(JSON_UNQUOTE(JSON_EXTRACT(detail_kondisi, '$.jumlah_tanggungan')) AS UNSIGNED) >= 5;
SELECT nama FROM warga WHERE JSON_CONTAINS(JSON_EXTRACT(detail_kondisi, '$.bantuan_sebelumnya'), '"PKH"');

-- =====================================================
-- B5. INSERT dan DELETE
-- =====================================================

-- B5a. Tambah warga baru dengan JSON
INSERT INTO warga (id_petugas, nik, nama, alamat, kategori_kerentanan, kondisi_ekonomi, detail_kondisi, tanggal_dicatat)
VALUES (1, '3577010101010005', 'Darto', 'RT 03 RW 01', 'lansia', 'tidak bekerja', '{"tinggal_sendiri":false,"kondisi_kesehatan":"stroke"}', '2026-11-12');
SELECT nama, detail_kondisi FROM warga WHERE nik = '3577010101010005';

-- B5b. Hapus warga tadi
DELETE FROM warga WHERE nik = '3577010101010005';
SELECT id_warga, nama FROM warga;

-- =====================================================
-- B6. Uji validasi (ketiganya HARUS ERROR)
-- Dikomentari supaya import script tidak berhenti.
-- Hapus tanda -- lalu jalankan satu per satu di tab SQL.
-- =====================================================

-- B6a. JSON tidak valid
-- INSERT INTO warga (id_petugas, nik, nama, alamat, tanggal_dicatat, detail_kondisi)
-- VALUES (1, '3577010101010099', 'Uji JSON', 'RT 01 RW 01', '2026-11-12', '{lantai:keramik}');

-- B6b. NIK ganda (error #1062)
-- INSERT INTO warga (id_petugas, nik, nama, alamat, tanggal_dicatat, detail_kondisi)
-- VALUES (1, '3577010101010001', 'NIK Ganda', 'RT 01 RW 01', '2026-11-12', '{}');

-- B6c. Hapus warga yang masih punya pengajuan (error #1451, ON DELETE RESTRICT)
-- DELETE FROM warga WHERE id_warga = 1;

-- =====================================================
-- B7. Transaksi
-- =====================================================

-- B7a. ROLLBACK (hasil: tanggungan 6, jumlah_pengajuan 3)
START TRANSACTION;
UPDATE warga SET detail_kondisi = JSON_SET(detail_kondisi, '$.jumlah_tanggungan', 7) WHERE id_warga = 3;
INSERT INTO pengajuan_bantuan (id_warga, jenis_bantuan, tanggal_pengajuan, status_pengajuan) VALUES (3, 'PKH', '2026-11-12', 'diajukan');
ROLLBACK;
SELECT nama, JSON_EXTRACT(detail_kondisi, '$.jumlah_tanggungan') AS tanggungan, jumlah_pengajuan FROM warga WHERE id_warga = 3;

-- B7b. COMMIT (hasil: tanggungan 7, jumlah_pengajuan 4)
START TRANSACTION;
UPDATE warga SET detail_kondisi = JSON_SET(detail_kondisi, '$.jumlah_tanggungan', 7) WHERE id_warga = 3;
INSERT INTO pengajuan_bantuan (id_warga, jenis_bantuan, tanggal_pengajuan, status_pengajuan) VALUES (3, 'PKH', '2026-11-12', 'diajukan');
COMMIT;
SELECT nama, JSON_EXTRACT(detail_kondisi, '$.jumlah_tanggungan') AS tanggungan, jumlah_pengajuan FROM warga WHERE id_warga = 3;

-- =====================================================
-- B8. Pemodelan objek
-- =====================================================

-- B8a. Objek Warga per jenis
SELECT id_warga, nama, kategori_kerentanan, detail_kondisi FROM warga WHERE kategori_kerentanan = 'lansia';
SELECT id_warga, nama, kategori_kerentanan, detail_kondisi FROM warga WHERE kategori_kerentanan = 'disabilitas';
SELECT id_warga, nama, kategori_kerentanan, detail_kondisi FROM warga WHERE kategori_kerentanan = 'keluarga miskin';

-- B8b. Gabungan data relasional dan JSON
SELECT w.id_warga, w.nama, w.kategori_kerentanan, p.nama AS petugas_pencatat, pb.jenis_bantuan, pb.status_pengajuan,
       JSON_EXTRACT(w.detail_kondisi, '$.jumlah_tanggungan') AS tanggungan
FROM warga w
JOIN petugas p ON w.id_petugas = p.id_petugas
LEFT JOIN pengajuan_bantuan pb ON pb.id_warga = w.id_warga;

SELECT w.nama, v.hasil_verifikasi, v.tanggal_verifikasi, w.jumlah_pengajuan
FROM warga w JOIN verifikasi_lapangan v ON v.id_warga = w.id_warga
WHERE v.hasil_verifikasi = 'layak';

-- B8c. Method objek sebagai stored function
DROP FUNCTION IF EXISTS cek_nik_ganda;

DELIMITER $$
CREATE FUNCTION cek_nik_ganda(p_nik CHAR(16))
RETURNS TINYINT(1) READS SQL DATA
BEGIN
  RETURN EXISTS (SELECT 1 FROM warga WHERE nik = p_nik);
END$$
DELIMITER ;

-- Hasil benar: nik_sudah_ada = 1, nik_belum_ada = 0
SELECT cek_nik_ganda('3577010101010001') AS nik_sudah_ada,
       cek_nik_ganda('3577010101019999') AS nik_belum_ada;

-- =====================================================
-- B9. Bukti engine InnoDB
-- =====================================================

-- Modul 11: Implementasi PostgreSQL (JSONB)
-- Database: praktikum_modul11 (jalankan di DBeaver, pastikan toolbar public@praktikum_modul11)
-- Script ini aman dijalankan berulang (bagian atas menghapus objek lama).

-- 1. Bersihkan objek lama
DROP TABLE IF EXISTS pengajuan_bantuan, verifikasi_lapangan, warga, petugas CASCADE;
DROP TYPE IF EXISTS peran_petugas, hasil_verif, status_aju;
DROP FUNCTION IF EXISTS sinkron_jumlah_pengajuan() CASCADE;

-- 2. Tipe ENUM
CREATE TYPE peran_petugas AS ENUM ('kader_rt', 'staf_kelurahan');
CREATE TYPE hasil_verif AS ENUM ('layak', 'tidak_layak', 'perlu_tinjau');
CREATE TYPE status_aju AS ENUM ('diajukan', 'diverifikasi', 'disetujui', 'ditolak');

-- 3. Tabel (kolom detail_kondisi bertipe JSONB)
CREATE TABLE petugas (
  id_petugas SERIAL PRIMARY KEY,
  nama VARCHAR(100) NOT NULL,
  username VARCHAR(50) NOT NULL UNIQUE,
  password VARCHAR(255) NOT NULL,
  peran peran_petugas NOT NULL
);
CREATE TABLE warga (
  id_warga SERIAL PRIMARY KEY,
  id_petugas INT NOT NULL REFERENCES petugas(id_petugas) ON UPDATE CASCADE ON DELETE RESTRICT,
  nik CHAR(16) NOT NULL UNIQUE,
  nama VARCHAR(100) NOT NULL,
  alamat VARCHAR(255) NOT NULL,
  kategori_kerentanan VARCHAR(50),
  kondisi_ekonomi VARCHAR(100),
  detail_kondisi JSONB,
  tanggal_dicatat DATE NOT NULL,
  jumlah_pengajuan INT NOT NULL DEFAULT 0
);
CREATE TABLE verifikasi_lapangan (
  id_verifikasi SERIAL PRIMARY KEY,
  id_warga INT NOT NULL REFERENCES warga(id_warga) ON UPDATE CASCADE ON DELETE RESTRICT,
  id_petugas INT NOT NULL REFERENCES petugas(id_petugas) ON UPDATE CASCADE ON DELETE RESTRICT,
  tanggal_verifikasi DATE NOT NULL,
  hasil_verifikasi hasil_verif NOT NULL,
  catatan VARCHAR(255)
);
CREATE TABLE pengajuan_bantuan (
  id_pengajuan SERIAL PRIMARY KEY,
  id_warga INT NOT NULL REFERENCES warga(id_warga) ON UPDATE CASCADE ON DELETE RESTRICT,
  jenis_bantuan VARCHAR(50) NOT NULL,
  tanggal_pengajuan DATE NOT NULL,
  status_pengajuan status_aju NOT NULL DEFAULT 'diajukan'
);

-- 4. Function dan trigger (sinkronisasi jumlah_pengajuan)
CREATE OR REPLACE FUNCTION sinkron_jumlah_pengajuan() RETURNS trigger AS $$
BEGIN
  IF TG_OP = 'INSERT' THEN
    UPDATE warga SET jumlah_pengajuan = jumlah_pengajuan + 1 WHERE id_warga = NEW.id_warga;
  ELSE
    UPDATE warga SET jumlah_pengajuan = jumlah_pengajuan - 1 WHERE id_warga = OLD.id_warga;
  END IF;
  RETURN NULL;
END;
$$ LANGUAGE plpgsql;
CREATE TRIGGER trg_pengajuan_sinkron AFTER INSERT OR DELETE ON pengajuan_bantuan FOR EACH ROW EXECUTE FUNCTION sinkron_jumlah_pengajuan();

-- 5. Data contoh
INSERT INTO petugas (nama, username, password, peran) VALUES
('Kader Contoh', 'kader1', 'hash_contoh', 'kader_rt'),
('Staf Kelurahan Contoh', 'staf1', 'hash_contoh', 'staf_kelurahan');
INSERT INTO warga (id_petugas, nik, nama, alamat, kategori_kerentanan, kondisi_ekonomi, detail_kondisi, tanggal_dicatat) VALUES
(1, '3577010101010001', 'Budi', 'RT 01 RW 01', 'lansia', 'tidak berpenghasilan tetap',
 '{"tinggal_sendiri":true,"kondisi_kesehatan":"sakit menahun","jenis_lantai":"tanah","sumber_air":"sumur"}', '2026-10-01'),
(1, '3577010101010002', 'Siti', 'RT 01 RW 02', 'disabilitas', 'buruh harian',
 '{"jenis_disabilitas":"tuna daksa","alat_bantu":"kursi roda","jumlah_tanggungan":3,"bantuan_sebelumnya":["PKH","BPNT"]}', '2026-10-01'),
(1, '3577010101010003', 'Joko', 'RT 02 RW 01', 'keluarga miskin', 'pedagang kecil',
 '{"jumlah_balita":2,"jumlah_tanggungan":5,"penghasilan_per_bulan":1200000,"daya_listrik":"450 VA"}', '2026-10-02'),
(1, '3577010101010004', 'Rina', 'RT 02 RW 02', 'keluarga miskin', 'tidak bekerja',
 '{"jumlah_balita":0,"jumlah_tanggungan":4,"penghasilan_per_bulan":0,"daya_listrik":"900 VA","jenis_lantai":"semen"}', '2026-10-02');
INSERT INTO verifikasi_lapangan (id_warga, id_petugas, tanggal_verifikasi, hasil_verifikasi, catatan) VALUES
(1, 1, '2026-10-03', 'layak', 'Rumah semi permanen'),
(2, 1, '2026-10-03', 'layak', 'Penyandang disabilitas'),
(3, 2, '2026-10-04', 'perlu_tinjau', 'Penghasilan perlu dicek ulang'),
(4, 1, '2026-11-06', 'layak', 'Survei rumah Rina');
INSERT INTO pengajuan_bantuan (id_warga, jenis_bantuan, tanggal_pengajuan, status_pengajuan) VALUES
(1, 'PKH', '2026-10-05', 'diajukan'),
(1, 'BPNT', '2026-10-06', 'diverifikasi'),
(2, 'BLT', '2026-10-06', 'diajukan'),
(3, 'PKH', '2026-10-07', 'disetujui'),
(3, 'BPNT', '2026-10-07', 'diajukan'),
(3, 'BLT', '2026-10-08', 'diverifikasi'),
(1, 'BLT', '2026-10-20', 'diajukan'),
(1, 'PKH', '2026-10-21', 'diajukan'),
(4, 'PKH', '2026-11-06', 'diajukan');

-- 6. SELECT: baca atribut JSONB (-> hasil JSON, ->> hasil teks)
SELECT nama, detail_kondisi->'jumlah_tanggungan' AS tanggungan_json, detail_kondisi->>'daya_listrik' AS daya_listrik FROM warga;

-- 7. UPDATE: ubah atribut (tanggungan Joko jadi 6)
UPDATE warga SET detail_kondisi = jsonb_set(detail_kondisi, '{jumlah_tanggungan}', '6') WHERE nik = '3577010101010003';

-- 8. UPDATE: tambah atribut baru
UPDATE warga SET detail_kondisi = jsonb_set(detail_kondisi, '{status_rumah}', '"Menumpang"') WHERE nik = '3577010101010001';

-- 9. DELETE atribut JSONB
UPDATE warga SET detail_kondisi = detail_kondisi - 'status_rumah' WHERE nik = '3577010101010001';

-- 10. SELECT: cari berdasarkan atribut JSONB
SELECT nama, kategori_kerentanan FROM warga WHERE detail_kondisi->>'sumber_air' = 'sumur';
SELECT nama FROM warga WHERE (detail_kondisi->>'jumlah_tanggungan')::int >= 5;
SELECT nama FROM warga WHERE detail_kondisi @> '{"alat_bantu":"kursi roda"}';
SELECT nama FROM warga WHERE jsonb_exists(detail_kondisi->'bantuan_sebelumnya', 'PKH');

-- 11. Indeks khusus JSONB
CREATE INDEX IF NOT EXISTS idx_warga_detail ON warga USING GIN (detail_kondisi);

-- 12. Hasil akhir trigger (Budi 4, Siti 1, Joko 3, Rina 1)
SELECT nama, jumlah_pengajuan FROM warga ORDER BY id_warga;

-- 13. Uji validasi (harus ERROR). Jalankan satu per satu, jangan ikut Alt+X:
-- INSERT INTO warga (id_petugas, nik, nama, alamat, tanggal_dicatat, detail_kondisi) VALUES (1, '3577010101010099', 'Uji JSON', 'RT 01 RW 01', '2026-11-12', '{lantai:keramik}');
-- INSERT INTO warga (id_petugas, nik, nama, alamat, tanggal_dicatat, detail_kondisi) VALUES (1, '3577010101010001', 'NIK Ganda', 'RT 01 RW 01', '2026-11-12', '{}');
-- DELETE FROM warga WHERE id_warga = 1;
SELECT TABLE_NAME, ENGINE
FROM information_schema.TABLES
WHERE TABLE_SCHEMA = 'tepatsasar_modul11';
