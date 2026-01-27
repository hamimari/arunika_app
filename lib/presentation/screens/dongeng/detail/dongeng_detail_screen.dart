import 'package:arunika_app/data/models/response/dongeng_response.dart';
import 'package:arunika_app/presentation/screens/dongeng/detail/dongeng_detail_bloc.dart';
import 'package:arunika_app/presentation/screens/dongeng/detail/dongeng_detail_event.dart';
import 'package:arunika_app/presentation/screens/dongeng/detail/dongeng_detail_state.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

class DongengDetailScreen extends StatelessWidget {
  final DongengResponse dongeng;

  const DongengDetailScreen({
    super.key,
    required this.dongeng,
  });

  String _fmt(Duration d) {
    final m = d.inMinutes.remainder(60).toString().padLeft(2, '0');
    final s = d.inSeconds.remainder(60).toString().padLeft(2, '0');
    return '$m:$s';
  }

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => DongengDetailBloc(dongeng)
        ..add(LoadAudio(dongeng.audioUrl)),
      child: Scaffold(
        appBar: AppBar(
          leading: const BackButton(color: Colors.black),
          backgroundColor: Colors.white,
          elevation: 0,
          title: Text(dongeng.title),
        ),
        body: BlocBuilder<DongengDetailBloc, DongengDetailState>(
          builder: (context, state) {
            final maxSeconds =
            state.duration.inSeconds == 0 ? 1.0 : state.duration.inSeconds.toDouble();

            return Container(
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    Color(0xFFFFF4E6), // soft peach
                    Color(0xFFFFE0B2), // light orange
                  ],
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                ),
              ),
              child: SafeArea(
                child: Column(
                  children: [
                    const SizedBox(height: 24),

                    Container(
                      height: 220,
                      width: 220,
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(32),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.08),
                            blurRadius: 20,
                            offset: const Offset(0, 10),
                          ),
                        ],
                        image: DecorationImage(
                          image: NetworkImage(dongeng.imageUrl), // or AssetImage
                          fit: BoxFit.cover,
                        ),
                      ),
                    ),

                    const SizedBox(height: 24),

                    Text(
                      dongeng.title,
                      textAlign: TextAlign.center,
                      style: const TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.w700,
                        color: Colors.orange,
                      ),
                    ),

                    const SizedBox(height: 8),

                    Text(
                      "Dongeng Anak",
                      style: TextStyle(
                        fontSize: 14,
                        color: Colors.orange.shade700,
                      ),
                    ),

                    const SizedBox(height: 32),

                    Expanded(
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 32),
                        decoration: const BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.vertical(
                            top: Radius.circular(40),
                          ),
                        ),
                        child: Column(
                          children: [
                            Slider(
                              activeColor: Colors.orange,
                              min: 0,
                              max: maxSeconds,
                              value: state.position.inSeconds
                                  .clamp(0, state.duration.inSeconds)
                                  .toDouble(),
                              onChanged: (v) => context
                                  .read<DongengDetailBloc>()
                                  .add(SeekTo(Duration(seconds: v.toInt()))),
                            ),

                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Text(_fmt(state.position)),
                                Text(_fmt(state.duration)),
                              ],
                            ),

                            const Spacer(),

                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                              children: [
                                IconButton(
                                  iconSize: 28,
                                  icon: const Icon(Icons.replay_10),
                                  onPressed: () => context
                                      .read<DongengDetailBloc>()
                                      .add(Backward10()),
                                ),

                                CircleAvatar(
                                  radius: 36,
                                  backgroundColor: Colors.orange,
                                  child: IconButton(
                                    iconSize: 40,
                                    color: Colors.white,
                                    icon: Icon(
                                      state.isPlaying
                                          ? Icons.pause_rounded
                                          : Icons.play_arrow_rounded,
                                    ),
                                    onPressed: () => context
                                        .read<DongengDetailBloc>()
                                        .add(PlayPause()),
                                  ),
                                ),

                                IconButton(
                                  iconSize: 28,
                                  icon: const Icon(Icons.forward_10),
                                  onPressed: () => context
                                      .read<DongengDetailBloc>()
                                      .add(Forward10()),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            );
          },
        ),
      ),
    );
  }
}

