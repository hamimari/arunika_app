import 'package:arunika_app/data/models/response/growth_record.dart';
import 'package:arunika_app/data/repositories/growth_repository.dart';
import 'package:arunika_app/di/locator.dart';
import 'package:arunika_app/presentation/screens/growth/growth_bloc.dart';
import 'package:arunika_app/presentation/screens/widgets/feature_scaffold.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intl/intl.dart';

class GrowthScreen extends StatelessWidget {
  final String childId;
  const GrowthScreen({super.key, required this.childId});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) =>
          GrowthBloc(repository: locator<GrowthRepository>())
            ..add(LoadGrowthHistory(childId)),
      child: _GrowthView(childId: childId),
    );
  }
}

class _GrowthView extends StatefulWidget {
  final String childId;
  const _GrowthView({required this.childId});

  @override
  State<_GrowthView> createState() => _GrowthViewState();
}

class _GrowthViewState extends State<_GrowthView> {
  final _weightCtrl = TextEditingController();
  final _heightCtrl = TextEditingController();
  final _formKey = GlobalKey<FormState>();
  DateTime _selectedDate = DateTime.now();
  bool _showForm = true;

  @override
  void dispose() {
    _weightCtrl.dispose();
    _heightCtrl.dispose();
    super.dispose();
  }

