import 'package:flutter/material.dart';
import 'package:iconsax/iconsax.dart';

/// Confirmation gate for account deletion: requires the user to type the
/// confirm word before the destructive action is enabled, so a stray tap
/// can't delete an account. Resolves the pushed dialog with `true` if
/// confirmed, `false`/`null` if canceled or dismissed.
class DeleteAccountDialog extends StatefulWidget {
  const DeleteAccountDialog({super.key});

  @override
  State<DeleteAccountDialog> createState() => _DeleteAccountDialogState();
}

class _DeleteAccountDialogState extends State<DeleteAccountDialog> {
  static const _confirmWord = 'HAPUS';
  final _controller = TextEditingController();
  bool _isDeleting = false;
  bool _canConfirm = false;

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
      backgroundColor: Colors.white,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(24, 28, 24, 20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const Icon(Iconsax.warning_2, color: Colors.red, size: 40),
            const SizedBox(height: 16),
            const Text(
              'Hapus Akun?',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700),
            ),
            const SizedBox(height: 10),
            const Text(
              'Semua data akun dan anak akan dihapus permanen dan tidak dapat dikembalikan.\n\n'
              'Ketik "$_confirmWord" untuk melanjutkan.',
              textAlign: TextAlign.center,
              style: TextStyle(color: Colors.black54),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: _controller,
              textAlign: TextAlign.center,
              decoration: InputDecoration(
                hintText: _confirmWord,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              onChanged: (value) => setState(
                () => _canConfirm = value.trim().toUpperCase() == _confirmWord,
              ),
            ),
            const SizedBox(height: 20),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: (_canConfirm && !_isDeleting)
                    ? () => setState(() {
                        _isDeleting = true;
                        Navigator.of(context).pop(true);
                      })
                    : null,
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.red,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14),
                  ),
                ),
                child: const Text(
                  'Hapus Akun Permanen',
                  style: TextStyle(color: Colors.white, fontWeight: FontWeight.w700),
                ),
              ),
            ),
            const SizedBox(height: 8),
            TextButton(
              onPressed: () => Navigator.of(context).pop(false),
              child: const Text('Batal'),
            ),
          ],
        ),
      ),
    );
  }
}
