import 'package:finance_manager_2026/features/ai/application/ai_service.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  late ProviderContainer container;

  setUp(() {
    container = ProviderContainer();
  });

  tearDown(() {
    container.dispose();
  });

  test('AiService initializes with a welcome message', () {
    final state = container.read(aiServiceProvider);
    expect(state.messages.length, 1);
    expect(state.messages.first.role, 'assistant');
    expect(state.isLoading, false);
  });

  test('sendMessage adds user message and awaits response', () async {
    // Keep provider alive (AutoDispose)
    container.listen(aiServiceProvider, (p, n) {});

    final notifier = container.read(aiServiceProvider.notifier);

    // Initial state
    expect(container.read(aiServiceProvider).messages.length, 1);

    // Send user message
    final future = notifier.sendMessage('Hello test');

    // Check loading state immediately after sending?
    // Since StateNotifier updates synchronously for the first part, we can check.
    verifyState() {
      final state = container.read(aiServiceProvider);
      expect(state.messages.length, 2);
      expect(state.messages.last.role, 'user');
      expect(state.messages.last.content, 'Hello test');
      expect(state.isLoading, true);
    }

    verifyState();

    // Wait for completion (simulated delay)
    await future;

    // Check final state
    final state = container.read(aiServiceProvider);
    expect(state.messages.length, 3);
    expect(state.messages.last.role, 'assistant');
    expect(state.messages.last.content, contains('Intéressant'));
    expect(state.isLoading, false);
  });
}
