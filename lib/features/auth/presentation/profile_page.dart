import 'package:flutter/material.dart';
import 'package:firebase_ui_auth/firebase_ui_auth.dart';
import 'package:go_router/go_router.dart';

class UserProfilePage extends StatelessWidget {
  const UserProfilePage({super.key});

  @override
  Widget build(BuildContext context) {
    return ProfileScreen(
      appBar: AppBar(title: const Text("Mon Profil")),
      children: [
        const Divider(),
        ListTile(
          leading: const Icon(Icons.palette),
          title: const Text("Personnalisation & Thèmes"),
          subtitle: const Text("Couleurs, Mode Sombre/Clair..."),
          trailing: const Icon(Icons.arrow_forward_ios, size: 16),
          onTap: () => context.push('/preferences'),
        ),
        const Divider(),
      ],
    );
  }
}
