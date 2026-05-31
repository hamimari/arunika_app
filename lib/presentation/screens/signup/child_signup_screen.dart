import 'package:arunika_app/presentation/screens/signup/signup_bloc.dart';
import 'package:arunika_app/presentation/screens/signup/signup_event.dart';
import 'package:arunika_app/presentation/screens/signup/signup_state.dart';
import 'package:arunika_app/presentation/screens/widgets/app_button.dart';
import 'package:arunika_app/presentation/screens/widgets/date_field.dart';
import 'package:arunika_app/presentation/screens/widgets/dropdown_field.dart';
import 'package:arunika_app/presentation/screens/widgets/error_dialog.dart';
import 'package:arunika_app/presentation/screens/widgets/progress_bar.dart';
import 'package:arunika_app/presentation/screens/widgets/text_field.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

class ChildSignupScreen extends StatefulWidget {
  const ChildSignupScreen({super.key});

  @override
  State<ChildSignupScreen> createState() => _ChildSignupState();
}

class _ChildSignupState extends State<ChildSignupScreen> {
  late final TextEditingController nameController;
  late final TextEditingController birthDateController;

  @override
  void initState() {
    super.initState();

    final state = context.read<SignupBloc>().state;
    nameController = TextEditingController(text: state.childName);
    birthDateController = TextEditingController(
      text: state.childBirthDate != null
          ? '${state.childBirthDate!.day}/${state.childBirthDate!.month}/${state.childBirthDate!.year}'
          : '',
    );
  }

