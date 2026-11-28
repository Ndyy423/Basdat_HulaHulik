db = db.getSiblingDB('tepatsasar_modul12');

const D = (s) => new Date(s + 'T00:00:00Z');

['petugas', 'warga', 'verifikasi_lapangan', 'pengajuan_bantuan'].forEach((n) => db.getCollection(n).drop());

db.createCollection('petugas', { validator: { $jsonSchema: {
  bsonType: 'object',
  required: ['id_petugas', 'nama', 'username', 'password_hash', 'peran'],
  properties: {
    id_petugas:    { bsonType: 'number' },
    nama:          { bsonType: 'string', maxLength: 100 },
    username:      { bsonType: 'string', maxLength: 50 },
    password_hash: { bsonType: 'string', maxLength: 255 },
    peran:         { enum: ['kader_rt', 'staf_kelurahan'] }
  } } } });

db.createCollection('warga', { validator: { $jsonSchema: {
  bsonType: 'object',
  required: ['id_warga', 'id_petugas', 'nik', 'nama', 'alamat', 'tanggal_dicatat', 'jumlah_pengajuan'],
  properties: {
    id_warga:            { bsonType: 'number' },
    id_petugas:          { bsonType: 'number' },
    nik:                 { bsonType: 'string', pattern: '^[0-9]{16}$' },
    nama:                { bsonType: 'string', maxLength: 100 },
    alamat:              { bsonType: 'string', maxLength: 255 },
    kategori_kerentanan: { bsonType: ['string', 'null'], maxLength: 50 },
    kondisi_ekonomi:     { bsonType: ['string', 'null'], maxLength: 100 },
    tanggal_dicatat:     { bsonType: 'date' },
    jumlah_pengajuan:    { bsonType: 'number', minimum: 0 }
  } } } });

db.createCollection('verifikasi_lapangan', { validator: { $jsonSchema: {
  bsonType: 'object',
  required: ['id_verifikasi', 'id_warga', 'id_petugas', 'tanggal_verifikasi', 'hasil_verifikasi'],
  properties: {
    id_verifikasi:      { bsonType: 'number' },
    id_warga:           { bsonType: 'number' },
    id_petugas:         { bsonType: 'number' },
    tanggal_verifikasi: { bsonType: 'date' },
    hasil_verifikasi:   { enum: ['layak', 'tidak_layak', 'perlu_tinjau'] },
    catatan:            { bsonType: ['string', 'null'], maxLength: 255 }
  } } } });

db.createCollection('pengajuan_bantuan', { validator: { $jsonSchema: {
  bsonType: 'object',
  required: ['id_pengajuan', 'id_warga', 'jenis_bantuan', 'tanggal_pengajuan', 'status_pengajuan'],
  properties: {
    id_pengajuan:      { bsonType: 'number' },
    id_warga:          { bsonType: 'number' },
    jenis_bantuan:     { bsonType: 'string', maxLength: 50 },
    tanggal_pengajuan: { bsonType: 'date' },
    status_pengajuan:  { enum: ['diajukan', 'diverifikasi', 'disetujui', 'ditolak'] }
  } } } });

db.petugas.createIndex({ id_petugas: 1 }, { unique: true, name: 'pk_petugas' });
db.petugas.createIndex({ username: 1 },   { unique: true, name: 'uk_petugas_username' });

db.warga.createIndex({ id_warga: 1 },   { unique: true, name: 'pk_warga' });
db.warga.createIndex({ nik: 1 },        { unique: true, name: 'uk_warga_nik' });
db.warga.createIndex({ id_petugas: 1 }, { name: 'idx_warga_petugas' });

db.verifikasi_lapangan.createIndex({ id_verifikasi: 1 }, { unique: true, name: 'pk_verifikasi_lapangan' });
db.verifikasi_lapangan.createIndex({ id_warga: 1 },      { name: 'idx_verif_warga' });
db.verifikasi_lapangan.createIndex({ id_petugas: 1 },    { name: 'idx_verif_petugas' });

db.pengajuan_bantuan.createIndex({ id_pengajuan: 1 }, { unique: true, name: 'pk_pengajuan_bantuan' });
db.pengajuan_bantuan.createIndex({ id_warga: 1 },     { name: 'idx_pengajuan_warga' });

printjson(db.petugas.insertMany([
  { id_petugas: 1, nama: 'Kader Contoh',          username: 'kader1',
    password_hash: '301d393f0dd2009a21bda0352166d522a46fd9a2e9597ec2fa3d05cb3836610b', peran: 'kader_rt' },
  { id_petugas: 2, nama: 'Staf Kelurahan Contoh', username: 'staf1',
    password_hash: 'd55ed37faf535e9b24d7baa04173735b9565d3421d4fb672b18f2730e27fc5c8', peran: 'staf_kelurahan' }
]));

