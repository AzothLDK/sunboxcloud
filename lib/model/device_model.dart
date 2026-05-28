class DeviceModel {
  final String? id;
  final String? deviceName;
  final String? deviceType;
  final String? deviceCode;
  final String? status;
  final String? sn;
  final String? stationId;
  final String? createTime;
  final double? soc;
  final double? chargedEnergy;
  final double? dischargedEnergy;
  final int? standby;
  final double? power;

  DeviceModel({
    this.id,
    this.deviceName,
    this.deviceType,
    this.deviceCode,
    this.status,
    this.sn,
    this.stationId,
    this.createTime,
    this.soc,
    this.chargedEnergy,
    this.dischargedEnergy,
    this.standby,
    this.power,
  });

  factory DeviceModel.fromJson(Map<String, dynamic> json) {
    String? status;
    if (json['standby'] == 1) {
      status = 'online';
    } else if (json['standby'] == 0) {
      status = 'offline';
    } else {
      status = json['status']?.toString();
    }

    return DeviceModel(
      id: json['id']?.toString(),
      deviceName: (json['deviceName'] ?? json['deviceType'] ?? 'SunBox')
          .toString(),
      deviceType: json['deviceType']?.toString(),
      deviceCode: json['deviceCode']?.toString(),
      status: status,
      sn: (json['sn'] ?? json['deviceCode'])?.toString(),
      stationId: json['stationId']?.toString(),
      createTime: json['createTime']?.toString(),
      soc: ((json['soc']) as num?)?.toDouble() ?? 00.0,
      chargedEnergy:
          ((json['chargedEnergy'] ?? json['charge']) as num?)?.toDouble() ??
          0.0,
      dischargedEnergy:
          ((json['dischargedEnergy'] ?? json['discharge']) as num?)
              ?.toDouble() ??
          0.0,
      standby: json['standby'] as int?,
      power: ((json['power']) as num?)?.toDouble(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'deviceName': deviceName,
      'deviceType': deviceType,
      'deviceCode': deviceCode,
      'status': status,
      'sn': sn,
      'stationId': stationId,
      'createTime': createTime,
      'soc': soc,
      'chargedEnergy': chargedEnergy,
      'dischargedEnergy': dischargedEnergy,
      'standby': standby,
      'power': power,
    };
  }
}
