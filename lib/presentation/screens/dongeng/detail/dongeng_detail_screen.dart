import 'dart:async';
import 'dart:math' show max;

import 'package:arunika_app/data/models/response/dongeng_page.dart';
import 'package:arunika_app/data/models/response/dongeng_response.dart';
import 'package:arunika_app/presentation/screens/dongeng/detail/dongeng_detail_bloc.dart';
import 'package:arunika_app/presentation/screens/dongeng/detail/dongeng_detail_event.dart';
import 'package:arunika_app/presentation/screens/dongeng/detail/dongeng_detail_state.dart';
import 'package:arunika_app/presentation/screens/dongeng/detail/page_curl/page_curl.dart';
import 'package:arunika_app/presentation/screens/dongeng/detail/page_curl/page_turn_controller.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:just_audio/just_audio.dart';
import 'package:smooth_page_indicator/smooth_page_indicator.dart';
import 'package:arunika_app/core/media/media_cache.dart';

class DongengDetailScreen extends StatefulWidget {
  final DongengResponse dongeng;

  const DongengDetailScreen({super.key, required this.dongeng});

  @override
  State<DongengDetailScreen> createState() => _DongengDetailScreenState();
}

class _DongengDetailScreenState extends State<DongengDetailScreen> {
  @override
  void initState() {
    super.initState();
    SystemChrome.setPreferredOrientations([
      DeviceOrientation.landscapeLeft,
      DeviceOrientation.landscapeRight,
    ]);
    SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge);
  }

  @override
  void dispose() {
    SystemChrome.setPreferredOrientations([
      DeviceOrientation.portraitUp,
      DeviceOrientation.portraitDown,
    ]);
    SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: BlocBuilder<DongengDetailBloc, DongengDetailState>(
        builder: (context, state) {
          if (state.pages.isNotEmpty) {
            return _PageReaderView(state: state, dongeng: widget.dongeng);
          }
          return _NoContentView(dongeng: widget.dongeng);
        },
      ),
    );
  }
}

// ══════════════════════════════════════════════════════════════════════════════
// Landscape page reader
// ══════════════════════════════════════════════════════════════════════════════

class _PageReaderView extends StatefulWidget {
  final DongengDetailState state;
  final DongengResponse dongeng;

  const _PageReaderView({required this.state, required this.dongeng});

  @override
  State<_PageReaderView> createState() => _PageReaderViewState();
}

class _PageReaderViewState extends State<_PageReaderView> {
  bool _showSubtitle = true;
  final _curlKey = GlobalKey<PageCurlState>();

  late final AudioPlayer _audioPlayer = AudioPlayer();
  StreamSubscription<PlayerState>? _playerStateSub;
  bool _isPlaying = false;

  @override
  void initState() {
    super.initState();
    _playerStateSub = _audioPlayer.playerStateStream.listen((ps) {
      if (ps.processingState == ProcessingState.completed && mounted) {
        setState(() => _isPlaying = false);
      }
    });
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _precacheNeighbours();
  }

