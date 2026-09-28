import 'package:arunika_app/core/legal/legal_versions.dart';
import 'package:flutter/material.dart';

/// Kept in step with the landing site page and, for what the parent agrees
/// to, with `LegalVersions`. Change the text => bump the version there and in
/// the backend's `CurrentConsentVersions` so users are asked again.
const _sections = <({String title, String content})>[
  (
    title: '1. Definisi',
    content:
        'Arunika adalah aplikasi edukasi anak berbasis Augmented Reality (AR), flashcard, dan konten dongeng digital.\n'
        '"Orang tua/wali" adalah orang tua atau wali sah anak yang mendaftarkan akun.',
  ),
  (
    title: '2. Pendaftaran dan Kelayakan',
    content:
        'Akun hanya boleh dibuat oleh orang tua atau wali sah yang berusia 18 tahun ke atas. Anak tidak dapat mendaftar sendiri.\n'
        'Orang tua/wali menjamin bahwa data yang diberikan benar dan bahwa ia berwenang memberikan persetujuan atas pemrosesan data anak, sebagaimana dijelaskan dalam Kebijakan Privasi.',
  ),
  (
    title: '3. Penggunaan Layanan',
    content:
        'Aplikasi hanya boleh digunakan untuk tujuan edukasi dan non-komersial.\n'
        'Orang tua/wali bertanggung jawab atas penggunaan aplikasi oleh anak dan mengawasi anak saat menggunakannya.',
  ),
  (
    title: '4. Akun Pengguna',
    content:
        'Pengguna bertanggung jawab menjaga kerahasiaan akun dan data login.\n'
        'Segala aktivitas yang terjadi di akun menjadi tanggung jawab pengguna.',
  ),
  (
    title: '5. Konten',
    content:
        'Seluruh konten (gambar, audio, cerita, objek AR) adalah milik Arunika dan dilindungi hak cipta.\n'
        'Dilarang menyalin, mendistribusikan, atau memperjualbelikan tanpa izin.',
  ),
  (
    title: '6. Layanan AR',
    content:
        'Fitur AR berfungsi sebagai media pembelajaran visual dan memerlukan izin kamera.\n'
        'Kami tidak menjamin kompatibilitas di semua perangkat.',
  ),
  (
    title: '7. Pembelian dan Langganan',
    content:
        'Sebagian konten dan paket premium bersifat berbayar. Harga yang ditampilkan di aplikasi berlaku pada saat pembelian dan dapat berubah untuk pembelian berikutnya.\n'
        'Pembelian melalui Google Play tunduk pada ketentuan pembayaran dan kebijakan pengembalian dana Google Play. Permintaan pengembalian dana dapat diajukan melalui Google Play atau ke arunika.helpdesk@gmail.com.\n'
        'Langganan berakhir pada tanggal yang tertera di aplikasi. Langganan melalui Google Play dapat diperpanjang otomatis dan dapat dibatalkan kapan saja di Google Play.\n'
        'Konten yang sudah dibeli tetap dapat diakses oleh akun yang membelinya.',
  ),
  (
    title: '8. Data Pribadi',
    content:
        'Cara kami mengumpulkan, menggunakan, dan melindungi data pribadi orang tua/wali dan anak diatur dalam Kebijakan Privasi, yang merupakan bagian dari Syarat & Ketentuan ini. Anda dapat menarik persetujuan dan menghapus akun kapan saja melalui menu Profil.',
  ),
  (
    title: '9. Batasan Tanggung Jawab',
    content:
        'Arunika tidak bertanggung jawab atas:\n'
        '• Kerusakan perangkat\n'
        '• Gangguan teknis\n'
        '• Kehilangan data akibat force majeure\n'
        'Batasan ini tidak mengurangi hak Anda menurut peraturan perundang-undangan yang berlaku.',
  ),
  (
    title: '10. Perubahan Layanan dan Ketentuan',
    content:
        'Kami berhak mengubah, menambah, atau menghapus fitur aplikasi.\n'
        'Untuk perubahan penting pada ketentuan ini, kami akan meminta persetujuan Anda kembali di dalam aplikasi.',
  ),
  (
    title: '11. Hukum yang Berlaku',
    content: 'Syarat ini tunduk pada hukum yang berlaku di Republik Indonesia.',
  ),
];

class TermsAndConditionsScreen extends StatelessWidget {
  const TermsAndConditionsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFFFFBF5), // soft cream
      appBar: AppBar(
        title: const Text(
          'Syarat & Ketentuan',
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
                      'SYARAT DAN KETENTUAN\nPENGGUNAAN APLIKASI ARUNIKA',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w700,
                        height: 1.3,
                      ),
                    ),
                    SizedBox(height: 12),
                    Text(
                      'Dengan mendaftar dan menggunakan aplikasi Arunika, Anda menyetujui syarat dan ketentuan berikut ini:',
                      style: TextStyle(
                        fontSize: 14.5,
                        height: 1.6,
                        color: Colors.black87,
                      ),
                    ),
                    SizedBox(height: 12),
                    Text(
                      'Versi ${LegalVersions.terms} · Berlaku sejak ${LegalVersions.effectiveDate}',
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
                  'Dengan mencentang persetujuan saat mendaftar, Anda menyatakan telah membaca, memahami, dan menyetujui seluruh ketentuan di atas.',
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
