final class KugouSession {
  const KugouSession({
    required this.userId,
    required this.token,
    required this.deviceId,
    required this.mid,
    required this.deviceFingerprint,
    this.installGuid,
    this.installMac,
    this.installDev,
    this.vipToken,
    this.vipType,
    this.refreshMetadata,
    this.updatedAt,
  });

  final String userId;
  final String token;
  final String deviceId;
  final String mid;
  final String deviceFingerprint;
  final String? installGuid;
  final String? installMac;
  final String? installDev;
  final String? vipToken;
  final String? vipType;
  final Map<String, String>? refreshMetadata;
  final DateTime? updatedAt;

  Map<String, dynamic> toJson() {
    return {
      'userId': userId,
      'token': token,
      'deviceId': deviceId,
      'mid': mid,
      'deviceFingerprint': deviceFingerprint,
      'installGuid': installGuid,
      'installMac': installMac,
      'installDev': installDev,
      'vipToken': vipToken,
      'vipType': vipType,
      'refreshMetadata': refreshMetadata,
      'updatedAt': updatedAt?.toIso8601String(),
    };
  }

  factory KugouSession.fromJson(Map<String, dynamic> json) {
    return KugouSession(
      userId: json['userId'] as String,
      token: json['token'] as String,
      deviceId: json['deviceId'] as String,
      mid: json['mid'] as String,
      deviceFingerprint: json['deviceFingerprint'] as String,
      installGuid: json['installGuid'] as String?,
      installMac: json['installMac'] as String?,
      installDev: json['installDev'] as String?,
      vipToken: json['vipToken'] as String?,
      vipType: json['vipType'] as String?,
      refreshMetadata: (json['refreshMetadata'] as Map<dynamic, dynamic>?)?.map(
        (k, v) => MapEntry(k.toString(), v.toString()),
      ),
      updatedAt: json['updatedAt'] != null
          ? DateTime.parse(json['updatedAt'] as String)
          : null,
    );
  }
}
