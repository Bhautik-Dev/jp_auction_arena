import 'dart:convert';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hive_flutter/hive_flutter.dart';
import '../models/models.dart';
import 'hive_service.dart';

abstract class DataBackupService {
  Future<String> createBackupJson();
  Future<Map<String, int>> restoreFromJson(String jsonString);
  Future<void> clearAllData();
}

class HiveDataBackupService implements DataBackupService {
  @override
  Future<String> createBackupJson() async {
    final auctionsBox = Hive.isBoxOpen(HiveBoxes.auctions) ? Hive.box<Auction>(HiveBoxes.auctions) : await Hive.openBox<Auction>(HiveBoxes.auctions);
    final teamsBox = Hive.isBoxOpen(HiveBoxes.teams) ? Hive.box<Team>(HiveBoxes.teams) : await Hive.openBox<Team>(HiveBoxes.teams);
    final playersBox = Hive.isBoxOpen(HiveBoxes.players) ? Hive.box<Player>(HiveBoxes.players) : await Hive.openBox<Player>(HiveBoxes.players);
    final bidsBox = Hive.isBoxOpen(HiveBoxes.bids) ? Hive.box<Bid>(HiveBoxes.bids) : await Hive.openBox<Bid>(HiveBoxes.bids);
    final settingsBox = Hive.isBoxOpen(HiveBoxes.settings) ? Hive.box<AppSettings>(HiveBoxes.settings) : await Hive.openBox<AppSettings>(HiveBoxes.settings);

    final currentSettings = settingsBox.get('app_settings');

    final backupMap = <String, dynamic>{
      'version': '1.0',
      'exportedAt': DateTime.now().toIso8601String(),
      'auctions': auctionsBox.values.map((a) => a.toMap()).toList(),
      'teams': teamsBox.values.map((t) => t.toMap()).toList(),
      'players': playersBox.values.map((p) => p.toMap()).toList(),
      'bids': bidsBox.values.map((b) => b.toMap()).toList(),
      'settings': currentSettings?.toMap(),
    };

    return const JsonEncoder.withIndent('  ').convert(backupMap);
  }

  @override
  Future<Map<String, int>> restoreFromJson(String jsonString) async {
    final dynamic decoded = jsonDecode(jsonString);
    if (decoded is! Map<String, dynamic>) {
      throw const FormatException('Invalid backup file structure: expected JSON object');
    }

    final auctionsBox = Hive.isBoxOpen(HiveBoxes.auctions) ? Hive.box<Auction>(HiveBoxes.auctions) : await Hive.openBox<Auction>(HiveBoxes.auctions);
    final teamsBox = Hive.isBoxOpen(HiveBoxes.teams) ? Hive.box<Team>(HiveBoxes.teams) : await Hive.openBox<Team>(HiveBoxes.teams);
    final playersBox = Hive.isBoxOpen(HiveBoxes.players) ? Hive.box<Player>(HiveBoxes.players) : await Hive.openBox<Player>(HiveBoxes.players);
    final bidsBox = Hive.isBoxOpen(HiveBoxes.bids) ? Hive.box<Bid>(HiveBoxes.bids) : await Hive.openBox<Bid>(HiveBoxes.bids);
    final settingsBox = Hive.isBoxOpen(HiveBoxes.settings) ? Hive.box<AppSettings>(HiveBoxes.settings) : await Hive.openBox<AppSettings>(HiveBoxes.settings);

    int auctionsCount = 0;
    int teamsCount = 0;
    int playersCount = 0;
    int bidsCount = 0;

    // Clear existing data before restoring
    await auctionsBox.clear();
    await teamsBox.clear();
    await playersBox.clear();
    await bidsBox.clear();

    if (decoded['auctions'] is List) {
      for (final item in decoded['auctions'] as List) {
        if (item is Map) {
          final auction = Auction.fromMap(Map<String, dynamic>.from(item));
          await auctionsBox.put(auction.id, auction);
          auctionsCount++;
        }
      }
    }

    if (decoded['teams'] is List) {
      for (final item in decoded['teams'] as List) {
        if (item is Map) {
          final team = Team.fromMap(Map<String, dynamic>.from(item));
          await teamsBox.put(team.id, team);
          teamsCount++;
        }
      }
    }

    if (decoded['players'] is List) {
      for (final item in decoded['players'] as List) {
        if (item is Map) {
          final player = Player.fromMap(Map<String, dynamic>.from(item));
          await playersBox.put(player.id, player);
          playersCount++;
        }
      }
    }

    if (decoded['bids'] is List) {
      for (final item in decoded['bids'] as List) {
        if (item is Map) {
          final bid = Bid.fromMap(Map<String, dynamic>.from(item));
          await bidsBox.put(bid.id, bid);
          bidsCount++;
        }
      }
    }

    if (decoded['settings'] is Map) {
      final settings = AppSettings.fromMap(Map<String, dynamic>.from(decoded['settings'] as Map));
      await settingsBox.put('app_settings', settings);
    }

    return {
      'auctions': auctionsCount,
      'teams': teamsCount,
      'players': playersCount,
      'bids': bidsCount,
    };
  }

  @override
  Future<void> clearAllData() async {
    final auctionsBox = Hive.isBoxOpen(HiveBoxes.auctions) ? Hive.box<Auction>(HiveBoxes.auctions) : await Hive.openBox<Auction>(HiveBoxes.auctions);
    final teamsBox = Hive.isBoxOpen(HiveBoxes.teams) ? Hive.box<Team>(HiveBoxes.teams) : await Hive.openBox<Team>(HiveBoxes.teams);
    final playersBox = Hive.isBoxOpen(HiveBoxes.players) ? Hive.box<Player>(HiveBoxes.players) : await Hive.openBox<Player>(HiveBoxes.players);
    final bidsBox = Hive.isBoxOpen(HiveBoxes.bids) ? Hive.box<Bid>(HiveBoxes.bids) : await Hive.openBox<Bid>(HiveBoxes.bids);

    await auctionsBox.clear();
    await teamsBox.clear();
    await playersBox.clear();
    await bidsBox.clear();
  }
}

final dataBackupServiceProvider = Provider<DataBackupService>((ref) {
  return HiveDataBackupService();
});
