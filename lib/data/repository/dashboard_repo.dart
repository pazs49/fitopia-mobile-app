import 'package:fitopia/data/api/api_client.dart';
import 'package:fitopia/model/dashboard_content_model.dart';
import 'package:fitopia/model/dashboard_nutrition_model.dart';
import 'package:get_storage/get_storage.dart';

class DashboardRepo {
  final ApiClient apiClient;

  DashboardRepo({required this.apiClient});

  Future<DashboardCalories> getTodayCalories() async {
    final response = await apiClient.getData('api/gettodayCaloriesData');
    final error = response['error'];
    if (error is String && error.isNotEmpty) {
      throw ApiException(error);
    }

    return DashboardCalories.fromJson(response);
  }

  Future<List<DashboardMacro>> getTodayMacros() async {
    final response = await apiClient.getData('api/gettodayMacrosData');
    final error = response['error'];
    if (error is String && error.isNotEmpty) {
      throw ApiException(error);
    }

    final rawMacros = response['data'];
    if (rawMacros is! List) {
      throw ApiException('The macros response was invalid.');
    }

    return rawMacros
        .whereType<Map>()
        .map((macro) =>
            DashboardMacro.fromJson(Map<String, dynamic>.from(macro)))
        .toList();
  }

  Future<DashboardWeeklyCalories> getWeeklyCalories() async {
    final response = await apiClient.getData('api/getWeeklyCaloriesData');
    final error = response['error'];
    if (error is String && error.isNotEmpty) {
      throw ApiException(error);
    }

    return DashboardWeeklyCalories.fromJson(response);
  }

  Future<void> logMeal(DashboardMeal meal) async {
    final userData = GetStorage().read('user_data');
    final userId = userData is Map ? userData['id'] : null;
    if (userId == null || meal.id == 0) {
      throw ApiException('The meal or user information is unavailable.');
    }

    await apiClient.postAuthenticatedData('api/todaymeal_create', {
      'meal_id': meal.id,
      'user_id': userId,
      'meal_date': DateTime.now().toIso8601String().split('T').first,
      'meal_desc': meal.category.toLowerCase(),
    });
  }

  Future<Set<int>> getLoggedMealIds(DateTime date) async {
    final dateText = date.toIso8601String().split('T').first;
    final response =
        await apiClient.getData('api/todaymeal_view?date=$dateText');
    final data = response['data'];
    if (data is! List) {
      throw ApiException('The logged meals response was invalid.');
    }

    return data
        .whereType<Map>()
        .map((item) => int.tryParse(item['id']?.toString() ?? ''))
        .whereType<int>()
        .toSet();
  }

  Future<DashboardNutrition> getNutrition() async {
    final results = await Future.wait<dynamic>([
      getTodayCalories(),
      getTodayMacros(),
    ]);

    return DashboardNutrition(
      calories: results[0] as DashboardCalories,
      macros: results[1] as List<DashboardMacro>,
    );
  }

  Future<DashboardContent> getContent({DateTime? selectedDate}) async {
    final dateText = selectedDate?.toIso8601String().split('T').first;
    final responses = await Future.wait<Map<String, dynamic>>([
      apiClient.getData('api/dashboard-detail'),
      apiClient.getData(
        dateText == null
            ? 'api/assign-diet-list'
            : 'api/assign-diet-list?date=$dateText',
      ),
      apiClient.getData('api/assign-workout-list'),
    ]);

    final dashboardData = _mapData(responses[0]);
    final rawWorkout = dashboardData['todays_workout'];
    DashboardWorkout? workout;
    if (rawWorkout is Map) {
      final workoutData = rawWorkout['workout'];
      if (workoutData is Map) {
        workout =
            DashboardWorkout.fromJson(Map<String, dynamic>.from(workoutData));
      }
    }

    if (workout == null) {
      final assignedWorkouts = _listData(responses[2]);
      final workoutItems = assignedWorkouts
          .whereType<Map>()
          .map((item) =>
              DashboardWorkout.fromJson(Map<String, dynamic>.from(item)))
          .toList();
      if (workoutItems.isNotEmpty) {
        workout = workoutItems.first;
      }
    }

    final dietsData = _listData(responses[1]);
    final meals = dietsData
        .whereType<Map>()
        .map((diet) => DashboardMeal.fromJson(Map<String, dynamic>.from(diet)))
        .where((meal) => dateText == null || meal.assignedDate == dateText)
        .toList();

    return DashboardContent(workout: workout, meals: meals);
  }

  Map<String, dynamic> _mapData(Map<String, dynamic> response) {
    final data = response['data'];
    if (data is Map) {
      return Map<String, dynamic>.from(data);
    }

    return response;
  }

  List<dynamic> _listData(Map<String, dynamic> response) {
    final data = response['data'];
    if (data is List) {
      return data;
    }

    throw ApiException('The Dashboard list response was invalid.');
  }
}

class DashboardNutrition {
  final DashboardCalories calories;
  final List<DashboardMacro> macros;

  const DashboardNutrition({
    required this.calories,
    required this.macros,
  });

  DashboardMacro? macro(String name) {
    for (final item in macros) {
      if (item.name.toLowerCase() == name.toLowerCase()) {
        return item;
      }
    }

    return null;
  }
}

class DashboardContent {
  final DashboardWorkout? workout;
  final List<DashboardMeal> meals;

  const DashboardContent({
    required this.workout,
    required this.meals,
  });
}
