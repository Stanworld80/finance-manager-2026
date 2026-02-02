import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'ai_service.g.dart';

class AiMessage {
  final String role; // 'user' or 'assistant'
  final String content;
  final DateTime timestamp;

  AiMessage({
    required this.role,
    required this.content,
    required this.timestamp,
  });
}

class AiState {
  final List<AiMessage> messages;
  final bool isLoading;

  AiState({this.messages = const [], this.isLoading = false});

  AiState copyWith({List<AiMessage>? messages, bool? isLoading}) {
    return AiState(
      messages: messages ?? this.messages,
      isLoading: isLoading ?? this.isLoading,
    );
  }
}

@riverpod
class AiService extends _$AiService {
  @override
  AiState build() {
    return AiState(
      messages: [
        AiMessage(
          role: 'assistant',
          content:
              "Bonjour ! Je suis votre coach financier. Comment puis-je vous aider aujourd'hui ?",
          timestamp: DateTime.now(),
        ),
      ],
    );
  }

  Future<void> sendMessage(String text) async {
    if (text.trim().isEmpty) return;

    final userMessage = AiMessage(
      role: 'user',
      content: text,
      timestamp: DateTime.now(),
    );

    // Update state with user message and loading=true
    state = state.copyWith(
      messages: [...state.messages, userMessage],
      isLoading: true,
    );

    try {
      // Simulate network delay (Gemini API logic would go here)
      await Future.delayed(const Duration(seconds: 1));

      final responseText = _generateMockResponse(text);

      final assistantMessage = AiMessage(
        role: 'assistant',
        content: responseText,
        timestamp: DateTime.now(),
      );

      // Update state with response and loading=false
      state = state.copyWith(
        messages: [...state.messages, assistantMessage],
        isLoading: false,
      );
    } catch (e) {
      // Handle error
      state = state.copyWith(isLoading: false);
    }
  }

  String _generateMockResponse(String input) {
    if (input.toLowerCase().contains('solde')) {
      return "D'après mes données, votre solde global est positif. Vous avez bien géré ce mois-ci !";
    } else if (input.toLowerCase().contains('dépensé')) {
      return "Vous avez dépensé environ 450€ en alimentation ce mois-ci. C'est 10% de plus que le mois dernier.";
    } else {
      return "Intéressant. Dites-m'en plus sur vos objectifs financiers.";
    }
  }
}
