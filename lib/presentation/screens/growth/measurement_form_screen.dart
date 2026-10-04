import 'dart:async';

import 'package:arunika_app/constants/app_colors.dart';
import 'package:arunika_app/constants/app_text_styles.dart';
import 'package:arunika_app/core/growth/growth_engine.dart';
import 'package:arunika_app/core/growth/growth_format.dart';
import 'package:arunika_app/data/models/response/growth_response.dart';
import 'package:arunika_app/data/repositories/growth_repository.dart';
import 'package:arunika_app/presentation/screens/growth/delete_measurement_sheet.dart';
import 'package:arunika_app/presentation/screens/growth/growth_cubit.dart';
import 'package:arunika_app/presentation/screens/growth/growth_widgets.dart';
import 'package:arunika_app/presentation/screens/widgets/header_icon_button.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:iconsax/iconsax.dart';

enum MeasurementFormResult { saved, deleteRequested }

/// Tambah Pengukuran / Edit Pengukuran. The "Hasil menurut standar WHO"
/// preview runs the on-device engine; the server's result replaces it after
/// saving.
class MeasurementFormScreen extends StatefulWidget {
  final GrowthMeasurement? existing;

  /// Overrides "today" in tests.
  final DateTime Function() now;

  const MeasurementFormScreen({
    super.key,
    this.existing,
    this.now = DateTime.now,
  });

  @override
  State<MeasurementFormScreen> createState() => _MeasurementFormScreenState();
}

class _MeasurementFormScreenState extends State<MeasurementFormScreen> {
  late final TextEditingController _height;
  late final TextEditingController _weight;
  late DateTime _date;
  late Position _position;
  bool _positionChosen = false;
  Timer? _debounce;
  GrowthResult? _preview;
  bool _saving = false;
  bool _confirmOutlier = false;
  String? _error;

  /// Reused when the parent retries after a failure, so the server never
  /// stores the same measurement twice.
  final String _clientId = newClientId();

  bool get _isEdit => widget.existing != null;
  GrowthState get _growth => context.read<GrowthCubit>().state;
  GrowthChild get _child => _growth.child!;

  @override
  void initState() {
    super.initState();
    final e = widget.existing;
    final today = widget.now();
    _date = e?.measuredOn ?? DateTime(today.year, today.month, today.day);
    _height = TextEditingController(
      text: e?.heightCm == null ? '' : formatDecimal(e!.heightCm!),
    );
    _weight = TextEditingController(
      text: e?.weightKg == null ? '' : formatDecimal(e!.weightKg!),
    );
    _position = e?.position ?? defaultPosition(_ageDays);
    _positionChosen = e != null;
    _recompute();
  }

  @override
  void dispose() {
    _debounce?.cancel();
    _height.dispose();
    _weight.dispose();
    super.dispose();
  }

  int get _ageDays => ageInDays(_child.birthDate!, _date);

  DateTime get _today {
    final n = widget.now();
    return DateTime(n.year, n.month, n.day);
  }

  bool get _dateValid => !_date.isAfter(_today) && _ageDays >= 0;

  double? get _heightValue => parseDecimal(_height.text);
  double? get _weightValue => parseDecimal(_weight.text);

  bool get _valuesValid {
    final h = _heightValue, w = _weightValue;
    bool ok(String text, double? v) =>
        text.trim().isEmpty || (v != null && v > 0 && v < 1000);
    return (h != null || w != null) &&
        ok(_height.text, h) &&
        ok(_weight.text, w);
  }

  bool get _canSave => _dateValid && _valuesValid && !_saving;

  void _onValueChanged(String _) {
    _debounce?.cancel();
    _debounce = Timer(const Duration(milliseconds: 250), () {
      if (mounted) setState(_recompute);
    });
    // The save button reacts at once.
    setState(() {
      _error = null;
      _confirmOutlier = false;
    });
  }

