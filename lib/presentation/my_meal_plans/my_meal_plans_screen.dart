import 'package:flutter/material.dart';

import '../../data/api/api_client.dart';
import '../../data/repository/meal_plan_repo.dart';
import '../../model/meal_plan_model.dart';
import '../resources/index_manager.dart';

class MyMealsPlanView extends StatefulWidget {
  const MyMealsPlanView({super.key});

  @override
  State<MyMealsPlanView> createState() => _MyMealsPlanViewState();
}

class _MyMealsPlanViewState extends State<MyMealsPlanView> {
  final MealPlanRepo _repo = MealPlanRepo(apiClient: ApiClient());
  MealPlan? _plan;
  String? _error;
  int _selectedDay = 0;
  final Set<int> _updatingMeals = <int>{};

  @override
  void initState() {
    super.initState();
    _loadPlan();
  }

  Future<void> _loadPlan() async {
    setState(() => _error = null);
    try {
      final plan = await _repo.getMealPlan();
      if (!mounted) return;
      setState(() {
        _plan = plan;
        if (_selectedDay >= plan.days.length) _selectedDay = 0;
      });
    } on ApiException catch (error) {
      if (mounted) setState(() => _error = error.message);
    }
  }

  Future<void> _toggleMeal(MealPlanEntry meal) async {
    final today = DateTime.now().toIso8601String().split('T').first;
    if (meal.date != today) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
            content: Text('Meals can be tracked on their scheduled day.')),
      );
      return;
    }
    if (_updatingMeals.contains(meal.assignmentId)) return;
    setState(() => _updatingMeals.add(meal.assignmentId));
    try {
      final eaten = await _repo.toggleMeal(meal);
      if (!mounted || _plan == null) return;
      final days = _plan!.days.map((day) {
        if (day.date != meal.date) return day;
        return day.withMeals(day.meals
            .map((item) => item.assignmentId == meal.assignmentId
                ? item.withEaten(eaten)
                : item)
            .toList());
      }).toList();
      setState(() => _plan = MealPlan(profile: _plan!.profile, days: days));
    } on ApiException catch (error) {
      if (mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text(error.message)));
      }
    } finally {
      if (mounted) setState(() => _updatingMeals.remove(meal.assignmentId));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('My Meal Plans'),
        actions: [
          IconButton(onPressed: _loadPlan, icon: const Icon(Icons.refresh)),
        ],
      ),
      body: _plan == null
          ? (_error == null
              ? const Center(child: CircularProgressIndicator())
              : _ErrorState(message: _error!, onRetry: _loadPlan))
          : RefreshIndicator(
              onRefresh: _loadPlan,
              child: _buildPlan(_plan!),
            ),
    );
  }

  Widget _buildPlan(MealPlan plan) {
    if (plan.days.isEmpty) {
      return ListView(
        children: const [
          SizedBox(height: 180),
          Center(child: Text('Your personalized meal plan is not ready yet.')),
        ],
      );
    }
    final day = plan.days[_selectedDay];
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        _ProfileCard(profile: plan.profile),
        const SizedBox(height: 16),
        SizedBox(
          height: 74,
          child: ListView.separated(
            scrollDirection: Axis.horizontal,
            itemCount: plan.days.length,
            separatorBuilder: (_, __) => const SizedBox(width: 8),
            itemBuilder: (_, index) {
              final item = plan.days[index];
              final selected = index == _selectedDay;
              return InkWell(
                onTap: () => setState(() => _selectedDay = index),
                borderRadius: BorderRadius.circular(14),
                child: Container(
                  width: 74,
                  padding: const EdgeInsets.symmetric(vertical: 10),
                  decoration: BoxDecoration(
                    color: selected ? ColorManager.primary : Colors.white,
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(
                      color: selected
                          ? ColorManager.primary
                          : Colors.grey.shade300,
                    ),
                  ),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(item.dayName.substring(0, 3),
                          style: TextStyle(
                              color: selected ? Colors.white : Colors.black54)),
                      const SizedBox(height: 4),
                      Text(item.date.substring(8),
                          style: TextStyle(
                              fontWeight: FontWeight.bold,
                              color: selected ? Colors.white : Colors.black)),
                    ],
                  ),
                ),
              );
            },
          ),
        ),
        const SizedBox(height: 18),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(day.dayName,
                style:
                    const TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
            Text(
                '${day.eatenCalories.toStringAsFixed(0)} / '
                '${_number(plan.profile.calorieGoal).toStringAsFixed(0)} kcal',
                style: TextStyle(color: Colors.grey.shade700)),
          ],
        ),
        const SizedBox(height: 12),
        if (day.meals.isEmpty)
          const Card(
            child: Padding(
              padding: EdgeInsets.all(20),
              child: Text('No meals assigned for this day.'),
            ),
          )
        else
          ...day.meals.map(_mealCard),
      ],
    );
  }

  Widget _mealCard(MealPlanEntry meal) {
    final updating = _updatingMeals.contains(meal.assignmentId);
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: InkWell(
        onTap: () => _showMealDetails(meal),
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Row(
            children: [
              CircleAvatar(
                backgroundColor: ColorManager.primary.withOpacity(.12),
                child: Icon(_iconForCategory(meal.category),
                    color: ColorManager.primary),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(_label(meal.category),
                        style: TextStyle(
                            color: ColorManager.primary,
                            fontSize: 12,
                            fontWeight: FontWeight.bold)),
                    const SizedBox(height: 3),
                    Text(meal.title,
                        style: const TextStyle(
                            fontSize: 16, fontWeight: FontWeight.w600)),
                    const SizedBox(height: 4),
                    Text('${meal.calories} kcal • ${meal.protein} protein',
                        style: TextStyle(color: Colors.grey.shade700)),
                  ],
                ),
              ),
              updating
                  ? const SizedBox(
                      width: 24,
                      height: 24,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : IconButton(
                      tooltip:
                          meal.eaten ? 'Mark as not eaten' : 'Mark as eaten',
                      onPressed: () => _toggleMeal(meal),
                      icon: Icon(
                        meal.eaten
                            ? Icons.check_circle
                            : Icons.radio_button_unchecked,
                        color: meal.eaten ? Colors.green : Colors.grey,
                      ),
                    ),
            ],
          ),
        ),
      ),
    );
  }

  void _showMealDetails(MealPlanEntry meal) {
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      builder: (_) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Wrap(
            runSpacing: 10,
            children: [
              Text(meal.title,
                  style: const TextStyle(
                      fontSize: 22, fontWeight: FontWeight.bold)),
              Text(meal.description.isEmpty
                  ? 'Personalized for your ${meal.category} meal.'
                  : meal.description),
              _nutritionRow('Calories', '${meal.calories} kcal'),
              _nutritionRow('Protein', meal.protein),
              _nutritionRow('Carbohydrates', meal.carbs),
              _nutritionRow('Fat', meal.fat),
              if (meal.ingredients.isNotEmpty)
                Text('Ingredients: ${meal.ingredients}'),
              Text('Serving: ${meal.servings}'),
            ],
          ),
        ),
      ),
    );
  }

  Widget _nutritionRow(String label, String value) => Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label),
          Text(value, style: const TextStyle(fontWeight: FontWeight.bold))
        ],
      );

  String _label(String value) =>
      value.isEmpty ? 'Meal' : '${value[0].toUpperCase()}${value.substring(1)}';

  IconData _iconForCategory(String category) {
    switch (category.toLowerCase()) {
      case 'breakfast':
        return Icons.free_breakfast;
      case 'lunch':
        return Icons.lunch_dining;
      case 'dinner':
        return Icons.dinner_dining;
      default:
        return Icons.cookie;
    }
  }

  double _number(double? value) => value ?? 0;
}

