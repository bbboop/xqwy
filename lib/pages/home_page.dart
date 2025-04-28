import 'package:flutter/material.dart';
import 'package:healther/services/api_service.dart';
import 'package:healther/services/health_service.dart';

class HomePage extends StatefulWidget {
  const HomePage({Key? key}) : super(key: key);

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  bool _isLoading = true;
  Map<String, dynamic> _userInfo = {};
  Map<String, dynamic> _healthData = {};
  List<Map<String, dynamic>> _weightStats = [];

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
      // 获取用户信息和健康数据
      final userProfileResult = await ApiService().getUserProfile();

      // 创建 HealthService 实例
      final healthService = HealthService();

      // 请求健康数据权限
      bool hasPermission = await healthService.requestHealthPermission();

      if (hasPermission) {
        // 获取原始健康数据
        final healthDataRaw = await healthService.fetchHealthData();
        // 处理健康数据
        final processedHealthData =
            await healthService.processHealthData(healthDataRaw);
        // 获取体重趋势数据
        final weightTrendResult = await healthService.getLast7DaysWeight();

        if (mounted) {
          setState(() {
            if (userProfileResult['code'] == 200 &&
                userProfileResult['data'] != null) {
              _userInfo = userProfileResult['data'];
            }

            _healthData = processedHealthData;
            _weightStats = weightTrendResult;
            _isLoading = false;
          });
        }
      } else {
        if (mounted) {
          setState(() {
            _isLoading = false;
          });
        }
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  Future<void> _onRefresh() async {
    await _loadData();
  }

  // 获取头像图像的方法
  ImageProvider _getAvatarImage(String? avatar) {
    if (avatar == null || avatar.isEmpty) {
      return const AssetImage('assets/images/avatar.png');
    }

    // 检查是否已经是完整的 URL
    if (avatar.startsWith('http://') || avatar.startsWith('https://')) {
      return NetworkImage(avatar);
    } else {
      // 将相对路径转为完整 URL
      String baseUrl = ApiService().getBaseUrl();
      // 确保不会重复斜杠
      if (baseUrl.endsWith('/') && avatar.startsWith('/')) {
        return NetworkImage('$baseUrl${avatar.substring(1)}');
      } else if (!baseUrl.endsWith('/') && !avatar.startsWith('/')) {
        return NetworkImage('$baseUrl/$avatar');
      } else {
        return NetworkImage('$baseUrl$avatar');
      }
    }
  }

  Widget _buildOverviewCard() {
    // 获取当前日期
    final now = DateTime.now();
    final dateStr = "${now.year}年${now.month}月${now.day}日";

    return Card(
      elevation: 0,
      color: Colors.blue,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  "今日概览",
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 16,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                Text(
                  dateStr,
                  style: TextStyle(
                    color: Colors.white.withValues(alpha: .8),
                    fontSize: 14,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                Expanded(
                  child: _buildDataItem(
                      "体重", _healthData['latest_weight'] ?? "-", "kg"),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: _buildDataItem(
                      "BMI", _healthData['latest_bmi'] ?? "-", ""),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: _buildDataItem(
                      "体脂率", _healthData['latest_body_fat'] ?? "-", "%"),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDataItem(String label, String value, String unit) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        children: [
          Text(
            label,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 14,
            ),
          ),
          const SizedBox(height: 4),
          Row(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.baseline,
            textBaseline: TextBaseline.alphabetic,
            children: [
              Text(
                value,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                ),
              ),
              if (unit.isNotEmpty) ...[
                const SizedBox(width: 2),
                Text(
                  unit,
                  style: TextStyle(
                    color: Colors.white.withValues(alpha: 0.8),
                    fontSize: 12,
                  ),
                ),
              ],
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildHealthIndicator(
    String title,
    String value,
    String unit,
    Color color,
    IconData icon,
  ) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withValues(alpha: 0.1),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.1),
              shape: BoxShape.circle,
            ),
            child: Icon(icon, color: color),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: TextStyle(color: Colors.grey[800], fontSize: 16),
                ),
                const SizedBox(height: 4),
                FittedBox(
                  fit: BoxFit.scaleDown,
                  child: Row(
                    children: [
                      Text(
                        value,
                        style: const TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(width: 4),
                      Text(
                        unit,
                        style: TextStyle(color: Colors.grey[600], fontSize: 12),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildWeightTrend() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withValues(alpha: .1),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            "体重趋势",
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w500,
              color: Colors.blue,
            ),
          ),
          const SizedBox(height: 16),
          SizedBox(
            height: 200,
            child: Column(
              children: [
                Expanded(
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceAround,
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: _buildTrendBars(),
                  ),
                ),
                const SizedBox(height: 24),
              ],
            ),
          ),
        ],
      ),
    );
  }

  List<Widget> _buildTrendBars() {
    if (_weightStats.isEmpty) {
      return List.generate(
        7,
        (index) => _buildBar("", 0.0, false, "-"),
      );
    }

    double maxValue = 0;
    for (var stat in _weightStats) {
      double value = double.tryParse(stat['value']?.toString() ?? '0') ?? 0;
      if (value > maxValue) {
        maxValue = value;
      }
    }

    return _weightStats.map((stat) {
      double value = double.tryParse(stat['value']?.toString() ?? '0') ?? 0;
      double height = maxValue > 0 ? value / maxValue : 0;
      return _buildBar(
        stat['title'] ?? '',
        height,
        false,
        value > 0 ? value.toStringAsFixed(1) : "-",
      );
    }).toList();
  }

  Widget _buildBar(
      String label, double height, bool isHighlighted, String value) {
    return Expanded(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Column(
            children: [
              Text(
                value,
                style: TextStyle(
                  fontSize: 10,
                  color: Colors.grey[600],
                ),
              ),
              const SizedBox(height: 4),
              Container(
                width: double.infinity,
                height: 120 * height,
                margin: const EdgeInsets.symmetric(horizontal: 4),
                decoration: BoxDecoration(
                  color: isHighlighted
                      ? Colors.blue
                      : Colors.blue.withValues(alpha: 0.2),
                  borderRadius: BorderRadius.circular(4),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          RotationTransition(
            turns: const AlwaysStoppedAnimation(0 / 360),
            child: Text(
              label,
              style: TextStyle(
                fontSize: 12,
                color: Colors.grey[600],
                height: 1.2,
              ),
              textAlign: TextAlign.center,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHealthIndicators() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              "健康指标",
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(
              child: _buildHealthIndicator(
                "心率",
                _healthData['latest_heart_rate'] ?? "-",
                "bpm",
                Colors.red,
                Icons.favorite,
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: _buildHealthIndicator(
                "血压",
                "${_healthData['latest_systolic'] ?? "-"}/${_healthData['latest_diastolic'] ?? "-"}",
                "mmHg",
                Colors.blue,
                Icons.water_drop,
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),
        Row(
          children: [
            Expanded(
              child: _buildHealthIndicator(
                "睡眠",
                _healthData['average_sleep_hours'] ?? "-",
                "小时",
                Colors.orange,
                Icons.nightlight_round,
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: _buildHealthIndicator(
                "步数",
                _healthData['average_daily_steps'] ?? "-",
                "步",
                Colors.green,
                Icons.directions_walk,
              ),
            ),
          ],
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: RefreshIndicator(
          onRefresh: _onRefresh,
          child: SingleChildScrollView(
            physics: const AlwaysScrollableScrollPhysics(),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Padding(
                  padding: const EdgeInsets.all(20),
                  child: Row(
                    children: [
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            _isLoading
                                ? "加载中..."
                                : "你好，${_userInfo['name'] ?? '加载中...'}",
                            style: const TextStyle(
                              fontSize: 24,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            "今天是个记录健康的好日子",
                            style: TextStyle(
                              color: Colors.grey[600],
                              fontSize: 14,
                            ),
                          ),
                        ],
                      ),
                      const Spacer(),
                      _isLoading || _userInfo['avatar'] == null
                          ? CircleAvatar(
                              radius: 24,
                              backgroundColor: Colors.grey[200],
                              child:
                                  Icon(Icons.person, color: Colors.grey[400]),
                            )
                          : CircleAvatar(
                              radius: 24,
                              backgroundImage:
                                  _getAvatarImage(_userInfo['avatar']),
                            ),
                    ],
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  child: _buildOverviewCard(),
                ),
                const SizedBox(height: 20),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  child: _buildHealthIndicators(),
                ),
                const SizedBox(height: 20),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  child: _buildWeightTrend(),
                ),
                const SizedBox(height: 20),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
