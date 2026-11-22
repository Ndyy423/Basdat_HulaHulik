// =====================================================================
// 03_pengujian_dcl.js
// Pengujian DCL (RBAC) pada MongoDB, database transport_db
//
// Padanan perintah DCL relasional pada MongoDB:
//   CREATE USER / GRANT  -> createUser(...) dan grantRolesToUser(...)
//   inspeksi hak         -> getUser(...) dan connectionStatus
//   REVOKE               -> revokeRolesFromUser(...)
//
// Satu skrip ini menyesuaikan diri dengan akun yang sedang login:
//   - tanpa login   : menguji bahwa perintah baca ditolak (autentikasi aktif)
//   - admin_ta      : menjalankan tahap yang dipilih pada TAHAP di bawah
//   - report_user   : menguji operasi yang diizinkan dan yang ditolak
//
// Prasyarat: autentikasi sudah diaktifkan (mongod.cfg: security: authorization: enabled,
// lalu Restart-Service MongoDB) dan akun admin_ta sudah dibuat:
//   use admin
//   db.createUser({ user: 'admin_ta', pwd: passwordPrompt(), roles: [{ role: 'root', db: 'admin' }] })
//
// Urutan menjalankan (dari folder praktikum_modul12, password diminta saat dijalankan):
//   0. tanpa login   : mongosh 'mongodb://127.0.0.1:27017/transport_db' --file scripts/03_pengujian_dcl.js
//   1. TAHAP = 1     : mongosh 'mongodb://127.0.0.1:27017/admin' -u admin_ta -p --authenticationDatabase admin --file scripts/03_pengujian_dcl.js
//   2. uji akun      : mongosh 'mongodb://127.0.0.1:27017/transport_db' -u report_user -p --authenticationDatabase transport_db --file scripts/03_pengujian_dcl.js
//   3. TAHAP = 2     : ubah TAHAP di bawah menjadi 2, jalankan sebagai admin_ta seperti langkah 1 (REVOKE)
//   4. uji akun lagi : ulangi langkah 2 (semua perintah harus ditolak)
//   5. TAHAP = 3     : opsional, kembalikan hak
//
// Bila passwordPrompt() tidak berjalan saat memakai --file, tempel isi fungsi createUser
// langsung di sesi mongosh interaktif. Password tidak pernah ditulis di berkas ini.
// =====================================================================

const TAHAP = 1;   // 1: CREATE USER + GRANT, 2: REVOKE, 3: GRANT ulang

const NAMA_DB = 'transport_db';
const target = db.getSiblingDB(NAMA_DB);

const info = db.getSiblingDB('admin').runCommand({ connectionStatus: 1 }).authInfo;
const pengguna = info.authenticatedUsers.length ? info.authenticatedUsers[0].user : null;

const cetak = (judul, nilai) => { print('=== ' + judul + ' ==='); printjson(nilai); };
const coba = (label, fn) => {
  try { const hasil = fn(); print(label + ' -> BERHASIL'); return hasil; }
  catch (e) { print(label + ' -> DITOLAK: ' + e.message); return null; }
};

if (pengguna === null) {
  // ---------------------------------------------------------------
  // Tanpa login
  // ---------------------------------------------------------------
  print('Sesi tanpa login');
  const hasil = coba('find tanpa login', () => target.trips.find().toArray());
  if (hasil !== null) print('PERINGATAN: perintah tidak ditolak, autentikasi belum aktif.');

} else if (pengguna === 'admin_ta') {
  // ---------------------------------------------------------------
  // Administrator
  // ---------------------------------------------------------------
  print('Sesi admin_ta, TAHAP ' + TAHAP);

  if (TAHAP === 1) {
    // CREATE USER dan GRANT role (akun yang sudah ada dilewati)
    const buatAkun = (nama, role) => {
      if (target.getUser(nama)) { print('Akun ' + nama + ' sudah ada, dilewati'); return; }
      target.createUser({ user: nama, pwd: passwordPrompt(), roles: [{ role: role, db: NAMA_DB }] });
      print('Akun ' + nama + ' dibuat dengan role ' + role);
    };
    buatAkun('report_user', 'read');
    buatAkun('operator_user', 'readWrite');

    // Inspeksi hak
    cetak('getUser report_user (benar: role read)', target.getUser('report_user').roles);
    cetak('getUser operator_user (benar: role readWrite)', target.getUser('operator_user').roles);

  } else if (TAHAP === 2) {
    // REVOKE
    printjson(target.revokeRolesFromUser('report_user', [{ role: 'read', db: NAMA_DB }]));
    cetak('getUser report_user setelah REVOKE (benar: roles kosong)', target.getUser('report_user').roles);

  } else if (TAHAP === 3) {
    // GRANT ulang (opsional)
    printjson(target.grantRolesToUser('report_user', [{ role: 'read', db: NAMA_DB }]));
    cetak('getUser report_user setelah GRANT ulang (benar: role read)', target.getUser('report_user').roles);

  } else {
    print('TAHAP harus 1, 2, atau 3');
  }

} else if (pengguna === 'report_user') {
  // ---------------------------------------------------------------
  // Pengujian akun report_user
  // Sebelum REVOKE: find berhasil, delete dan insert ditolak.
  // Sesudah REVOKE: semuanya ditolak.
  // ---------------------------------------------------------------
  print('Sesi report_user');

  const trip = coba('find route 12', () => target.trips.find({ route_id: 12 }).toArray());
  if (trip !== null) cetak('trip_id yang tampil (benar: T001, T003, T005)', trip.map((t) => t.trip_id));

  coba('deleteOne T006', () => target.trips.deleteOne({ trip_id: 'T006' }));
  coba('insertOne T999', () => target.trips.insertOne({
    trip_id: 'T999', route_id: 12, started_at: '2026-11-10 08:00', status: 'completed'
  }));

  cetak('connectionStatus (benar sebelum REVOKE: role read pada transport_db)', info);

} else {
  print('Akun ' + pengguna + ' tidak dikenali oleh skrip ini. Gunakan tanpa login, admin_ta, atau report_user.');
}
