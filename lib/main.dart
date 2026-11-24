import 'dart:async';

import 'package:easy_localization/easy_localization.dart';
import 'package:fitopia/translations/codegen_loader.g.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get_storage/get_storage.dart';
import 'app/app.dart';
import 'data/notifications/push_notification_service.dart';

//late List<CameraDescription> _cameras;
void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await EasyLocalization.ensureInitialized();
  await GetStorage.init();
  unawaited(PushNotificationService.instance.initialize());
  // WidgetsFlutterBinding.ensureInitialized();
  SystemChrome.setPreferredOrientations(
      [DeviceOrientation.portraitUp, DeviceOrientation.portraitDown]);
  WidgetsFlutterBinding.ensureInitialized();
  runApp(EasyLocalization(
      path: 'assets/translations',
      supportedLocales: const [
        Locale('en'),
        Locale('ar'),
      ],
      fallbackLocale: const Locale('en'),
      saveLocale: true,
      assetLoader: const CodegenLoader(),
      child: MyApp()));
}