class _ProfileCard extends StatelessWidget {
  final MealPlanProfile profile;

  const _ProfileCard({required this.profile});

  @override
  Widget build(BuildContext context) {
    final details = [
      if (profile.goal != null) profile.goal!,
      if (profile.dietaryPreference != null) profile.dietaryPreference!,
    ];
    return Card(
      color: ColorManager.primary.withOpacity(.08),
      elevation: 0,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Your personalized plan',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            if (details.isNotEmpty) ...[
              const SizedBox(height: 5),
              Text(details.join(' • ')),
            ],
            const SizedBox(height: 10),
            Text(
                'Daily target: ${profile.calorieGoal?.toStringAsFixed(0) ?? '-'} kcal'),
            Text(
                'Macros: P ${profile.proteinGoal?.toStringAsFixed(0) ?? '-'}g  '
                'C ${profile.carbsGoal?.toStringAsFixed(0) ?? '-'}g  '
                'F ${profile.fatGoal?.toStringAsFixed(0) ?? '-'}g'),
          ],
        ),
      ),
    );
  }
}

class _ErrorState extends StatelessWidget {
  final String message;
  final VoidCallback onRetry;

  const _ErrorState({required this.message, required this.onRetry});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(message, textAlign: TextAlign.center),
            const SizedBox(height: 12),
            ElevatedButton(onPressed: onRetry, child: const Text('Retry')),
          ],
        ),
      ),
    );
  }
}
