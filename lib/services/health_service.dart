import 'package:health/health.dart';
import 'package:healther/services/api_service.dart';
import 'package:logger/logger.dart';

class HealthService {
  final logger = Logger();
  // 单例模式
  static final HealthService _instance = HealthService._internal();
  factory HealthService() => _instance;
  HealthService._internal();

  final Health _health = Health();
  final ApiService _apiService = ApiService();

  // 需要获取的健康数据类型列表
  final List<HealthDataType> dataTypes = [
    HealthDataType.WEIGHT,
    HealthDataType.HEIGHT,
    HealthDataType.BODY_MASS_INDEX,
    HealthDataType.BODY_FAT_PERCENTAGE,
    HealthDataType.STEPS,
    HealthDataType.HEART_RATE,
    HealthDataType.BLOOD_PRESSURE_SYSTOLIC,
    HealthDataType.BLOOD_PRESSURE_DIASTOLIC,
    HealthDataType.BLOOD_GLUCOSE,
    HealthDataType.SLEEP_ASLEEP,
    HealthDataType.SLEEP_IN_BED,
    HealthDataType.ACTIVE_ENERGY_BURNED,
    HealthDataType.EXERCISE_TIME
  ];

  // 获取访问健康数据的权限
  Future<bool> requestHealthPermission() async {
    try {
      // 需要读取和写入的所有数据类型
      final readOnlyTypes = [
        HealthDataType.WEIGHT,
        HealthDataType.HEIGHT,
        HealthDataType.BODY_MASS_INDEX,
        HealthDataType.BODY_FAT_PERCENTAGE,
        HealthDataType.STEPS,
        HealthDataType.HEART_RATE,
        HealthDataType.BLOOD_PRESSURE_SYSTOLIC,
        HealthDataType.BLOOD_PRESSURE_DIASTOLIC,
        HealthDataType.BLOOD_GLUCOSE,
        HealthDataType.SLEEP_ASLEEP,
        HealthDataType.SLEEP_IN_BED,
        HealthDataType.ACTIVE_ENERGY_BURNED,
        HealthDataType.EXERCISE_TIME
      ];
      // 需要读取和写入的所有数据类型
      final writeTypes = [
        HealthDataType.WEIGHT,
        HealthDataType.HEIGHT,
        HealthDataType.HEART_RATE,
        HealthDataType.BLOOD_PRESSURE_SYSTOLIC,
        HealthDataType.BLOOD_PRESSURE_DIASTOLIC,
        HealthDataType.BLOOD_GLUCOSE,
        HealthDataType.SLEEP_ASLEEP,
        HealthDataType.SLEEP_IN_BED,
        HealthDataType.STEPS
      ];
      final allTypes = [...writeTypes, ...readOnlyTypes];

      // 配置健康插件
      await _health.configure();

      // 直接请求所有权限
      // 使用 READ_WRITE 对于 writeTypes，READ 对于 readOnlyTypes
      final permissions = [
        ...List.generate(writeTypes.length, (_) => HealthDataAccess.READ_WRITE),
        ...List.generate(readOnlyTypes.length, (_) => HealthDataAccess.READ),
      ];
      bool? authorized = await _health.requestAuthorization(allTypes,
          permissions: permissions);

      // 请求历史数据访问权限
      if (authorized == true) {
        await _health.requestHealthDataHistoryAuthorization();
      }

      return authorized == true;
    } catch (e) {
      logger.d("获取健康数据权限失败: $e");
      return false;
    }
  }

  // 从健康应用获取数据
  Future<Map<HealthDataType, List<HealthDataPoint>>> fetchHealthData() async {
    final now = DateTime.now();
    final thirtyDaysAgo = now.subtract(const Duration(days: 90));
    Map<HealthDataType, List<HealthDataPoint>> healthData = {};

    for (HealthDataType type in dataTypes) {
      try {
        List<HealthDataPoint> data = await _health.getHealthDataFromTypes(
          startTime: thirtyDaysAgo,
          endTime: now,
          types: [type],
        );

        if (data.isNotEmpty) {
          healthData[type] = data;
        }
      } catch (e) {
        logger.d("获取${type.toString()}数据错误: $e");
      }
    }

    return healthData;
  }

  // 处理健康数据
  Future<Map<String, dynamic>> processHealthData(
      Map<HealthDataType, List<HealthDataPoint>> healthData) async {
    Map<String, dynamic> processedData = {};
    final now = DateTime.now();
    final sevenDaysAgo = now.subtract(const Duration(days: 7));
    final startOfDay =
        DateTime(sevenDaysAgo.year, sevenDaysAgo.month, sevenDaysAgo.day)
            .add(const Duration(days: 1));
    final endOfDay =
        DateTime(now.year, now.month, now.day).add(const Duration(days: 1));
    final todayStart = DateTime(now.year, now.month, now.day);
    final todayEnd = todayStart.add(const Duration(days: 1));

    // 处理每种类型的数据
    for (var entry in healthData.entries) {
      await _processSpecificData(entry.key, entry.value, processedData,
          startOfDay, endOfDay, todayStart, todayEnd);
    }

    return processedData;
  }

