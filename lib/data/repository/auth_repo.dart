import 'package:fitopia/data/api/api_client.dart';

class AuthRepo {
  final ApiClient apiClient;

  AuthRepo({required this.apiClient});

  Future<Map<String, dynamic>> register({
    required String email,
    required String password,
    required String firstName,
    required String lastName,
  }) {
    return apiClient.postData(
      'api/register',
      <String, dynamic>{
        'email': email,
        'password': password,
        'first_name': firstName,
        'last_name': lastName,
      },
    );
  }

  Future<Map<String, dynamic>> login(String email, String password) {
    return apiClient.postData(
      'api/login',
      <String, dynamic>{
        'email': email,
        'password': password,
      },
    );
  }

  Future<void> logout() async {
    await apiClient.getData('api/logout');
  }
}
