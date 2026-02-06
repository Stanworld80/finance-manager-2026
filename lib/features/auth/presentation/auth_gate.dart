import 'package:firebase_ui_auth/firebase_ui_auth.dart';
import 'package:firebase_ui_oauth_google/firebase_ui_oauth_google.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/providers.dart';
import '../data/auth_providers.dart';

// Google Web Client ID for Staging
const _googleClientId =
    "420654277416-4hf1o54jhmas2e7obhfscohbbd5fp0sa.apps.googleusercontent.com";

class AuthGate extends ConsumerWidget {
  const AuthGate({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final authState = ref.watch(authStateProvider);

    return authState.when(
      data: (user) {
        if (user != null) {
          return const Scaffold(
            body: Center(child: CircularProgressIndicator()),
          );
        }

        return Scaffold(
          body: SignInScreen(
            providers: [
              EmailAuthProvider(),
              GoogleProvider(clientId: _googleClientId),
            ],
            headerBuilder: (context, constraints, shrinkOffset) {
              return const Padding(
                padding: EdgeInsets.all(20),
                child: Center(
                  child: Icon(
                    Icons.account_balance_wallet,
                    size: 80,
                    color: Colors.blue,
                  ),
                ),
              );
            },
            footerBuilder: (context, action) {
              final packageInfoAsync = ref.watch(packageInfoProvider);
              return packageInfoAsync.when(
                data: (info) => Padding(
                  padding: const EdgeInsets.only(top: 24),
                  child: Center(
                    child: Text(
                      'v${info.version} (${info.buildNumber})',
                      style: const TextStyle(color: Colors.grey),
                    ),
                  ),
                ),
                loading: () => const SizedBox.shrink(),
                error: (_, __) => const SizedBox.shrink(),
              );
            },
          ),
        );
      },
      loading: () =>
          const Scaffold(body: Center(child: CircularProgressIndicator())),
      error: (err, stack) =>
          Scaffold(body: Center(child: Text('Auth Error: $err'))),
    );
  }
}
