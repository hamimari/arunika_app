import 'package:arunika_app/constants/app_colors.dart';
import 'package:arunika_app/constants/app_text_styles.dart';
import 'package:arunika_app/core/growth/growth_engine.dart';
import 'package:arunika_app/core/growth/growth_format.dart';
import 'package:arunika_app/data/models/response/growth_response.dart';
import 'package:arunika_app/presentation/navigation/main_shell.dart';
import 'package:arunika_app/presentation/screens/growth/growth_chart.dart';
import 'package:arunika_app/presentation/screens/growth/growth_cubit.dart';
import 'package:arunika_app/presentation/screens/growth/growth_widgets.dart';
import 'package:arunika_app/presentation/screens/profile/profile_screen.dart';
import 'package:arunika_app/presentation/screens/widgets/error_retry_view.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:iconsax/iconsax.dart';

/// The Tumbuh tab: "Tumbuh Kembang — grafik & riwayat".
class GrowthScreen extends StatelessWidget {
  const GrowthScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.warmPage,
      body: SafeArea(
        bottom: false,
        child: BlocBuilder<GrowthCubit, GrowthState>(
          builder: (context, state) {
            if (state.summary == null) {
              if (state.status == GrowthStatus.error) {
                return ErrorRetryView(
                  message: 'Data tumbuh kembang belum bisa dimuat.',
                  onRetry: () => context.read<GrowthCubit>().load(),
                );
              }
              return const Center(
                child: CircularProgressIndicator(color: AppColors.ctaRust),
              );
            }
            return RefreshIndicator(
              color: AppColors.ctaRust,
              onRefresh: () => context.read<GrowthCubit>().load(),
              child: ListView(
                physics: const AlwaysScrollableScrollPhysics(),
                padding: const EdgeInsets.fromLTRB(16, 20, 16, 24),
                children: _content(context, state),
              ),
            );
          },
        ),
      ),
    );
  }

  List<Widget> _content(BuildContext context, GrowthState state) {
    final child = state.child!;
    final header = [
      Text('Tumbuh Kembang', style: AppTextStyles.displayLarge),
      const SizedBox(height: 2),
      Text(
        'Pantau tinggi dan berat si kecil',
        style: AppTextStyles.body.copyWith(color: AppColors.textMedium),
      ),
      const SizedBox(height: 16),
    ];

    if (!state.profileComplete ||
        child.sex == null ||
        child.birthDate == null) {
      return [...header, const _CompleteProfileCard()];
    }

    final measurements = state.measurements;
    return [
      ...header,
      _ChildHeader(child: child),
      const SizedBox(height: 12),
      if (measurements.isEmpty)
        _EmptyCard(childName: child.name)
      else
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: _SummaryTile(
                icon: Iconsax.ruler,
                label: 'Tinggi badan',
                unit: 'cm',
                latest: state.latestHeight,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _SummaryTile(
                icon: Iconsax.weight,
                label: 'Berat badan',
                unit: 'kg',
                latest: state.latestWeight,
              ),
            ),
          ],
        ),
      const SizedBox(height: 16),
      const AddMeasurementButton(),
      if (measurements.isNotEmpty && state.standard != null) ...[
        const SizedBox(height: 16),
        _ChartCard(state: state),
        const SizedBox(height: 24),
        _HistoryList(measurements: measurements),
      ],
    ];
  }
}

class AddMeasurementButton extends StatelessWidget {
  const AddMeasurementButton({super.key});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 54,
      child: FilledButton.icon(
        style: FilledButton.styleFrom(
          backgroundColor: AppColors.ctaRust,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
        ),
        onPressed: () => openMeasurementForm(context),
        icon: const Icon(Icons.add_rounded, color: Colors.white),
        label: Text(
          'Tambah Pengukuran',
          style: AppTextStyles.button.copyWith(color: Colors.white),
        ),
      ),
    );
  }
}

class _ChildHeader extends StatelessWidget {
  final GrowthChild child;
  const _ChildHeader({required this.child});