  // 处理特定类型的健康数据
  Future<void> _processSpecificData(
    HealthDataType type,
    List<HealthDataPoint> data,
    Map<String, dynamic> processedData,
    DateTime startOfDay,
    DateTime endOfDay,
    DateTime todayStart,
    DateTime todayEnd,
  ) async {
    switch (type) {
      case HealthDataType.WEIGHT:
        _processWeight(
            data, processedData, startOfDay, endOfDay, todayStart, todayEnd);
        break;
      case HealthDataType.BODY_MASS_INDEX:
        _processBMI(
            data, processedData, startOfDay, endOfDay, todayStart, todayEnd);
        break;
      case HealthDataType.BODY_FAT_PERCENTAGE:
        _processBodyFat(
            data, processedData, startOfDay, endOfDay, todayStart, todayEnd);
        break;
      case HealthDataType.HEART_RATE:
        _processHeartRate(
            data, processedData, startOfDay, endOfDay, todayStart, todayEnd);
        break;
      case HealthDataType.STEPS:
        await _processSteps(
            data, processedData, startOfDay, endOfDay, todayStart, todayEnd);
        break;
      case HealthDataType.SLEEP_ASLEEP:
      case HealthDataType.SLEEP_IN_BED:
        if (type == HealthDataType.SLEEP_ASLEEP) {
          _processSleep(type, data, processedData, startOfDay, endOfDay,
              todayStart, todayEnd);
        } else if (type == HealthDataType.SLEEP_IN_BED &&
            (processedData['average_sleep_hours'] == null ||
                processedData['average_sleep_hours'] == '0')) {
          _processSleep(type, data, processedData, startOfDay, endOfDay,
              todayStart, todayEnd);
        }
        break;
      case HealthDataType.BLOOD_PRESSURE_SYSTOLIC:
        _processSystolicBP(
            data, processedData, startOfDay, endOfDay, todayStart, todayEnd);
        break;
      case HealthDataType.BLOOD_PRESSURE_DIASTOLIC:
        _processDiastolicBP(
            data, processedData, startOfDay, endOfDay, todayStart, todayEnd);
        break;
      case HealthDataType.BLOOD_GLUCOSE:
        _processBloodGlucose(
            data, processedData, startOfDay, endOfDay, todayStart, todayEnd);
        break;
      case HealthDataType.ACTIVE_ENERGY_BURNED:
        _processActiveEnergy(
            data, processedData, startOfDay, endOfDay, todayStart, todayEnd);
        break;
      case HealthDataType.EXERCISE_TIME:
        _processExerciseTime(
            data, processedData, startOfDay, endOfDay, todayStart, todayEnd);
        break;
      default:
        break;
    }
  }

  void _processWeight(
      List<HealthDataPoint> data,
      Map<String, dynamic> processedData,
      DateTime startOfDay,
      DateTime endOfDay,
      DateTime todayStart,
      DateTime todayEnd) {
    var weekData = _filterDataByDateRange(data, startOfDay, endOfDay)
        .where((item) => _getNumericValue(item) > 0)
        .toList();
    var todayData = _filterDataByDateRange(data, todayStart, todayEnd)
        .where((item) => _getNumericValue(item) > 0)
        .toList();

    if (weekData.isNotEmpty) {
      double totalWeight = _sumNumericValues(weekData);
      processedData['latest_weight'] =
          (totalWeight / weekData.length).toStringAsFixed(1);
    }

    if (todayData.isNotEmpty) {
      var latestValue = _getNumericValue(todayData.last);
      processedData['latest_weight_today'] = latestValue.toStringAsFixed(1);
    }
  }

  void _processBMI(
      List<HealthDataPoint> data,
      Map<String, dynamic> processedData,
      DateTime startOfDay,
      DateTime endOfDay,
      DateTime todayStart,
      DateTime todayEnd) {
    var weekData = _filterDataByDateRange(data, startOfDay, endOfDay)
        .where((item) => _getNumericValue(item) > 0)
        .toList();
    var todayData = _filterDataByDateRange(data, todayStart, todayEnd)
        .where((item) => _getNumericValue(item) > 0)
        .toList();

    if (weekData.isNotEmpty) {
      double totalBMI = _sumNumericValues(weekData);
      processedData['latest_bmi'] =
          (totalBMI / weekData.length).toStringAsFixed(1);
    }

    if (todayData.isNotEmpty) {
      var latestValue = _getNumericValue(todayData.last);
      processedData['latest_bmi_today'] = latestValue.toStringAsFixed(1);
    }
  }

  void _processBodyFat(
      List<HealthDataPoint> data,
      Map<String, dynamic> processedData,
      DateTime startOfDay,
      DateTime endOfDay,
      DateTime todayStart,
      DateTime todayEnd) {
    var weekData = _filterDataByDateRange(data, startOfDay, endOfDay)
        .where((item) => _getNumericValue(item) > 0)
        .toList();
    var todayData = _filterDataByDateRange(data, todayStart, todayEnd)
        .where((item) => _getNumericValue(item) > 0)
        .toList();

    if (weekData.isNotEmpty) {
      double totalBodyFat = _sumNumericValues(weekData);
      processedData['latest_body_fat'] =
          ((totalBodyFat / weekData.length) * 100).toStringAsFixed(1);
    }

    if (todayData.isNotEmpty) {
      var latestValue = _getNumericValue(todayData.last);
      processedData['latest_body_fat_today'] =
          (latestValue * 100).toStringAsFixed(1);
    }
  }

