import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:hugeicons/hugeicons.dart';
import 'package:tu_lojita_business/core/theme/app_theme.dart';
import 'package:tu_lojita_business/core/widgets/dual_price_text.dart';
import 'package:tu_lojita_business/features/dashboard/domain/entities/dashboard_analytics.dart';

enum SalesChartMode { area, bars }

const double _kChartTopPad = 8.0;
const double _kChartBottomPad = 4.0;
const double _kChartHorizontalPad = 10.0;
const double _kBarSlotWidth = 38.0;

class HomeSalesTrendChart extends StatefulWidget {
  final List<SalesChartPoint> salesChart;
  final String period;

  const HomeSalesTrendChart({
    super.key,
    required this.salesChart,
    required this.period,
  });

  @override
  State<HomeSalesTrendChart> createState() => _HomeSalesTrendChartState();
}

class _HomeSalesTrendChartState extends State<HomeSalesTrendChart> {
  SalesChartMode _mode = SalesChartMode.area;
  int? _selectedIndex;
  final ScrollController _barsScrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    _selectedIndex = _defaultSelectedIndex(widget.salesChart);
  }

  @override
  void didUpdateWidget(covariant HomeSalesTrendChart oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.salesChart != widget.salesChart ||
        oldWidget.period != widget.period) {
      _selectedIndex = _defaultSelectedIndex(widget.salesChart);
      if (_mode == SalesChartMode.bars) {
        _scheduleBarsScrollToSelection();
      }
    }
  }

  @override
  void dispose() {
    _barsScrollController.dispose();
    super.dispose();
  }

  int? _defaultSelectedIndex(List<SalesChartPoint> points) {
    if (points.isEmpty) return null;
    double maxVal = -1;
    int peakIdx = points.length - 1;
    for (int i = 0; i < points.length; i++) {
      if (points[i].sales > maxVal) {
        maxVal = points[i].sales;
        peakIdx = i;
      }
    }
    return peakIdx;
  }

  void _scheduleBarsScrollToSelection() {
    if (widget.salesChart.length <= 8) return;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted || !_barsScrollController.hasClients) return;
      final position = _barsScrollController.position;
      if (position.maxScrollExtent <= 0) return;

      final idx = (_selectedIndex ?? widget.salesChart.length - 1)
          .clamp(0, widget.salesChart.length - 1);
      final targetOffset = (idx * _kBarSlotWidth -
              position.viewportDimension / 2 +
              _kBarSlotWidth / 2)
          .clamp(0.0, position.maxScrollExtent);

      _barsScrollController.animateTo(
        targetOffset,
        duration: const Duration(milliseconds: 280),
        curve: Curves.easeOutCubic,
      );
    });
  }

  String _formatCompactAxis(double amount) {
    if (amount >= 1000000) {
      return '\$${(amount / 1000000).toStringAsFixed(1)}M';
    }
    if (amount >= 1000) {
      return '\$${(amount / 1000).toStringAsFixed(1)}k';
    }
    return '\$${amount.toStringAsFixed(0)}';
  }

  List<int> _areaLabelIndices(int length) {
    if (length <= 0) return const [];
    if (length <= 5) return List.generate(length, (i) => i);
    final indices = <int>{};
    for (int step = 0; step < 5; step++) {
      indices.add((step * (length - 1) / 4).round().clamp(0, length - 1));
    }
    return indices.toList()..sort();
  }

  @override
  Widget build(BuildContext context) {
    final points = widget.salesChart;
    final maxSales = points.fold<double>(
      0.0,
      (max, p) => p.sales > max ? p.sales : max,
    );
    final double niceMax = maxSales > 0 ? maxSales : 100.0;
    final int? peakIdx = _defaultSelectedIndex(points);
    final int? safeIndex = (points.isNotEmpty &&
            _selectedIndex != null &&
            _selectedIndex! >= 0 &&
            _selectedIndex! < points.length)
        ? _selectedIndex
        : (points.isNotEmpty ? points.length - 1 : null);
    final selectedPoint = safeIndex != null ? points[safeIndex] : null;
    final bool isPeakSelected =
        maxSales > 0 && safeIndex != null && safeIndex == peakIdx;

    final double textScale =
        MediaQuery.textScalerOf(context).scale(1.0).clamp(1.0, 1.35);
    final double xAxisHeight = (18.0 * textScale).ceilToDouble();
    const double xAxisGap = 8.0;
    final double chartBoxHeight = 152.0 + xAxisGap + xAxisHeight;

    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: TuLojitaBrandColors.surface,
        borderRadius: BorderRadius.circular(22),
        border: Border.all(
          color: TuLojitaBrandColors.borderSubtle,
          width: 1.5,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.025),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header + [Área | Barras] Toggle
          Row(
            children: [
              const Expanded(
                child: Text(
                  'Evolución de Ventas',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w800,
                    letterSpacing: -0.4,
                    color: TuLojitaBrandColors.inkPrimary,
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Container(
                padding: const EdgeInsets.all(3),
                decoration: BoxDecoration(
                  color: TuLojitaBrandColors.canvas,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: TuLojitaBrandColors.borderMuted),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    _ModeTab(
                      label: 'Área',
                      selected: _mode == SalesChartMode.area,
                      onTap: () => setState(() => _mode = SalesChartMode.area),
                    ),
                    _ModeTab(
                      label: 'Barras',
                      selected: _mode == SalesChartMode.bars,
                      onTap: () {
                        setState(() => _mode = SalesChartMode.bars);
                        _scheduleBarsScrollToSelection();
                      },
                    ),
                  ],
                ),
              ),
            ],
          ),

          if (selectedPoint != null) ...[
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 9),
              decoration: BoxDecoration(
                color: TuLojitaBrandColors.canvas,
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: TuLojitaBrandColors.indigo100),
              ),
              child: Row(
                children: [
                  Container(
                    width: 8,
                    height: 8,
                    decoration: const BoxDecoration(
                      color: TuLojitaBrandColors.amber400,
                      shape: BoxShape.circle,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Flexible(
                              child: Text(
                                selectedPoint.label,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: const TextStyle(
                                  fontSize: 12,
                                  fontWeight: FontWeight.w800,
                                  color: TuLojitaBrandColors.inkPrimary,
                                ),
                              ),
                            ),
                            if (isPeakSelected) ...[
                              const SizedBox(width: 6),
                              Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 6,
                                  vertical: 1.5,
                                ),
                                decoration: BoxDecoration(
                                  color: TuLojitaBrandColors.amber100,
                                  borderRadius: BorderRadius.circular(6),
                                ),
                                child: const Text(
                                  'Pico',
                                  style: TextStyle(
                                    fontSize: 9.5,
                                    fontWeight: FontWeight.w800,
                                    color: TuLojitaBrandColors.amber700,
                                  ),
                                ),
                              ),
                            ],
                          ],
                        ),
                        Text(
                          '${selectedPoint.ordersCount} ${selectedPoint.ordersCount == 1 ? 'pedido' : 'pedidos'} · Toca o desliza',
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            fontSize: 10.5,
                            fontWeight: FontWeight.w600,
                            color: TuLojitaBrandColors.inkSecondary,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 8),
                  ConstrainedBox(
                    constraints: const BoxConstraints(maxWidth: 145),
                    child: DualPriceText(
                      amountInUsd: selectedPoint.sales,
                      crossAxisAlignment: CrossAxisAlignment.end,
                      usdStyle: const TextStyle(
                        fontSize: 13.5,
                        fontWeight: FontWeight.w800,
                        color: TuLojitaBrandColors.indigo600,
                      ),
                      bsStyle: const TextStyle(
                        fontSize: 10,
                        fontWeight: FontWeight.w600,
                        color: TuLojitaBrandColors.inkSecondary,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],

          const SizedBox(height: 16),

          if (points.isEmpty)
            const Padding(
              padding: EdgeInsets.symmetric(vertical: 28),
              child: Center(
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    HugeIcon(
                      icon: HugeIcons.strokeRoundedAnalytics01,
                      color: TuLojitaBrandColors.inkSecondary,
                      size: 18,
                    ),
                    SizedBox(width: 8),
                    Flexible(
                      child: Text(
                        'Sin datos de ventas en este período',
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          fontSize: 12.5,
                          fontWeight: FontWeight.w500,
                          color: TuLojitaBrandColors.inkSecondary,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            )
          else
            SizedBox(
              height: chartBoxHeight,
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // Y-axis reference labels synced with _GuideLinesPainter
                  SizedBox(
                    width: 44,
                    child: Padding(
                      padding: EdgeInsets.only(
                        top: _kChartTopPad,
                        bottom: _kChartBottomPad + xAxisGap + xAxisHeight,
                      ),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: [
                          Text(
                            _formatCompactAxis(niceMax),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                              fontSize: 9.5,
                              fontWeight: FontWeight.w600,
                              color: TuLojitaBrandColors.inkSecondary,
                            ),
                          ),
                          Text(
                            _formatCompactAxis(niceMax / 2),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                              fontSize: 9.5,
                              fontWeight: FontWeight.w600,
                              color: TuLojitaBrandColors.inkSecondary,
                            ),
                          ),
                          const Text(
                            '\$0',
                            style: TextStyle(
                              fontSize: 9.5,
                              fontWeight: FontWeight.w600,
                              color: TuLojitaBrandColors.inkSecondary,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: _mode == SalesChartMode.area
                        ? _buildAreaChart(
                            points,
                            niceMax,
                            safeIndex!,
                            xAxisGap,
                            xAxisHeight,
                          )
                        : _buildBarsChart(
                            points,
                            niceMax,
                            safeIndex!,
                            xAxisGap,
                            xAxisHeight,
                          ),
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildAreaChart(
    List<SalesChartPoint> points,
    double niceMax,
    int selectedIdx,
    double xAxisGap,
    double xAxisHeight,
  ) {
    final labelIndices = _areaLabelIndices(points.length);

    return Column(
      children: [
        Expanded(
          child: LayoutBuilder(
            builder: (context, constraints) {
              final chartWidth = math.max(1.0, constraints.maxWidth);
              final plotWidth = math.max(1.0, chartWidth - _kChartHorizontalPad * 2);

              void updateSelection(double dx) {
                if (points.length <= 1) {
                  setState(() => _selectedIndex = 0);
                  return;
                }
                final clamped = (dx - _kChartHorizontalPad).clamp(0.0, plotWidth);
                final idx = ((clamped / plotWidth) * (points.length - 1))
                    .round()
                    .clamp(0, points.length - 1);
                if (idx != _selectedIndex) {
                  setState(() => _selectedIndex = idx);
                }
              }

              return GestureDetector(
                behavior: HitTestBehavior.opaque,
                onTapDown: (d) => updateSelection(d.localPosition.dx),
                onHorizontalDragUpdate: (d) =>
                    updateSelection(d.localPosition.dx),
                child: CustomPaint(
                  size: Size(chartWidth, constraints.maxHeight),
                  painter: _AreaTrendPainter(
                    values: points.map((p) => p.sales).toList(),
                    maxScale: niceMax,
                    selectedIndex: selectedIdx,
                  ),
                ),
              );
            },
          ),
        ),
        SizedBox(height: xAxisGap),
        SizedBox(
          height: xAxisHeight,
          child: Row(
            mainAxisAlignment: points.length == 1
                ? MainAxisAlignment.center
                : MainAxisAlignment.spaceBetween,
            children: labelIndices.map((idx) {
              final isSelected = idx == selectedIdx;
              return Flexible(
                child: Text(
                  points[idx].label,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontSize: 9.5,
                    fontWeight: isSelected ? FontWeight.w800 : FontWeight.w600,
                    color: isSelected
                        ? TuLojitaBrandColors.indigo600
                        : TuLojitaBrandColors.inkSecondary,
                  ),
                ),
              );
            }).toList(),
          ),
        ),
      ],
    );
  }

  Widget _buildBarsChart(
    List<SalesChartPoint> points,
    double niceMax,
    int selectedIdx,
    double xAxisGap,
    double xAxisHeight,
  ) {
    final bool useHorizontalScroll = points.length > 8;

    return LayoutBuilder(
      builder: (context, constraints) {
        final double plotTotalHeight =
            math.max(1.0, constraints.maxHeight - xAxisGap - xAxisHeight);
        final double barTrackHeight =
            math.max(1.0, plotTotalHeight - _kChartTopPad - _kChartBottomPad);

        Widget buildBarSlot(int i, {double? fixedWidth}) {
          final point = points[i];
          final isSelected = i == selectedIdx;
          final bool hasValue = point.sales > 0;
          final double factor =
              hasValue ? (point.sales / niceMax).clamp(0.05, 1.0) : 0.04;

          final slotContent = GestureDetector(
            behavior: HitTestBehavior.opaque,
            onTap: () => setState(() => _selectedIndex = i),
            child: SizedBox(
              width: fixedWidth,
              child: Column(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  Expanded(
                    child: Padding(
                      padding: const EdgeInsets.only(
                        top: _kChartTopPad,
                        bottom: _kChartBottomPad,
                      ),
                      child: Align(
                        alignment: Alignment.bottomCenter,
                        child: AnimatedContainer(
                          duration: const Duration(milliseconds: 280),
                          width: 16,
                          height: barTrackHeight * factor,
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              begin: Alignment.bottomCenter,
                              end: Alignment.topCenter,
                              colors: isSelected
                                  ? const [
                                      TuLojitaBrandColors.amber500,
                                      TuLojitaBrandColors.amber400,
                                    ]
                                  : hasValue
                                      ? const [
                                          TuLojitaBrandColors.indigo600,
                                          TuLojitaBrandColors.indigo500,
                                        ]
                                      : const [
                                          Color(0xFFE2E8F0),
                                          Color(0xFFE2E8F0),
                                        ],
                            ),
                            borderRadius: BorderRadius.circular(6),
                          ),
                        ),
                      ),
                    ),
                  ),
                  SizedBox(height: xAxisGap),
                  SizedBox(
                    height: xAxisHeight,
                    child: FittedBox(
                      fit: BoxFit.scaleDown,
                      child: Text(
                        point.label,
                        style: TextStyle(
                          fontSize: 9.5,
                          fontWeight:
                              isSelected ? FontWeight.w800 : FontWeight.w600,
                          color: isSelected
                              ? TuLojitaBrandColors.inkPrimary
                              : TuLojitaBrandColors.inkSecondary,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          );

          return fixedWidth != null
              ? slotContent
              : Expanded(child: slotContent);
        }

        return Stack(
          children: [
            Positioned.fill(
              bottom: xAxisGap + xAxisHeight,
              child: CustomPaint(painter: _GuideLinesPainter()),
            ),
            if (!useHorizontalScroll)
              Row(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: List.generate(points.length, (i) => buildBarSlot(i)),
              )
            else
              SingleChildScrollView(
                controller: _barsScrollController,
                scrollDirection: Axis.horizontal,
                physics: const BouncingScrollPhysics(),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: List.generate(
                    points.length,
                    (i) => buildBarSlot(i, fixedWidth: _kBarSlotWidth),
                  ),
                ),
              ),
          ],
        );
      },
    );
  }
}

class _ModeTab extends StatelessWidget {
  final String label;
  final bool selected;
  final VoidCallback onTap;

  const _ModeTab({
    required this.label,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
        decoration: BoxDecoration(
          color: selected ? TuLojitaBrandColors.indigo600 : Colors.transparent,
          borderRadius: BorderRadius.circular(9),
        ),
        child: Text(
          label,
          style: TextStyle(
            fontSize: 11,
            fontWeight: FontWeight.w700,
            color: selected ? Colors.white : TuLojitaBrandColors.inkSecondary,
          ),
        ),
      ),
    );
  }
}

class _GuideLinesPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final guidePaint = Paint()
      ..color = TuLojitaBrandColors.borderMuted
      ..strokeWidth = 1;

    final usableH = math.max(1.0, size.height - _kChartTopPad - _kChartBottomPad);
    for (final ratio in [0.0, 0.5, 1.0]) {
      final y = _kChartTopPad + usableH * ratio;
      canvas.drawLine(Offset(0, y), Offset(size.width, y), guidePaint);
    }
  }

  @override
  bool shouldRepaint(covariant _GuideLinesPainter oldDelegate) => false;
}

class _AreaTrendPainter extends CustomPainter {
  final List<double> values;
  final double maxScale;
  final int selectedIndex;

  const _AreaTrendPainter({
    required this.values,
    required this.maxScale,
    required this.selectedIndex,
  });

  @override
  void paint(Canvas canvas, Size size) {
    _GuideLinesPainter().paint(canvas, size);

    if (values.isEmpty) return;

    final double usableH =
        math.max(1.0, size.height - _kChartTopPad - _kChartBottomPad);
    final double plotWidth =
        math.max(1.0, size.width - _kChartHorizontalPad * 2);
    final double safeMax = maxScale > 0 ? maxScale : 100.0;

    final coords = <Offset>[];
    if (values.length == 1) {
      final norm = (values.first / safeMax).clamp(0.0, 1.0);
      final y = _kChartTopPad + usableH * (1 - norm);
      coords.add(Offset(size.width / 2, y));
    } else {
      final stepX = plotWidth / (values.length - 1);
      for (int i = 0; i < values.length; i++) {
        final norm = (values[i] / safeMax).clamp(0.0, 1.0);
        final x = _kChartHorizontalPad + i * stepX;
        final y = _kChartTopPad + usableH * (1 - norm);
        coords.add(Offset(x, y));
      }
    }

    final linePaint = Paint()
      ..color = TuLojitaBrandColors.indigo600
      ..strokeWidth = 2.5
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;

    final double baselineY = size.height - _kChartBottomPad;

    if (coords.length > 1) {
      final path = Path()..moveTo(coords.first.dx, coords.first.dy);
      for (int i = 0; i < coords.length - 1; i++) {
        final p0 = coords[i];
        final p1 = coords[i + 1];
        final ctrlX = (p0.dx + p1.dx) / 2;
        path.cubicTo(ctrlX, p0.dy, ctrlX, p1.dy, p1.dx, p1.dy);
      }

      final fillPath = Path.from(path)
        ..lineTo(coords.last.dx, baselineY)
        ..lineTo(coords.first.dx, baselineY)
        ..close();

      final fillPaint = Paint()
        ..shader = LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            TuLojitaBrandColors.indigo600.withValues(alpha: 0.22),
            TuLojitaBrandColors.indigo600.withValues(alpha: 0.0),
          ],
        ).createShader(Rect.fromLTWH(0, _kChartTopPad, size.width, usableH));

      canvas.drawPath(fillPath, fillPaint);
      canvas.drawPath(path, linePaint);
    } else {
      canvas.drawLine(
        Offset(_kChartHorizontalPad, coords.first.dy),
        Offset(size.width - _kChartHorizontalPad, coords.first.dy),
        linePaint,
      );
    }

    final idx = selectedIndex.clamp(0, coords.length - 1);
    final activePoint = coords[idx];

    canvas.drawLine(
      Offset(activePoint.dx, _kChartTopPad),
      Offset(activePoint.dx, baselineY),
      Paint()
        ..color = TuLojitaBrandColors.amber400.withValues(alpha: 0.45)
        ..strokeWidth = 1.2,
    );

    canvas.drawCircle(
      activePoint,
      9,
      Paint()..color = TuLojitaBrandColors.amber400.withValues(alpha: 0.28),
    );
    canvas.drawCircle(
      activePoint,
      5.5,
      Paint()..color = TuLojitaBrandColors.amber400,
    );
    canvas.drawCircle(
      activePoint,
      3,
      Paint()..color = TuLojitaBrandColors.indigo600,
    );
  }

  @override
  bool shouldRepaint(covariant _AreaTrendPainter oldDelegate) {
    return oldDelegate.values != values ||
        oldDelegate.maxScale != maxScale ||
        oldDelegate.selectedIndex != selectedIndex;
  }
}
