import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/supabase/supabase_client.dart';
import '../../core/supabase/live_auction_client.dart';
import '../../data/models/player.dart';
import '../../data/models/team.dart';

class LiveAuctionState {
  const LiveAuctionState({
    required this.auctionId,
    this.auctionState,
    this.currentPlayer,
    this.leadingTeam,
    this.players = const [],
    this.teams = const [],
    this.recentBids = const [],
    this.serverTimeOffset,
    this.isConnected = false,
    this.lastError,
  });

  final String auctionId;
  final Map<String, dynamic>? auctionState;
  final Player? currentPlayer;
  final Team? leadingTeam;
  final List<Player> players;
  final List<Team> teams;
  final List<Map<String, dynamic>> recentBids;
  final int? serverTimeOffset;
  final bool isConnected;
  final String? lastError;

  int get secondsRemaining {
    if (auctionState == null) return 0;
    if (auctionState!['is_live'] != true) return 0;
    if (auctionState!['is_paused'] == true) return 0;

    final timerEndsAt = auctionState!['timer_ends_at'];
    if (timerEndsAt == null) {
      final remaining = auctionState!['timer_seconds_remaining'] as int?;
      return remaining ?? 0;
    }

    final endTime = DateTime.parse(timerEndsAt as String);
    final now = DateTime.now().add(Duration(milliseconds: serverTimeOffset ?? 0));
    final diff = endTime.difference(now).inSeconds;
    return diff > 0 ? diff : 0;
  }

  bool get isCountdownRunning {
    return secondsRemaining > 0 && auctionState!['is_live'] == true && auctionState!['is_paused'] != true;
  }

  LiveAuctionState copyWith({
    String? auctionId,
    Map<String, dynamic>? auctionState,
    Player? currentPlayer,
    Team? leadingTeam,
    List<Player>? players,
    List<Team>? teams,
    List<Map<String, dynamic>>? recentBids,
    int? serverTimeOffset,
    bool? isConnected,
    String? lastError,
  }) {
    return LiveAuctionState(
      auctionId: auctionId ?? this.auctionId,
      auctionState: auctionState ?? this.auctionState,
      currentPlayer: currentPlayer ?? this.currentPlayer,
      leadingTeam: leadingTeam ?? this.leadingTeam,
      players: players ?? this.players,
      teams: teams ?? this.teams,
      recentBids: recentBids ?? this.recentBids,
      serverTimeOffset: serverTimeOffset ?? this.serverTimeOffset,
      isConnected: isConnected ?? this.isConnected,
      lastError: lastError ?? this.lastError,
    );
  }
}

class LiveAuctionNotifier extends Notifier<LiveAuctionState> {
  StreamSubscription? _stateSubscription;
  StreamSubscription? _playersSubscription;
  StreamSubscription? _teamsSubscription;
  StreamSubscription? _bidsSubscription;
  Timer? _timerSubscription;
  Timer? _serverTimeSubscription;

  @override
  LiveAuctionState build() {
    ref.onDispose(stop);
    return const LiveAuctionState(auctionId: '');
  }

  Future<void> _initServerTime() async {
    final client = SupabaseClientService.instance.client;
    if (client == null) return;

    try {
      final response = await client.rpc('select_now', params: {}).single();
      final serverTime = DateTime.parse(response['now'] as String);
      final localTime = DateTime.now();
      final offset = serverTime.difference(localTime).inMilliseconds;
      state = state.copyWith(serverTimeOffset: offset);
    } catch (_) {
      try {
        final data = await client.from('auction_state').select('updated_at').limit(1).single();
        final serverTime = DateTime.parse(data['updated_at'] as String);
        final localTime = DateTime.now();
        final offset = serverTime.difference(localTime).inMilliseconds;
        state = state.copyWith(serverTimeOffset: offset);
      } catch (_) {
        state = state.copyWith(serverTimeOffset: 0);
      }
    }
  }

  Future<void> start(String auctionId) async {
    stop();

    state = state.copyWith(auctionId: auctionId, isConnected: true, lastError: null);
    await _initServerTime();

    final client = SupabaseClientService.instance.client;
    if (client == null) {
      state = state.copyWith(isConnected: false, lastError: 'Supabase client not initialized');
      return;
    }

    _stateSubscription = client
        .from('auction_state')
        .stream(primaryKey: ['id'])
        .eq('auction_id', auctionId)
        .listen((rows) {
      if (rows.isNotEmpty) {
        final row = rows.first;
        state = state.copyWith(auctionState: row, lastError: null);
      }
    });

    _playersSubscription = client
        .from('players')
        .stream(primaryKey: ['id'])
        .eq('auction_id', auctionId)
        .listen((rows) {
      state = state.copyWith(
        players: rows.map((row) => Player.fromMap(row)).toList(),
      );
    });

    _teamsSubscription = client
        .from('teams')
        .stream(primaryKey: ['id'])
        .eq('auction_id', auctionId)
        .listen((rows) {
      state = state.copyWith(
        teams: rows.map((row) => Team.fromMap(row)).toList(),
      );
    });

    _bidsSubscription = client
        .from('bids')
        .stream(primaryKey: ['id'])
        .eq('auction_id', auctionId)
        .order('timestamp', ascending: false)
        .listen((rows) {
      state = state.copyWith(
        recentBids: rows.cast<Map<String, dynamic>>().take(10).toList(),
      );
    });

    _timerSubscription = Timer.periodic(const Duration(seconds: 1), (_) {
      state = state.copyWith();
    });

    _serverTimeSubscription = Timer.periodic(const Duration(seconds: 30), (_) async {
      await _initServerTime();
    });
  }

  void stop() {
    _stateSubscription?.cancel();
    _playersSubscription?.cancel();
    _teamsSubscription?.cancel();
    _bidsSubscription?.cancel();
    _timerSubscription?.cancel();
    _serverTimeSubscription?.cancel();
    _stateSubscription = null;
    _playersSubscription = null;
    _teamsSubscription = null;
    _bidsSubscription = null;
    _timerSubscription = null;
    _serverTimeSubscription = null;
  }

  Future<LiveAuctionResult> callRpc(Future<LiveAuctionResult> Function() rpcCall) async {
    final result = await rpcCall();
    if (!result.success) {
      state = state.copyWith(lastError: LiveAuctionErrorMessages.forCode(result.errorCode, result.errorMessage));
    } else {
      state = state.copyWith(lastError: null);
    }
    return result;
  }
}

final liveAuctionNotifierProvider = NotifierProvider<LiveAuctionNotifier, LiveAuctionState>(() {
  return LiveAuctionNotifier();
});

final liveAuctionStateProvider = Provider<LiveAuctionState>((ref) {
  return ref.watch(liveAuctionNotifierProvider);
});

final countdownSecondsProvider = Provider<int>((ref) {
  return ref.watch(liveAuctionNotifierProvider).secondsRemaining;
});

final countdownRunningProvider = Provider<bool>((ref) {
  return ref.watch(liveAuctionNotifierProvider).isCountdownRunning;
});

final liveAuctionErrorProvider = Provider<String?>((ref) {
  return ref.watch(liveAuctionNotifierProvider).lastError;
});
