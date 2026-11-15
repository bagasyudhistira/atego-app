import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:presence/app/controllers/theme_controller.dart';

class AppearanceSetting extends StatelessWidget {
  const AppearanceSetting({super.key, required this.controller});

  final ThemeController controller;

  @override
  Widget build(BuildContext context) => Obx(
    () => Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Appearance', style: Theme.of(context).textTheme.titleMedium),
        const SizedBox(height: 4),
        Text(
          'Automatic follows your phone’s settings.',
          style: Theme.of(context).textTheme.bodySmall,
        ),
        const SizedBox(height: 12),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: [
            for (final entry in const {
              ThemeMode.light: 'Light',
              ThemeMode.dark: 'Dark',
              ThemeMode.system: 'Automatic',
            }.entries)
              ChoiceChip(
                label: Text(entry.value),
                selected: controller.mode.value == entry.key,
                onSelected: controller.saving.value
                    ? null
                    : (_) async {
                        final saved = await controller.select(entry.key);
                        if (!saved && context.mounted) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text(
                                'Could not save appearance. Try again.',
                              ),
                            ),
                          );
                        }
                      },
              ),
          ],
        ),
      ],
    ),
  );
}
