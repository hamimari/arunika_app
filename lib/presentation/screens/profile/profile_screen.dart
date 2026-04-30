import 'dart:math';

import 'package:arunika_app/core/storage/LocalProfileStorage.dart';
import 'package:arunika_app/core/storage/SecureStorageToken.dart';
import 'package:arunika_app/data/models/response/badge_item.dart';
import 'package:arunika_app/data/models/response/growth_record.dart';
import 'package:arunika_app/presentation/screens/badge/badge_gallery_screen.dart';
import 'package:arunika_app/data/repositories/ar_repository.dart';
import 'package:arunika_app/data/repositories/badge_repository.dart';
import 'package:arunika_app/data/repositories/growth_repository.dart';
import 'package:arunika_app/di/locator.dart';
import 'package:arunika_app/presentation/screens/badge/badge_bloc.dart';
import 'package:arunika_app/presentation/screens/growth/growth_bloc.dart';
import 'package:arunika_app/presentation/screens/qrscanner/qr_scanner.dart';
import 'package:arunika_app/presentation/screens/qrscanner/qr_scanner_bloc.dart';
import 'package:arunika_app/presentation/screens/profile/child_form.dart';
import 'package:arunika_app/presentation/screens/profile/profile_bloc.dart';
import 'package:arunika_app/presentation/screens/profile/profile_event.dart';
import 'package:arunika_app/presentation/screens/profile/profile_state.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:iconsax/iconsax.dart';

import '../widgets/bottom_nav.dart';

class ProfileScreen extends StatelessWidget {
  const ProfileScreen({super.key});

