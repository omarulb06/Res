import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../l10n/app_strings.dart';
import '../providers/settings_provider.dart';

/// Modal bottom sheet with Theme + Language controls.
/// Open with [SettingsSheet.show]; pushes rebuilds via [SettingsProvider].
class SettingsSheet extends StatelessWidget {
  const SettingsSheet({super.key});

  static Future<void> show(BuildContext context) {
    return showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      showDragHandle: true,
      builder: (_) => const SettingsSheet(),
    );
  }

  @override
  Widget build(BuildContext context) {
    final s = S.of(context);
    final settings = context.watch<SettingsProvider>();
    final theme = Theme.of(context);

    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(s.settings, style: theme.textTheme.headlineSmall),
            const SizedBox(height: 20),

            // --- Theme ---
            Text(s.theme,
                style: theme.textTheme.titleMedium
                    ?.copyWith(fontWeight: FontWeight.w600)),
            const SizedBox(height: 8),
            SegmentedButton<ThemeMode>(
              segments: [
                ButtonSegment(
                  value: ThemeMode.light,
                  label: Text(s.themeLight),
                  icon: const Icon(Icons.light_mode_outlined),
                ),
                ButtonSegment(
                  value: ThemeMode.dark,
                  label: Text(s.themeDark),
                  icon: const Icon(Icons.dark_mode_outlined),
                ),
                ButtonSegment(
                  value: ThemeMode.system,
                  label: Text(s.themeSystem),
                  icon: const Icon(Icons.settings_suggest_outlined),
                ),
              ],
              selected: {settings.themeMode},
              onSelectionChanged: (sel) =>
                  context.read<SettingsProvider>().setThemeMode(sel.first),
            ),

            const SizedBox(height: 24),

            // --- Language ---
            Text(s.language,
                style: theme.textTheme.titleMedium
                    ?.copyWith(fontWeight: FontWeight.w600)),
            const SizedBox(height: 8),
            ...AppLocale.values.map(
              (locale) => RadioListTile<AppLocale>(
                value: locale,
                groupValue: settings.appLocale,
                onChanged: (v) {
                  if (v != null) {
                    context.read<SettingsProvider>().setLocale(v);
                  }
                },
                title: Text(locale.nativeName,
                    style: const TextStyle(fontWeight: FontWeight.w600)),
                secondary: Text(locale.flag,
                    style: const TextStyle(fontSize: 28)),
                dense: false,
              ),
            ),

            const SizedBox(height: 8),
            Align(
              alignment: AlignmentDirectional.centerEnd,
              child: FilledButton(
                onPressed: () => Navigator.of(context).pop(),
                child: Text(s.done),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Convenience AppBar action: shows a cog icon that opens the settings sheet.
class SettingsAppBarAction extends StatelessWidget {
  const SettingsAppBarAction({super.key});

  @override
  Widget build(BuildContext context) {
    return IconButton(
      tooltip: S.of(context).settings,
      icon: const Icon(Icons.tune_rounded),
      onPressed: () => SettingsSheet.show(context),
    );
  }
}

/// Convenience: just a theme toggle icon (light/dark/system cycle),
/// without opening the full sheet. Handy for compact AppBars.
class ThemeToggleAction extends StatelessWidget {
  const ThemeToggleAction({super.key});

  @override
  Widget build(BuildContext context) {
    final mode = context.watch<SettingsProvider>().themeMode;
    final icon = switch (mode) {
      ThemeMode.light => Icons.light_mode_outlined,
      ThemeMode.dark => Icons.dark_mode_outlined,
      ThemeMode.system => Icons.brightness_auto_outlined,
    };
    return IconButton(
      tooltip: S.of(context).theme,
      icon: Icon(icon),
      onPressed: () => context.read<SettingsProvider>().cycleThemeMode(),
    );
  }
}
