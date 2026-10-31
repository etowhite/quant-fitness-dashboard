import '../../../../core/localization/app_strings.dart';
import 'package:flutter/material.dart';

import '../../../../core/health/health_connect_service.dart';
import 'dashboard_card.dart';

class HealthAccessBanner extends StatelessWidget {
  const HealthAccessBanner(
      {required this.access,
      required this.busy,
      required this.onConnect,
      super.key});
  final HealthAccess access;
  final bool busy;
  final VoidCallback onConnect;

  @override
  Widget build(BuildContext context) => DashboardCard(
          child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          QText(switch (access) {
            HealthAccess.denied =>
              'Добавьте активность и состав тела в свой дашборд.',
            HealthAccess.updateRequired =>
              'Установите или обновите Health Connect, затем проверьте подключение.',
            _ =>
              'Health Connect недоступен на этом устройстве. Дневник питания работает офлайн.',
          }),
          const SizedBox(height: 12),
          FilledButton.tonal(
            onPressed: busy ? null : onConnect,
            child: QText(access == HealthAccess.denied
                ? 'Подключить Health Connect'
                : 'Проверить подключение'),
          ),
        ],
      ));
}