  @override
  void dispose() {
    nameController.dispose();
    birthDateController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return BlocListener<SignupBloc, SignupState>(
      listener: (context, state) {
        if (state.error != null) {
          showModalBottomSheet(
            context: context,
            isScrollControlled: true,
            backgroundColor: Colors.transparent,
            builder: (_) => AppErrorSheet(
              title: 'Yah, ada kendala',
              message: state.error!,
              onConfirm: () {},
            ),
          );
        }

        if (state.isSuccess) {
          Navigator.of(context).popUntil((route) => route.isFirst);
          context.go('/shell');
        }
      },
      child: Scaffold(
        backgroundColor: const Color(0xFFFFFBF5),
        body: SafeArea(
          child: SingleChildScrollView(
            child: Column(
              children: [
                // ================= HEADER =================
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.fromLTRB(20, 20, 20, 28),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [Colors.orange.shade400, Colors.orange.shade300],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    borderRadius: const BorderRadius.vertical(
                      bottom: Radius.circular(28),
                    ),
                  ),
                  child: Stack(
                    children: [
                      // BACK BUTTON
                      Positioned(
                        top: 0,
                        left: 0,
                        child: Container(
                          decoration: BoxDecoration(
                            color: Colors.white.withValues(alpha: 0.25),
                            shape: BoxShape.circle,
                          ),
                          child: IconButton(
                            icon: const Icon(
                              Icons.arrow_back_ios_new_rounded,
                              color: Colors.white,
                              size: 20,
                            ),
                            onPressed: () => Navigator.pop(context),
                          ),
                        ),
                      ),

                      // CENTERED CONTENT
                      Align(
                        alignment: Alignment.topCenter,
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          crossAxisAlignment: CrossAxisAlignment.center,
                          children: [
                            const SizedBox(height: 8),
                            const Text(
                              "Data Anak",
                              textAlign: TextAlign.center,
                              style: TextStyle(
                                fontSize: 22,
                                fontWeight: FontWeight.w700,
                                color: Colors.white,
                                letterSpacing: 0.3,
                              ),
                            ),
                            const SizedBox(height: 12),
                            // Container(
                            //   height: 90,
                            //   width: 90,
                            //   decoration: BoxDecoration(
                            //     color: Colors.white.withValues(alpha: 0.25),
                            //     shape: BoxShape.circle,
                            //   ),
                            //   child: const Icon(
                            //     Icons.child_care_rounded,
                            //     size: 48,
                            //     color: Colors.white,
                            //   ),
                            // ),
                            // const SizedBox(height: 12),
                            const Padding(
                              padding: EdgeInsets.symmetric(horizontal: 24),
                              child: Text(
                                "Lengkapi data si kecil untuk pengalaman belajar yang personal",
                                textAlign: TextAlign.center,
                                style: TextStyle(
                                  fontSize: 13,
                                  color: Colors.white,
                                  height: 1.4,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),

                // ================= FORM CARD =================
                Padding(
                  padding: const EdgeInsets.fromLTRB(24, 24, 24, 32),
                  child: Container(
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(24),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.orange.withValues(alpha: 0.08),
                          blurRadius: 24,
                          offset: const Offset(0, 12),
                        ),
                      ],
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const AppProgress(value: 1.0),
                        const SizedBox(height: 24),

                        // Nama Anak
                        BlocBuilder<SignupBloc, SignupState>(
                          buildWhen: (p, c) =>
                              p.childNameError != c.childNameError,
                          builder: (context, state) {
                            return AppTextField(
                              controller: nameController,
                              label: 'Nama Anak',
                              hint: 'Contoh: Rafatar',
                              onChanged: (value) => context
                                  .read<SignupBloc>()
                                  .add(ChildNameChanged(value)),
                              error: state.childNameError,
                            );
                          },
                        ),

                        const SizedBox(height: 12),

                        // Tanggal Lahir
                        BlocBuilder<SignupBloc, SignupState>(
                          buildWhen: (p, c) =>
                              p.childBirthDate != c.childBirthDate ||
                              p.childBirthDateError != c.childBirthDateError,
                          builder: (context, state) {
                            return AppDateField(
                              controller: birthDateController,
                              label: 'Tanggal Lahir Anak',
                              value: state.childBirthDate,
                              hint: '22/11/2022',
                              error: state.childBirthDateError,
                              onChanged: (date) {
                                context.read<SignupBloc>().add(
                                  ChildBirthDateChanged(date),
                                );
                              },
                            );
                          },
                        ),

                        const SizedBox(height: 12),

                        // Gender
                        BlocBuilder<SignupBloc, SignupState>(
                          buildWhen: (p, c) =>
                              p.childGenderError != c.childGenderError,
                          builder: (context, state) {
                            return AppDropdownField(
                              label: 'Jenis Kelamin',
                              value: state.childGender,
                              hint: 'Pilih Jenis Kelamin',
                              error: state.childGenderError,
                              items: const [
                                DropdownMenuItem(
                                  value: 'Laki-Laki',
                                  child: Text('Laki-Laki'),
                                ),
                                DropdownMenuItem(
                                  value: 'Perempuan',
                                  child: Text('Perempuan'),
                                ),
                              ],
                              onChanged: (val) {
                                context.read<SignupBloc>().add(
                                  ChildGenderChanged(val),
                                );
                              },
                            );
                          },
                        ),

                        const SizedBox(height: 16),

                        // T&C
                        BlocBuilder<SignupBloc, SignupState>(
                          buildWhen: (p, c) => p.tncAccepted != c.tncAccepted,
                          builder: (context, state) {
                            return Row(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Checkbox(
                                  value: state.tncAccepted,
                                  activeColor: Colors.orange,
                                  onChanged: (value) {
                                    context.read<SignupBloc>().add(
                                      TncToggled(value ?? false),
                                    );
                                  },
                                ),
                                Expanded(
                                  child: Padding(
                                    padding: const EdgeInsets.only(top: 10),
                                    child: Text.rich(
                                      TextSpan(
                                        text:
                                            'Dengan mendaftar, Kamu menyetujui ',
                                        style: const TextStyle(
                                          fontSize: 12,
                                          color: Colors.black54,
                                        ),
                                        children: [
                                          TextSpan(
                                            text: 'Syarat & Ketentuan',
                                            style: const TextStyle(
                                              color: Colors.orange,
                                              fontWeight: FontWeight.w600,
                                            ),
                                            recognizer: TapGestureRecognizer()
                                              ..onTap = () {
                                                context.push('/terms');
                                              },
                                          ),
                                          const TextSpan(text: ' dan '),
                                          TextSpan(
                                            text: 'Kebijakan Privasi',
                                            style: const TextStyle(
                                              color: Colors.orange,
                                              fontWeight: FontWeight.w600,
                                            ),
                                            recognizer: TapGestureRecognizer()
                                              ..onTap = () {
                                                context.push('/privacy');
                                              },
                                          ),
                                          const TextSpan(text: ' kami'),
                                        ],
                                      ),
                                    ),
                                  ),
                                ),
                              ],
                            );
                          },
                        ),

                        const SizedBox(height: 24),

                        // Button
                        BlocBuilder<SignupBloc, SignupState>(
                          builder: (context, state) {
                            return AppButton(
                              text: 'Simpan',
                              enabled: state.tncAccepted,
                              loading: state.isSubmitting,
                              onPressed: () {
                                context.read<SignupBloc>().add(
                                  SignupSubmitted(),
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
          ),
        ),
      ),
    );
  }
}
