import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'auth_controller.dart';

const configuredApiBaseUrl = String.fromEnvironment('API_BASE_URL');

String get apiBaseUrl {
  if (configuredApiBaseUrl.isNotEmpty) {
    return configuredApiBaseUrl;
  }
  return kIsWeb ? '/api' : 'http://localhost:8080';
}

String get normalizedApiBaseUrl =>
    apiBaseUrl.endsWith('/') ? apiBaseUrl : '$apiBaseUrl/';

String apiPath(String path) => path.replaceFirst(RegExp(r'^/+'), '');

final rawApiClientProvider = Provider<ApiClient>((ref) {
  return ApiClient(token: null);
});

final apiClientProvider = Provider<ApiClient>((ref) {
  final token = ref.watch(authControllerProvider).token;
  return ApiClient(token: token);
});

class ApiClient {
  ApiClient({required String? token})
      : dio = Dio(
          BaseOptions(
            baseUrl: normalizedApiBaseUrl,
            connectTimeout: const Duration(seconds: 10),
            receiveTimeout: const Duration(seconds: 20),
            headers: {
              if (token != null) 'Authorization': 'Bearer $token',
              'Content-Type': 'application/json',
            },
          ),
        );

  final Dio dio;

  Future<Map<String, dynamic>> getMap(String path,
      {Map<String, dynamic>? query}) async {
    final response = await dio.get<Map<String, dynamic>>(apiPath(path),
        queryParameters: query);
    return response.data ?? <String, dynamic>{};
  }

  Future<Map<String, dynamic>> postMap(
      String path, Map<String, dynamic> body) async {
    final response =
        await dio.post<Map<String, dynamic>>(apiPath(path), data: body);
    return response.data ?? <String, dynamic>{};
  }

  Future<void> postEmpty(String path, Map<String, dynamic> body) async {
    await dio.post<void>(apiPath(path), data: body);
  }

  Future<Map<String, dynamic>> patchMap(
      String path, Map<String, dynamic> body) async {
    final response =
        await dio.patch<Map<String, dynamic>>(apiPath(path), data: body);
    return response.data ?? <String, dynamic>{};
  }

  Future<void> delete(String path) async {
    await dio.delete<void>(apiPath(path));
  }
}
