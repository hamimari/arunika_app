import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

/// The two separate, required consent checkboxes shown at signup and on the
/// re-consent screen (UU PDP): agreement to the Terms and Privacy Policy, and
/// the parent/guardian declaration that lets us process the child's data.
/// They are deliberately two boxes, not one: consent has to be specific.
class ConsentCheckboxes extends StatelessWidget {
  final bool termsAccepted;
  final bool parentalAccepted;
  final ValueChanged<bool> onTermsChanged;
  final ValueChanged<bool> onParentalChanged;

  const ConsentCheckboxes({
    super.key,
    required this.termsAccepted,
    required this.parentalAccepted,
    required this.onTermsChanged,
    required this.onParentalChanged,
  });

  static const _bodyStyle = TextStyle(fontSize: 12, color: Colors.black54);
  static const _linkStyle = TextStyle(
    color: Colors.orange,
    fontWeight: FontWeight.w600,
  );

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _row(
          key: const Key('consent_terms_checkbox'),
          value: termsAccepted,
          onChanged: onTermsChanged,
          text: TextSpan(
            text: 'Saya telah membaca dan menyetujui ',
            style: _bodyStyle,
            children: [
              TextSpan(
                text: 'Syarat & Ketentuan',
                style: _linkStyle,
                recognizer: TapGestureRecognizer()
                  ..onTap = () => context.push('/terms'),
              ),
              const TextSpan(text: ' dan '),
              TextSpan(
                text: 'Kebijakan Privasi',
                style: _linkStyle,
                recognizer: TapGestureRecognizer()
                  ..onTap = () => context.push('/privacy'),
              ),
              const TextSpan(text: ' Arunika.'),
            ],
          ),
        ),
        _row(
          key: const Key('consent_parental_checkbox'),
          value: parentalAccepted,
          onChanged: onParentalChanged,
          text: const TextSpan(
            text:
                'Saya adalah orang tua atau wali sah anak ini, berusia 18 tahun '
                'atau lebih, dan menyetujui pemrosesan data pribadi anak saya '
                '(nama, tanggal lahir, dan jenis kelamin) untuk tujuan yang '
                'dijelaskan dalam Kebijakan Privasi.',
            style: _bodyStyle,
          ),
        ),
      ],
    );
  }

  Widget _row({
    required Key key,
    required bool value,
    required ValueChanged<bool> onChanged,
    required TextSpan text,
  }) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Checkbox(
          key: key,
          value: value,
          activeColor: Colors.orange,
          onChanged: (v) => onChanged(v ?? false),
        ),
        Expanded(
          child: Padding(
            padding: const EdgeInsets.only(top: 10),
            child: Text.rich(text),
          ),
        ),
      ],
    );
  }
}
