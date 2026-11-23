import 'package:fitopia/data/api/api_client.dart';
import 'package:fitopia/model/meal_plan_model.dart';
import 'package:get_storage/get_storage.dart';

class MealPlanRepo {
  final ApiClient apiClient;

  MealPlanRepo({required this.apiClient});

  Future<MealPlan> getMealPlan({DateTime? startDate, DateTime? endDate}) async {
    final today = DateTime.now();
    final start = startDate ?? today.subtract(const Duration(days: 7));
    final end = endDate ?? today.add(const Duration(days: 23));
    final response = await apiClient.getData(
      'api/meal-plans?start_date=${_date(start)}&end_date=${_date(end)}',
    );
    if (response['success'] == false) {
      throw ApiException(
          response['message']?.toString() ?? 'Unable to load meal plans.');
    }
    return MealPlan.fromJson(response);
  }

  Future<bool> toggleMeal(MealPlanEntry meal) async {
    final userData = GetStorage().read('user_data');
    final userId = userData is Map ? userData['id'] : null;
    if (userId == null) {
      throw ApiException('The user information is unavailable.');
    }

    final response =
        await apiClient.postAuthenticatedData('api/todaymeal_toggle', {
      'meal_id': meal.id,
      'user_id': userId,
      'meal_date': meal.date,
      'meal_desc': meal.category,
    });
    return response['is_eaten'] == true || response['is_eaten'] == 1;
  }

  String _date(DateTime date) => date.toIso8601String().split('T').first;
}
