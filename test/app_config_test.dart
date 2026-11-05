import 'package:flutter_test/flutter_test.dart';
import 'package:jp_auction_arena/core/config/app_config.dart';

void main() {
  group('AppConfig Tests', () {
    test('contains expected application metadata', () {
      expect(AppConfig.appName, 'JP AUCTION ARENA');
      expect(AppConfig.appVersion, isNotEmpty);
      expect(AppConfig.appDescription, isNotEmpty);
      expect(AppConfig.isDebugBannerEnabled, isFalse);
    });
  });
}
