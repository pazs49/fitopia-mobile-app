import 'dart:async';
import 'dart:developer' as developer;

import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:fitopia/data/api/api_client.dart';
import 'package:flutter_native_timezone/flutter_native_timezone.dart';
import 'package:get_storage/get_storage.dart';

Future<void> firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  await Firebase.initializeApp();
}

class PushNotificationService {
  PushNotificationService._();

  static final PushNotificationService instance = PushNotificationService._();
  final ApiClient _apiClient = ApiClient();
  StreamSubscription<String>? _tokenSubscription;
  Future<void>? _initialization;

  FirebaseMessaging get _messaging => FirebaseMessaging.instance;

  Future<void> initialize() {
    final initialization = _initializeFirebase();
    _initialization = initialization;
    return initialization;
  }

  Future<void> _initializeFirebase() async {
    _log('Firebase initialization started.');
    try {
      await Firebase.initializeApp();
    } catch (error, stackTrace) {
      developer.log(
        'Firebase initialization failed.',
        name: 'PushNotificationService',
        error: error,
        stackTrace: stackTrace,
      );
      return;
    }

    _log('Firebase initialization completed.');
    FirebaseMessaging.onBackgroundMessage(firebaseMessagingBackgroundHandler);
    unawaited(requestPermissionAndSyncToken());
  }

  Future<void> requestPermissionAndSyncToken() async {
    try {
      await _messaging.requestPermission(
        alert: true,
        badge: true,
        sound: true,
      );

      await syncToken();
      await _tokenSubscription?.cancel();
      _tokenSubscription = _messaging.onTokenRefresh.listen((token) {
        _saveToken(token);
      });
    } catch (error, stackTrace) {
      developer.log(
        'Push notification setup failed.',
        name: 'PushNotificationService',
        error: error,
        stackTrace: stackTrace,
      );
    }
  }

  Future<void> syncToken() async {
    try {
      _log('Starting Firebase device-token synchronization.');
      final initialization = _initialization;
      if (initialization != null) {
        await initialization;
      }

      final token = await _messaging.getToken();
      if (token != null && token.isNotEmpty) {
        await _saveToken(token);
      } else {
        _log('Firebase did not provide a device token.');
      }
    } catch (error, stackTrace) {
      _log(
        'Unable to retrieve the Firebase device token: $error\n$stackTrace',
      );
    }
  }

  Future<void> _saveToken(String token) async {
    final accessToken = GetStorage().read<String>('api_token');
    if (accessToken == null || accessToken.isEmpty) {
      _log(
        'Skipping Firebase token registration because no authenticated session is stored.',
      );
      return;
    }

    try {
      final timezone = await _getDeviceTimezone();
      final payload = <String, dynamic>{
        'fcm_token': token,
      };
      if (timezone != null && timezone.isNotEmpty) {
        payload['timezone'] = timezone;
      }

      await _apiClient.postAuthenticatedData(
        'api/devicetoken',
        payload,
      );
      _log('Firebase device token registered with the API.');
    } on ApiException catch (error) {
      _log('Unable to register the push token: ${error.message}');
    }
  }

  Future<String?> _getDeviceTimezone() async {
    try {
      return await FlutterNativeTimezone.getLocalTimezone();
    } catch (error) {
      _log('Unable to read the device timezone: $error');
      return null;
    }
  }

  void _log(String message) {
    // Keep diagnostics visible in the Flutter run console without exposing the token.
    print('[PushNotificationService] $message');
  }

  Future<void> dispose() async {
    await _tokenSubscription?.cancel();
    _tokenSubscription = null;
  }
}
