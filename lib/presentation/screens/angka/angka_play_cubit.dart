import 'dart:async';

import 'package:arunika_app/core/angka/question_generator.dart';
import 'package:arunika_app/core/logger/app_logger.dart';
import 'package:arunika_app/data/models/response/angka_response.dart';
import 'package:arunika_app/data/repositories/angka_repository.dart';
import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

enum AngkaPlayPhase {
  loading,
  answering,

  /// Right answer: the success pop-up.
  success,

  /// Wrong: the retry pop-up. The child tries until the answer is right.
  retry,
  completing,

  /// The level is over: the stars pop-up.
  done,

  /// The level needs Akses Premium (402).
  premiumLocked,

  /// The prerequisite isn't completed (409).
  prerequisiteLocked,
  error,
}

class AngkaPlayState extends Equatable {
  final AngkaPlayPhase phase;
  final AngkaSession? session;
  final List<AngkaQuestion> questions;

  /// The current question (0-based).
  final int index;

  /// What the child has typed (at most 2 digits; "07" reads as 7).
  final String input;

  /// Tries on the current question so far.
  final List<int> tries;

  /// Questions answered right on the first try (the header's star count).
  final int firstCorrect;

  /// Pictures the child has tapped, in tap order (indexes into points).
  final List<int> marks;

  /// The answer just checked, for the pop-ups.
  final int? lastAnswer;
  final AngkaCompleteResult? result;

  /// True when [result] was computed on the device because complete failed.
  final bool provisional;

  const AngkaPlayState({
    this.phase = AngkaPlayPhase.loading,
    this.session,
    this.questions = const [],
    this.index = 0,
    this.input = '',
    this.tries = const [],
    this.firstCorrect = 0,
    this.marks = const [],
    this.lastAnswer,
    this.result,
    this.provisional = false,
  });

  AngkaQuestion? get question =>
      index < questions.length ? questions[index] : null;

  AngkaObject? get object {
    final q = question;
    return q == null ? null : session?.objects[q.objectId];
  }

  /// The question's object name ("apel"), for the copy.
  String get benda => object?.name ?? '';

  /// Whether the last check was right on the first try ("+1 bintang").
  bool get firstTry => tries.length == 1;

  AngkaPlayState copyWith({
    AngkaPlayPhase? phase,
    AngkaSession? session,
    List<AngkaQuestion>? questions,
    int? index,
    String? input,
    List<int>? tries,
    int? firstCorrect,
    List<int>? marks,
    int? lastAnswer,
    AngkaCompleteResult? result,
    bool? provisional,
  }) => AngkaPlayState(
    phase: phase ?? this.phase,
    session: session ?? this.session,
    questions: questions ?? this.questions,
    index: index ?? this.index,
    input: input ?? this.input,
    tries: tries ?? this.tries,
    firstCorrect: firstCorrect ?? this.firstCorrect,
    marks: marks ?? this.marks,
    lastAnswer: lastAnswer ?? this.lastAnswer,
    result: result ?? this.result,
    provisional: provisional ?? this.provisional,
  );

  @override
  List<Object?> get props => [
    phase,
    session,
    questions,
    index,
    input,
    tries,
    firstCorrect,
    marks,
    lastAnswer,
    result,
    provisional,
  ];
}

/// One Hitung Benda level: starts or resumes the session, checks answers on
/// the device, records every try on the server in order, and completes.
class AngkaPlayCubit extends Cubit<AngkaPlayState> {
  final AngkaRepository repository;
  final String childId;
  final String levelId;

  /// Tries are sent one after another: the server refuses a try whose
  /// previous one it hasn't seen.
  Future<void> _writes = Future.value();

  AngkaPlayCubit({
    required this.repository,
    required this.childId,
    required this.levelId,
  }) : super(const AngkaPlayState());

