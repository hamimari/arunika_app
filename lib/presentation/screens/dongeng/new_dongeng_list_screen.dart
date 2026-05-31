import 'package:arunika_app/constants/app_colors.dart';
import 'package:arunika_app/constants/app_strings.dart';
import 'package:arunika_app/constants/app_text_styles.dart';
import 'package:arunika_app/core/auth/auth_notifier.dart';
import 'package:arunika_app/data/models/response/dongeng_response.dart';
import 'package:arunika_app/di/locator.dart';
import 'package:arunika_app/presentation/screens/dongeng/dongeng_list_bloc.dart';
import 'package:arunika_app/presentation/screens/dongeng/dongeng_list_event.dart';
import 'package:arunika_app/presentation/screens/dongeng/dongeng_list_state.dart';
import 'package:arunika_app/presentation/screens/widgets/login_required_dialog.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

class NewDongengListScreen extends StatefulWidget {
  const NewDongengListScreen({super.key});

  @override
  State<NewDongengListScreen> createState() => _NewDongengListScreenState();
}

class _NewDongengListScreenState extends State<NewDongengListScreen> {
  bool _isSearching = false;
  final _searchController = TextEditingController();

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  void _startSearch() => setState(() => _isSearching = true);

  void _stopSearch() {
    setState(() => _isSearching = false);
    _searchController.clear();
    context.read<DongengListBloc>().add(SearchDongeng(''));
  }

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
        final isNavigating = state is DongengListNavigating;

        return Scaffold(
          backgroundColor: const Color(0xFFFFEDD5),
          body: DecoratedBox(
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                colors: [Color(0xFFFFEDD5), AppColors.pageBackground],
                begin: Alignment.topCenter,
                end: Alignment.center,
              ),
            ),
            child: Stack(
              children: [
                SafeArea(child: _buildBody(context, state)),
                if (isNavigating)
                  IgnorePointer(
                    child: Container(
                      color: Colors.black.withValues(alpha: 0.2),
                      child: const Center(
                        child: CircularProgressIndicator(
                          color: AppColors.primaryOrange,
                        ),
                      ),
                    ),
                  ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildSearchBar() {
    return Row(
      children: [
        Expanded(
          child: TextField(
            controller: _searchController,
            autofocus: true,
            onChanged: (v) =>
                context.read<DongengListBloc>().add(SearchDongeng(v)),
            decoration: InputDecoration(
              hintText: 'Cari dongeng...',
              hintStyle: AppTextStyles.body.copyWith(
                color: AppColors.textMedium,
              ),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(14),
                borderSide: BorderSide.none,
              ),
              filled: true,
              fillColor: AppColors.white,
              contentPadding: const EdgeInsets.symmetric(
                horizontal: 16,
                vertical: 12,
              ),
              prefixIcon: const Icon(
                Icons.search_rounded,
                color: AppColors.primaryOrange,
              ),
            ),
            style: AppTextStyles.body,
          ),
        ),
        const SizedBox(width: 8),
        GestureDetector(
          onTap: _stopSearch,
          child: Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: AppColors.white,
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Icon(
              Icons.close_rounded,
              color: AppColors.textDark,
              size: 20,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildTitle() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(AppStrings.dongengTitle, style: AppTextStyles.heading),
            const SizedBox(height: 4),
            Text(
              'Nikmati cerita seru yang penuh petualangan!',
              style: AppTextStyles.caption.copyWith(
                color: AppColors.textMedium,
              ),
            ),
          ],
        ),
        GestureDetector(
          onTap: _startSearch,
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
              Icons.search_rounded,
              color: AppColors.primaryOrange,
              size: 22,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildBody(BuildContext context, DongengListState state) {
    if (state is DongengListLoading) {
      return const Center(
        child: CircularProgressIndicator(color: AppColors.primaryOrange),
      );
    }

    if (state is DongengListError) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(
                Icons.error_outline,
                size: 64,
                color: AppColors.primaryOrange,
              ),
              const SizedBox(height: 16),
              Text(
                state.message,
                textAlign: TextAlign.center,
                style: AppTextStyles.body,
              ),
              const SizedBox(height: 24),
              ElevatedButton(
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
      return const Center(
        child: CircularProgressIndicator(color: AppColors.primaryOrange),
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Header with animated search toggle
        Padding(
          padding: const EdgeInsets.fromLTRB(20, 20, 20, 16),
          child: AnimatedSwitcher(
            duration: const Duration(milliseconds: 200),
            child: _isSearching ? _buildSearchBar() : _buildTitle(),
          ),
        ),

        Expanded(
          child: list.isEmpty
              ? Center(
                  child: Text(
                    _isSearching
                        ? 'Tidak ada dongeng yang cocok.'
                        : 'Belum ada dongeng tersedia.',
                    style: AppTextStyles.body.copyWith(
                      color: AppColors.lockGrey,
                    ),
                  ),
                )
              : _buildList(context, state, list),
        ),
      ],
    );
  }

  Widget _buildList(
    BuildContext context,
    DongengListState state,
    List<DongengResponse> list,
  ) {
    // In search mode, show a flat list. Normal mode: featured + list.
    if (_isSearching) {
      return ListView.builder(
        padding: const EdgeInsets.fromLTRB(20, 0, 20, 24),
        itemCount: list.length,
        itemBuilder: (_, i) {
          final story = list[i];
          final isSelected =
              state is DongengListNavigating && state.selectedId == story.id;
          return _StoryRow(
            dongeng: story,
            isLoading: isSelected,
            onTap: () => _onTap(context, story),
          );
        },
      );
    }

    // Normal mode: featured card + popular list
    final featured = list.first;
    final rest = list.length > 1 ? list.sublist(1) : <DongengResponse>[];

    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Featured card
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: _FeaturedCard(
              dongeng: featured,
              onTap: () => _onTap(context, featured),
            ),
          ),

          const SizedBox(height: 24),

          // Popular section header
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  AppStrings.dongengPopular,
                  style: AppTextStyles.subheading,
                ),
                TextButton(
                  onPressed: () {},
                  child: Text(
                    AppStrings.dongengSeeAll,
                    style: AppTextStyles.body.copyWith(
                      color: AppColors.primaryOrange,
                    ),
                  ),
                ),
              ],
            ),
          ),

          // Story list rows
          ListView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            padding: const EdgeInsets.fromLTRB(20, 0, 20, 24),
            itemCount: rest.length,
            itemBuilder: (_, i) {
              final story = rest[i];
              final isSelected =
                  state is DongengListNavigating &&
                  state.selectedId == story.id;
              return _StoryRow(
                dongeng: story,
                isLoading: isSelected,
                onTap: () => _onTap(context, story),
              );
            },
          ),
        ],
      ),
    );
  }

  void _onTap(BuildContext context, DongengResponse story) {
    if (story.isFree) {
      context.read<DongengListBloc>().add(DongengItemSelected(story));
    } else if (!locator<AuthNotifier>().isLoggedIn) {
      showLoginRequiredDialog(context, featureLabel: 'dongeng premium');
    } else {
      context.push('/premium');
    }
  }
}

