import 'package:hive/hive.dart';

class AppSettings extends HiveObject {
  String profileName;
  String orgName;
  String phone;
  String pin;
  String language;
  bool soundOn;
  bool voiceOn;

  AppSettings({
    this.profileName = 'JP Arena Admin',
    this.orgName = 'JP Cricket Association',
    this.phone = '+91 98765 43210',
    this.pin = '1234',
    this.language = 'en',
    this.soundOn = true,
    this.voiceOn = true,
  });

  AppSettings copyWith({
    String? profileName,
    String? orgName,
    String? phone,
    String? pin,
    String? language,
    bool? soundOn,
    bool? voiceOn,
  }) {
    return AppSettings(
      profileName: profileName ?? this.profileName,
      orgName: orgName ?? this.orgName,
      phone: phone ?? this.phone,
      pin: pin ?? this.pin,
      language: language ?? this.language,
      soundOn: soundOn ?? this.soundOn,
      voiceOn: voiceOn ?? this.voiceOn,
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
    };
  }

  factory AppSettings.fromMap(Map<String, dynamic> map) {
    return AppSettings(
      profileName: map['profileName'] as String? ?? 'JP Arena Admin',
      orgName: map['orgName'] as String? ?? 'JP Cricket Association',
      phone: map['phone'] as String? ?? '+91 98765 43210',
      pin: map['pin'] as String? ?? '1234',
      language: map['language'] as String? ?? 'en',
      soundOn: map['soundOn'] as bool? ?? true,
      voiceOn: map['voiceOn'] as bool? ?? true,
    );
  }
}
