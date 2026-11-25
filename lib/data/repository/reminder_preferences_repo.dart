import '../api/api_client.dart';
import '../../model/reminder_preferences_model.dart';

class ReminderPreferencesRepo {
  ReminderPreferencesRepo({ApiClient? apiClient})
      : _apiClient = apiClient ?? ApiClient();

  final ApiClient _apiClient;

  Future<ReminderPreferences> getPreferences() async {
    final response = await _apiClient.getData('api/reminder-preferences');
    final data = response['data'];
    if (data is! Map) {
      throw ApiException('The reminder preferences response was invalid.');
    }
    return ReminderPreferences.fromJson(Map<String, dynamic>.from(data));
  }

  Future<ReminderPreferences> updatePreferences(
      ReminderPreferences preferences) async {
    final response = await _apiClient.postAuthenticatedData(
      'api/reminder-preferences',
      preferences.toJson(),
    );
    final data = response['data'];
    if (data is! Map) {
      throw ApiException(
          'The saved reminder preferences response was invalid.');
    }
    return ReminderPreferences.fromJson(Map<String, dynamic>.from(data));
  }
}
