import 'package:fitopia/data/api/api_client.dart';
import 'package:fitopia/model/my_program_model.dart';

class MyProgramRepo {
  final ApiClient apiClient;

  MyProgramRepo({required this.apiClient});

  Future<List<MyProgram>> getPrograms() async {
    final response =
        await apiClient.getData('api/workoutroutine-list?per_page=-1');
    final rawData = response['data'];
    if (rawData is! List) {
      throw ApiException('The programs response was invalid.');
    }

    return rawData
        .whereType<Map>()
        .map((item) => MyProgram.fromJson(Map<String, dynamic>.from(item)))
        .where((program) => program.title.isNotEmpty)
        .toList();
  }
}
