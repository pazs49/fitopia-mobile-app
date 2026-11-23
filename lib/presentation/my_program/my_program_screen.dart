import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';

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

  @override
  void initState() {
    super.initState();
    _programsFuture = _loadPrograms();
  }

  Future<List<MyProgram>> _loadPrograms() {
    return _programRepo.getPrograms();
  }

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
        backgroundColor: ColorManager.greyBoxColor,
        leading: InkWell(
          onTap: () => Navigator.of(context).pop(),
          child: Padding(
            padding: const EdgeInsets.all(18.0),
            child: SvgPicture.asset(
              ImageAssets.arrowBack,
              color: ColorManager.blackColor,
            ),
          ),
        ),
        title: Text(
          'My Program',
          style: getboldStyle(
            color: ColorManager.blackColor,
            fontSize: AppSize.s16,
          ),
        ),
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
              message: 'No workout programs have been assigned yet.',
              actionLabel: 'Refresh',
              onAction: _refresh,
            );
          }

          return RefreshIndicator(
            onRefresh: _refresh,
            child: ListView.separated(
              padding: const EdgeInsets.all(16),
              itemCount: programs.length,
              separatorBuilder: (_, __) => const SizedBox(height: 12),
              itemBuilder: (context, index) {
                final program = programs[index];
                final card = Card(
                  child: ListTile(
                    onTap: program.workoutId == null
                        ? null
                        : () => Navigator.pushNamed(
                              context,
                              Routes.workoutDetailPageRoute,
                              arguments: program.toDashboardWorkout(),
                            ),
                    contentPadding: const EdgeInsets.all(16),
                    leading: CircleAvatar(
                      backgroundColor: ColorManager.secondry.withAlpha(31),
                      child: Icon(
                        Icons.fitness_center,
                        color: ColorManager.secondry,
                      ),
                    ),
                    title: Text(
                      program.title,
                      style: getboldStyle(
                        color: ColorManager.blackColor,
                        fontSize: AppSize.s16,
                      ),
                    ),
                    subtitle: Padding(
                      padding: const EdgeInsets.only(top: 6),
                      child: Text(
                        _subtitle(program),
                        style: getRegularStyle(
                          color: ColorManager.greyColor,
                          fontSize: AppSize.s12,
                        ),
                      ),
                    ),
                  ),
                );
                return card;
              },
            ),
          );
        },
      ),
    );
  }

  String _subtitle(MyProgram program) {
    final date = program.assignedDate;
    final status = program.status.isEmpty ? '' : program.status;
    if (date.isEmpty) {
      return status;
    }
    return status.isEmpty ? 'Assigned $date' : 'Assigned $date • $status';
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
            TextButton(
              onPressed: onAction,
              child: Text(actionLabel),
            ),
          ],
        ),
      ),
    );
  }
}
