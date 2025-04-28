import 'package:flutter/material.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:healther/pages/detailed_report_page.dart';
import 'package:healther/services/api_service.dart';
import 'package:flutter_spinkit/flutter_spinkit.dart';
import 'package:healther/services/health_service.dart';

class ReportPage extends StatefulWidget {
  const ReportPage({Key? key}) : super(key: key);

  @override
  State<ReportPage> createState() => _ReportPageState();
}

class _ReportPageState extends State<ReportPage> {
  final ApiService _apiService = ApiService();
  bool _isLoading = true;
  Map<String, dynamic>? _weeklyReport;
  late DateTime _selectedStartDate;
  late DateTime _selectedEndDate;

  @override
  void initState() {
    super.initState();
    _initializeDates();
    _loadData();
  }

  void _initializeDates() {
    // 获取当前日期
    final now = DateTime.now();
    // 计算上周一（当前日期减去一周再找到那个周一）
    _selectedStartDate = DateTime(
      now
          .subtract(const Duration(days: 7))
          .subtract(Duration(days: now.weekday - 1))
          .year,
      now
          .subtract(const Duration(days: 7))
          .subtract(Duration(days: now.weekday - 1))
          .month,
      now
          .subtract(const Duration(days: 7))
          .subtract(Duration(days: now.weekday - 1))
          .day,
    );
    // 计算上周日，设置时间为23:59:59
    _selectedEndDate = _selectedStartDate
        .add(const Duration(days: 6, hours: 23, minutes: 59, seconds: 59));
  }

  DateTime _getWeekStart(DateTime date) {
    return DateTime(
      date.subtract(Duration(days: date.weekday - 1)).year,
      date.subtract(Duration(days: date.weekday - 1)).month,
      date.subtract(Duration(days: date.weekday - 1)).day,
    );
  }

  DateTime _getWeekEnd(DateTime date) {
    final weekStart = _getWeekStart(date);
    return weekStart
        .add(const Duration(days: 6, hours: 23, minutes: 59, seconds: 59));
  }

  Future<void> _loadData() async {
    setState(() {
      _isLoading = true;
    });

    try {
      // 获取健康数据
      final healthService = HealthService();
      final healthData = await healthService.getEnergyAndSleepData(
        _selectedStartDate,
        _selectedEndDate,
      );

      // 调用周报接口
      final reportResponse = await _apiService.getWeeklyHealthReport(
        startDate: _selectedStartDate,
        endDate: _selectedEndDate,
        totalEnergySum: healthData['total_energy_sum'],
        totalSleepHoursSum: healthData['total_sleep_hours_sum'],
      );

      if (reportResponse['code'] != 200 && reportResponse['code'] != 501) {
        Fluttertoast.showToast(msg: reportResponse['message'] ?? "查询失败");
        if (mounted) {
          setState(() {
            _weeklyReport = null;
            _isLoading = false;
          });
        }
        return;
      }

      if (mounted) {
        setState(() {
          _weeklyReport = reportResponse['data'];
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('加载数据失败，请稍后重试'),
            duration: Duration(seconds: 2),
          ),
        );
      }
    }
  }

