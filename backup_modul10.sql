-- phpMyAdmin SQL Dump
-- version 5.2.3
-- https://www.phpmyadmin.net/
--
-- Host: localhost:3306
-- Generation Time: Nov 08, 2026 at 11:12 AM
-- Server version: 8.4.3
-- PHP Version: 8.3.33

SET SQL_MODE = "NO_AUTO_VALUE_ON_ZERO";
START TRANSACTION;
SET time_zone = "+00:00";


/*!40101 SET @OLD_CHARACTER_SET_CLIENT=@@CHARACTER_SET_CLIENT */;
/*!40101 SET @OLD_CHARACTER_SET_RESULTS=@@CHARACTER_SET_RESULTS */;
/*!40101 SET @OLD_COLLATION_CONNECTION=@@COLLATION_CONNECTION */;
/*!40101 SET NAMES utf8mb4 */;

--
-- Database: `tepatsasar_restore`
--

-- --------------------------------------------------------

--
-- Table structure for table `pengajuan_bantuan`
--

DROP TABLE IF EXISTS `pengajuan_bantuan`;
CREATE TABLE `pengajuan_bantuan` (
  `id_pengajuan` int UNSIGNED NOT NULL,
  `id_warga` int UNSIGNED NOT NULL,
  `jenis_bantuan` varchar(50) NOT NULL,
  `tanggal_pengajuan` date NOT NULL,
  `status_pengajuan` enum('diajukan','diverifikasi','disetujui','ditolak') NOT NULL DEFAULT 'diajukan'
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_0900_ai_ci;

--
-- Dumping data for table `pengajuan_bantuan`
--

INSERT INTO `pengajuan_bantuan` (`id_pengajuan`, `id_warga`, `jenis_bantuan`, `tanggal_pengajuan`, `status_pengajuan`) VALUES
(1, 1, 'PKH', '2026-10-05', 'diajukan'),
(2, 1, 'BPNT', '2026-10-06', 'diverifikasi'),
(3, 2, 'BLT', '2026-10-06', 'diajukan'),
(4, 3, 'PKH', '2026-10-07', 'disetujui'),
(5, 3, 'BPNT', '2026-10-07', 'diajukan'),
(6, 3, 'BLT', '2026-10-08', 'diverifikasi'),
(7, 1, 'BLT', '2026-10-20', 'diajukan'),
(8, 1, 'PKH', '2026-10-21', 'diajukan'),
(10, 4, 'PKH', '2026-11-06', 'diajukan');

--
-- Triggers `pengajuan_bantuan`
--
DROP TRIGGER IF EXISTS `trg_pengajuan_after_delete`;
DELIMITER $$
CREATE TRIGGER `trg_pengajuan_after_delete` AFTER DELETE ON `pengajuan_bantuan` FOR EACH ROW UPDATE warga SET jumlah_pengajuan = jumlah_pengajuan - 1 WHERE id_warga = OLD.id_warga
$$
DELIMITER ;
DROP TRIGGER IF EXISTS `trg_pengajuan_after_insert`;
DELIMITER $$
CREATE TRIGGER `trg_pengajuan_after_insert` AFTER INSERT ON `pengajuan_bantuan` FOR EACH ROW UPDATE warga SET jumlah_pengajuan = jumlah_pengajuan + 1 WHERE id_warga = NEW.id_warga
$$
DELIMITER ;

-- --------------------------------------------------------

--
-- Table structure for table `petugas`
--

DROP TABLE IF EXISTS `petugas`;
CREATE TABLE `petugas` (
  `id_petugas` int UNSIGNED NOT NULL,
  `nama` varchar(100) NOT NULL,
  `username` varchar(50) NOT NULL,
  `password` varchar(255) NOT NULL,
  `peran` enum('kader_rt','staf_kelurahan') NOT NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_0900_ai_ci;

--
-- Dumping data for table `petugas`
--

INSERT INTO `petugas` (`id_petugas`, `nama`, `username`, `password`, `peran`) VALUES
(1, 'Kader Contoh', 'kader1', 'hash_contoh', 'kader_rt'),
(2, 'Staf Kelurahan Contoh', 'staf1', 'hash_contoh', 'staf_kelurahan');

-- --------------------------------------------------------

--
-- Table structure for table `verifikasi_lapangan`
--

DROP TABLE IF EXISTS `verifikasi_lapangan`;
CREATE TABLE `verifikasi_lapangan` (
  `id_verifikasi` int UNSIGNED NOT NULL,
  `id_warga` int UNSIGNED NOT NULL,
  `id_petugas` int UNSIGNED NOT NULL,
  `tanggal_verifikasi` date NOT NULL,
  `hasil_verifikasi` enum('layak','tidak_layak','perlu_tinjau') NOT NULL,
  `catatan` varchar(255) DEFAULT NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_0900_ai_ci;

--
-- Dumping data for table `verifikasi_lapangan`
--

INSERT INTO `verifikasi_lapangan` (`id_verifikasi`, `id_warga`, `id_petugas`, `tanggal_verifikasi`, `hasil_verifikasi`, `catatan`) VALUES
(1, 1, 1, '2026-10-03', 'layak', 'Rumah semi permanen'),
(2, 2, 1, '2026-10-03', 'layak', 'Penyandang disabilitas'),
(3, 3, 2, '2026-10-04', 'perlu_tinjau', 'Penghasilan perlu dicek ulang'),
(4, 4, 1, '2026-11-06', 'layak', 'Survei rumah Rina');

-- --------------------------------------------------------

--
-- Table structure for table `warga`
--

DROP TABLE IF EXISTS `warga`;
CREATE TABLE `warga` (
  `id_warga` int UNSIGNED NOT NULL,
  `id_petugas` int UNSIGNED NOT NULL,
  `nik` char(16) NOT NULL,
  `nama` varchar(100) NOT NULL,
  `alamat` varchar(255) NOT NULL,
  `kategori_kerentanan` varchar(50) DEFAULT NULL,
  `kondisi_ekonomi` varchar(100) DEFAULT NULL,
  `tanggal_dicatat` date NOT NULL,
  `jumlah_pengajuan` int UNSIGNED NOT NULL DEFAULT '0'
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_0900_ai_ci;

--
-- Dumping data for table `warga`
--

INSERT INTO `warga` (`id_warga`, `id_petugas`, `nik`, `nama`, `alamat`, `kategori_kerentanan`, `kondisi_ekonomi`, `tanggal_dicatat`, `jumlah_pengajuan`) VALUES
(1, 1, '3577010101010001', 'Budi', 'RT 01 RW 01', 'lansia', 'tidak berpenghasilan tetap', '2026-10-01', 4),
(2, 1, '3577010101010002', 'Siti', 'RT 01 RW 02', 'disabilitas', 'buruh harian', '2026-10-01', 1),
(3, 1, '3577010101010003', 'Joko', 'RT 02 RW 01', 'keluarga miskin', 'pedagang kecil', '2026-10-02', 3),
(4, 1, '3577010101010004', 'Rina', 'RT 02 RW 02', 'keluarga miskin', 'tidak bekerja', '2026-10-02', 1);

--
-- Indexes for dumped tables
--

--
-- Indexes for table `pengajuan_bantuan`
--
ALTER TABLE `pengajuan_bantuan`
  ADD PRIMARY KEY (`id_pengajuan`),
  ADD KEY `idx_pengajuan_warga` (`id_warga`),
  ADD KEY `idx_tanggal_pengajuan` (`tanggal_pengajuan`);

--
-- Indexes for table `petugas`
--
ALTER TABLE `petugas`
  ADD PRIMARY KEY (`id_petugas`),
  ADD UNIQUE KEY `uk_petugas_username` (`username`);

--
-- Indexes for table `verifikasi_lapangan`
--
ALTER TABLE `verifikasi_lapangan`
  ADD PRIMARY KEY (`id_verifikasi`),
  ADD KEY `idx_verif_warga` (`id_warga`),
  ADD KEY `idx_verif_petugas` (`id_petugas`);

--
-- Indexes for table `warga`
--
ALTER TABLE `warga`
  ADD PRIMARY KEY (`id_warga`),
  ADD UNIQUE KEY `uk_warga_nik` (`nik`),
  ADD KEY `idx_warga_petugas` (`id_petugas`);

--
-- AUTO_INCREMENT for dumped tables
--

--
-- AUTO_INCREMENT for table `pengajuan_bantuan`
--
ALTER TABLE `pengajuan_bantuan`
  MODIFY `id_pengajuan` int UNSIGNED NOT NULL AUTO_INCREMENT, AUTO_INCREMENT=12;

--
-- AUTO_INCREMENT for table `petugas`
--
ALTER TABLE `petugas`
  MODIFY `id_petugas` int UNSIGNED NOT NULL AUTO_INCREMENT, AUTO_INCREMENT=3;

--
-- AUTO_INCREMENT for table `verifikasi_lapangan`
--
ALTER TABLE `verifikasi_lapangan`
  MODIFY `id_verifikasi` int UNSIGNED NOT NULL AUTO_INCREMENT, AUTO_INCREMENT=5;

--
-- AUTO_INCREMENT for table `warga`
--
ALTER TABLE `warga`
  MODIFY `id_warga` int UNSIGNED NOT NULL AUTO_INCREMENT, AUTO_INCREMENT=7;

--
-- Constraints for dumped tables
--

--
-- Constraints for table `pengajuan_bantuan`
--
ALTER TABLE `pengajuan_bantuan`
  ADD CONSTRAINT `fk_pengajuan_warga` FOREIGN KEY (`id_warga`) REFERENCES `warga` (`id_warga`) ON DELETE RESTRICT ON UPDATE CASCADE;

--
-- Constraints for table `verifikasi_lapangan`
--
ALTER TABLE `verifikasi_lapangan`
  ADD CONSTRAINT `fk_verif_petugas` FOREIGN KEY (`id_petugas`) REFERENCES `petugas` (`id_petugas`) ON DELETE RESTRICT ON UPDATE CASCADE,
  ADD CONSTRAINT `fk_verif_warga` FOREIGN KEY (`id_warga`) REFERENCES `warga` (`id_warga`) ON DELETE RESTRICT ON UPDATE CASCADE;

--
-- Constraints for table `warga`
--
ALTER TABLE `warga`
  ADD CONSTRAINT `fk_warga_petugas` FOREIGN KEY (`id_petugas`) REFERENCES `petugas` (`id_petugas`) ON DELETE RESTRICT ON UPDATE CASCADE;
COMMIT;

/*!40101 SET CHARACTER_SET_CLIENT=@OLD_CHARACTER_SET_CLIENT */;
/*!40101 SET CHARACTER_SET_RESULTS=@OLD_CHARACTER_SET_RESULTS */;
/*!40101 SET COLLATION_CONNECTION=@OLD_COLLATION_CONNECTION */;
