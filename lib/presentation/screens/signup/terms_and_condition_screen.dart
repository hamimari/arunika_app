import 'package:flutter/material.dart';

class TermsAndConditionsScreen extends StatelessWidget {
  const TermsAndConditionsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFFFFBF5),
      appBar: AppBar(
        title: const Text(
          "Syarat & Ketentuan",
          style: TextStyle(fontWeight: FontWeight.w600),
        ),
        backgroundColor: Colors.transparent,
        elevation: 0,
        foregroundColor: Colors.black,
      ),
      body: Column(
        children: [
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.fromLTRB(20, 0, 20, 24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // ── Branded header ──────────────────────────────────────
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(24),
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [
                          Colors.orange.shade400,
                          Colors.orange.shade300,
                        ],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Container(
                          padding: const EdgeInsets.all(10),
                          decoration: BoxDecoration(
                            color: Colors.white.withValues(alpha: 0.25),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: const Icon(
                            Icons.gavel_rounded,
                            color: Colors.white,
                            size: 28,
                          ),
                        ),
                        const SizedBox(height: 16),
                        const Text(
                          "Syarat dan Ketentuan\nPenggunaan Arunika",
                          style: TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.w700,
                            color: Colors.white,
                            height: 1.3,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          "Terakhir diperbarui: 1 Januari 2025",
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.white.withValues(alpha: 0.85),
                          ),
                        ),
                        const SizedBox(height: 12),
                        Text(
                          "Dengan menggunakan aplikasi Arunika, Anda menyetujui seluruh syarat dan ketentuan berikut ini.",
                          style: TextStyle(
                            fontSize: 13.5,
                            color: Colors.white.withValues(alpha: 0.92),
                            height: 1.5,
                          ),
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 20),

                  // ── Sections ────────────────────────────────────────────
                  _SectionCard(
                    number: "1",
                    title: "Definisi",
                    content:
                        "Arunika adalah aplikasi edukasi anak berbasis Augmented Reality (AR), flashcard, dan konten dongeng digital.",
                  ),
                  _SectionCard(
                    number: "2",
                    title: "Penggunaan Layanan",
                    content:
                        "Aplikasi hanya boleh digunakan untuk tujuan edukasi dan non-komersial.\n"
                        "Orang tua/wali bertanggung jawab atas penggunaan aplikasi oleh anak.",
                  ),
                  _SectionCard(
                    number: "3",
                    title: "Akun Pengguna",
                    content:
                        "Pengguna bertanggung jawab menjaga kerahasiaan akun dan data login.\n"
                        "Segala aktivitas yang terjadi di akun menjadi tanggung jawab pengguna.",
                  ),
                  _SectionCard(
                    number: "4",
                    title: "Konten",
                    content:
                        "Seluruh konten (gambar, audio, cerita, AR object) adalah milik Arunika dan dilindungi hak cipta.\n"
                        "Dilarang menyalin, mendistribusikan, atau memperjualbelikan tanpa izin.",
                  ),
                  _SectionCard(
                    number: "5",
                    title: "Layanan AR",
                    content:
                        "Fitur AR berfungsi sebagai media pembelajaran visual.\n"
                        "Kami tidak menjamin kompatibilitas di semua perangkat.",
                  ),
                  _SectionCard(
                    number: "6",
                    title: "Pembelian Produk",
                    content:
                        "Produk flashcard AR yang dibeli tidak dapat dikembalikan kecuali terdapat cacat produksi.\n"
                        "Harga dapat berubah sewaktu-waktu tanpa pemberitahuan.",
                  ),
                  _SectionCard(
                    number: "7",
                    title: "Batasan Tanggung Jawab",
                    content:
                        "Arunika tidak bertanggung jawab atas:\n"
                        "• Kerusakan perangkat\n"
                        "• Gangguan teknis\n"
                        "• Kehilangan data akibat force majeure",
                  ),
                  _SectionCard(
                    number: "8",
                    title: "Perubahan Layanan",
                    content:
                        "Kami berhak mengubah, menambah, atau menghapus fitur aplikasi kapan saja.",
                  ),
                  _SectionCard(
                    number: "9",
                    title: "Hukum yang Berlaku",
                    content:
                        "Syarat ini tunduk pada hukum yang berlaku di Republik Indonesia.",
                  ),

                  const SizedBox(height: 8),
                ],
              ),
            ),
          ),

          // ── Sticky bottom button ─────────────────────────────────────
          Container(
            padding: const EdgeInsets.fromLTRB(20, 12, 20, 28),
            decoration: BoxDecoration(
              color: Colors.white,
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.06),
                  blurRadius: 12,
                  offset: const Offset(0, -4),
                ),
              ],
            ),
            child: SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () => Navigator.of(context).pop(),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.orange,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14),
                  ),
                  elevation: 0,
                ),
                child: const Text(
                  "Saya Mengerti",
                  style: TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w600,
                    color: Colors.white,
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _SectionCard extends StatelessWidget {
  final String number;
  final String title;
  final String content;

  const _SectionCard({
    required this.number,
    required this.title,
    required this.content,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.orange.withValues(alpha: 0.05),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 32,
            height: 32,
            decoration: BoxDecoration(
              color: Colors.orange.shade50,
              borderRadius: BorderRadius.circular(8),
            ),
            child: Center(
              child: Text(
                number,
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w700,
                  color: Colors.orange.shade700,
                ),
              ),
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w700,
                    color: Colors.black87,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  content,
                  style: TextStyle(
                    fontSize: 13.5,
                    height: 1.6,
                    color: Colors.grey.shade700,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
