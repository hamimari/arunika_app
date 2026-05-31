import 'dart:async';
import 'package:flutter/material.dart';
import 'package:just_audio/just_audio.dart';
import 'package:arunika_app/constants/app_colors.dart';
import 'package:arunika_app/constants/app_text_styles.dart';
import 'package:arunika_app/data/models/response/ar_card_response.dart';
import 'package:arunika_app/presentation/screens/arscanner/ar_core_screen.dart';

class ArCardDetailScreen extends StatefulWidget {
  final ArCardResponse card;
  const ArCardDetailScreen({super.key, required this.card});

  @override
  State<ArCardDetailScreen> createState() => _ArCardDetailScreenState();
}

class _ArCardDetailScreenState extends State<ArCardDetailScreen> {
  late final AudioPlayer _audioPlayer;
  StreamSubscription<PlayerState>? _playerSubscription;
  bool _isPlaying = false;

  @override
  void initState() {
    super.initState();
    _audioPlayer = AudioPlayer();
    _playerSubscription = _audioPlayer.playerStateStream.listen((state) {
      if (mounted) {
        // Explicitly check processingState so the button snaps back to idle
        // when playback ends naturally (completed), not just when stopped.
        final isNowPlaying =
            state.playing && state.processingState != ProcessingState.completed;
        setState(() {
          _isPlaying = isNowPlaying;
        });
      }
    });
  }

  @override
  void dispose() {
    _playerSubscription?.cancel();
    _audioPlayer.dispose();
    super.dispose();
  }

  Color _parseBgColor(String? hex) {
    try {
      final h = (hex ?? '').replaceAll('#', '');
      if (h.length == 6) return Color(int.parse('FF$h', radix: 16));
    } catch (_) {}
    return const Color(0xFFFFF3E0);
  }

  Future<void> _toggleAudio() async {
    final audioUrl = widget.card.audioUrl;
    if (audioUrl == null || audioUrl.isEmpty) return;
    try {
      if (_isPlaying) {
        await _audioPlayer.stop();
      } else {
        await _audioPlayer.setUrl(audioUrl);
        await _audioPlayer.play();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Gagal memutar audio: $e')));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final card = widget.card;
    return Scaffold(
      backgroundColor: AppColors.pageBackground,
      appBar: AppBar(
        backgroundColor: AppColors.pageBackground,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(
            Icons.arrow_back_ios_rounded,
            color: AppColors.textDark,
          ),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          card.title ?? 'Detail Kartu AR',
          style: AppTextStyles.subheading,
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Top: card image — colored background + contain fit, matching card list
            ClipRRect(
              borderRadius: BorderRadius.circular(20),
              child: Container(
                width: double.infinity,
                height: 350,
                color: _parseBgColor(card.bgColor),
                child: card.imageUrl.isNotEmpty
                    ? Image.network(
                        card.imageUrl,
                        width: double.infinity,
                        height: 350,
                        fit: BoxFit.fitWidth,
                        errorBuilder: (_, __, ___) =>
                            _ImagePlaceholder(card: card),
                      )
                    : _ImagePlaceholder(card: card),
              ),
            ),
            const SizedBox(height: 20),

            // Middle: description
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: AppColors.white,
                borderRadius: BorderRadius.circular(16),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.04),
                    blurRadius: 8,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Fun Fact',
                    style: AppTextStyles.bodyLarge.copyWith(
                      fontWeight: FontWeight.w700,
                      color: AppColors.primaryOrange,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    card.description.isNotEmpty
                        ? card.description
                        : 'Deskripsi belum tersedia untuk kartu ini.',
                    style: AppTextStyles.body,
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),

            // Bottom: action buttons
            Builder(
              builder: (context) {
                final hasAudio =
                    card.audioUrl != null && card.audioUrl!.isNotEmpty;
                final arButton = ElevatedButton.icon(
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => ArCoreSurfacePlaceScreen(
                          modelUrl: card.fileUrl ?? '',
                          soundUrl: card.audioUrl,
                          showScanAgain: false,
                        ),
                      ),
                    );
                  },
                  icon: const Icon(Icons.view_in_ar_rounded),
                  label: const Text('Lihat AR'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.premiumPurple,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14),
                    ),
                  ),
                );
                if (!hasAudio) {
                  return SizedBox(width: double.infinity, child: arButton);
                }
                return Row(
                  children: [
                    Expanded(
                      child: ElevatedButton.icon(
                        onPressed: _toggleAudio,
                        icon: Icon(
                          _isPlaying
                              ? Icons.stop_rounded
                              : Icons.volume_up_rounded,
                        ),
                        label: Text(_isPlaying ? 'Hentikan' : 'Putar Suara'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.primaryOrange,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(14),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(child: arButton),
                  ],
                );
              },
            ),
          ],
        ),
      ),
    );
  }
}

class _ImagePlaceholder extends StatelessWidget {
  final ArCardResponse card;
  const _ImagePlaceholder({required this.card});

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 260,
      color: Colors.transparent,
      child: Center(
        child: Text(card.resolvedEmoji, style: const TextStyle(fontSize: 80)),
      ),
    );
  }
}