  @override
  Widget build(BuildContext context) {
    final age = ageInDays(child.birthDate!, DateTime.now());
    return GrowthCard(
      padding: const EdgeInsets.all(14),
      child: Row(
        children: [
          CircleAvatar(
            radius: 24,
            backgroundColor: const Color(0xFFFFE0B2),
            child: Text(
              child.name.isEmpty ? '?' : child.name[0].toUpperCase(),
              style: AppTextStyles.heading.copyWith(color: AppColors.ctaRust),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  child.name,
                  style: AppTextStyles.subheading,
                  overflow: TextOverflow.ellipsis,
                ),
                Text(
                  '${sexLabel(child.sex!)} · ${ageLabelLong(age)}',
                  style: AppTextStyles.caption.copyWith(
                    color: AppColors.textMedium,
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

class _SummaryTile extends StatelessWidget {
  final IconData icon;
  final String label;
  final String unit;
  final LatestValue? latest;

  const _SummaryTile({
    required this.icon,
    required this.label,
    required this.unit,
    required this.latest,
  });

  @override
  Widget build(BuildContext context) {
    final l = latest;
    return GrowthCard(
      padding: const EdgeInsets.all(14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, size: 16, color: AppColors.ctaRust),
              const SizedBox(width: 6),
              Flexible(
                child: Text(
                  label,
                  style: AppTextStyles.caption.copyWith(
                    color: AppColors.textMedium,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          Text.rich(
            TextSpan(
              children: [
                TextSpan(
                  text: l == null ? '–' : formatDecimal(l.value),
                  style: AppTextStyles.displayLarge.copyWith(fontSize: 26),
                ),
                if (l != null)
                  TextSpan(
                    text: ' $unit',
                    style: AppTextStyles.body.copyWith(
                      color: AppColors.textMedium,
                    ),
                  ),
              ],
            ),
          ),
          if (l != null) ...[
            const SizedBox(height: 8),
            CategoryChip(category: l.category),
            if (l.delta != null) ...[
              const SizedBox(height: 8),
              Text(
                '${formatSigned(l.delta!)} $unit dari pengukuran lalu',
                style: AppTextStyles.caption.copyWith(
                  color: AppColors.textMedium,
                ),
              ),
            ],
          ],
        ],
      ),
    );
  }
}

class _ChartCard extends StatefulWidget {
  final GrowthState state;
  const _ChartCard({required this.state});

  @override
  State<_ChartCard> createState() => _ChartCardState();
}

class _ChartCardState extends State<_ChartCard> {
  Indicator _indicator = Indicator.heightForAge;

  @override
  Widget build(BuildContext context) {
    final state = widget.state;
    final child = state.child!;
    final height = _indicator == Indicator.heightForAge;
    final points = chartPoints(state.measurements, _indicator);
    final window = chartWindowDays(points.map((p) => p.ageDays).toList());
    final latest = height ? state.latestHeight : state.latestWeight;
    final category = latest?.category;
    final sentence = category == null
        ? 'Belum ada data ${height ? 'tinggi' : 'berat'} badan.'
        : statusSentence(
            indicator: _indicator,
            category: category,
            childName: child.name,
          );

    return GrowthCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          GrowthSegmentedSwitch(
            labels: const ['Tinggi badan', 'Berat badan'],
            selected: height ? 0 : 1,
            onChanged: (i) => setState(
              () => _indicator = i == 0
                  ? Indicator.heightForAge
                  : Indicator.weightForAge,
            ),
          ),
          const SizedBox(height: 16),
          Text(
            height ? 'Tinggi badan menurut umur' : 'Berat badan menurut umur',
            style: AppTextStyles.subheading,
          ),
          Text(
            chartSubtitle(child.sex!, window),
            style: AppTextStyles.caption.copyWith(color: AppColors.textMedium),
          ),
          const SizedBox(height: 12),
          GrowthChart(
            standard: state.standard!,
            indicator: _indicator,
            sex: child.sex!,
            points: points,
            window: window,
            semanticLabel: sentence,
          ),
          const SizedBox(height: 12),
          _Legend(childName: child.name, height: height),
          if (child.over60Months) ...[
            const SizedBox(height: 12),
            Text(
              'Grafik menampilkan data sampai usia 5 tahun. Standar WHO 0–5 '
              'tahun tidak berlaku lagi untuk usia ${child.name} sekarang.',
              style: AppTextStyles.caption.copyWith(
                color: AppColors.textMedium,
              ),
            ),
          ],
          const SizedBox(height: 14),
          _StatusBox(sentence: sentence, category: category),
          const SizedBox(height: 12),
          Text(
            growthDisclaimer,
            style: AppTextStyles.caption.copyWith(
              color: AppColors.textMedium,
              fontSize: 11,
            ),
          ),
        ],
      ),
    );
  }
}

class _Legend extends StatelessWidget {
  final String childName;
  final bool height;
  const _Legend({required this.childName, required this.height});

  @override
  Widget build(BuildContext context) {
    final zones = height
        ? const [
            ('Tinggi', GrowthPalette.zoneBlue),
            ('Normal', GrowthPalette.zoneGreen),
            ('Pendek', GrowthPalette.zoneAmber),
            ('Sangat pendek', GrowthPalette.zoneRed),
          ]
        : const [
            ('Risiko berat badan lebih', GrowthPalette.zoneAmber),
            ('Normal', GrowthPalette.zoneGreen),
            ('Berat badan kurang', GrowthPalette.zoneAmber),
            ('Berat badan sangat kurang', GrowthPalette.zoneRed),
          ];
    final style = AppTextStyles.caption.copyWith(color: AppColors.textDark);

    Widget item(Widget mark, String label) => Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        mark,
        const SizedBox(width: 6),
        Flexible(child: Text(label, style: style)),
      ],
    );

    final entries = [
      item(
        Container(width: 16, height: 3, color: AppColors.ctaRust),
        childName,
      ),
      item(
        Text('- - -', style: style.copyWith(fontWeight: FontWeight.w700)),
        'Median WHO',
      ),
      for (final (label, color) in zones)
        item(
          Container(
            width: 14,
            height: 14,
            decoration: BoxDecoration(
              color: color,
              borderRadius: BorderRadius.circular(3),
              border: Border.all(color: Colors.black12),
            ),
          ),
          label,
        ),
    ];
    return LayoutBuilder(
      builder: (context, c) => Wrap(
        runSpacing: 8,
        children: [
          for (final e in entries) SizedBox(width: c.maxWidth / 2, child: e),
        ],
      ),
    );
  }
}

class _StatusBox extends StatelessWidget {
  final String sentence;
  final String? category;
  const _StatusBox({required this.sentence, required this.category});

  @override
  Widget build(BuildContext context) {
    final style = categoryStyle(category ?? GrowthCategory.normal);
    final hasCategory = category != null;
    // First sentence as the headline, any advice under it.
    final dot = sentence.indexOf('. ');
    final title = dot < 0 ? sentence : sentence.substring(0, dot + 1);
    final body = dot < 0 ? null : sentence.substring(dot + 2);
    final icon = switch (style.severity) {
      GrowthSeverity.normal => Icons.check_rounded,
      GrowthSeverity.urgent => Icons.priority_high_rounded,
      _ => Icons.info_outline_rounded,
    };
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: hasCategory ? style.background : const Color(0xFFF2ECE5),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (hasCategory) ...[
            CircleAvatar(
              radius: 14,
              backgroundColor: style.foreground,
              child: Icon(icon, size: 16, color: Colors.white),
            ),
            const SizedBox(width: 10),
          ],
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title.endsWith('.')
                      ? title.substring(0, title.length - 1)
                      : title,
                  style: AppTextStyles.bodyLarge.copyWith(
                    fontWeight: FontWeight.w700,
                    color: hasCategory ? style.foreground : AppColors.textDark,
                  ),
                ),
                if (body != null) ...[
                  const SizedBox(height: 4),
                  Text(
                    body,
                    style: AppTextStyles.body.copyWith(
                      color: AppColors.textDark,
                    ),
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _HistoryList extends StatelessWidget {
  final List<GrowthMeasurement> measurements;
  const _HistoryList({required this.measurements});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Row(
          children: [
            Expanded(
              child: Text(
                'Riwayat Pengukuran',
                style: AppTextStyles.heading.copyWith(fontSize: 20),
              ),
            ),
            Text(
              '${measurements.length} data',
              style: AppTextStyles.body.copyWith(color: AppColors.textMedium),
            ),
          ],
        ),
        const SizedBox(height: 12),
        GrowthCard(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 4),
          child: Column(
            children: [
              for (var i = 0; i < measurements.length; i++) ...[
                if (i > 0) const Divider(height: 1, color: Color(0xFFEEE7DF)),
                _HistoryRow(m: measurements[i]),
              ],
            ],
          ),
        ),
      ],
    );
  }
}

class _HistoryRow extends StatelessWidget {
  final GrowthMeasurement m;
  const _HistoryRow({required this.m});

  @override
  Widget build(BuildContext context) {
    final bold = AppTextStyles.bodyLarge.copyWith(fontWeight: FontWeight.w700);
    final date = formatShortDate(m.measuredOn);
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 10),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(date, style: bold),
                Text(
                  ageLabelShort(m.ageDays),
                  style: AppTextStyles.caption.copyWith(
                    color: AppColors.textMedium,
                  ),
                ),
              ],
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(valueWithUnit(m.heightCm, 'cm'), style: bold),
              Text(
                valueWithUnit(m.weightKg, 'kg'),
                style: AppTextStyles.body.copyWith(color: AppColors.textDark),
              ),
            ],
          ),
          const SizedBox(width: 4),
          IconButton(
            constraints: const BoxConstraints(minWidth: 44, minHeight: 44),
            tooltip: 'Edit pengukuran $date',
            icon: const Icon(Iconsax.edit_2, size: 20),
            color: AppColors.textDark,
            onPressed: () => openMeasurementForm(context, existing: m),
          ),
          IconButton(
            constraints: const BoxConstraints(minWidth: 44, minHeight: 44),
            tooltip: 'Hapus pengukuran $date',
            icon: const Icon(Iconsax.trash, size: 20),
            color: const Color(0xFFB3261E),
            onPressed: () => deleteMeasurementWithUndo(context, m),
          ),
        ],
      ),
    );
  }
}

