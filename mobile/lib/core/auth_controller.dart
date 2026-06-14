import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

import 'api_client.dart';

final secureStorageProvider = Provider<FlutterSecureStorage>((ref) {
  return const FlutterSecureStorage();
});

final authControllerProvider =
    StateNotifierProvider<AuthController, AuthState>((ref) {
  return AuthController(
    api: ref.watch(rawApiClientProvider),
    storage: ref.watch(secureStorageProvider),
  )..restore();
});

class AuthState {
  const AuthState({
    required this.token,
    required this.user,
    required this.loading,
    required this.error,
  });

  const AuthState.initial()
      : token = null,
        user = null,
        loading = false,
        error = null;

  final String? token;
  final Map<String, dynamic>? user;
  final bool loading;
  final String? error;

  bool get isAuthenticated => token != null;

  AuthState copyWith({
    String? token,
    Map<String, dynamic>? user,
    bool? loading,
    String? error,
    bool clearToken = false,
    bool clearError = false,
  }) {
    return AuthState(
      token: clearToken ? null : token ?? this.token,
      user: user ?? this.user,
      loading: loading ?? this.loading,
      error: clearError ? null : error ?? this.error,
    );
  }
}

class AuthController extends StateNotifier<AuthState> {
  AuthController({required this.api, required this.storage})
      : super(const AuthState.initial());

  final ApiClient api;
  final FlutterSecureStorage storage;

  Future<void> restore() async {
    final token = await storage.read(key: 'auth_token');
    if (token != null) {
      state = state.copyWith(token: token);
    }
  }

  Future<void> login(String email, String password) async {
    await _authenticate('/login', {'email': email, 'password': password});
  }

  Future<void> signup(String email, String username, String password) async {
    await _authenticate('/signup',
        {'email': email, 'username': username, 'password': password});
  }

  Future<void> logout() async {
    final token = state.token;
    if (token != null) {
      try {
        await ApiClient(token: token).postEmpty('/logout', <String, dynamic>{});
      } on DioException {
        // Local logout should still clear credentials if the network is unavailable.
      }
    }
    await storage.delete(key: 'auth_token');
    state = const AuthState.initial();
  }

  Future<void> _authenticate(String path, Map<String, dynamic> body) async {
    state = state.copyWith(loading: true, clearError: true);
    try {
      final data = await api.postMap(path, body);
      final token = data['token'] as String;
      await storage.write(key: 'auth_token', value: token);
      state = AuthState(
        token: token,
        user: data['user'] as Map<String, dynamic>?,
        loading: false,
        error: null,
      );
    } on DioException catch (error) {
      state = state.copyWith(loading: false, error: _message(error));
    }
  }

  String _message(DioException error) {
    final data = error.response?.data;
    if (data is Map<String, dynamic>) {
      final apiError = data['error'];
      if (apiError is Map<String, dynamic>) {
        return apiError['message']?.toString() ?? 'Request failed.';
      }
    }
    return 'Request failed.';
  }
}
