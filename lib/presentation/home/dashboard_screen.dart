import 'package:flutter/material.dart';
import 'package:flutter/gestures.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:fitopia/model/deshboard_model.dart';
import 'package:fitopia/model/dashboard_nutrition_model.dart';
import 'package:fitopia/data/api/api_client.dart';
import 'package:fitopia/data/repository/dashboard_repo.dart';
import 'package:fitopia/model/dashboard_content_model.dart';
import 'package:fitopia/translations/locale_keys.g.dart';
import 'package:fitopia/widgets/line_cahrt_sample7.dart';
import 'package:fitopia/widgets/products_card_widgets.dart';
import 'package:fitopia/widgets/week_days_list.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:fitopia/presentation/Mixins/size.dart';
import 'package:percent_indicator/percent_indicator.dart';
import 'package:responsive_sizer/responsive_sizer.dart';
import 'package:smooth_page_indicator/smooth_page_indicator.dart';
import '../resources/index_manager.dart';

class DashboardView extends StatefulWidget {
  const DashboardView({super.key});

  @override
  State<DashboardView> createState() => _DashboardViewState();
}

class _DashboardViewState extends State<DashboardView> {
  final PageController _controller = PageController(initialPage: 0);
  final DashboardRepo _dashboardRepo = DashboardRepo(apiClient: ApiClient());
  int selectedIndex = DateTime.now().weekday % 7;
  DashboardNutrition? _nutrition;
  String? _nutritionError;
  DashboardContent? _content;
  String? _contentError;
  DashboardWeeklyCalories? _weeklyCalories;
  final Set<int> _loggedMealIds = <int>{};
  final Set<int> _loggingMealIds = <int>{};
  bool _redirectingToLogin = false;
  bool _selectedDayLoading = true;

  @override
  void initState() {
    super.initState();
    _loadNutrition();
    _loadSelectedDay();
    _loadWeeklyCalories();
  }

  Future<void> _loadSelectedDay() async {
    setState(() {
      _selectedDayLoading = true;
      _content = null;
      _loggedMealIds.clear();
    });

    await Future.wait<void>([
      _loadContent(selectedDate: _selectedDate),
      _loadLoggedMeals(),
    ]);

    if (mounted) {
      setState(() {
        _selectedDayLoading = false;
      });
    }
  }

  Future<void> _loadNutrition() async {
    try {
      final nutrition = await _dashboardRepo.getNutrition();
      if (!mounted) {
        return;
      }

      setState(() {
        _nutrition = nutrition;
        _nutritionError = null;
      });
    } on ApiException catch (error) {
      _redirectIfSessionExpired(error);
      if (!mounted) {
        return;
      }

      setState(() {
        _nutritionError = error.message;
      });
    }
  }

  Future<void> _loadContent({DateTime? selectedDate}) async {
    try {
      final content =
          await _dashboardRepo.getContent(selectedDate: selectedDate);
      if (!mounted) {
        return;
      }

      setState(() {
        _content = content;
        _contentError = null;
        _loggedMealIds
          ..removeWhere(
            (id) => !content.meals.any((meal) => meal.id == id && meal.logged),
          )
          ..addAll(
            content.meals.where((meal) => meal.logged).map((meal) => meal.id),
          );
      });
    } on ApiException catch (error) {
      _redirectIfSessionExpired(error);
      if (!mounted) {
        return;
      }

      setState(() {
        _contentError = error.message;
      });
    }
  }

  Future<void> _loadWeeklyCalories() async {
    try {
      final weeklyCalories = await _dashboardRepo.getWeeklyCalories();
      if (!mounted) {
        return;
      }

      setState(() {
        _weeklyCalories = weeklyCalories;
      });
    } on ApiException catch (error) {
      _redirectIfSessionExpired(error);
      if (!mounted) {
        return;
      }

      setState(() {
        _weeklyCalories = const DashboardWeeklyCalories(
          values: [0, 0, 0, 0, 0, 0, 0],
          labels: ['', '', '', '', '', '', ''],
        );
      });
    }
  }

  void _redirectIfSessionExpired(ApiException error) {
    if (error.statusCode != 401 || _redirectingToLogin || !mounted) {
      return;
    }

    _redirectingToLogin = true;
    Navigator.pushNamedAndRemoveUntil(
      context,
      Routes.loginRoute,
      (route) => false,
    );
  }

