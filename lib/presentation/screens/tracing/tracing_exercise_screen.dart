import 'dart:math';
import 'package:arunika_app/constants/app_colors.dart';
import 'package:arunika_app/constants/app_text_styles.dart';
import 'package:arunika_app/core/storage/LocalProfileStorage.dart';
import 'package:arunika_app/data/models/response/tracing_item.dart';
import 'package:arunika_app/data/repositories/tracing_repository.dart';
import 'package:arunika_app/di/locator.dart';
import 'package:arunika_app/presentation/screens/tracing/tracing_exercise_bloc.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

class TracingExerciseScreen extends StatelessWidget {
  final TracingItem item;
  const TracingExerciseScreen({super.key, required this.item});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) =>
          TracingExerciseBloc(repository: locator<TracingRepository>()),
      child: _TracingExerciseView(item: item),
    );
  }
}

class _TracingExerciseView extends StatefulWidget {
  final TracingItem item;
  const _TracingExerciseView({required this.item});

  @override
  State<_TracingExerciseView> createState() => _TracingExerciseViewState();
}

class _TracingExerciseViewState extends State<_TracingExerciseView> {
  final List<Offset> _strokes = [];
  String? _childId;

  @override
  void initState() {
    super.initState();
    _loadChild();
  }

  Future<void> _loadChild() async {
    final profile = await LocalProfileStorage.get();
    if (profile != null && profile.children.isNotEmpty) {
      setState(() => _childId = profile.children.first.id);
      if (mounted) {
        context.read<TracingExerciseBloc>().add(
          LoadTracingExercise(
            item: widget.item,
            childId: profile.children.first.id,
          ),
        );
      }
    }
  }

  int _computeScore() {
    if (_strokes.isEmpty) return 0;
    final guide = widget.item.guidePoints;
    if (guide.isEmpty) return 100;
    int hits = 0;
    const threshold = 30.0;
    for (final pt in guide) {
      final gx = pt['x']!;
      final gy = pt['y']!;
      for (final s in _strokes) {
        final dist = sqrt(pow(s.dx - gx, 2) + pow(s.dy - gy, 2));
        if (dist < threshold) {
          hits++;
          break;
        }
      }
    }
    return ((hits / guide.length) * 100).round();
  }