  void _openEditSheet(BuildContext context, GrowthRecord record) {
    final weightCtrl = TextEditingController(text: record.weightKg.toString());
    final heightCtrl = TextEditingController(text: record.heightCm.toString());
    final formKey = GlobalKey<FormState>();
    DateTime selectedDate = record.recordedAt;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) {
        return StatefulBuilder(
          builder: (ctx, setSheetState) {
            return AnimatedPadding(
              duration: const Duration(milliseconds: 150),
              curve: Curves.easeOut,
              padding: EdgeInsets.only(
                bottom: MediaQuery.of(ctx).viewInsets.bottom,
              ),
              child: Container(
                decoration: const BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
                ),
                padding: const EdgeInsets.fromLTRB(20, 16, 20, 28),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Center(
                      child: Container(
                        width: 36,
                        height: 4,
                        decoration: BoxDecoration(
                          color: Colors.grey.shade300,
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),
                    const Text(
                      'Edit Catatan',
                      style: TextStyle(
                        fontSize: 17,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF6D4C41),
                      ),
                    ),
                    const SizedBox(height: 16),
                    Form(
                      key: formKey,
                      child: Column(
                        children: [
                          _buildField(
                            controller: weightCtrl,
                            label: 'Berat Badan',
                            hint: 'cth: 15.5',
                            suffix: 'kg',
                            icon: Icons.monitor_weight_outlined,
                            validator: (v) {
                              if (v == null || v.isEmpty) {
                                return 'Masukkan berat badan';
                              }
                              if (double.tryParse(v) == null) {
                                return 'Masukkan angka yang valid';
                              }
                              return null;
                            },
                          ),
                          const SizedBox(height: 14),
                          _buildField(
                            controller: heightCtrl,
                            label: 'Tinggi Badan',
                            hint: 'cth: 100.0',
                            suffix: 'cm',
                            icon: Icons.height_rounded,
                            validator: (v) {
                              if (v == null || v.isEmpty) {
                                return 'Masukkan tinggi badan';
                              }
                              if (double.tryParse(v) == null) {
                                return 'Masukkan angka yang valid';
                              }
                              return null;
                            },
                          ),
                          const SizedBox(height: 14),
                          GestureDetector(
                            onTap: () async {
                              final picked = await showDatePicker(
                                context: ctx,
                                initialDate: selectedDate,
                                firstDate: DateTime(2020),
                                lastDate: DateTime.now(),
                                builder: (c, child) => Theme(
                                  data: ThemeData.light().copyWith(
                                    colorScheme: const ColorScheme.light(
                                      primary: Colors.orange,
                                    ),
                                  ),
                                  child: child!,
                                ),
                              );
                              if (picked != null) {
                                setSheetState(() => selectedDate = picked);
                              }
                            },
                            child: Container(
                              padding: const EdgeInsets.all(14),
                              decoration: BoxDecoration(
                                border: Border.all(color: Colors.grey.shade300),
                                borderRadius: BorderRadius.circular(14),
                              ),
                              child: Row(
                                children: [
                                  const Icon(
                                    Icons.calendar_today_rounded,
                                    color: Colors.orange,
                                    size: 20,
                                  ),
                                  const SizedBox(width: 10),
                                  Text(
                                    DateFormat(
                                      'dd MMM yyyy',
                                    ).format(selectedDate),
                                    style: const TextStyle(
                                      fontSize: 14,
                                      color: Color(0xFF6D4C41),
                                    ),
                                  ),
                                  const Spacer(),
                                  const Icon(
                                    Icons.arrow_drop_down_rounded,
                                    color: Colors.grey,
                                  ),
                                ],
                              ),
                            ),
                          ),
                          const SizedBox(height: 20),
                          SizedBox(
                            width: double.infinity,
                            child: ElevatedButton(
                              onPressed: () {
                                if (!formKey.currentState!.validate()) {
                                  return;
                                }
                                context.read<GrowthBloc>().add(
                                  UpdateGrowthRecord(
                                    id: record.id,
                                    childId: record.childId,
                                    weightKg: double.parse(weightCtrl.text),
                                    heightCm: double.parse(heightCtrl.text),
                                    recordedAt: selectedDate,
                                  ),
                                );
                                Navigator.pop(ctx);
                              },
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Colors.orange,
                                padding: const EdgeInsets.symmetric(
                                  vertical: 14,
                                ),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(14),
                                ),
                                elevation: 0,
                              ),
                              child: const Text(
                                'Simpan Perubahan',
                                style: TextStyle(
                                  color: Colors.white,
                                  fontSize: 15,
                                  fontWeight: FontWeight.bold,
                                ),
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
          },
        );
      },
    );
  }

  void _submit() {
    if (!_formKey.currentState!.validate()) return;
    final weight = double.parse(_weightCtrl.text);
    final height = double.parse(_heightCtrl.text);
    context.read<GrowthBloc>().add(
      SaveGrowthRecord(
        childId: widget.childId,
        weightKg: weight,
        heightCm: height,
        recordedAt: _selectedDate,
      ),
    );
    _weightCtrl.clear();
    _heightCtrl.clear();
    setState(() => _showForm = false);
  }

  @override
  Widget build(BuildContext context) {
    return FeatureScaffold(
      title: 'Tumbuh Kembang',
      headerActions: [
        GestureDetector(
          onTap: () => setState(() => _showForm = !_showForm),
          child: Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.7),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(
              _showForm ? Icons.list_rounded : Icons.add_rounded,
              color: const Color(0xFF6D4C41),
            ),
          ),
        ),
        const SizedBox(width: 8),
      ],
      body: BlocListener<GrowthBloc, GrowthState>(
        listenWhen: (_, s) =>
            s is GrowthSaved || s is GrowthUpdated || s is GrowthError,
        listener: (context, state) {
          if (state is GrowthSaved) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('Catatan berhasil disimpan!'),
                backgroundColor: Colors.green,
              ),
            );
            setState(() => _showForm = false);
          }
          if (state is GrowthUpdated) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('Catatan berhasil diperbarui!'),
                backgroundColor: Colors.green,
              ),
            );
          }
          if (state is GrowthError) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(state.message),
                backgroundColor: Colors.red,
              ),
            );
          }
        },
        child: BlocBuilder<GrowthBloc, GrowthState>(
          builder: (context, state) {
            final records = state is GrowthLoaded
                ? state.records
                : state is GrowthSaved
                ? state.records
                : state is GrowthUpdated
                ? state.records
                : <GrowthRecord>[];
            final isLoading = state is GrowthLoading;

            return ListView(
              padding: const EdgeInsets.all(16),
              children: [
                // ── Input Form ──────────────────────────────────────────────
                if (_showForm) ...[
                  Container(
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(20),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.orange.withOpacity(0.1),
                          blurRadius: 16,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    child: Form(
                      key: _formKey,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Container(
                                padding: const EdgeInsets.all(8),
                                decoration: BoxDecoration(
                                  color: Colors.orange.withOpacity(0.12),
                                  borderRadius: BorderRadius.circular(10),
                                ),
                                child: const Icon(
                                  Icons.add_chart_rounded,
                                  color: Colors.orange,
                                ),
                              ),
                              const SizedBox(width: 10),
                              const Text(
                                'Tambah Catatan',
                                style: TextStyle(
                                  fontSize: 17,
                                  fontWeight: FontWeight.bold,
                                  color: Color(0xFF6D4C41),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 20),
                          // Weight field
                          _buildField(
                            controller: _weightCtrl,
                            label: 'Berat Badan',
                            hint: 'cth: 15.5',
                            suffix: 'kg',
                            icon: Icons.monitor_weight_outlined,
                            validator: (v) {
                              if (v == null || v.isEmpty) {
                                return 'Masukkan berat badan';
                              }
                              if (double.tryParse(v) == null) {
                                return 'Masukkan angka yang valid';
                              }
                              return null;
                            },
                          ),
                          const SizedBox(height: 14),
                          // Height field
                          _buildField(
                            controller: _heightCtrl,
                            label: 'Tinggi Badan',
                            hint: 'cth: 100.0',
                            suffix: 'cm',
                            icon: Icons.height_rounded,
                            validator: (v) {
                              if (v == null || v.isEmpty) {
                                return 'Masukkan tinggi badan';
                              }
                              if (double.tryParse(v) == null) {
                                return 'Masukkan angka yang valid';
                              }
                              return null;
                            },
                          ),
                          const SizedBox(height: 14),
                          // Date picker
                          GestureDetector(
                            onTap: () async {
                              final picked = await showDatePicker(
                                context: context,
                                initialDate: _selectedDate,
                                firstDate: DateTime(2020),
                                lastDate: DateTime.now(),
                                builder: (ctx, child) => Theme(
                                  data: ThemeData.light().copyWith(
                                    colorScheme: const ColorScheme.light(
                                      primary: Colors.orange,
                                    ),
                                  ),
                                  child: child!,
                                ),
                              );
                              if (picked != null) {
                                setState(() => _selectedDate = picked);
                              }
                            },
                            child: Container(
                              padding: const EdgeInsets.all(14),
                              decoration: BoxDecoration(
                                border: Border.all(color: Colors.grey.shade300),
                                borderRadius: BorderRadius.circular(14),
                              ),
                              child: Row(
                                children: [
                                  const Icon(
                                    Icons.calendar_today_rounded,
                                    color: Colors.orange,
                                    size: 20,
                                  ),
                                  const SizedBox(width: 10),
                                  Text(
                                    DateFormat(
                                      'dd MMM yyyy',
                                    ).format(_selectedDate),
                                    style: const TextStyle(
                                      fontSize: 14,
                                      color: Color(0xFF6D4C41),
                                    ),
                                  ),
                                  const Spacer(),
                                  const Icon(
                                    Icons.arrow_drop_down_rounded,
                                    color: Colors.grey,
                                  ),
                                ],
                              ),
                            ),
                          ),
                          const SizedBox(height: 20),
                          SizedBox(
                            width: double.infinity,
                            child: ElevatedButton(
                              onPressed: isLoading ? null : _submit,
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Colors.orange,
                                padding: const EdgeInsets.symmetric(
                                  vertical: 14,
                                ),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(14),
                                ),
                                elevation: 0,
                              ),
                              child: isLoading
                                  ? const SizedBox(
                                      width: 20,
                                      height: 20,
                                      child: CircularProgressIndicator(
                                        strokeWidth: 2,
                                        color: Colors.white,
                                      ),
                                    )
                                  : const Text(
                                      'Simpan Catatan',
                                      style: TextStyle(
                                        color: Colors.white,
                                        fontSize: 15,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 24),
                ],

                // ── Records list ────────────────────────────────────────────
                Row(
                  children: [
                    const Text(
                      'Riwayat',
                      style: TextStyle(
                        fontSize: 17,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF6D4C41),
                      ),
                    ),
                    const Spacer(),
                    if (!_showForm)
                      GestureDetector(
                        onTap: () => setState(() => _showForm = true),
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 12,
                            vertical: 6,
                          ),
                          decoration: BoxDecoration(
                            color: Colors.orange.withOpacity(0.12),
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

                if (isLoading)
                  const Center(
                    child: CircularProgressIndicator(color: Colors.orange),
                  )
                else if (records.isEmpty)
                  Container(
                    padding: const EdgeInsets.all(24),
                    decoration: BoxDecoration(
                      color: Colors.orange.withOpacity(0.06),
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(
                        color: Colors.orange.withOpacity(0.15),
                      ),
                    ),
                    child: const Column(
                      children: [
                        Icon(
                          Icons.insert_chart_outlined_rounded,
                          size: 48,
                          color: Colors.orange,
                        ),
                        SizedBox(height: 8),
                        Text(
                          'Belum ada catatan',
                          style: TextStyle(
                            fontSize: 15,
                            color: Color(0xFF6D4C41),
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                        SizedBox(height: 4),
                        Text(
                          'Tambahkan catatan pertama di form atas.',
                          style: TextStyle(
                            fontSize: 12,
                            color: Color(0xFF8D6E63),
                          ),
                          textAlign: TextAlign.center,
                        ),
                      ],
                    ),
                  )
                else
                  ...records.reversed.map(
                    (r) => _RecordCard(
                      record: r,
                      onEdit: () => _openEditSheet(context, r),
                    ),
                  ),
              ],
            );
          },
        ),
      ),
    );
  }

  Widget _buildField({
    required TextEditingController controller,
    required String label,
    required String hint,
    required String suffix,
    required IconData icon,
    String? Function(String?)? validator,
  }) {
    return TextFormField(
      controller: controller,
      keyboardType: const TextInputType.numberWithOptions(decimal: true),
      validator: validator,
      decoration: InputDecoration(
        labelText: label,
        hintText: hint,
        suffixText: suffix,
        prefixIcon: Icon(icon, color: Colors.orange, size: 20),
        filled: true,
        fillColor: Colors.grey.shade50,
        labelStyle: const TextStyle(color: Color(0xFF8D6E63)),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: BorderSide(color: Colors.grey.shade300),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: BorderSide(color: Colors.grey.shade300),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: const BorderSide(color: Colors.orange, width: 1.5),
        ),
      ),
    );
  }
}

class _RecordCard extends StatelessWidget {
  final GrowthRecord record;
  final VoidCallback onEdit;
  const _RecordCard({required this.record, required this.onEdit});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.orange.withOpacity(0.07),
            blurRadius: 10,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: Colors.orange.withOpacity(0.12),
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Icon(
              Icons.monitor_weight_outlined,
              color: Colors.orange,
              size: 22,
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '${record.weightKg} kg  ·  ${record.heightCm} cm',
                  style: const TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w600,
                    color: Color(0xFF6D4C41),
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  DateFormat('dd MMM yyyy').format(record.recordedAt),
                  style: const TextStyle(
                    fontSize: 12,
                    color: Color(0xFF8D6E63),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          GestureDetector(
            onTap: onEdit,
            child: Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: Colors.orange.withOpacity(0.10),
                borderRadius: BorderRadius.circular(10),
              ),
              child: const Icon(
                Icons.edit_rounded,
                color: Colors.orange,
                size: 18,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
