import 'package:arunika_app/constants/app_colors.dart';
import 'package:arunika_app/data/repositories/auth_repository.dart';
import 'package:arunika_app/di/locator.dart';
import 'package:dio/dio.dart';
import 'package:flutter/material.dart';

/// Prompts a user whose email address is unverified to verify it.
///
/// Deliberately non-modal and dismissible: verification gates password
/// recovery and nothing else, so it must never stand between a parent and
/// the content or purchases they came for. It informs; it does not obstruct.
class EmailVerificationBanner extends StatefulWidget {
  const EmailVerificationBanner({
    super.key,
    required this.isVerified,
    this.repository,
  });

  /// When true the banner renders nothing.
  final bool isVerified;

  /// Injectable for tests; falls back to the registered singleton.
  final AuthRepository? repository;

  @override
  State<EmailVerificationBanner> createState() =>
      _EmailVerificationBannerState();
}

enum _ResendState { idle, sending, sent, rateLimited, failed }

class _EmailVerificationBannerState extends State<EmailVerificationBanner> {
  bool _dismissed = false;
  _ResendState _state = _ResendState.idle;

  AuthRepository get _repo => widget.repository ?? locator<AuthRepository>();

  Future<void> _resend() async {
    setState(() => _state = _ResendState.sending);
    try {
      await _repo.resendVerification();
      if (!mounted) return;
      setState(() => _state = _ResendState.sent);
    } on DioException catch (e) {
      if (!mounted) return;
      // 429 is not a failure the user should read as "something broke" —
      // they asked too often and simply need to wait.
      setState(
        () => _state = e.response?.statusCode == 429
            ? _ResendState.rateLimited
            : _ResendState.failed,
      );
    } catch (_) {
      if (!mounted) return;
      setState(() => _state = _ResendState.failed);
    }
  }

  String? get _statusMessage => switch (_state) {
    _ResendState.sent => 'Email verifikasi sudah dikirim. Cek kotak masuk kamu.',
    _ResendState.rateLimited =>
      'Terlalu sering meminta. Coba lagi dalam beberapa menit.',
    _ResendState.failed => 'Gagal mengirim email. Coba lagi nanti.',
    _ => null,
  };

  @override
  Widget build(BuildContext context) {
    if (widget.isVerified || _dismissed) return const SizedBox.shrink();

    final message = _statusMessage;

    return Container(
      key: const Key('email-verification-banner'),
      margin: const EdgeInsets.fromLTRB(16, 12, 16, 0),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.creamCard,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.primaryOrangeLight),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Icon(
                Icons.mark_email_unread_outlined,
                color: AppColors.primaryOrangeDark,
                size: 20,
              ),
              const SizedBox(width: 10),
              const Expanded(
                child: Text(
                  'Verifikasi email kamu agar bisa memulihkan kata sandi '
                  'lewat email jika suatu saat lupa.',
                  style: TextStyle(
                    color: AppColors.deepBrown,
                    fontSize: 13,
                    height: 1.4,
                  ),
                ),
              ),
              InkWell(
                key: const Key('email-verification-banner-dismiss'),
                onTap: () => setState(() => _dismissed = true),
                child: const Padding(
                  padding: EdgeInsets.only(left: 6),
                  child: Icon(
                    Icons.close,
                    size: 18,
                    color: AppColors.mediumBrown,
                  ),
                ),
              ),
            ],
          ),
          if (message != null)
            Padding(
              padding: const EdgeInsets.only(top: 8),
              child: Text(
                message,
                key: const Key('email-verification-banner-status'),
                style: const TextStyle(
                  color: AppColors.mediumBrown,
                  fontSize: 12,
                ),
              ),
            ),
          // A failed or rate-limited attempt keeps the action available; only
          // a confirmed send retires it.
          if (_state != _ResendState.sent)
            Align(
              alignment: Alignment.centerLeft,
              child: TextButton(
                key: const Key('email-verification-banner-resend'),
                onPressed:
                    _state == _ResendState.sending ? null : _resend,
                style: TextButton.styleFrom(
                  padding: const EdgeInsets.symmetric(horizontal: 4),
                  minimumSize: const Size(0, 32),
                  tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                ),
                child: Text(
                  _state == _ResendState.sending ? 'Mengirim…' : 'Kirim ulang',
                  style: const TextStyle(
                    color: AppColors.primaryOrangeDark,
                    fontWeight: FontWeight.bold,
                    fontSize: 13,
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}
