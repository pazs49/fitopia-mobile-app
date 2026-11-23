import 'dart:async';

import 'package:flutter/material.dart';

import '../../data/api/api_client.dart';
import '../../data/repository/recipe_repo.dart';
import '../../model/recipe_model.dart';
import '../resources/index_manager.dart';

class ReceipeListView extends StatefulWidget {
  const ReceipeListView({super.key});

  @override
  State<ReceipeListView> createState() => _ReceipeListViewState();
}

class _ReceipeListViewState extends State<ReceipeListView> {
  final RecipeRepo _repo = RecipeRepo(apiClient: ApiClient());
  final TextEditingController _searchController = TextEditingController();
  late Future<List<Recipe>> _recipesFuture;
  late Future<List<RecipeCategory>> _categoriesFuture;
  Timer? _searchDebounce;
  String? _mealCategory;
  int? _dietaryCategoryId;

  @override
  void initState() {
    super.initState();
    _recipesFuture = _loadRecipes();
    _categoriesFuture = _repo.getCategories();
  }

  @override
  void dispose() {
    _searchDebounce?.cancel();
    _searchController.dispose();
    super.dispose();
  }

  Future<List<Recipe>> _loadRecipes() {
    return _repo.getRecipes(
      search: _searchController.text,
      categoryId: _dietaryCategoryId,
      mealCategory: _mealCategory,
    );
  }

  void _applyFilters() {
    setState(() => _recipesFuture = _loadRecipes());
  }

