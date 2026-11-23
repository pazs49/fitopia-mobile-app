class RecipeCategory {
  final int id;
  final String title;

  const RecipeCategory({required this.id, required this.title});

  factory RecipeCategory.fromJson(Map<String, dynamic> json) {
    return RecipeCategory(
      id: int.tryParse(json['id']?.toString() ?? '') ?? 0,
      title: json['title']?.toString() ?? 'Other',
    );
  }
}

class Recipe {
  final int id;
  final String title;
  final String description;
  final String ingredients;
  final String image;
  final String calories;
  final String protein;
  final String carbs;
  final String fat;
  final String servings;
  final String totalTime;
  final String dietaryCategory;
  final bool favourite;

  const Recipe({
    required this.id,
    required this.title,
    required this.description,
    required this.ingredients,
    required this.image,
    required this.calories,
    required this.protein,
    required this.carbs,
    required this.fat,
    required this.servings,
    required this.totalTime,
    required this.dietaryCategory,
    required this.favourite,
  });

  factory Recipe.fromJson(Map<String, dynamic> json) {
    return Recipe(
      id: _int(json['id']),
      title: _text(json['title'], 'Recipe'),
      description: _text(json['description']),
      ingredients: _text(json['ingredients']),
      image: _text(json['diet_image']),
      calories: _text(json['calories'], '0'),
      protein: _text(json['protein'], '0'),
      carbs: _text(json['carbs'], '0'),
      fat: _text(json['fat'], '0'),
      servings: _text(json['servings'], '1'),
      totalTime: _text(json['total_time']),
      dietaryCategory: _text(json['categorydiet_title'], 'General'),
      favourite: json['is_favourite'] == true ||
          json['is_favourite'] == 1 ||
          json['is_favourite']?.toString() == '1',
    );
  }

  Recipe withFavourite(bool value) {
    return Recipe(
      id: id,
      title: title,
      description: description,
      ingredients: ingredients,
      image: image,
      calories: calories,
      protein: protein,
      carbs: carbs,
      fat: fat,
      servings: servings,
      totalTime: totalTime,
      dietaryCategory: dietaryCategory,
      favourite: value,
    );
  }
}

class RecipeDetail {
  final Recipe recipe;
  final Map<String, dynamic> goalPercentages;

  const RecipeDetail({required this.recipe, required this.goalPercentages});

  factory RecipeDetail.fromJson(Map<String, dynamic> json) {
    return RecipeDetail(
      recipe: Recipe.fromJson(json),
      goalPercentages: json['daily_goal_percentages'] is Map
          ? Map<String, dynamic>.from(json['daily_goal_percentages'] as Map)
          : const {},
    );
  }
}

String _text(dynamic value, [String fallback = '']) {
  final text = value?.toString().trim() ?? '';
  return text.isEmpty ? fallback : text;
}

int _int(dynamic value) => int.tryParse(value?.toString() ?? '') ?? 0;
