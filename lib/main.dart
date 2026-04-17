import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:firebase_core/firebase_core.dart';

import 'app/app.dart';
import 'core/services/device_service.dart';
import 'core/services/push_notification_service.dart';

void main() async {
  // Ensure Flutter binding is initialized
  WidgetsFlutterBinding.ensureInitialized();

  // Pre-warm DeviceService so the device ID is cached before any HTTP request fires.
  // This prevents the first login request from going out without X-Device-ID.
  try {
    await DeviceService.instance.getDeviceId();
    debugPrint('✅ DeviceService pre-warmed: ${await DeviceService.instance.getDeviceId()}');
  } catch (e) {
    debugPrint('⚠️ DeviceService pre-warm failed: $e');
  }
  
  // Initialize Firebase
  try {
    await Firebase.initializeApp();
    debugPrint('Firebase initialized successfully');
    
    // Initialize push notifications
    await PushNotificationService().initialize();
    debugPrint('Push notifications initialized successfully');
  } catch (e) {
    debugPrint('Error initializing Firebase or push notifications: $e');
  }
  
  // Handle overflow errors gracefully in debug mode
  FlutterError.onError = (FlutterErrorDetails details) {
    FlutterError.presentError(details);
    if (details.exception.toString().contains('RenderFlex overflowed')) {
      debugPrint('⚠️ Overflow detected: ${details.exception}');
    }
  };
  
  runApp(
    const ProviderScope(
      child: KnowvasApp(),
    ),
  );
}

