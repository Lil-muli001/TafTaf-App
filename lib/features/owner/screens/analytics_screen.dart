import 'dart:typed_data';

import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
import 'package:taftaf/core/constants/app_colors.dart';
import 'package:taftaf/core/models/ad_model.dart';
import 'package:taftaf/core/models/booking_model.dart';
import 'package:taftaf/core/models/property_model.dart';
import 'package:taftaf/core/providers/providers.dart';
import 'package:taftaf/shared/widgets/bottom_nav_bar.dart';

// ── Metric selector ───────────────────────────────────────────────────────────

enum _Metric { combined, views, likes }

// ── Colour palette (10 distinct colours) ─────────────────────────────────────

const _kPalette = [
  AppColors.primary,
  Color(0xFF3B82F6),
  Color(0xFFF97316),
  Color(0xFFA855F7),
  Color(0xFF10B981),
  Color(0xFFEC4899),
  Color(0xFFEF4444),
  Color(0xFFF59E0B),
  Color(0xFF6366F1),
  Color(0xFF14B8A6),
];

// ── Segment data ──────────────────────────────────────────────────────────────

class _Seg {
  final String name;
  final double value;
  final Color color;
  const _Seg({required this.name, required this.value, required this.color});
}

// ── PDF builder ───────────────────────────────────────────────────────────────

