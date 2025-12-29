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
      backgroundColor: Colors.grey[100],
      bottomNavigationBar: BottomNav(
        currentIndex: 1,
        onArPressed: () {
          Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => QRScannerPage()),
          );
        },
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => QRScannerPage()),
          );
        },
        backgroundColor: Colors.orange,
        child: const Icon(Iconsax.scan),
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
                  boxShadow: const [
                    BoxShadow(color: Colors.black12, blurRadius: 6),
                  ],
                ),
                child: Column(
                  children: [
                    // ===== HEADER =====
                    Stack(
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
