import 'dart:math';

import 'package:arunika_app/constants/app_colors.dart';
import 'package:arunika_app/constants/app_text_styles.dart';
import 'package:flutter/material.dart';

/// A simple arithmetic challenge shown before a child-directed app's
/// purchase screens (Google Play Families Policy requirement) — an adult is
/// expected to answer it; a child typically can't yet.
class ParentalGateScreen extends StatefulWidget {
  final VoidCallback onPassed;

  const ParentalGateScreen({super.key, required this.onPassed});

  @override
  State<ParentalGateScreen> createState() => _ParentalGateScreenState();
}

class _ParentalGateScreenState extends State<ParentalGateScreen> {
  final _controller = TextEditingController();
  late int _a, _b;
  String? _error;

  @override
  void initState() {
    super.initState();
    _rollChallenge();
  }

  void _rollChallenge() {
    final rng = Random();
    _a = 3 + rng.nextInt(6); // 3..8
    _b = 3 + rng.nextInt(6); // 3..8
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _submit() {
    final answer = int.tryParse(_controller.text.trim());
    if (answer == _a * _b) {
      widget.onPassed();
      return;
    }
    setState(() {
      _error = 'Jawaban kurang tepat. Coba lagi.';
      _controller.clear();
      _rollChallenge();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.creamBackground,
      appBar: AppBar(
        backgroundColor: AppColors.creamBackground,
        elevation: 0,
        leading: BackButton(
          color: AppColors.deepBrown,
          onPressed: () => Navigator.of(context).maybePop(),
        ),
      ),
      body: SafeArea(
        child: Center(
          child: Padding(
            padding: const EdgeInsets.all(28),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(
                  Icons.family_restroom_rounded,
                  size: 56,
                  color: AppColors.primaryOrange,
                ),
                const SizedBox(height: 20),
                Text(
                  'Verifikasi Orang Tua',
                  style: AppTextStyles.subheading,
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 10),
                Text(
                  'Halaman ini berisi pembelian dalam aplikasi. Selesaikan soal berikut untuk melanjutkan.',
                  style: AppTextStyles.body.copyWith(color: AppColors.mediumBrown),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 28),
                Text(
                  '$_a  ×  $_b  =  ?',
                  style: AppTextStyles.subheading.copyWith(fontSize: 28),
                ),
                const SizedBox(height: 16),
                TextField(
                  controller: _controller,
                  keyboardType: TextInputType.number,
                  textAlign: TextAlign.center,
                  autofocus: true,
                  onSubmitted: (_) => _submit(),
                  decoration: InputDecoration(
                    hintText: 'Jawaban',
                    errorText: _error,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                ),
                const SizedBox(height: 20),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: _submit,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.primaryOrange,
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14),
                      ),
                      elevation: 0,
                    ),
                    child: Text(
                      'Lanjutkan',
                      style: AppTextStyles.button.copyWith(color: AppColors.white),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
