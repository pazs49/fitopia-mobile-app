import 'package:fitopia/data/api/api_client.dart';

class AuthRepo {
  final ApiClient apiClient;

  AuthRepo({required this.apiClient});

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
