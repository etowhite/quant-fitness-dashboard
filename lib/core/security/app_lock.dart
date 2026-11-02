import 'package:smart_fitness_dashboard/core/theme/app_spacing.dart';
import '../home_widgets/home_widgets.dart';
import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:local_auth/local_auth.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../localization/app_strings.dart';
import '../../shared/widgets/quant_logo.dart';

class AppLockService {
  final LocalAuthentication _auth = LocalAuthentication();
  DateTime? lastAuthenticated;
  Future<bool> authenticate(String reason) async {
    final success = await _auth.authenticate(
        localizedReason: reason,
        options: const AuthenticationOptions(
            biometricOnly: false, stickyAuth: true));
    if (success) lastAuthenticated = DateTime.now();
    return success;
  }
}

final appLockServiceProvider = Provider((ref) => AppLockService());
final appLockProvider =
    AsyncNotifierProvider<AppLockNotifier, bool>(AppLockNotifier.new);

class AppLockNotifier extends AsyncNotifier<bool> {
  static const key = 'quant.appLock';
  @override
  Future<bool> build() async =>
      (await SharedPreferences.getInstance()).getBool(key) ?? false;
  Future<bool> setEnabled(bool enabled, String reason) async {
    if (!await ref.read(appLockServiceProvider).authenticate(reason)) {
      return false;
    }
    if (!await (await SharedPreferences.getInstance()).setBool(key, enabled)) {
      throw StateError('Could not save app lock');
    }
    state = AsyncData(enabled);
    await HomeWidgets.refresh();
    return true;
  }
}

/// Sits above the Navigator so existing dialogs/routes cannot bypass the lock.
/// This is an entry gate, not database encryption. Credentials stay with Android.
class AppLockGate extends ConsumerStatefulWidget {
  const AppLockGate(
      {required this.child, this.clock = DateTime.now, super.key});
  final Widget child;
  final DateTime Function() clock;
  @override
  ConsumerState<AppLockGate> createState() => _AppLockGateState();
}

class _AppLockGateState extends ConsumerState<AppLockGate>
    with WidgetsBindingObserver {
  DateTime? _backgroundAt;
  bool _locked = true,
      _private = false,
      _authenticating = false,
      _scheduled = false;
  String? _error;
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (_authenticating || ref.read(appLockProvider).valueOrNull != true) {
      return;
    }
    if (state == AppLifecycleState.inactive) {
      setState(() => _private = true);
    } else if (state == AppLifecycleState.paused ||
        state == AppLifecycleState.hidden) {
      _backgroundAt ??= widget.clock();
      setState(() => _private = true);
    } else if (state == AppLifecycleState.resumed) {
      final expired = _backgroundAt != null &&
          widget.clock().difference(_backgroundAt!) >=
              const Duration(minutes: 1);
      setState(() {
        _private = false;
        if (expired) {
          _locked = true;
          _scheduled = false;
        }
      });
      _backgroundAt = null;
    }
  }

  Future<void> _unlock() async {
    if (_authenticating) return;
    setState(() {
      _authenticating = true;
      _error = null;
    });
    try {
      final success = await ref
          .read(appLockServiceProvider)
          .authenticate(context.tr('Подтвердите вход в quant'));
      if (mounted) {
        setState(() {
          _locked = !success;
          _private = false;
        });
      }
    } catch (_) {
      if (mounted) {
        setState(() => _error =
            'Не удалось подтвердить вход. Проверьте блокировку устройства и повторите.');
      }
    } finally {
      if (mounted) setState(() => _authenticating = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final enabled = ref.watch(appLockProvider);
    ref.listen(appLockProvider, (previous, next) {
      if (previous?.valueOrNull == false && next.valueOrNull == true) {
        // Settings enabling is accepted only after a successful system challenge.
        setState(() => _locked = false);
      }
    });
    final blocked = enabled.isLoading ||
        enabled.hasError ||
        (enabled.valueOrNull == true && (_locked || _private));
    if (enabled.valueOrNull == true && _locked && !_private && !_scheduled) {
      _scheduled = true;
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) unawaited(_unlock());
      });
    }
    return Stack(children: [
      Offstage(offstage: blocked, child: widget.child),
      if (blocked)
        Positioned.fill(
            child: PopScope(
                canPop: false,
                child: Scaffold(
                    body: SafeArea(
                        child: Center(
                            child: SingleChildScrollView(
                                padding: const EdgeInsets.all(32),
                                child: Column(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      const QuantLogo(size: 112),
                                      const SizedBox(height: 24),
                                      Text('quant',
                                          style: Theme.of(context)
                                              .textTheme
                                              .displaySmall),
                                      const SizedBox(
                                          height: AppSpacing.actionGap),
                                      const QText('Ваши данные под защитой'),
                                      if (_error != null)
                                        Padding(
                                            padding:
                                                const EdgeInsets.only(top: 16),
                                            child: QText(_error!)),
                                      const SizedBox(height: 24),
                                      if (enabled.isLoading || _authenticating)
                                        const CircularProgressIndicator()
                                      else
                                        FilledButton.icon(
                                            onPressed: enabled.hasError
                                                ? () => ref
                                                    .invalidate(appLockProvider)
                                                : _unlock,
                                            icon: const Icon(Icons.fingerprint),
                                            label:
                                                const QText('Разблокировать')),
                                    ]))))))),
    ]);
  }
}

class AppLockCard extends ConsumerWidget {
  const AppLockCard({super.key});
  @override
  Widget build(BuildContext context, WidgetRef ref) => Card(
          child: SwitchListTile(
        secondary: const Icon(Icons.fingerprint),
        title: const QText('Защита входа'),
        subtitle: const QText(
            'Биометрия или ПИН-код устройства · блокировка через минуту в фоне'),
        value: ref.watch(appLockProvider).valueOrNull ?? false,
        onChanged: (value) async {
          try {
            final changed = await ref
                .read(appLockProvider.notifier)
                .setEnabled(value, context.tr('Подтвердите вход в quant'));
            if (!changed && context.mounted) {
              ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: QText('Подтверждение отменено')));
            }
          } catch (_) {
            if (context.mounted) {
              ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
                  content: QText(
                      'Настройте ПИН-код или биометрию в настройках Android.')));
            }
          }
        },
      ));
}