Future<Uint8List> _buildPdf({
  required String ownerName,
  required List<PropertyModel> properties,
  required List<AdModel> ads,
  required List<BookingModel> bookings,
}) async {
  final doc = pw.Document();
  final now = DateFormat('d MMM yyyy, h:mm a').format(DateTime.now());

  final totalViews   = properties.fold(0, (s, p) => s + p.viewCount);
  final totalLikes   = properties.fold(0, (s, p) => s + p.likedBy.length);
  final totalReviews = properties.fold(0, (s, p) => s + p.reviewCount);

  const kGreen  = PdfColor(0.0, 0.698, 0.318); // #00B251
  const kHeader = pw.TextStyle(fontWeight: pw.FontWeight.bold, color: PdfColors.white, fontSize: 10);
  const kCell   = pw.EdgeInsets.symmetric(horizontal: 8, vertical: 5);

  doc.addPage(
    pw.MultiPage(
      pageFormat: PdfPageFormat.a4,
      margin: const pw.EdgeInsets.all(36),
      footer: (ctx) => pw.Container(
        alignment: pw.Alignment.centerRight,
        child: pw.Text(
          'TafTaf — Kenya\'s Premium Real Estate Platform   •   Page ${ctx.pageNumber}/${ctx.pagesCount}',
          style: const pw.TextStyle(fontSize: 8, color: PdfColors.grey500),
        ),
      ),
      build: (ctx) => [
        // ── Header ───────────────────────────────────────────────────
        pw.Row(
          mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
          crossAxisAlignment: pw.CrossAxisAlignment.start,
          children: [
            pw.Column(
              crossAxisAlignment: pw.CrossAxisAlignment.start,
              children: [
                pw.Text('TafTaf', style: pw.TextStyle(fontSize: 26, fontWeight: pw.FontWeight.bold, color: kGreen)),
                pw.Text('Property Report', style: pw.TextStyle(fontSize: 14, color: PdfColors.grey700)),
              ],
            ),
            pw.Column(
              crossAxisAlignment: pw.CrossAxisAlignment.end,
              children: [
                pw.Text('Owner: $ownerName', style: pw.TextStyle(fontSize: 10, fontWeight: pw.FontWeight.bold)),
                pw.SizedBox(height: 3),
                pw.Text('Generated: $now', style: const pw.TextStyle(fontSize: 9, color: PdfColors.grey600)),
              ],
            ),
          ],
        ),
        pw.Divider(height: 24, color: PdfColors.grey400),

        // ── Summary ───────────────────────────────────────────────────
        pw.Text('SUMMARY', style: pw.TextStyle(fontSize: 12, fontWeight: pw.FontWeight.bold)),
        pw.SizedBox(height: 6),
        pw.TableHelper.fromTextArray(
          headers: ['Metric', 'Value'],
          data: [
            ['Total Properties', '${properties.length}'],
            ['Total Views', '$totalViews'],
            ['Total Favourites', '$totalLikes'],
            ['Total Reviews', '$totalReviews'],
            ['Total Bookings', '${bookings.length}'],
            ['Active Ad Campaigns', '${ads.where((a) => a.isActive).length}'],
          ],
          border: pw.TableBorder.all(color: PdfColors.grey300),
          headerStyle: kHeader,
          headerDecoration: const pw.BoxDecoration(color: kGreen),
          cellPadding: kCell,
        ),
        pw.SizedBox(height: 20),

        // ── Property Performance ──────────────────────────────────────
        pw.Text('PROPERTY PERFORMANCE', style: pw.TextStyle(fontSize: 12, fontWeight: pw.FontWeight.bold)),
        pw.SizedBox(height: 6),
        pw.TableHelper.fromTextArray(
          headers: ['Property', 'Type', 'Views', 'Likes', 'Rating', 'Bookings'],
          data: properties.map((p) {
            final title = p.title.length > 22 ? '${p.title.substring(0, 22)}…' : p.title;
            return [
              title,
              p.typeLabel,
              '${p.viewCount}',
              '${p.likedBy.length}',
              p.rating.toStringAsFixed(1),
              '${bookings.where((b) => b.propertyId == p.id).length}',
            ];
          }).toList(),
          border: pw.TableBorder.all(color: PdfColors.grey300),
          headerStyle: kHeader,
          headerDecoration: const pw.BoxDecoration(color: kGreen),
          cellPadding: kCell,
          columnWidths: {
            0: const pw.FlexColumnWidth(3),
            1: const pw.FlexColumnWidth(2),
            2: const pw.FlexColumnWidth(1),
            3: const pw.FlexColumnWidth(1),
            4: const pw.FlexColumnWidth(1),
            5: const pw.FlexColumnWidth(1.2),
          },
        ),
        pw.SizedBox(height: 20),

        // ── Ad Campaigns ──────────────────────────────────────────────
        if (ads.isNotEmpty) ...[
          pw.Text('AD CAMPAIGNS', style: pw.TextStyle(fontSize: 12, fontWeight: pw.FontWeight.bold)),
          pw.SizedBox(height: 6),
          pw.TableHelper.fromTextArray(
            headers: ['Property', 'Package', 'Paid (KES)', 'Impressions', 'Status', 'Expires'],
            data: ads.map((a) {
              final prop = properties.firstWhere(
                (p) => p.id == a.propertyId,
                orElse: () => properties.first,
              );
              final title = prop.title.length > 18 ? '${prop.title.substring(0, 18)}…' : prop.title;
              return [
                title,
                a.packageLabel,
                '${a.amountPaid}',
                '${a.impressions}',
                a.isActive ? 'Active' : 'Expired',
                DateFormat('d MMM yyyy').format(a.expiresAt),
              ];
            }).toList(),
            border: pw.TableBorder.all(color: PdfColors.grey300),
            headerStyle: kHeader,
            headerDecoration: const pw.BoxDecoration(color: kGreen),
            cellPadding: kCell,
            ),
          pw.SizedBox(height: 20),
        ],

        // ── Bookings ──────────────────────────────────────────────────
        if (bookings.isNotEmpty) ...[
          pw.Text('BOOKINGS', style: pw.TextStyle(fontSize: 12, fontWeight: pw.FontWeight.bold)),
          pw.SizedBox(height: 6),
          pw.TableHelper.fromTextArray(
            headers: ['Property', 'Client', 'Type', 'Status', 'Scheduled'],
            data: bookings.map((b) {
              final title = b.propertyTitle.length > 18 ? '${b.propertyTitle.substring(0, 18)}…' : b.propertyTitle;
              return [
                title,
                b.clientName,
                b.typeLabel,
                b.statusLabel,
                DateFormat('d MMM yyyy').format(b.scheduledDate),
              ];
            }).toList(),
            border: pw.TableBorder.all(color: PdfColors.grey300),
            headerStyle: kHeader,
            headerDecoration: const pw.BoxDecoration(color: kGreen),
            cellPadding: kCell,
            ),
        ],
      ],
    ),
  );

  return doc.save();
}

// ── Screen ────────────────────────────────────────────────────────────────────

