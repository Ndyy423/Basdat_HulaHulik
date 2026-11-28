-- 1. CREATE: Tambah data pengajuan baru
INSERT INTO tepatsasar_cassandra.pengajuan_by_warga (id_warga, tanggal_pengajuan, id_pengajuan, nik, nama_warga, kategori_kerentanan, jenis_bantuan, status_pengajuan)
VALUES (1, '2026-11-28', 999001, '3577010101010001', 'Budi', 'lansia', 'BLT', 'diajukan');

-- 2. READ: Cek data yang baru ditambahkan
SELECT id_warga, nama_warga, tanggal_pengajuan, id_pengajuan, jenis_bantuan, status_pengajuan
FROM tepatsasar_cassandra.pengajuan_by_warga
WHERE id_warga = 1 AND tanggal_pengajuan = '2026-11-28' AND id_pengajuan = 999001;

-- 3. UPDATE: Ubah status pengajuan menjadi disetujui
UPDATE tepatsasar_cassandra.pengajuan_by_warga
SET status_pengajuan = 'disetujui'
WHERE id_warga = 1 AND tanggal_pengajuan = '2026-11-28' AND id_pengajuan = 999001;

-- 4. DELETE: Hapus data uji coba
DELETE FROM tepatsasar_cassandra.pengajuan_by_warga
WHERE id_warga = 1 AND tanggal_pengajuan = '2026-11-28' AND id_pengajuan = 999001;