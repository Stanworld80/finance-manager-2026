import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'theme.dart';

part 'theme_provider.g.dart';

@riverpod
class ThemeStyle extends _$ThemeStyle {
  @override
  AppStyle build() {
    return AppStyle.defaults;
  }

  void setStyle(AppStyle style) {
    state = style;
  }
}

@riverpod
class ThemeModeController extends _$ThemeModeController {
  @override
  ThemeMode build() {
    return ThemeMode.system;
  }

  void setMode(ThemeMode mode) {
    state = mode;
  }
}

// Derived providers for easy use in MaterialApp
@riverpod
ThemeData lightTheme(Ref ref) {
  final style = ref.watch(themeStyleProvider);
  return AppTheme.getTheme(style, Brightness.light);
}

@riverpod
ThemeData darkTheme(Ref ref) {
  final style = ref.watch(themeStyleProvider);
  return AppTheme.getTheme(style, Brightness.dark);
}
