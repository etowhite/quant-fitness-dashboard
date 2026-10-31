import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:isar_community/isar.dart';

import 'isar_database_service.dart';

// App-scoped: page navigation must not repeatedly open/close the database.
final databaseServiceProvider =
    FutureProvider<IsarDatabaseService>((ref) async {
  var disposed = false;
  IsarDatabaseService? service;
  ref.onDispose(() {
    disposed = true;
    final opened = service;
    if (opened != null) unawaited(opened.close());
  });
  final opened = await IsarDatabaseService.init();
  if (disposed) {
    await opened.close();
    throw StateError('Database provider disposed during initialization');
  }
  service = opened;
  return opened;
});

final isarProvider = FutureProvider<Isar>(
    (ref) async => (await ref.watch(databaseServiceProvider.future)).isar);
