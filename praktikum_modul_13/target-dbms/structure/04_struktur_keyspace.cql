CREATE KEYSPACE IF NOT EXISTS tepatsasar_cassandra
WITH replication = {'class': 'SimpleStrategy', 'replication_factor': 1};

CREATE TABLE IF NOT EXISTS tepatsasar_cassandra.warga_by_rt (
    id_rt int,
    id_warga int,
    id_petugas int,
    nik text,
    nama text,
    alamat text,
    kategori_kerentanan text,
    kondisi_ekonomi text,
    tanggal_dicatat date,
    jumlah_pengajuan int,
    PRIMARY KEY ((id_rt), id_warga)
);

CREATE TABLE IF NOT EXISTS tepatsasar_cassandra.pengajuan_by_warga (
    id_warga int,
    tanggal_pengajuan date,
    id_pengajuan int,
    nik text,
    nama_warga text,
    kategori_kerentanan text,
    jenis_bantuan text,
    status_pengajuan text,
    PRIMARY KEY ((id_warga), tanggal_pengajuan, id_pengajuan)
) WITH CLUSTERING ORDER BY (tanggal_pengajuan DESC, id_pengajuan DESC);

CREATE TABLE IF NOT EXISTS tepatsasar_cassandra.verifikasi_by_warga (
    id_warga int,
    tanggal_verifikasi date,
    id_verifikasi int,
    id_petugas int,
    hasil_verifikasi text,
    catatan text,
    PRIMARY KEY ((id_warga), tanggal_verifikasi, id_verifikasi)
) WITH CLUSTERING ORDER BY (tanggal_verifikasi DESC, id_verifikasi DESC);