class TicketModel {
  final String? stationId;
  final int? id;
  final String? deviceId;
  final String? ticketType;
  final String? contact;
  final int? contactType;
  final String? remark;
  final String? picture;

  TicketModel({
    this.stationId,
    this.id,
    this.deviceId,
    this.ticketType,
    this.contact,
    this.contactType,
    this.remark,
    this.picture,
  });

  factory TicketModel.fromJson(Map<String, dynamic> json) {
    return TicketModel(
      stationId: json['stationId']?.toString(),
      id: json['id'] as int?,
      deviceId: json['deviceId']?.toString(),
      ticketType: json['ticketType']?.toString(),
      contact: json['contact']?.toString(),
      contactType: json['contactType'] as int?,
      remark: json['remark']?.toString(),
      picture: json['picture']?.toString(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'stationId': stationId,
      'id': id,
      'deviceId': deviceId,
      'ticketType': ticketType,
      'contact': contact,
      'contactType': contactType,
      'remark': remark,
      'picture': picture,
    };
  }
}
