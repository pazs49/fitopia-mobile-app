import 'package:fitopia/data/api/api_client.dart';
import 'package:fitopia/data/repository/auth_repo.dart';
import 'package:get/get.dart';
import 'package:get_storage/get_storage.dart';

class AuthController extends GetxController {
  AuthController({AuthRepo? authRepo})
      : authRepo = authRepo ?? AuthRepo(apiClient: ApiClient());

  final AuthRepo authRepo;
  final GetStorage storage = GetStorage();

  bool isLoading = false;
  String? errorMessage;

  Future<bool> login(String email, String password) async {
    isLoading = true;
    errorMessage = null;
    update();

    try {
      final response = await authRepo.login(email, password);
      final rawData = response['data'];

      if (rawData is! Map) {
        throw ApiException('The login response did not contain user data.');
      }

      final userData = Map<String, dynamic>.from(rawData);
      final apiToken = userData['api_token'];
      if (apiToken is! String || apiToken.isEmpty) {
        throw ApiException('The login response did not contain an API token.');
      }

      await storage.write('api_token', apiToken);
      final refreshToken = userData['refresh_token'];
      if (refreshToken is String && refreshToken.isNotEmpty) {
        await storage.write('refresh_token', refreshToken);
      }
      await storage.write('user_data', userData);

      return true;
    } on ApiException catch (error) {
      errorMessage = error.message;
      return false;
    } finally {
      isLoading = false;
      update();
    }
  }
}
