import 'dart:async';

import 'package:arunika_app/constants/app_colors.dart';
import 'package:arunika_app/constants/app_strings.dart';
import 'package:arunika_app/constants/app_text_styles.dart';
import 'package:arunika_app/data/models/response/angka_response.dart';
import 'package:arunika_app/data/repositories/angka_repository.dart';
import 'package:arunika_app/presentation/screens/angka/angka_cubit.dart';
import 'package:arunika_app/presentation/screens/angka/angka_widgets.dart';
import 'package:arunika_app/presentation/screens/huruf/huruf_audio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

/// A Kenal Angka card: the numeral, its name, and that many objects. The
/// speaker says the number, then lights the objects one by one as they are
/// counted aloud. Nothing plays until the child taps it.
class AngkaNumberScreen extends StatefulWidget {
  final int value;

  /// Audio player; tests pass a fake.
  final HurufAudio Function()? audioFactory;

  const AngkaNumberScreen({super.key, required this.value, this.audioFactory});

  @override
  State<AngkaNumberScreen> createState() => _AngkaNumberScreenState();
}

class _AngkaNumberScreenState extends State<AngkaNumberScreen> {
  /// Time between counted objects.
  static const step = Duration(milliseconds: 700);

  late final HurufAudio _audio =
      (widget.audioFactory ?? JustAudioHurufAudio.new)();
  late int _value = widget.value;
  AngkaNumberCard? _card;
  bool _failed = false;

  /// How many objects are lit: all of them until the speaker is tapped,
  /// then one more per counted number.
  int _lit = 0;
  Timer? _timer;

  AngkaCubit get _cubit => context.read<AngkaCubit>();

  @override
  void initState() {
    super.initState();
    _load();
  }

  @override
  void dispose() {
    _timer?.cancel();
    _audio.dispose();
    super.dispose();
  }

  Future<void> _load() async {
    _timer?.cancel();
    setState(() {
      _card = null;
      _failed = false;
      _lit = 0;
    });
    try {
      final card = await _cubit.number(_value);
      if (!mounted) return;
      setState(() {
        _card = card;
        _lit = card.value;
      });
    } on AngkaLockedException {
      if (mounted) Navigator.of(context).maybePop();
    } catch (_) {
      if (mounted) setState(() => _failed = true);
    }
  }

  /// Says the number, then counts the objects aloud.
  void _play() {
    final card = _card;
    if (card == null) return;
    _timer?.cancel();
    setState(() => _lit = 0);
    _audio.play(card.audioUrl);
    void next() {
      if (!mounted || _lit >= card.value) return;
      setState(() => _lit++);
      final url = card.countAudio[_lit];
      if (url != null) _audio.play(url);
      _timer = Timer(step, next);
    }

    _timer = Timer(const Duration(milliseconds: 900), next);
  }

  /// The neighbouring number in the grid, if it is open to this account.
  AngkaManifestNumber? _neighbour(int delta) {
    final numbers = _cubit.state.numbers;
    final i = numbers.indexWhere((n) => n.value == _value);
    final j = i + delta;
    if (i < 0 || j < 0 || j >= numbers.length) return null;
    return numbers[j];
  }

  void _go(int delta) {
    final n = _neighbour(delta);
    if (n == null) return;
    if (n.locked) {
      openAngkaPaywall(context);
      return;
    }
    _value = n.value;
    _load();
  }

  @override
  Widget build(BuildContext context) {
    final (fg, edge) = AngkaColors.numeral(_value);
    final card = _card;
    return Scaffold(
      backgroundColor: AppColors.warmPage,
      body: SafeArea(
        bottom: false,
        child: ListView(
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
          children: [
            Row(
              children: [
                AngkaSquareButton(
                  icon: Icons.chevron_left_rounded,
                  label: 'Kembali',
                  onPressed: () => Navigator.of(context).maybePop(),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Text(
                    AppStrings.angkaKenalTitle,
                    style: AppTextStyles.displayLarge,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),
            if (_failed)
              Padding(
                padding: const EdgeInsets.only(top: 60),
                child: Column(
                  children: [
                    Text(
                      AppStrings.angkaLoadError,
                      style: AppTextStyles.body.copyWith(
                        color: AppColors.textMedium,
                      ),
                    ),
                    const SizedBox(height: 12),
                    OutlinedButton(
                      onPressed: _load,
                      child: const Text(AppStrings.hurufRetry),
                    ),
                  ],
                ),
              )
            else if (card == null)
              const Padding(
                padding: EdgeInsets.only(top: 80),
                child: Center(
                  child: CircularProgressIndicator(color: AppColors.ctaRust),
                ),
              )
            else ...[
              Container(
                padding: const EdgeInsets.fromLTRB(16, 20, 16, 20),
                decoration: BoxDecoration(
                  color: AppColors.white,
                  borderRadius: BorderRadius.circular(28),
                  border: Border(bottom: BorderSide(color: edge, width: 6)),
                ),
                child: Column(
                  children: [
                    Semantics(
                      label: 'Angka ${card.value}, ${card.name}',
                      excludeSemantics: true,
                      child: Column(
                        children: [
                          Text(
                            '${card.value}',
                            style: AppTextStyles.displayLarge.copyWith(
                              fontSize: 96,
                              height: 1.1,
                              color: fg,
                            ),
                          ),
                          Text(
                            card.name,
                            style: AppTextStyles.heading.copyWith(
                              fontSize: 22,
                              color: fg,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 18),
                    Wrap(
                      alignment: WrapAlignment.center,
                      spacing: 10,
                      runSpacing: 10,
                      children: [
                        for (var i = 0; i < card.value; i++)
                          _CountedObject(
                            key: ValueKey('angka-count-$i'),
                            url: card.object?.imageUrl ?? '',
                            number: i + 1,
                            lit: i < _lit,
                          ),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 18),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  AngkaSquareButton(
                    icon: Icons.chevron_left_rounded,
                    label: AppStrings.angkaPrevious,
                    onPressed: () => _go(-1),
                  ),
                  const SizedBox(width: 16),
                  AngkaSpeakerButton(
                    key: const ValueKey('angka-number-replay'),
                    label: AppStrings.angkaReplay,
                    onPressed: _play,
                  ),
                  const SizedBox(width: 16),
                  AngkaSquareButton(
                    icon: Icons.chevron_right_rounded,
                    label: AppStrings.angkaNext,
                    onPressed: () => _go(1),
                  ),
                ],
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class _CountedObject extends StatelessWidget {
  final String url;
  final int number;
  final bool lit;

  const _CountedObject({
    super.key,
    required this.url,
    required this.number,
    required this.lit,
  });

  @override
  Widget build(BuildContext context) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 200),
      width: 64,
      height: 76,
      decoration: BoxDecoration(
        color: lit ? AngkaColors.peach : const Color(0xFFF6F2EE),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          AnimatedOpacity(
            duration: const Duration(milliseconds: 200),
            opacity: lit ? 1 : 0.35,
            child: AngkaPicture(url: url, size: 44),
          ),
          Text(
            lit ? '$number' : ' ',
            style: AppTextStyles.caption.copyWith(
              color: AngkaColors.blue,
              fontWeight: FontWeight.w800,
            ),
          ),
        ],
      ),
    );
  }
}
