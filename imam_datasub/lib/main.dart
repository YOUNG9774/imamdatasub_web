import 'dart:async';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_crashlytics/firebase_crashlytics.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'app.dart';
import 'core/config/firebase_options.dart';
import 'core/di/injection.dart';
import 'core/utils/logger.dart';

void main() {
  var firebaseReady = false;

  void recordStartupError(Object error, StackTrace stack, {bool fatal = false}) {
    appLogger.e('Startup error', error: error, stackTrace: stack);
    if (!firebaseReady) return;

    try {
      FirebaseCrashlytics.instance.recordError(error, stack, fatal: fatal);
    } catch (crashlyticsError, crashlyticsStack) {
      appLogger.e(
        'Crashlytics reporting failed',
        error: crashlyticsError,
        stackTrace: crashlyticsStack,
      );
    }
  }

  runZonedGuarded(
    () async {
      WidgetsFlutterBinding.ensureInitialized();

      await SystemChrome.setPreferredOrientations([
        DeviceOrientation.portraitUp,
        DeviceOrientation.portraitDown,
      ]);

      SystemChrome.setSystemUIOverlayStyle(
        const SystemUiOverlayStyle(statusBarColor: Colors.transparent),
      );

      try {
        if (Firebase.apps.isEmpty) {
          await Firebase.initializeApp(
            options: DefaultFirebaseOptions.currentPlatform,
          );
        } else {
          Firebase.app();
        }
        firebaseReady = true;
      } catch (error, stack) {
        recordStartupError(error, stack);
      }

      FlutterError.onError = (errorDetails) {
        FlutterError.presentError(errorDetails);
        if (!firebaseReady) return;
        FirebaseCrashlytics.instance.recordFlutterFatalError(errorDetails);
      };
      PlatformDispatcher.instance.onError = (error, stack) {
        recordStartupError(error, stack, fatal: true);
        return true;
      };

      final container = ProviderContainer();

      // flutter_secure_storage backs onto the iOS Keychain, which - unlike
      // every other app data store - survives a full uninstall by default.
      // Without this check, uninstalling and reinstalling to "start fresh"
      // (e.g. to test a second account) instead resurrects the previous
      // account's session, cached login PIN, and lockout counters, exactly
      // as if the app had never been removed at all. SharedPreferences DOES
      // get cleared on uninstall on both platforms, so its mere absence here
      // is itself the signal that this is a genuinely fresh install.
      final prefs = await SharedPreferences.getInstance();
      const hasRunBeforeKey = 'kd_has_run_before';
      if (prefs.getBool(hasRunBeforeKey) != true) {
        await container.read(secureStorageProvider).clearAll();
        await prefs.setBool(hasRunBeforeKey, true);
      }

      final hive = container.read(hiveStorageProvider);
      await hive.initialize();

      appLogger.i('App initialized, launching IMAM DATASUB');

      runApp(
        UncontrolledProviderScope(
          container: container,
          child: const ImamDatasubApp(),
        ),
      );
    },
    (error, stack) {
      recordStartupError(error, stack, fatal: true);
    },
  );
}
