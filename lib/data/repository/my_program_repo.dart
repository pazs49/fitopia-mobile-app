import 'package:fitopia/data/api/api_client.dart';
import 'package:fitopia/model/my_program_model.dart';

class MyProgramRepo {
  final ApiClient apiClient;

  MyProgramRepo({required this.apiClient});

  Future<List<MyProgram>> getPrograms() async {
    final today = DateTime.now();
    final startDate = today.subtract(const Duration(days: 7));
    final endDate = today.add(const Duration(days: 29));
    final start = startDate.toIso8601String().split('T').first;
    final end = endDate.toIso8601String().split('T').first;
    final response = await apiClient.getData(
      'api/ai-workouts/date-range?start_date=$start&end_date=$end',
    );
    final rawData = response['data'];
    if (rawData is! List) {
      throw ApiException('The programs response was invalid.');
    }

    return rawData
        .whereType<Map>()
        .map((item) => MyProgram.fromJson(Map<String, dynamic>.from(item)))
        .toList();
  }
}