class _EmptyCard extends StatelessWidget {
  final String childName;
  const _EmptyCard({required this.childName});

  @override
  Widget build(BuildContext context) {
    return GrowthCard(
      child: Text(
        'Belum ada pengukuran. Catat tinggi dan berat $childName untuk melihat '
        'grafik sesuai standar WHO.',
        style: AppTextStyles.body.copyWith(color: AppColors.textMedium),
      ),
    );
  }
}

class _CompleteProfileCard extends StatelessWidget {
  const _CompleteProfileCard();

  @override
  Widget build(BuildContext context) {
    return GrowthCard(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Lengkapi profil anak', style: AppTextStyles.subheading),
          const SizedBox(height: 6),
          Text(
            'Kami butuh tanggal lahir dan jenis kelamin si kecil untuk '
            'membandingkan tinggi dan beratnya dengan standar WHO.',
            style: AppTextStyles.body.copyWith(color: AppColors.textMedium),
          ),
          const SizedBox(height: 16),
          SizedBox(
            width: double.infinity,
            height: 50,
            child: FilledButton(
              style: FilledButton.styleFrom(
                backgroundColor: AppColors.ctaRust,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
              ),
              onPressed: () {
                MainShell.shellKey.currentState?.switchTab(MainShellTab.profil);
                ProfileScreen.editRequested.value = true;
              },
              child: Text(
                'Lengkapi profil',
                style: AppTextStyles.button.copyWith(color: Colors.white),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
