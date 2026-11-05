import 'package:hive/hive.dart';
import 'enums.dart';

class AppSettings extends HiveObject {
  String profileName;
  String orgName;
  String phone;
  String pin;
  String language;
  bool soundOn;
  bool voiceOn;
  bool isSetupComplete;
  UserRole role;

  AppSettings({
    this.profileName = '',
    this.orgName = '',
    this.phone = '',
    this.pin = '',
    this.language = 'en',
    this.soundOn = true,
    this.voiceOn = true,
    this.isSetupComplete = false,
    this.role = UserRole.admin,
  });

  AppSettings copyWith({
    String? profileName,
    String? orgName,
    String? phone,
    String? pin,
    String? language,
    bool? soundOn,
    bool? voiceOn,
    bool? isSetupComplete,
    UserRole? role,
  }) {
    return AppSettings(
      profileName: profileName ?? this.profileName,
      orgName: orgName ?? this.orgName,
      phone: phone ?? this.phone,
      pin: pin ?? this.pin,
      language: language ?? this.language,
      soundOn: soundOn ?? this.soundOn,
      voiceOn: voiceOn ?? this.voiceOn,
      isSetupComplete: isSetupComplete ?? this.isSetupComplete,
      role: role ?? this.role,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'profileName': profileName,
      'orgName': orgName,
      'phone': phone,
      'pin': pin,
      'language': language,
      'soundOn': soundOn,
      'voiceOn': voiceOn,
      'isSetupComplete': isSetupComplete,
      'role': role.name,
    };
  }

  factory AppSettings.fromMap(Map<String, dynamic> map) {
    return AppSettings(
      profileName: map['profileName'] as String? ?? '',
      orgName: map['orgName'] as String? ?? '',
      phone: map['phone'] as String? ?? '',
      pin: map['pin'] as String? ?? '',
      language: map['language'] as String? ?? 'en',
      soundOn: map['soundOn'] as bool? ?? true,
      voiceOn: map['voiceOn'] as bool? ?? true,
      isSetupComplete: map['isSetupComplete'] as bool? ?? false,
      role: UserRole.fromString(map['role'] as String?),
    );
  }
}