  void _submit() {
    final score = _computeScore();
    context.read<TracingExerciseBloc>().add(
      SubmitTracingResult(score: score, passed: score >= 70),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFFFEDD5),
      body: DecoratedBox(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            colors: [Color(0xFFFFEDD5), AppColors.pageBackground],
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
          ),
        ),
        child: SafeArea(
          child: BlocConsumer<TracingExerciseBloc, TracingExerciseState>(
            listener: (ctx, state) {},
            builder: (ctx, state) {
              if (state is TracingExercisePassed) {
                return _ResultView(
                  passed: true,
                  score: state.score,
                  label: widget.item.label,
                  onNext: () => context.pop(),
                );
              }
              if (state is TracingExerciseFailed) {
                return _ResultView(
                  passed: false,
                  score: state.score,
                  label: widget.item.label,
                  onNext: () {
                    setState(() => _strokes.clear());
                    ctx.read<TracingExerciseBloc>().add(
                      LoadTracingExercise(
                        item: widget.item,
                        childId: _childId ?? '',
                      ),
                    );
                  },
                );
              }

              return Column(
                children: [
                  // ── Header ────────────────────────────────────────────
                  Padding(
                    padding: const EdgeInsets.fromLTRB(20, 20, 20, 0),
                    child: Row(
                      children: [
                        GestureDetector(
                          onTap: () => context.pop(),
                          child: Container(
                            padding: const EdgeInsets.all(10),
                            decoration: BoxDecoration(
                              color: AppColors.white,
                              borderRadius: BorderRadius.circular(12),
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.black.withValues(alpha: 0.06),
                                  blurRadius: 8,
                                  offset: const Offset(0, 2),
                                ),
                              ],
                            ),
                            child: const Icon(
                              Icons.arrow_back_ios_new_rounded,
                              size: 18,
                              color: AppColors.textDark,
                            ),
                          ),
                        ),
                        const SizedBox(width: 14),
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Jejak: ${widget.item.label}',
                              style: AppTextStyles.heading,
                            ),
                            Text(
                              'Ikuti jalur garis panduan',
                              style: AppTextStyles.caption.copyWith(
                                color: AppColors.textMedium,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 16),

                  // ── Canvas ────────────────────────────────────────────
                  Expanded(
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 20),
                      child: Container(
                        decoration: BoxDecoration(
                          color: AppColors.white,
                          borderRadius: BorderRadius.circular(24),
                          boxShadow: [
                            BoxShadow(
                              color: AppColors.primaryOrange.withValues(
                                alpha: 0.08,
                              ),
                              blurRadius: 16,
                              offset: const Offset(0, 4),
                            ),
                          ],
                        ),
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(24),
                          child: GestureDetector(
                            onPanUpdate: (d) =>
                                setState(() => _strokes.add(d.localPosition)),
                            child: CustomPaint(
                              painter: _TracingPainter(
                                strokes: _strokes,
                                guide: widget.item.guidePoints,
                              ),
                              child: Container(color: Colors.transparent),
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),

                  // ── Actions ───────────────────────────────────────────
                  Padding(
                    padding: const EdgeInsets.fromLTRB(20, 16, 20, 20),
                    child: Row(
                      children: [
                        Expanded(
                          child: OutlinedButton.icon(
                            onPressed: () => setState(() => _strokes.clear()),
                            icon: const Icon(Icons.refresh_rounded, size: 18),
                            label: const Text('Hapus'),
                            style: OutlinedButton.styleFrom(
                              foregroundColor: AppColors.primaryOrange,
                              side: const BorderSide(
                                color: AppColors.primaryOrange,
                              ),
                              padding: const EdgeInsets.symmetric(vertical: 14),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(14),
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(width: 14),
                        Expanded(
                          child: ElevatedButton.icon(
                            onPressed: _submit,
                            icon: const Icon(
                              Icons.check_circle_rounded,
                              size: 18,
                              color: Colors.white,
                            ),
                            label: const Text(
                              'Selesai',
                              style: TextStyle(color: Colors.white),
                            ),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: AppColors.primaryOrange,
                              padding: const EdgeInsets.symmetric(vertical: 14),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(14),
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              );
            },
          ),
        ),
      ),
    );
  }
}

// ── Tracing painter ────────────────────────────────────────────────────────────

class _TracingPainter extends CustomPainter {
  final List<Offset> strokes;
  final List<Map<String, double>> guide;

  _TracingPainter({required this.strokes, required this.guide});

  @override
  void paint(Canvas canvas, Size size) {
    // Guide path (dotted dots)
    if (guide.isNotEmpty) {
      final guidePaint = Paint()
        ..color = const Color(0xFFDDDDDD)
        ..strokeWidth = 6
        ..style = PaintingStyle.stroke
        ..strokeCap = StrokeCap.round;
      final path = Path();
      path.moveTo(guide[0]['x']!, guide[0]['y']!);
      for (int i = 1; i < guide.length; i++) {
        path.lineTo(guide[i]['x']!, guide[i]['y']!);
      }
      canvas.drawPath(path, guidePaint);

      // Start dot
      canvas.drawCircle(
        Offset(guide[0]['x']!, guide[0]['y']!),
        10,
        Paint()..color = AppColors.primaryOrange.withValues(alpha: 0.4),
      );
    }

    // User stroke
    if (strokes.isNotEmpty) {
      final strokePaint = Paint()
        ..color = AppColors.primaryOrange
        ..strokeWidth = 7
        ..strokeCap = StrokeCap.round
        ..strokeJoin = StrokeJoin.round
        ..style = PaintingStyle.stroke;
      final path = Path();
      path.moveTo(strokes[0].dx, strokes[0].dy);
      for (int i = 1; i < strokes.length; i++) {
        path.lineTo(strokes[i].dx, strokes[i].dy);
      }
      canvas.drawPath(path, strokePaint);
    }
  }

  @override
  bool shouldRepaint(_TracingPainter old) => true;
}

// ── Result view ────────────────────────────────────────────────────────────────

class _ResultView extends StatelessWidget {
  final bool passed;
  final int score;
  final String label;
  final VoidCallback onNext;

  const _ResultView({
    required this.passed,
    required this.score,
    required this.label,
    required this.onNext,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(32),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            padding: const EdgeInsets.all(28),
            decoration: BoxDecoration(
              color: passed
                  ? const Color(0xFF4CAF50).withValues(alpha: 0.10)
                  : AppColors.primaryOrange.withValues(alpha: 0.10),
              shape: BoxShape.circle,
            ),
            child: Icon(
              passed ? Icons.star_rounded : Icons.refresh_rounded,
              size: 72,
              color: passed ? const Color(0xFFFFCC00) : AppColors.primaryOrange,
            ),
          ),
          const SizedBox(height: 24),
          Text(
            passed ? 'Hebat! Nilai: $score' : 'Coba Lagi! Nilai: $score',
            style: AppTextStyles.heading,
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 8),
          Text(
            passed
                ? 'Kamu berhasil menelusuri "$label"!'
                : 'Terus berlatih ya!',
            style: AppTextStyles.body.copyWith(color: AppColors.textMedium),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 32),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: onNext,
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primaryOrange,
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
              ),
              child: Text(
                passed ? 'Lanjut' : 'Ulangi',
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
