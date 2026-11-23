import 'package:fitopia/data/api/api_client.dart';
import 'package:fitopia/data/repository/analytics_repo.dart';
import 'package:fitopia/model/analytics_model.dart';
import 'package:fitopia/presentation/Mixins/size.dart';
import 'package:fitopia/presentation/resources/color_manager.dart';
import 'package:fitopia/presentation/resources/routes_manager.dart';
import 'package:fitopia/presentation/resources/styles_manager.dart';
import 'package:fitopia/presentation/resources/values_manager.dart';
import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:image_picker/image_picker.dart';
import 'package:path_provider/path_provider.dart';
import 'package:responsive_sizer/responsive_sizer.dart';
import 'package:share_plus/share_plus.dart';
import 'dart:io';

class AnalyticsView extends StatefulWidget {
  const AnalyticsView({super.key});

  @override
  State<AnalyticsView> createState() => _AnalyticsViewState();
}

String _dateLabel(DateTime date) {
  return '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';
}

class _AnalyticsViewState extends State<AnalyticsView> {
  static const _metrics = <Map<String, String>>[
    {'key': 'weight', 'label': 'Weight'},
    {'key': 'steps', 'label': 'Steps'},
    {'key': 'neck', 'label': 'Neck'},
    {'key': 'waist', 'label': 'Waist'},
    {'key': 'hips', 'label': 'Hips'},
  ];

  final AnalyticsRepo _analyticsRepo = AnalyticsRepo(apiClient: ApiClient());
  String _selectedMetric = 'weight';
  int _selectedPeriod = 7;
  DateTime _selectedDate = DateTime.now();
  AnalyticsData? _analytics;
  String? _errorMessage;
  bool _isLoading = true;
  bool _redirectingToLogin = false;
  bool _isActionLoading = false;

  @override
  void initState() {
    super.initState();
    _loadAnalytics();
  }

  Future<void> _loadAnalytics() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final analytics = await _analyticsRepo.getAnalytics(
        metric: _selectedMetric,
        period: _selectedPeriod,
        endDate: _selectedDate,
      );
      if (!mounted) {
        return;
      }

