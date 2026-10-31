import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/localization/app_language.dart';
import '../../../../core/localization/locale_provider.dart';
import '../../../../core/localization/app_strings.dart';
import '../../../onboarding/application/onboarding_provider.dart';
import '../../../../app/dashboard_shell.dart';

class LanguageCard extends ConsumerWidget {
  const LanguageCard({super.key});
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final value = ref.watch(localeProvider).valueOrNull ?? AppLanguage.system;
    return Card(
        shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(28),
            side: BorderSide(
                color: Theme.of(context).colorScheme.outlineVariant)),
        child: Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Row(children: [
                    const Icon(Icons.language),
                    const SizedBox(width: 12),
                    const Expanded(child: QText('Язык')),
                    SizedBox(
                        width: 150,
                        child: DropdownButtonFormField<AppLanguage>(
                          isExpanded: true,
                          key: ValueKey(value),
                          initialValue: value,
                          decoration: InputDecoration(
                              contentPadding: const EdgeInsets.symmetric(
                                  horizontal: 16, vertical: 12),
                              border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(32)),
                              focusedBorder: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(32),
                                  borderSide: BorderSide(
                                      color:
                                          Theme.of(context).colorScheme.primary,
                                      width: 2))),
                          items: const [
                            DropdownMenuItem(
                                value: AppLanguage.ru, child: Text('Русский')),
                            DropdownMenuItem(
                                value: AppLanguage.en, child: Text('English')),
                            DropdownMenuItem(
                                value: AppLanguage.system, child: QText('Авто'))
                          ],
                          onChanged: (v) async {
                            if (v == null) return;
                            try {
                              await ref.read(localeProvider.notifier).save(v);
                            } catch (_) {
                              if (context.mounted) {
                                ScaffoldMessenger.of(context).showSnackBar(
                                    const SnackBar(
                                        content: QText(
                                            'Не удалось сохранить настройки.')));
                              }
                            }
                          },
                        )),
                  ]),
                  const Divider(height: 28),
                  const SizedBox(height: 12),
                  OutlinedButton.icon(
                      onPressed: () async {
                        try {
                          await ref
                              .read(onboardingProvider.notifier)
                              .setCompleted(false);
                          ref
                              .read(selectedTabProvider.notifier)
                              .select(AppTab.dashboard);
                        } catch (_) {
                          if (context.mounted) {
                            ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(
                                    content: QText(
                                        'Не удалось сохранить настройки.')));
                          }
                        }
                      },
                      icon: const Icon(Icons.auto_awesome),
                      label: const QText('Пройти ознакомление заново')),
                ])));
  }
}
