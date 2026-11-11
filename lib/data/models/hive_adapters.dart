import 'package:hive/hive.dart';
import 'auction.dart';
import 'team.dart';
import 'player.dart';
import 'bid.dart';
import 'app_settings.dart';
import 'enums.dart';

class AuctionStatusAdapter extends TypeAdapter<AuctionStatus> {
  @override
  final int typeId = 0;

  @override
  AuctionStatus read(BinaryReader reader) {
    final index = reader.readByte();
    if (index >= 0 && index < AuctionStatus.values.length) {
      return AuctionStatus.values[index];
    }
    return AuctionStatus.draft;
  }

  @override
  void write(BinaryWriter writer, AuctionStatus obj) {
    writer.writeByte(obj.index);
  }
}

class AuctionModeAdapter extends TypeAdapter<AuctionMode> {
  @override
  final int typeId = 1;

  @override
  AuctionMode read(BinaryReader reader) {
    final index = reader.readByte();
    if (index >= 0 && index < AuctionMode.values.length) {
      return AuctionMode.values[index];
    }
    return AuctionMode.manual;
  }

  @override
  void write(BinaryWriter writer, AuctionMode obj) {
    writer.writeByte(obj.index);
  }
}

class PlayerStatusAdapter extends TypeAdapter<PlayerStatus> {
  @override
  final int typeId = 2;

  @override
  PlayerStatus read(BinaryReader reader) {
    final index = reader.readByte();
    if (index >= 0 && index < PlayerStatus.values.length) {
      return PlayerStatus.values[index];
    }
    return PlayerStatus.available;
  }

  @override
  void write(BinaryWriter writer, PlayerStatus obj) {
    writer.writeByte(obj.index);
  }
}

class AuctionAdapter extends TypeAdapter<Auction> {
  @override
  final int typeId = 3;

  @override
  Auction read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return Auction(
      id: fields[0] as String,
      name: fields[1] as String,
      logoBase64: fields[2] as String?,
      venue: fields[3] as String? ?? '',
      description: fields[4] as String? ?? '',
      startDateTime: fields[5] != null ? DateTime.fromMillisecondsSinceEpoch(fields[5] as int) : DateTime.now(),
      status: fields[6] as AuctionStatus? ?? AuctionStatus.draft,
      categories: (fields[7] as List?)?.cast<String>() ?? ['Batsman', 'Bowler', 'All-Rounder', 'Wicket-Keeper'],
      numberOfTeams: fields[8] as int? ?? 8,
      minSquad: fields[9] as int? ?? 11,
      maxSquad: fields[10] as int? ?? 15,
      basePriceDefault: fields[11] as double? ?? 10000.0,
      bidIncrement: fields[12] as double? ?? 2000.0,
      teamPurse: fields[13] as double? ?? 1000000.0,
      countdownSeconds: fields[14] as int? ?? 30,
      mode: fields[15] as AuctionMode? ?? AuctionMode.manual,
      createdAt: fields[16] != null ? DateTime.fromMillisecondsSinceEpoch(fields[16] as int) : DateTime.now(),
      contactPhone: fields[17] as String? ?? '',
      contactEmail: fields[18] as String? ?? '',
      categoryBasePrices: (fields[19] as Map?)?.cast<String, double>() ?? {},
      reservePurseRule: fields[20] as bool? ?? true,
      smartBidSlabs: fields[21] as bool? ?? false,
    );
  }

  @override
  void write(BinaryWriter writer, Auction obj) {
    writer
      ..writeByte(22)
      ..writeByte(0)
      ..write(obj.id)
      ..writeByte(1)
      ..write(obj.name)
      ..writeByte(2)
      ..write(obj.logoBase64)
      ..writeByte(3)
      ..write(obj.venue)
      ..writeByte(4)
      ..write(obj.description)
      ..writeByte(5)
      ..write(obj.startDateTime.millisecondsSinceEpoch)
      ..writeByte(6)
      ..write(obj.status)
      ..writeByte(7)
      ..write(obj.categories)
      ..writeByte(8)
      ..write(obj.numberOfTeams)
      ..writeByte(9)
      ..write(obj.minSquad)
      ..writeByte(10)
      ..write(obj.maxSquad)
      ..writeByte(11)
      ..write(obj.basePriceDefault)
      ..writeByte(12)
      ..write(obj.bidIncrement)
      ..writeByte(13)
      ..write(obj.teamPurse)
      ..writeByte(14)
      ..write(obj.countdownSeconds)
      ..writeByte(15)
      ..write(obj.mode)
      ..writeByte(16)
      ..write(obj.createdAt.millisecondsSinceEpoch)
      ..writeByte(17)
      ..write(obj.contactPhone)
      ..writeByte(18)
      ..write(obj.contactEmail)
      ..writeByte(19)
      ..write(obj.categoryBasePrices)
      ..writeByte(20)
      ..write(obj.reservePurseRule)
      ..writeByte(21)
      ..write(obj.smartBidSlabs);
  }
}