class AnalyticsScreen extends ConsumerStatefulWidget {
  const AnalyticsScreen({super.key});

  @override
  ConsumerState<AnalyticsScreen> createState() => _AnalyticsScreenState();
}

class _AnalyticsScreenState extends ConsumerState<AnalyticsScreen> {
  bool _downloading = false;

  Future<void> _downloadReport() async {
    final user       = ref.read(authProvider).currentUser;
    final properties = ref.read(propertyProvider).properties;
    final allAds     = ref.read(adProvider);
    final bookings   = ref.read(bookingProvider);
    final ads        = allAds.where((a) => a.ownerId == (user?.id ?? '')).toList();

    setState(() => _downloading = true);
    try {
      await Printing.layoutPdf(
        onLayout: (_) => _buildPdf(
          ownerName:  user?.username ?? 'Owner',
          properties: properties,
          ads:        ads,
          bookings:   bookings,
        ),
        name: 'TafTaf_Report_${DateFormat('yyyyMMdd').format(DateTime.now())}.pdf',
      );
    } finally {
      if (mounted) setState(() => _downloading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final user       = ref.watch(authProvider).currentUser;
    final properties = ref.watch(propertyProvider).properties;
    final allAds     = ref.watch(adProvider);
    final ads        = allAds.where((a) => a.ownerId == (user?.id ?? '')).toList();
    final bookings   = ref.watch(bookingProvider);

    final totalViews   = properties.fold(0, (s, p) => s + p.viewCount);
    final totalLikes   = properties.fold(0, (s, p) => s + p.likedBy.length);
    final totalReviews = properties.fold(0, (s, p) => s + p.reviewCount);
    final totalBookings = bookings.length;
    final activeAds = ads.where((a) => a.isActive).length;

    return Scaffold(
      backgroundColor: context.bgColor,
      appBar: AppBar(
        title: Text('Reports', style: TextStyle(color: context.textColor, fontWeight: FontWeight.w700)),
        backgroundColor: context.bgColor,
        elevation: 0,
        leading: IconButton(
          icon: Icon(Icons.arrow_back, color: context.textColor),
          onPressed: () => context.pop(),
        ),
        actions: [
          _downloading
              ? const Padding(
                  padding: EdgeInsets.all(14),
                  child: SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2)),
                )
              : IconButton(
                  icon: const Icon(Icons.download_rounded, color: AppColors.primary),
                  tooltip: 'Download PDF Report',
                  onPressed: _downloadReport,
                ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ── Summary cards ─────────────────────────────────────────
            Row(
              children: [
                _AnalyticCard(label: 'Properties', value: '${properties.length}', icon: Icons.home_rounded, color: AppColors.primary),
                const SizedBox(width: 10),
                _AnalyticCard(label: 'Total Views', value: '$totalViews', icon: Icons.visibility_outlined, color: Colors.blue),
              ],
            ).animate().fadeIn().slideY(begin: 0.2),
            const SizedBox(height: 10),
            Row(
              children: [
                _AnalyticCard(label: 'Favourites', value: '$totalLikes', icon: Icons.favorite_rounded, color: Colors.red),
                const SizedBox(width: 10),
                _AnalyticCard(label: 'Reviews', value: '$totalReviews', icon: Icons.star_rounded, color: AppColors.star),
              ],
            ).animate().fadeIn(delay: 80.ms).slideY(begin: 0.2),
            const SizedBox(height: 10),
            Row(
              children: [
                _AnalyticCard(label: 'Bookings', value: '$totalBookings', icon: Icons.calendar_month_rounded, color: Colors.teal),
                const SizedBox(width: 10),
                _AnalyticCard(label: 'Active Ads', value: '$activeAds', icon: Icons.campaign_rounded, color: Colors.purple),
              ],
            ).animate().fadeIn(delay: 150.ms).slideY(begin: 0.2),

            if (properties.isNotEmpty) ...[
              const SizedBox(height: 28),

              // ── Ad Campaigns ─────────────────────────────────────────
              if (ads.isNotEmpty) ...[
                Text('Ad Campaigns',
                    style: TextStyle(color: context.textColor, fontSize: 16, fontWeight: FontWeight.w600)),
                const SizedBox(height: 4),
                Text('Active and recent boost campaigns across your listings.',
                    style: TextStyle(color: context.textMutedColor, fontSize: 12)),
                const SizedBox(height: 12),
                ...ads.map((a) {
                  final prop = properties.firstWhere(
                    (p) => p.id == a.propertyId,
                    orElse: () => properties.first,
                  );
                  return _AdCampaignCard(ad: a, propertyTitle: prop.title)
                      .animate().fadeIn(delay: 200.ms);
                }),
                const SizedBox(height: 28),
              ],

              // ── Bookings overview ─────────────────────────────────────
              if (bookings.isNotEmpty) ...[
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text('Bookings Overview',
                        style: TextStyle(color: context.textColor, fontSize: 16, fontWeight: FontWeight.w600)),
                  ],
                ),
                const SizedBox(height: 12),
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: context.surfaceColor,
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: context.divColor),
                  ),
                  child: Row(
                    children: [
                      _BookingStatChip(label: 'Total',     value: '${bookings.length}',                                                              color: AppColors.primary),
                      _BookingStatChip(label: 'Pending',   value: '${bookings.where((b) => b.status == BookingStatus.pending).length}',   color: Colors.orange),
                      _BookingStatChip(label: 'Confirmed', value: '${bookings.where((b) => b.status == BookingStatus.confirmed).length}', color: Colors.green),
                      _BookingStatChip(label: 'Completed', value: '${bookings.where((b) => b.status == BookingStatus.completed).length}', color: Colors.blue),
                    ],
                  ),
                ).animate().fadeIn(delay: 250.ms),
                const SizedBox(height: 28),
              ],

              // ── Views per property ────────────────────────────────────
              Text('Views per Property',
                  style: TextStyle(color: context.textColor, fontSize: 16, fontWeight: FontWeight.w600)),
              const SizedBox(height: 16),
              _ViewsBarChart(properties: properties)
                  .animate().fadeIn(delay: 300.ms),

              const SizedBox(height: 24),

              // ── Engagement distribution ───────────────────────────────
              Text('Engagement Distribution',
                  style: TextStyle(color: context.textColor, fontSize: 16, fontWeight: FontWeight.w600)),
              const SizedBox(height: 4),
              Text(
                'Tap any slice or legend chip to inspect. Shows top 6 + grouped remainder.',
                style: TextStyle(color: context.textMutedColor, fontSize: 12),
              ),
              const SizedBox(height: 16),
              _EngagementChart(properties: properties)
                  .animate().fadeIn(delay: 350.ms),

              const SizedBox(height: 24),

              // ── Property performance ──────────────────────────────────
              Text('Property Performance',
                  style: TextStyle(color: context.textColor, fontSize: 16, fontWeight: FontWeight.w600)),
              const SizedBox(height: 12),
              ...properties.map(
                (p) => _PropertyStat(
                  property: p,
                  bookingCount: bookings.where((b) => b.propertyId == p.id).length,
                ).animate().fadeIn(delay: 400.ms),
              ),
            ] else
              Center(
                child: Padding(
                  padding: const EdgeInsets.all(40),
                  child: Text('No properties to report on yet.',
                      style: TextStyle(color: context.textSecColor)),
                ),
              ),
          ],
        ),
      ),
      bottomNavigationBar: const OwnerBottomNav(currentIndex: 2),
    );
  }
}