      setState(() {
        _analytics = analytics;
        _isLoading = false;
      });
    } on ApiException catch (error) {
      if (error.statusCode == 401 && mounted && !_redirectingToLogin) {
        _redirectingToLogin = true;
        Navigator.pushNamedAndRemoveUntil(
          context,
          Routes.loginRoute,
          (route) => false,
        );
        return;
      }

      if (!mounted) {
        return;
      }
      setState(() {
        _isLoading = false;
        _errorMessage = error.message;
      });
    }
  }

  void _selectMetric(String metric) {
    if (_selectedMetric == metric) {
      return;
    }
    setState(() {
      _selectedMetric = metric;
    });
    _loadAnalytics();
  }

  void _selectPeriod(int? period) {
    if (period == null || period == _selectedPeriod) {
      return;
    }
    setState(() {
      _selectedPeriod = period;
    });
    _loadAnalytics();
  }

  @override
  Widget build(BuildContext context) {
    return RefreshIndicator(
      onRefresh: _loadAnalytics,
      child: SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        child: Column(
          children: [
            SizedBox(height: 50.vs),
            _sectionHeader(
              'My Analytics',
              'Add Measurements',
              _showMeasurementDialog,
            ),
            const SizedBox(height: 10),
            _metricTabs(),
            Padding(
              padding: const EdgeInsets.all(8.0),
              child: _chartCard(),
            ),
            const SizedBox(height: 10),
            _sectionHeader(
              'My Progress',
              'Upload Progress Pic',
              _uploadProgressPhoto,
            ),
            const SizedBox(height: 10),
            _progressPhotos(),
            SizedBox(height: 10.vs),
            _exportButton(),
            SizedBox(height: 1.vs),
          ],
        ),
      ),
    );
  }

  Widget _metricTabs() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 10.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: _metrics.map((metric) {
          final isSelected = metric['key'] == _selectedMetric;
          return GestureDetector(
            onTap: () => _selectMetric(metric['key']!),
            child: Column(
              children: [
                Text(
                  metric['label']!,
                  style: isSelected
                      ? getboldStyle(
                          color: ColorManager.secondryTwo,
                          fontSize: 10.mv,
                        )
                      : getRegularStyle(
                          color: ColorManager.darkGreyColor,
                          fontSize: 10.mv,
                        ),
                ),
                Padding(
                  padding: const EdgeInsets.all(5.0),
                  child: Container(
                    height: 2,
                    width: isSelected ? 50 : 0,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(2),
                      color: ColorManager.secondryTwo,
                    ),
                  ),
                ),
              ],
            ),
          );
        }).toList(),
      ),
    );
  }

  Widget _chartCard() {
    final data = _analytics;
    return Container(
      height: 300,
      decoration: BoxDecoration(
        color: ColorManager.greyBoxColor,
        borderRadius: BorderRadius.circular(15.0),
      ),
      child: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _errorMessage != null
              ? _errorState()
              : data == null
                  ? _emptyState('No analytics data yet.')
                  : _chart(data),
    );
  }

  Widget _chart(AnalyticsData data) {
    final values =
        data.points.map((point) => point.value).whereType<double>().toList();
    final maxValue =
        values.isEmpty ? 1.0 : values.reduce((a, b) => a > b ? a : b);
    final chartMax = maxValue <= 1 ? 1.0 : maxValue * 1.2;

    return Padding(
      padding: const EdgeInsets.fromLTRB(12, 16, 12, 8),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'My ${_metricLabel(data.metric)} History',
                style: getRegularStyle(
                  color: ColorManager.blackColor,
                  fontSize: 16.sp,
                ),
              ),
              DropdownButton<int>(
                value: _selectedPeriod,
                underline: const SizedBox.shrink(),
                items: const [
                  DropdownMenuItem(value: 7, child: Text('Last 7 Days')),
                  DropdownMenuItem(value: 30, child: Text('Last 30 Days')),
                  DropdownMenuItem(value: 90, child: Text('Last 90 Days')),
                ],
                onChanged: _selectPeriod,
              ),
            ],
          ),
          const SizedBox(height: 8),
          Expanded(
            child: BarChart(
              BarChartData(
                maxY: chartMax,
                minY: 0,
                barGroups: data.points.asMap().entries.map((entry) {
                  final value = entry.value.value ?? 0;
                  return BarChartGroupData(
                    x: entry.key,
                    barRods: [
                      BarChartRodData(
                        toY: value,
                        color: ColorManager.secondryTwo,
                        width: _selectedPeriod == 7 ? 8 : 4,
                        borderRadius: BorderRadius.circular(3),
                      ),
                    ],
                  );
                }).toList(),
                borderData: FlBorderData(show: false),
                gridData: FlGridData(show: false),
                barTouchData: BarTouchData(enabled: true),
                titlesData: FlTitlesData(
                  topTitles: AxisTitles(
                    sideTitles: SideTitles(showTitles: false),
                  ),
                  rightTitles: AxisTitles(
                    sideTitles: SideTitles(showTitles: false),
                  ),
                  leftTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      reservedSize: 35,
                      getTitlesWidget: (value, meta) => Text(
                        value.toStringAsFixed(value >= 10 ? 0 : 1),
                        style: const TextStyle(
                          color: Color(0xff7589a2),
                          fontWeight: FontWeight.bold,
                          fontSize: 10,
                        ),
                      ),
                    ),
                  ),
                  bottomTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      reservedSize: 26,
                      getTitlesWidget: (value, meta) {
                        final index = value.toInt();
                        if (index < 0 || index >= data.points.length) {
                          return const SizedBox.shrink();
                        }
                        if (_selectedPeriod > 7 && index % 5 != 0) {
                          return const SizedBox.shrink();
                        }
                        return Text(
                          data.points[index].label,
                          style: const TextStyle(
                            color: Color(0xff7589a2),
                            fontWeight: FontWeight.bold,
                            fontSize: 10,
                          ),
                        );
                      },
                    ),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _progressPhotos() {
    final photos = _analytics?.progressPhotos ?? const <AnalyticsPhoto>[];
    if (photos.isEmpty) {
      return _emptyState('Upload your first progress photo to see it here.');
    }

    return SizedBox(
      height: 200,
      child: ListView.separated(
        padding: const EdgeInsets.symmetric(horizontal: 10),
        scrollDirection: Axis.horizontal,
        itemCount: photos.length,
        separatorBuilder: (_, __) => const SizedBox(width: 5),
        itemBuilder: (context, index) {
          final photo = photos[index];
          return Column(
            children: [
              ClipRRect(
                borderRadius: BorderRadius.circular(10),
                child: Image.network(
                  photo.imageUrl,
                  width: 160,
                  height: 160,
                  fit: BoxFit.cover,
                  errorBuilder: (_, __, ___) => Container(
                    width: 160,
                    height: 160,
                    color: ColorManager.greyBoxColor,
                    child: const Icon(Icons.image_not_supported_outlined),
                  ),
                ),
              ),
              const SizedBox(height: 8),
              Text(
                _photoDate(photo.capturedAt),
                style: getRegularStyle(
                  color: ColorManager.blackColor,
                  fontSize: AppSize.s10.mv,
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _exportButton() {
    return Padding(
      padding: EdgeInsets.symmetric(
        horizontal: AppSize.sizeWidth(context) * 0.06,
        vertical: 10,
      ),
      child: SizedBox(
        width: double.infinity,
        child: ElevatedButton(
          style: ElevatedButton.styleFrom(
            backgroundColor: ColorManager.secondryTwo,
            padding: const EdgeInsets.symmetric(vertical: 14),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(10),
            ),
          ),
          onPressed: _isActionLoading ? null : _exportData,
          child: Text(
            'Export My Data',
            style: getboldStyle(
              color: ColorManager.whiteColor,
              fontSize: AppSize.s12.mv,
            ),
          ),
        ),
      ),
    );
  }

  Widget _sectionHeader(String title, String action, VoidCallback onTap) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 10.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            title,
            style: getboldStyle(
              color: ColorManager.blackColor,
              fontSize: 14.px,
            ),
          ),
          InkWell(
            onTap: onTap,
            borderRadius: BorderRadius.circular(6),
            child: Container(
              decoration: BoxDecoration(
                color: ColorManager.secondryTwo,
                borderRadius: BorderRadius.circular(6),
              ),
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
              child: Text(
                action,
                style: getRegularStyle(color: ColorManager.whiteColor),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _emptyState(String message) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Text(
          message,
          textAlign: TextAlign.center,
          style: getRegularStyle(color: ColorManager.darkGreyColor),
        ),
      ),
    );
  }

  Widget _errorState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(
            _errorMessage!,
            textAlign: TextAlign.center,
            style: getRegularStyle(color: ColorManager.darkGreyColor),
          ),
          const SizedBox(height: 10),
          TextButton(
            onPressed: _loadAnalytics,
            child: const Text('Retry'),
          ),
        ],
      ),
    );
  }

  String _metricLabel(String metric) {
    return _metrics.firstWhere(
      (item) => item['key'] == metric,
      orElse: () => {'label': 'Weight'},
    )['label']!;
  }

  String _photoDate(DateTime? date) {
    if (date == null) {
      return 'Date unavailable';
    }
    final difference = DateTime.now().difference(date).inDays;
    if (difference <= 0) {
      return 'Today';
    }
    return '$difference ${difference == 1 ? 'day' : 'days'} ago';
  }

  void _showMessage(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message)),
    );
  }

  Future<void> _showMeasurementDialog() async {
    DateTime measurementDate = _selectedDate;
    final weightController = TextEditingController();
    final stepsController = TextEditingController();
    final neckController = TextEditingController();
    final waistController = TextEditingController();
    final hipsController = TextEditingController();

    final saved = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => StatefulBuilder(
        builder: (dialogContext, setDialogState) => AlertDialog(
          title: const Text('Add Measurements'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                ListTile(
                  contentPadding: EdgeInsets.zero,
                  title: const Text('Measurement date'),
                  subtitle: Text(_dateLabel(measurementDate)),
                  trailing: const Icon(Icons.calendar_today_outlined),
                  onTap: () async {
                    final picked = await showDatePicker(
                      context: dialogContext,
                      initialDate: measurementDate,
                      firstDate: DateTime(2000),
                      lastDate: DateTime.now().add(const Duration(days: 365)),
                    );
                    if (picked != null) {
                      measurementDate = picked;
                      setDialogState(() {});
                    }
                  },
                ),
                _measurementField(weightController, 'Weight (kg)', false),
                _measurementField(stepsController, 'Steps', false),
                _measurementField(neckController, 'Neck (cm)', false),
                _measurementField(waistController, 'Waist (cm)', false),
                _measurementField(hipsController, 'Hips (cm)', false),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(dialogContext, false),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () {
                final hasValue = [
                  weightController,
                  stepsController,
                  neckController,
                  waistController,
                  hipsController,
                ].any((controller) => controller.text.trim().isNotEmpty);
                if (!hasValue) {
                  _showMessage('Enter at least one measurement.');
                  return;
                }
                if (stepsController.text.trim().isNotEmpty &&
                    int.tryParse(stepsController.text.trim()) == null) {
                  _showMessage('Enter a valid step count.');
                  return;
                }
                if ([
                  weightController,
                  neckController,
                  waistController,
                  hipsController,
                ].any((controller) =>
                    controller.text.trim().isNotEmpty &&
                    double.tryParse(controller.text.trim()) == null)) {
                  _showMessage('Enter valid measurement values.');
                  return;
                }
                Navigator.pop(dialogContext, true);
              },
              child: const Text('Save'),
            ),
          ],
        ),
      ),
    );

    if (saved != true || !mounted) {
      _disposeMeasurementControllers([
        weightController,
        stepsController,
        neckController,
        waistController,
        hipsController,
      ]);
      return;
    }

    await _runAction(
      () => _analyticsRepo.saveMeasurement(
        date: measurementDate,
        weight: double.tryParse(weightController.text.trim()),
        steps: int.tryParse(stepsController.text.trim()),
        neck: double.tryParse(neckController.text.trim()),
        waist: double.tryParse(waistController.text.trim()),
        hips: double.tryParse(hipsController.text.trim()),
      ),
      successMessage: 'Measurements saved.',
    );
    _disposeMeasurementControllers([
      weightController,
      stepsController,
      neckController,
      waistController,
      hipsController,
    ]);
    setState(() {
      _selectedDate = measurementDate;
    });
    await _loadAnalytics();
  }

  Widget _measurementField(
    TextEditingController controller,
    String label,
    bool required,
  ) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: TextField(
        controller: controller,
        keyboardType: const TextInputType.numberWithOptions(decimal: true),
        decoration: InputDecoration(
          labelText: required ? '$label *' : label,
          border: const OutlineInputBorder(),
        ),
      ),
    );
  }

  void _disposeMeasurementControllers(
    List<TextEditingController> controllers,
  ) {
    for (final controller in controllers) {
      controller.dispose();
    }
  }

  Future<void> _uploadProgressPhoto() async {
    final image = await ImagePicker().pickImage(
      source: ImageSource.gallery,
      imageQuality: 85,
      maxWidth: 1600,
    );
    if (image == null || !mounted) {
      return;
    }

    await _runAction(
      () => _analyticsRepo.uploadProgressPhoto(File(image.path)),
      successMessage: 'Progress photo uploaded.',
    );
  }

  Future<void> _exportData() async {
    await _runAction(() async {
      final bytes = await _analyticsRepo.exportMeasurements();
      final directory = await getTemporaryDirectory();
      final file = File(
        '${directory.path}${Platform.pathSeparator}fitopia_measurements.pdf',
      );
      await file.writeAsBytes(bytes, flush: true);
      await Share.shareXFiles(
        [XFile(file.path)],
        text: 'My Fitopia measurements',
      );
    });
  }

  Future<void> _runAction(
    Future<void> Function() action, {
    String? successMessage,
  }) async {
    setState(() {
      _isActionLoading = true;
    });
    try {
      await action();
      if (!mounted) {
        return;
      }
      if (successMessage != null) {
        _showMessage(successMessage);
      }
      await _loadAnalytics();
    } on ApiException catch (error) {
      if (mounted) {
        _showMessage(error.message);
      }
    } finally {
      if (mounted) {
        setState(() {
          _isActionLoading = false;
        });
      }
    }
  }
}