  void _openEditModal(BuildContext context) {
    final profileBloc = context.read<ProfileBloc>();
    final child = profileBloc.state.user?.children.isNotEmpty == true
        ? profileBloc.state.user!.children.first
        : null;

    if (child == null) return;

    profileBloc.add(
      ChildPrefilled(
        name: child.name,
        gender: child.gender,
        birthDate: DateTime.parse(child.dateOfBirth),
      ),
    );

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      isDismissible: true,
      enableDrag: true,
      builder: (_) {
        return BlocProvider.value(
          value: profileBloc,
          child: _EditProfileSheet(profileBloc: profileBloc),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFFFFBF5),
      bottomNavigationBar: const BottomNav(currentIndex: 1),
      floatingActionButton: Container(
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          boxShadow: [
            BoxShadow(
              color: Colors.orange.withValues(alpha: 0.35),
              blurRadius: 18,
              offset: const Offset(0, 8),
            ),
          ],
        ),
        child: FloatingActionButton(
          elevation: 0,
          backgroundColor: Colors.orange,
          onPressed: () {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (_) => BlocProvider(
                  create: (_) =>
                      QRScannerBloc(repository: locator<ArRepository>()),
                  child: QRScannerPage(),
                ),
              ),
            );
          },
          child: const Icon(Iconsax.scan, size: 30),
        ),
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.centerDocked,
      body: SafeArea(
        child: BlocBuilder<ProfileBloc, ProfileState>(
          builder: (context, state) {
            final user = state.user;
            final child = user?.children.isNotEmpty == true
                ? user!.children.first
                : null;
            final ageText = child != null
                ? '${calculateAge(child.dateOfBirth)} Tahun'
                : '-';
            final parentName = user?.name ?? '-';

            return Column(
              children: [
                // ── Header ────────────────────────────────────────────────────
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.fromLTRB(20, 24, 20, 20),
                  decoration: const BoxDecoration(
                    gradient: LinearGradient(
                      colors: [Color(0xFFFFF4E6), Color(0xFFFFE0B2)],
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                    ),
                    borderRadius: BorderRadius.only(
                      bottomLeft: Radius.circular(28),
                      bottomRight: Radius.circular(28),
                    ),
                  ),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Avatar
                      CircleAvatar(
                        radius: 32,
                        backgroundColor: Colors.orange.shade200,
                        backgroundImage: child != null
                            ? NetworkImage(
                                'https://api.dicebear.com/7.x/bottts/png?seed=${child.name}',
                              )
                            : null,
                        child: child == null
                            ? const Icon(
                                Icons.child_care,
                                color: Colors.white,
                                size: 28,
                              )
                            : null,
                      ),
                      const SizedBox(width: 14),
                      // Name + age + badge
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              child?.name ?? '-',
                              style: const TextStyle(
                                fontSize: 22,
                                fontWeight: FontWeight.bold,
                                color: Color(0xFF6D4C41),
                              ),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              ageText,
                              style: const TextStyle(
                                fontSize: 14,
                                color: Color(0xFF8D6E63),
                              ),
                            ),
                            const SizedBox(height: 6),
                            // Badge level chip
                            _BadgeLevelChip(),
                          ],
                        ),
                      ),
                      // Edit button
                      GestureDetector(
                        onTap: () => _openEditModal(context),
                        child: Container(
                          padding: const EdgeInsets.all(10),
                          decoration: BoxDecoration(
                            color: Colors.orange.withValues(alpha: 0.15),
                            shape: BoxShape.circle,
                          ),
                          child: const Icon(
                            Icons.edit_rounded,
                            color: Colors.orange,
                            size: 20,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 20),

                // ── Body ──────────────────────────────────────────────────────
                Expanded(
                  child: ListView(
                    padding: const EdgeInsets.symmetric(horizontal: 20),
                    children: [
                      // ── User info cards ────────────────────────────────────
                      _InfoCard(
                        icon: Iconsax.user,
                        label: 'Orang Tua',
                        value: parentName,
                      ),
                      const SizedBox(height: 12),
                      _InfoCard(
                        icon: Iconsax.sms,
                        label: 'Email',
                        value: user?.emailAddress ?? '-',
                      ),
                      const SizedBox(height: 12),
                      _InfoCard(
                        icon: Iconsax.call,
                        label: 'Nomor Telepon',
                        value: user?.phoneNumber ?? '-',
                      ),
                      const SizedBox(height: 12),
                      _InfoCard(
                        icon: Iconsax.location,
                        label: 'Kota',
                        value: user?.city ?? '-',
                      ),
                      const SizedBox(height: 12),
                      _InfoCard(
                        icon: Iconsax.home,
                        label: 'Alamat',
                        value: user?.address ?? '-',
                      ),
                      const SizedBox(height: 28),

                      // ── Growth Charts ──────────────────────────────────────
                      if (child != null) ...[
                        _GrowthChartsSection(
                          childId: child.id,
                          dateOfBirth: child.dateOfBirth,
                          gender: child.gender,
                        ),
                        const SizedBox(height: 28),
                      ],

                      // ── Badge Gallery ──────────────────────────────────────
                      _BadgeGallerySection(),
                      const SizedBox(height: 24),

                      // ── Logout ─────────────────────────────────────────────
                      SizedBox(
                        width: double.infinity,
                        child: OutlinedButton.icon(
                          onPressed: () async {
                            await SecureTokenStorage.clear();
                            await LocalProfileStorage.clear();
                            if (context.mounted) context.go('/signin');
                          },
                          icon: const Icon(
                            Iconsax.logout,
                            color: Colors.orange,
                          ),
                          label: const Text(
                            'Keluar',
                            style: TextStyle(
                              color: Colors.orange,
                              fontWeight: FontWeight.w600,
                              fontSize: 16,
                            ),
                          ),
                          style: OutlinedButton.styleFrom(
                            padding: const EdgeInsets.symmetric(vertical: 14),
                            side: const BorderSide(
                              color: Colors.orange,
                              width: 1.5,
                            ),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(16),
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(height: 24),
                    ],
                  ),
                ),
              ],
            );
          },
        ),
      ),
    );
  }
}

// ── Badge level chip (header) ──────────────────────────────────────────────────

class _BadgeLevelChip extends StatelessWidget {
  const _BadgeLevelChip();

