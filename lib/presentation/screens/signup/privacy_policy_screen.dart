import 'package:flutter/material.dart';

class PrivacyPolicyScreen extends StatelessWidget {
  const PrivacyPolicyScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFFFFBF5), // soft cream
      appBar: AppBar(
        title: const Text(
          "Kebijakan Privasi",
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
                      "KEBIJAKAN PRIVASI\nARUNIKA",
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w700,
                        height: 1.3,
                      ),
                    ),
                    SizedBox(height: 12),
                    Text(
                      "Arunika sangat menghargai privasi pengguna. Dokumen ini menjelaskan bagaimana kami mengelola data Anda.",
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

              _SectionCard(
                title: "1. Data yang Dikumpulkan",
                content:
                "Kami dapat mengumpulkan:\n"
                    "• Nama pengguna\n"
                    "• Data anak (nama, usia)\n"
                    "• Email\n"
                    "• Data penggunaan aplikasi\n"
                    "• Data perangkat",
              ),
              _SectionCard(
                title: "2. Penggunaan Data",
                content:
                "Data digunakan untuk:\n"
                    "• Menyediakan layanan aplikasi\n"
                    "• Personalisasi konten edukasi\n"
                    "• Peningkatan kualitas layanan\n"
                    "• Keamanan sistem",
              ),
              _SectionCard(
                title: "3. Data Anak",
                content:
                "Data anak hanya digunakan untuk keperluan edukasi di dalam aplikasi.\n"
                    "Tidak dibagikan ke pihak ketiga.",
              ),
              _SectionCard(
                title: "4. Keamanan Data",
                content:
                "Kami menggunakan sistem keamanan yang wajar untuk melindungi data pengguna dari akses tidak sah.",
              ),
              _SectionCard(
                title: "5. Pembagian Data",
                content:
                "Kami tidak menjual atau menyewakan data pengguna kepada pihak ketiga.\n"
                    "Data hanya dibagikan jika diwajibkan oleh hukum.",
              ),
              _SectionCard(
                title: "6. Cookie dan Teknologi Serupa",
                content:
                "Aplikasi dapat menggunakan teknologi analitik untuk peningkatan layanan.",
              ),
              _SectionCard(
                title: "7. Hak Pengguna",
                content:
                "Pengguna berhak:\n"
                    "• Mengakses data\n"
                    "• Mengubah data\n"
                    "• Menghapus data\n"
                    "• Menutup akun",
              ),
              _SectionCard(
                title: "8. Perubahan Kebijakan",
                content:
                "Kebijakan privasi dapat diperbarui sewaktu-waktu.\n"
                    "Perubahan akan diinformasikan melalui aplikasi.",
              ),
              _SectionCard(
                title: "9. Kontak",
                content:
                "Jika ada pertanyaan terkait privasi:\n"
                    "Email: arunika.helpdesk@gmail.com",
              ),

              const SizedBox(height: 16),

              // Footer agreement
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.orange.withValues(alpha: 0.08),
                  borderRadius: BorderRadius.circular(14),
                ),
                child: const Text(
                  "Dengan menggunakan aplikasi Arunika, Anda menyetujui kebijakan privasi ini.",
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