  Future<void> _refresh() async {
    final recipes = _loadRecipes();
    final categories = _repo.getCategories();
    setState(() {
      _recipesFuture = recipes;
      _categoriesFuture = categories;
    });
    await recipes;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Recipe List'),
        actions: [
          IconButton(onPressed: _refresh, icon: const Icon(Icons.refresh)),
        ],
      ),
      body: Column(
        children: [
          _buildFilters(),
          Expanded(
            child: FutureBuilder<List<Recipe>>(
              future: _recipesFuture,
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }
                if (snapshot.hasError) {
                  return _MessageState(
                    message: snapshot.error.toString(),
                    actionLabel: 'Retry',
                    onAction: _refresh,
                  );
                }

                final recipes = snapshot.data ?? const <Recipe>[];
                if (recipes.isEmpty) {
                  return _MessageState(
                    message: 'No recipes match your filters.',
                    actionLabel: 'Clear filters',
                    onAction: () async {
                      _searchController.clear();
                      setState(() {
                        _mealCategory = null;
                        _dietaryCategoryId = null;
                        _recipesFuture = _loadRecipes();
                      });
                    },
                  );
                }

                return RefreshIndicator(
                  onRefresh: _refresh,
                  child: GridView.builder(
                    padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
                    itemCount: recipes.length,
                    gridDelegate:
                        const SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: 2,
                      crossAxisSpacing: 12,
                      mainAxisSpacing: 12,
                      childAspectRatio: .70,
                    ),
                    itemBuilder: (_, index) => _recipeCard(recipes[index]),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFilters() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 4),
      child: Column(
        children: [
          TextField(
            controller: _searchController,
            textInputAction: TextInputAction.search,
            onSubmitted: (_) => _applyFilters(),
            onChanged: (_) {
              _searchDebounce?.cancel();
              _searchDebounce = Timer(
                const Duration(milliseconds: 450),
                _applyFilters,
              );
            },
            decoration: InputDecoration(
              hintText: 'Search recipes',
              prefixIcon: const Icon(Icons.search),
              suffixIcon: _searchController.text.isEmpty
                  ? null
                  : IconButton(
                      onPressed: () {
                        _searchController.clear();
                        _applyFilters();
                      },
                      icon: const Icon(Icons.clear),
                    ),
              border:
                  OutlineInputBorder(borderRadius: BorderRadius.circular(14)),
            ),
          ),
          const SizedBox(height: 8),
          SizedBox(
            height: 38,
            child: ListView(
              scrollDirection: Axis.horizontal,
              children: [
                _filterChip('All meals', _mealCategory == null,
                    () => _selectMealCategory(null)),
                _filterChip('Breakfast', _mealCategory == 'breakfast',
                    () => _selectMealCategory('breakfast')),
                _filterChip('Lunch', _mealCategory == 'lunch',
                    () => _selectMealCategory('lunch')),
                _filterChip('Dinner', _mealCategory == 'dinner',
                    () => _selectMealCategory('dinner')),
                _filterChip('Snacks', _mealCategory == 'snacks',
                    () => _selectMealCategory('snacks')),
              ],
            ),
          ),
          const SizedBox(height: 4),
          SizedBox(
            height: 38,
            child: FutureBuilder<List<RecipeCategory>>(
              future: _categoriesFuture,
              builder: (_, snapshot) {
                final categories = snapshot.data ?? const <RecipeCategory>[];
                return ListView(
                  scrollDirection: Axis.horizontal,
                  children: [
                    _filterChip(
                      'All dietary types',
                      _dietaryCategoryId == null,
                      () => _selectDietaryCategory(null),
                    ),
                    ...categories.map(
                      (category) => _filterChip(
                        category.title,
                        _dietaryCategoryId == category.id,
                        () => _selectDietaryCategory(category.id),
                      ),
                    ),
                  ],
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _filterChip(String label, bool selected, VoidCallback onTap) {
    return Padding(
      padding: const EdgeInsets.only(right: 8),
      child: ChoiceChip(
        label: Text(label),
        selected: selected,
        onSelected: (_) => onTap(),
        selectedColor: ColorManager.primary,
        labelStyle: TextStyle(color: selected ? Colors.white : Colors.black87),
      ),
    );
  }

  void _selectMealCategory(String? value) {
    setState(() {
      _mealCategory = value;
      _recipesFuture = _loadRecipes();
    });
  }

  void _selectDietaryCategory(int? value) {
    setState(() {
      _dietaryCategoryId = value;
      _recipesFuture = _loadRecipes();
    });
  }

  Widget _recipeCard(Recipe recipe) {
    return Card(
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: () => _showRecipeDetails(recipe),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(child: _recipeImage(recipe)),
            Padding(
              padding: const EdgeInsets.fromLTRB(10, 8, 6, 8),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(recipe.title,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(fontWeight: FontWeight.bold)),
                  const SizedBox(height: 4),
                  Text('${recipe.calories} kcal • ${recipe.protein} protein',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style:
                          TextStyle(color: Colors.grey.shade700, fontSize: 12)),
                  Row(
                    children: [
                      Expanded(
                        child: Text(recipe.totalTime.isEmpty
                            ? 'View recipe'
                            : recipe.totalTime),
                      ),
                      IconButton(
                        padding: EdgeInsets.zero,
                        constraints: const BoxConstraints(),
                        onPressed: () => _toggleFavourite(recipe),
                        icon: Icon(
                          recipe.favourite
                              ? Icons.favorite
                              : Icons.favorite_border,
                          size: 20,
                          color: recipe.favourite
                              ? Colors.red
                              : Colors.grey.shade600,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _recipeImage(Recipe recipe) {
    if (recipe.image.isEmpty) {
      return _placeholderImage();
    }
    return Image.network(
      _imageUrl(recipe.image),
      fit: BoxFit.cover,
      width: double.infinity,
      errorBuilder: (_, __, ___) => _placeholderImage(),
    );
  }

  String _imageUrl(String value) {
    final uri = Uri.tryParse(value);
    if (uri == null) return _defaultImageUrl();

    final base = Uri.parse(AppStrings.appBaseUrl);
    if (uri.host == '127.0.0.1' || uri.host == 'localhost') {
      return uri
          .replace(
            scheme: base.scheme,
            host: base.host,
            port: base.hasPort ? base.port : null,
          )
          .toString();
    }
    return uri.hasScheme ? value : base.resolve(value).toString();
  }

  String _defaultImageUrl() =>
      Uri.parse(AppStrings.appBaseUrl).resolve('images/default.png').toString();

  Widget _placeholderImage() {
    return Image.network(
      _defaultImageUrl(),
      fit: BoxFit.cover,
      width: double.infinity,
      errorBuilder: (_, __, ___) => Container(
        color: Colors.grey.shade100,
        child: Center(
          child: Icon(Icons.image_not_supported_outlined,
              size: 42, color: Colors.grey.shade400),
        ),
      ),
    );
  }

  Future<void> _toggleFavourite(Recipe recipe) async {
    try {
      final favourite = await _repo.toggleFavourite(recipe);
      if (!mounted) return;
      setState(() {
        _recipesFuture = _recipesFuture.then((recipes) => recipes
            .map((item) =>
                item.id == recipe.id ? item.withFavourite(favourite) : item)
            .toList());
      });
    } on ApiException catch (error) {
      if (mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text(error.message)));
      }
    }
  }

  Future<void> _showRecipeDetails(Recipe recipe) async {
    RecipeDetail detail;
    try {
      detail = await _repo.getDetail(recipe.id);
    } on ApiException catch (error) {
      if (mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text(error.message)));
      }
      return;
    }
    if (!mounted) return;

    var selectedCategory = _mealCategory ?? 'breakfast';
    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      builder: (_) => StatefulBuilder(
        builder: (context, setSheetState) => SafeArea(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(detail.recipe.title,
                    style: const TextStyle(
                        fontSize: 22, fontWeight: FontWeight.bold)),
                const SizedBox(height: 8),
                Text(detail.recipe.description.isEmpty
                    ? 'Personalized recipe from the Fitopia library.'
                    : detail.recipe.description),
                const SizedBox(height: 14),
                _nutritionLine('Calories', '${detail.recipe.calories} kcal'),
                _nutritionLine('Protein', detail.recipe.protein),
                _nutritionLine('Carbohydrates', detail.recipe.carbs),
                _nutritionLine('Fat', detail.recipe.fat),
                _nutritionLine('Servings', detail.recipe.servings),
                if (detail.recipe.totalTime.isNotEmpty)
                  _nutritionLine('Preparation time', detail.recipe.totalTime),
                if (detail.recipe.ingredients.isNotEmpty) ...[
                  const SizedBox(height: 12),
                  const Text('Ingredients',
                      style: TextStyle(fontWeight: FontWeight.bold)),
                  const SizedBox(height: 4),
                  Text(detail.recipe.ingredients),
                ],
                const SizedBox(height: 18),
                const Text('Add to today’s meal plan',
                    style: TextStyle(fontWeight: FontWeight.bold)),
                DropdownButton<String>(
                  value: selectedCategory,
                  isExpanded: true,
                  items: const [
                    DropdownMenuItem(
                        value: 'breakfast', child: Text('Breakfast')),
                    DropdownMenuItem(value: 'lunch', child: Text('Lunch')),
                    DropdownMenuItem(value: 'dinner', child: Text('Dinner')),
                    DropdownMenuItem(value: 'snacks', child: Text('Snacks')),
                  ],
                  onChanged: (value) {
                    if (value != null) {
                      setSheetState(() => selectedCategory = value);
                    }
                  },
                ),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton.icon(
                    onPressed: () async {
                      try {
                        await _repo.addToMealPlan(
                          recipe: detail.recipe,
                          category: selectedCategory,
                        );
                        if (context.mounted) {
                          Navigator.pop(context);
                          ScaffoldMessenger.of(this.context).showSnackBar(
                            const SnackBar(
                                content:
                                    Text('Recipe added to today’s meal plan.')),
                          );
                        }
                      } on ApiException catch (error) {
                        if (context.mounted) {
                          ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(content: Text(error.message)));
                        }
                      }
                    },
                    icon: const Icon(Icons.add),
                    label: const Text('Add to meal plan'),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _nutritionLine(String label, String value) => Padding(
        padding: const EdgeInsets.only(bottom: 5),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(label),
            Text(value, style: const TextStyle(fontWeight: FontWeight.bold)),
          ],
        ),
      );
}

class _MessageState extends StatelessWidget {
  final String message;
  final String actionLabel;
  final Future<void> Function() onAction;

  const _MessageState({
    required this.message,
    required this.actionLabel,
    required this.onAction,
  });

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(message, textAlign: TextAlign.center),
            const SizedBox(height: 12),
            TextButton(onPressed: onAction, child: Text(actionLabel)),
          ],
        ),
      ),
    );
  }
}
