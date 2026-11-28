-- Workload 1: Daftar warga di wilayah RT 1 berdasarkan partition key id_rt
SELECT id_rt, id_warga, nik, nama, kategori_kerentanan, kondisi_ekonomi
FROM tepatsasar_cassandra.warga_by_rt
WHERE id_rt = 1 LIMIT 5;

-- Workload 2: Riwayat pengajuan bantuan beserta identitas warga tanpa JOIN
SELECT id_warga, nama_warga, nik, tanggal_pengajuan, id_pengajuan, jenis_bantuan, status_pengajuan
FROM tepatsasar_cassandra.pengajuan_by_warga
WHERE id_warga = 1 LIMIT 5;

-- Workload 3: Riwayat hasil verifikasi lapangan milik warga tertentu
SELECT id_warga, tanggal_verifikasi, id_verifikasi, id_petugas, hasil_verifikasi, catatan
FROM tepatsasar_cassandra.verifikasi_by_warga
WHERE id_warga = 1 LIMIT 5;