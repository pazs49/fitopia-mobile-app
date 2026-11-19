import 'package:fitopia/data/api/api_client.dart';
import 'package:fitopia/data/repository/onboarding_repo.dart';
import 'package:fitopia/model/onboarding_model.dart';
import 'package:fitopia/presentation/Mixins/size.dart';
import 'package:fitopia/presentation/resources/index_manager.dart';
import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';

class Onboarding1View extends StatefulWidget {
  const Onboarding1View({super.key});

  @override
  State<Onboarding1View> createState() => _Onboarding1ViewState();
}

class _Onboarding1ViewState extends State<Onboarding1View> {
  final OnboardingRepo _onboardingRepo = OnboardingRepo(apiClient: ApiClient());
  final TextEditingController _ageController =
      TextEditingController(text: '25');
  final TextEditingController _heightController =
      TextEditingController(text: '170');
  final TextEditingController _weightController =
      TextEditingController(text: '70');

  int _currentPage = 0;
  int? _goal;
  int? _dietary;
  int? _active;
  int? _gender;
  int? _femaleSpecificPlan;
  String _weekGoals = 'maintain';
  bool _isSubmitting = false;
  String? _errorMessage;

  static const List<_Option> _goals = [
    _Option(3, 'Lose weight'),
    _Option(1, 'Lean bulk'),
    _Option(5, 'Gain weight'),
  ];
  static const List<_Option> _dietaryRequirements = [
    _Option(1, 'Standard'),
    _Option(2, 'Vegetarian'),
    _Option(3, 'Vegan'),
  ];
  static const List<_Option> _activityLevels = [
    _Option(1, 'Sedentary'),
    _Option(2, 'Lightly active'),
    _Option(3, 'Moderately active'),
    _Option(4, 'Very active'),
    _Option(5, 'Extremely active'),
  ];
  static const List<_Option> _genders = [
    _Option(1, 'Male'),
    _Option(2, 'Female'),
  ];
  static const List<_Option> _femalePlans = [
    _Option(1, 'Yes'),
    _Option(2, 'No'),
  ];
  static const List<_Option> _weeklyGoals = [
    _Option(0, 'Maintain weight', value: 'maintain'),
    _Option(1, 'Lose 0.25 kg per week', value: 'lose_0.25'),
    _Option(2, 'Lose 0.5 kg per week', value: 'lose_0.5'),
    _Option(3, 'Lose 1 kg per week', value: 'lose_1'),
    _Option(4, 'Gain 0.25 kg per week', value: 'gain_0.25'),
    _Option(5, 'Gain 0.5 kg per week', value: 'gain_0.5'),
  ];

  @override
  void dispose() {
    _ageController.dispose();
    _heightController.dispose();
    _weightController.dispose();
    super.dispose();
  }

  Future<void> _next() async {
    if (!_validateCurrentPage()) {
      return;
    }

    if (_currentPage < 8) {
      setState(() {
        _currentPage++;
        _errorMessage = null;
      });
      return;
    }

    await _submit();
  }

  bool _validateCurrentPage() {
    if (_currentPage == 0 && _goal == null ||
        _currentPage == 1 && _dietary == null ||
        _currentPage == 2 && _active == null ||
        _currentPage == 3 && _gender == null ||
        _currentPage == 4 && _femaleSpecificPlan == null) {
      _showError('Please select an option to continue.');
      return false;
    }

    if (_currentPage == 5 && !_validNumber(_ageController, 13, 120) ||
        _currentPage == 6 && !_validNumber(_heightController, 100, 250) ||
        _currentPage == 7 && !_validNumber(_weightController, 20, 350)) {
      _showError('Please enter a valid value to continue.');
      return false;
    }

    return true;
  }

  bool _validNumber(TextEditingController controller, int min, int max) {
    final value = int.tryParse(controller.text.trim());
    return value != null && value >= min && value <= max;
  }

  Future<void> _submit() async {
    setState(() {
      _isSubmitting = true;
      _errorMessage = null;
    });

    try {
      await _onboardingRepo.submit({
        'goal': _goal,
        'dietary': _dietary,
        'active': _active,
        'gender': _gender,
        'female_specific_plan': _femaleSpecificPlan,
        'age': int.parse(_ageController.text.trim()),
        'height': int.parse(_heightController.text.trim()),
        'weight': int.parse(_weightController.text.trim()),
        'weekgoals': _weekGoals,
      });

      if (!mounted) {
        return;
      }
      Navigator.pushReplacementNamed(context, Routes.HomePageRoute);
    } on ApiException catch (error) {
      if (mounted) {
        setState(() {
          _errorMessage = error.message;
        });
      }
    } finally {
      if (mounted) {
        setState(() {
          _isSubmitting = false;
        });
      }
    }
  }

