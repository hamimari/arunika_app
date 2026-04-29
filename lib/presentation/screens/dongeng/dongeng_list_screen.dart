import 'package:arunika_app/data/models/response/dongeng_response.dart';
import 'package:arunika_app/presentation/screens/dongeng/dongeng_list_bloc.dart';
import 'package:arunika_app/presentation/screens/dongeng/dongeng_list_event.dart';
import 'package:arunika_app/presentation/screens/dongeng/dongeng_list_state.dart';
import 'package:arunika_app/presentation/screens/widgets/bottom_nav.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

class DongengListScreen extends StatelessWidget {
  const DongengListScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocConsumer<DongengListBloc, DongengListState>(
      buildWhen: (_, curr) => curr is! NavigateToDongengPlayer,
      listenWhen: (_, curr) => curr is NavigateToDongengPlayer,
      listener: (context, state) {
        if (state is NavigateToDongengPlayer) {
          context.push('/dongeng-player', extra: state.dongeng);
          context.read<DongengListBloc>().add(ResetDongengListNavigation());
        }
      },
      builder: (context, state) {
        final bool isNavigating = state is DongengListNavigating;

        return Scaffold(
          appBar: AppBar(
            leading: const BackButton(color: Colors.black),
            backgroundColor: Colors.white,
            elevation: 0,
            title: const Text(
              'Dongeng',
              style: TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.bold,
                color: Colors.orange,
              ),
            ),
          ),
          backgroundColor: const Color(0xFFFFFBF5),
          body: Stack(
            children: [
              SafeArea(child: _buildBody(context, state)),
              if (isNavigating)
                IgnorePointer(
                  child: Container(
                    color: Colors.black.withValues(alpha: 0.25),
                    child: const Center(
                      child: CircularProgressIndicator(color: Colors.orange),
                    ),
                  ),
                ),
            ],
          ),
          bottomNavigationBar: const BottomNav(currentIndex: 1),
        );
      },
    );
  }

  Widget _buildBody(BuildContext context, DongengListState state) {
    if (state is DongengListLoading) {
      return const Center(
        child: CircularProgressIndicator(color: Colors.orange),
      );
    }

    if (state is DongengListError) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.error_outline, size: 64, color: Colors.orange),
              const SizedBox(height: 16),
              Text(
                state.message,
                textAlign: TextAlign.center,
                style: const TextStyle(fontSize: 16),
              ),
              const SizedBox(height: 24),
              ElevatedButton(
                style: ElevatedButton.styleFrom(backgroundColor: Colors.orange),
                onPressed: () =>
                    context.read<DongengListBloc>().add(LoadDongengList()),
                child: const Text('Coba Lagi'),
              ),
            ],
          ),
        ),
      );
    }

    final List<DongengResponse> list;
    if (state is DongengListLoaded) {
      list = state.dongengList;
    } else if (state is DongengListNavigating) {
      list = state.dongengList;
    } else {
      return const Center(child: CircularProgressIndicator(color: Colors.orange));
    }

    if (list.isEmpty) {
      return const Center(
        child: Text(
          'Belum ada dongeng tersedia.',
          style: TextStyle(fontSize: 16, color: Colors.grey),
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
      itemCount: list.length,
      itemBuilder: (context, index) {
        final story = list[index];
        final bool isSelected = state is DongengListNavigating &&
            state.selectedId == story.id;
        return Padding(
          padding: const EdgeInsets.only(bottom: 16),
          child: Material(
            color: Colors.transparent,
            child: InkWell(
              borderRadius: BorderRadius.circular(12),
              onTap: state is DongengListNavigating
                  ? null
                  : () => context
                        .read<DongengListBloc>()
                        .add(DongengItemSelected(story)),
              child: _StoryCard(dongeng: story, isLoading: isSelected),
            ),
          ),
        );
      },
    );
  }
}

// ── Story card ─────────────────────────────────────────────────────────────────

class _StoryCard extends StatelessWidget {
  final DongengResponse dongeng;
  final bool isLoading;

  const _StoryCard({required this.dongeng, this.isLoading = false});

  @override
  Widget build(BuildContext context) {
    final labelColor = dongeng.isFree ? Colors.green : Colors.orange;

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: const [BoxShadow(color: Colors.black12, blurRadius: 4)],
      ),
      padding: const EdgeInsets.all(12),
      child: Row(
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(28),
            child: Image.network(
              dongeng.imageUrl,
              width: 56,
              height: 56,
              fit: BoxFit.cover,
              errorBuilder: (_, __, ___) => CircleAvatar(
                radius: 28,
                backgroundColor: labelColor.withValues(alpha: 0.2),
                child: Icon(Icons.book, color: labelColor),
              ),
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  dongeng.title,
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: labelColor,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  '${dongeng.ageStart.toInt()}–${dongeng.ageEnd.toInt()} tahun · ${dongeng.duration}',
                  style: const TextStyle(color: Colors.grey, fontSize: 13),
                ),
              ],
            ),
          ),
          if (isLoading)
            const SizedBox(
              width: 20,
              height: 20,
              child: CircularProgressIndicator(strokeWidth: 2, color: Colors.orange),
            )
          else
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: labelColor,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(
                dongeng.isFree ? 'FREE' : 'PAID',
                style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                  fontSize: 10,
                ),
              ),
            ),
        ],
      ),
    );
  }
}
