/// API Service
///
/// Generic HTTP client for Laravel API communication.
/// Handles exam operations and can be extended for study plans,
/// performance tracking, and other backend features.

import 'package:dio/dio.dart';
import '../config/api_config.dart';
import '../models/exam_model.dart';
import '../models/study_plan_model.dart';

/// Custom exception for API errors
class ApiException implements Exception {
  final String message;
  final int? statusCode;
  final String? errorCode;

  const ApiException(this.message, [this.statusCode, this.errorCode]);

  @override
  String toString() => message;

  /// Create user-friendly error message based on status code
  factory ApiException.fromStatusCode(int statusCode, [String? serverMessage]) {
    switch (statusCode) {
      case 400:
        return ApiException(
          serverMessage ?? 'Invalid request. Please check your input.',
          statusCode,
          'BAD_REQUEST',
        );
      case 401:
        return ApiException(
          'Authentication required. Please sign in again.',
          statusCode,
          'UNAUTHORIZED',
        );
      case 403:
        return ApiException(
          'You do not have permission to perform this action.',
          statusCode,
          'FORBIDDEN',
        );
      case 404:
        return ApiException(
          serverMessage ?? 'The requested resource was not found.',
          statusCode,
          'NOT_FOUND',
        );
      case 422:
        return ApiException(
          serverMessage ?? 'Validation failed. Please check your input.',
          statusCode,
          'VALIDATION_ERROR',
        );
      case 429:
        return ApiException(
          'Too many requests. Please try again later.',
          statusCode,
          'RATE_LIMITED',
        );
      case 500:
        return ApiException(
          'Server error. Please try again later.',
          statusCode,
          'SERVER_ERROR',
        );
      default:
        return ApiException(
          serverMessage ?? 'An unexpected error occurred.',
          statusCode,
          'UNKNOWN',
        );
    }
  }
}

/// API Service singleton
class ApiService {
  // Singleton pattern
  static final ApiService _instance = ApiService._internal();
  factory ApiService() => _instance;
  ApiService._internal() {
    _dio = Dio(BaseOptions(
      baseUrl: ApiConfig.laravelApiUrl,
      connectTimeout: const Duration(seconds: 30),
      receiveTimeout: const Duration(seconds: 30),
      headers: {
        'Content-Type': 'application/json',
        'Accept': 'application/json',
      },
    ));
  }

  late final Dio _dio;

  // ========== GENERIC HTTP METHODS ==========

  /// Perform GET request
  Future<Map<String, dynamic>> get(
    String endpoint, {
    Map<String, dynamic>? queryParams,
  }) async {
    try {
      final response = await _dio.get(
        endpoint,
        queryParameters: queryParams,
      );
      return _handleResponse(response);
    } on DioException catch (e) {
      throw _handleDioError(e);
    }
  }

  /// Perform POST request
  Future<Map<String, dynamic>> post(
    String endpoint,
    Map<String, dynamic> body,
  ) async {
    try {
      final response = await _dio.post(endpoint, data: body);
      return _handleResponse(response);
    } on DioException catch (e) {
      throw _handleDioError(e);
    }
  }

  /// Perform PUT request
  Future<Map<String, dynamic>> put(
    String endpoint,
    Map<String, dynamic> body,
  ) async {
    try {
      final response = await _dio.put(endpoint, data: body);
      return _handleResponse(response);
    } on DioException catch (e) {
      throw _handleDioError(e);
    }
  }

  /// Perform DELETE request
  Future<void> delete(String endpoint, {Map<String, dynamic>? queryParams}) async {
    try {
      await _dio.delete(endpoint, queryParameters: queryParams);
    } on DioException catch (e) {
      throw _handleDioError(e);
    }
  }

  /// Handle API response
  Map<String, dynamic> _handleResponse(Response response) {
    if (response.data == null) {
      return {'success': true};
    }
    if (response.data is Map<String, dynamic>) {
      return response.data as Map<String, dynamic>;
    }
    return {'success': true, 'data': response.data};
  }

  /// Handle Dio errors
  ApiException _handleDioError(DioException e) {
    switch (e.type) {
      case DioExceptionType.connectionTimeout:
      case DioExceptionType.sendTimeout:
      case DioExceptionType.receiveTimeout:
        return const ApiException(
          'Connection timed out. Please try again.',
          null,
          'TIMEOUT',
        );
      case DioExceptionType.connectionError:
        return const ApiException(
          'No internet connection. Please check your network.',
          null,
          'NETWORK_ERROR',
        );
      case DioExceptionType.badResponse:
        final statusCode = e.response?.statusCode;
        String? serverMessage;
        try {
          final data = e.response?.data;
          if (data is Map) {
            serverMessage = data['message'] ?? data['error'];
          }
        } catch (_) {}
        return ApiException.fromStatusCode(statusCode ?? 500, serverMessage);
      case DioExceptionType.cancel:
        return const ApiException(
          'Request was cancelled.',
          null,
          'CANCELLED',
        );
      default:
        return const ApiException(
          'Connection failed. Please try again.',
          null,
          'CONNECTION_ERROR',
        );
    }
  }