  Future<void> _toggleMeal(DashboardMeal meal) async {
    if (meal.id == 0 || _loggingMealIds.contains(meal.id)) {
      return;
    }

    setState(() {
      _loggingMealIds.add(meal.id);
    });

    try {
      final wasLogged = _loggedMealIds.contains(meal.id);
      await _dashboardRepo.toggleMeal(meal);
      if (!mounted) {
        return;
      }

      setState(() {
        _loggingMealIds.remove(meal.id);
        if (wasLogged) {
          _loggedMealIds.remove(meal.id);
        } else {
          _loggedMealIds.add(meal.id);
        }
      });

      await Future.wait<void>([
        _loadNutrition(),
        _loadWeeklyCalories(),
      ]);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            wasLogged
                ? '${meal.title} marked as not eaten.'
                : '${meal.title} marked as eaten.',
          ),
        ),
      );
    } on ApiException catch (error) {
      _redirectIfSessionExpired(error);
      if (!mounted) {
        return;
      }
      setState(() {
        _loggingMealIds.remove(meal.id);
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(error.message)),
      );
    }
  }

  Future<void> _toggleWorkout(DashboardWorkout workout) async {
    try {
      await _dashboardRepo.toggleWorkout(workout);
      await _loadContent(selectedDate: _selectedDate);
      if (!mounted) {
        return;
      }
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            workout.completed
                ? 'Workout completion was undone.'
                : 'Workout marked as completed.',
          ),
        ),
      );
    } on ApiException catch (error) {
      _redirectIfSessionExpired(error);
      if (!mounted) {
        return;
      }
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(error.message)),
      );
    }
  }

  Future<void> _loadLoggedMeals() async {
    try {
      final loggedMealIds =
          await _dashboardRepo.getLoggedMealIds(_selectedDate);
      if (!mounted) {
        return;
      }

      setState(() {
        _loggedMealIds
          ..clear()
          ..addAll(loggedMealIds);
      });
    } on ApiException {
      // The meal list remains usable if the optional status lookup fails.
    }
  }

  List<weekDaysModel> get _currentWeekDays {
    final today = DateTime.now();
    final sunday = today.subtract(Duration(days: today.weekday % 7));
    const labels = ['S', 'M', 'T', 'W', 'T', 'F', 'S'];

    return List<weekDaysModel>.generate(7, (index) {
      final date = sunday.add(Duration(days: index));
      return weekDaysModel(
        id: index,
        day: labels[index],
        date: date.day.toString(),
      );
    });
  }

  DateTime get _selectedDate {
    final today = DateTime.now();
    final sunday = DateTime(
      today.year,
      today.month,
      today.day - (today.weekday % 7),
    );
    return sunday.add(Duration(days: selectedIndex));
  }

  bool get _isSelectedDateToday {
    final today = DateTime.now();
    final selectedDate = _selectedDate;
    return selectedDate.year == today.year &&
        selectedDate.month == today.month &&
        selectedDate.day == today.day;
  }

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      SizedBox(height: 30.vs),

      // AnimatedContainer(
      //   width: double.infinity,
      //   height: 56.0, //double.maxFinite,
      //   duration: Duration(
      //       milliseconds:
      //           1500), //animationDuration,// Duration(milliseconds: 1500);
      //   child: SizedBox(
      //     width: 48.0, //itemWidth
      //     height: 48.0 - 20, //itemHeight,
      //     child: Stack(
      //       clipBehavior: Clip.none,
      //       children: <Widget>[
      //         Positioned(
      //           top: -20, // double topOffset = isSelected ? -20 : -10;
      //           left: -48.0 / 2,
      //           right: -48.0 / 2,
      //           child: Column(
      //             crossAxisAlignment: CrossAxisAlignment.center,
      //             children: <Widget>[
      //               SizedBox(
      //                   height:
      //                       0), //double iconTopSpacer = isSelected ? 0 : 2; //double shadowTopSpacer = 4;

      //               _makeIconArea(48.0, Icons.close), // iconAreaWidget,
      //               //labelWidget,
      //               // SizedBox(height: shadowTopSpacer),
      //               //shadowWidget,
      //             ],
      //           ),
      //         ),
      //       ],
      //     ),
      //   ),
      // ),

      UserNotification(),
      if (_nutritionError != null)
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12.0),
          child: Row(
            children: [
              Expanded(
                child: Text(
                  _nutritionError!,
                  style: TextStyle(color: Colors.red, fontSize: 12.mv),
                ),
              ),
              TextButton(
                onPressed: _loadNutrition,
                child: const Text('Retry'),
              ),
            ],
          ),
        ),
      //SizedBox(height: 15.0),
      linegraph(),

      weekdaysWidget(_currentWeekDays),
      //progressbar(),
      //dotIndicator(),
      Padding(
        padding: const EdgeInsets.all(8.0),
        child: Text("Today's Workout",
            //LocaleKeys.Products.tr(),
            style: getboldStyle(
                color: Theme.of(context).textTheme.bodyText1!.color!,
                fontSize: 16.mv)),
      ),
      todayWorkout(),
      SizedBox(height: 15.0),
      Padding(
        padding: const EdgeInsets.symmetric(horizontal: 8.0),
        child: Text("Today's Meals",
            //LocaleKeys.Products.tr(),
            style: getboldStyle(
                color: Theme.of(context).textTheme.bodyText1!.color!,
                fontSize: 16.mv)),
      ),

      todayMeals(),
      SizedBox(height: 10.0),
      SizedBox(
        height: 30.h,
        child: PageView(
          scrollDirection: Axis.horizontal,
          controller: _controller,
          children: List.generate(
            4,
            ((index) {
              return index == 0
                  ? calories()
                  : index == 1
                      ? Macros()
                      : index == 2
                          ? progressbar(
                              LocaleKeys.LowCarb.tr(),
                              LocaleKeys.Carbohydrates.tr(),
                              "60/260g",
                              LocaleKeys.Sugar.tr(),
                              "55/260g",
                              LocaleKeys.Fiber.tr(),
                              "25/38g")
                          : index == 3
                              ? progressbar("Heart Healthy", "Fat", "0/68g",
                                  "Sodium", "0/2300mg", "Choesterol", "0/300mg")
                              : SizedBox();
            }),
          ),
        ),
      ),

      // dotIndicator(),
      dotIndicatorWidget(),

      //ProducsWidget(),
      //dotIndicator1(),

      SizedBox(height: 30.0),
    ]));
  }

  Widget _makeIconArea(double itemWidth, IconData iconData) {
    bool isSelected = true; //_isItemSelected();
    double radius = itemWidth / 2;
    double innerBoxSize = itemWidth - 8;
    double innerRadius = (itemWidth - 8) / 2 - 4;

    return CircleAvatar(
      radius: isSelected ? radius : radius * 0.7,
      backgroundColor: Colors.black, //_getBorderColor(isSelected),
      child: SizedBox(
        width: innerBoxSize,
        height: isSelected ? innerBoxSize : innerBoxSize / 2,
        child: CircleAvatar(
          radius: innerRadius,
          backgroundColor: Colors.red,
          //  isSelected
          //     ? selectedBackgroundColor ?? theme.selectedItemBackgroundColor
          //     : theme.unselectedItemBackgroundColor,
          child: Icon(
            iconData,
            color: Colors.green,
          ), //_makeIcon(iconData),
        ),
      ),
    );
  }

  Widget todayWorkout() {
    if (_selectedDayLoading) {
      return const Center(
        child: Padding(
          padding: EdgeInsets.all(16.0),
          child: CircularProgressIndicator(),
        ),
      );
    }

    final workout = _content?.workout;
    if (workout == null) {
      return _contentError == null
          ? const SizedBox.shrink()
          : _contentMessage(_contentError!, _loadContent);
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.end,
      children: [
        ProductCardWidget(
          index: 0,
          title: workout.type.isEmpty
              ? (workout.level.isEmpty ? 'Workout' : workout.level)
              : workout.type,
          subtile: workout.title,
          des: workout.description,
          imagepath: ImageAssets.workoutImage1,
        ),
        TextButton.icon(
          onPressed: workout.assignmentId == null || !_isSelectedDateToday
              ? null
              : () => _toggleWorkout(workout),
          icon: Icon(
            workout.completed ? Icons.undo : Icons.check_circle_outline,
          ),
          label: Text(
            workout.completed
                ? 'Undo complete'
                : workout.assignmentId == null
                    ? 'Unavailable'
                    : 'Mark complete',
          ),
        ),
      ],
    );
  }

  Widget todayMeals() {
    if (_selectedDayLoading) {
      return const Center(
        child: Padding(
          padding: EdgeInsets.all(16.0),
          child: CircularProgressIndicator(),
        ),
      );
    }

    final meals = _content?.meals ?? const <DashboardMeal>[];
    if (_content == null) {
      return _contentError == null
          ? const SizedBox.shrink()
          : _contentMessage(_contentError!, _loadContent);
    }

    if (meals.isEmpty) {
      return const Padding(
        padding: EdgeInsets.all(8.0),
        child: Text('No assigned meals yet.'),
      );
    }

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 7.0),
      child: ListView.builder(
        // scrollDirection: Axis.vertical,
        itemCount: meals.length,
        shrinkWrap: true,
        physics: NeverScrollableScrollPhysics(),
        itemBuilder: (context, index) {
          final meal = meals[index];
          return Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              ProductCardWidget(
                index: index,
                title: meal.category,
                subtile: meal.title,
                des: _mealDescription(meal),
                imagepath: _mealImage(index),
              ),
              TextButton.icon(
                onPressed: _selectedDayLoading ||
                        !_isSelectedDateToday ||
                        _loggingMealIds.contains(meal.id)
                    ? null
                    : () => _toggleMeal(meal),
                icon: Icon(
                  _loggedMealIds.contains(meal.id)
                      ? Icons.undo
                      : Icons.check_circle_outline,
                ),
                label: Text(
                  _loggedMealIds.contains(meal.id)
                      ? 'Undo eaten'
                      : _selectedDayLoading
                          ? 'Loading...'
                          : !_isSelectedDateToday
                              ? 'Available today'
                              : _loggingMealIds.contains(meal.id)
                                  ? 'Saving...'
                                  : 'Mark as eaten',
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _contentMessage(String message, VoidCallback retry) {
    return Padding(
      padding: const EdgeInsets.all(8.0),
      child: Row(
        children: [
          Expanded(child: Text(message)),
          TextButton(onPressed: retry, child: const Text('Retry')),
        ],
      ),
    );
  }

  String _mealImage(int index) {
    const images = [
      ImageAssets.mealsImage1,
      ImageAssets.mealsImage2,
      ImageAssets.mealsImage3,
      ImageAssets.mealsImage4,
    ];
    return images[index % images.length];
  }

  String _mealDescription(DashboardMeal meal) {
    if (meal.duration.isEmpty) {
      return meal.description;
    }
    if (meal.description.isEmpty) {
      return meal.duration;
    }

    return '${meal.duration}, ${meal.description}';
  }

  Widget calories() {
    return Padding(
        padding: const EdgeInsets.symmetric(horizontal: 8.0, vertical: 5.0),
        child: Container(
            decoration: BoxDecoration(
                color: ColorManager.greyBoxColor,
                //  border: Border.all(color: Colors.grey),
                borderRadius: BorderRadius.circular(15.0)),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Padding(
                  padding: const EdgeInsets.all(8.0),
                  child: Text("Calories",
                      style: getboldStyle(
                          color: Theme.of(context).textTheme.bodyText1!.color!,
                          fontSize: 16.mv)),
                ),
                Padding(
                  padding: const EdgeInsets.only(top: 5.0, left: 10.0),
                  child: Text("Remaining = Goal - Food + Exercise ",
                      style: getRegularStyle(
                          color: Theme.of(context).textTheme.bodyText1!.color!,
                          fontSize: 12.mv)),
                ),
                SizedBox(height: 10.0),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    circleWidget(
                        _formatNumber(_nutrition?.calories.remaining ?? 0),
                        "Remaining",
                        110,
                        110),
                    Padding(
                      padding: const EdgeInsets.only(right: 20.0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          listTile(ImageAssets.BaseGoalIcon, "Base Goal",
                              _formatNumber(_nutrition?.calories.goal ?? 0)),
                          listTile(ImageAssets.foodIcon, "Food",
                              _formatNumber(_foodCalories)),
                          listTile(ImageAssets.ExerciseIcon, "Exercise", "0"),
                        ],
                      ),
                    ),
                  ],
                ),
              ],
            )));
  }

  Widget Macros() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 8.0, vertical: 5.0),
      child: Container(
        decoration: BoxDecoration(
            color: ColorManager.greyBoxColor,
            // border: Border.all(color: Colors.grey),
            borderRadius: BorderRadius.circular(15.0)),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            SizedBox(height: 10.0),
            Padding(
              padding: const EdgeInsets.all(8.0),
              child: Text("Macros",
                  style: getboldStyle(
                      color: Theme.of(context).textTheme.bodyText1!.color!,
                      fontSize: 16.mv)),
            ),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    Text("Carbohydrates",
                        style: getRegularStyle(
                            color:
                                Theme.of(context).textTheme.bodyText1!.color!,
                            fontSize: 14.mv)),
                    SizedBox(height: 10.0),
                    circleWidget(_formatNumber(_macroAmount('Carbs')),
                        "/${_formatNumber(_macroGoal('Carbs'))}g", 100, 100),
                  ],
                ),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    Text("Fat",
                        style: getRegularStyle(
                            color:
                                Theme.of(context).textTheme.bodyText1!.color!,
                            fontSize: 14.mv)),
                    SizedBox(height: 10.0),
                    circleWidget(_formatNumber(_macroAmount('Fats')),
                        "/${_formatNumber(_macroGoal('Fats'))}g", 100, 100),
                  ],
                ),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    Text("Protein",
                        style: getRegularStyle(
                            color:
                                Theme.of(context).textTheme.bodyText1!.color!,
                            fontSize: 14.mv)),
                    SizedBox(height: 10.0),
                    circleWidget(_formatNumber(_macroAmount('Protein')),
                        "/${_formatNumber(_macroGoal('Protein'))}g", 100, 100),
                  ],
                ),
              ],
            ),
            SizedBox(height: 10.0),
          ],
        ),
      ),
    );
  }

  double get _foodCalories => _nutrition?.macro('Calories')?.amount ?? 0;

  double _macroAmount(String name) => _nutrition?.macro(name)?.amount ?? 0;

  double _macroGoal(String name) => _nutrition?.macro(name)?.goal ?? 0;

  String _formatNumber(double value) {
    return value == value.roundToDouble()
        ? value.toInt().toString()
        : value.toStringAsFixed(1);
  }

  Widget circleWidget(
      String title, String subtitle, double height, double widget) {
    return Padding(
      padding: const EdgeInsets.only(left: 15.0, bottom: 15.0),
      child: Container(
        height: height,
        width: widget,
        decoration: BoxDecoration(
            border: Border.all(color: ColorManager.greyBorderColor, width: 5.0),
            shape: BoxShape.circle),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(title, //"2050",
                style: getboldStyle(
                    color: Theme.of(context).textTheme.bodyText1!.color!,
                    fontSize: 18.mv)),
            Text(subtitle, //,
                style: getRegularStyle(
                    color: Theme.of(context).textTheme.bodyText1!.color!,
                    fontSize: 14.mv)),
          ],
        ),
      ),
    );
  }

  Widget listTile(String iconPath, String title, String subtitl) {
    return Padding(
      padding: const EdgeInsets.all(8.0),
      child: Container(
        child: Row(children: [
          SvgPicture.asset(
            iconPath,
          ),
          SizedBox(width: 10.0),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(title,
                  style: getboldStyle(
                      color: Theme.of(context).textTheme.bodyText1!.color!,
                      fontSize: 12.mv)),
              Text(subtitl,
                  style: getRegularStyle(
                      color: Theme.of(context).textTheme.bodyText1!.color!,
                      fontSize: 12.mv)),
            ],
          )
        ]),
      ),
    );
  }

  Widget weekdaysWidget(List<weekDaysModel>? itemList) {
    return WeekDaysToggleButtonsList(
      selected: selectedIndex,
      callback: (int index) {
        setState(() {
          selectedIndex = index;
        });
        _loadSelectedDay();
      },
      list: itemList,
    );
  }

  Widget UserNotification() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 12.0, vertical: 8.0),
      child: Row(
        children: [
          SvgPicture.asset(ImageAssets.userCircleIcon,
              color: ColorManager.greyColor),
          textspan(
            text1: "Hi ",
            text2: "Steve",
            context: context,
          ),
          Spacer(),
          SvgPicture.asset(
            ImageAssets.bellIcon,
            color: ColorManager.greyColor,
            height: 20,
            width: 20,
          ),
        ],
      ),
    );
  }

  Widget textspan(
      {String? text1,
      String? text2,
      BuildContext? context,
      Function()? onTap}) {
    return Container(
      padding: EdgeInsets.symmetric(
          horizontal: AppPadding.p14, vertical: AppPadding.p20),
      child: RichText(
        textAlign: TextAlign.center,
        text: TextSpan(
          text: text1,
          style: getboldStyle(
              color: Theme.of(context!).textTheme.bodyText1!.color!,
              fontSize: AppSize.s14.mv),
          children: <TextSpan>[
            TextSpan(
                text: text2,
                style: TextStyle(
                    //decoration: TextDecoration.underline,
                    color: ColorManager.primary,
                    fontFamily: FontConstants.fontFamily,
                    fontWeight: FontWeightManager.bold,
                    fontSize: AppSize.s14.mv),
                recognizer: TapGestureRecognizer()..onTap = onTap)
          ],
        ),
      ),
    );
  }

  Widget dotIndicatorWidget() {
    return Align(
      alignment: Alignment.center,
      child: SmoothPageIndicator(
          controller: _controller,
          count: 4,
          // effect: SlideEffect,
          effect: SlideEffect(
            spacing: 8.0,
            radius: 10.0,
            dotWidth: 10.0,
            dotHeight: 10.0,
            paintStyle: PaintingStyle.fill,
            strokeWidth: 1.5,
            activeDotColor: ColorManager.secondry,
          )),
    );
  }

  Widget progressbar(String heading, String p1Title, String p1value,
      String p2Title, String p2value, String p3Title, String p3value) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 8.0, vertical: 5.0),
      child: Container(
        decoration: BoxDecoration(
            color: ColorManager.greyBoxColor,
            // border: Border.all(color: Colors.grey),
            borderRadius: BorderRadius.circular(15.0)),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.all(8.0),
              child: Text(heading, //
                  style: getboldStyle(
                      color: Theme.of(context).textTheme.bodyText1!.color!,
                      fontSize: 16.mv)),
            ),
            Padding(
              padding: EdgeInsets.symmetric(vertical: 5.0, horizontal: 10.0),
              child: Column(
                children: [
                  Column(
                    children: [
                      titleOfProgressBar(p1Title, p1value),
                      LinearPercentIndicator(
                          barRadius: const Radius.circular(20.0),
                          animation: true,
                          lineHeight: 12.0,
                          animationDuration: 2000,
                          percent: 0.2,
                          progressColor: ColorManager.secondry),
                    ],
                  ),
                  SizedBox(height: 10.0),
                  Column(
                    children: [
                      titleOfProgressBar(p2Title, p2value),
                      LinearPercentIndicator(
                          barRadius: const Radius.circular(20.0),
                          animation: true,
                          lineHeight: 12.0,
                          animationDuration: 2000,
                          percent: 0.7,
                          progressColor: ColorManager.secondry),
                    ],
                  ),
                  SizedBox(height: 10.0),
                  Column(
                    children: [
                      titleOfProgressBar(p3Title, p3value),
                      LinearPercentIndicator(
                          barRadius: const Radius.circular(20.0),
                          animation: true,
                          lineHeight: 12.0,
                          animationDuration: 2000,
                          percent: 0.3,
                          progressColor: ColorManager.secondry),
                    ],
                  ),
                  // Padding(
                  //   padding: const EdgeInsets.symmetric(
                  //       horizontal: 10.0, vertical: 2.0),
                  //   child: Row(
                  //     mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  //     children: const [
                  //       Text("0", style: TextStyle(color: Colors.grey)),
                  //       Text("5", style: TextStyle(color: Colors.grey)),
                  //       Text("10", style: TextStyle(color: Colors.grey)),
                  //       Text("15", style: TextStyle(color: Colors.grey)),
                  //     ],
                  //   ),
                  // ),
                ],
              ),
            ),
            SizedBox(height: 10.0),
          ],
        ),
      ),
    );
  }

  Widget titleOfProgressBar(String title, String subtitle) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 8.0, vertical: 4.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(title,
              style: getRegularStyle(
                  color: Theme.of(context).textTheme.bodyText1!.color!,
                  fontSize: 12.mv)),
          Text(
            subtitle,
            style: getRegularStyle(
                color: Theme.of(context).textTheme.bodyText1!.color!,
                fontSize: 12.mv),
          ),
        ],
      ),
    );
  }

