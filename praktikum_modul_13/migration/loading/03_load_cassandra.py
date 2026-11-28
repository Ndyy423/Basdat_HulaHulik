import json
import time
from cassandra.cluster import Cluster
from cassandra.concurrent import execute_concurrent_with_args

start = time.time()
print("=== TAHAP 3: LOADING KE APACHE CASSANDRA ===")

with open("migration/transformed_cassandra.json", "r", encoding="utf-8") as f:
    data = json.load(f)

cluster = Cluster(["127.0.0.1"], port=9042)
session = cluster.connect("tepatsasar_cassandra")

def kirim_batch(query, rows, nama_tabel):
    stmt = session.prepare(query)
    total = len(rows)
    for i in range(0, total, 2000):
        execute_concurrent_with_args(session, stmt, rows[i:i+2000], concurrency=50)
        if (i + 2000) % 50000 == 0 or (i + 2000) >= total:
            print(f"  -> {nama_tabel}: {min(i+2000, total)}/{total} baris terkirim")

kirim_batch(
    "INSERT INTO warga_by_rt (id_rt, id_warga, id_petugas, nik, nama, alamat, kategori_kerentanan, kondisi_ekonomi, tanggal_dicatat, jumlah_pengajuan) VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?)",
    data["warga_by_rt"], "warga_by_rt"
)
kirim_batch(
    "INSERT INTO pengajuan_by_warga (id_warga, tanggal_pengajuan, id_pengajuan, nik, nama_warga, kategori_kerentanan, jenis_bantuan, status_pengajuan) VALUES (?, ?, ?, ?, ?, ?, ?, ?)",
    data["pengajuan_by_warga"], "pengajuan_by_warga"
)
kirim_batch(
    "INSERT INTO verifikasi_by_warga (id_warga, tanggal_verifikasi, id_verifikasi, id_petugas, hasil_verifikasi, catatan) VALUES (?, ?, ?, ?, ?, ?)",
    data["verifikasi_by_warga"], "verifikasi_by_warga"
)

print(f"\n[SELESAI] Total 708.350 baris dimuat dalam {round(time.time() - start, 2)} detik.")
cluster.shutdown()