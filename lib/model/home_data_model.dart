class HomeDataModel {
  final String? weather;
  final double? temperature;
  final double? solar;
  final double? grid;
  final double? storage;
  final double? site;
  final double? ssRate;
  final double? pvPower;
  final double? loadPower;
  final double? chargePower;
  final double? dischargePower;
  final double? gridPower;
  final double? gridSellPower;
  final double? bsoc;
  final String? icon;
  final double? ev;

  HomeDataModel({
    this.weather,
    this.temperature,
    this.solar,
    this.grid,
    this.storage,
    this.site,
    this.ssRate,
    this.pvPower,
    this.loadPower,
    this.chargePower,
    this.dischargePower,
    this.gridPower,
    this.gridSellPower,
    this.bsoc,
    this.icon,
    this.ev,
  });

  factory HomeDataModel.fromJson(Map<String, dynamic> json) {
    return HomeDataModel(
      weather: json['weather']?.toString(),
      temperature: _toDouble(json['temperature']),
      solar: _toDouble(json['solar']),
      grid: _toDouble(json['grid']),
      storage: _toDouble(json['storage']),
      site: _toDouble(json['site']),
      ssRate: _toDouble(json['ssRate']),
      pvPower: _toDouble(json['pvPower']),
      loadPower: _toDouble(json['loadPower']),
      chargePower: _toDouble(json['chargePower']),
      dischargePower: _toDouble(json['dischargePower']),
      gridPower: _toDouble(json['gridPower']),
      gridSellPower: _toDouble(json['gridSellPower']),
      bsoc: _toDouble(json['bsoc']),
      icon: json['icon']?.toString(),
      ev: _toDouble(json['ev']),
    );
  }

  static double? _toDouble(dynamic value) {
    if (value == null) return null;
    if (value is num) return value.toDouble();
    if (value is String) return double.tryParse(value);
    return null;
  }

  Map<String, dynamic> toJson() {
    return {
      'weather': weather,
      'temperature': temperature,
      'solar': solar,
      'grid': grid,
      'storage': storage,
      'site': site,
      'ssRate': ssRate,
      'pvPower': pvPower,
      'loadPower': loadPower,
      'chargePower': chargePower,
      'dischargePower': dischargePower,
      'gridPower': gridPower,
      'gridSellPower': gridSellPower,
      'bsoc': bsoc,
      'icon': icon,
      'ev': ev,
    };
  }
}
