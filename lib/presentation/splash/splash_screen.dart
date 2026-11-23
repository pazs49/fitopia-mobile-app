import 'dart:async';
import 'package:fitopia/data/api/api_client.dart';
import 'package:fitopia/data/repository/onboarding_repo.dart';
import 'package:fitopia/data/repository/subscription_repo.dart';
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
  final SubscriptionRepo _subscriptionRepo =
      SubscriptionRepo(apiClient: ApiClient());
  final OnboardingRepo _onboardingRepo =
      OnboardingRepo(apiClient: ApiClient());
  String? _errorMessage;
  bool _isChecking = false;

  _startDelay() {
    _timer = Timer(const Duration(seconds: 3), _goNext);
  }

  Future<void> _goNext() async {
    if (_isChecking) {
      return;
    }

    final token = GetStorage().read<String>('api_token');
    if (token == null || token.isEmpty) {
      _navigateTo(Routes.loginRoute);
      return;
    }

    setState(() {
      _isChecking = true;
      _errorMessage = null;
    });

    try {
      final hasActiveSubscription =
          await _subscriptionRepo.hasActiveSubscription();
      if (!mounted) {
        return;
      }

      if (!hasActiveSubscription) {
        _navigateTo(Routes.subscriptionViewPageRoute);
        return;
      }

      final hasCompletedOnboarding =
          await _onboardingRepo.hasCompletedOnboarding();
      if (!mounted) {
        return;
      }

      _navigateTo(
        hasCompletedOnboarding
            ? Routes.HomePageRoute
            : Routes.Onboarding1Route,
      );
    } on ApiException catch (error) {
      if (!mounted) {
        return;
      }

      if (error.statusCode == 401) {
        _navigateTo(Routes.loginRoute);
        return;
      }

      setState(() {
        _errorMessage = error.message;
        _isChecking = false;
      });
    }
  }

  void _navigateTo(String route) {
    if (mounted) {
      Navigator.pushReplacementNamed(context, route);
    }
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
            child: _errorMessage == null
                ? Image.asset(
                    ImageAssets.appPngLogo,
                    height: 150,
                    width: 150,
                  )
                : Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Image.asset(
                        ImageAssets.appPngLogo,
                        height: 120,
                        width: 120,
                      ),
                      const SizedBox(height: 24),
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 24),
                        child: Text(
                          _errorMessage!,
                          textAlign: TextAlign.center,
                        ),
                      ),
                      const SizedBox(height: 16),
                      ElevatedButton(
                        onPressed: _isChecking ? null : _goNext,
                        child: Text(_isChecking ? 'Checking...' : 'Retry'),
                      ),
                    ],
                  ),
          ),
        ),
      );
}
