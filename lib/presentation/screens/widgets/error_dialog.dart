import 'package:flutter/material.dart';

enum AppSheetType { error, info, success }

class AppErrorSheet extends StatelessWidget {
  final String message;
  final String? title;
  final VoidCallback onConfirm;
  final String buttonText;
  final AppSheetType type;

  const AppErrorSheet({
    super.key,
    required this.message,
    required this.onConfirm,
    this.title,
    this.buttonText = 'Mengerti',
    this.type = AppSheetType.error,
  });

  /// Convenience method — shows the sheet and resolves when dismissed.
  static Future<void> show(
    BuildContext context, {
    required String message,
    String? title,
    String buttonText = 'Mengerti',
    AppSheetType type = AppSheetType.error,
    VoidCallback? onConfirm,
  }) {
    return showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => AppErrorSheet(
        message: message,
        title: title,
        buttonText: buttonText,
        type: type,
        onConfirm: onConfirm ?? () {},
      ),
    );
  }

  _SheetStyle get _style {
    switch (type) {
      case AppSheetType.error:
        return _SheetStyle(
          iconBg: const Color(0xFFFFEBEE),
          iconColor: const Color(0xFFE53935),
          buttonColor: const Color(0xFFE53935),
          icon: Icons.error_outline_rounded,
          accentBar: const Color(0xFFE53935),
        );
      case AppSheetType.success:
        return _SheetStyle(
          iconBg: const Color(0xFFE8F5E9),
          iconColor: const Color(0xFF43A047),
          buttonColor: const Color(0xFF43A047),
          icon: Icons.check_circle_outline_rounded,
          accentBar: const Color(0xFF43A047),
        );
      case AppSheetType.info:
        return _SheetStyle(
          iconBg: const Color(0xFFFFF3E0),
          iconColor: Colors.orange,
          buttonColor: Colors.orange,
          icon: Icons.info_outline_rounded,
          accentBar: Colors.orange,
        );
    }
  }

  @override
  Widget build(BuildContext context) {
    final s = _style;

    return Container(
      width: double.infinity,
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // ── Accent bar (colour-coded) ──────────────────────────────────
          Container(
            width: 48,
            height: 4,
            margin: const EdgeInsets.only(top: 12),
            decoration: BoxDecoration(
              color: s.accentBar,
              borderRadius: BorderRadius.circular(8),
            ),
          ),

          Padding(
            padding: const EdgeInsets.fromLTRB(24, 24, 24, 28),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // ── Icon ────────────────────────────────────────────────
                Container(
                  width: 64,
                  height: 64,
                  decoration: BoxDecoration(
                    color: s.iconBg,
                    shape: BoxShape.circle,
                  ),
                  child: Icon(s.icon, color: s.iconColor, size: 32),
                ),

                const SizedBox(height: 16),

                // ── Title ───────────────────────────────────────────────
                if (title != null) ...[
                  Text(
                    title!,
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w700,
                      color: Color(0xFF1A1A1A),
                      letterSpacing: 0.1,
                    ),
                  ),
                  const SizedBox(height: 8),
                ],

                // ── Message ─────────────────────────────────────────────
                Text(
                  message,
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 14.5,
                    height: 1.55,
                    color: Colors.grey.shade600,
                  ),
                ),

                const SizedBox(height: 24),

                // ── Button ──────────────────────────────────────────────
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: () {
                      Navigator.pop(context);
                      onConfirm();
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: s.buttonColor,
                      padding: const EdgeInsets.symmetric(vertical: 15),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14),
                      ),
                      elevation: 0,
                    ),
                    child: Text(
                      buttonText,
                      style: const TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w600,
                        color: Colors.white,
                      ),
                    ),
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

class _SheetStyle {
  final Color iconBg;
  final Color iconColor;
  final Color buttonColor;
  final IconData icon;
  final Color accentBar;

  const _SheetStyle({
    required this.iconBg,
    required this.iconColor,
    required this.buttonColor,
    required this.icon,
    required this.accentBar,
  });
}
