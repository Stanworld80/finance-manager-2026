import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:firebase_core/firebase_core.dart';
import 'app.dart';
import 'core/environment.dart';
import 'firebase_options_prod.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  Environment.init(AppFlavor.prod);

  try {
    await Firebase.initializeApp(options: ProdFirebaseOptions.currentPlatform);
  } catch (e) {
    print("Firebase init failed: $e");
  }

  runApp(const ProviderScope(child: FinanceManagerApp()));
}
