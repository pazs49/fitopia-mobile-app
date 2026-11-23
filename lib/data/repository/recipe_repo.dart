import 'package:fitopia/data/api/api_client.dart';
import 'package:fitopia/model/recipe_model.dart';

class RecipeRepo {
  final ApiClient apiClient;

  RecipeRepo({required this.apiClient});

  Future<List<Recipe>> getRecipes({
    String search = '',
    int? categoryId,
    String? mealCategory,
  }) async {
    final params = <String, String>{
      'per_page': '-1',
      'recommended': '1',
    };
    if (search.trim().isNotEmpty) params['title'] = search.trim();
    if (categoryId != null) params['categorydiet_id'] = categoryId.toString();
    if (mealCategory != null) params['meal_category'] = mealCategory;

    final response = await apiClient.getData('api/diet-list?${_query(params)}');
    final rawData = response['data'];
    if (rawData is! List) {
      throw ApiException('The recipes response was invalid.');
    }

    return rawData
        .whereType<Map>()
        .map((item) => Recipe.fromJson(Map<String, dynamic>.from(item)))
        .where((recipe) => recipe.id > 0)
        .toList();
  }

  Future<List<RecipeCategory>> getCategories() async {
    final response =
        await apiClient.getData('api/categorydiet-list?per_page=-1');
    final rawData = response['data'];
    if (rawData is! List) {
      throw ApiException('The recipe categories response was invalid.');
    }
    return rawData
        .whereType<Map>()
        .map((item) => RecipeCategory.fromJson(Map<String, dynamic>.from(item)))
        .where((category) => category.id > 0)
        .toList();
  }

  Future<RecipeDetail> getDetail(int recipeId) async {
    final response = await apiClient.postAuthenticatedData(
      'api/diet-detail',
      {'id': recipeId},
    );
    final rawData = response['data'];
    if (rawData is! Map) {
      throw ApiException('The recipe detail response was invalid.');
    }
    return RecipeDetail.fromJson(Map<String, dynamic>.from(rawData));
  }

  Future<bool> toggleFavourite(Recipe recipe) async {
    await apiClient.postAuthenticatedData(
      'api/set-favourite-diet',
      {'diet_id': recipe.id},
    );
    return !recipe.favourite;
  }

  Future<void> addToMealPlan({
    required Recipe recipe,
    required String category,
    required DateTime date,
  }) async {
    await apiClient.postAuthenticatedData('api/meal-plans/add', {
      'diet_id': recipe.id,
      'meal_category': category,
      'assign_date': date.toIso8601String().split('T').first,
    });
  }

  String _query(Map<String, String> values) => values.entries
      .map((entry) =>
          '${Uri.encodeQueryComponent(entry.key)}=${Uri.encodeQueryComponent(entry.value)}')
      .join('&');
}