// ── Horizontally scrollable bar chart ────────────────────────────────────────

class _ViewsBarChart extends StatelessWidget {
  final List<PropertyModel> properties;
  const _ViewsBarChart({required this.properties});

  @override
  Widget build(BuildContext context) {
    final maxY = (properties.map((p) => p.viewCount).reduce((a, b) => a > b ? a : b) + 20).toDouble();

    const barW = 24.0;
    const groupW = 52.0;
    final chartW = (properties.length * groupW).clamp(0.0, double.infinity);
    final needsScroll = properties.length > 6;

    final chart = BarChart(
      BarChartData(
        alignment: BarChartAlignment.spaceAround,
        maxY: maxY,
        barGroups: properties.asMap().entries.map((e) {
          return BarChartGroupData(
            x: e.key,
            barRods: [
              BarChartRodData(
                toY: e.value.viewCount.toDouble(),
                color: AppColors.primary,
                width: barW,
                borderRadius: const BorderRadius.vertical(top: Radius.circular(6)),
                backDrawRodData: BackgroundBarChartRodData(
                  show: true,
                  toY: maxY,
                  color: context.bgColor,
                ),
              ),
            ],
          );
        }).toList(),
        gridData: FlGridData(
          show: true,
          drawVerticalLine: false,
          getDrawingHorizontalLine: (_) => FlLine(
            color: context.divColor,
            strokeWidth: 1,
            dashArray: [4, 4],
          ),
        ),
        borderData: FlBorderData(show: false),
        barTouchData: BarTouchData(
          touchTooltipData: BarTouchTooltipData(
            getTooltipColor: (_) => context.surfaceColor,
            tooltipRoundedRadius: 8,
            getTooltipItem: (group, _, rod, _) {
              final title = properties[group.x].title;
              return BarTooltipItem(
                '${title.length > 12 ? '${title.substring(0, 12)}…' : title}\n',
                TextStyle(color: context.textColor, fontSize: 11, fontWeight: FontWeight.w600),
                children: [
                  TextSpan(
                    text: '${rod.toY.toInt()} views',
                    style: const TextStyle(color: AppColors.primary, fontWeight: FontWeight.w800, fontSize: 13),
                  ),
                ],
              );
            },
          ),
        ),
        titlesData: FlTitlesData(
          leftTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              reservedSize: 36,
              getTitlesWidget: (v, _) => Text(
                v.toInt().toString(),
                style: TextStyle(color: context.textMutedColor, fontSize: 10),
              ),
            ),
          ),
          topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
          rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
          bottomTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              getTitlesWidget: (v, _) {
                final idx = v.toInt();
                if (idx >= properties.length) return const SizedBox();
                final title = properties[idx].title;
                return Padding(
                  padding: const EdgeInsets.only(top: 6),
                  child: Text(
                    title.length > 7 ? '${title.substring(0, 7)}…' : title,
                    style: TextStyle(color: context.textSecColor, fontSize: 10),
                  ),
                );
              },
              reservedSize: 32,
            ),
          ),
        ),
      ),
    );

    return Container(
      height: 220,
      padding: const EdgeInsets.fromLTRB(8, 16, 16, 8),
      decoration: BoxDecoration(
        color: context.surfaceColor,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: context.divColor),
      ),
      child: needsScroll
          ? SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: SizedBox(width: chartW, child: chart),
            )
          : chart,
    );
  }
}

