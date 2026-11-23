import 'package:flutter/material.dart';

import '../../data/api/api_client.dart';
import '../../data/repository/my_program_repo.dart';
import '../../model/my_program_model.dart';
import '../resources/index_manager.dart';

class MyProgramView extends StatefulWidget {
  const MyProgramView({super.key});

  @override
  State<MyProgramView> createState() => _MyProgramViewState();
}

class _MyProgramViewState extends State<MyProgramView> {
  final MyProgramRepo _programRepo = MyProgramRepo(apiClient: ApiClient());
  late Future<List<MyProgram>> _programsFuture;
  int _selectedDay = 0;

  @override
  void initState() {
    super.initState();
    _programsFuture = _loadPrograms();
  }

  Future<List<MyProgram>> _loadPrograms() => _programRepo.getPrograms();

  Future<void> _refresh() async {
    final future = _loadPrograms();
    setState(() {
      _programsFuture = future;
    });
    await future;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('My Program'),
        actions: [
          IconButton(onPressed: _refresh, icon: const Icon(Icons.refresh)),
        ],
      ),
      body: FutureBuilder<List<MyProgram>>(
        future: _programsFuture,
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

          final programs = snapshot.data ?? const <MyProgram>[];
          if (programs.isEmpty) {
            return _MessageState(
              message: 'Your personalized workout program is not ready yet.',
              actionLabel: 'Refresh',
              onAction: _refresh,
            );
          }

          final selectedIndex =
              _selectedDay.clamp(0, programs.length - 1).toInt();
          return RefreshIndicator(
            onRefresh: _refresh,
            child: _buildProgram(programs, selectedIndex),
          );
        },
      ),
    );
  }

  Widget _buildProgram(List<MyProgram> programs, int selectedIndex) {
    final selectedProgram = programs[selectedIndex];
    final workoutCount =
        programs.where((program) => program.workoutId != null).length;
    final restCount = programs.length - workoutCount;

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        _ProgramSummary(
          workoutCount: workoutCount,
          restCount: restCount,
        ),
        const SizedBox(height: 16),
        SizedBox(
          height: 74,
          child: ListView.separated(
            scrollDirection: Axis.horizontal,
            itemCount: programs.length,
            separatorBuilder: (_, __) => const SizedBox(width: 8),
            itemBuilder: (_, index) {
              final program = programs[index];
              final selected = index == selectedIndex;
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
                      Text(_dayLabel(program.assignedDate),
                          style: TextStyle(
                              color: selected ? Colors.white : Colors.black54)),
                      const SizedBox(height: 4),
                      Text(_dateLabel(program.assignedDate),
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
            Text(_fullDayLabel(selectedProgram.assignedDate),
                style:
                    const TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
            Text(selectedProgram.workoutId == null ? 'Rest day' : 'Workout day',
                style: TextStyle(color: Colors.grey.shade700)),
          ],
        ),
        const SizedBox(height: 12),
        _workoutCard(selectedProgram),
      ],
    );
  }

  Widget _workoutCard(MyProgram program) {
    final isRestDay = program.workoutId == null;
    return Card(
      margin: EdgeInsets.zero,
      child: InkWell(
        onTap: isRestDay
            ? null
            : () => Navigator.pushNamed(
                  context,
                  Routes.workoutDetailPageRoute,
                  arguments: program.toDashboardWorkout(),
                ),
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Row(
            children: [
              CircleAvatar(
                backgroundColor: ColorManager.secondry.withOpacity(.12),
                child: Icon(
                  isRestDay ? Icons.hotel : Icons.fitness_center,
                  color: ColorManager.secondry,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(isRestDay ? 'Recovery' : _label(program.type),
                        style: TextStyle(
                            color: ColorManager.secondry,
                            fontSize: 12,
                            fontWeight: FontWeight.bold)),
                    const SizedBox(height: 3),
                    Text(program.title,
                        style: const TextStyle(
                            fontSize: 16, fontWeight: FontWeight.w600)),
                    const SizedBox(height: 4),
                    Text(_subtitle(program),
                        style: TextStyle(color: Colors.grey.shade700)),
                  ],
                ),
              ),
              if (!isRestDay)
                Icon(Icons.chevron_right, color: Colors.grey.shade600),
            ],
          ),
        ),
      ),
    );
  }

  String _subtitle(MyProgram program) {
    if (program.status == 'completed') return 'Completed';
    if (program.canComplete) return 'Ready for today';
    return program.level.isEmpty ? 'Available on workout day' : program.level;
  }

  String _dayLabel(String value) {
    final date = DateTime.tryParse(value);
    return date == null
        ? 'Day'
        : const [
            'Sun',
            'Mon',
            'Tue',
            'Wed',
            'Thu',
            'Fri',
            'Sat'
          ][date.weekday % 7];
  }

  String _dateLabel(String value) {
    final date = DateTime.tryParse(value);
    return date == null ? '--' : date.day.toString();
  }

  String _fullDayLabel(String value) {
    final date = DateTime.tryParse(value);
    if (date == null) return 'Program day';
    return const [
      'Sunday',
      'Monday',
      'Tuesday',
      'Wednesday',
      'Thursday',
      'Friday',
      'Saturday'
    ][date.weekday % 7];
  }

  String _label(String value) {
    if (value.isEmpty) return 'Workout';
    return '${value[0].toUpperCase()}${value.substring(1)}';
  }
}

class _ProgramSummary extends StatelessWidget {
  final int workoutCount;
  final int restCount;

  const _ProgramSummary({
    required this.workoutCount,
    required this.restCount,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      color: ColorManager.secondry.withOpacity(.08),
      elevation: 0,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Your personalized program',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            const SizedBox(height: 5),
            const Text('Your AI-generated schedule is organized day by day.'),
            const SizedBox(height: 10),
            Text('$workoutCount workouts • $restCount recovery days'),
          ],
        ),
      ),
    );
  }
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
