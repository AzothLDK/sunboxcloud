class StationModel {
  final String? id;
  final String? stationName;
  final String? stationType;
  final String? status;
  final String? location;
  final String? detailAddress;
  final String? createTime;
  final List<RegionNode>? regionNodes;

  StationModel({
    this.id,
    this.stationName,
    this.stationType,
    this.status,
    this.location,
    this.detailAddress,
    this.createTime,
    this.regionNodes,
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
      regionNodes: (json['regionNodes'] as List?)
          ?.map((e) => RegionNode.fromJson(e))
          .toList(),
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
      'regionNodes': regionNodes?.map((e) => e.toJson()).toList(),
    };
  }
}

class RegionNode {
  final int? id;
  final String? name;

  RegionNode({this.id, this.name});

  factory RegionNode.fromJson(Map<String, dynamic> json) {
    return RegionNode(id: json['id'] as int?, name: json['name']?.toString());
  }

  Map<String, dynamic> toJson() {
    return {'id': id, 'name': name};
  }
}