class TeamAdapter extends TypeAdapter<Team> {
  @override
  final int typeId = 4;

  @override
  Team read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return Team(
      id: fields[0] as String,
      auctionId: fields[1] as String,
      name: fields[2] as String,
      logoBase64: fields[3] as String?,
      ownerName: fields[4] as String? ?? '',
      purseTotal: fields[5] as double? ?? 1000000.0,
      purseSpent: fields[6] as double? ?? 0.0,
      playerIds: (fields[7] as List?)?.cast<String>() ?? [],
    );
  }

  @override
  void write(BinaryWriter writer, Team obj) {
    writer
      ..writeByte(8)
      ..writeByte(0)
      ..write(obj.id)
      ..writeByte(1)
      ..write(obj.auctionId)
      ..writeByte(2)
      ..write(obj.name)
      ..writeByte(3)
      ..write(obj.logoBase64)
      ..writeByte(4)
      ..write(obj.ownerName)
      ..writeByte(5)
      ..write(obj.purseTotal)
      ..writeByte(6)
      ..write(obj.purseSpent)
      ..writeByte(7)
      ..write(obj.playerIds);
  }
}

class PlayerAdapter extends TypeAdapter<Player> {
  @override
  final int typeId = 5;

  @override
  Player read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return Player(
      id: fields[0] as String,
      auctionId: fields[1] as String,
      playerNo: fields[2] as int? ?? 1,
      name: fields[3] as String,
      photoBase64: fields[4] as String?,
      age: fields[5] as int? ?? 20,
      village: fields[6] as String? ?? '',
      category: fields[7] as String? ?? 'All-Rounder',
      battingStyle: fields[8] as String? ?? 'Right Hand Bat',
      bowlingStyle: fields[9] as String? ?? 'Right Arm Medium',
      matches: fields[10] as int? ?? 0,
      runs: fields[11] as int? ?? 0,
      wickets: fields[12] as int? ?? 0,
      highScore: fields[13] as int? ?? 0,
      strikeRate: fields[14] as double? ?? 0.0,
      economy: fields[15] as double? ?? 0.0,
      basePrice: fields[16] as double? ?? 10000.0,
      isIcon: fields[17] as bool? ?? false,
      isOwner: fields[18] as bool? ?? false,
      isRetained: fields[19] as bool? ?? false,
      retainedTeamId: fields[20] as String?,
      status: fields[21] as PlayerStatus? ?? PlayerStatus.available,
      soldPrice: fields[22] as double?,
      soldTeamId: fields[23] as String?,
    );
  }

  @override
  void write(BinaryWriter writer, Player obj) {
    writer
      ..writeByte(24)
      ..writeByte(0)
      ..write(obj.id)
      ..writeByte(1)
      ..write(obj.auctionId)
      ..writeByte(2)
      ..write(obj.playerNo)
      ..writeByte(3)
      ..write(obj.name)
      ..writeByte(4)
      ..write(obj.photoBase64)
      ..writeByte(5)
      ..write(obj.age)
      ..writeByte(6)
      ..write(obj.village)
      ..writeByte(7)
      ..write(obj.category)
      ..writeByte(8)
      ..write(obj.battingStyle)
      ..writeByte(9)
      ..write(obj.bowlingStyle)
      ..writeByte(10)
      ..write(obj.matches)
      ..writeByte(11)
      ..write(obj.runs)
      ..writeByte(12)
      ..write(obj.wickets)
      ..writeByte(13)
      ..write(obj.highScore)
      ..writeByte(14)
      ..write(obj.strikeRate)
      ..writeByte(15)
      ..write(obj.economy)
      ..writeByte(16)
      ..write(obj.basePrice)
      ..writeByte(17)
      ..write(obj.isIcon)
      ..writeByte(18)
      ..write(obj.isOwner)
      ..writeByte(19)
      ..write(obj.isRetained)
      ..writeByte(20)
      ..write(obj.retainedTeamId)
      ..writeByte(21)
      ..write(obj.status)
      ..writeByte(22)
      ..write(obj.soldPrice)
      ..writeByte(23)
      ..write(obj.soldTeamId);
  }
}

