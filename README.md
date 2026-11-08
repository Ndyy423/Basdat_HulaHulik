

|Komponen|Keterangan|Rujukan|
|-|-|-|
|Petugas|Kader RT atau staf kelurahan. Hanya petugas berakun yang boleh mengoperasikan sistem.|Batasan, KNF-08|
|Keyboard, mouse, monitor|Perangkat petugas untuk memasukkan data dan membaca tampilan.|3.1|
|Komputer petugas|Menjalankan semua komponen perangkat lunak. Memakai Windows 10/11 atau Ubuntu 22.04 dengan RAM minimal 4 GB, dan UPS menjaga data saat listrik padam.|2.4, KNF-02, KNF-04, KNF-05|
|Browser|Antarmuka yang dipakai petugas, yaitu Chrome atau Firefox.|2.4|
|Aplikasi TepatSasar|Aplikasi web lokal yang memproses semua permintaan petugas tanpa internet.|KNF-01|
|Login petugas|Memeriksa akun sebelum modul apa pun bisa dibuka.|KF-01, KNF-08|
|Modul Pendataan warga|Mencatat dan memperbarui data warga prasejahtera, termasuk memeriksa NIK ganda.|KF-02, 03, 06|
|Modul Verifikasi lapangan|Menyimpan hasil survei petugas ke rumah warga, lengkap dengan tanggal dan catatan.|KF-04|
|Modul Pengajuan dan usulan|Mencatat pengajuan bantuan dan usulan warga, lalu melacak statusnya.|KF-05, 07|
|Modul Pelaporan|Menyusun daftar penerima dan laporan rekapitulasi.|KF-08, 09|
|DBMS lokal|Menyimpan enam tabel: petugas, warga, verifikasi lapangan, pengajuan bantuan, usulan pengaduan, dan riwayat perubahan. Memakai MySQL 8, MariaDB, atau SQLite.|ERD, 2.4|
|Printer|Mencetak daftar penerima dan laporan rekapitulasi.|3.1|
|Hard disk eksternal|Tempat salinan backup database setiap minggu.|KNF-02|
|Dinas Sosial|Pihak di luar sistem yang menerima laporan cetak. Perannya diasumsikan, karena SKPL belum menjelaskan cara Dinsos menerima data.|Diagram Konteks|



