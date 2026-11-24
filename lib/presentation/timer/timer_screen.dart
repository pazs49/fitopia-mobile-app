import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../resources/index_manager.dart';

enum _TimerPhase { work, rest }

class TimerView extends StatefulWidget {
  const TimerView({super.key});

  @override
  State<TimerView> createState() => _TimerViewState();
}

class _TimerViewState extends State<TimerView> {
  static const int _tabataWork = 20;
  static const int _tabataRest = 10;

  Timer? _ticker;
  DateTime? _endsAt;
  String _selectedTemplate = 'Tabata';
  int _workSeconds = _tabataWork;
  int _restSeconds = _tabataRest;
  int _totalRounds = 8;
  int _round = 1;
  int _remainingSeconds = _tabataWork;
  int _phaseTotalSeconds = _tabataWork;
  _TimerPhase _phase = _TimerPhase.work;
  bool _isRunning = false;
  bool _isComplete = false;

  bool get _hasRest => _restSeconds > 0;
  String get _phaseLabel {
    if (_isComplete) {
      return 'Workout complete';
    }
    return _phase == _TimerPhase.work ? 'WORK' : 'REST';
  }

  Color get _phaseColor => _phase == _TimerPhase.work
      ? ColorManager.primary
      : ColorManager.fabBlueColor;

  @override
  void dispose() {
    _ticker?.cancel();
    super.dispose();
  }

  void _selectTemplate(String template) {
    if (_isRunning) {
      return;
    }

    switch (template) {
      case 'Tabata':
        _setWorkout(template, _tabataWork, _tabataRest, 8);
        break;
      case 'HIIT':
        _setWorkout(template, 30, 15, 8);
        break;
      case 'EMOM':
        _setWorkout(template, 60, 0, 10);
        break;
      case 'Circuit':
        _setWorkout(template, 45, 15, 6);
        break;
    }
  }

  void _setWorkout(String template, int work, int rest, int rounds) {
    setState(() {
      _selectedTemplate = template;
      _workSeconds = work;
      _restSeconds = rest;
      _totalRounds = rounds;
      _resetValues();
    });
  }

  void _resetValues() {
    _ticker?.cancel();
    _ticker = null;
    _endsAt = null;
    _isRunning = false;
    _isComplete = false;
    _round = 1;
    _phase = _TimerPhase.work;
    _phaseTotalSeconds = _workSeconds;
    _remainingSeconds = _workSeconds;
  }

  void _toggleTimer() {
    if (_isComplete) {
      _resetTimer();
      _startTimer();
      return;
    }
    if (_isRunning) {
      _pauseTimer();
    } else {
      _startTimer();
    }
  }

  void _startTimer() {
    if (_remainingSeconds == 0) {
      _resetTimer();
    }

    setState(() {
      _isRunning = true;
      _endsAt = DateTime.now().add(Duration(seconds: _remainingSeconds));
    });
    _ticker?.cancel();
    _ticker = Timer.periodic(const Duration(milliseconds: 250), (_) {
      _tick();
    });
  }

  void _pauseTimer() {
    _tick();
    _ticker?.cancel();
    setState(() {
      _ticker = null;
      _isRunning = false;
      _endsAt = null;
    });
  }

  void _tick() {
    if (!_isRunning || _endsAt == null) {
      return;
    }
    final milliseconds = _endsAt!.difference(DateTime.now()).inMilliseconds;
    final seconds = math.max(0, (milliseconds + 999) ~/ 1000);
    if (seconds > 0) {
      if (seconds != _remainingSeconds && mounted) {
        setState(() {
          _remainingSeconds = seconds;
        });
      }
      return;
    }
    _advancePhase();
  }

  void _advancePhase() {
    if (_phase == _TimerPhase.work && _hasRest) {
      _beginPhase(_TimerPhase.rest, _restSeconds);
      return;
    }

    if (_round >= _totalRounds) {
      _ticker?.cancel();
      if (mounted) {
        setState(() {
          _ticker = null;
          _endsAt = null;
          _isRunning = false;
          _isComplete = true;
          _remainingSeconds = 0;
        });
      }
      return;
    }

    setState(() {
      _round++;
    });
    _beginPhase(_TimerPhase.work, _workSeconds);
  }

  void _beginPhase(_TimerPhase phase, int seconds) {
    if (!mounted) {
      return;
    }
    setState(() {
      _phase = phase;
      _phaseTotalSeconds = seconds;
      _remainingSeconds = seconds;
      _endsAt = DateTime.now().add(Duration(seconds: seconds));
    });
  }

  void _skipPhase() {
    if (!_isRunning || _isComplete) {
      return;
    }
    _advancePhase();
  }

  void _addTenSeconds() {
    if (_isComplete) {
      return;
    }
    setState(() {
      _remainingSeconds += 10;
      _phaseTotalSeconds += 10;
      if (_isRunning) {
        _endsAt = DateTime.now().add(Duration(seconds: _remainingSeconds));
      }
    });
  }