class BidAdapter extends TypeAdapter<Bid> {
  @override
  final int typeId = 6;

  @override
  Bid read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return Bid(
      id: fields[0] as String,
      auctionId: fields[1] as String,
      playerId: fields[2] as String,
      teamId: fields[3] as String,
      amount: fields[4] as double? ?? 0.0,
      timestamp: fields[5] != null ? DateTime.fromMillisecondsSinceEpoch(fields[5] as int) : DateTime.now(),
    );
  }

  @override
  void write(BinaryWriter writer, Bid obj) {
    writer
      ..writeByte(6)
      ..writeByte(0)
      ..write(obj.id)
      ..writeByte(1)
      ..write(obj.auctionId)
      ..writeByte(2)
      ..write(obj.playerId)
      ..writeByte(3)
      ..write(obj.teamId)
      ..writeByte(4)
      ..write(obj.amount)
      ..writeByte(5)
      ..write(obj.timestamp.millisecondsSinceEpoch);
  }
}

class AppSettingsAdapter extends TypeAdapter<AppSettings> {
  @override
  final int typeId = 7;

  @override
  AppSettings read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return AppSettings(
      profileName: fields[0] as String? ?? '',
      orgName: fields[1] as String? ?? '',
      phone: fields[2] as String? ?? '',
      pin: fields[3] as String? ?? '',
      language: fields[4] as String? ?? 'en',
      soundOn: fields[5] as bool? ?? true,
      voiceOn: fields[6] as bool? ?? true,
      isSetupComplete: fields[7] as bool? ?? false,
      role: fields[8] as UserRole? ?? UserRole.admin,
      orgDescription: fields[9] as String? ?? '',
      auctionReminders: fields[10] as bool? ?? true,
      soldAnimation: fields[11] as bool? ?? true,
      themeAccent: fields[12] as String? ?? 'blue',
      fontSize: fields[13] as String? ?? 'normal',
      autoBackupAfterSale: fields[14] as bool? ?? false,
    );
  }

  @override
  void write(BinaryWriter writer, AppSettings obj) {
    writer
      ..writeByte(15)
      ..writeByte(0)
      ..write(obj.profileName)
      ..writeByte(1)
      ..write(obj.orgName)
      ..writeByte(2)
      ..write(obj.phone)
      ..writeByte(3)
      ..write(obj.pin)
      ..writeByte(4)
      ..write(obj.language)
      ..writeByte(5)
      ..write(obj.soundOn)
      ..writeByte(6)
      ..write(obj.voiceOn)
      ..writeByte(7)
      ..write(obj.isSetupComplete)
      ..writeByte(8)
      ..write(obj.role)
      ..writeByte(9)
      ..write(obj.orgDescription)
      ..writeByte(10)
      ..write(obj.auctionReminders)
      ..writeByte(11)
      ..write(obj.soldAnimation)
      ..writeByte(12)
      ..write(obj.themeAccent)
      ..writeByte(13)
      ..write(obj.fontSize)
      ..writeByte(14)
      ..write(obj.autoBackupAfterSale);
  }
}


class UserRoleAdapter extends TypeAdapter<UserRole> {
  @override
  final int typeId = 8;

  @override
  UserRole read(BinaryReader reader) {
    final index = reader.readByte();
    if (index >= 0 && index < UserRole.values.length) {
      return UserRole.values[index];
    }
    return UserRole.admin;
  }

  @override
  void write(BinaryWriter writer, UserRole obj) {
    writer.writeByte(obj.index);
  }
}
