import 'package:freshtrack/domain/settings/app_settings.dart';

abstract interface class AppSettingsRepository {
  Future<AppSettings> load();
  Future<void> save(AppSettings settings);
  Future<void> clear();
}
