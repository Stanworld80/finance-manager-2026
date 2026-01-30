# Coding Guidelines & Vibe

## Design Philosophy (The "Vibe")
- **Wowliness**: The UI must be impressive. Avoid "default Material" looks.
- **Premium Feel**: Use vibrant but harmonious color palettes, dark mode by default or highly polished light mode.
- **Motion**: Use animations (Hero, AnimatedContainer, transitions) to make the app feel alive.
- **Structure**: Clean, readable, well-commented code.

## Flutter Architecture
- **State Management**: **Riverpod** (ConsumerWidget, ConsumerStatefulWidget). Avoid `setState` for complex state.
- **Navigation**: **GoRouter**. Typed routes where possible.
- **Folder Structure**: Feature-first.
    ```
    lib/features/
      feature_name/
        data/
        domain/
        presentation/
          pages/
          widgets/
          providers/
    ```

## Development Rules
1.  **Strict Typing**: No `dynamic` unless absolutely necessary.
2.  **Linting**: Follow `flutter_lints` and fix warnings immediately.
3.  **Testing**:
    - Unit tests for logic/repositories.
    - Widget tests for UI components.
    - `flutter test` must pass before deployment.
4.  **Environment**: Use `Environment.config` for flavor-specific logic. Do not hardcode "dev" or "prod" strings in checking logic (use `Environment.isDev`).

## CI/CD
- Always use `build_deploy.ps1` for building and deploying.
- Do not modify `pubspec.yaml` version manually; the script does it.
