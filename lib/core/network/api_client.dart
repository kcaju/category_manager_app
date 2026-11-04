import 'package:dio/dio.dart';
import '../constants/app_constants.dart';
import '../errors/failures.dart';

class ApiClient {
  final Dio dio;

  ApiClient({Dio? customDio})
      : dio = customDio ??
            Dio(
              BaseOptions(
                baseUrl: AppConstants.jsonPlaceholderBaseUrl,
                connectTimeout: const Duration(seconds: 15),
                receiveTimeout: const Duration(seconds: 15),
                headers: {
                  'Content-Type': 'application/json',
                  'Accept': 'application/json',
                },
              ),
            );

  Future<Response<T>> get<T>(
    String path, {
    Map<String, dynamic>? queryParameters,
  }) async {
    try {
      final response = await dio.get<T>(
        path,
        queryParameters: queryParameters,
      );
      return response;
    } on DioException catch (e) {
      if (e.type == DioExceptionType.connectionTimeout ||
          e.type == DioExceptionType.receiveTimeout ||
          e.type == DioExceptionType.connectionError) {
        throw const NetworkFailure('Failed to connect to JSONPlaceholder API. Check your internet connection.');
      }
      final statusCode = e.response?.statusCode;
      final statusMessage = e.response?.statusMessage ?? e.message ?? 'Unknown API error';
      throw ServerFailure('API Error [$statusCode]: $statusMessage');
    } catch (e) {
      throw ServerFailure(e.toString());
    }
  }
}