// ── Featured Card ──────────────────────────────────────────────────────────────

class _FeaturedCard extends StatelessWidget {
  final DongengResponse dongeng;
  final VoidCallback onTap;

  const _FeaturedCard({required this.dongeng, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.10),
            blurRadius: 20,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(24),
        child: Stack(
          children: [
            // Cover image
            SizedBox(
              width: double.infinity,
              height: 200,
              child: Image.network(
                dongeng.imageUrl,
                fit: BoxFit.cover,
                errorBuilder: (_, __, ___) => Container(
                  color: AppColors.creamCard,
                  child: const Center(
                    child: Text('📖', style: TextStyle(fontSize: 64)),
                  ),
                ),
              ),
            ),

            // Gradient overlay
            Positioned.fill(
              child: Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      Colors.transparent,
                      AppColors.deepBrown.withValues(alpha: 0.85),
                    ],
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                  ),
                ),
              ),
            ),

            // Content
            Positioned(
              left: 16,
              right: 16,
              bottom: 16,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (!dongeng.isFree)
                    Container(
                      margin: const EdgeInsets.only(bottom: 8),
                      padding: const EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: AppColors.accentGold,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        AppStrings.badgePremium,
                        style: AppTextStyles.caption.copyWith(
                          fontWeight: FontWeight.w700,
                          color: AppColors.deepBrown,
                        ),
                      ),
                    ),
                  Text(
                    dongeng.title,
                    style: AppTextStyles.subheading.copyWith(
                      color: AppColors.white,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    '${dongeng.ageStart.toInt()}–${dongeng.ageEnd.toInt()} tahun · ${dongeng.duration}',
                    style: AppTextStyles.caption.copyWith(
                      color: AppColors.white.withValues(alpha: 0.8),
                    ),
                  ),
                  const SizedBox(height: 10),
                  SizedBox(
                    width: 160,
                    height: 44,
                    child: ElevatedButton(
                      onPressed: onTap,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.primaryOrange,
                        elevation: 0,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(14),
                        ),
                      ),
                      child: Text(
                        AppStrings.btnReadNow,
                        style: AppTextStyles.buttonSmall,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ── Story Row ─────────────────────────────────────────────────────────────────

class _StoryRow extends StatelessWidget {
  final DongengResponse dongeng;
  final bool isLoading;
  final VoidCallback onTap;

  const _StoryRow({
    required this.dongeng,
    required this.onTap,
    this.isLoading = false,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: AppColors.white,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.05),
              blurRadius: 8,
              offset: const Offset(0, 3),
            ),
          ],
        ),
        child: Row(
          children: [
            // Thumbnail
            ClipRRect(
              borderRadius: BorderRadius.circular(12),
              child: Image.network(
                dongeng.imageUrl,
                width: 64,
                height: 64,
                fit: BoxFit.cover,
                errorBuilder: (_, __, ___) => Container(
                  width: 64,
                  height: 64,
                  color: AppColors.creamCard,
                  child: const Center(
                    child: Text('📖', style: TextStyle(fontSize: 28)),
                  ),
                ),
              ),
            ),
            const SizedBox(width: 14),
            // Info
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    dongeng.title,
                    style: AppTextStyles.bodyLarge,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 4),
                  Text(
                    '${dongeng.ageStart.toInt()}–${dongeng.ageEnd.toInt()} tahun · ${dongeng.duration}',
                    style: AppTextStyles.caption,
                  ),
                ],
              ),
            ),
            const SizedBox(width: 8),
            // Lock / loading icon
            if (isLoading)
              const SizedBox(
                width: 20,
                height: 20,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  color: AppColors.primaryOrange,
                ),
              )
            else if (dongeng.isFree)
              const Icon(
                Icons.play_circle_fill_rounded,
                color: AppColors.primaryOrange,
                size: 28,
              )
            else
              const Icon(
                Icons.lock_rounded,
                color: AppColors.lockGrey,
                size: 24,
              ),
          ],
        ),
      ),
    );
  }
}
