import 'dart:async';
import 'package:fitopia/widgets/background_image_widget.dart';
import 'package:flutter/material.dart';
import 'package:get_storage/get_storage.dart';
import '../resources/index_manager.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({Key? key}) : super(key: key);

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  Timer? _timer;

  _startDelay() {
    _timer = Timer(Duration(seconds: 3), _goNext);
  }

  _goNext() {
    final token = GetStorage().read<String>('api_token');
    Navigator.pushReplacementNamed(
      context,
      token != null && token.isNotEmpty
          ? Routes.HomePageRoute
          : Routes.loginRoute,
    );
  }

  @override
  void initState() {
    super.initState();
    _startDelay();
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => BackgroundImage(
          child: Scaffold(
        backgroundColor: Colors.transparent,
        body: Center(
          child: Image.asset(
            ImageAssets.appPngLogo,
            //appLogo,
            height: 150,
            width: 150,
          ),
        ),
      ));
}
