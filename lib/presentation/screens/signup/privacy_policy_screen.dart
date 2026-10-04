import 'package:arunika_app/core/legal/legal_versions.dart';
import 'package:flutter/material.dart';

/// Kept in step with the landing site page and, for what the parent agrees
/// to, with `LegalVersions`. Change the text => bump the version there and in
/// the backend's `CurrentConsentVersions` so users are asked again.
const _sections = <({String title, String content})>[
  (
    title: '1. Pengendali Data Pribadi',
    content:
        'Arunika ("kami") adalah pengendali data pribadi untuk aplikasi Arunika, sesuai Undang-Undang No. 27 Tahun 2022 tentang Pelindungan Data Pribadi (UU PDP).\n'
        'Kontak pelindungan data pribadi: arunika.helpdesk@gmail.com',
  ),
  (
    title: '2. Data yang Kami Kumpulkan',
    content:
        'Data orang tua/wali:\n'
        '• Nama, nomor telepon, alamat email, kota, dan alamat lengkap\n'
        '• Kata sandi (disimpan dalam bentuk terenkripsi, tidak dapat kami baca)\n'
        '\n'
        'Data anak (dengan persetujuan orang tua/wali):\n'
        '• Nama, tanggal lahir, dan jenis kelamin\n'
        '\n'
        'Data penggunaan:\n'
        '• Kemajuan belajar, riwayat dongeng, lencana, dan poin bintang\n'
        '\n'
        'Data perangkat dan teknis:\n'
        '• Jenis perangkat, versi sistem dan aplikasi, token notifikasi, dan laporan kerusakan aplikasi\n'
        '\n'
        'Data pembelian:\n'
        '• Riwayat pesanan dan pembayaran. Data kartu atau rekening tidak kami simpan; pembayaran diproses oleh Google Play atau penyedia pembayaran.',
  ),
  (
    title: '3. Tujuan dan Dasar Pemrosesan',
    content:
        '• Membuat dan mengelola akun Anda, serta menyediakan layanan aplikasi. Dasar: pelaksanaan perjanjian dengan Anda.\n'
        '• Menyesuaikan konten edukasi dengan usia anak dan menyimpan kemajuan belajar. Dasar: persetujuan orang tua/wali.\n'
        '• Memproses pembelian dan langganan. Dasar: pelaksanaan perjanjian dan kewajiban hukum (pencatatan keuangan).\n'
        '• Mengirim notifikasi layanan dan promosi. Dasar: persetujuan Anda (dapat dimatikan di pengaturan perangkat).\n'
        '• Menjaga keamanan dan memperbaiki gangguan aplikasi. Dasar: kepentingan yang sah.',
  ),
  (
    title: '4. Data Anak dan Persetujuan Orang Tua/Wali',
    content:
        'Anak tidak dapat mendaftar sendiri. Pendaftaran hanya dapat dilakukan oleh orang tua atau wali sah berusia 18 tahun ke atas.\n'
        'Kami memproses data anak hanya setelah orang tua/wali memberikan persetujuan tersendiri saat mendaftar, dan hanya untuk keperluan edukasi di dalam aplikasi.\n'
        'Kami tidak menggunakan data anak untuk iklan atau pembuatan profil pemasaran, dan tidak menjualnya.\n'
        'Persetujuan dapat ditarik kapan saja dengan menghapus akun (lihat bagian Hak Anda).',
  ),
  (
    title: '5. Kamera dan Izin Perangkat',
    content:
        'Izin kamera digunakan hanya untuk menampilkan kartu Augmented Reality (AR) di layar. Kami tidak merekam, menyimpan, atau mengunggah foto maupun video dari kamera.\n'
        'Izin notifikasi digunakan untuk mengirim pemberitahuan dan dapat dimatikan kapan saja.',
  ),
  (
    title: '6. Pihak Ketiga dan Transfer ke Luar Negeri',
    content:
        'Kami menggunakan penyedia layanan berikut untuk mengolah data atas nama kami:\n'
        '• Google (Firebase Crashlytics untuk laporan kerusakan, Firebase Cloud Messaging untuk notifikasi, dan Google Play untuk pembayaran)\n'
        '• Penyedia pembayaran (Midtrans), bila tersedia\n'
        '• Penyedia server dan email\n'
        'Sebagian penyedia berada atau menyimpan data di luar Indonesia. Kami hanya bekerja sama dengan penyedia yang menjamin tingkat pelindungan data yang setara dan memprosesnya sesuai instruksi kami.\n'
        'Kami tidak menjual atau menyewakan data pribadi. Data juga dapat dibagikan bila diwajibkan oleh hukum.',
  ),
  (
    title: '7. Jangka Waktu Penyimpanan',
    content:
        '• Data akun dan data anak disimpan selama akun Anda aktif.\n'
        '• Setelah akun dihapus, data akun, data anak, kemajuan belajar, dan persetujuan dihapus. Catatan pesanan dan pembayaran yang wajib kami simpan untuk keperluan pembukuan dan pajak disimpan tanpa identitas Anda (dianonimkan).\n'
        '• Laporan kerusakan dan token notifikasi disimpan selama diperlukan untuk tujuannya, lalu dihapus.',
  ),
  (
    title: '8. Hak Anda',
    content:
        'Sesuai UU PDP, Anda berhak:\n'
        '• Mendapatkan informasi tentang pemrosesan data Anda dan anak Anda\n'
        '• Mengakses dan memperoleh salinan data\n'
        '• Memperbaiki data yang keliru atau tidak lengkap\n'
        '• Menghapus data dan menutup akun\n'
        '• Menarik persetujuan\n'
        '• Membatasi atau menolak pemrosesan tertentu\n'
        '• Meminta data Anda dipindahkan (portabilitas)\n'
        '• Mengajukan keberatan atau pengaduan, termasuk kepada lembaga pelindungan data pribadi yang berwenang',
  ),
  (
    title: '9. Cara Menggunakan Hak Anda',
    content:
        '• Mengubah data: menu Profil di aplikasi.\n'
        '• Menghapus akun dan data: menu Profil > Hapus Akun, atau halaman permintaan penghapusan di situs Arunika tanpa perlu memasang aplikasi.\n'
        '• Hak lainnya (akses, salinan, pembatasan, penolakan, portabilitas, penarikan persetujuan): kirim email ke arunika.helpdesk@gmail.com dari alamat email yang terdaftar.\n'
        'Kami menanggapi permintaan paling lambat 3 x 24 jam untuk permintaan sederhana dan paling lambat 30 hari untuk permintaan lainnya.',
  ),
  (
    title: '10. Keamanan Data',
    content:
        'Kami menerapkan langkah pengamanan teknis dan organisasi yang wajar, antara lain enkripsi kata sandi, koneksi terenkripsi, dan pembatasan akses, untuk melindungi data dari akses, pengungkapan, atau perubahan yang tidak sah.',
  ),
  (
    title: '11. Kegagalan Pelindungan Data',
    content:
        'Bila terjadi kegagalan pelindungan data pribadi, kami akan memberitahu Anda dan lembaga yang berwenang secara tertulis paling lambat 3 x 24 jam setelah kami mengetahuinya, disertai data yang terbuka, waktu, penyebab, dan langkah penanganannya.',
  ),
  (
    title: '12. Perubahan Kebijakan',
    content:
        'Kebijakan ini dapat diperbarui. Untuk perubahan penting, kami akan meminta persetujuan Anda kembali di dalam aplikasi sebelum Anda melanjutkan. Versi dan tanggal berlaku tercantum di bagian atas halaman ini.',
  ),
  (
    title: '13. Kontak',
    content:
        'Pertanyaan atau permintaan terkait data pribadi:\n'
        'Email: arunika.helpdesk@gmail.com',
  ),
];

