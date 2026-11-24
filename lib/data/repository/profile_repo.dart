import 'dart:io';

import 'package:fitopia/data/api/api_client.dart';
import 'package:fitopia/model/profile_summary_model.dart';
import 'package:fitopia/presentation/resources/index_manager.dart';

class ProfileRepo {
  final ApiClient apiClient;

  ProfileRepo({required this.apiClient});

  Future<ProfileSummary> getSummary() async {
    final response = await apiClient.getData('api/userprofile');
    return ProfileSummary.fromJson(response);
  }

  Future<void> updateStartingWeight(double weight) async {
    await apiClient.postAuthenticatedData(
      'api/userprofile/starting-weight',
      {'weight': weight},
    );
  }

  Future<Map<String, dynamic>> updateName({
    required String firstName,
    required String lastName,
  }) {
    return apiClient.postAuthenticatedData(
      'api/update-profile',
      {
        'first_name': firstName,
        'last_name': lastName,
      },
    );
  }

  Future<Map<String, dynamic>> updatePhone(String phoneNumber) {
    return apiClient.postAuthenticatedData(
      'api/update-profile',
      {'phone_number': phoneNumber},
    );
  }

  Future<Map<String, dynamic>> uploadProfilePhoto(File file) {
    return apiClient.postAuthenticatedMultipart(
      'api/update-profile',
      file: file,
      fieldName: 'profile_image',
    );
  }
}

String? resolveProfileImageUrl(dynamic value) {
  final raw = value?.toString().trim();
  if (raw == null || raw.isEmpty || AppStrings.appBaseUrl.isEmpty) {
    return raw;
  }

  final imageUri = Uri.tryParse(raw);
  final baseUri = Uri.tryParse(AppStrings.appBaseUrl);
  if (imageUri == null || baseUri == null) {
    return raw;
  }

  final isLocalHost = imageUri.host == '127.0.0.1' ||
      imageUri.host == 'localhost' ||
      imageUri.host == '::1';
  if (!imageUri.hasScheme || isLocalHost) {
    return baseUri
        .resolve(imageUri.hasScheme ? imageUri.path : raw)
        .replace(query: imageUri.query, fragment: imageUri.fragment)
        .toString();
  }
  return raw;
}
