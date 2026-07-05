import 'package:flutter/material.dart';
// Trigger CD pipeline again v5
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:firebase_core/firebase_core.dart';
import 'app.dart';
import 'core/environment.dart';
import 'firebase_options_stg.dart';
import 'firebase_options_dev.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  Environment.init(AppFlavor.dev);

  const appEnv = String.fromEnvironment('APP_ENV', defaultValue: 'staging');
  final firebaseOptions = appEnv == 'develop'
      ? DevFirebaseOptions.currentPlatform
      : StagingFirebaseOptions.currentPlatform;

  try {
    await Firebase.initializeApp(
      options: firebaseOptions,
    );
  } catch (e) {
    debugPrint("Firebase init failed (expected if not configured): $e");
  }

  runApp(const ProviderScope(child: FinanceManagerApp()));
}
