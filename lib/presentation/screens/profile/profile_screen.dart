import 'package:arunika_app/core/auth/auth_notifier.dart';
import 'package:arunika_app/di/locator.dart';
import 'package:arunika_app/presentation/screens/profile/child_form.dart';
import 'package:arunika_app/presentation/screens/profile/profile_bloc.dart';
import 'package:arunika_app/presentation/screens/profile/profile_event.dart';
import 'package:arunika_app/presentation/screens/profile/profile_state.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:iconsax/iconsax.dart';

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
                // ── Header — matches home page gradient style ──────────────
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.fromLTRB(20, 24, 20, 28),
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
                      // Child name + age
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

                // ── Info cards ────────────────────────────────────────────
                Expanded(
                  child: RefreshIndicator(
                    color: Colors.orange,
                    onRefresh: () async =>
                        context.read<ProfileBloc>().add(ProfileInitial()),
                    child: ListView(
                      physics: const AlwaysScrollableScrollPhysics(),
                      padding: const EdgeInsets.symmetric(horizontal: 20),
                      children: [
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

                        // ── Logout ────────────────────────────────────────
                        SizedBox(
                          width: double.infinity,
                          child: OutlinedButton.icon(
                            onPressed: () async {
                              await locator<AuthNotifier>().logout();
                              if (context.mounted) context.go('/landing');
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
                ),
              ],
            );
          },
        ),
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
                // ── Drag handle ───────────────────────────────────────────
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

                // ── Sheet header ──────────────────────────────────────────
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
                      // ── Close / cancel button ─────────────────────────
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

                // ── Scrollable form ───────────────────────────────────────
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
