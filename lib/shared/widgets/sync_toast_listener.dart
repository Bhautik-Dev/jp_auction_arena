import 'package:flutter/material.dart';

import '../../data/repositories/sync/supabase_sync_service.dart';
import '../../shared/widgets/app_ui_feedback.dart';

/// Wraps the app content and shows user-facing toast messages whenever a
/// Supabase cloud sync operation succeeds or fails.
///
/// The [SupabaseSyncService] invokes [onSyncResult] after every cloud write.
/// This listener translates those results into [AppToast] success/error
/// messages so the user always knows whether data reached the cloud.
class SyncToastListener extends StatefulWidget {
  final Widget child;

  const SyncToastListener({
    super.key,
    required this.child,
  });

  @override
  State<SyncToastListener> createState() => _SyncToastListenerState();
}

class _SyncToastListenerState extends State<SyncToastListener> {
  bool _listenerAttached = false;

  @override
  void initState() {
    super.initState();
    _attachListener();
  }

  void _attachListener() {
    if (_listenerAttached) return;
    _listenerAttached = true;

    SupabaseSyncService.onSyncResult = (table, op, success, error) {
      if (!mounted) return;

      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!mounted) return;

        if (success) {
          // Show success toast for non-noise operations (skip individual bids
          // during live auctions to avoid toast spam).
          if (op != 'insert' || table != 'bids') {
            AppToast.showSuccess(
              context,
              'Cloud sync: $op $table saved to Supabase',
            );
          }
        } else {
          AppToast.showError(
            context,
            'Cloud sync failed ($op $table): $error',
          );
        }
      });
    };
  }

  @override
  void didUpdateWidget(SyncToastListener oldWidget) {
    super.didUpdateWidget(oldWidget);
    _attachListener();
  }

  @override
  Widget build(BuildContext context) {
    return widget.child;
  }
}