  @override
  void didUpdateWidget(_PageReaderView oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.state.currentPageIndex != widget.state.currentPageIndex) {
      _audioPlayer.stop();
      setState(() => _isPlaying = false);
      _precacheNeighbours();
    }
  }

  // So the page revealed under a curl is already drawn, not a spinner.
  void _precacheNeighbours() {
    final pages = widget.state.pages;
    final i = widget.state.currentPageIndex;
    for (final n in [i - 1, i + 1]) {
      if (n < 0 || n >= pages.length) continue;
      precacheImage(
        MediaCache.image(pages[n].imageUrl),
        context,
        onError: (_, __) {}, // the page shows its own error when reached
      );
    }
  }

  @override
  void dispose() {
    _playerStateSub?.cancel();
    _audioPlayer.dispose();
    super.dispose();
  }

  Future<void> _toggleAudio(String audioUrl) async {
    if (_isPlaying) {
      await _audioPlayer.stop();
      setState(() => _isPlaying = false);
    } else {
      setState(() => _isPlaying = true);
      try {
        await MediaCache.setAudioUrl(_audioPlayer, audioUrl);
        await _audioPlayer.play();
      } catch (_) {
        if (mounted) setState(() => _isPlaying = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final state = widget.state;
    final page = state.currentPage!;
    final totalPages = state.pages.length;
    final hasAudio = page.audioUrl.isNotEmpty;

    // Respect device safe-area insets so nav buttons are never clipped by
    // notches, rounded corners, or system UI on narrow screens.
    final safeArea = MediaQuery.of(context).padding;
    final leftInset = max(12.0, safeArea.left + 8.0);
    final rightInset = max(12.0, safeArea.right + 8.0);

    return Stack(
      children: [
        // ── Full-bleed image, turned with a page curl ─────────────────────
        Positioned.fill(
          child: PageCurl(
            key: _curlKey,
            pageCount: totalPages,
            index: state.currentPageIndex,
            pageBuilder: (_, i) => _PageImage(page: state.pages[i]),
            onTurned: (d) => context.read<DongengDetailBloc>().add(
              d == TurnDirection.forward ? NextPage() : PreviousPage(),
            ),
          ),
        ),

        // ── Top gradient — back button + title ────────────────────────────
        Positioned(
          top: 0,
          left: 0,
          right: 0,
          child: Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [
                  Colors.black.withValues(alpha: 0.55),
                  Colors.transparent,
                ],
              ),
            ),
            child: SafeArea(
              bottom: false,
              child: Padding(
                padding: const EdgeInsets.fromLTRB(0, 4, 16, 24),
                child: Row(
                  children: [
                    const BackButton(color: Colors.white),
                    Expanded(
                      child: Text(
                        widget.dongeng.title,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 15,
                          fontWeight: FontWeight.w600,
                          shadows: [
                            Shadow(color: Colors.black54, blurRadius: 6),
                          ],
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),

        // ── Left prev button ──────────────────────────────────────────────
        Positioned(
          left: leftInset,
          top: 0,
          bottom: 0,
          child: Center(
            child: _SideNavButton(
              icon: Icons.arrow_back_ios_rounded,
              enabled: !state.isFirstPage,
              onTap: () =>
                  _curlKey.currentState?.turn(TurnDirection.backward),
            ),
          ),
        ),

        // ── Right next button ─────────────────────────────────────────────
        Positioned(
          right: rightInset,
          top: 0,
          bottom: 0,
          child: Center(
            child: _SideNavButton(
              icon: Icons.arrow_forward_ios_rounded,
              enabled: !state.isLastPage,
              onTap: () => _curlKey.currentState?.turn(TurnDirection.forward),
            ),
          ),
        ),

        // ── Bottom: subtitle + controls ───────────────────────────────────
        Positioned(
          bottom: 0,
          left: 0,
          right: 0,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Subtitle overlay (toggleable, fades in/out)
              IgnorePointer(
                ignoring: !_showSubtitle,
                child: AnimatedOpacity(
                  opacity: _showSubtitle ? 1.0 : 0.0,
                  duration: const Duration(milliseconds: 250),
                  child: Container(
                    width: double.infinity,
                    color: Colors.black.withValues(alpha: 0.65),
                    padding: const EdgeInsets.symmetric(
                      horizontal: 72,
                      vertical: 8,
                    ),
                    child: AnimatedSwitcher(
                      duration: const Duration(milliseconds: 300),
                      child: Text(
                        page.text,
                        key: ValueKey(page.id),
                        textAlign: TextAlign.center,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 14,
                          height: 1.5,
                        ),
                      ),
                    ),
                  ),
                ),
              ),

              // Controls bar
              Container(
                color: Colors.black.withValues(alpha: 0.5),
                child: SafeArea(
                  top: false,
                  child: Padding(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 6,
                    ),
                    child: Row(
                      children: [
                        AnimatedSmoothIndicator(
                          activeIndex: state.currentPageIndex,
                          count: totalPages,
                          effect: const WormEffect(
                            dotWidth: 7,
                            dotHeight: 7,
                            activeDotColor: Colors.orange,
                            dotColor: Colors.white38,
                          ),
                        ),
                        const SizedBox(width: 10),
                        Text(
                          '${state.currentPageIndex + 1} / $totalPages',
                          style: const TextStyle(
                            color: Colors.white70,
                            fontSize: 11,
                          ),
                        ),
                        const Spacer(),
                        if (hasAudio) ...[
                          _ControlButton(
                            icon: _isPlaying
                                ? Icons.stop_rounded
                                : Icons.volume_up_rounded,
                            active: _isPlaying,
                            onTap: () => _toggleAudio(page.audioUrl),
                          ),
                          const SizedBox(width: 8),
                        ],
                        _ControlButton(
                          icon: _showSubtitle
                              ? Icons.subtitles_rounded
                              : Icons.subtitles_off_rounded,
                          active: _showSubtitle,
                          onTap: () =>
                              setState(() => _showSubtitle = !_showSubtitle),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

// ── One page's picture ────────────────────────────────────────────────────────

class _PageImage extends StatelessWidget {
  final DongengPage page;

  const _PageImage({required this.page});

  @override
  Widget build(BuildContext context) {
    return Image(
      image: MediaCache.image(page.imageUrl),
      width: double.infinity,
      height: double.infinity,
      fit: BoxFit.cover,
      loadingBuilder: (_, child, progress) => progress == null
          ? child
          : const ColoredBox(
              color: Colors.black,
              child: Center(
                child: CircularProgressIndicator(color: Colors.orange),
              ),
            ),
      errorBuilder: (_, __, ___) => Container(
        color: const Color(0xFFFFE0B2),
        child: const Icon(
          Icons.image_not_supported,
          size: 64,
          color: Colors.orange,
        ),
      ),
    );
  }
}

// ── Side navigation arrow ─────────────────────────────────────────────────────

class _SideNavButton extends StatelessWidget {
  final IconData icon;
  final bool enabled;
  final VoidCallback onTap;

  const _SideNavButton({
    required this.icon,
    required this.enabled,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return AnimatedOpacity(
      opacity: enabled ? 0.85 : 0.2,
      duration: const Duration(milliseconds: 200),
      child: GestureDetector(
        onTap: enabled ? onTap : null,
        child: Container(
          width: 44,
          height: 44,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: Colors.black.withValues(alpha: 0.45),
            border: Border.all(color: Colors.white24),
          ),
          child: Icon(icon, color: Colors.white, size: 20),
        ),
      ),
    );
  }
}

// ── Small icon button for the bottom bar ─────────────────────────────────────

class _ControlButton extends StatelessWidget {
  final IconData icon;
  final bool active;
  final VoidCallback onTap;

  const _ControlButton({
    required this.icon,
    required this.active,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(7),
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: active
              ? Colors.orange.withValues(alpha: 0.85)
              : Colors.white.withValues(alpha: 0.15),
        ),
        child: Icon(icon, color: Colors.white, size: 20),
      ),
    );
  }
}

// ══════════════════════════════════════════════════════════════════════════════
// Audio-only player — COMMENTED OUT (_PageReaderView handles all dongeng types)
// ══════════════════════════════════════════════════════════════════════════════

// class _AudioPlayerView extends StatefulWidget {
//   final DongengResponse dongeng;
//   const _AudioPlayerView({required this.dongeng});
//   @override
//   State<_AudioPlayerView> createState() => _AudioPlayerViewState();
// }
//
// class _AudioPlayerViewState extends State<_AudioPlayerView> {
//   late final AudioPlayer _player;
//   bool _hasError = false;
//   @override
//   void initState() { super.initState(); _player = AudioPlayer(); _initAudio(); }
//   Future<void> _initAudio() async {
//     try { await _player.setUrl(widget.dongeng.audioUrl); }
//     catch (_) { if (mounted) setState(() => _hasError = true); }
//   }
//   @override
//   void dispose() { _player.dispose(); super.dispose(); }
//   @override
//   Widget build(BuildContext context) { ... }
// }

// ══════════════════════════════════════════════════════════════════════════════
// No content fallback
// ══════════════════════════════════════════════════════════════════════════════

class _NoContentView extends StatelessWidget {
  final DongengResponse dongeng;

  const _NoContentView({required this.dongeng});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const BackButton(color: Colors.white),
          Image(
            image: MediaCache.image(dongeng.imageUrl),
            height: 140,
            fit: BoxFit.contain,
            errorBuilder: (_, __, ___) =>
                const Icon(Icons.book, size: 64, color: Colors.orange),
          ),
          const SizedBox(height: 16),
          Text(
            dongeng.title,
            style: const TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: Colors.orange,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 8),
          const Text(
            'Konten dongeng belum tersedia.',
            style: TextStyle(fontSize: 14, color: Colors.grey),
          ),
        ],
      ),
    );
  }
}
