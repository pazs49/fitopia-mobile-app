import 'package:flutter/material.dart';
import 'package:fitopia/data/api/api_client.dart';
import 'package:fitopia/data/repository/dashboard_repo.dart';
import 'package:fitopia/model/dashboard_content_model.dart';
import 'package:fitopia/model/workout_detail_model.dart';
import 'package:fitopia/presentation/resources/strings_manager.dart';

class WorkoutDetailScreen extends StatefulWidget {
  final DashboardWorkout workout;

  const WorkoutDetailScreen({super.key, required this.workout});

  @override
  State<WorkoutDetailScreen> createState() => _WorkoutDetailScreenState();
}

class _WorkoutDetailScreenState extends State<WorkoutDetailScreen> {
  final DashboardRepo _repository = DashboardRepo(apiClient: ApiClient());
  WorkoutDetail? _detail;
  String? _error;
  bool _loading = true;
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    _loadDetail();
  }

  Future<void> _loadDetail() async {
    final id = widget.workout.workoutId;
    if (id == null) {
      setState(() {
        _loading = false;
        _error = 'This workout does not have a valid id.';
      });
      return;
    }

    try {
      final detail = await _repository.getWorkoutDetail(id);
      if (!mounted) return;
      setState(() {
        _detail = detail;
        _loading = false;
      });
    } on ApiException catch (error) {
      if (!mounted) return;
      setState(() {
        _loading = false;
        _error = error.message;
      });
    }
  }

  Future<void> _toggleCompletion() async {
    final assignmentId = widget.workout.assignmentId;
    if (assignmentId == null || !_canComplete || _saving) return;
    setState(() => _saving = true);
    try {
      await _repository.toggleWorkout(widget.workout);
      if (!mounted) return;
      Navigator.pop(context, true);
    } on ApiException catch (error) {
      if (!mounted) return;
      setState(() => _saving = false);
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text(error.message)));
    }
  }

  bool get _canComplete => widget.workout.canComplete;

  String? _imageUrl(String value) {
    if (value.isEmpty) return null;
    final uri = Uri.tryParse(value);
    if (uri?.hasScheme == true) return value;
    final base = AppStrings.imgBaseUrl.isNotEmpty
        ? AppStrings.imgBaseUrl
        : AppStrings.appBaseUrl;
    return base.isEmpty ? value : Uri.parse(base).resolve(value).toString();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(widget.workout.title)),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : _error != null
              ? Center(child: Text(_error!))
              : _buildContent(_detail!),
    );
  }

  Widget _buildContent(WorkoutDetail detail) {
    final image = _imageUrl(detail.imageUrl);
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        if (image != null)
          ClipRRect(
            borderRadius: BorderRadius.circular(12),
            child: Image.network(
              image,
              height: 190,
              fit: BoxFit.cover,
              errorBuilder: (_, __, ___) => const SizedBox.shrink(),
            ),
          ),
        const SizedBox(height: 16),
        Text(detail.title, style: Theme.of(context).textTheme.headlineSmall),
        if (detail.description.isNotEmpty) ...[
          const SizedBox(height: 8),
          Text(detail.description),
        ],
        const SizedBox(height: 12),
        Wrap(
          spacing: 8,
          children: [
            if (detail.level.isNotEmpty) Chip(label: Text(detail.level)),
            if (detail.type.isNotEmpty) Chip(label: Text(detail.type)),
            if (detail.duration.isNotEmpty) Chip(label: Text(detail.duration)),
          ],
        ),
        if (detail.equipment.isNotEmpty) ...[
          const SizedBox(height: 8),
          Text('Equipment: ${detail.equipment.join(', ')}'),
        ],
        const SizedBox(height: 20),
        Text('Exercises', style: Theme.of(context).textTheme.titleLarge),
        const SizedBox(height: 8),
        if (detail.exercises.isEmpty)
          const Text('No exercise details available.')
        else
          ...detail.exercises.map(_exerciseTile),
        const SizedBox(height: 16),
        FilledButton.icon(
          onPressed:
              widget.workout.assignmentId == null || !_canComplete || _saving
                  ? null
                  : _toggleCompletion,
          icon: Icon(
            !_canComplete
                ? Icons.event
                : widget.workout.completed
                    ? Icons.undo
                    : Icons.check,
          ),
          label: Text(!_canComplete
              ? 'Available on workout day'
              : widget.workout.completed
                  ? 'Undo complete'
                  : 'Mark complete'),
        ),
      ],
    );
  }

  Widget _exerciseTile(WorkoutExercise exercise) {
    final facts = <String>[
      if (exercise.sets.isNotEmpty) 'Sets: ${exercise.sets}',
      if (exercise.reps.isNotEmpty) 'Reps: ${exercise.reps}',
      if (exercise.duration.isNotEmpty) 'Duration: ${exercise.duration}',
      if (exercise.equipment.isNotEmpty) 'Equipment: ${exercise.equipment}',
    ];
    return Card(
      child: ListTile(
        title: Text(exercise.title),
        subtitle: facts.isEmpty ? null : Text(facts.join(' • ')),
      ),
    );
  }
}
