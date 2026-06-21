import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../core/api_client.dart';
import '../models/usuario.dart';

class AuthState {
  final Usuario? usuario;
  final bool loading;
  final String? error;

  const AuthState({this.usuario, this.loading = false, this.error});

  bool get isAuthenticated => usuario != null;
  AuthState copyWith({Usuario? usuario, bool? loading, String? error}) =>
      AuthState(
        usuario: usuario ?? this.usuario,
        loading: loading ?? this.loading,
        error: error,
      );
}

class AuthNotifier extends StateNotifier<AuthState> {
  final ApiClient _api;

  AuthNotifier(this._api) : super(const AuthState()) {
    _checkToken();
  }

  Future<void> _checkToken() async {
    final token = await _api.getToken();
    if (token == null) return;
    try {
      final resp = await _api.get('/usuarios/me');
      state = AuthState(usuario: Usuario.fromJson(resp.data));
    } catch (_) {
      await _api.clearToken();
    }
  }

  Future<bool> login(String email, String senha) async {
    state = state.copyWith(loading: true, error: null);
    try {
      final resp = await _api.post('/auth/login', data: {'email': email, 'senha': senha});
      await _api.saveToken(resp.data['access_token']);
      state = AuthState(usuario: Usuario.fromJson(resp.data['usuario']));
      return true;
    } catch (e) {
      state = state.copyWith(loading: false, error: 'E-mail ou senha incorretos');
      return false;
    }
  }

  Future<bool> registrar(String nome, String email, String senha) async {
    state = state.copyWith(loading: true, error: null);
    try {
      final resp = await _api.post('/auth/registrar',
          data: {'nome': nome, 'email': email, 'senha': senha});
      await _api.saveToken(resp.data['access_token']);
      state = AuthState(usuario: Usuario.fromJson(resp.data['usuario']));
      return true;
    } catch (e) {
      state = state.copyWith(loading: false, error: 'Erro ao criar conta. Tente novamente.');
      return false;
    }
  }

  Future<void> logout() async {
    await _api.clearToken();
    state = const AuthState();
  }
}

final authProvider = StateNotifierProvider<AuthNotifier, AuthState>((ref) {
  return AuthNotifier(ref.read(apiClientProvider));
});