// ── Interactive engagement donut chart ───────────────────────────────────────

class _EngagementChart extends StatefulWidget {
  final List<PropertyModel> properties;
  const _EngagementChart({required this.properties});

  @override
  State<_EngagementChart> createState() => _EngagementChartState();
}

class _EngagementChartState extends State<_EngagementChart> {
  _Metric _metric = _Metric.combined;
  int _touchedIndex = -1;

  static const _kMaxSlices = 6;

  double _val(PropertyModel p) => switch (_metric) {
        _Metric.views    => p.viewCount.toDouble(),
        _Metric.likes    => p.likedBy.length.toDouble(),
        _Metric.combined => (p.viewCount + p.likedBy.length).toDouble(),
      };

  List<_Seg> get _segments {
    if (widget.properties.isEmpty) return [];
    final sorted = [...widget.properties]
      ..sort((a, b) => _val(b).compareTo(_val(a)));
    final segs = <_Seg>[];
    for (var i = 0; i < sorted.length && i < _kMaxSlices; i++) {
      segs.add(_Seg(name: sorted[i].title, value: _val(sorted[i]).clamp(1.0, double.infinity), color: _kPalette[i % _kPalette.length]));
    }
    if (sorted.length > _kMaxSlices) {
      final othersVal = sorted.skip(_kMaxSlices).fold(0.0, (s, p) => s + _val(p).clamp(1.0, double.infinity));
      segs.add(_Seg(name: 'Others (${sorted.length - _kMaxSlices})', value: othersVal, color: const Color(0xFF64748B)));
    }
    return segs;
  }

  String _fmt(double v) {
    if (v >= 1000000) return '${(v / 1000000).toStringAsFixed(1)}M';
    if (v >= 1000) return '${(v / 1000).toStringAsFixed(1)}K';
    return v.toInt().toString();
  }