  void _showBadgeInfo(BuildContext context, List<BadgeItem> badges) {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Row(
          children: [
            Icon(Icons.emoji_events_rounded, color: Colors.orange),
            SizedBox(width: 8),
            Text(
              'Sistem Lencana',
              style: TextStyle(
                fontSize: 17,
                fontWeight: FontWeight.bold,
                color: Color(0xFF6D4C41),
              ),
            ),
          ],
        ),
        content: SizedBox(
          width: 280,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: badges.map((b) {
              return Padding(
                padding: const EdgeInsets.symmetric(vertical: 6),
                child: Row(
                  children: [
                    Icon(
                      b.earned
                          ? Icons.emoji_events_rounded
                          : Icons.lock_rounded,
                      color: b.earned ? Colors.orange : Colors.grey.shade400,
                      size: 20,
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            b.level,
                            style: TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.w600,
                              color: b.earned
                                  ? const Color(0xFF6D4C41)
                                  : Colors.grey.shade500,
                            ),
                          ),
                          Text(
                            '${b.progress}/${b.threshold} aktivitas',
                            style: TextStyle(
                              fontSize: 11,
                              color: Colors.grey.shade500,
                            ),
                          ),
                        ],
                      ),
                    ),
                    if (b.earned)
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 6,
                          vertical: 2,
                        ),
                        decoration: BoxDecoration(
                          color: Colors.green.shade50,
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: Text(
                          'Diraih',
                          style: TextStyle(
                            color: Colors.green.shade700,
                            fontSize: 10,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                  ],
                ),
              );
            }).toList(),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Tutup', style: TextStyle(color: Colors.orange)),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return BlocProvider<BadgeCubit>(
      create: (_) => BadgeCubit(repository: locator<BadgeRepository>())..load(),
      child: BlocBuilder<BadgeCubit, BadgeState>(
        builder: (context, state) {
          if (state is! BadgeLoaded) return const SizedBox.shrink();
          final earned = state.badges.where((b) => b.earned).toList();
          if (earned.isEmpty) return const SizedBox.shrink();
          earned.sort((a, b) => b.threshold.compareTo(a.threshold));
          final level = earned.first.level;

          return Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: Colors.orange.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(
                    color: Colors.orange.withValues(alpha: 0.4),
                  ),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(
                      Icons.emoji_events_rounded,
                      size: 12,
                      color: Colors.orange,
                    ),
                    const SizedBox(width: 4),
                    Text(
                      level,
                      style: const TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w700,
                        color: Colors.orange,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 6),
              GestureDetector(
                onTap: () => _showBadgeInfo(context, state.badges),
                child: Icon(
                  Icons.help_outline_rounded,
                  size: 16,
                  color: Colors.grey.shade500,
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}

// ── Edit profile bottom sheet ──────────────────────────────────────────────────

class _EditProfileSheet extends StatelessWidget {
  final ProfileBloc profileBloc;

  const _EditProfileSheet({required this.profileBloc});

  @override
  Widget build(BuildContext context) {
    return BlocListener<ProfileBloc, ProfileState>(
      listenWhen: (prev, curr) =>
          prev.isSuccess != curr.isSuccess || prev.error != curr.error,
      listener: (context, state) {
        if (state.isSuccess == true) {
          Navigator.pop(context);
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Profil berhasil diperbarui'),
              backgroundColor: Colors.green,
            ),
          );
        }
        if (state.error != null) {
          Navigator.pop(context);
          ScaffoldMessenger.of(context)
            ..clearSnackBars()
            ..showSnackBar(
              SnackBar(
                content: Text(state.error!),
                backgroundColor: Colors.red,
              ),
            );
        }
      },
      child: SafeArea(
        child: AnimatedPadding(
          duration: const Duration(milliseconds: 150),
          curve: Curves.easeOut,
          padding: EdgeInsets.only(
            bottom: MediaQuery.of(context).viewInsets.bottom,
          ),
          child: Container(
            constraints: BoxConstraints(
              maxHeight: MediaQuery.of(context).size.height * 0.88,
            ),
            decoration: const BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Padding(
                  padding: const EdgeInsets.only(top: 12, bottom: 4),
                  child: Container(
                    width: 36,
                    height: 4,
                    decoration: BoxDecoration(
                      color: Colors.grey.shade300,
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                ),
                Container(
                  padding: const EdgeInsets.fromLTRB(20, 10, 12, 10),
                  child: Row(
                    children: [
                      const Expanded(
                        child: Text(
                          'Edit Profil',
                          style: TextStyle(
                            fontSize: 17,
                            fontWeight: FontWeight.w700,
                            color: Color(0xFF6D4C41),
                          ),
                        ),
                      ),
                      TextButton.icon(
                        onPressed: () => Navigator.pop(context),
                        icon: const Icon(
                          Icons.close_rounded,
                          size: 18,
                          color: Colors.orange,
                        ),
                        label: const Text(
                          'Batal',
                          style: TextStyle(color: Colors.orange),
                        ),
                        style: TextButton.styleFrom(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 12,
                            vertical: 8,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                const Divider(height: 1),
                Flexible(
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.fromLTRB(20, 16, 20, 24),
                    child: ChildForm(
                      onSubmit: () {
                        context.read<ProfileBloc>().add(EditSubmitted());
                      },
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

// ── Info card ──────────────────────────────────────────────────────────────────

class _InfoCard extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;

  const _InfoCard({
    required this.icon,
    required this.label,
    required this.value,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.orange.withValues(alpha: 0.07),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(9),
            decoration: BoxDecoration(
              color: Colors.orange.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(icon, color: Colors.orange, size: 20),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: const TextStyle(
                    fontSize: 12,
                    color: Color(0xFF8D6E63),
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  value,
                  style: const TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w600,
                    color: Color(0xFF6D4C41),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ── Badge Gallery Section ──────────────────────────────────────────────────────

class _BadgeGallerySection extends StatelessWidget {
  const _BadgeGallerySection();

  @override
  Widget build(BuildContext context) {
    return BlocProvider<BadgeCubit>(
      create: (_) => BadgeCubit(repository: locator<BadgeRepository>())..load(),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Expanded(
                child: Text(
                  'Lencana Diraih',
                  style: TextStyle(
                    fontSize: 17,
                    fontWeight: FontWeight.w700,
                    color: Color(0xFF6D4C41),
                  ),
                ),
              ),
              GestureDetector(
                onTap: () => Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => BlocProvider(
                      create: (_) =>
                          BadgeCubit(repository: locator<BadgeRepository>())
                            ..load(),
                      child: const BadgeGalleryScreen(),
                    ),
                  ),
                ),
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 6,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.orange.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: const Row(
                    children: [
                      Text(
                        'Lihat semua',
                        style: TextStyle(
                          color: Colors.orange,
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      SizedBox(width: 4),
                      Icon(
                        Icons.arrow_forward_ios_rounded,
                        color: Colors.orange,
                        size: 12,
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          BlocBuilder<BadgeCubit, BadgeState>(
            builder: (context, state) {
              if (state is BadgeLoading) {
                return const Center(child: CircularProgressIndicator());
              }
              if (state is BadgeError) {
                return Text(
                  'Gagal memuat lencana',
                  style: TextStyle(color: Colors.grey.shade500),
                );
              }
              if (state is BadgeLoaded) {
                final earned = state.badges.where((b) => b.earned).toList();
                if (earned.isEmpty) {
                  return Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Colors.orange.shade50,
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(color: Colors.orange.shade100),
                    ),
                    child: Column(
                      children: [
                        Icon(
                          Icons.emoji_events_outlined,
                          size: 36,
                          color: Colors.orange.shade300,
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'Belum ada lencana yang diraih.\nTerus belajar untuk mendapatkan lencana!',
                          style: TextStyle(
                            color: Colors.orange.shade700,
                            fontSize: 13,
                          ),
                          textAlign: TextAlign.center,
                        ),
                      ],
                    ),
                  );
                }
                return GridView.builder(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 3,
                    crossAxisSpacing: 10,
                    mainAxisSpacing: 10,
                    childAspectRatio: 0.85,
                  ),
                  itemCount: earned.length,
                  itemBuilder: (context, index) {
                    return _BadgeCard(badge: earned[index]);
                  },
                );
              }
              return const SizedBox.shrink();
            },
          ),
        ],
      ),
    );
  }
}

class _BadgeCard extends StatelessWidget {
  final BadgeItem badge;
  const _BadgeCard({required this.badge});

  @override
  Widget build(BuildContext context) {
    final locked = !badge.earned;
    final progress = badge.threshold > 0
        ? badge.progress / badge.threshold
        : 1.0;

    return Container(
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: locked ? Colors.grey.shade100 : Colors.orange.shade50,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: locked ? Colors.grey.shade300 : Colors.orange.shade200,
        ),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            locked ? Icons.lock_rounded : Icons.emoji_events_rounded,
            size: 32,
            color: locked ? Colors.grey.shade400 : Colors.orange,
          ),
          const SizedBox(height: 6),
          Text(
            badge.level,
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w600,
              color: locked ? Colors.grey.shade500 : const Color(0xFF6D4C41),
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 4),
          ClipRRect(
            borderRadius: BorderRadius.circular(4),
            child: LinearProgressIndicator(
              value: progress.clamp(0.0, 1.0),
              minHeight: 4,
              backgroundColor: Colors.grey.shade200,
              color: badge.earned ? Colors.orange : Colors.orange.shade200,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            '${badge.progress}/${badge.threshold}',
            style: TextStyle(fontSize: 10, color: Colors.grey.shade500),
          ),
        ],
      ),
    );
  }
}

// ── Growth Charts Section ──────────────────────────────────────────────────────

class _GrowthChartsSection extends StatefulWidget {
  final String childId;
  final String dateOfBirth;
  final String gender;
  const _GrowthChartsSection({
    required this.childId,
    required this.dateOfBirth,
    required this.gender,
  });

  @override
  State<_GrowthChartsSection> createState() => _GrowthChartsSectionState();
}

class _GrowthChartsSectionState extends State<_GrowthChartsSection> {
  late final GrowthBloc _bloc;
  bool _showWeight = true;

  @override
  void initState() {
    super.initState();
    _bloc = GrowthBloc(repository: locator<GrowthRepository>())
      ..add(LoadGrowthHistory(widget.childId));
  }

  @override
  void dispose() {
    _bloc.close();
    super.dispose();
  }

  void _reload() => _bloc.add(LoadGrowthHistory(widget.childId));

  @override
  Widget build(BuildContext context) {
    return BlocProvider.value(
      value: _bloc,
      child: BlocBuilder<GrowthBloc, GrowthState>(
        builder: (context, state) {
          if (state is GrowthLoading) {
            return const Center(child: CircularProgressIndicator());
          }
          final records = state is GrowthLoaded
              ? state.records
              : state is GrowthSaved
              ? state.records
              : <GrowthRecord>[];

          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  const Text(
                    'Tumbuh Kembang',
                    style: TextStyle(
                      fontSize: 17,
                      fontWeight: FontWeight.w700,
                      color: Color(0xFF6D4C41),
                    ),
                  ),
                  const Spacer(),
                  GestureDetector(
                    onTap: () => context
                        .push('/growth', extra: widget.childId)
                        .then((_) => _reload()),
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 6,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.orange.withValues(alpha: 0.12),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: const Row(
                        children: [
                          Icon(
                            Icons.add_rounded,
                            color: Colors.orange,
                            size: 16,
                          ),
                          SizedBox(width: 4),
                          Text(
                            'Tambah',
                            style: TextStyle(
                              color: Colors.orange,
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              if (records.length < 2)
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.orange.shade50,
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(color: Colors.orange.shade100),
                  ),
                  child: Column(
                    children: [
                      Text(
                        'Belum cukup data untuk menampilkan grafik.\nTambahkan minimal 2 catatan tumbuh kembang.',
                        style: TextStyle(
                          color: Colors.orange.shade700,
                          fontSize: 13,
                        ),
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 12),
                      ElevatedButton.icon(
                        onPressed: () => context
                            .push('/growth', extra: widget.childId)
                            .then((_) => _reload()),
                        icon: const Icon(
                          Icons.add_rounded,
                          color: Colors.white,
                          size: 16,
                        ),
                        label: const Text(
                          'Tambah Catatan',
                          style: TextStyle(color: Colors.white),
                        ),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.orange,
                          elevation: 0,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(10),
                          ),
                        ),
                      ),
                    ],
                  ),
                )
              else
                _GrowthCombinedChart(
                  records: records,
                  dateOfBirth: widget.dateOfBirth,
                  gender: widget.gender,
                  showWeight: _showWeight,
                  onToggle: (v) => setState(() => _showWeight = v),
                ),
            ],
          );
        },
      ),
    );
  }
}

// ── WHO reference helpers ─────────────────────────────────────────────────────

double whoWeightMedian(int ageMonths, String gender) {
  const boysWeight = <int, double>{
    0: 3.3,
    1: 4.5,
    2: 5.6,
    3: 6.4,
    4: 7.0,
    5: 7.5,
    6: 7.9,
    9: 9.2,
    12: 10.2,
    15: 11.0,
    18: 11.7,
    21: 12.2,
    24: 12.7,
    30: 13.8,
    36: 14.7,
    42: 15.7,
    48: 16.7,
    54: 17.5,
    60: 18.3,
  };
  const girlsWeight = <int, double>{
    0: 3.2,
    1: 4.2,
    2: 5.1,
    3: 5.8,
    4: 6.4,
    5: 6.9,
    6: 7.3,
    9: 8.6,
    12: 9.5,
    15: 10.2,
    18: 10.9,
    21: 11.5,
    24: 12.0,
    30: 13.0,
    36: 13.9,
    42: 14.8,
    48: 15.8,
    54: 16.6,
    60: 17.4,
  };
  final isFemale =
      gender.toLowerCase() == 'female' ||
      gender.toLowerCase() == 'p' ||
      gender.toLowerCase() == 'f';
  return _interpolateWho(
    isFemale ? girlsWeight : boysWeight,
    ageMonths.clamp(0, 60),
  );
}

double whoHeightMedian(int ageMonths, String gender) {
  const boysHeight = <int, double>{
    0: 49.9,
    1: 54.7,
    2: 58.4,
    3: 61.4,
    4: 63.9,
    5: 65.9,
    6: 67.6,
    9: 72.0,
    12: 75.8,
    15: 79.1,
    18: 82.3,
    21: 85.1,
    24: 87.8,
    30: 92.7,
    36: 96.5,
    42: 100.0,
    48: 103.3,
    54: 106.4,
    60: 110.0,
  };
  const girlsHeight = <int, double>{
    0: 49.1,
    1: 53.7,
    2: 57.1,
    3: 59.8,
    4: 62.1,
    5: 64.0,
    6: 65.7,
    9: 70.1,
    12: 74.0,
    15: 77.5,
    18: 80.7,
    21: 83.7,
    24: 86.4,
    30: 91.4,
    36: 95.1,
    42: 98.7,
    48: 101.8,
    54: 104.8,
    60: 107.9,
  };
  final isFemale =
      gender.toLowerCase() == 'female' ||
      gender.toLowerCase() == 'p' ||
      gender.toLowerCase() == 'f';
  return _interpolateWho(
    isFemale ? girlsHeight : boysHeight,
    ageMonths.clamp(0, 60),
  );
}

double _whoWeightSigma(int ageMonths) {
  const table = <int, double>{
    0: 0.45,
    3: 0.60,
    6: 0.75,
    12: 1.00,
    18: 1.10,
    24: 1.20,
    36: 1.40,
    48: 1.60,
    60: 1.80,
  };
  return _interpolateWho(table, ageMonths.clamp(0, 60));
}

double _whoHeightSigma(int ageMonths) {
  const table = <int, double>{
    0: 1.9,
    3: 2.0,
    6: 2.1,
    12: 2.2,
    18: 2.3,
    24: 2.5,
    36: 2.7,
    48: 2.9,
    60: 3.1,
  };
  return _interpolateWho(table, ageMonths.clamp(0, 60));
}

double _interpolateWho(Map<int, double> table, int months) {
  if (table.containsKey(months)) return table[months]!;
  final keys = table.keys.toList()..sort();
  for (int i = 0; i < keys.length - 1; i++) {
    final k0 = keys[i], k1 = keys[i + 1];
    if (months >= k0 && months <= k1) {
      final t = (months - k0) / (k1 - k0);
      return table[k0]! + t * (table[k1]! - table[k0]!);
    }
  }
  return table[keys.last]!;
}

List<FlSpot> _generateWhoLine(
  bool isWeight,
  int minAge,
  int maxAge,
  String gender,
  double sdFactor,
) {
  return List.generate(maxAge - minAge + 1, (i) {
    final age = minAge + i;
    final median = isWeight
        ? whoWeightMedian(age, gender)
        : whoHeightMedian(age, gender);
    final sigma = isWeight ? _whoWeightSigma(age) : _whoHeightSigma(age);
    return FlSpot(age.toDouble(), median + sdFactor * sigma);
  });
}

// ── Combined growth chart ─────────────────────────────────────────────────────

class _GrowthCombinedChart extends StatelessWidget {
  final List<GrowthRecord> records;
  final String dateOfBirth;
  final String gender;
  final bool showWeight;
  final ValueChanged<bool> onToggle;

  const _GrowthCombinedChart({
    required this.records,
    required this.dateOfBirth,
    required this.gender,
    required this.showWeight,
    required this.onToggle,
  });

  int _ageInMonths(DateTime dob, DateTime at) {
    int m = (at.year - dob.year) * 12 + (at.month - dob.month);
    if (at.day < dob.day) m--;
    return m.clamp(0, 60);
  }

  @override
  Widget build(BuildContext context) {
    final dob = DateTime.tryParse(dateOfBirth) ?? DateTime.now();
    final sorted = [...records]
      ..sort((a, b) => a.recordedAt.compareTo(b.recordedAt));

    // Actual data spots — x = age in months
    final dataSpots = sorted.map((r) {
      final age = _ageInMonths(dob, r.recordedAt).toDouble();
      final val = showWeight ? r.weightKg : r.heightCm;
      return FlSpot(age, val);
    }).toList();

    final ages = dataSpots.map((s) => s.x.toInt());
    final minAge = (ages.reduce(min) - 2).clamp(0, 58);
    final maxAge = (ages.reduce(max) + 2).clamp(2, 60);

    // WHO reference lines
    final whoMinus2 = _generateWhoLine(showWeight, minAge, maxAge, gender, -2);
    final whoMinus1 = _generateWhoLine(showWeight, minAge, maxAge, gender, -1);
    final whoMedian = _generateWhoLine(showWeight, minAge, maxAge, gender, 0);
    final whoPlus1 = _generateWhoLine(showWeight, minAge, maxAge, gender, 1);
    final whoPlus2 = _generateWhoLine(showWeight, minAge, maxAge, gender, 2);

    // Y range
    final allY = [
      ...dataSpots.map((s) => s.y),
      ...whoMinus2.map((s) => s.y),
      ...whoPlus2.map((s) => s.y),
    ];
    final minY = allY.reduce(min) - 0.5;
    final maxY = allY.reduce(max) + 0.5;

    final dataColor = showWeight
        ? const Color(0xFF1565C0)
        : const Color(0xFF2E7D32);
    final unit = showWeight ? 'kg' : 'cm';
    final label = showWeight ? 'Berat Badan (kg)' : 'Tinggi Badan (cm)';

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        boxShadow: [
          BoxShadow(
            color: Colors.orange.withValues(alpha: 0.07),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header row with toggle
          Row(
            children: [
              Expanded(
                child: Text(
                  label,
                  style: const TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: Color(0xFF6D4C41),
                  ),
                ),
              ),
              _ToggleChip(
                label: 'BB',
                active: showWeight,
                color: const Color(0xFF1565C0),
                onTap: () => onToggle(true),
              ),
              const SizedBox(width: 6),
              _ToggleChip(
                label: 'TB',
                active: !showWeight,
                color: const Color(0xFF2E7D32),
                onTap: () => onToggle(false),
              ),
            ],
          ),
          const SizedBox(height: 8),
          // Zone legend
          Wrap(
            spacing: 12,
            runSpacing: 4,
            children: [
              _ZoneLegend(color: dataColor, label: 'Data anak', solid: true),
              _ZoneLegend(color: Colors.green.shade600, label: 'Ideal (±1 SD)'),
              _ZoneLegend(
                color: Colors.orange.shade600,
                label: 'Perhatian (±2 SD)',
              ),
              _ZoneLegend(color: Colors.red.shade600, label: 'Batas bahaya'),
            ],
          ),
          const SizedBox(height: 14),
          SizedBox(
            height: 200,
            child: LineChart(
              LineChartData(
                minX: minAge.toDouble(),
                maxX: maxAge.toDouble(),
                minY: minY,
                maxY: maxY,
                // Bar order: [0]=data, [1]=-2SD, [2]=-1SD, [3]=median,
                //             [4]=+1SD, [5]=+2SD
                lineBarsData: [
                  // 0 — actual data
                  LineChartBarData(
                    spots: dataSpots,
                    isCurved: true,
                    color: dataColor,
                    barWidth: 3,
                    dotData: FlDotData(
                      show: true,
                      getDotPainter: (spot, _, __, ___) => FlDotCirclePainter(
                        radius: 4,
                        color: dataColor,
                        strokeWidth: 2,
                        strokeColor: Colors.white,
                      ),
                    ),
                    belowBarData: BarAreaData(show: false),
                  ),
                  // 1 — WHO -2 SD (red, dashed)
                  LineChartBarData(
                    spots: whoMinus2,
                    isCurved: true,
                    color: Colors.red.shade400,
                    barWidth: 1.2,
                    dashArray: [5, 4],
                    dotData: const FlDotData(show: false),
                  ),
                  // 2 — WHO -1 SD (orange, dashed)
                  LineChartBarData(
                    spots: whoMinus1,
                    isCurved: true,
                    color: Colors.orange.shade400,
                    barWidth: 1.2,
                    dashArray: [5, 4],
                    dotData: const FlDotData(show: false),
                  ),
                  // 3 — WHO median (green, dashed)
                  LineChartBarData(
                    spots: whoMedian,
                    isCurved: true,
                    color: Colors.green.shade400,
                    barWidth: 1.5,
                    dashArray: [6, 3],
                    dotData: const FlDotData(show: false),
                  ),
                  // 4 — WHO +1 SD (orange, dashed)
                  LineChartBarData(
                    spots: whoPlus1,
                    isCurved: true,
                    color: Colors.orange.shade400,
                    barWidth: 1.2,
                    dashArray: [5, 4],
                    dotData: const FlDotData(show: false),
                  ),
                  // 5 — WHO +2 SD (red, dashed)
                  LineChartBarData(
                    spots: whoPlus2,
                    isCurved: true,
                    color: Colors.red.shade400,
                    barWidth: 1.2,
                    dashArray: [5, 4],
                    dotData: const FlDotData(show: false),
                  ),
                ],
                // Fill colored zones between WHO bands
                betweenBarsData: [
                  // Green: between -1SD and +1SD (ideal)
                  BetweenBarsData(
                    fromIndex: 2,
                    toIndex: 4,
                    color: Colors.green.withValues(alpha: 0.08),
                  ),
                  // Orange lower: between -2SD and -1SD
                  BetweenBarsData(
                    fromIndex: 1,
                    toIndex: 2,
                    color: Colors.orange.withValues(alpha: 0.10),
                  ),
                  // Orange upper: between +1SD and +2SD
                  BetweenBarsData(
                    fromIndex: 4,
                    toIndex: 5,
                    color: Colors.orange.withValues(alpha: 0.10),
                  ),
                ],
                titlesData: FlTitlesData(
                  leftTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      reservedSize: 42,
                      getTitlesWidget: (value, meta) => Text(
                        value.toStringAsFixed(1),
                        style: const TextStyle(
                          fontSize: 9,
                          color: Color(0xFF8D6E63),
                        ),
                      ),
                    ),
                  ),
                  bottomTitles: AxisTitles(
                    axisNameWidget: Text(
                      'Usia (bulan)',
                      style: TextStyle(
                        fontSize: 9,
                        color: Colors.grey.shade500,
                      ),
                    ),
                    axisNameSize: 16,
                    sideTitles: SideTitles(
                      showTitles: true,
                      interval: 6,
                      getTitlesWidget: (value, meta) {
                        final age = value.toInt();
                        return Padding(
                          padding: const EdgeInsets.only(top: 2),
                          child: Text(
                            '${age}b',
                            style: const TextStyle(
                              fontSize: 9,
                              color: Color(0xFF8D6E63),
                            ),
                          ),
                        );
                      },
                    ),
                  ),
                  topTitles: const AxisTitles(
                    sideTitles: SideTitles(showTitles: false),
                  ),
                  rightTitles: const AxisTitles(
                    sideTitles: SideTitles(showTitles: false),
                  ),
                ),
                gridData: FlGridData(
                  show: true,
                  drawVerticalLine: false,
                  getDrawingHorizontalLine: (value) => FlLine(
                    color: Colors.grey.withValues(alpha: 0.12),
                    strokeWidth: 1,
                  ),
                ),
                borderData: FlBorderData(show: false),
                lineTouchData: LineTouchData(
                  touchTooltipData: LineTouchTooltipData(
                    getTooltipItems: (spots) {
                      final labels = [
                        'Data',
                        '-2 SD',
                        '-1 SD',
                        'Median',
                        '+1 SD',
                        '+2 SD',
                      ];
                      return spots.map((s) {
                        if (s.barIndex != 0 && s.barIndex != 3) {
                          return null; // only show data + median in tooltip
                        }
                        return LineTooltipItem(
                          '${labels[s.barIndex]}: ${s.y.toStringAsFixed(1)} $unit',
                          TextStyle(
                            color: s.barIndex == 0
                                ? dataColor
                                : Colors.green.shade600,
                            fontSize: 11,
                            fontWeight: FontWeight.w600,
                          ),
                        );
                      }).toList();
                    },
                  ),
                ),
              ),
            ),
          ),
          const SizedBox(height: 6),
          // Unit label
          Center(
            child: Text(
              unit,
              style: TextStyle(fontSize: 10, color: Colors.grey.shade500),
            ),
          ),
        ],
      ),
    );
  }
}

class _ToggleChip extends StatelessWidget {
  final String label;
  final bool active;
  final Color color;
  final VoidCallback onTap;

  const _ToggleChip({
    required this.label,
    required this.active,
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 5),
        decoration: BoxDecoration(
          color: active ? color.withValues(alpha: 0.12) : Colors.grey.shade100,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: active ? color : Colors.grey.shade300,
            width: 1.2,
          ),
        ),
        child: Text(
          label,
          style: TextStyle(
            fontSize: 11,
            fontWeight: FontWeight.w700,
            color: active ? color : Colors.grey.shade500,
          ),
        ),
      ),
    );
  }
}

class _ZoneLegend extends StatelessWidget {
  final Color color;
  final String label;
  final bool solid;

  const _ZoneLegend({
    required this.color,
    required this.label,
    this.solid = false,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        solid
            ? Container(width: 14, height: 2.5, color: color)
            : Row(
                mainAxisSize: MainAxisSize.min,
                children: List.generate(
                  3,
                  (i) => Container(
                    width: 4,
                    height: 2,
                    margin: const EdgeInsets.symmetric(horizontal: 0.5),
                    color: color,
                  ),
                ),
              ),
        const SizedBox(width: 4),
        Text(label, style: TextStyle(fontSize: 9, color: Colors.grey.shade600)),
      ],
    );
  }
}

// ── Helpers ────────────────────────────────────────────────────────────────────

int calculateAge(String dobString) {
  final dob = DateTime.parse(dobString);
  final now = DateTime.now();
  int age = now.year - dob.year;
  if (now.month < dob.month || (now.month == dob.month && now.day < dob.day)) {
    age--;
  }
  return age;
}