  /// Starts the level, or resumes its session at the first unfinished
  /// question. [restart] starts over ("Main lagi").
  Future<void> start({bool restart = false}) async {
    emit(const AngkaPlayState());
    try {
      final s = await repository.startSession(
        childId,
        levelId,
        restart: restart,
      );
      final qs = s.questions();
      var first = 0;
      var index = 0;
      final answers = {for (final a in s.answers) a.q: a.tries};
      for (var i = 0; i < qs.length; i++) {
        final tries = answers[i + 1] ?? const <int>[];
        if (tries.isNotEmpty && tries.first == qs[i].count) first++;
        if (tries.contains(qs[i].count)) {
          index = i + 1;
        } else {
          break;
        }
      }
      if (isClosed) return;
      final resumeTries = index < qs.length
          ? (answers[index + 1] ?? [])
          : <int>[];
      emit(
        AngkaPlayState(
          phase: AngkaPlayPhase.answering,
          session: s,
          questions: qs,
          index: index,
          tries: resumeTries,
          firstCorrect: first,
        ),
      );
      // Every question answered but complete never reached the server.
      if (index >= qs.length) await _complete();
    } on AngkaLockedException {
      if (!isClosed) {
        emit(const AngkaPlayState(phase: AngkaPlayPhase.premiumLocked));
      }
    } on AngkaLevelLockedException {
      if (!isClosed) {
        emit(const AngkaPlayState(phase: AngkaPlayPhase.prerequisiteLocked));
      }
    } catch (e) {
      AppLogger.warning('Failed to start Angka level', name: 'Angka', error: e);
      if (!isClosed) emit(const AngkaPlayState(phase: AngkaPlayPhase.error));
    }
  }

  /// Appends a digit; the box holds at most two.
  void type(int digit) {
    if (state.phase != AngkaPlayPhase.answering || state.input.length >= 2) {
      return;
    }
    emit(state.copyWith(input: '${state.input}$digit'));
  }

  void backspace() {
    if (state.phase != AngkaPlayPhase.answering || state.input.isEmpty) return;
    emit(
      state.copyWith(input: state.input.substring(0, state.input.length - 1)),
    );
  }

  /// Marks picture [point] with the next number. Returns that number, or
  /// null when it was already marked.
  int? mark(int point) {
    if (state.phase != AngkaPlayPhase.answering ||
        state.marks.contains(point)) {
      return null;
    }
    final marks = [...state.marks, point];
    emit(state.copyWith(marks: marks));
    return marks.length;
  }

  /// "Periksa": checks the typed answer on the device and records the try.
  void check() {
    final q = state.question;
    if (state.phase != AngkaPlayPhase.answering ||
        state.input.isEmpty ||
        q == null) {
      return;
    }
    final answer = int.parse(state.input);
    final tries = [...state.tries, answer];
    _record(state.index + 1, tries.length, answer);
    final right = answer == q.count;
    final AngkaPlayPhase phase;
    var first = state.firstCorrect;
    if (right) {
      if (tries.length == 1) first++;
      phase = AngkaPlayPhase.success;
    } else {
      phase = AngkaPlayPhase.retry;
    }
    emit(
      state.copyWith(
        phase: phase,
        tries: tries,
        firstCorrect: first,
        lastAnswer: answer,
      ),
    );
  }

  void _record(int q, int attempt, int answer) {
    final session = state.session!;
    _writes = _writes.then(
      (_) => repository
          .recordTry(
            childId,
            session.id,
            q: q,
            attempt: attempt,
            answer: answer,
          )
          .catchError((Object e) {
            AppLogger.warning('Angka try not saved', name: 'Angka', error: e);
          }),
    );
  }

  /// "Coba lagi": back to the number pad with an empty box.
  void tryAgain() {
    if (state.phase != AngkaPlayPhase.retry) return;
    emit(state.copyWith(phase: AngkaPlayPhase.answering, input: ''));
  }

  /// "Soal berikutnya": the next question, or completing the level.
  Future<void> next() async {
    if (state.phase != AngkaPlayPhase.success) return;
    final index = state.index + 1;
    emit(
      AngkaPlayState(
        phase: AngkaPlayPhase.answering,
        session: state.session,
        questions: state.questions,
        index: index,
        firstCorrect: state.firstCorrect,
      ),
    );
    if (index >= state.questions.length) await _complete();
  }

  Future<void> _complete() async {
    final session = state.session!;
    emit(state.copyWith(phase: AngkaPlayPhase.completing));
    await _writes;
    try {
      final r = await repository.complete(childId, session.id);
      if (!isClosed) {
        emit(state.copyWith(phase: AngkaPlayPhase.done, result: r));
      }
    } catch (e) {
      AppLogger.warning('Angka level not completed', name: 'Angka', error: e);
      if (isClosed) return;
      final stars = session.content.starsFor(state.firstCorrect);
      emit(
        state.copyWith(
          phase: AngkaPlayPhase.done,
          provisional: true,
          result: AngkaCompleteResult(
            stars: stars,
            firstCorrect: state.firstCorrect,
            bestStars: stars,
          ),
        ),
      );
    }
  }
}
