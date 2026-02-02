import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:firebase_core/firebase_core.dart';
import 'app.dart';
import 'core/environment.dart';
import 'firebase_options_prod.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  Environment.init(AppFlavor.prod);

  try {
    await Firebase.initializeApp(options: ProdFirebaseOptions.currentPlatform);

    if (kDebugMode) {
      // Connect to local emulators if running infra.ps1 up
      try {
        FirebaseFirestore.instance.useFirestoreEmulator('localhost', 8080);
        await FirebaseAuth.instance.useAuthEmulator('localhost', 9099);
        print('Using Firebase Emulators');
      } catch (e) {
        print('Emulator connection failed (non-critical): $e');
      }
    }
  } catch (e) {
    print("Firebase init failed: $e");
  }

  runApp(const ProviderScope(child: FinanceManagerApp()));
}
