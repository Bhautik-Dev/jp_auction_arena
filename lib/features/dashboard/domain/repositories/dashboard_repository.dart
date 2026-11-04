import 'package:jp_auction_arena/features/auth/domain/models/auth_user.dart';
import 'package:jp_auction_arena/features/dashboard/domain/models/dashboard_snapshot.dart';

abstract interface class DashboardRepository {
  Future<DashboardSnapshot> loadForUser(AuthUser user);
}
