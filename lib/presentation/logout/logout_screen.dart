import 'package:fitopia/controller/auth_controller.dart';
import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';

import '../resources/index_manager.dart';

class LogoutView extends StatefulWidget {
  const LogoutView({super.key});

  @override
  State<LogoutView> createState() => _LogoutViewState();
}

class _LogoutViewState extends State<LogoutView> {
  bool _isLoggingOut = false;

  Future<void> _logout() async {
    if (_isLoggingOut) {
      return;
    }

    setState(() {
      _isLoggingOut = true;
    });

    final error = await AuthController().logout();
    if (!mounted) {
      return;
    }

    Navigator.pushNamedAndRemoveUntil(
      context,
      Routes.loginRoute,
      (route) => false,
    );

    if (error != null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Local logout completed: $error')),
      );
    }
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
          'Logout',
          style: getboldStyle(
            color: ColorManager.blackColor,
            fontSize: AppSize.s16,
          ),
        ),
      ),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: _isLoggingOut ? null : _logout,
              child: Text(_isLoggingOut ? 'Logging out...' : 'Logout'),
            ),
          ),
        ),
      ),
    );
  }
}