  void _processHeartRate(
      List<HealthDataPoint> data,
      Map<String, dynamic> processedData,
      DateTime startOfDay,
      DateTime endOfDay,
      DateTime todayStart,
      DateTime todayEnd) {
    var weekData = _filterDataByDateRange(data, startOfDay, endOfDay)
        .where((item) => _getNumericValue(item) > 0)
        .toList();
    var todayData = _filterDataByDateRange(data, todayStart, todayEnd)
        .where((item) => _getNumericValue(item) > 0)
        .toList();

    if (weekData.isNotEmpty) {
      double totalHeartRate = _sumNumericValues(weekData);
      processedData['latest_heart_rate'] =
          (totalHeartRate / weekData.length).toStringAsFixed(1);
    }

    if (todayData.isNotEmpty) {
      var latestValue = _getNumericValue(todayData.last);
      processedData['latest_heart_rate_today'] = latestValue.toStringAsFixed(1);
    }
  }

  Future<void> _processSteps(
      List<HealthDataPoint> data,
      Map<String, dynamic> processedData,
      DateTime startOfDay,
      DateTime endOfDay,
      DateTime todayStart,
      DateTime todayEnd) async {
    double totalSteps = 0;
    int daysWithData = 0;

    // 从startOfDay开始计算7天的数据
    for (int i = 0; i < 7; i++) {
      DateTime dayStart = startOfDay.add(Duration(days: i));
      DateTime dayEnd = dayStart.add(const Duration(days: 1));

      int? steps = await _health.getTotalStepsInInterval(dayStart, dayEnd);
      if (steps != null && steps > 0) {
        totalSteps += steps;
        daysWithData++;
      }
    }

    if (daysWithData > 0) {
      processedData['average_daily_steps'] =
          (totalSteps / daysWithData).toStringAsFixed(0);
    } else {
      processedData['average_daily_steps'] = '0';
    }

    int? todaySteps =
        await _health.getTotalStepsInInterval(todayStart, todayEnd);
    if (todaySteps != null && todaySteps > 0) {
      processedData['average_daily_steps_today'] = todaySteps.toString();
    } else {
      processedData['average_daily_steps_today'] = '0';
    }
  }

  void _processSleep(
      HealthDataType type,
      List<HealthDataPoint> data,
      Map<String, dynamic> processedData,
      DateTime startOfDay,
      DateTime endOfDay,
      DateTime todayStart,
      DateTime todayEnd) {
    double totalSleepHours = 0;
    int daysWithData = 0;

    // 从startOfDay开始计算7天的数据
    for (int i = 0; i < 7; i++) {
      DateTime dayStart = startOfDay.add(Duration(days: i));
      // 调整时间范围为前一天20:00到当天20:00
      DateTime adjustedDayStart = dayStart.subtract(const Duration(hours: 4));
      DateTime adjustedDayEnd =
          dayStart.add(const Duration(days: 1, hours: -4));

      // 获取当天的睡眠数据
      var dayData = data.where((item) =>
          item.dateFrom.isAfter(adjustedDayStart) &&
          item.dateFrom.isBefore(adjustedDayEnd));

      double daySleepHours = 0;
      for (var item in dayData) {
        Duration sleepDuration = item.dateTo.difference(item.dateFrom);
        daySleepHours += sleepDuration.inMinutes / 60.0;
      }

      if (daySleepHours > 0) {
        totalSleepHours += daySleepHours;
        daysWithData++;
      }
    }

    if (daysWithData > 0) {
      processedData['average_sleep_hours'] =
          (totalSleepHours / daysWithData).toStringAsFixed(1);
    } else {
      processedData['average_sleep_hours'] = '0';
    }

    // 处理今天的数据
    // 调整今天的时间范围为前一天20:00到今天20:00
    DateTime adjustedTodayStart = todayStart.subtract(const Duration(hours: 4));
    DateTime adjustedTodayEnd = todayEnd.subtract(const Duration(hours: 4));

    var todayData = data.where((item) =>
        item.dateFrom.isAfter(adjustedTodayStart) &&
        item.dateFrom.isBefore(adjustedTodayEnd));

    double todaySleepHours = 0;
    for (var item in todayData) {
      Duration sleepDuration = item.dateTo.difference(item.dateFrom);
      todaySleepHours += sleepDuration.inMinutes / 60.0;
    }

    processedData['average_sleep_hours_today'] =
        todaySleepHours.toStringAsFixed(1);
  }