printjson(db.warga.insertMany([
  { id_warga: 1, id_petugas: 1, nik: '3577010101010001', nama: 'Budi', alamat: 'RT 01 RW 01',
    kategori_kerentanan: 'lansia', kondisi_ekonomi: 'tidak berpenghasilan tetap',
    tanggal_dicatat: D('2026-10-01'), jumlah_pengajuan: 4 },
  { id_warga: 2, id_petugas: 1, nik: '3577010101010002', nama: 'Siti', alamat: 'RT 01 RW 02',
    kategori_kerentanan: 'disabilitas', kondisi_ekonomi: 'buruh harian',
    tanggal_dicatat: D('2026-10-01'), jumlah_pengajuan: 1 },
  { id_warga: 3, id_petugas: 1, nik: '3577010101010003', nama: 'Joko', alamat: 'RT 02 RW 01',
    kategori_kerentanan: 'keluarga miskin', kondisi_ekonomi: 'pedagang kecil',
    tanggal_dicatat: D('2026-10-02'), jumlah_pengajuan: 3 },
  { id_warga: 4, id_petugas: 1, nik: '3577010101010004', nama: 'Rina', alamat: 'RT 02 RW 02',
    kategori_kerentanan: 'keluarga miskin', kondisi_ekonomi: 'tidak bekerja',
    tanggal_dicatat: D('2026-10-02'), jumlah_pengajuan: 1 }
]));

printjson(db.verifikasi_lapangan.insertMany([
  { id_verifikasi: 1, id_warga: 1, id_petugas: 1, tanggal_verifikasi: D('2026-10-03'), hasil_verifikasi: 'layak',        catatan: 'Rumah semi permanen' },
  { id_verifikasi: 2, id_warga: 2, id_petugas: 1, tanggal_verifikasi: D('2026-10-03'), hasil_verifikasi: 'layak',        catatan: 'Penyandang disabilitas' },
  { id_verifikasi: 3, id_warga: 3, id_petugas: 2, tanggal_verifikasi: D('2026-10-04'), hasil_verifikasi: 'perlu_tinjau', catatan: 'Penghasilan perlu dicek ulang' },
  { id_verifikasi: 4, id_warga: 4, id_petugas: 1, tanggal_verifikasi: D('2026-11-06'), hasil_verifikasi: 'layak',        catatan: 'Survei rumah Rina' }
]));

printjson(db.pengajuan_bantuan.insertMany([
  { id_pengajuan: 1,  id_warga: 1, jenis_bantuan: 'PKH',  tanggal_pengajuan: D('2026-10-05'), status_pengajuan: 'diajukan' },
  { id_pengajuan: 2,  id_warga: 1, jenis_bantuan: 'BPNT', tanggal_pengajuan: D('2026-10-06'), status_pengajuan: 'diverifikasi' },
  { id_pengajuan: 3,  id_warga: 2, jenis_bantuan: 'BLT',  tanggal_pengajuan: D('2026-10-06'), status_pengajuan: 'diajukan' },
  { id_pengajuan: 4,  id_warga: 3, jenis_bantuan: 'PKH',  tanggal_pengajuan: D('2026-10-07'), status_pengajuan: 'disetujui' },
  { id_pengajuan: 5,  id_warga: 3, jenis_bantuan: 'BPNT', tanggal_pengajuan: D('2026-10-07'), status_pengajuan: 'diajukan' },
  { id_pengajuan: 6,  id_warga: 3, jenis_bantuan: 'BLT',  tanggal_pengajuan: D('2026-10-08'), status_pengajuan: 'diverifikasi' },
  { id_pengajuan: 7,  id_warga: 1, jenis_bantuan: 'BLT',  tanggal_pengajuan: D('2026-10-20'), status_pengajuan: 'diajukan' },
  { id_pengajuan: 8,  id_warga: 1, jenis_bantuan: 'PKH',  tanggal_pengajuan: D('2026-10-21'), status_pengajuan: 'diajukan' },
  { id_pengajuan: 10, id_warga: 4, jenis_bantuan: 'PKH',  tanggal_pengajuan: D('2026-11-06'), status_pengajuan: 'diajukan' }
]));

print('\n=== 1. Jumlah dokumen tiap koleksi ===');
print('Jumlah dokumen petugas             : ' + db.petugas.countDocuments({}));
print('Jumlah dokumen warga               : ' + db.warga.countDocuments({}));
print('Jumlah dokumen pengajuan_bantuan   : ' + db.pengajuan_bantuan.countDocuments({}));
print('Jumlah dokumen verifikasi_lapangan : ' + db.verifikasi_lapangan.countDocuments({}));

print('\n=== 2. jumlah_pengajuan tersimpan ===');
printjson(db.warga.aggregate([
  { $lookup: { from: 'pengajuan_bantuan', localField: 'id_warga', foreignField: 'id_warga', as: 'p' } },
  { $project: { _id: 0, nama: 1, hitung_join: { $size: '$p' }, tersimpan: '$jumlah_pengajuan' } }
]).toArray());

print('\n=== 3. Data yatim ===');
const yatim = (koleksi, kolom, induk) => {
  const r = db.getCollection(koleksi).aggregate([
    { $lookup: { from: induk, localField: kolom, foreignField: kolom, as: 'induk' } },
    { $match: { induk: { $size: 0 } } },
    { $count: 'jumlah' }
  ]).toArray();
  return r.length ? r[0].jumlah : 0;
};
print('pengajuan tanpa warga    : ' + yatim('pengajuan_bantuan', 'id_warga', 'warga'));
print('verifikasi tanpa warga   : ' + yatim('verifikasi_lapangan', 'id_warga', 'warga'));
print('verifikasi tanpa petugas : ' + yatim('verifikasi_lapangan', 'id_petugas', 'petugas'));
print('warga tanpa petugas      : ' + yatim('warga', 'id_petugas', 'petugas'));