  Future<void> _selectDateRange() async {
    // 计算本周一
    final now = DateTime.now();
    final thisWeekMonday = _getWeekStart(now);
    // 最后可选日期为上周日
    final lastSelectableDate = thisWeekMonday.subtract(const Duration(days: 1));

    // 如果当前选择的日期超过了最后可选日期，则使用最后可选日期的上一周
    DateTime initialPickDate = _selectedStartDate;
    if (initialPickDate.isAfter(lastSelectableDate)) {
      initialPickDate = _getWeekStart(lastSelectableDate);
    }

    final picked = await showDatePicker(
      context: context,
      firstDate: DateTime(2020),
      lastDate: lastSelectableDate,
      initialDate: initialPickDate,
      currentDate: DateTime.now(),
      helpText: "选择周",
      cancelText: "取消",
      confirmText: "确定",
      locale: const Locale('zh'),
      selectableDayPredicate: (DateTime date) {
        // 只允许选择周一
        return date.weekday == 1;
      },
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: Theme.of(context).colorScheme.copyWith(
                  primary: Colors.blue,
                ),
          ),
          child: child!,
        );
      },
    );

    if (picked != null) {
      setState(() {
        // 设置所选周的周一和周日
        _selectedStartDate = _getWeekStart(picked);
        _selectedEndDate = _getWeekEnd(picked);
      });
      await _loadData(); // 重新加载数据
    }
  }

  Widget _buildHeader() {
    String formatDate(DateTime date) {
      return "${date.month}月${date.day}日";
    }

    return Container(
      padding: const EdgeInsets.all(16),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  "健康报告",
                  style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 4),
                Text(
                  "每周健康数据分析",
                  style: TextStyle(fontSize: 14, color: Colors.grey[600]),
                ),
              ],
            ),
          ),
          GestureDetector(
            onTap: _selectDateRange,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              decoration: BoxDecoration(
                color: Colors.blue.withValues(alpha: .1),
                borderRadius: BorderRadius.circular(20),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(Icons.calendar_today,
                      size: 16, color: Colors.blue),
                  const SizedBox(width: 4),
                  Text(
                    "${formatDate(_selectedStartDate)} - ${formatDate(_selectedEndDate)}",
                    style: const TextStyle(
                      fontSize: 12,
                      color: Colors.blue,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHealthScore() {
    final overallScore = _weeklyReport?['overall_score'] ?? 0;

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.blue,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Row(
            children: [
              Text(
                "本周健康评分",
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 16,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
          const SizedBox(height: 4),
          Text(
            "基于各项指标的综合评估",
            style: TextStyle(
              color: Colors.white.withValues(alpha: 0.9),
              fontSize: 12,
            ),
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Text(
                "$overallScore",
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 48,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const Text(
                "分",
                style: TextStyle(color: Colors.white, fontSize: 16),
              ),
              const Spacer(),
              Container(
                width: 150,
                height: 6,
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.2),
                  borderRadius: BorderRadius.circular(3),
                ),
                child: FractionallySizedBox(
                  alignment: Alignment.centerLeft,
                  widthFactor: overallScore / 100,
                  child: Container(
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(3),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildAnalysisItem({
    required String title,
    required IconData icon,
    required Color color,
    required String value,
    required double progress,
    required List<String> suggestions,
  }) {
    // 根据标题确定单位
    String getUnit() {
      switch (title) {
        case "饮食分析":
          return "卡";
        case "运动分析":
          return "千卡";
        case "睡眠分析":
          return "小时";
        case "药物分析":
          return ""; // 药物分析不显示单位
        default:
          return "%";
      }
    }

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(icon, color: color, size: 20),
              ),
              const SizedBox(width: 12),
              Text(
                title,
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: Container(
                  padding:
                      const EdgeInsets.symmetric(vertical: 8, horizontal: 12),
                  decoration: BoxDecoration(
                    color: color.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        "评分",
                        style: TextStyle(fontSize: 12, color: Colors.grey),
                      ),
                      const SizedBox(height: 4),
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: [
                          Text(
                            value,
                            style: TextStyle(
                              fontSize: 28,
                              fontWeight: FontWeight.bold,
                              color: color,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Container(
                  padding:
                      const EdgeInsets.symmetric(vertical: 8, horizontal: 12),
                  decoration: BoxDecoration(
                    color: color.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        "平均每天",
                        style: TextStyle(fontSize: 12, color: Colors.grey),
                      ),
                      const SizedBox(height: 4),
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: [
                          Text(
                            "${progress * 100}",
                            style: TextStyle(
                              fontSize: 28,
                              fontWeight: FontWeight.bold,
                              color: color,
                            ),
                          ),
                          if (title != "药物分析") ...[
                            const SizedBox(width: 2),
                            Padding(
                              padding: const EdgeInsets.only(bottom: 4),
                              child: Text(
                                getUnit(),
                                style: TextStyle(
                                  fontSize: 14,
                                  color: color.withValues(alpha: 0.8),
                                ),
                              ),
                            ),
                          ],
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          const Text(
            "本周建议：",
            style: TextStyle(fontSize: 14, fontWeight: FontWeight.w500),
          ),
          const SizedBox(height: 8),
          ...suggestions.map(
            (suggestion) => Padding(
              padding: const EdgeInsets.only(bottom: 4),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    margin: const EdgeInsets.only(top: 6),
                    width: 4,
                    height: 4,
                    decoration: BoxDecoration(
                      color: Colors.grey[400],
                      shape: BoxShape.circle,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      suggestion,
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.grey[600],
                        height: 1.5,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildGenerateReportButton(BuildContext context) {
    return Container(
      margin: const EdgeInsets.all(16),
      child: ElevatedButton(
        onPressed: () {
          // 处理生成详细报告
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => DetailedReportPage(
                startDate: _selectedStartDate,
                endDate: _selectedEndDate,
              ),
            ),
          );
        },
        style: ElevatedButton.styleFrom(
          backgroundColor: Colors.deepPurple,
          minimumSize: const Size(double.infinity, 50),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(25),
          ),
        ),
        child: const Text(
          "生成详细健康报告",
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w600,
            color: Colors.white,
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Scaffold(
        body: Center(
          child: SpinKitWave(
            color: Colors.blue,
            size: 50.0,
          ),
        ),
      );
    }

    if (_weeklyReport == null) {
      return Scaffold(
        backgroundColor: Colors.white,
        body: SafeArea(
          child: RefreshIndicator(
            onRefresh: _loadData,
            child: SingleChildScrollView(
              physics: const AlwaysScrollableScrollPhysics(),
              child: SizedBox(
                height: MediaQuery.of(context).size.height * 0.8 -
                    MediaQuery.of(context).padding.top,
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.start,
                  children: [
                    _buildHeader(),
                    Expanded(
                      child: Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Container(
                              padding: const EdgeInsets.all(20),
                              decoration: BoxDecoration(
                                color: Colors.blue.withValues(alpha: 0.1),
                                shape: BoxShape.circle,
                              ),
                              child: const Icon(
                                Icons.assessment_outlined,
                                size: 64,
                                color: Colors.blue,
                              ),
                            ),
                            const SizedBox(height: 24),
                            const Text(
                              "暂无健康报告数据",
                              style: TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.w600,
                                color: Colors.black87,
                              ),
                            ),
                            const SizedBox(height: 8),
                            Text(
                              "请尝试选择其他日期范围",
                              style: TextStyle(
                                fontSize: 14,
                                color: Colors.grey[600],
                              ),
                            ),
                            const SizedBox(height: 32),
                            TextButton.icon(
                              onPressed: _loadData,
                              icon: const Icon(Icons.refresh),
                              label: const Text("重新加载"),
                              style: TextButton.styleFrom(
                                foregroundColor: Colors.blue,
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 24, vertical: 12),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(20),
                                  side: const BorderSide(color: Colors.blue),
                                ),
                              ),
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
        ),
      );
    }

    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: RefreshIndicator(
          onRefresh: _loadData,
          child: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildHeader(),
                _buildHealthScore(),
                const SizedBox(height: 20),
                _buildAnalysisItem(
                  title: "饮食分析",
                  icon: Icons.restaurant,
                  color: Colors.green,
                  value: (_weeklyReport?['diet']?['judgment'] ?? 0).toString(),
                  progress: double.parse(
                          (_weeklyReport?['diet']?['completion_rate'] ?? 0)
                              .toString()) /
                      100,
                  suggestions: List<String>.from(
                      _weeklyReport?['diet']?['suggestions'] ?? []),
                ),
                _buildAnalysisItem(
                  title: "运动分析",
                  icon: Icons.directions_run,
                  color: Colors.blue,
                  value: (_weeklyReport?['sport']?['judgment'] ?? 0).toString(),
                  progress: double.parse(
                          (_weeklyReport?['sport']?['completion_rate'] ?? 0)
                              .toString()) /
                      100,
                  suggestions: List<String>.from(
                      _weeklyReport?['sport']?['suggestions'] ?? []),
                ),
                _buildAnalysisItem(
                  title: "睡眠分析",
                  icon: Icons.nightlight_round,
                  color: Colors.orange,
                  value: (_weeklyReport?['sleep']?['judgment'] ?? 0).toString(),
                  progress: double.parse(
                          (_weeklyReport?['sleep']?['completion_rate'] ?? 0)
                              .toString()) /
                      100,
                  suggestions: List<String>.from(
                      _weeklyReport?['sleep']?['suggestions'] ?? []),
                ),
                _buildAnalysisItem(
                  title: "药物分析",
                  icon: Icons.medical_services,
                  color: Colors.purple,
                  value:
                      (_weeklyReport?['medicine']?['judgment'] ?? 0).toString(),
                  progress: double.parse(
                          (_weeklyReport?['medicine']?['completion_rate'] ?? 0)
                              .toString()) /
                      100,
                  suggestions: List<String>.from(
                      _weeklyReport?['medicine']?['suggestions'] ?? []),
                ),
                _buildGenerateReportButton(context),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