  // ========== EXAM-SPECIFIC METHODS ==========

  /// Get all exams for a user
  Future<List<ExamModel>> getExams(String userId) async {
    final response = await get('/exams', queryParams: {'userId': userId});

    final data = response['data'];
    if (data == null) return [];

    if (data is List) {
      return data.map((e) => ExamModel.fromJson(e as Map<String, dynamic>)).toList();
    }

    return [];
  }

  /// Get upcoming exams for a user (not completed, future dates)
  Future<List<ExamModel>> getUpcomingExams(String userId) async {
    final response = await get('/exams/upcoming', queryParams: {'userId': userId});

    final data = response['data'];
    if (data == null) return [];

    if (data is List) {
      return data.map((e) => ExamModel.fromJson(e as Map<String, dynamic>)).toList();
    }

    return [];
  }

  /// Get a single exam by ID
  Future<ExamModel> getExam(int examId, String userId) async {
    final response = await get('/exams/$examId', queryParams: {'userId': userId});

    final data = response['data'];
    if (data == null) {
      throw const ApiException('Exam not found', 404, 'NOT_FOUND');
    }

    return ExamModel.fromJson(data as Map<String, dynamic>);
  }

  /// Create a new exam
  Future<ExamModel> createExam(ExamModel exam) async {
    final response = await post('/exams', exam.toJson());

    final data = response['data'];
    if (data == null) {
      throw const ApiException('Failed to create exam', null, 'CREATE_FAILED');
    }

    return ExamModel.fromJson(data as Map<String, dynamic>);
  }

  /// Update an existing exam
  Future<ExamModel> updateExam(ExamModel exam) async {
    final response = await put('/exams/${exam.id}', exam.toJson());

    final data = response['data'];
    if (data == null) {
      throw const ApiException('Failed to update exam', null, 'UPDATE_FAILED');
    }

    return ExamModel.fromJson(data as Map<String, dynamic>);
  }

  /// Delete an exam
  Future<void> deleteExam(int examId, String userId) async {
    await delete('/exams/$examId', queryParams: {'userId': userId});
  }

  /// Toggle exam completion status
  Future<ExamModel> toggleExamCompleted(int examId, bool isCompleted, String userId) async {
    final response = await put('/exams/$examId', {
      'userId': userId,
      'isCompleted': isCompleted,
    });

    final data = response['data'];
    if (data == null) {
      throw const ApiException('Failed to update exam', null, 'UPDATE_FAILED');
    }

    return ExamModel.fromJson(data as Map<String, dynamic>);
  }

  // ========== STUDY PLAN METHODS ==========

  /// Get all study plans for a user
  Future<List<StudyPlanModel>> getStudyPlans(String userId) async {
    final response = await get('/study-plan', queryParams: {'userId': userId});

    final data = response['data'];
    if (data == null) return [];

    if (data is List) {
      return data.map((e) => StudyPlanModel.fromJson(e as Map<String, dynamic>)).toList();
    }

    return [];
  }

  /// Get a single study plan by ID
  Future<StudyPlanModel> getStudyPlan(int planId, String userId) async {
    final response = await get('/study-plan/$planId', queryParams: {'userId': userId});

    final data = response['data'];
    if (data == null) {
      throw const ApiException('Study plan not found', 404, 'NOT_FOUND');
    }

    return StudyPlanModel.fromJson(data as Map<String, dynamic>);
  }

  /// Generate a new study plan
  ///
  /// [subjects] - List of subjects with name, difficulty, and exam date
  /// [availableHoursPerDay] - Hours available for study per day (1-12)
  /// [preferredStudyTime] - Preferred time of day (morning, afternoon, evening, night)
  Future<StudyPlanModel> generateStudyPlan({
    required String userId,
    required List<StudySubject> subjects,
    required int availableHoursPerDay,
    required String preferredStudyTime,
  }) async {
    final response = await post('/study-plan/generate', {
      'userId': userId,
      'subjects': subjects.map((s) => s.toJson()).toList(),
      'availableHoursPerDay': availableHoursPerDay,
      'preferredStudyTime': preferredStudyTime,
    });

    final data = response['data'];
    if (data == null) {
      throw const ApiException('Failed to generate study plan', null, 'GENERATE_FAILED');
    }

    return StudyPlanModel.fromJson(data as Map<String, dynamic>);
  }

  /// Delete a study plan
  Future<void> deleteStudyPlan(int planId, String userId) async {
    await delete('/study-plan/$planId', queryParams: {'userId': userId});
  }
}
