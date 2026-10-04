import 'package:arunika_app/core/auth/auth_notifier.dart';
import 'package:arunika_app/core/auth/consent_gate.dart';
import 'package:arunika_app/data/models/request/consent_request.dart';
import 'package:arunika_app/data/repositories/user_repository.dart';
import 'package:arunika_app/di/locator.dart';
import 'package:arunika_app/presentation/screens/widgets/app_button.dart';
import 'package:arunika_app/presentation/screens/widgets/consent_checkboxes.dart';
import 'package:arunika_app/presentation/screens/widgets/delete_account_dialog.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

/// Shown, with no way back, to a signed-in user whose consent is missing or
/// out of date (UU PDP). They can accept, sign out, or delete their account;
/// there is no way to carry on without agreeing.
class ConsentScreen extends StatefulWidget {
  const ConsentScreen({super.key});

  @override
  State<ConsentScreen> createState() => _ConsentScreenState();
}

class _ConsentScreenState extends State<ConsentScreen> {
  bool _termsAccepted = false;
  bool _parentalAccepted = false;
  bool _submitting = false;
  String? _error;

  bool get _canSubmit => _termsAccepted && _parentalAccepted && !_submitting;

  Future<void> _accept() async {
    setState(() {
      _submitting = true;
      _error = null;
    });
    try {
      final stillRequired = await locator<UserRepository>().recordConsent(
        const ConsentRequest.current(),
      );
      if (stillRequired) {
        // The backend wants a newer version than this build shows.
        setState(() {
          _submitting = false;
          _error =
              'Versi terbaru Syarat & Ketentuan belum tersedia di aplikasi ini. '
              'Silakan perbarui aplikasi Arunika.';
        });
        return;
      }
      await ConsentGate.markAccepted();
      if (mounted) context.go('/shell');
    } catch (_) {
      if (mounted) {
        setState(() {
          _submitting = false;
          _error = 'Gagal menyimpan persetujuan. Silakan coba lagi.';
        });
      }
    }
  }

  Future<void> _signOut() async {
    await locator<AuthNotifier>().logout();
    if (mounted) context.go('/landing');
  }

  Future<void> _deleteAccount() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (_) => const DeleteAccountDialog(),
    );
    if (confirmed != true || !mounted) return;
    try {
      await locator<UserRepository>().deleteAccount();
      await locator<AuthNotifier>().logout();
      if (mounted) context.go('/landing');
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Gagal menghapus akun. Silakan coba lagi.'),
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    // No back navigation: consent can't be skipped.
    return PopScope(
      canPop: false,
      child: Scaffold(
        backgroundColor: const Color(0xFFFFFBF5),
        body: SafeArea(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(24),
                boxShadow: [
                  BoxShadow(
                    color: Colors.orange.withValues(alpha: 0.08),
                    blurRadius: 24,
                    offset: const Offset(0, 12),
                  ),
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Pembaruan Kebijakan Privasi',
                    style: TextStyle(fontSize: 20, fontWeight: FontWeight.w700),
                  ),
                  const SizedBox(height: 12),
                  const Text(
                    'Kami memperbarui Syarat & Ketentuan dan Kebijakan Privasi '
                    'sesuai Undang-Undang Pelindungan Data Pribadi (UU PDP). '
                    'Karena Arunika memproses data anak Anda, kami perlu '
                    'persetujuan Anda sebagai orang tua atau wali sebelum Anda '
                    'dapat melanjutkan.',
                    style: TextStyle(fontSize: 14, height: 1.5),
                  ),
                  const SizedBox(height: 16),
                  ConsentCheckboxes(
                    termsAccepted: _termsAccepted,
                    parentalAccepted: _parentalAccepted,
                    onTermsChanged: (v) => setState(() => _termsAccepted = v),
                    onParentalChanged: (v) =>
                        setState(() => _parentalAccepted = v),
                  ),
                  if (_error != null) ...[
                    const SizedBox(height: 8),
                    Text(
                      _error!,
                      style: const TextStyle(color: Colors.red, fontSize: 13),
                    ),
                  ],
                  const SizedBox(height: 20),
                  AppButton(
                    text: 'Setuju & Lanjutkan',
                    enabled: _canSubmit,
                    loading: _submitting,
                    onPressed: _accept,
                  ),
                  const SizedBox(height: 8),
                  Center(
                    child: TextButton(
                      onPressed: _submitting ? null : _signOut,
                      child: const Text('Keluar'),
                    ),
                  ),
                  Center(
                    child: TextButton(
                      onPressed: _submitting ? null : _deleteAccount,
                      style: TextButton.styleFrom(foregroundColor: Colors.red),
                      child: const Text('Hapus Akun'),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
