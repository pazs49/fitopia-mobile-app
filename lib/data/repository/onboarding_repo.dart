import 'package:fitopia/data/api/api_client.dart';

class OnboardingRepo {
  final ApiClient apiClient;

  OnboardingRepo({required this.apiClient});

  Future<void> submit(Map<String, dynamic> data) async {
    await apiClient.postAuthenticatedData(
      'api/store-user-onboarding',
      data,
    );
  }
}
