import 'package:flutter/material.dart';

class TermsAndConditionsScreen extends StatelessWidget {
  const TermsAndConditionsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFFFFBF5), // soft cream
      appBar: AppBar(
        title: const Text(
          "Syarat & Ketentuan",
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
                      color: Colors.orange.withOpacity(0.08),
                      blurRadius: 20,
                      offset: const Offset(0, 8),
                    ),
                  ],
                ),
                child: const Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      "SYARAT DAN KETENTUAN\nPENGGUNAAN APLIKASI ARUNIKA",
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w700,
                        height: 1.3,
                      ),
                    ),
                    SizedBox(height: 12),
                    Text(
                      "Dengan menggunakan aplikasi Arunika, Anda menyetujui seluruh syarat dan ketentuan berikut ini:",
                      style: TextStyle(
                        fontSize: 14.5,
                        height: 1.6,
                        color: Colors.black87,
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 20),

              // Content card
              _SectionCard(
                title: "1. Definisi",
                content:
                "Arunika adalah aplikasi edukasi anak berbasis Augmented Reality (AR), flashcard, dan konten dongeng digital.",
              ),
              _SectionCard(
                title: "2. Penggunaan Layanan",
                content:
                "Aplikasi hanya boleh digunakan untuk tujuan edukasi dan non-komersial.\n"
                    "Orang tua/wali bertanggung jawab atas penggunaan aplikasi oleh anak.",
              ),
              _SectionCard(
                title: "3. Akun Pengguna",
                content:
                "Pengguna bertanggung jawab menjaga kerahasiaan akun dan data login.\n"
                    "Segala aktivitas yang terjadi di akun menjadi tanggung jawab pengguna.",
              ),
              _SectionCard(
                title: "4. Konten",
                content:
                "Seluruh konten (gambar, audio, cerita, AR object) adalah milik Arunika dan dilindungi hak cipta.\n"
                    "Dilarang menyalin, mendistribusikan, atau memperjualbelikan tanpa izin.",
              ),
              _SectionCard(
                title: "5. Layanan AR",
                content:
                "Fitur AR berfungsi sebagai media pembelajaran visual.\n"
                    "Kami tidak menjamin kompatibilitas di semua perangkat.",
              ),
              _SectionCard(
                title: "6. Pembelian Produk",
                content:
                "Produk flashcard AR yang dibeli tidak dapat dikembalikan kecuali terdapat cacat produksi.\n"
                    "Harga dapat berubah sewaktu-waktu tanpa pemberitahuan.",
              ),
              _SectionCard(
                title: "7. Batasan Tanggung Jawab",
                content:
                "Arunika tidak bertanggung jawab atas:\n"
                    "• Kerusakan perangkat\n"
                    "• Gangguan teknis\n"
                    "• Kehilangan data akibat force majeure",
              ),
              _SectionCard(
                title: "8. Perubahan Layanan",
                content:
                "Kami berhak mengubah, menambah, atau menghapus fitur aplikasi kapan saja.",
              ),
              _SectionCard(
                title: "9. Hukum yang Berlaku",
                content:
                "Syarat ini tunduk pada hukum yang berlaku di Republik Indonesia.",
              ),

              const SizedBox(height: 16),

              // Footer agreement
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.orange.withOpacity(0.08),
                  borderRadius: BorderRadius.circular(14),
                ),
                child: const Text(
                  "Dengan menggunakan aplikasi ini, Anda dianggap telah membaca, memahami, dan menyetujui seluruh ketentuan di atas.",
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

  const _SectionCard({
    required this.title,
    required this.content,
  });

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
            color: Colors.orange.withOpacity(0.05),
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
            style: const TextStyle(
              fontSize: 15.5,
              fontWeight: FontWeight.w700,
            ),
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