class PrivacyPolicyScreen extends StatelessWidget {
  const PrivacyPolicyScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFFFFBF5), // soft cream
      appBar: AppBar(
        title: const Text(
          'Kebijakan Privasi',
          style: TextStyle(fontWeight: FontWeight.w600),
        ),
        backgroundColor: Colors.transparent,
        elevation: 0,
        foregroundColor: Colors.black,
      ),
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header card
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(20),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.orange.withValues(alpha: 0.08),
                      blurRadius: 20,
                      offset: const Offset(0, 8),
                    ),
                  ],
                ),
                child: const Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'KEBIJAKAN PRIVASI\nARUNIKA',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w700,
                        height: 1.3,
                      ),
                    ),
                    SizedBox(height: 12),
                    Text(
                      'Arunika sangat menghargai privasi pengguna. Dokumen ini menjelaskan data apa yang kami kumpulkan dari orang tua/wali dan anak, untuk apa, dan hak Anda atas data tersebut sesuai UU PDP.',
                      style: TextStyle(
                        fontSize: 14.5,
                        height: 1.6,
                        color: Colors.black87,
                      ),
                    ),
                    SizedBox(height: 12),
                    Text(
                      'Versi ${LegalVersions.privacy} · Berlaku sejak ${LegalVersions.effectiveDate}',
                      key: Key('legal_version'),
                      style: TextStyle(fontSize: 12.5, color: Colors.black54),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 20),

              for (final s in _sections)
                _SectionCard(title: s.title, content: s.content),

              const SizedBox(height: 16),

              // Footer agreement
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.orange.withValues(alpha: 0.08),
                  borderRadius: BorderRadius.circular(14),
                ),
                child: const Text(
                  'Dengan mencentang persetujuan saat mendaftar, Anda menyatakan telah membaca dan memahami kebijakan privasi ini.',
                  style: TextStyle(
                    fontSize: 13.5,
                    height: 1.5,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),

              const SizedBox(height: 24),
            ],
          ),
        ),
      ),
    );
  }
}

class _SectionCard extends StatelessWidget {
  final String title;
  final String content;

  const _SectionCard({required this.title, required this.content});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 14),
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        boxShadow: [
          BoxShadow(
            color: Colors.orange.withValues(alpha: 0.05),
            blurRadius: 15,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: const TextStyle(fontSize: 15.5, fontWeight: FontWeight.w700),
          ),
          const SizedBox(height: 8),
          Text(
            content,
            style: TextStyle(
              fontSize: 14,
              height: 1.6,
              color: Colors.grey.shade700,
            ),
          ),
        ],
      ),
    );
  }
}
