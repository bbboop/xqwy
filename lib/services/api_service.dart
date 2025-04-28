import 'package:dio/dio.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:io';
import 'package:flutter/foundation.dart';

class ApiService {
  static final ApiService _instance = ApiService._internal();
  final Dio _dio = Dio();
  static const String _tokenKey = 'auth_token';
  static const String _userProfileKey = 'user_profile';
  static const String _userProfileCompleteKey = 'profile_complete';

  // token 过期后的回调函数
  static VoidCallback? onTokenExpired;

  factory ApiService() {
    return _instance;
  }

  // 获取基础 URL
  String getBaseUrl() {
    return _dio.options.baseUrl;
  }

  ApiService._internal() {
    // 根据运行模式设置不同的baseUrl
    _dio.options.baseUrl = kReleaseMode
        ? 'http://jk.6xq.cn' // 生产环境
        : 'http://192.168.15.246:3000'; // 开发环境

    _dio.options.connectTimeout = const Duration(seconds: 5);
    _dio.options.receiveTimeout = const Duration(seconds: 3);

    // 添加请求拦截器，自动添加token
    _dio.interceptors.add(InterceptorsWrapper(
      onRequest: (options, handler) async {
        final token = await _getToken();
        if (token != null) {
          options.headers['Authorization'] = 'Bearer $token';
        }
        return handler.next(options);
      },
      onError: (DioException error, handler) async {
        // 处理 401 错误（token 过期）
        if (error.response?.statusCode == 401) {
          // 清除 token
          await clearToken();

          // 调用 token 过期回调函数
          if (onTokenExpired != null) {
            onTokenExpired!();
          }
        }
        return handler.next(error);
      },
    ));
  }