/*
  Widget dotIndicator1() {
    return Align(
      alignment: Alignment.center,
      child: DotsIndicator(
        mainAxisAlignment: MainAxisAlignment.center,
        dotsCount: 2,
        position: 0.0, //selectedPage.toDouble(),
        decorator: DotsDecorator(
          size: Size.square(10.0),
          color: Colors.grey, // Inactive color
          activeColor: ColorManager.secondry,
        ),
      ),
    );
  }

  Widget listTile(String title, String subtitle) {
    return ListTile(
      title: Text(title,
          style: getboldStyle(
              color: Theme.of(context).textTheme.bodyText1!.color!,
              fontSize: 16.mv)),
      subtitle: Padding(
        padding: const EdgeInsets.only(top: 5.0),
        child: Text(
          subtitle,
          style: TextStyle(
            color: Theme.of(context).textTheme.bodyText1!.color!,
          ),
        ),
      ),
    );
  }

  Widget ProducsWidget() {
    return SizedBox(
      height: 120,
      child: ListView.separated(
          itemCount: HomeProductsList.length,
          scrollDirection: Axis.horizontal,
          separatorBuilder: ((context, index) => SizedBox(
                width: 10.0,
              )),
          itemBuilder: ((context, index) {
            return Padding(
              padding: EdgeInsets.only(left: index == 0 ? 10 : 0.0),
              child: Container(
                decoration: BoxDecoration(
                    color: ColorManager.whiteColor,
                    border: Border.all(color: Colors.grey),
                    borderRadius: BorderRadius.circular(15.0)),
                child: Padding(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 15.0, vertical: 8.0),
                  child: Column(
                    children: [
                      Image.asset(
                        HomeProductsList[index].imagePath!,
                        height: 70,
                        width: 70,
                      ),
                      SizedBox(height: 4.0),
                      Text(HomeProductsList[index].title!,
                          style: getmediumStyle(
                              color:
                                  Theme.of(context).textTheme.bodyText1!.color!,
                              fontSize: 12.mv)),
                    ],
                  ),
                ),
              ),
            );
          })),
    );
  }
*/
  Widget linegraph() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 8.0),
      child: Container(
        decoration: BoxDecoration(
            color: ColorManager.whiteColor,
            // border: Border.all(color: Colors.grey),
            borderRadius: BorderRadius.circular(15.0)),
        child: Column(
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Padding(
                  padding: const EdgeInsets.all(8.0),
                  child: SvgPicture.asset(ImageAssets.arrowBack),
                ),
                Padding(
                  padding: const EdgeInsets.all(8.0),
                  child: Column(
                    children: [
                      Padding(
                        padding: const EdgeInsets.fromLTRB(8.0, 8.0, 0.0, 5.0),
                        child: Text("Week View",
                            style: getRegularStyle(
                                color: Theme.of(context)
                                    .textTheme
                                    .bodyText1!
                                    .color!,
                                fontSize: 10.mv)),
                      ),
                      Padding(
                        padding: const EdgeInsets.only(left: 12.0),
                        child: Text(
                          "Last 7 Days",
                          style: getboldStyle(
                              color:
                                  Theme.of(context).textTheme.bodyText1!.color!,
                              fontSize: 14.mv),
                        ),
                      ),
                    ],
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.all(8.0),
                  child: SvgPicture.asset(ImageAssets.arrowForward),
                ),
              ],
            ),
            Container(
              height: 200,
              child: Padding(
                padding: const EdgeInsets.only(
                    bottom: 30.0, left: 8.0, right: 8.0, top: 8.0),
                child: LineChartSample7(
                  betweenColor: Colors.transparent,
                  line2Color: Colors.transparent,
                  line1Color: ColorManager.graphLineColor,
                  values: _weeklyCalories?.values ?? const [],
                  labels: _weeklyCalories?.labels ?? const [],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
