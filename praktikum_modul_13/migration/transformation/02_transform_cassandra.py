import json

print("=== TAHAP 2: TRANSFORMATION & DENORMALIZATION ===")
with open("migration/raw_mysql.json", "r", encoding="utf-8") as f:
    raw = json.load(f)

warga_lookup = {}
warga_by_rt = []
for w in raw["warga"]:
    id_w = w["id_warga"]
    rt_val = w["id_rt"] if w["id_rt"] is not None else 0
    warga_lookup[id_w] = (w["nik"], w["nama"], w["kategori_kerentanan"])
    warga_by_rt.append([
        rt_val, id_w, w["id_petugas"], w["nik"], w["nama"], w["alamat"],
        w["kategori_kerentanan"], w["kondisi_ekonomi"], w["tanggal_dicatat"], w["jumlah_pengajuan"]
    ])

pengajuan_by_warga = []
for p in raw["pengajuan_bantuan"]:
    nik, nama, kat = warga_lookup.get(p["id_warga"], ("", "", ""))
    pengajuan_by_warga.append([
        p["id_warga"], p["tanggal_pengajuan"], p["id_pengajuan"],
        nik, nama, kat, p["jenis_bantuan"], p["status_pengajuan"]
    ])

verifikasi_by_warga = []
for v in raw["verifikasi_lapangan"]:
    verifikasi_by_warga.append([
        v["id_warga"], v["tanggal_verifikasi"], v["id_verifikasi"],
        v["id_petugas"], v["hasil_verifikasi"], v["catatan"]
    ])

hasil_transform = {
    "warga_by_rt": warga_by_rt,
    "pengajuan_by_warga": pengajuan_by_warga,
    "verifikasi_by_warga": verifikasi_by_warga
}

with open("migration/transformed_cassandra.json", "w", encoding="utf-8") as f:
    json.dump(hasil_transform, f)

print(f"[OK] warga_by_rt siap: {len(warga_by_rt)} baris")
print(f"[OK] pengajuan_by_warga siap (denormalisasi): {len(pengajuan_by_warga)} baris")
print(f"[OK] verifikasi_by_warga siap: {len(verifikasi_by_warga)} baris")