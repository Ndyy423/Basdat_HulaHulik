import mysql.connector
from cassandra.cluster import Cluster

print("=== TAHAP 4: VALIDASI JUMLAH BARIS (MYSQL vs CASSANDRA) ===")
mysql_conn = mysql.connector.connect(
    host="localhost", user="root", password="", database="tepatsasar_modul10"
)
m_cur = mysql_conn.cursor()

cluster = Cluster(["127.0.0.1"], port=9042)
c_sess = cluster.connect("tepatsasar_cassandra")

pasangan_tabel = [
    ("warga", "warga_by_rt"),
    ("pengajuan_bantuan", "pengajuan_by_warga"),
    ("verifikasi_lapangan", "verifikasi_by_warga")
]

print(f"{'Tabel MySQL':<22} | {'Baris MySQL':<12} | {'Tabel Cassandra':<22} | {'Baris Cassandra':<15} | {'Status'}")
print("-" * 92)

for tbl_mysql, tbl_cass in pasangan_tabel:
    m_cur.execute(f"SELECT COUNT(*) FROM {tbl_mysql}")
    jml_mysql = m_cur.fetchone()[0]

    jml_cass = c_sess.execute(f"SELECT COUNT(*) FROM {tbl_cass}").one()[0]
    status = "VALID (COCOK)" if jml_mysql == jml_cass else "TIDAK COCOK"
    print(f"{tbl_mysql:<22} | {jml_mysql:<12} | {tbl_cass:<22} | {jml_cass:<15} | {status}")

m_cur.close()
mysql_conn.close()
cluster.shutdown()