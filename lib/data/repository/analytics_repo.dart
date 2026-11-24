import 'package:fitopia/data/api/api_client.dart';
import 'package:fitopia/model/analytics_model.dart';
import 'dart:io';

class AnalyticsRepo {
  final ApiClient apiClient;

  AnalyticsRepo({required this.apiClient});

  Future<AnalyticsData> getAnalytics({
    required String metric,
    required int period,
    DateTime? endDate,
  }) async {
    final date = endDate ?? DateTime.now();
    final response = await apiClient.getData(
      'api/analytics?metric=$metric&period=$period&end_date=${date.toIso8601String().split('T').first}',
    );
    final rawData = response['data'];
    if (rawData is! Map) {
      throw ApiException('The analytics response was invalid.');
    }

    return AnalyticsData.fromJson(Map<String, dynamic>.from(rawData));
  }

  Future<void> saveMeasurement({
    required DateTime date,
    double? weight,
    int? steps,
    double? neck,
    double? waist,
    double? hips,
  }) async {
    await apiClient.postAuthenticatedData('api/usermeasurement_create', {
      'measure_date': date.toIso8601String().split('T').first,
      if (weight != null) 'Weight': weight,
      if (steps != null) 'steps': steps,
      if (neck != null) 'Neck': neck,
      if (waist != null) 'Waist': waist,
      if (hips != null) 'Hips': hips,
    });
  }

  Future<void> uploadProgressPhoto(File file) async {
    await apiClient.postAuthenticatedMultipart(
      'api/userselfiegallier_create',
      file: file,
      fieldName: 'user_selfie_img',
    );
  }

  Future<void> deleteProgressPhoto(int photoId) async {
    await apiClient.postAuthenticatedData(
      'api/userselfiegallier_delete',
      {'id': photoId},
    );
  }

  Future<List<int>> exportMeasurements() {
    return apiClient.getAuthenticatedBytes('api/usermeasurement1_pdfview');
  }
}
