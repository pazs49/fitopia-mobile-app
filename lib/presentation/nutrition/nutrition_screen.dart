import 'package:fitopia/data/api/api_client.dart';
import 'package:fitopia/data/repository/dashboard_repo.dart';
import 'package:fitopia/model/dashboard_nutrition_model.dart';
import 'package:flutter/material.dart';

import '../resources/index_manager.dart';

class NutritionView extends StatefulWidget {
  const NutritionView({super.key});

  @override
  State<NutritionView> createState() => _NutritionViewState();
}

class _NutritionViewState extends State<NutritionView> {
  final DashboardRepo _repo = DashboardRepo(apiClient: ApiClient());
  DashboardNutrition? _nutrition;
  DashboardWeeklyCalories? _weeklyCalories;
  WaterIntakeSummary? _water;
  String? _error;
  bool _isLoading = true;
  bool _isAddingWater = false;

  @override
  void initState() {
    super.initState();
    _loadNutrition();
  }

  Future<void> _loadNutrition() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      final nutrition = await _repo.getNutrition();
      final weeklyCalories = await _loadWeeklyCalories();
      final water = await _loadWater();
      if (!mounted) {
        return;
      }

      setState(() {
        _nutrition = nutrition;
        _weeklyCalories = weeklyCalories;
        _water = water;
        _isLoading = false;
      });
    } on ApiException catch (error) {
      if (!mounted) {
        return;
      }
      setState(() {
        _isLoading = false;
        _error = error.message;
      });
    }
  }

  Future<DashboardWeeklyCalories?> _loadWeeklyCalories() async {
    try {
      return await _repo.getWeeklyCalories();
    } on ApiException {
      return null;
    }
  }

  Future<WaterIntakeSummary?> _loadWater() async {
    try {
      return await _repo.getWaterToday();
    } on ApiException {
      return null;
    }
  }

  Future<void> _addWater(int milliliters) async {
    if (_isAddingWater) {
      return;
    }

    setState(() => _isAddingWater = true);
    try {
      final water = await _repo.addWater(milliliters: milliliters);
      if (!mounted) {
        return;
      }
      setState(() => _water = water);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('$milliliters ml of water added.'),
          action: SnackBarAction(
            label: 'Undo',
            onPressed: _undoLatestWater,
          ),
        ),
      );
    } on ApiException catch (error) {
      if (mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text(error.message)));
      }

    } finally {
      if (mounted) {
        setState(() => _isAddingWater = false);
      }
    }

  }

  Future<void> _undoLatestWater() async {
    if (_isAddingWater) {
      return;
    }

    setState(() => _isAddingWater = true);
    try {
      final water = await _repo.undoLatestWater();
      if (!mounted) {
        return;
      }
      setState(() => _water = water);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Latest water entry removed.')),
      );
    } on ApiException catch (error) {
      if (mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text(error.message)));
      }
    } finally {
      if (mounted) {
        setState(() => _isAddingWater = false);
      }
    }
  }

  Future<void> _showCustomWaterDialog() async {
    final controller = TextEditingController();
    final milliliters = await showDialog<int>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Add custom water amount'),
        content: TextField(
          controller: controller,
          autofocus: true,
          keyboardType: TextInputType.number,
          decoration: const InputDecoration(
            labelText: 'Milliliters',
            suffixText: 'ml',
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              final value = int.tryParse(controller.text.trim());
              if (value == null || value < 1) {
                return;
              }
              Navigator.pop(dialogContext, value);
            },
            child: const Text('Add'),
          ),
        ],
      ),
    );
    if (milliliters != null && mounted) {
      await _addWater(milliliters);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Nutrition'),
        actions: [
          IconButton(
            onPressed: _isLoading ? null : _loadNutrition,
            icon: const Icon(Icons.refresh),
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _error != null
              ? _errorState()
              : RefreshIndicator(
                  onRefresh: _loadNutrition,
                  child: _content(),
                ),
    );
  }

  Widget _content() {
    final nutrition = _nutrition!;
    final calories = nutrition.calories;
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        const Text(
          "Today's nutrition",
          style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 12),
        _calorieCard(calories),
        const SizedBox(height: 16),
        const Text(
          'Macros',
          style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 8),
        ...nutrition.macros.map(_macroCard),
        const SizedBox(height: 16),
        if (_weeklyCalories != null) _weeklyCard(_weeklyCalories!),
        if (_water != null) ...[
          const SizedBox(height: 16),
          _waterCard(_water!),
        ],
      ],
    );
  }

  Widget _calorieCard(DashboardCalories calories) {
    final progress =
        calories.goal <= 0 ? 0.0 : (calories.dailyAverage / calories.goal).clamp(0.0, 1.0);
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text('Calories consumed'),
                Text(
                  '${calories.dailyAverage.toStringAsFixed(0)} / '
                  '${calories.goal.toStringAsFixed(0)} kcal',
                  style: const TextStyle(fontWeight: FontWeight.bold),
                ),
              ],
            ),
            const SizedBox(height: 12),
            LinearProgressIndicator(
              value: progress,
              minHeight: 10,
              color: ColorManager.primary,
              backgroundColor: ColorManager.primary.withOpacity(.12),
            ),
            const SizedBox(height: 10),
            Text(
              calories.remaining > 0
                  ? '${calories.remaining.toStringAsFixed(0)} kcal remaining'
                  : 'Daily calorie goal reached',
              style: TextStyle(color: Colors.grey.shade700),
            ),
          ],
        ),
      ),
    );
  }

  Widget _macroCard(DashboardMacro macro) {
    final progress =
        macro.goal <= 0 ? 0.0 : (macro.amount / macro.goal).clamp(0.0, 1.0);
    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(macro.name),
                Text(
                  '${macro.amount.toStringAsFixed(0)} / '
                  '${macro.goal.toStringAsFixed(0)} g',
                  style: const TextStyle(fontWeight: FontWeight.bold),
                ),
              ],
            ),
            const SizedBox(height: 8),
            LinearProgressIndicator(
              value: progress,
              color: ColorManager.secondryTwo,
              backgroundColor: ColorManager.secondryTwo.withOpacity(.12),
            ),
          ],
        ),
      ),
    );
  }

  Widget _weeklyCard(DashboardWeeklyCalories weekly) {
    final maxValue = weekly.values.fold<double>(
      0,
      (max, value) => value > max ? value : max,
    );
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'This week',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            SizedBox(
              height: 150,
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: List.generate(weekly.values.length, (index) {
                  final value = weekly.values[index];
                  final height =
                      maxValue == 0 ? 4.0 : (value / maxValue) * 110;
                  return Expanded(
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 4),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.end,
                        children: [
                          Text(
                            value.toStringAsFixed(0),
                            style: const TextStyle(fontSize: 10),
                          ),
                          const SizedBox(height: 4),
                          Container(
                            height: height,
                            decoration: BoxDecoration(
                              color: ColorManager.primary,
                              borderRadius: BorderRadius.circular(5),
                            ),
                          ),
                          const SizedBox(height: 6),
                          Text(
                            weekly.labels[index],
                            style: const TextStyle(fontSize: 10),
                          ),
                        ],
                      ),
                    ),
                  );
                }),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _waterCard(WaterIntakeSummary water) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.water_drop, color: Colors.blue.shade400, size: 32),
                const SizedBox(width: 12),
                Text(
                  'Hydration',
                  style: const TextStyle(fontWeight: FontWeight.bold),
                ),
                const Spacer(),
                Text('${water.totalMl} ml today'),
              ],
            ),
            const SizedBox(height: 14),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                for (final amount in const [150, 250, 330, 500, 750])
                  OutlinedButton(
                    onPressed:
                        _isAddingWater ? null : () => _addWater(amount),
                    child: Text('$amount ml'),
                  ),
                OutlinedButton(
                  onPressed: _isAddingWater ? null : _showCustomWaterDialog,
                  child: const Text('Custom'),
                ),
              ],
            ),
            if (_isAddingWater) ...[
              const SizedBox(height: 12),
              const LinearProgressIndicator(),
            ],
          ],
        ),
      ),
    );
  }

  Widget _errorState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(_error!, textAlign: TextAlign.center),
            const SizedBox(height: 12),
            ElevatedButton(
              onPressed: _loadNutrition,
              child: const Text('Retry'),
            ),
          ],
        ),
      ),
    );
  }
}
