import 'dart:math';
import 'package:arunika_app/core/storage/LocalProfileStorage.dart';
import 'package:arunika_app/data/models/response/tracing_item.dart';
import 'package:arunika_app/data/repositories/tracing_repository.dart';
import 'package:arunika_app/di/locator.dart';
import 'package:arunika_app/presentation/screens/tracing/tracing_exercise_bloc.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

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
      appBar: AppBar(title: Text('Jejak: ${widget.item.label}')),
      body: BlocConsumer<TracingExerciseBloc, TracingExerciseState>(
        listener: (ctx, state) {},
        builder: (ctx, state) {
          if (state is TracingExercisePassed) {
            return _ResultView(
              passed: true,
              score: state.score,
              onNext: () => Navigator.pop(context),
            );
          }
          if (state is TracingExerciseFailed) {
            return _ResultView(
              passed: false,
              score: state.score,
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
              Expanded(
                child: GestureDetector(
                  onPanUpdate: (d) =>
                      setState(() => _strokes.add(d.localPosition)),
                  child: CustomPaint(
                    painter: _TracingPainter(
                      strokes: _strokes,
                      guide: widget.item.guidePoints,
                    ),
                    child: Container(color: Colors.white),
                  ),
                ),
              ),
              Padding(
                padding: const EdgeInsets.all(16),
                child: Row(
                  children: [
                    Expanded(
                      child: OutlinedButton(
                        onPressed: () => setState(() => _strokes.clear()),
                        child: const Text('Hapus'),
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: ElevatedButton(
                        onPressed: _submit,
                        child: const Text('Selesai'),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}

class _TracingPainter extends CustomPainter {
  final List<Offset> strokes;
  final List<Map<String, double>> guide;

  _TracingPainter({required this.strokes, required this.guide});

  @override
  void paint(Canvas canvas, Size size) {
    // Draw guide path
    if (guide.isNotEmpty) {
      final guidePaint = Paint()
        ..color = Colors.grey.shade300
        ..strokeWidth = 4
        ..style = PaintingStyle.stroke;
      final path = Path();
      path.moveTo(guide[0]['x']!, guide[0]['y']!);
      for (int i = 1; i < guide.length; i++) {
        path.lineTo(guide[i]['x']!, guide[i]['y']!);
      }
      canvas.drawPath(path, guidePaint);
    }

    // Draw user strokes
    if (strokes.isNotEmpty) {
      final strokePaint = Paint()
        ..color = Colors.orange
        ..strokeWidth = 6
        ..strokeCap = StrokeCap.round
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

class _ResultView extends StatelessWidget {
  final bool passed;
  final int score;
  final VoidCallback onNext;
  const _ResultView({
    required this.passed,
    required this.score,
    required this.onNext,
  });

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            passed ? Icons.star_rounded : Icons.refresh,
            size: 80,
            color: passed ? Colors.amber : Colors.grey,
          ),
          const SizedBox(height: 16),
          Text(
            passed ? 'Hebat! Nilai: $score' : 'Coba lagi! Nilai: $score',
            style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 16),
          ElevatedButton(
            onPressed: onNext,
            child: Text(passed ? 'Lanjut' : 'Ulangi'),
          ),
        ],
      ),
    );
  }
}
