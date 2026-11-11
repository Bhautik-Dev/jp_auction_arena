import 'package:hive/hive.dart';
import 'enums.dart';

class AppSettings extends HiveObject {
  String profileName;
  String orgName;
  String orgDescription;
  String phone;
  String pin;
  String language;
  bool soundOn;
  bool voiceOn;
  bool auctionReminders;
  bool soldAnimation;
  String themeAccent; // 'blue', 'purple', 'pink'
  String fontSize; // 'normal', 'large', 'compact'
  bool autoBackupAfterSale;
  bool isSetupComplete;
  UserRole role;

  AppSettings({
    this.profileName = '',
    this.orgName = '',
    this.orgDescription = '',
    this.phone = '',
    this.pin = '',
    this.language = 'en',
    this.soundOn = true,
    this.voiceOn = true,
    this.auctionReminders = true,
    this.soldAnimation = true,
    this.themeAccent = 'blue',
    this.fontSize = 'normal',
    this.autoBackupAfterSale = false,
    this.isSetupComplete = false,
    this.role = UserRole.admin,
  });

  AppSettings copyWith({
    String? profileName,
    String? orgName,
    String? orgDescription,
    String? phone,
    String? pin,
    String? language,
    bool? soundOn,
    bool? voiceOn,
    bool? auctionReminders,
    bool? soldAnimation,
    String? themeAccent,
    String? fontSize,
    bool? autoBackupAfterSale,
    bool? isSetupComplete,
    UserRole? role,
  }) {
    return AppSettings(
      profileName: profileName ?? this.profileName,
      orgName: orgName ?? this.orgName,
      orgDescription: orgDescription ?? this.orgDescription,
      phone: phone ?? this.phone,
      pin: pin ?? this.pin,
      language: language ?? this.language,
      soundOn: soundOn ?? this.soundOn,
      voiceOn: voiceOn ?? this.voiceOn,
      auctionReminders: auctionReminders ?? this.auctionReminders,
      soldAnimation: soldAnimation ?? this.soldAnimation,
      themeAccent: themeAccent ?? this.themeAccent,
      fontSize: fontSize ?? this.fontSize,
      autoBackupAfterSale: autoBackupAfterSale ?? this.autoBackupAfterSale,
      isSetupComplete: isSetupComplete ?? this.isSetupComplete,
      role: role ?? this.role,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'profileName': profileName,
      'orgName': orgName,
      'orgDescription': orgDescription,
      'phone': phone,
      'pin': pin,
      'language': language,
      'soundOn': soundOn,
      'voiceOn': voiceOn,
      'auctionReminders': auctionReminders,
      'soldAnimation': soldAnimation,
      'themeAccent': themeAccent,
      'fontSize': fontSize,
      'autoBackupAfterSale': autoBackupAfterSale,
      'isSetupComplete': isSetupComplete,
      'role': role.name,
    };
  }

  factory AppSettings.fromMap(Map<String, dynamic> map) {
    return AppSettings(
      profileName: map['profileName'] as String? ?? '',
      orgName: map['orgName'] as String? ?? '',
      orgDescription: map['orgDescription'] as String? ?? '',
      phone: map['phone'] as String? ?? '',
      pin: map['pin'] as String? ?? '',
      language: map['language'] as String? ?? 'en',
      soundOn: map['soundOn'] as bool? ?? true,
      voiceOn: map['voiceOn'] as bool? ?? true,
      auctionReminders: map['auctionReminders'] as bool? ?? true,
      soldAnimation: map['soldAnimation'] as bool? ?? true,
      themeAccent: map['themeAccent'] as String? ?? 'blue',
      fontSize: map['fontSize'] as String? ?? 'normal',
      autoBackupAfterSale: map['autoBackupAfterSale'] as bool? ?? false,
      isSetupComplete: map['isSetupComplete'] as bool? ?? false,
      role: UserRole.fromString(map['role'] as String?),
    );
  }
}
