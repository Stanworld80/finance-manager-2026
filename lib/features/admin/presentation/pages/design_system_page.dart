import 'package:flutter/material.dart';

class DesignSystemPage extends StatelessWidget {
  const DesignSystemPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Design System')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          const SectionTitle(title: 'Typography'),
          Text(
            'Display Large',
            style: Theme.of(context).textTheme.displayLarge,
          ),
          Text(
            'Headline Medium',
            style: Theme.of(context).textTheme.headlineMedium,
          ),
          Text('Body Large', style: Theme.of(context).textTheme.bodyLarge),

          const SizedBox(height: 24),
          const SectionTitle(title: 'Buttons'),
          Wrap(
            spacing: 8,
            children: [
              ElevatedButton(onPressed: () {}, child: const Text('Elevated')),
              FilledButton(onPressed: () {}, child: const Text('Filled')),
              OutlinedButton(onPressed: () {}, child: const Text('Outlined')),
              TextButton(onPressed: () {}, child: const Text('Text')),
            ],
          ),

          const SizedBox(height: 24),
          const SectionTitle(title: 'Inputs'),
          const TextField(
            decoration: InputDecoration(
              labelText: 'Standard Input',
              border: OutlineInputBorder(),
            ),
          ),
        ],
      ),
    );
  }
}

class SectionTitle extends StatelessWidget {
  final String title;
  const SectionTitle({super.key, required this.title});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: Theme.of(
              context,
            ).textTheme.labelLarge?.copyWith(color: Colors.grey),
          ),
          const Divider(),
        ],
      ),
    );
  }
}
