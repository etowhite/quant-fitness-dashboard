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
        child: Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  QText('Язык', style: Theme.of(context).textTheme.titleLarge),
                  const SizedBox(height: 12),
                  SegmentedButton<AppLanguage>(
                      segments: const [
                        ButtonSegment(
                            value: AppLanguage.ru, label: QText('RU')),
                        ButtonSegment(
                            value: AppLanguage.en, label: QText('EN')),
                        ButtonSegment(
                            value: AppLanguage.system, label: QText('Авто'))
                      ],
                      selected: {
                        value
                      },
                      onSelectionChanged: (v) async {
                        try {
                          await ref.read(localeProvider.notifier).save(v.first);
                        } catch (_) {
                          if (context.mounted) {
                            ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(
                                    content: QText(
                                        'Не удалось сохранить настройки.')));
                          }
                        }
                      }),
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