  void _processSystolicBP(
      List<HealthDataPoint> data,
      Map<String, dynamic> processedData,
      DateTime startOfDay,
      DateTime endOfDay,
      DateTime todayStart,
      DateTime todayEnd) {
    var weekData = _filterDataByDateRange(data, startOfDay, endOfDay)
        .where((item) => _getNumericValue(item) > 0)
        .toList();
    var todayData = _filterDataByDateRange(data, todayStart, todayEnd)
        .where((item) => _getNumericValue(item) > 0)
        .toList();

    if (weekData.isNotEmpty) {
      double totalSystolic = _sumNumericValues(weekData);
      processedData['latest_systolic'] =
          (totalSystolic / weekData.length).toStringAsFixed(1);
    }

    if (todayData.isNotEmpty) {
      var latestValue = _getNumericValue(todayData.last);
      processedData['latest_systolic_today'] = latestValue.toStringAsFixed(1);
    }
  }

  void _processDiastolicBP(
      List<HealthDataPoint> data,
      Map<String, dynamic> processedData,
      DateTime startOfDay,
      DateTime endOfDay,
      DateTime todayStart,
      DateTime todayEnd) {
    var weekData = _filterDataByDateRange(data, startOfDay, endOfDay)
        .where((item) => _getNumericValue(item) > 0)
        .toList();
    var todayData = _filterDataByDateRange(data, todayStart, todayEnd)
        .where((item) => _getNumericValue(item) > 0)
        .toList();

    if (weekData.isNotEmpty) {
      double totalDiastolic = _sumNumericValues(weekData);
      processedData['latest_diastolic'] =
          (totalDiastolic / weekData.length).toStringAsFixed(1);
    }

    if (todayData.isNotEmpty) {
      var latestValue = _getNumericValue(todayData.last);
      processedData['latest_diastolic_today'] = latestValue.toStringAsFixed(1);
    }
  }

  void _processBloodGlucose(
      List<HealthDataPoint> data,
      Map<String, dynamic> processedData,
      DateTime startOfDay,
      DateTime endOfDay,
      DateTime todayStart,
      DateTime todayEnd) {
    var weekData = _filterDataByDateRange(data, startOfDay, endOfDay)
        .where((item) => _getNumericValue(item) > 0)
        .toList();
    var todayData = _filterDataByDateRange(data, todayStart, todayEnd)
        .where((item) => _getNumericValue(item) > 0)
        .toList();

    if (weekData.isNotEmpty) {
      double totalGlucose = _sumNumericValues(weekData);
      processedData['latest_glucose'] =
          (totalGlucose / weekData.length).toStringAsFixed(1);
    }

    if (todayData.isNotEmpty) {
      var latestValue = _getNumericValue(todayData.last);
      processedData['latest_glucose_today'] = latestValue.toStringAsFixed(1);
    }
  }

  void _processActiveEnergy(
      List<HealthDataPoint> data,
      Map<String, dynamic> processedData,
      DateTime startOfDay,
      DateTime endOfDay,
      DateTime todayStart,
      DateTime todayEnd) {
    var weekData = _filterDataByDateRange(
            data, startOfDay.subtract(const Duration(seconds: 1)), endOfDay)
        .where((item) => _getNumericValue(item) > 0)
        .toList();
    var todayData = _filterDataByDateRange(
            data, todayStart.subtract(const Duration(seconds: 1)), todayEnd)
        .where((item) => _getNumericValue(item) > 0)
        .toList();

    if (weekData.isNotEmpty) {
      double totalEnergy = _sumNumericValues(weekData);
      processedData['active_energy'] = (totalEnergy / 7).toStringAsFixed(1);
    }

    if (todayData.isNotEmpty) {
      double todayEnergy = _sumNumericValues(todayData);
      processedData['active_energy_today'] = todayEnergy.toStringAsFixed(1);
    }
  }

  void _processExerciseTime(
      List<HealthDataPoint> data,
      Map<String, dynamic> processedData,
      DateTime startOfDay,
      DateTime endOfDay,
      DateTime todayStart,
      DateTime todayEnd) {
    var weekData = _filterDataByDateRange(data, startOfDay, endOfDay)
        .where((item) => _getNumericValue(item) > 0)
        .toList();
    var todayData = _filterDataByDateRange(data, todayStart, todayEnd)
        .where((item) => _getNumericValue(item) > 0)
        .toList();

    if (weekData.isNotEmpty) {
      double totalMinutes = _sumNumericValues(weekData);
      processedData['exercise_minutes'] = (totalMinutes / 7).toStringAsFixed(0);
    }

    if (todayData.isNotEmpty) {
      double todayMinutes = _sumNumericValues(todayData);
      processedData['exercise_minutes_today'] = todayMinutes.toStringAsFixed(0);
    }
  }

  // 辅助方法
  List<HealthDataPoint> _filterDataByDateRange(
      List<HealthDataPoint> data, DateTime start, DateTime end) {
    return data
        .where((item) =>
            item.dateFrom.isAfter(start) && item.dateFrom.isBefore(end))
        .toList();
  }

  double _sumNumericValues(List<HealthDataPoint> data) {
    return data.fold(0.0, (sum, item) {
      double value = _getNumericValue(item);
      return sum + value;
    });
  }

