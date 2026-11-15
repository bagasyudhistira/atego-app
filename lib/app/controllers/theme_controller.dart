import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:shared_preferences/shared_preferences.dart';

class ThemeController extends GetxController {
  ThemeController(this.preferences)
    : mode = _restore(preferences.getString('appearance')).obs;

  final SharedPreferences preferences;
  final Rx<ThemeMode> mode;
  final saving = false.obs;

  static ThemeMode _restore(String? value) => switch (value) {
    'light' => ThemeMode.light,
    'dark' => ThemeMode.dark,
    _ => ThemeMode.system,
  };

  Future<bool> select(ThemeMode value) async {
    if (saving.value) return false;
    saving.value = true;
    try {
      final saved = await preferences.setString('appearance', value.name);
      if (saved) mode.value = value;
      return saved;
    } catch (_) {
      return false;
    } finally {
      saving.value = false;
    }
  }
}
