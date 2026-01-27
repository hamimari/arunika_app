import 'package:arunika_app/core/storage/LocalProfileStorage.dart';
import 'package:arunika_app/core/storage/SecureStorageToken.dart';
import 'package:arunika_app/presentation/screens/arscanner/qr_scanner.dart';
import 'package:arunika_app/presentation/screens/profile/child_form.dart';
import 'package:arunika_app/presentation/screens/profile/profile_bloc.dart';
import 'package:arunika_app/presentation/screens/profile/profile_event.dart';
import 'package:arunika_app/presentation/screens/profile/profile_state.dart';
import 'package:arunika_app/presentation/screens/widgets/app_button.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:iconsax/iconsax.dart';

import '../widgets/bottom_nav.dart';

class ProfileScreen extends StatelessWidget {
  const ProfileScreen({super.key});

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
              color: Colors.orange.withOpacity(0.35),
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
              MaterialPageRoute(builder: (_) => QRScannerPage()),
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
                ? '${calculateAge(child.dateOfBirth)} Years Old'
                : '-';

            return SingleChildScrollView(
              child: Container(
                margin: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(12),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.orange.withOpacity(0.08),
                      blurRadius: 20,
                      offset: const Offset(0, 8),
                    ),
                  ],
                ),
                child: Column(
                  children: [
                    /*Stack(
                      children: [
                        Image.network(
                          'https://storage.googleapis.com/a1aa/image/8HOKyghgmBiIhH-KAyvq2Fgh9s_WmO1zezsACVtQpTs.jpg',
                          height: 300,
                          width: double.infinity,
                          fit: BoxFit.cover,
                        ),
                        Positioned(
                          bottom: 0,
                          left: 0,
                          right: 0,
                          child: Container(
                            padding: const EdgeInsets.all(16),
                            color: Colors.white.withOpacity(0.9),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      child?.name ?? '-',
                                      style: const TextStyle(
                                        fontSize: 20,
                                        fontWeight: FontWeight.w600,
                                        color: Colors.orange,
                                      ),
                                    ),
                                    Text(
                                      ageText,
                                      style: const TextStyle(
                                        color: Colors.grey,
                                      ),
                                    ),
                                  ],
                                ),

                                IconButton(
                                  icon: const Icon(Icons.edit, color: Colors.orange),
                                  onPressed: () {
                                    final profileBloc = context.read<ProfileBloc>();
                                    final child = context.read<ProfileBloc>().state.user!.children.first;

                                    showModalBottomSheet(
                                      context: context,
                                      isScrollControlled: true,
                                      backgroundColor: Colors.transparent,
                                      isDismissible: true,
                                      enableDrag: true,
                                      builder: (_) {
                                        return BlocProvider.value(
                                          value: profileBloc
                                            ..add(
                                              ChildPrefilled(
                                                name: child.name,
                                                gender: child.gender,
                                                birthDate: DateTime.parse(child.dateOfBirth),
                                              ),
                                            ),
                                          child: SafeArea(
                                            child: Padding(
                                              padding: EdgeInsets.only(
                                                bottom: MediaQuery.of(context).viewInsets.bottom,
                                              ),
                                              child: Center(
                                                child: ConstrainedBox(
                                                  constraints: const BoxConstraints(maxWidth: 520),
                                                  child: Container(
                                                    margin: const EdgeInsets.symmetric(
                                                      horizontal: 16,
                                                      vertical: 24,
                                                    ),
                                                    padding: const EdgeInsets.fromLTRB(20, 12, 20, 24),
                                                    decoration: const BoxDecoration(
                                                      color: Colors.white,
                                                      borderRadius: BorderRadius.vertical(
                                                        top: Radius.circular(20),
                                                        bottom: Radius.circular(20),
                                                      ),
                                                    ),
                                                    child: BlocListener<ProfileBloc, ProfileState>(
                                                      listenWhen: (prev, curr) =>
                                                      prev.isSuccess != curr.isSuccess || prev.error != curr.error,
                                                      listener: (context, state) {
                                                        if (state.isSuccess == true) {
                                                          Navigator.pop(context); // close modal

                                                          ScaffoldMessenger.of(context).showSnackBar(
                                                            const SnackBar(
                                                              content: Text('Profil berhasil diperbarui'),
                                                              backgroundColor: Colors.green,
                                                            ),
                                                          );
                                                        }
                                                        if (state.error != null) {
                                                          Navigator.pop(context); // close modal FIRST

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
                                                      child: SingleChildScrollView(
                                                        child: Column(
                                                          children: [
                                                            // drag handle
                                                            Container(
                                                              width: 40,
                                                              height: 4,
                                                              margin: const EdgeInsets.only(bottom: 16),
                                                              decoration: BoxDecoration(
                                                                color: Colors.grey.shade300,
                                                                borderRadius: BorderRadius.circular(8),
                                                              ),
                                                            ),
                                                            ChildForm(
                                                              onSubmit: () {
                                                                context.read<ProfileBloc>().add(EditSubmitted());
                                                              },
                                                            ),
                                                          ],
                                                        ),
                                                      ),
                                                    ),

                                                  ),
                                                ),
                                              ),
                                            ),
                                          ),
                                        );
                                      },
                                    );
                                  },
                                ),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),*/
                    Stack(
                      children: [
                        Container(
                          height: 260,
                          decoration: const BoxDecoration(
                            gradient: LinearGradient(
                              colors: [Color(0xFFFFC26F), Color(0xFFFF9F43)],
                              begin: Alignment.topLeft,
                              end: Alignment.bottomRight,
                            ),
                            borderRadius: BorderRadius.vertical(
                              bottom: Radius.circular(32),
                            ),
                          ),
                        ),

                        Positioned(
                          bottom: 10,
                          left: 0,
                          right: 0,
                          child: Container(
                            margin: const EdgeInsets.symmetric(horizontal: 16),
                            padding: const EdgeInsets.all(16),
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(20),
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.orange.withOpacity(0.08),
                                  blurRadius: 20,
                                  offset: const Offset(0, 8),
                                ),
                              ],
                            ),
                            child: Row(
                              children: [
                                CircleAvatar(
                                  radius: 36,
                                  backgroundColor: Colors.orange.shade100,
                                  backgroundImage: child != null
                                      ? NetworkImage(
                                    'https://api.dicebear.com/7.x/bottts/png?seed=${child.name}',
                                  )
                                      : null,
                                  child: child == null
                                      ? const Icon(Icons.child_care, color: Colors.orange)
                                      : null,
                                ),

                                const SizedBox(width: 16),

                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        child?.name ?? '-',
                                        style: const TextStyle(
                                          fontSize: 18,
                                          fontWeight: FontWeight.w600,
                                        ),
                                      ),
                                      const SizedBox(height: 4),
                                      Text(
                                        ageText,
                                        style: const TextStyle(
                                          color: Colors.grey,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),

                                IconButton(
                                  icon: const Icon(Icons.edit, color: Colors.orange),
                                  onPressed: () {
                                    final profileBloc = context.read<ProfileBloc>();
                                    final child = context.read<ProfileBloc>().state.user!.children.first;

                                    showModalBottomSheet(
                                      context: context,
                                      isScrollControlled: true,
                                      backgroundColor: Colors.transparent,
                                      isDismissible: true,
                                      enableDrag: true,
                                      builder: (_) {
                                        return BlocProvider.value(
                                          value: profileBloc
                                            ..add(
                                              ChildPrefilled(
                                                name: child.name,
                                                gender: child.gender,
                                                birthDate: DateTime.parse(child.dateOfBirth),
                                              ),
                                            ),
                                          child: SafeArea(
                                            child: Padding(
                                              padding: EdgeInsets.only(
                                                bottom: MediaQuery.of(context).viewInsets.bottom,
                                              ),
                                              child: Center(
                                                child: ConstrainedBox(
                                                  constraints: const BoxConstraints(maxWidth: 520),
                                                  child: Container(
                                                    margin: const EdgeInsets.symmetric(
                                                      horizontal: 16,
                                                      vertical: 24,
                                                    ),
                                                    padding: const EdgeInsets.fromLTRB(20, 12, 20, 24),
                                                    decoration: const BoxDecoration(
                                                      color: Colors.white,
                                                      borderRadius: BorderRadius.vertical(
                                                        top: Radius.circular(20),
                                                        bottom: Radius.circular(20),
                                                      ),
                                                    ),
                                                    child: BlocListener<ProfileBloc, ProfileState>(
                                                      listenWhen: (prev, curr) =>
                                                      prev.isSuccess != curr.isSuccess || prev.error != curr.error,
                                                      listener: (context, state) {
                                                        if (state.isSuccess == true) {
                                                          Navigator.pop(context); // close modal

                                                          ScaffoldMessenger.of(context).showSnackBar(
                                                            const SnackBar(
                                                              content: Text('Profil berhasil diperbarui'),
                                                              backgroundColor: Colors.green,
                                                            ),
                                                          );
                                                        }
                                                        if (state.error != null) {
                                                          Navigator.pop(context); // close modal FIRST

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
                                                      child: SingleChildScrollView(
                                                        child: Column(
                                                          children: [
                                                            // drag handle
                                                            Container(
                                                              width: 40,
                                                              height: 4,
                                                              margin: const EdgeInsets.only(bottom: 16),
                                                              decoration: BoxDecoration(
                                                                color: Colors.grey.shade300,
                                                                borderRadius: BorderRadius.circular(8),
                                                              ),
                                                            ),
                                                            ChildForm(
                                                              onSubmit: () {
                                                                context.read<ProfileBloc>().add(EditSubmitted());
                                                              },
                                                            ),
                                                          ],
                                                        ),
                                                      ),
                                                    ),

                                                  ),
                                                ),
                                              ),
                                            ),
                                          ),
                                        );
                                      },
                                    );
                                  },
                                ),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),


                    // ===== LOGOUT =====
                    Padding(
                      padding: const EdgeInsets.all(16),
                      child: AppButton(
                        text: 'Keluar',
                        enabled: true,
                        loading: false,
                        onPressed: () async {
                          await SecureTokenStorage.clear();
                          await LocalProfileStorage.clear();
                          context.go('/signin');
                        },
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

int calculateAge(String dobString) {
  final dob = DateTime.parse(dobString);
  final now = DateTime.now();
  int age = now.year - dob.year;

  if (now.month < dob.month || (now.month == dob.month && now.day < dob.day)) {
    age--;
  }
  return age;
}