  String _clip(String s, {int max = 15}) => s.length > max ? '${s.substring(0, max)}…' : s;

  String get _metricLabel => switch (_metric) {
        _Metric.views    => 'views',
        _Metric.likes    => 'likes',
        _Metric.combined => 'engagement',
      };

  @override
  Widget build(BuildContext context) {
    final segs = _segments;
    final total = segs.fold(0.0, (s, e) => s + e.value);
    final touched = (_touchedIndex >= 0 && _touchedIndex < segs.length) ? segs[_touchedIndex] : null;

    return Container(
      decoration: BoxDecoration(
        color: context.surfaceColor,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: context.divColor),
      ),
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Wrap(
            spacing: 8,
            children: _Metric.values.map((m) {
              final label = switch (m) {
                _Metric.combined => 'Combined',
                _Metric.views    => 'Views',
                _Metric.likes    => 'Likes',
              };
              final sel = _metric == m;
              return ChoiceChip(
                label: Text(label, style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: sel ? AppColors.black : context.textSecColor)),
                selected: sel,
                onSelected: (_) => setState(() { _metric = m; _touchedIndex = -1; }),
                selectedColor: AppColors.primary,
                backgroundColor: context.bgColor,
                side: BorderSide(color: sel ? AppColors.primary : context.divColor),
                padding: const EdgeInsets.symmetric(horizontal: 4),
                visualDensity: VisualDensity.compact,
                showCheckmark: false,
              );
            }).toList(),
          ),
          const SizedBox(height: 20),
          SizedBox(
            height: 210,
            child: Stack(
              alignment: Alignment.center,
              children: [
                PieChart(
                  PieChartData(
                    pieTouchData: PieTouchData(
                      touchCallback: (event, response) {
                        setState(() {
                          if (!event.isInterestedForInteractions || response == null || response.touchedSection == null) {
                            _touchedIndex = -1;
                          } else {
                            _touchedIndex = response.touchedSection!.touchedSectionIndex;
                          }
                        });
                      },
                    ),
                    sections: segs.asMap().entries.map((e) {
                      final isTouched = e.key == _touchedIndex;
                      return PieChartSectionData(
                        value: e.value.value,
                        color: e.value.color,
                        radius: isTouched ? 88 : 72,
                        title: '',
                        borderSide: isTouched ? const BorderSide(color: Colors.white, width: 2.5) : BorderSide.none,
                      );
                    }).toList(),
                    sectionsSpace: 2,
                    centerSpaceRadius: 56,
                  ),
                  duration: const Duration(milliseconds: 400),
                  curve: Curves.easeInOutCubic,
                ),
                Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      _fmt(touched?.value ?? total),
                      style: TextStyle(color: touched != null ? touched.color : context.textColor, fontSize: 24, fontWeight: FontWeight.w900, height: 1.1),
                    ),
                    const SizedBox(height: 3),
                    Text(
                      touched != null ? _clip(touched.name, max: 12) : 'Total $_metricLabel',
                      style: TextStyle(color: context.textMutedColor, fontSize: 11, fontWeight: FontWeight.w500),
                      textAlign: TextAlign.center,
                    ),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: segs.asMap().entries.map((e) {
              final isTouched = e.key == _touchedIndex;
              final pct = total > 0 ? ((e.value.value / total) * 100).toStringAsFixed(1) : '0';
              return GestureDetector(
                onTap: () => setState(() => _touchedIndex = isTouched ? -1 : e.key),
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 220),
                  padding: const EdgeInsets.fromLTRB(10, 6, 10, 6),
                  decoration: BoxDecoration(
                    color: isTouched ? e.value.color.withValues(alpha: 0.15) : context.bgColor,
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: isTouched ? e.value.color : context.divColor, width: isTouched ? 1.5 : 1),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Container(width: 9, height: 9, decoration: BoxDecoration(color: e.value.color, shape: BoxShape.circle)),
                      const SizedBox(width: 6),
                      Text(_clip(e.value.name), style: TextStyle(color: isTouched ? e.value.color : context.textSecColor, fontSize: 12, fontWeight: isTouched ? FontWeight.w700 : FontWeight.w400)),
                      const SizedBox(width: 4),
                      Text('$pct%', style: TextStyle(color: isTouched ? e.value.color.withValues(alpha: 0.8) : context.textMutedColor, fontSize: 11, fontWeight: FontWeight.w600)),
                    ],
                  ),
                ),
              );
            }).toList(),
          ),
        ],
      ),
    );
  }
}

