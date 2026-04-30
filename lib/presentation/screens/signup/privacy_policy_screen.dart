import 'package:flutter/material.dart';

class PrivacyPolicyScreen extends StatelessWidget {
  const PrivacyPolicyScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFFFFBF5),
      appBar: AppBar(
        title: const Text(
          "Kebijakan Privasi",
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
                            Icons.shield_rounded,
                            color: Colors.white,
                            size: 28,
                          ),
                        ),
                        const SizedBox(height: 16),
                        const Text(
                          "Kebijakan Privasi\nArunika",
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
                          "Arunika sangat menghargai privasi pengguna. Dokumen ini menjelaskan bagaimana kami mengelola data Anda.",
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
                    title: "Data yang Dikumpulkan",
                    content:
                        "Kami dapat mengumpulkan:\n"
                        "• Nama pengguna\n"
                        "• Data anak (nama, usia)\n"
                        "• Email\n"
                        "• Data penggunaan aplikasi\n"
                        "• Data perangkat",
                  ),
                  _SectionCard(
                    number: "2",
                    title: "Penggunaan Data",
                    content:
                        "Data digunakan untuk:\n"
                        "• Menyediakan layanan aplikasi\n"
                        "• Personalisasi konten edukasi\n"
                        "• Peningkatan kualitas layanan\n"
                        "• Keamanan sistem",
                  ),
                  _SectionCard(
                    number: "3",
                    title: "Data Anak",
                    content:
                        "Data anak hanya digunakan untuk keperluan edukasi di dalam aplikasi.\n"
                        "Tidak dibagikan ke pihak ketiga.",
                  ),
                  _SectionCard(
                    number: "4",
                    title: "Keamanan Data",
                    content:
                        "Kami menggunakan sistem keamanan yang wajar untuk melindungi data pengguna dari akses tidak sah.",
                  ),
                  _SectionCard(
                    number: "5",
                    title: "Pembagian Data",
                    content:
                        "Kami tidak menjual atau menyewakan data pengguna kepada pihak ketiga.\n"
                        "Data hanya dibagikan jika diwajibkan oleh hukum.",
                  ),
                  _SectionCard(
                    number: "6",
                    title: "Cookie dan Teknologi Serupa",
                    content:
                        "Aplikasi dapat menggunakan teknologi analitik untuk peningkatan layanan.",
                  ),
                  _SectionCard(
                    number: "7",
                    title: "Hak Pengguna",
                    content:
                        "Pengguna berhak:\n"
                        "• Mengakses data\n"
                        "• Mengubah data\n"
                        "• Menghapus data\n"
                        "• Menutup akun",
                  ),
                  _SectionCard(
                    number: "8",
                    title: "Perubahan Kebijakan",
                    content:
                        "Kebijakan privasi dapat diperbarui sewaktu-waktu.\n"
                        "Perubahan akan diinformasikan melalui aplikasi.",
                  ),
                  _SectionCard(
                    number: "9",
                    title: "Kontak",
                    content:
                        "Jika ada pertanyaan terkait privasi:\n"
                        "Email: arunika.helpdesk@gmail.com",
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
