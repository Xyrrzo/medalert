import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/app_role.dart';

class AuthService {
  AuthService._();
  static final AuthService instance = AuthService._();
  final SupabaseClient _client = Supabase.instance.client;

  Stream<AuthState> get authChanges => _client.auth.onAuthStateChange;
  User? get currentUser => _client.auth.currentUser;

  Future<void> signIn(String email, String password) async {
    await _client.auth.signInWithPassword(email: email.trim(), password: password);
  }

  Future<void> register(String email, String password, String fullName) async {
    await _client.auth.signUp(email: email.trim(), password: password, data: {'full_name': fullName.trim()});
  }

  Future<void> resetPassword(String email) async {
    await _client.auth.resetPasswordForEmail(email.trim());
  }

  Future<AppRole> loadRole(String userId) async {
    final row = await _client.from('profiles').select('role').eq('id', userId).single();
    return AppRoleParsing.parse(row['role']);
  }

  Future<void> signOut() => _client.auth.signOut();
}