  void _resetTimer() {
    setState(_resetValues);
  }

  Future<void> _showCustomSetup() async {
    if (_isRunning) {
      return;
    }

    final workController = TextEditingController(text: '30');
    final restController = TextEditingController(text: '15');
    final roundsController = TextEditingController(text: '8');
    final result = await showDialog<List<int>>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Custom interval'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: workController,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(labelText: 'Work seconds'),
            ),
            TextField(
              controller: restController,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(labelText: 'Rest seconds'),
            ),
            TextField(
              controller: roundsController,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(labelText: 'Rounds'),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              final values = [
                int.tryParse(workController.text) ?? 0,
                int.tryParse(restController.text) ?? 0,
                int.tryParse(roundsController.text) ?? 0,
              ];
              if (values[0] > 0 && values[1] >= 0 && values[2] > 0) {
                Navigator.pop(context, values);
              }
            },
            child: const Text('Use timer'),
          ),
        ],
      ),
    );
    if (result == null || !mounted) {
      return;
    }
    setState(() {
      _selectedTemplate = 'Custom';
      _workSeconds = result[0];
      _restSeconds = result[1];
      _totalRounds = result[2];
      _resetValues();
    });
  }

  String _formatTime(int seconds) {
    final minutes = seconds ~/ 60;
    final remaining = seconds % 60;
    return '${minutes.toString().padLeft(2, '0')}:'
        '${remaining.toString().padLeft(2, '0')}';
  }

  @override
  Widget build(BuildContext context) {
    final progress = _phaseTotalSeconds == 0
        ? 0.0
        : _remainingSeconds / _phaseTotalSeconds;

    return Scaffold(
      appBar: AppBar(title: const Text('Workout Timer')),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.fromLTRB(20, 12, 20, 24),
          children: [
            Text(
              'Choose a workout style',
              style: getboldStyle(
                color: ColorManager.blackColor,
                fontSize: AppSize.s16,
              ),
            ),
            const SizedBox(height: 10),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                ...['Tabata', 'HIIT', 'EMOM', 'Circuit'].map(
                  (template) => ChoiceChip(
                    label: Text(template),
                    selected: _selectedTemplate == template,
                    onSelected: (_) => _selectTemplate(template),
                  ),
                ),
                ActionChip(
                  label: const Text('Custom'),
                  avatar: const Icon(Icons.tune, size: 18),
                  onPressed: _showCustomSetup,
                ),
              ],
            ),
            const SizedBox(height: 22),
            Card(
              elevation: 0,
              color: ColorManager.greyBoxColor,
              child: Padding(
                padding: const EdgeInsets.all(14),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceAround,
                  children: [
                    _stat('Work', _formatTime(_workSeconds)),
                    _stat('Rest', _formatTime(_restSeconds)),
                    _stat('Rounds', '$_totalRounds'),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 28),
            Center(
              child: Stack(
                alignment: Alignment.center,
                children: [
                  SizedBox(
                    width: 235,
                    height: 235,
                    child: CircularProgressIndicator(
                      value: progress,
                      strokeWidth: 13,
                      backgroundColor: ColorManager.greyBoxColor,
                      valueColor: AlwaysStoppedAnimation<Color>(_phaseColor),
                    ),
                  ),
                  Column(
                    children: [
                      Text(
                        _phaseLabel,
                        style: getboldStyle(color: _phaseColor, fontSize: 18),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        _formatTime(_remainingSeconds),
                        style: getboldStyle(
                          color: ColorManager.blackColor,
                          fontSize: 40,
                        ),
                      ),
                      if (!_isComplete)
                        Text(
                          'Round $_round of $_totalRounds',
                          style: getmediumStyle(
                            color: ColorManager.darkGreyColor,
                          ),
                        ),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 26),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                OutlinedButton.icon(
                  onPressed: _resetTimer,
                  icon: const Icon(Icons.refresh),
                  label: const Text('Reset'),
                ),
                const SizedBox(width: 12),
                ElevatedButton.icon(
                  onPressed: _toggleTimer,
                  icon: Icon(_isRunning ? Icons.pause : Icons.play_arrow),
                  label: Text(_isComplete
                      ? 'Start again'
                      : (_isRunning ? 'Pause' : 'Start')),
                ),
              ],
            ),
            const SizedBox(height: 10),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                TextButton.icon(
                  onPressed: _isRunning ? _skipPhase : null,
                  icon: const Icon(Icons.skip_next),
                  label: const Text('Skip phase'),
                ),
                TextButton.icon(
                  onPressed: _isRunning ? _addTenSeconds : null,
                  icon: const Icon(Icons.add),
                  label: const Text('10 seconds'),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _stat(String label, String value) {
    return Column(
      children: [
        Text(label, style: getmediumStyle(color: ColorManager.darkGreyColor)),
        const SizedBox(height: 4),
        Text(
          value,
          style: getboldStyle(color: ColorManager.blackColor, fontSize: 16),
        ),
      ],
    );
  }
}