  double _getNumericValue(HealthDataPoint point) {
    try {
      final value = point.value;
      String stringValue;

      if (value is NumericHealthValue) {
        stringValue = value.numericValue.toString();
      } else {
        stringValue = value.toString();
      }

      return double.parse(stringValue);
    } catch (e) {
      logger.d("数值转换失败: $e");
      return 0.0;
    }
  }

  // 从服务器获取健康数据
  Future<Map<String, dynamic>> fetchHealthDataFromServer() async {
    try {
      final response = await _apiService.getHealthDetail();
      if (response['code'] == 200 && response['data'] != null) {
        final data = response['data'];
        return {
          'average_sleep_hours': data['sleep_hours']?.toString() ?? '-',
          'latest_weight': data['weight_kg']?.toString() ?? '-',
          'latest_heart_rate': data['heart_rate']?.toString() ?? '-',
          'latest_systolic': data['systolic_bp']?.toString() ?? '-',
          'latest_diastolic': data['diastolic_bp']?.toString() ?? '-',
          'latest_glucose': data['blood_glucose_mmol']?.toString() ?? '-',
          'average_daily_steps': data['steps']?.toString() ?? '-',
        };
      }
      return {};
    } catch (e) {
      logger.d('获取健康数据失败: $e');
      return {};
    }
  }

  // 上传健康数据到服务器
  Future<bool> uploadHealthData(Map<String, dynamic> processedData) async {
    try {
      final response = await _apiService.uploadHealthData(
        steps: processedData['average_daily_steps'],
        heartRate: processedData['latest_heart_rate'],
        sleepMinutes: processedData['average_sleep_hours'] != null
            ? (double.parse(processedData['average_sleep_hours']) * 1)
                .toString()
            : null,
        weightKg: processedData['latest_weight'],
        bloodGlucoseMmol: processedData['latest_glucose'],
        systolicBp: processedData['latest_systolic'],
        diastolicBp: processedData['latest_diastolic'],
        bmi: processedData['latest_bmi'],
        bodyFat: processedData['latest_body_fat'],
        activeEnergy: processedData['active_energy'],
        exerciseMinutes: processedData['exercise_minutes'],
        stepsToday: processedData['average_daily_steps_today'],
        heartRateToday: processedData['latest_heart_rate_today'],
        sleepHoursToday: processedData['average_sleep_hours_today'],
        weightKgToday: processedData['latest_weight_today'],
        bloodGlucoseMmolToday: processedData['latest_glucose_today'],
        systolicBpToday: processedData['latest_systolic_today'],
        diastolicBpToday: processedData['latest_diastolic_today'],
        bmiToday: processedData['latest_bmi_today'],
        bodyFatToday: processedData['latest_body_fat_today'],
        activeEnergyToday: processedData['active_energy_today'],
        exerciseMinutesToday: processedData['exercise_minutes_today'],
      );

      return response['code'] == 200;
    } catch (e) {
      logger.d('上传健康数据失败: $e');
      return false;
    }
  }

  // 写入体重数据
  Future<bool> writeWeight(double weight) async {
    try {
      final now = DateTime.now();
      bool success = await _health.writeHealthData(
        value: weight,
        type: HealthDataType.WEIGHT,
        startTime: now,
        endTime: now,
        recordingMethod: RecordingMethod.manual,
      );
      return success;
    } catch (e) {
      logger.d('写入体重数据失败: $e');
      return false;
    }
  }

  // 写入心率数据
  Future<bool> writeHeartRate(int heartRate) async {
    try {
      final now = DateTime.now();
      bool success = await _health.writeHealthData(
        value: heartRate.toDouble(),
        type: HealthDataType.HEART_RATE,
        startTime: now,
        endTime: now,
        recordingMethod: RecordingMethod.manual,
      );
      return success;
    } catch (e) {
      logger.d('写入心率数据失败: $e');
      return false;
    }
  }

  // 写入血压数据
  Future<bool> writeBloodPressure(int systolic, int diastolic) async {
    try {
      final now = DateTime.now();
      bool systolicSuccess = await _health.writeHealthData(
        value: systolic.toDouble(),
        type: HealthDataType.BLOOD_PRESSURE_SYSTOLIC,
        startTime: now,
        endTime: now,
        recordingMethod: RecordingMethod.manual,
      );

      bool diastolicSuccess = await _health.writeHealthData(
        value: diastolic.toDouble(),
        type: HealthDataType.BLOOD_PRESSURE_DIASTOLIC,
        startTime: now,
        endTime: now,
        recordingMethod: RecordingMethod.manual,
      );

      return systolicSuccess && diastolicSuccess;
    } catch (e) {
      logger.d('写入血压数据失败: $e');
      return false;
    }
  }

  // 写入血糖数据
  Future<bool> writeBloodGlucose(double glucose) async {
    try {
      final now = DateTime.now();
      bool success = await _health.writeHealthData(
        value: glucose,
        type: HealthDataType.BLOOD_GLUCOSE,
        startTime: now,
        endTime: now,
        recordingMethod: RecordingMethod.manual,
      );
      return success;
    } catch (e) {
      logger.d('写入血糖数据失败: $e');
      return false;
    }
  }

