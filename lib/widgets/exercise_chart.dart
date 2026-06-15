import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:intl/intl.dart';
import '../models/exercise_log.dart';
import '../theme/app_theme.dart';

class ExerciseChart extends StatefulWidget {
  final List<MapEntry<DateTime, ExerciseLog>> history;
  final bool showOneRepMax;
  final bool isCalisthenics;

  const ExerciseChart({
    super.key,
    required this.history,
    required this.showOneRepMax,
    this.isCalisthenics = false,
  });

  @override
  State<ExerciseChart> createState() => _ExerciseChartState();
}

class _CustomLineChartSpotData {
  final List<FlSpot> spots;
  final double minX;
  final double maxX;
  final double minY;
  final double maxY;

  _CustomLineChartSpotData({
    required this.spots,
    required this.minX,
    required this.maxX,
    required this.minY,
    required this.maxY,
  });
}

class _ExerciseChartState extends State<ExerciseChart> {
  _CustomLineChartSpotData _prepareData() {
    final List<FlSpot> spots = [];
    if (widget.history.isEmpty) {
      return _CustomLineChartSpotData(spots: [], minX: 0, maxX: 0, minY: 0, maxY: 0);
    }

    double minY = double.infinity;
    double maxY = double.negativeInfinity;

    for (int i = 0; i < widget.history.length; i++) {
      final log = widget.history[i].value;
      final val = widget.isCalisthenics
          ? log.maxReps.toDouble()
          : (widget.showOneRepMax ? log.estimatedOneRepMax : log.maxWeight);
      spots.add(FlSpot(i.toDouble(), val));

      if (val < minY) minY = val;
      if (val > maxY) maxY = val;
    }

    // Add padding to Y axis
    if (minY == maxY) {
      minY = (minY - 10).clamp(0, double.infinity);
      maxY = maxY + 10;
    } else {
      final range = maxY - minY;
      minY = (minY - range * 0.15).clamp(0, double.infinity);
      maxY = maxY + range * 0.15;
    }

    return _CustomLineChartSpotData(
      spots: spots,
      minX: 0,
      maxX: (widget.history.length - 1).toDouble(),
      minY: minY,
      maxY: maxY,
    );
  }

  @override
  Widget build(BuildContext context) {
    if (widget.history.length < 2) {
      return Container(
        height: 200,
        decoration: BoxDecoration(
          color: AppTheme.surface,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: AppTheme.border),
        ),
        child: const Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.show_chart, color: AppTheme.textSecondary, size: 40),
              SizedBox(height: 12),
              Text(
                'Log at least 2 sessions to view progress chart',
                style: TextStyle(color: AppTheme.textSecondary, fontSize: 13),
              ),
            ],
          ),
        ),
      );
    }

    final chartData = _prepareData();
    final accentColor = widget.isCalisthenics
        ? AppTheme.primary
        : (widget.showOneRepMax ? AppTheme.secondary : AppTheme.primary);

    return Container(
      height: 240,
      padding: const EdgeInsets.fromLTRB(12, 24, 24, 12),
      decoration: BoxDecoration(
        color: AppTheme.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppTheme.border),
      ),
      child: LineChart(
        LineChartData(
          gridData: FlGridData(
            show: true,
            drawVerticalLine: false,
            getDrawingHorizontalLine: (value) {
              return const FlLine(
                color: AppTheme.border,
                strokeWidth: 1,
              );
            },
          ),
          titlesData: FlTitlesData(
            show: true,
            rightTitles: const AxisTitles(
              sideTitles: SideTitles(showTitles: false),
            ),
            topTitles: const AxisTitles(
              sideTitles: SideTitles(showTitles: false),
            ),
            bottomTitles: AxisTitles(
              sideTitles: SideTitles(
                showTitles: true,
                reservedSize: 24,
                interval: (widget.history.length / 4).ceil().toDouble(),
                getTitlesWidget: (value, meta) {
                  final index = value.toInt();
                  if (index >= 0 && index < widget.history.length) {
                    final date = widget.history[index].key;
                    return SideTitleWidget(
                      axisSide: meta.axisSide,
                      child: Text(
                        DateFormat('MM/dd').format(date),
                        style: const TextStyle(
                          color: AppTheme.textSecondary,
                          fontSize: 10,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    );
                  }
                  return const SizedBox.shrink();
                },
              ),
            ),
            leftTitles: AxisTitles(
              sideTitles: SideTitles(
                showTitles: true,
                reservedSize: 45,
                getTitlesWidget: (value, meta) {
                  final label = widget.isCalisthenics ? '${value.toInt()} r' : '${value.toInt()}kg';
                  return SideTitleWidget(
                    axisSide: meta.axisSide,
                    child: Text(
                      label,
                      style: const TextStyle(
                        color: AppTheme.textSecondary,
                        fontSize: 10,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  );
                },
              ),
            ),
          ),
          borderData: FlBorderData(
            show: false,
          ),
          minX: chartData.minX,
          maxX: chartData.maxX,
          minY: chartData.minY,
          maxY: chartData.maxY,
          lineTouchData: LineTouchData(
            touchTooltipData: LineTouchTooltipData(
              getTooltipColor: (spot) => AppTheme.surfaceLight,
              tooltipRoundedRadius: 8,
              getTooltipItems: (touchedSpots) {
                return touchedSpots.map((spot) {
                  final index = spot.x.toInt();
                  final date = widget.history[index].key;
                  final dateStr = DateFormat('MMM dd, yyyy').format(date);
                  final valueStr = widget.isCalisthenics
                      ? '${spot.y.toInt()} reps'
                      : '${spot.y.toStringAsFixed(1)} kg';
                  return LineTooltipItem(
                    '$dateStr\n$valueStr',
                    const TextStyle(
                      color: Colors.white,
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                    ),
                  );
                }).toList();
              },
            ),
          ),
          lineBarsData: [
            LineChartBarData(
              spots: chartData.spots,
              isCurved: true,
              color: accentColor,
              barWidth: 3,
              isStrokeCapRound: true,
              dotData: FlDotData(
                show: true,
                getDotPainter: (spot, percent, barData, index) => FlDotCirclePainter(
                  radius: 4,
                  color: AppTheme.background,
                  strokeWidth: 2.5,
                  strokeColor: accentColor,
                ),
              ),
              belowBarData: BarAreaData(
                show: true,
                gradient: LinearGradient(
                  colors: [
                    accentColor.withAlpha(80),
                    accentColor.withAlpha(0),
                  ],
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
