import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hive_flutter/hive_flutter.dart';
import '../models/models.dart';
import 'hive_service.dart';

abstract class SettingsRepository {
  AppSettings getSettings();
  Future<void> saveSettings(AppSettings settings);
  Stream<AppSettings> watchSettings();
}

class HiveSettingsRepository implements SettingsRepository {
  Box<AppSettings> get _box => Hive.box<AppSettings>(HiveBoxes.settings);
  static const String _key = 'app_settings';

  @override
  AppSettings getSettings() {
    return _box.get(_key) ?? AppSettings();
  }

  @override
  Future<void> saveSettings(AppSettings settings) async {
    await _box.put(_key, settings);
  }

  @override
  Stream<AppSettings> watchSettings() {
    return _box.watch(key: _key).map((event) => (event.value as AppSettings?) ?? AppSettings());
  }
}

final settingsRepositoryProvider = Provider<SettingsRepository>((ref) {
  return HiveSettingsRepository();
});

final appSettingsProvider = StreamProvider<AppSettings>((ref) async* {
  final repo = ref.watch(settingsRepositoryProvider);
  yield repo.getSettings();
  yield* repo.watchSettings();
});
