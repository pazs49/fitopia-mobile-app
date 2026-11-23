import 'package:fitopia/data/api/api_client.dart';
import 'package:fitopia/model/dashboard_content_model.dart';
import 'package:fitopia/model/dashboard_nutrition_model.dart';
import 'package:fitopia/model/workout_detail_model.dart';
import 'package:get_storage/get_storage.dart';

class DashboardRepo {
  final ApiClient apiClient;

  DashboardRepo({required this.apiClient});

  Future<DashboardCalories> getTodayCalories() async {
    final date = DateTime.now().toIso8601String().split('T').first;
    final response =
        await apiClient.getData('api/gettodayCaloriesData?date=$date');
    final error = response['error'];
    if (error is String && error.isNotEmpty) {
      throw ApiException(error);
    }

    return DashboardCalories.fromJson(response);
  }

  Future<List<DashboardMacro>> getTodayMacros() async {
    final date = DateTime.now().toIso8601String().split('T').first;
    final response =
        await apiClient.getData('api/gettodayMacrosData?date=$date');
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

  Future<void> toggleMeal(DashboardMeal meal) async {
    final userData = GetStorage().read('user_data');
    final userId = userData is Map ? userData['id'] : null;
    if (userId == null || meal.id == 0) {
      throw ApiException('The meal or user information is unavailable.');
    }

    await apiClient.postAuthenticatedData('api/todaymeal_toggle', {
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
        .where((item) => item['is_eaten'] == true || item['is_eaten'] == 1)
        .map((item) => int.tryParse(item['id']?.toString() ?? ''))
        .whereType<int>()
        .toSet();
  }

  Future<void> completeWorkout(DashboardWorkout workout) async {
    final assignmentId = workout.assignmentId;
    if (assignmentId == null) {
      throw ApiException('The workout assignment information is unavailable.');
    }

    await apiClient.postAuthenticatedData('api/ai-workouts/mark-completed', {
      'workout_assignment_id': assignmentId,
    });
  }

  Future<void> toggleWorkout(DashboardWorkout workout) async {
    final assignmentId = workout.assignmentId;
    if (assignmentId == null) {
      throw ApiException('The workout assignment information is unavailable.');
    }

    await apiClient.postAuthenticatedData(
      workout.completed
          ? 'api/ai-workouts/unmark-completed'
          : 'api/ai-workouts/mark-completed',
      {'workout_assignment_id': assignmentId},
    );
  }

  Future<WorkoutDetail> getWorkoutDetail(int workoutId) async {
    final response =
        await apiClient.getData('api/workout-detail?id=$workoutId');
    final rawData = response['data'];
    if (rawData is! Map) {
      throw ApiException('The workout detail response was invalid.');
    }

    final data = Map<String, dynamic>.from(rawData);
    if (data['exercises'] is! List) {
      data['exercises'] = const <dynamic>[];
    }
    return WorkoutDetail.fromJson(data);
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
    final todayText = DateTime.now().toIso8601String().split('T').first;
    final isToday = dateText == null || dateText == todayText;
    final dietResponse = apiClient.getData(
      'api/assign-diet-list?date=${dateText ?? todayText}',
    );
    final responses = isToday
        ? await Future.wait<Map<String, dynamic>>([
            apiClient.getData('api/dashboard-detail'),
            dietResponse,
          ])
        : await Future.wait<Map<String, dynamic>>([dietResponse]);

    final dashboardData =
        isToday ? _mapData(responses[0]) : <String, dynamic>{};
    final rawWorkout = isToday ? dashboardData['todays_workout'] : null;
    DashboardWorkout? workout;
    if (rawWorkout is Map) {
      final workoutData = rawWorkout['workout'];
      if (workoutData is Map) {
        final workoutJson = Map<String, dynamic>.from(workoutData);
        workoutJson['assignment_id'] = rawWorkout['id'];
        workoutJson['status'] = rawWorkout['status'];
        workoutJson['completed_at'] = rawWorkout['completed_at'];
        workout = DashboardWorkout.fromJson(workoutJson);
      }
    }

    if (workout == null && isToday) {
      final todayWorkoutResponse =
          await apiClient.getData('api/ai-workouts/today');
      final todayWorkoutData = todayWorkoutResponse['data'];
      if (todayWorkoutData is Map) {
        final workoutData = todayWorkoutData['workout'];
        if (workoutData is Map) {
          final workoutJson = Map<String, dynamic>.from(workoutData);
          workoutJson['assignment_id'] = todayWorkoutData['id'];
          workoutJson['status'] = todayWorkoutData['status'];
          workoutJson['completed_at'] = todayWorkoutData['completed_at'];
          workout = DashboardWorkout.fromJson(workoutJson);
        }
      }
    }

    if (workout == null && dateText != null) {
      final rangeResponse = await apiClient.getData(
        'api/ai-workouts/date-range?start_date=$dateText&end_date=$dateText',
      );
      final rangeData = rangeResponse['data'];
      if (rangeData is List && rangeData.isNotEmpty) {
        final assignment = rangeData.first;
        if (assignment is Map && assignment['workout'] is Map) {
          final workoutJson =
              Map<String, dynamic>.from(assignment['workout'] as Map);
          workoutJson['assignment_id'] = assignment['id'];
          workoutJson['status'] = assignment['status'];
          workoutJson['completed_at'] = assignment['completed_at'];
          workout = DashboardWorkout.fromJson(workoutJson);
        }
      }
    }

    final dietsData = _listData(responses[isToday ? 1 : 0]);
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