// ── Summary card ──────────────────────────────────────────────────────────────

class _AnalyticCard extends StatelessWidget {
  final String label;
  final String value;
  final IconData icon;
  final Color color;
  const _AnalyticCard({required this.label, required this.value, required this.icon, required this.color});

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: context.surfaceColor,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: context.divColor),
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(color: color.withValues(alpha: 0.15), borderRadius: BorderRadius.circular(12)),
              child: Icon(icon, color: color, size: 22),
            ),
            const SizedBox(width: 12),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(value, style: TextStyle(color: context.textColor, fontWeight: FontWeight.bold, fontSize: 22)),
                Text(label, style: TextStyle(color: context.textSecColor, fontSize: 11)),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

// ── Per-property performance row ──────────────────────────────────────────────

class _PropertyStat extends StatelessWidget {
  final PropertyModel property;
  final int bookingCount;
  const _PropertyStat({required this.property, this.bookingCount = 0});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: context.surfaceColor,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: context.divColor),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(property.title, style: TextStyle(color: context.textColor, fontWeight: FontWeight.w600)),
          const SizedBox(height: 10),
          Wrap(
            spacing: 8,
            runSpacing: 6,
            children: [
              _StatPill(icon: Icons.visibility, value: '${property.viewCount} views', color: Colors.blue),
              _StatPill(icon: Icons.favorite, value: '${property.likedBy.length} likes', color: Colors.red),
              _StatPill(icon: Icons.star, value: property.rating.toStringAsFixed(1), color: AppColors.star),
              if (bookingCount > 0)
                _StatPill(icon: Icons.calendar_month_rounded, value: '$bookingCount bookings', color: Colors.teal),
            ],
          ),
        ],
      ),
    );
  }
}

class _StatPill extends StatelessWidget {
  final IconData icon;
  final String value;
  final Color color;
  const _StatPill({required this.icon, required this.value, required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(color: color.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(20)),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 12, color: color),
          const SizedBox(width: 4),
          Text(value, style: TextStyle(color: color, fontSize: 11, fontWeight: FontWeight.w600)),
        ],
      ),
    );
  }
}

// ── Ad campaign card ──────────────────────────────────────────────────────────

class _AdCampaignCard extends StatelessWidget {
  final AdModel ad;
  final String propertyTitle;
  const _AdCampaignCard({required this.ad, required this.propertyTitle});

  @override
  Widget build(BuildContext context) {
    final color  = ad.isActive ? Colors.purple : context.textMutedColor;
    final status = ad.isActive ? 'Active — ${AdModel.formatRemaining(ad.remaining)} left' : 'Expired';

    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: context.surfaceColor,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: context.divColor),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(color: color.withValues(alpha: 0.12), shape: BoxShape.circle),
            child: Icon(Icons.campaign_rounded, color: color, size: 18),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(propertyTitle,
                    style: TextStyle(color: context.textColor, fontWeight: FontWeight.w600, fontSize: 13),
                    maxLines: 1, overflow: TextOverflow.ellipsis),
                const SizedBox(height: 2),
                Text('${ad.packageLabel} · KES ${ad.amountPaid} · ${ad.impressions} impressions',
                    style: TextStyle(color: context.textSecColor, fontSize: 11)),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: color.withValues(alpha: 0.3)),
            ),
            child: Text(status, style: TextStyle(color: color, fontSize: 10, fontWeight: FontWeight.w700)),
          ),
        ],
      ),
    );
  }
}

// ── Booking stat chip ──────────────────────────────────────────────────────────

class _BookingStatChip extends StatelessWidget {
  final String label;
  final String value;
  final Color color;
  const _BookingStatChip({required this.label, required this.value, required this.color});

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Column(
        children: [
          Text(value, style: TextStyle(color: color, fontSize: 20, fontWeight: FontWeight.w800)),
          const SizedBox(height: 2),
          Text(label, style: TextStyle(color: context.textSecColor, fontSize: 10)),
        ],
      ),
    );
  }
}
