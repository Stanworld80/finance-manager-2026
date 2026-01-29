import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:firebase_core/firebase_core.dart';
import 'app.dart';
import 'core/environment.dart';
import 'firebase_options.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  Environment.init(AppFlavor.dev);

  // Initialize Firebase (Assuming firebase_options.dart is generated later,
  // skipping for now or adding a placeholder if user hasn't generated it yet.
  // We will wrap in try-catch to allow running without firebase initially for UI tests if needed)
  try {
    await Firebase.initializeApp(
      options: DefaultFirebaseOptions.currentPlatform,
    );
  } catch (e) {
    print("Firebase init failed (expected if not configured): $e");
  }

  runApp(const ProviderScope(child: FinanceManagerApp()));
}
