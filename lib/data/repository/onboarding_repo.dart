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

  Future<bool> hasCompletedOnboarding() async {
    final response = await apiClient.getData('api/onboarding-status');
    final completed = response['completed'];
    if (completed is bool) {
      return completed;
    }
    throw ApiException('The onboarding status response was invalid.');
  }
}
