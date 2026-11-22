// =====================================================================
// 03_pengujian_dcl.js
// Pengujian DCL (RBAC) pada MongoDB, database transport_db
//
// Padanan perintah DCL relasional pada MongoDB:
//   CREATE USER / GRANT  -> db.createUser(...) dan db.grantRolesToUser(...)
//   inspeksi hak         -> db.getUser(...) dan connectionStatus
//   REVOKE               -> db.revokeRolesFromUser(...)
//
// CATATAN PENGGUNAAN
// Berkas ini adalah kumpulan perintah bertahap, bukan skrip yang dijalankan sekaligus
// dengan --file. Pengujian membutuhkan pergantian akun dan permintaan password
// (passwordPrompt()), sehingga setiap bagian ditempel manual di mongosh.
// Password tidak pernah ditulis di berkas ini.
// =====================================================================


// ---------------------------------------------------------------------
// 1. Akun administrator (dikerjakan saat autentikasi masih mati)
// ---------------------------------------------------------------------
//   mongosh
//   use admin
//   db.createUser({ user: 'admin_ta', pwd: passwordPrompt(), roles: [{ role: 'root', db: 'admin' }] })
//   // hasil: { ok: 1 }


// ---------------------------------------------------------------------
// 2. Aktifkan autentikasi
// ---------------------------------------------------------------------
//   Edit C:\Program Files\MongoDB\Server\9.0\bin\mongod.cfg (Notepad sebagai Administrator),
//   lalu ubah menjadi (indentasi 2 spasi, bukan Tab):
//
//     security:
//       authorization: enabled
//
//   Restart layanan (PowerShell sebagai Administrator):
//     Restart-Service MongoDB


// ---------------------------------------------------------------------
// 3. Uji tanpa login (harus ditolak)
// ---------------------------------------------------------------------
//   mongosh
//   use transport_db
//   db.trips.find()
//   // hasil: MongoServerError[Unauthorized]: Command find requires authentication


// ---------------------------------------------------------------------
// 4. Login sebagai admin, lalu CREATE USER dan GRANT role
// ---------------------------------------------------------------------
//   mongosh 'mongodb://127.0.0.1:27017/admin' -u admin_ta -p --authenticationDatabase admin
//
//   use transport_db
//   db.createUser({ user: 'report_user',   pwd: passwordPrompt(), roles: [{ role: 'read',      db: 'transport_db' }] })
//   db.createUser({ user: 'operator_user', pwd: passwordPrompt(), roles: [{ role: 'readWrite', db: 'transport_db' }] })
//   // hasil: { ok: 1 } untuk masing-masing akun


// ---------------------------------------------------------------------
// 5. Inspeksi hak
// ---------------------------------------------------------------------
//   db.getUser('report_user')     // roles: [ { role: 'read', db: 'transport_db' } ]
//   db.getUser('operator_user')   // roles: [ { role: 'readWrite', db: 'transport_db' } ]


// ---------------------------------------------------------------------
// 6. Uji akun report_user (jendela PowerShell baru)
// ---------------------------------------------------------------------
//   mongosh 'mongodb://127.0.0.1:27017/transport_db' -u report_user -p --authenticationDatabase transport_db
//
//   db.trips.find({ route_id: 12 })        // diizinkan: menampilkan T001, T003, T005
//   db.trips.deleteOne({ trip_id: 'T006' })   // ditolak: MongoServerError[Unauthorized]: not authorized on transport_db to execute command { delete: "trips", ... }
//   db.trips.insertOne({ trip_id: 'T999', route_id: 12, started_at: '2026-11-10 08:00', status: 'completed' })
//                                          // ditolak: not authorized on transport_db to execute command { insert: "trips", ... }
//   db.runCommand({ connectionStatus: 1 }).authInfo
//                                          // authenticatedUserRoles: [ { role: 'read', db: 'transport_db' } ]


// ---------------------------------------------------------------------
// 7. REVOKE (di jendela admin)
// ---------------------------------------------------------------------
//   use transport_db
//   db.revokeRolesFromUser('report_user', [{ role: 'read', db: 'transport_db' }])
//   // hasil: { ok: 1 }
//   db.getUser('report_user')     // roles: []


// ---------------------------------------------------------------------
// 8. Uji setelah REVOKE (sesi report_user yang baru)
// ---------------------------------------------------------------------
//   db.trips.find({ route_id: 12 })
//   // ditolak: not authorized on transport_db to execute command { find: "trips", ... }


// ---------------------------------------------------------------------
// 9. (Opsional) Kembalikan hak
// ---------------------------------------------------------------------
//   db.grantRolesToUser('report_user', [{ role: 'read', db: 'transport_db' }])
//   // hasil: { ok: 1 }
