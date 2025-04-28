import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:intl/intl.dart';
import 'package:logger/logger.dart';
import '../services/health_service.dart';

class ChartData {
  final double value;
  final String title;
  final int index;

  ChartData(this.index, dynamic value, this.title)
      : value = (value is int) ? value.toDouble() : (value as double);
}

class DetailedReportPage extends StatefulWidget {
  final DateTime? startDate;
  final DateTime? endDate;

  const DetailedReportPage({
    Key? key,
    this.startDate,
    this.endDate,
  }) : super(key: key);

  @override
  State<DetailedReportPage> createState() => _DetailedReportPageState();
}

class _DetailedReportPageState extends State<DetailedReportPage> {
  final logger = Logger();
  bool _isLoading = false;

  // 图表数据
  List<ChartData> _weightTrend = [];
  List<ChartData> _systolicTrend = [];
  List<ChartData> _diastolicTrend = [];
  List<ChartData> _sleepTrend = [];
  List<ChartData> _heartRateTrend = [];

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    setState(() {
      _isLoading = true;
    });

    try {
      final HealthService healthService = HealthService();
      final startDate =
          widget.startDate ?? DateTime.now().subtract(const Duration(days: 7));

      // 获取心率趋势
      _heartRateTrend = (await healthService.getHeartRateTrend(
        startDate,
        widget.endDate ?? DateTime.now(),
      ))
          .asMap()
          .entries
          .map((entry) => ChartData(
                entry.key,
                entry.value['value'],
                entry.value['title'],
              ))
          .toList();

      // 获取睡眠趋势
      _sleepTrend = (await healthService.getSleepTrend(
        startDate,
        widget.endDate ?? DateTime.now(),
      ))
          .asMap()
          .entries
          .map((entry) => ChartData(
                entry.key,
                entry.value['value'],
                entry.value['title'],
              ))
          .toList();

      // 获取体重趋势
      _weightTrend = (await healthService.getWeightTrend(
        startDate,
        widget.endDate ?? DateTime.now(),
      ))
          .asMap()
          .entries
          .map((entry) => ChartData(
                entry.key,
                entry.value['value'],
                entry.value['title'],
              ))
          .toList();

      // 获取血压趋势
      final bloodPressureData = await healthService.getBloodPressureTrend(
        startDate,
        widget.endDate ?? DateTime.now(),
      );

      _systolicTrend = bloodPressureData['systolic']!
          .asMap()
          .entries
          .map((entry) => ChartData(
                entry.key,
                entry.value['value'],
                entry.value['title'],
              ))
          .toList();

      _diastolicTrend = bloodPressureData['diastolic']!
          .asMap()
          .entries
          .map((entry) => ChartData(
                entry.key,
                entry.value['value'],
                entry.value['title'],
              ))
          .toList();

      setState(() {
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _isLoading = false;
      });
      if (mounted) {
        logger.d(e.toString());
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('加载数据失败: ${e.toString()}')),
        );
      }
    }
  }

  PreferredSizeWidget _buildAppBar() {
    return AppBar(
      backgroundColor: Colors.white,
      elevation: 0,
      leading: IconButton(
        icon: const Icon(Icons.arrow_back, color: Colors.black),
        onPressed: () => Navigator.of(context).pop(),
      ),
      title: const Text(
        '详细健康报告',
        style: TextStyle(
          color: Colors.black,
          fontSize: 18,
          fontWeight: FontWeight.w500,
        ),
      ),
    );
  }

  Widget _buildScoreHeader() {
    String formatDateRange() {
      if (widget.startDate == null || widget.endDate == null) {
        return DateFormat('yyyy-MM-dd').format(DateTime.now());
      }
      return "${DateFormat('yyyy-MM-dd').format(widget.startDate!)} - ${DateFormat('yyyy-MM-dd').format(widget.endDate!)}";
    }

    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: 16.0,
        vertical: 8.0,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Text(
                '详情健康报告',
                style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
              ),
              const Spacer(),
              Text(
                formatDateRange(),
                style: TextStyle(color: Colors.grey[600], fontSize: 14),
              ),
            ],
          ),
          // const SizedBox(height: 20),
          // Row(
          //   mainAxisAlignment: MainAxisAlignment.spaceAround,
          //   children: [
          //     _buildScoreItem('健康评分', '85', Colors.red),
          //     _buildScoreItem('达标项目', '8/10', Colors.green),
          //     _buildScoreItem('警告', '2项', Colors.orange),
          //   ],
          // ),
        ],
      ),
    );
  }

  Widget _buildTrendChart(String title, Color color, List<ChartData> data) {
    if (_isLoading) {
      return Container(
        margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        height: 250,
        child: const Center(child: CircularProgressIndicator()),
      );
    }

    final spots =
        data.map((item) => FlSpot(item.index.toDouble(), item.value)).toList();

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: .05),
            blurRadius: 5,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 20),
          SizedBox(
            height: 200,
            child: data.isEmpty
                ? Center(
                    child: Text(
                      '暂无数据',
                      style: TextStyle(color: Colors.grey[600]),
                    ),
                  )
                : LineChart(
                    LineChartData(
                      gridData: const FlGridData(
                        show: false,
                      ),
                      titlesData: FlTitlesData(
                        leftTitles: AxisTitles(
                          sideTitles: SideTitles(
                            showTitles: true,
                            reservedSize: 40,
                            interval: title == '睡眠趋势' ? 2 : null,
                          ),
                        ),
                        bottomTitles: AxisTitles(
                          sideTitles: SideTitles(
                            showTitles: true,
                            reservedSize: 30,
                            getTitlesWidget: (value, meta) {
                              if (value.toInt() >= 0 &&
                                  value.toInt() < data.length) {
                                return Transform.rotate(
                                  angle: -0, // 0度的弧度值
                                  child: Padding(
                                    padding: const EdgeInsets.only(
                                        top: 8.0, right: 20.0),
                                    child: Text(
                                      data[value.toInt()].title,
                                      style: TextStyle(
                                        color: Colors.grey[600],
                                        fontSize: 12,
                                      ),
                                    ),
                                  ),
                                );
                              }
                              return const SizedBox();
                            },
                          ),
                        ),
                        rightTitles: const AxisTitles(
                          sideTitles: SideTitles(showTitles: false),
                        ),
                        topTitles: const AxisTitles(
                          sideTitles: SideTitles(showTitles: false),
                        ),
                      ),
                      borderData: FlBorderData(
                        show: true,
                        border: Border.all(color: Colors.grey[300]!, width: 1),
                      ),
                      lineBarsData: [
                        LineChartBarData(
                          spots: spots,
                          isCurved: false,
                          color: color,
                          barWidth: 2,
                          dotData: FlDotData(
                            show: true,
                            getDotPainter: (spot, percent, barData, index) {
                              return FlDotCirclePainter(
                                radius: 4,
                                color: color,
                                strokeWidth: 2,
                                strokeColor: Colors.white,
                              );
                            },
                          ),
                          belowBarData: BarAreaData(
                            show: true,
                            color: color.withValues(alpha: .1),
                          ),
                          showingIndicators:
                              spots.map((e) => e.x.toInt()).toList(),
                        ),
                      ],
                      lineTouchData: LineTouchData(
                        enabled: true,
                        touchTooltipData: LineTouchTooltipData(
                          tooltipBgColor: Colors.blueAccent,
                          getTooltipItems: (List<LineBarSpot> touchedSpots) {
                            return touchedSpots.map((LineBarSpot touchedSpot) {
                              return LineTooltipItem(
                                touchedSpot.y.toStringAsFixed(1),
                                const TextStyle(color: Colors.white),
                              );
                            }).toList();
                          },
                        ),
                      ),
                    ),
                  ),
          ),
        ],
      ),
    );
  }

  Widget _buildBloodPressureChart() {
    if (_isLoading) {
      return Container(
        margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        height: 250,
        child: const Center(child: CircularProgressIndicator()),
      );
    }

    final systolicSpots = _systolicTrend
        .map((item) => FlSpot(item.index.toDouble(), item.value))
        .toList();
    final diastolicSpots = _diastolicTrend
        .map((item) => FlSpot(item.index.toDouble(), item.value))
        .toList();

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: .05),
            blurRadius: 5,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            '血压趋势',
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.w500),
          ),
          const SizedBox(height: 20),
          SizedBox(
            height: 200,
            child: _systolicTrend.isEmpty && _diastolicTrend.isEmpty
                ? Center(
                    child: Text(
                      '暂无数据',
                      style: TextStyle(color: Colors.grey[600]),
                    ),
                  )
                : LineChart(
                    LineChartData(
                      gridData: const FlGridData(
                        show: false,
                      ),
                      titlesData: FlTitlesData(
                        leftTitles: const AxisTitles(
                          sideTitles: SideTitles(
                            showTitles: true,
                            reservedSize: 40,
                            interval: 20,
                          ),
                        ),
                        bottomTitles: AxisTitles(
                          sideTitles: SideTitles(
                            showTitles: true,
                            reservedSize: 30,
                            getTitlesWidget: (value, meta) {
                              if (value.toInt() >= 0 &&
                                  value.toInt() < _systolicTrend.length) {
                                return Transform.rotate(
                                  angle: -0, // 0度的弧度值
                                  child: Padding(
                                    padding: const EdgeInsets.only(
                                        top: 8.0, right: 20.0),
                                    child: Text(
                                      _systolicTrend[value.toInt()].title,
                                      style: TextStyle(
                                        color: Colors.grey[600],
                                        fontSize: 12,
                                      ),
                                    ),
                                  ),
                                );
                              }
                              return const SizedBox();
                            },
                          ),
                        ),
                        rightTitles: const AxisTitles(
                          sideTitles: SideTitles(showTitles: false),
                        ),
                        topTitles: const AxisTitles(
                          sideTitles: SideTitles(showTitles: false),
                        ),
                      ),
                      borderData: FlBorderData(
                        show: true,
                        border: Border.all(color: Colors.grey[300]!, width: 1),
                      ),
                      lineBarsData: [
                        LineChartBarData(
                          spots: systolicSpots,
                          isCurved: false,
                          color: Colors.green,
                          barWidth: 2,
                          dotData: FlDotData(
                            show: true,
                            getDotPainter: (spot, percent, barData, index) {
                              return FlDotCirclePainter(
                                radius: 4,
                                color: Colors.green,
                                strokeWidth: 2,
                                strokeColor: Colors.white,
                              );
                            },
                          ),
                          belowBarData: BarAreaData(
                            show: true,
                            color: Colors.green.withValues(alpha: .1),
                          ),
                          showingIndicators:
                              systolicSpots.map((e) => e.x.toInt()).toList(),
                        ),
                        LineChartBarData(
                          spots: diastolicSpots,
                          isCurved: false,
                          color: Colors.blue,
                          barWidth: 2,
                          dotData: FlDotData(
                            show: true,
                            getDotPainter: (spot, percent, barData, index) {
                              return FlDotCirclePainter(
                                radius: 4,
                                color: Colors.blue,
                                strokeWidth: 2,
                                strokeColor: Colors.white,
                              );
                            },
                          ),
                          belowBarData: BarAreaData(
                            show: true,
                            color: Colors.blue.withValues(alpha: .1),
                          ),
                          showingIndicators:
                              diastolicSpots.map((e) => e.x.toInt()).toList(),
                        ),
                      ],
                      lineTouchData: LineTouchData(
                        enabled: true,
                        touchTooltipData: LineTouchTooltipData(
                          tooltipBgColor: Colors.blueAccent,
                          getTooltipItems: (List<LineBarSpot> touchedSpots) {
                            return touchedSpots.map((LineBarSpot touchedSpot) {
                              final String label =
                                  touchedSpot.barIndex == 0 ? '收缩压: ' : '舒张压: ';
                              return LineTooltipItem(
                                '$label${touchedSpot.y.toStringAsFixed(1)}',
                                const TextStyle(color: Colors.white),
                              );
                            }).toList();
                          },
                        ),
                      ),
                    ),
                  ),
          ),
          const SizedBox(height: 12),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              _buildLegendItem('收缩压', Colors.green),
              const SizedBox(width: 24),
              _buildLegendItem('舒张压', Colors.blue),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildLegendItem(String label, Color color) {
    return Row(
      children: [
        Container(
          width: 12,
          height: 12,
          decoration: BoxDecoration(color: color, shape: BoxShape.circle),
        ),
        const SizedBox(width: 4),
        Text(label, style: TextStyle(fontSize: 12, color: Colors.grey[600])),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: _buildAppBar(),
      body: RefreshIndicator(
        onRefresh: _loadData,
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          child: Column(
            children: [
              _buildScoreHeader(),
              _buildTrendChart('心率趋势', Colors.red, _heartRateTrend),
              _buildTrendChart('睡眠趋势', Colors.purple, _sleepTrend),
              _buildTrendChart('体重趋势', Colors.blue, _weightTrend),
              _buildBloodPressureChart(),
              const SizedBox(height: 20),
            ],
          ),
        ),
      ),
    );
  }
}