  // 写入步数数据
  Future<bool> writeSteps(int steps) async {
    try {
      final now = DateTime.now();
      bool success = await _health.writeHealthData(
        value: steps.toDouble(),
        type: HealthDataType.STEPS,
        startTime: now,
        endTime: now,
        recordingMethod: RecordingMethod.manual,
      );
      return success;
    } catch (e) {
      logger.d('写入步数数据失败: $e');
      return false;
    }
  }

  // 写入睡眠数据
  Future<bool> writeSleep(DateTime sleepStart, DateTime sleepEnd) async {
    try {
      bool successAsleep = await _health.writeHealthData(
        value: 0.0, // 睡眠数据不需要具体的数值，只需要时间段
        type: HealthDataType.SLEEP_ASLEEP,
        startTime: sleepStart,
        endTime: sleepEnd,
        recordingMethod: RecordingMethod.manual,
      );

      bool successInBed = await _health.writeHealthData(
        value: 0.0,
        type: HealthDataType.SLEEP_IN_BED,
        startTime: sleepStart,
        endTime: sleepEnd,
        recordingMethod: RecordingMethod.manual,
      );

      return successAsleep && successInBed;
    } catch (e) {
      logger.d('写入睡眠数据失败: $e');
      return false;
    }
  }

  // 获取最近7天的体重数据
  Future<List<Map<String, dynamic>>> getLast7DaysWeight() async {
    final now = DateTime.now();
    final sevenDaysAgo = now.subtract(const Duration(days: 7));
    List<Map<String, dynamic>> weightTrend = [];

    try {
      List<HealthDataPoint> weightData = await _health.getHealthDataFromTypes(
        startTime: sevenDaysAgo,
        endTime: now,
        types: [HealthDataType.WEIGHT],
      );

      // 按日期分组数据
      for (int i = 6; i >= 0; i--) {
        final date = now.subtract(Duration(days: i));
        final dayStart = DateTime(date.year, date.month, date.day);
        final dayEnd = dayStart.add(const Duration(days: 1));

        // 获取当天的体重数据
        var dayData = weightData.where((data) =>
            data.dateFrom.isAfter(dayStart) && data.dateFrom.isBefore(dayEnd));

        // 如果当天有数据，使用最后一条记录
        if (dayData.isNotEmpty) {
          var lastRecord = dayData.last;
          weightTrend.add({
            'date': dayStart,
            'value': _getNumericValue(lastRecord),
            'title': '${dayStart.month}/${dayStart.day}'
          });
        } else {
          // 如果当天没有数据，添加空值
          weightTrend.add({
            'date': dayStart,
            'value': 0,
            'title': '${dayStart.month}/${dayStart.day}'
          });
        }
      }

      return weightTrend;
    } catch (e) {
      logger.d("获取体重趋势数据失败: $e");
      return [];
    }
  }

  // 获取心率趋势数据
  Future<List<Map<String, dynamic>>> getHeartRateTrend(
      DateTime startDate, DateTime endDate) async {
    List<Map<String, dynamic>> heartRateTrend = [];

    try {
      List<HealthDataPoint> heartRateData =
          await _health.getHealthDataFromTypes(
        startTime: startDate,
        endTime: endDate.add(const Duration(days: 1)),
        types: [HealthDataType.HEART_RATE],
      );

      // 计算日期范围内的所有日期
      List<DateTime> dates = [];
      DateTime currentDate =
          DateTime(startDate.year, startDate.month, startDate.day);
      final endDateTime = DateTime(endDate.year, endDate.month, endDate.day);

      while (!currentDate.isAfter(endDateTime)) {
        dates.add(currentDate);
        currentDate = currentDate.add(const Duration(days: 1));
      }

      // 处理每一天的数据
      for (var date in dates) {
        final nextDay = date.add(const Duration(days: 1));
        var dayData = heartRateData.where((data) =>
            data.dateFrom.isAfter(date) && data.dateFrom.isBefore(nextDay));

        if (dayData.isNotEmpty) {
          double totalHeartRate = 0;
          int count = 0;

          for (var item in dayData) {
            try {
              double value = _getNumericValue(item);
              totalHeartRate += value;
              count++;
            } catch (e) {
              logger.d("心率数据转换失败: $e");
              continue;
            }
          }

          heartRateTrend.add({
            'date': date,
            'value': count > 0 ? totalHeartRate / count : 0.0,
            'title': '${date.month}/${date.day}'
          });
        } else {
          heartRateTrend.add({
            'date': date,
            'value': 0.0,
            'title': '${date.month}/${date.day}'
          });
        }
      }

      return heartRateTrend;
    } catch (e) {
      logger.d("获取心率趋势数据失败: $e");
      return [];
    }
  }

