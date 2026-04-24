class StationModel {
  final String? id;
  final String? stationName;
  final String? stationType;
  final String? status;
  final String? location;
  final String? detailAddress;
  final String? createTime;

  StationModel({
    this.id,
    this.stationName,
    this.stationType,
    this.status,
    this.location,
    this.detailAddress,
    this.createTime,
  });

  factory StationModel.fromJson(Map<String, dynamic> json) {
    return StationModel(
      id: json['id']?.toString(),
      stationName: json['stationName']?.toString(),
      stationType: json['stationType']?.toString(),
      status: json['status']?.toString(),
      location: json['location']?.toString(),
      detailAddress: json['detailAddress']?.toString(),
      createTime: json['createTime']?.toString(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'stationName': stationName,
      'stationType': stationType,
      'status': status,
      'location': location,
      'detailAddress': detailAddress,
      'createTime': createTime,
    };
  }
}