  void _showError(String message) {
    setState(() {
      _errorMessage = message;
    });
  }

  @override
  Widget build(BuildContext context) {
    final title = _titles[_currentPage];

    return Scaffold(
      body: SafeArea(
        child: Column(
          children: [
            _progress(),
            const SizedBox(height: 18),
            SvgPicture.asset(
              OnboardingImgTitle[_currentPage].imagePath!,
              height: 150,
            ),
            const SizedBox(height: 18),
            Text(
              title,
              style: getboldStyle(
                color: Theme.of(context).textTheme.bodyLarge!.color!,
                fontSize: AppSize.s20.mv,
              ),
            ),
            const SizedBox(height: 18),
            Expanded(child: _content()),
            if (_errorMessage != null)
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: Text(
                  _errorMessage!,
                  textAlign: TextAlign.center,
                  style: TextStyle(color: Colors.red.shade700),
                ),
              ),
            Padding(
              padding: const EdgeInsets.all(16),
              child: SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: _isSubmitting ? null : _next,
                  child: Text(
                    _isSubmitting
                        ? 'Saving...'
                        : _currentPage == 8
                            ? 'Finish'
                            : 'Next',
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _progress() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(12, 12, 12, 0),
      child: Row(
        children: List.generate(
          9,
          (index) => Expanded(
            child: Container(
              height: 8,
              margin: const EdgeInsets.symmetric(horizontal: 3),
              decoration: BoxDecoration(
                color: index <= _currentPage
                    ? ColorManager.primary
                    : ColorManager.greyColor,
                borderRadius: BorderRadius.circular(8),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _content() {
    if (_currentPage == 5) {
      return _numberField(_ageController, 'Age', 'years');
    }
    if (_currentPage == 6) {
      return _numberField(_heightController, 'Height', 'cm');
    }
    if (_currentPage == 7) {
      return _numberField(_weightController, 'Weight', 'kg');
    }

    final options = <_Option>[
      if (_currentPage == 0) ..._goals,
      if (_currentPage == 1) ..._dietaryRequirements,
      if (_currentPage == 2) ..._activityLevels,
      if (_currentPage == 3) ..._genders,
      if (_currentPage == 4) ..._femalePlans,
      if (_currentPage == 8) ..._weeklyGoals,
    ];

    return ListView.builder(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      itemCount: options.length,
      itemBuilder: (context, index) {
        final option = options[index];
        final selected = _isSelected(option);
        return Padding(
          padding: const EdgeInsets.symmetric(vertical: 5),
          child: ListTile(
            onTap: () => _select(option),
            tileColor:
                selected ? ColorManager.secondry : ColorManager.greylightColor,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(14),
            ),
            title: Text(
              option.label,
              style: getboldStyle(
                color: selected
                    ? ColorManager.whiteColor
                    : ColorManager.blackColor,
              ),
            ),
            trailing: selected
                ? Icon(Icons.check, color: ColorManager.whiteColor)
                : null,
          ),
        );
      },
    );
  }

  Widget _numberField(
    TextEditingController controller,
    String label,
    String suffix,
  ) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24),
      child: TextField(
        controller: controller,
        keyboardType: TextInputType.number,
        decoration: InputDecoration(
          labelText: label,
          suffixText: suffix,
          border: const OutlineInputBorder(),
        ),
      ),
    );
  }

  bool _isSelected(_Option option) {
    if (_currentPage == 0) return _goal == option.id;
    if (_currentPage == 1) return _dietary == option.id;
    if (_currentPage == 2) return _active == option.id;
    if (_currentPage == 3) return _gender == option.id;
    if (_currentPage == 4) return _femaleSpecificPlan == option.id;
    return _weekGoals == option.value;
  }

  void _select(_Option option) {
    setState(() {
      if (_currentPage == 0) _goal = option.id;
      if (_currentPage == 1) _dietary = option.id;
      if (_currentPage == 2) _active = option.id;
      if (_currentPage == 3) _gender = option.id;
      if (_currentPage == 4) _femaleSpecificPlan = option.id;
      if (_currentPage == 8) _weekGoals = option.value!;
      _errorMessage = null;
    });
  }

  static const List<String> _titles = [
    'What is your goal?',
    'What are your dietary requirements?',
    'How active are you?',
    'What gender do you identify as?',
    'Do you want a female-specific plan?',
    'How old are you?',
    'What is your height?',
    'What is your weight?',
    'What is your weekly goal?',
  ];
}

class _Option {
  final int id;
  final String label;
  final String? value;

  const _Option(this.id, this.label, {this.value});
}