  // 获取睡眠趋势数据
  Future<List<Map<String, dynamic>>> getSleepTrend(
      DateTime startDate, DateTime endDate) async {
    List<Map<String, dynamic>> sleepTrend = [];

    try {
      // 调整查询时间范围，向前推4小时
      DateTime adjustedStartDate = startDate.subtract(const Duration(hours: 4));
      DateTime adjustedEndDate = endDate
          .add(const Duration(days: 1))
          .subtract(const Duration(hours: 4));

      // 首先获取SLEEP_ASLEEP数据
      List<HealthDataPoint> sleepData = await _health.getHealthDataFromTypes(
        startTime: adjustedStartDate,
        endTime: adjustedEndDate,
        types: [HealthDataType.SLEEP_ASLEEP],
      );

      // 如果SLEEP_ASLEEP没有数据，则获取SLEEP_IN_BED数据
      if (sleepData.isEmpty) {
        sleepData = await _health.getHealthDataFromTypes(
          startTime: adjustedStartDate,
          endTime: adjustedEndDate,
          types: [HealthDataType.SLEEP_IN_BED],
        );
      }

      // 计算日期范围内的所有日期
      List<DateTime> dates = [];
      DateTime currentDate =
          DateTime(startDate.year, startDate.month, startDate.day);
      final endDateTime = DateTime(endDate.year, endDate.month, endDate.day);

      while (!currentDate.isAfter(endDateTime)) {
        dates.add(currentDate);
        currentDate = currentDate.add(const Duration(days: 1));
      }

      // 处理每一天的数据
      for (var date in dates) {
        // 调整日期范围为前一天20:00到当天20:00
        final dayStart = date.subtract(const Duration(hours: 4));
        final dayEnd = date
            .add(const Duration(days: 1))
            .subtract(const Duration(hours: 4));

        var dayData = sleepData.where((data) =>
            data.dateFrom.isAfter(dayStart) && data.dateFrom.isBefore(dayEnd));

        double totalSleepHours = 0.0;
        for (var item in dayData) {
          try {
            Duration sleepDuration = item.dateTo.difference(item.dateFrom);
            totalSleepHours += sleepDuration.inMinutes / 60.0;
          } catch (e) {
            logger.d("睡眠数据处理失败: $e");
            continue;
          }
        }

        sleepTrend.add({
          'date': date,
          'value': totalSleepHours,
          'title': '${date.month}/${date.day}'
        });
      }

      return sleepTrend;
    } catch (e) {
      logger.d("获取睡眠趋势数据失败: $e");
      return [];
    }
  }

  // 获取体重趋势数据
  Future<List<Map<String, dynamic>>> getWeightTrend(
      DateTime startDate, DateTime endDate) async {
    List<Map<String, dynamic>> weightTrend = [];

    try {
      List<HealthDataPoint> weightData = await _health.getHealthDataFromTypes(
        startTime: startDate,
        endTime: endDate.add(const Duration(days: 1)),
        types: [HealthDataType.WEIGHT],
      );

      // 计算日期范围内的所有日期
      List<DateTime> dates = [];
      DateTime currentDate =
          DateTime(startDate.year, startDate.month, startDate.day);
      final endDateTime = DateTime(endDate.year, endDate.month, endDate.day);

      while (!currentDate.isAfter(endDateTime)) {
        dates.add(currentDate);
        currentDate = currentDate.add(const Duration(days: 1));
      }

      // 处理每一天的数据
      for (var date in dates) {
        final nextDay = date.add(const Duration(days: 1));
        var dayData = weightData.where((data) =>
            data.dateFrom.isAfter(date) && data.dateFrom.isBefore(nextDay));

        if (dayData.isNotEmpty) {
          try {
            double value = _getNumericValue(dayData.last);
            weightTrend.add({
              'date': date,
              'value': value,
              'title': '${date.month}/${date.day}'
            });
          } catch (e) {
            logger.d("体重数据转换失败: $e");
            weightTrend.add({
              'date': date,
              'value': 0.0,
              'title': '${date.month}/${date.day}'
            });
          }
        } else {
          weightTrend.add({
            'date': date,
            'value': 0.0,
            'title': '${date.month}/${date.day}'
          });
        }
      }

      return weightTrend;
    } catch (e) {
      logger.d("获取体重趋势数据失败: $e");
      return [];
    }
  }

