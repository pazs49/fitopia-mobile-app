import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';

import '../presentation/resources/index_manager.dart';

class LineChartSample7 extends StatelessWidget {
  LineChartSample7({
    super.key,
    Color? line1Color,
    Color? line2Color,
    Color? betweenColor,
    this.values = const [],
    this.labels = const [],
  })  : line1Color = line1Color ?? AppColors.contentColorGreen,
        line2Color = line2Color ?? AppColors.contentColorRed,
        betweenColor =
            betweenColor ?? AppColors.contentColorRed.withOpacity(0.5);

  final Color line1Color;
  final Color line2Color;
  final Color betweenColor;
  final List<double> values;
  final List<String> labels;

  Widget bottomTitleWidgets(double value, TitleMeta meta) {
    const style = TextStyle(
      fontSize: 12,
      fontWeight: FontWeight.bold,
    );
    final index = value.toInt();
    final text = index >= 0 && index < labels.length ? labels[index] : '';

    return SideTitleWidget(
      axisSide: meta.axisSide,
      space: 4,
      child: Text(text, style: style),
    );
  }

  Widget leftTitleWidgets(double value, TitleMeta meta) {
    const style = TextStyle(fontSize: 10);

    return SideTitleWidget(
      axisSide: meta.axisSide,
      space: 10,
      child: Text(
        value.round().toString(),
        style: style,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final chartValues =
        values.isEmpty ? const [1.0, 4.5, 2.0, 4.2, 1.9, 4.3, 2.2] : values;
    final highestValue = chartValues.fold<double>(
      0,
      (highest, value) => value > highest ? value : highest,
    );
    final chartMax = highestValue <= 0 ? 1.0 : highestValue * 1.2;
    final interval = chartMax / 4;

    return AspectRatio(
      aspectRatio: 3,
      child: Padding(
        padding: const EdgeInsets.only(
          left: 10,
          right: 18,
          top: 10,
          bottom: 4,
        ),
        child: LineChart(
          LineChartData(
            lineTouchData: LineTouchData(enabled: false),
            lineBarsData: [
              LineChartBarData(
                spots: [
                  for (var index = 0; index < chartValues.length; index++)
                    FlSpot(index.toDouble(), chartValues[index]),
                ],
                isCurved: true,
                barWidth: 2,
                color: line1Color,
                dotData: FlDotData(show: false),
              ),
            ],
            minY: 0,
            maxY: chartMax,
            borderData: FlBorderData(show: false),
            titlesData: FlTitlesData(
              bottomTitles: AxisTitles(
                sideTitles: SideTitles(
                  showTitles: true,
                  interval: 1,
                  getTitlesWidget: bottomTitleWidgets,
                ),
              ),
              leftTitles: AxisTitles(
                sideTitles: SideTitles(
                  showTitles: true,
                  getTitlesWidget: leftTitleWidgets,
                  interval: interval,
                  reservedSize: 36,
                ),
              ),
              topTitles: AxisTitles(
                sideTitles: SideTitles(showTitles: false),
              ),
              rightTitles: AxisTitles(
                sideTitles: SideTitles(showTitles: false),
              ),
            ),
            gridData: FlGridData(
              show: true,
              drawVerticalLine: false,
              horizontalInterval: interval,
            ),
          ),
        ),
      ),
    );
  }
}