  void _recompute() {
    final standard = _growth.standard;
    if (standard == null || !_dateValid) {
      _preview = null;
      return;
    }
    _preview = standard.classify(
      sex: _child.sex!,
      birthDate: _child.birthDate!,
      measuredOn: _date,
      heightCm: _heightValue,
      weightKg: _weightValue,
      position: _position,
    );
  }

  Future<void> _pickDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _date.isAfter(_today) ? _today : _date,
      firstDate: _child.birthDate!,
      lastDate: _today,
      helpText: 'Tanggal pengukuran',
    );
    if (picked == null) return;
    setState(() {
      _date = picked;
      if (!_positionChosen) _position = defaultPosition(_ageDays);
      _confirmOutlier = false;
      _recompute();
    });
  }

  Future<void> _save() async {
    if (!_canSave) return;
    _debounce?.cancel();
    _recompute();
    // Ask before sending a value outside WHO's flag limits.
    if ((_preview?.flagged ?? false) && !_confirmOutlier) {
      setState(() => _error = 'OUTLIER_NEEDS_CONFIRM');
      return;
    }
    setState(() {
      _saving = true;
      _error = null;
    });
    final input = MeasurementInput(
      measuredOn: _date,
      heightCm: _heightValue,
      weightKg: _weightValue,
      position: _position,
    );
    final cubit = context.read<GrowthCubit>();
    try {
      if (_isEdit) {
        await cubit.update(
          widget.existing!.id,
          input,
          confirmOutlier: _confirmOutlier,
        );
      } else {
        await cubit.create(
          input,
          clientId: _clientId,
          confirmOutlier: _confirmOutlier,
        );
      }
      if (mounted) Navigator.of(context).pop(MeasurementFormResult.saved);
    } on GrowthSaveException catch (e) {
      if (mounted) {
        setState(() {
          _saving = false;
          _error = e.code ?? 'NETWORK';
          if (e.needsOutlierConfirm) _confirmOutlier = false;
        });
      }
    }
  }

  void _keepAnyway() {
    setState(() {
      _confirmOutlier = true;
      _error = null;
    });
    _save();
  }

  Future<void> _delete() async {
    final ok = await showDeleteMeasurementSheet(
      context,
      measurement: widget.existing!,
      childName: _child.name,
    );
    if (ok == true && mounted) {
      Navigator.of(context).pop(MeasurementFormResult.deleteRequested);
    }
  }

  String? get _errorMessage => switch (_error) {
    null || 'OUTLIER_NEEDS_CONFIRM' => null,
    'NETWORK' => 'Gagal menyimpan. Periksa koneksi, lalu coba lagi.',
    'DATE_OUT_OF_RANGE' =>
      'Tanggal tidak boleh setelah hari ini atau sebelum tanggal lahir.',
    'PROFILE_INCOMPLETE' => 'Lengkapi tanggal lahir dan jenis kelamin anak.',
    'VALUE_REQUIRED' => 'Isi tinggi atau berat badan.',
    _ => 'Gagal menyimpan. Coba lagi, ya.',
  };

  @override
  Widget build(BuildContext context) {
    final child = _child;
    return Scaffold(
      backgroundColor: AppColors.warmPage,
      body: SafeArea(
        child: Column(
          children: [
            Expanded(
              child: ListView(
                padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
                children: [
                  Row(
                    children: [
                      HeaderIconButton(
                        icon: Icons.arrow_back_ios_new_rounded,
                        color: AppColors.textDark,
                        semanticLabel: 'Kembali',
                        onTap: () => Navigator.of(context).maybePop(),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              _isEdit ? 'Edit Pengukuran' : 'Tambah Pengukuran',
                              style: AppTextStyles.heading,
                            ),
                            Text(
                              '${child.name} · ${sexLabel(child.sex!)}',
                              style: AppTextStyles.caption.copyWith(
                                color: AppColors.textMedium,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 20),
                  _label('Tanggal pengukuran'),
                  _DateField(
                    text: formatLongDate(_date),
                    hasError: !_dateValid,
                    onTap: _pickDate,
                  ),
                  const SizedBox(height: 8),
                  if (_dateValid)
                    Text.rich(
                      TextSpan(
                        style: AppTextStyles.caption.copyWith(
                          color: AppColors.textMedium,
                        ),
                        children: [
                          const TextSpan(text: 'Umur saat diukur: '),
                          TextSpan(
                            text: ageLabelLong(_ageDays),
                            style: const TextStyle(
                              fontWeight: FontWeight.w700,
                              color: AppColors.textDark,
                            ),
                          ),
                          const TextSpan(
                            text: ' (otomatis dari tanggal lahir)',
                          ),
                        ],
                      ),
                    )
                  else
                    Text(
                      'Tanggal tidak boleh setelah hari ini atau sebelum '
                      'tanggal lahir.',
                      style: AppTextStyles.caption.copyWith(
                        color: const Color(0xFFB3261E),
                      ),
                    ),
                  const SizedBox(height: 18),
                  Row(
                    children: [
                      Expanded(
                        child: _NumberField(
                          label: 'Tinggi badan',
                          unit: 'cm',
                          controller: _height,
                          onChanged: _onValueChanged,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: _NumberField(
                          label: 'Berat badan',
                          unit: 'kg',
                          controller: _weight,
                          onChanged: _onValueChanged,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 18),
                  _label('Posisi saat diukur'),
                  GrowthSegmentedSwitch(
                    labels: const ['Berdiri', 'Berbaring'],
                    selected: _position == Position.standing ? 0 : 1,
                    onChanged: (i) => setState(() {
                      _position = i == 0
                          ? Position.standing
                          : Position.recumbent;
                      _positionChosen = true;
                      _confirmOutlier = false;
                      _recompute();
                    }),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Anak di bawah 2 tahun diukur berbaring (panjang badan).',
                    style: AppTextStyles.caption.copyWith(
                      color: AppColors.textMedium,
                    ),
                  ),
                  const SizedBox(height: 18),
                  _PreviewCard(preview: _preview),
                ],
              ),
            ),
            Container(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 12),
              decoration: const BoxDecoration(
                border: Border(top: BorderSide(color: Color(0xFFEEE7DF))),
              ),
              child: Column(
                children: [
                  // Kept next to the button so they are never scrolled away.
                  if (_error == 'OUTLIER_NEEDS_CONFIRM') ...[
                    _OutlierWarning(onKeep: _saving ? null : _keepAnyway),
                    const SizedBox(height: 10),
                  ],
                  if (_errorMessage != null) ...[
                    Text(
                      _errorMessage!,
                      style: AppTextStyles.body.copyWith(
                        color: const Color(0xFFB3261E),
                      ),
                    ),
                    const SizedBox(height: 10),
                  ],
                  SizedBox(
                    width: double.infinity,
                    height: 54,
                    child: FilledButton(
                      style: FilledButton.styleFrom(
                        backgroundColor: AppColors.ctaRust,
                        disabledBackgroundColor: AppColors.ctaRust.withValues(
                          alpha: 0.4,
                        ),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16),
                        ),
                      ),
                      onPressed: _canSave ? _save : null,
                      child: _saving
                          ? const SizedBox(
                              width: 22,
                              height: 22,
                              child: CircularProgressIndicator(
                                strokeWidth: 2.5,
                                color: Colors.white,
                              ),
                            )
                          : Text(
                              _isEdit ? 'Simpan Perubahan' : 'Simpan',
                              style: AppTextStyles.button.copyWith(
                                color: Colors.white,
                              ),
                            ),
                    ),
                  ),
                  if (_isEdit)
                    TextButton.icon(
                      style: TextButton.styleFrom(
                        minimumSize: const Size(0, 44),
                      ),
                      onPressed: _saving ? null : _delete,
                      icon: const Icon(
                        Iconsax.trash,
                        size: 18,
                        color: Color(0xFFB3261E),
                      ),
                      label: Text(
                        'Hapus data ini',
                        style: AppTextStyles.button.copyWith(
                          color: const Color(0xFFB3261E),
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

  Widget _label(String text) => Padding(
    padding: const EdgeInsets.only(bottom: 8),
    child: Text(
      text,
      style: AppTextStyles.body.copyWith(fontWeight: FontWeight.w700),
    ),
  );
}

class _DateField extends StatelessWidget {
  final String text;
  final bool hasError;
  final VoidCallback onTap;
  const _DateField({
    required this.text,
    required this.hasError,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      label: 'Tanggal pengukuran, $text',
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: onTap,
        child: Container(
          height: 56,
          padding: const EdgeInsets.symmetric(horizontal: 16),
          decoration: BoxDecoration(
            color: AppColors.white,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: hasError
                  ? const Color(0xFFB3261E)
                  : const Color(0xFFEEE7DF),
            ),
          ),
          child: Row(
            children: [
              Expanded(child: Text(text, style: AppTextStyles.bodyLarge)),
              const Icon(Iconsax.calendar_1, color: AppColors.ctaRust),
            ],
          ),
        ),
      ),
    );
  }
}

class _NumberField extends StatelessWidget {
  final String label;
  final String unit;
  final TextEditingController controller;
  final ValueChanged<String> onChanged;

  const _NumberField({
    required this.label,
    required this.unit,
    required this.controller,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    final border = OutlineInputBorder(
      borderRadius: BorderRadius.circular(16),
      borderSide: const BorderSide(color: Color(0xFFEEE7DF)),
    );
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(bottom: 8),
          child: Text(
            label,
            style: AppTextStyles.body.copyWith(fontWeight: FontWeight.w700),
          ),
        ),
        TextField(
          controller: controller,
          onChanged: onChanged,
          keyboardType: const TextInputType.numberWithOptions(decimal: true),
          // Up to 3 digits and one decimal, with a comma or a dot.
          inputFormatters: [
            FilteringTextInputFormatter.allow(RegExp(r'^\d{0,3}([.,]\d?)?')),
          ],
          style: AppTextStyles.bodyLarge.copyWith(
            fontSize: 18,
            fontWeight: FontWeight.w700,
          ),
          decoration: InputDecoration(
            filled: true,
            fillColor: AppColors.white,
            suffixText: unit,
            hintText: '0,0',
            semanticCounterText: label,
            border: border,
            enabledBorder: border,
            focusedBorder: border.copyWith(
              borderSide: const BorderSide(color: AppColors.ctaRust, width: 2),
            ),
          ),
        ),
      ],
    );
  }
}

class _PreviewCard extends StatelessWidget {
  final GrowthResult? preview;
  const _PreviewCard({required this.preview});

  @override
  Widget build(BuildContext context) {
    Widget row(String label, IndicatorResult? r) => Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          Expanded(
            child: Text(
              label,
              style: AppTextStyles.body.copyWith(color: AppColors.textDark),
            ),
          ),
          if (r == null)
            Text('–', style: AppTextStyles.body)
          else
            CategoryChip(category: r.category),
        ],
      ),
    );

    return GrowthCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Hasil menurut standar WHO',
            style: AppTextStyles.body.copyWith(fontWeight: FontWeight.w700),
          ),
          const SizedBox(height: 6),
          row('Tinggi badan / umur', preview?.hfa),
          row('Berat badan / umur', preview?.wfa),
        ],
      ),
    );
  }
}

class _OutlierWarning extends StatelessWidget {
  final VoidCallback? onKeep;
  const _OutlierWarning({required this.onKeep});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: GrowthPalette.amberSoft,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        children: [
          const Icon(Icons.info_outline_rounded, color: GrowthPalette.amber),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              'Angka ini tidak biasa. Periksa lagi, ya.',
              style: AppTextStyles.body.copyWith(
                color: GrowthPalette.amber,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          TextButton(
            style: TextButton.styleFrom(minimumSize: const Size(0, 44)),
            onPressed: onKeep,
            child: Text(
              'Tetap simpan',
              style: AppTextStyles.button.copyWith(color: GrowthPalette.amber),
            ),
          ),
        ],
      ),
    );
  }
}