  // 获取保存的token
  Future<String?> _getToken() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_tokenKey);
  }

  // 保存token
  Future<void> _saveToken(String token) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_tokenKey, token);
  }

  // 清除token
  Future<void> clearToken() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_tokenKey);
  }

  // 登出
  Future<void> logout() async {
    final prefs = await SharedPreferences.getInstance();
    // 清除 token
    await prefs.remove(_tokenKey);
    // 清除用户资料状态
    await prefs.remove(_userProfileKey);
    await prefs.remove(_userProfileCompleteKey);

    // 可以在这里添加退出登录的 API 调用
    // try {
    //   await _dio.post('/api/member/logout');
    // } catch (e) {
    //   // 即使 API 调用失败，也继续清除本地数据
    // }
  }

  // 保存用户资料
  Future<void> saveUserProfile(Map<String, dynamic> userProfile) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_userProfileKey, userProfile.toString());
    await prefs.setBool(_userProfileCompleteKey, true);
  }

  // 检查用户资料是否完整
  Future<bool> isProfileComplete() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool(_userProfileCompleteKey) ?? false;
  }

  // 密码登录
  Future<Map<String, dynamic>> loginWithPassword(
      String phone, String password) async {
    try {
      final response = await _dio.post('/api/member/login-password', data: {
        'phone': phone,
        'password': password,
      });

      if (response.data['code'] == 200 &&
          response.data['data']['token'] != null) {
        await _saveToken(response.data['data']['token']);

        // 同时检查用户资料状态
        if (response.data['data']['userInfo'] != null) {
          final userInfo = response.data['data']['userInfo'];
          // 判断用户资料是否完整
          final isComplete = userInfo['height'] != null &&
              userInfo['weight'] != null &&
              userInfo['birthdate'] != null &&
              userInfo['gender'] != null;

          final prefs = await SharedPreferences.getInstance();
          await prefs.setBool(_userProfileCompleteKey, isComplete);
        }
      }
      return response.data;
    } catch (e) {
      return _handleError(e);
    }
  }

  // 验证码登录
  Future<Map<String, dynamic>> loginWithSms(String phone, String code) async {
    try {
      final response = await _dio.post('/api/member/login-sms', data: {
        'phone': phone,
        'code': code,
      });

      if (response.data['code'] == 200 &&
          response.data['data']['token'] != null) {
        await _saveToken(response.data['data']['token']);

        // 同时检查用户资料状态
        if (response.data['data']['userInfo'] != null) {
          final userInfo = response.data['data']['userInfo'];
          // 判断用户资料是否完整
          final isComplete = userInfo['height'] != null &&
              userInfo['weight'] != null &&
              userInfo['birthdate'] != null &&
              userInfo['gender'] != null;

          final prefs = await SharedPreferences.getInstance();
          await prefs.setBool(_userProfileCompleteKey, isComplete);
        }
      }
      return response.data;
    } catch (e) {
      return _handleError(e);
    }
  }

  // 发送验证码
  Future<Map<String, dynamic>> sendSmsCode(String phone) async {
    try {
      final response = await _dio.post('/api/member/send-sms-code', data: {
        'phone': phone,
      });
      return response.data;
    } catch (e) {
      return _handleError(e);
    }
  }

  // 注册
  Future<Map<String, dynamic>> register(
      String name, String phone, String password,
      {File? avatarFile}) async {
    try {
      Map<String, dynamic> data = {
        'name': name,
        'phone': phone,
        'password': password,
      };

      if (avatarFile != null) {
        // 创建 MultipartFile
        String fileName = avatarFile.path.split('/').last;
        FormData formData = FormData.fromMap({
          'name': name,
          'phone': phone,
          'password': password,
          'avatar': await MultipartFile.fromFile(
            avatarFile.path,
            filename: fileName,
          ),
        });

        final response = await _dio.post(
          '/api/member/register',
          data: formData,
          options: Options(
            contentType: 'multipart/form-data',
          ),
        );
        return response.data;
      } else {
        final response = await _dio.post('/api/member/register', data: data);
        return response.data;
      }
    } catch (e) {
      return _handleError(e);
    }
  }

  // 更新用户资料
  Future<Map<String, dynamic>> updateUserProfile(
      Map<String, dynamic> profileData) async {
    try {
      final response =
          await _dio.post('/api/member/update-profile', data: profileData);

      // 如果更新成功，同时更新本地的资料状态
      if (response.data['code'] == 200) {
        await saveUserProfile(profileData);
      }

      return response.data;
    } catch (e) {
      return _handleError(e);
    }
  }

  // 更新用户基本信息
  Future<Map<String, dynamic>> updateUserInfo(dynamic data) async {
    try {
      final response = await _dio.post(
        '/api/member/update',
        data: data,
        options: data is FormData
            ? Options(contentType: 'multipart/form-data')
            : null,
      );
      return response.data;
    } catch (e) {
      return _handleError(e);
    }
  }

  // 获取用户信息
  Future<Map<String, dynamic>> getUserProfile() async {
    try {
      final response = await _dio.post('/api/member/profile');

      // 如果获取成功，更新本地的资料状态
      if (response.data['code'] == 200 && response.data['data'] != null) {
        final userInfo = response.data['data'];

        // 判断用户资料是否完整
        final isComplete = userInfo['height'] != null &&
            userInfo['weight'] != null &&
            userInfo['birthdate'] != null &&
            userInfo['gender'] != null;

        if (isComplete) {
          // 将获取到的用户信息保存到本地
          final Map<String, dynamic> profileData = {
            'height': userInfo['height'],
            'weight': userInfo['weight'],
            'birthdate': userInfo['birthdate'],
            'gender': userInfo['gender'],
          };
          await saveUserProfile(profileData);
        }

        final prefs = await SharedPreferences.getInstance();
        await prefs.setBool(_userProfileCompleteKey, isComplete);
      }

      return response.data;
    } catch (e) {
      return _handleError(e);
    }
  }

  // 统一处理错误
  Map<String, dynamic> _handleError(dynamic error) {
    if (error is DioException) {
      // 401 错误已在拦截器中处理
      return {
        'code': error.response?.statusCode ?? 500,
        'message': error.response?.data?['message'] ?? '网络请求失败',
      };
    }
    return {'code': 500, 'message': '服务器错误: ${error.toString()}'};
  }

  // 上传健康数据
  Future<Map<String, dynamic>> uploadHealthData({
    String? steps,
    String? heartRate,
    String? sleepMinutes,
    String? weightKg,
    String? bloodGlucoseMmol,
    String? systolicBp,
    String? diastolicBp,
    String? bmi,
    String? bodyFat,
    String? activeEnergy,
    String? exerciseMinutes,
    String? stepsMonth,
    String? sleepMonth,
    String? activeEnergyMonth,
    String? exerciseMinutesMonth,
    String? stepsToday,
    String? heartRateToday,
    String? sleepHoursToday,
    String? weightKgToday,
    String? bloodGlucoseMmolToday,
    String? systolicBpToday,
    String? diastolicBpToday,
    String? bmiToday,
    String? bodyFatToday,
    String? activeEnergyToday,
    String? exerciseMinutesToday,
  }) async {
    try {
      final Map<String, dynamic> healthData = {
        'steps': steps,
        'heart_rate': heartRate,
        'sleep_hours': sleepMinutes,
        'weight_kg': weightKg,
        'blood_glucose_mmol': bloodGlucoseMmol,
        'systolic_bp': systolicBp,
        'diastolic_bp': diastolicBp,
        'bmi': bmi,
        'body_fat': bodyFat,
        'active_energy': activeEnergy,
        'exercise_minutes': exerciseMinutes,
        'steps_today': stepsToday,
        'heart_rate_today': heartRateToday,
        'sleep_hours_today': sleepHoursToday,
        'weight_kg_today': weightKgToday,
        'blood_glucose_mmol_today': bloodGlucoseMmolToday,
        'systolic_bp_today': systolicBpToday,
        'diastolic_bp_today': diastolicBpToday,
        'bmi_today': bmiToday,
        'body_fat_today': bodyFatToday,
        'active_energy_today': activeEnergyToday,
        'exercise_minutes_today': exerciseMinutesToday,
      };

      // 移除空值和值为 '-' 的数据
      healthData.removeWhere((key, value) => value == null || value == '-');

      final response = await _dio.post('/api/health/create', data: healthData);
      return response.data;
    } catch (e) {
      return _handleError(e);
    }
  }

  // 获取健康数据详情
  Future<Map<String, dynamic>> getHealthDetail() async {
    try {
      final response = await _dio.post('/api/health/detail');
      return response.data;
    } catch (e) {
      return _handleError(e);
    }
  }

  // 保存目标设置
  Future<Map<String, dynamic>> saveGoals(
      List<Map<String, dynamic>> goals) async {
    try {
      final response = await _dio.post('/api/goals/batch-update', data: {
        'goals': goals,
      });
      return response.data;
    } catch (e) {
      return _handleError(e);
    }
  }

  // 获取目标设置
  Future<Map<String, dynamic>> getGoals() async {
    try {
      final response = await _dio.post('/api/goals/detail');
      return response.data;
    } catch (e) {
      return _handleError(e);
    }
  }

  // 获取今日目标设置
  Future<Map<String, dynamic>> getTodayGoals() async {
    try {
      final response = await _dio.post('/api/goals/today');
      return response.data;
    } catch (e) {
      return _handleError(e);
    }
  }

  // 更新目标完成状态
  Future<Map<String, dynamic>> updateGoalStatus(
      int id, bool shouldComplete) async {
    try {
      final response = await _dio.post('/api/goals/complete', data: {
        'id': id,
        'is_completed': shouldComplete ? 2 : 1,
      });
      return response.data;
    } catch (e) {
      return _handleError(e);
    }
  }

  // 获取 AI 健康分析
  Future<Map<String, dynamic>> getAIAnalysis([int isManual = 0]) async {
    try {
      final response = await _dio.post(
        '/api/coze/analyze',
        data: {
          'is_manual': isManual,
        },
        options: Options(
          sendTimeout: const Duration(seconds: 30),
          receiveTimeout: const Duration(seconds: 30),
        ),
      );
      return response.data;
    } catch (e) {
      return _handleError(e);
    }
  }

  // 获取趋势数据
  Future<Map<String, dynamic>> getTrends({
    required DateTime? startDate,
    required DateTime? endDate,
  }) async {
    try {
      final response = await _dio.post('/api/health/trends', data: {
        'startDate': startDate?.toIso8601String(),
        'endDate': endDate?.toIso8601String(),
      });
      return response.data;
    } catch (e) {
      return _handleError(e);
    }
  }

  // 获取最近7天的统计数据
  Future<Map<String, dynamic>> getWeeklyStats() async {
    try {
      final response = await _dio.post('/api/health/get-weekly-data');
      return response.data;
    } catch (e) {
      return _handleError(e);
    }
  }

  // 获取本周健康报告
  Future<Map<String, dynamic>> getWeeklyHealthReport({
    DateTime? startDate,
    DateTime? endDate,
    String? totalEnergy,
    String? totalSleepHours,
    String? totalEnergySum,
    String? totalSleepHoursSum,
  }) async {
    try {
      final response = await _dio.post(
        '/api/coze/weekly-report',
        data: {
          if (startDate != null)
            'startDate':
                "${startDate.year}-${startDate.month.toString().padLeft(2, '0')}-${startDate.day.toString().padLeft(2, '0')}",
          if (endDate != null)
            'endDate':
                "${endDate.year}-${endDate.month.toString().padLeft(2, '0')}-${endDate.day.toString().padLeft(2, '0')}",
          if (totalEnergy != null) 'totalEnergy': totalEnergy,
          if (totalSleepHours != null) 'totalSleepHours': totalSleepHours,
          if (totalEnergySum != null) 'totalEnergySum': totalEnergySum,
          if (totalSleepHoursSum != null)
            'totalSleepHoursSum': totalSleepHoursSum,
        },
        options: Options(
          sendTimeout: const Duration(seconds: 30),
          receiveTimeout: const Duration(seconds: 30),
        ),
      );
      return response.data;
    } catch (e) {
      return _handleError(e);
    }
  }

  // 获取心率数据
  Future<Map<String, dynamic>> getHeartRateData(String range) async {
    try {
      final response = await _dio.post('/api/health/heart-rate', data: {
        'range': range, // week, month, half_year
      });
      return response.data;
    } catch (e) {
      return _handleError(e);
    }
  }

  // 检查今天是否已同步健康数据
  Future<Map<String, dynamic>> checkSyncToday() async {
    try {
      final response = await _dio.post('/api/health/check-sync-today');
      return response.data;
    } catch (e) {
      return _handleError(e);
    }
  }

  // 保存数据显示设置
  Future<Map<String, dynamic>> saveDataDisplaySettings(
      Map<String, bool> settings) async {
    try {
      final response =
          await _dio.post('/api/member/save-display-settings', data: {
        'settings': {
          'weight': settings['weight'] ?? true,
          'heart': settings['heart'] ?? true,
          'blood_pressure': settings['blood_pressure'] ?? true,
          'blood_sugar': settings['blood_sugar'] ?? true,
          'sleep': settings['sleep'] ?? true,
          'exercise': settings['exercise'] ?? true,
          'body_overview': settings['body_overview'] ?? true,
        }
      });
      return response.data;
    } catch (e) {
      return _handleError(e);
    }
  }

  // 获取数据显示设置
  Future<Map<String, dynamic>> getDataDisplaySettings() async {
    try {
      final response = await _dio.post('/api/member/get-display-settings');
      return response.data;
    } catch (e) {
      return _handleError(e);
    }
  }

  // 获取隐私协议
  Future<Map<String, dynamic>> getPrivacyPolicy() async {
    try {
      final response = await _dio.post('/api/privacy/privacy-policy');
      return response.data;
    } catch (e) {
      return _handleError(e);
    }
  }

  // 获取用户协议
  Future<Map<String, dynamic>> getTermsOfService() async {
    try {
      final response = await _dio.post('/api/privacy/terms-of-service');
      return response.data;
    } catch (e) {
      return _handleError(e);
    }
  }

  // 提交意见反馈
  Future<Map<String, dynamic>> submitFeedback(
      String contact, String content) async {
    try {
      final response = await _dio.post('/api/feedback/save', data: {
        'contact': contact,
        'content': content,
      });
      return response.data;
    } catch (e) {
      return _handleError(e);
    }
  }

  // 自动生成健康目标
  Future<Map<String, dynamic>> autoGenerateWeeklyGoals() async {
    try {
      final response = await _dio.post('/api/goals/auto-generate-weekly-goals');
      return response.data;
    } catch (e) {
      return _handleError(e);
    }
  }

  // 食物识别上传
  Future<Map<String, dynamic>> uploadFoodImage(File image) async {
    try {
      String fileName = image.path.split('/').last;
      FormData formData = FormData.fromMap({
        'image': await MultipartFile.fromFile(
          image.path,
          filename: fileName,
        ),
      });

      final response = await _dio.post(
        '/api/coze/food-recognition',
        data: formData,
        options: Options(
          contentType: 'multipart/form-data',
          sendTimeout: const Duration(seconds: 40),
          receiveTimeout: const Duration(seconds: 40),
        ),
      );
      return response.data;
    } catch (e) {
      return _handleError(e);
    }
  }

  // 获取食物列表
  Future<Map<String, dynamic>> getFoodsList({
    required int page,
    required int pageSize,
  }) async {
    try {
      final response = await _dio.post('/api/foods/list', data: {
        'page': page,
        'pageSize': pageSize,
      });
      return response.data;
    } catch (e) {
      return _handleError(e);
    }
  }

  // 删除食物识别记录
  Future<Map<String, dynamic>> deleteFood(int id) async {
    try {
      final response = await _dio.post('/api/foods/delete', data: {
        'id': id,
      });
      return response.data;
    } catch (e) {
      return _handleError(e);
    }
  }

  // 更新健康数据
  Future<Map<String, dynamic>> updateHealthData({
    required int id,
    String? steps,
    String? heartRate,
    String? sleepHours,
    String? weightKg,
    String? bloodGlucoseMmol,
    String? systolicBp,
    String? diastolicBp,
  }) async {
    try {
      final Map<String, dynamic> healthData = {
        'id': id,
        'steps': steps,
        'heart_rate': heartRate,
        'sleep_hours': sleepHours,
        'weight_kg': weightKg,
        'blood_glucose_mmol': bloodGlucoseMmol,
        'systolic_bp': systolicBp,
        'diastolic_bp': diastolicBp,
      };

      // 移除空值
      healthData.removeWhere((key, value) => value == null || value == '');

      final response = await _dio.post('/api/health/update', data: healthData);
      return response.data;
    } catch (e) {
      return _handleError(e);
    }
  }
}
