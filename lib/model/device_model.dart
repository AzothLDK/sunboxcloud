class DeviceModel {
  final String? id;
  final String? deviceName;
  final String? deviceType;
  final String? status;
  final String? sn;
  final String? stationId;
  final String? createTime;
  final double? soc;
  final double? chargedEnergy;
  final double? dischargedEnergy;

  DeviceModel({
    this.id,
    this.deviceName,
    this.deviceType,
    this.status,
    this.sn,
    this.stationId,
    this.createTime,
    this.soc,
    this.chargedEnergy,
    this.dischargedEnergy,
  });

  factory DeviceModel.fromJson(Map<String, dynamic> json) {
    return DeviceModel(
      id: json['id']?.toString(),
      deviceName: json['deviceName']?.toString(),
      deviceType: json['deviceType']?.toString(),
      status: json['status']?.toString(),
      sn: json['sn']?.toString(),
      stationId: json['stationId']?.toString(),
      createTime: json['createTime']?.toString(),
      soc: (json['soc'] as num?)?.toDouble(),
      chargedEnergy: (json['chargedEnergy'] as num?)?.toDouble(),
      dischargedEnergy: (json['dischargedEnergy'] as num?)?.toDouble(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'deviceName': deviceName,
      'deviceType': deviceType,
      'status': status,
      'sn': sn,
      'stationId': stationId,
      'createTime': createTime,
      'soc': soc,
      'chargedEnergy': chargedEnergy,
      'dischargedEnergy': dischargedEnergy,
    };
  }
}
