import sys
from cassandra.cluster import Cluster

if len(sys.argv) < 2:
    print("Gunakan: python jalankan_cql.py <path_file.cql>")
    sys.exit(1)

file_cql = sys.argv[1]
with open(file_cql, "r", encoding="utf-8") as f:
    isi = f.read()

# Bersihkan komentar baris dan pisahkan per perintah titik koma (;)
baris_bersih = [b for b in isi.splitlines() if not b.strip().startswith("--")]
perintah_list = [p.strip() for p in "\n".join(baris_bersih).split(";") if p.strip()]

cluster = Cluster(["127.0.0.1"], port=9042)
session = cluster.connect()

print(f"=== Menjalankan {file_cql} ===")
for idx, query in enumerate(perintah_list, 1):
    print(f"\n[Query {idx}] {query};")
    hasil = session.execute(query)
    rows = list(hasil)
    if rows:
        for r in rows:
            print(" ->", dict(r._asdict()))
    else:
        print(" -> [OK] Eksekusi berhasil.")

cluster.shutdown()