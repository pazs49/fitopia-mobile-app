import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';

import '../../data/api/api_client.dart';
import '../../data/repository/reminder_preferences_repo.dart';
import '../../model/reminder_preferences_model.dart';
import '../resources/index_manager.dart';

class SettingsView extends StatefulWidget {
  const SettingsView({super.key});

  @override
  State<SettingsView> createState() => _SettingsViewState();
}

class _SettingsViewState extends State<SettingsView> {
  final ReminderPreferencesRepo _repo = ReminderPreferencesRepo();
  ReminderPreferences? _preferences;
  String? _error;
  bool _loading = true;
  bool _saving = false;

  final List<String> _otherSettings = const [
    'About Us',
    'Frequently Asked Questions',
    'Contact Support',
    'Terms of Services',
    'Troubleshooting',
    'New Updates',
    'Delete Account',
    'Subscriptions',
  ];

  @override
  void initState() {
    super.initState();
    _loadPreferences();
  }

  Future<void> _loadPreferences() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final preferences = await _repo.getPreferences();
      if (!mounted) return;
      setState(() {
        _preferences = preferences;
        _loading = false;
      });
    } on ApiException catch (error) {
      if (!mounted) return;
      setState(() {
        _error = error.message;
        _loading = false;
      });
    }
  }

  Future<void> _save(ReminderPreferences preferences) async {
    if (_saving) return;
    setState(() {
      _preferences = preferences;
      _saving = true;
    });
    try {
      final saved = await _repo.updatePreferences(preferences);
      if (!mounted) return;
      setState(() => _preferences = saved);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Reminder preferences saved.')),
      );
    } on ApiException catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text(error.message)));
      await _loadPreferences();
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  Future<void> _pickTime(
    String label,
    String current,
    ReminderPreferences Function(String) update,
  ) async {
    final parts = current.split(':');
    final initial = TimeOfDay(
      hour: int.tryParse(parts[0]) ?? 0,
      minute: int.tryParse(parts[1]) ?? 0,
    );
    final selected = await showTimePicker(
      context: context,
      initialTime: initial,
      helpText: '$label reminder time',
    );
    if (selected == null || _preferences == null) return;
    final value = '${selected.hour.toString().padLeft(2, '0')}:'
        '${selected.minute.toString().padLeft(2, '0')}';
    await _save(update(value));
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
          'Settings',
          style: getboldStyle(
            color: ColorManager.blackColor,
            fontSize: AppSize.s18,
          ),
        ),
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : _error != null
              ? _ErrorState(message: _error!, onRetry: _loadPreferences)
              : ListView(
                  padding: const EdgeInsets.all(8),
                  children: [
                    _buildReminderSection(_preferences!),
                    const SizedBox(height: 8),
                    ..._otherSettings.map(
                      (setting) => Column(
                        children: [
                          const Divider(),
                          Padding(
                            padding: const EdgeInsets.all(8),
                            child: Align(
                              alignment: Alignment.centerLeft,
                              child: Text(
                                setting,
                                style: getRegularStyle(
                                    color: ColorManager.blackColor),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
    );
  }

  Widget _buildReminderSection(ReminderPreferences preferences) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 8),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Padding(
              padding: EdgeInsets.fromLTRB(16, 8, 16, 4),
              child: Text(
                'Reminder preferences',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
            ),
            const Padding(
              padding: EdgeInsets.fromLTRB(16, 0, 16, 8),
              child: Text('Choose when Fitopia should remind you.'),
            ),
            _reminderTile(
              label: 'Breakfast',
              time: preferences.breakfastTime,
              enabled: preferences.breakfastEnabled,
              update: (time) => preferences.copyWith(breakfastTime: time),
              toggle: (enabled) =>
                  preferences.copyWith(breakfastEnabled: enabled),
            ),
            _reminderTile(
              label: 'Lunch',
              time: preferences.lunchTime,
              enabled: preferences.lunchEnabled,
              update: (time) => preferences.copyWith(lunchTime: time),
              toggle: (enabled) => preferences.copyWith(lunchEnabled: enabled),
            ),
            _reminderTile(
              label: 'Snack',
              time: preferences.snackTime,
              enabled: preferences.snackEnabled,
              update: (time) => preferences.copyWith(snackTime: time),
              toggle: (enabled) => preferences.copyWith(snackEnabled: enabled),
            ),
            _reminderTile(
              label: 'Dinner',
              time: preferences.dinnerTime,
              enabled: preferences.dinnerEnabled,
              update: (time) => preferences.copyWith(dinnerTime: time),
              toggle: (enabled) => preferences.copyWith(dinnerEnabled: enabled),
            ),
            _reminderTile(
              label: 'Workout',
              time: preferences.workoutTime,
              enabled: preferences.workoutEnabled,
              update: (time) => preferences.copyWith(workoutTime: time),
              toggle: (enabled) =>
                  preferences.copyWith(workoutEnabled: enabled),
            ),
            if (_saving)
              const Padding(
                padding: EdgeInsets.symmetric(horizontal: 16),
                child: LinearProgressIndicator(),
              ),
          ],
        ),
      ),
    );
  }

  Widget _reminderTile({
    required String label,
    required String time,
    required bool enabled,
    required ReminderPreferences Function(String) update,
    required ReminderPreferences Function(bool) toggle,
  }) {
    return ListTile(
      title: Text(label),
      subtitle: Text(enabled ? 'Reminder at $time' : 'Reminder disabled'),
      trailing: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          TextButton(
            onPressed: enabled ? () => _pickTime(label, time, update) : null,
            child: const Text('Change'),
          ),
          Switch(
            value: enabled,
            onChanged: (value) => _save(toggle(value)),
          ),
        ],
      ),
    );
  }
}

class _ErrorState extends StatelessWidget {
  const _ErrorState({required this.message, required this.onRetry});

  final String message;
  final VoidCallback onRetry;

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
