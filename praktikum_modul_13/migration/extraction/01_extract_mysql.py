import json
import mysql.connector

print("=== TAHAP 1: EXTRACTION DARI MYSQL ===")
conn = mysql.connector.connect(
    host="localhost", user="root", password="", database="tepatsasar_modul10"
)
cursor = conn.cursor(dictionary=True)

data_ekstrak = {}
for tabel in ["warga", "pengajuan_bantuan", "verifikasi_lapangan"]:
    cursor.execute(f"SELECT * FROM {tabel}")
    rows = cursor.fetchall()
    for r in rows:
        for k, v in r.items():
            if hasattr(v, "isoformat"):
                r[k] = v.isoformat()
    data_ekstrak[tabel] = rows
    print(f"[OK] Berhasil ekstrak '{tabel}': {len(rows)} baris")

with open("migration/raw_mysql.json", "w", encoding="utf-8") as f:
    json.dump(data_ekstrak, f)

cursor.close()
conn.close()
print("File hasil ekstraksi tersimpan di migration/raw_mysql.json")