  // 获取血压趋势数据
  Future<Map<String, List<Map<String, dynamic>>>> getBloodPressureTrend(
      DateTime startDate, DateTime endDate) async {
    List<Map<String, dynamic>> systolicTrend = [];
    List<Map<String, dynamic>> diastolicTrend = [];

    try {
      List<HealthDataPoint> systolicData = await _health.getHealthDataFromTypes(
        startTime: startDate,
        endTime: endDate.add(const Duration(days: 1)),
        types: [HealthDataType.BLOOD_PRESSURE_SYSTOLIC],
      );

      List<HealthDataPoint> diastolicData =
          await _health.getHealthDataFromTypes(
        startTime: startDate,
        endTime: endDate.add(const Duration(days: 1)),
        types: [HealthDataType.BLOOD_PRESSURE_DIASTOLIC],
      );

      // 计算日期范围内的所有日期
      List<DateTime> dates = [];
      DateTime currentDate =
          DateTime(startDate.year, startDate.month, startDate.day);
      final endDateTime = DateTime(endDate.year, endDate.month, endDate.day);

      while (!currentDate.isAfter(endDateTime)) {
        dates.add(currentDate);
        currentDate = currentDate.add(const Duration(days: 1));
      }

      // 处理每一天的数据
      for (var date in dates) {
        final nextDay = date.add(const Duration(days: 1));

        // 处理收缩压数据
        var systolicDayData = systolicData.where((data) =>
            data.dateFrom.isAfter(date) && data.dateFrom.isBefore(nextDay));

        if (systolicDayData.isNotEmpty) {
          double totalSystolic = 0;
          int count = 0;

          for (var item in systolicDayData) {
            try {
              double value = _getNumericValue(item);
              totalSystolic += value;
              count++;
            } catch (e) {
              logger.d("收缩压数据转换失败: $e");
              continue;
            }
          }

          systolicTrend.add({
            'date': date,
            'value': count > 0 ? totalSystolic / count : 0.0,
            'title': '${date.month}/${date.day}'
          });
        } else {
          systolicTrend.add({
            'date': date,
            'value': 0.0,
            'title': '${date.month}/${date.day}'
          });
        }

        // 处理舒张压数据
        var diastolicDayData = diastolicData.where((data) =>
            data.dateFrom.isAfter(date) && data.dateFrom.isBefore(nextDay));

        if (diastolicDayData.isNotEmpty) {
          double totalDiastolic = 0;
          int count = 0;

          for (var item in diastolicDayData) {
            try {
              double value = _getNumericValue(item);
              totalDiastolic += value;
              count++;
            } catch (e) {
              logger.d("舒张压数据转换失败: $e");
              continue;
            }
          }

          diastolicTrend.add({
            'date': date,
            'value': count > 0 ? totalDiastolic / count : 0.0,
            'title': '${date.month}/${date.day}'
          });
        } else {
          diastolicTrend.add({
            'date': date,
            'value': 0.0,
            'title': '${date.month}/${date.day}'
          });
        }
      }

      return {
        'systolic': systolicTrend,
        'diastolic': diastolicTrend,
      };
    } catch (e) {
      logger.d("获取血压趋势数据失败: $e");
      return {
        'systolic': [],
        'diastolic': [],
      };
    }
  }

  // 获取指定日期范围内的运动消耗能量和睡眠时长
  Future<Map<String, String>> getEnergyAndSleepData(
      DateTime startDate, DateTime endDate) async {
    Map<String, String> result = {
      'total_energy_sum': '0',
      'total_sleep_hours_sum': '0',
    };

    try {
      // 获取运动消耗能量数据
      List<HealthDataPoint> energyData = await _health.getHealthDataFromTypes(
        startTime: startDate,
        endTime: endDate.add(const Duration(days: 1)),
        types: [HealthDataType.ACTIVE_ENERGY_BURNED],
      );

      // 调整睡眠数据的时间范围
      DateTime adjustedStartDate = startDate.subtract(const Duration(hours: 4));
      DateTime adjustedEndDate = endDate
          .add(const Duration(days: 1))
          .subtract(const Duration(hours: 4));

      // 首先获取SLEEP_ASLEEP数据
      List<HealthDataPoint> sleepData = await _health.getHealthDataFromTypes(
        startTime: adjustedStartDate,
        endTime: adjustedEndDate,
        types: [HealthDataType.SLEEP_ASLEEP],
      );

      // 如果SLEEP_ASLEEP没有数据，则获取SLEEP_IN_BED数据
      if (sleepData.isEmpty) {
        sleepData = await _health.getHealthDataFromTypes(
          startTime: adjustedStartDate,
          endTime: adjustedEndDate,
          types: [HealthDataType.SLEEP_IN_BED],
        );
      }

      // 计算能量消耗总和
      double totalEnergySum = 0;
      Set<String> energyDays = {};
      for (var item in energyData) {
        totalEnergySum += _getNumericValue(item);
        String dateKey =
            "${item.dateFrom.year}-${item.dateFrom.month.toString().padLeft(2, '0')}-${item.dateFrom.day.toString().padLeft(2, '0')}";
        energyDays.add(dateKey);
      }

      // 计算睡眠时长总和
      double totalSleepHoursSum = 0;
      Set<String> sleepDays = {};
      for (var item in sleepData) {
        Duration sleepDuration = item.dateTo.difference(item.dateFrom);
        totalSleepHoursSum += sleepDuration.inMinutes / 60.0;
        DateTime adjustedDate = item.dateFrom.add(const Duration(hours: 4));
        String dateKey =
            "${adjustedDate.year}-${adjustedDate.month.toString().padLeft(2, '0')}-${adjustedDate.day.toString().padLeft(2, '0')}";
        sleepDays.add(dateKey);
      }

      // 添加平均数据
      result['total_energy_sum'] = energyDays.isEmpty
          ? '0'
          : (totalEnergySum / energyDays.length).toStringAsFixed(1);
      result['total_sleep_hours_sum'] = sleepDays.isEmpty
          ? '0'
          : (totalSleepHoursSum / sleepDays.length).toStringAsFixed(1);

      return result;
    } catch (e) {
      logger.d("获取能量消耗和睡眠数据失败: $e");
      return result;
    }
  }
}
