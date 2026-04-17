import 'dart:async';
import 'package:flutter/services.dart';

class SmartBleLink {
  static const MethodChannel _channel = MethodChannel('smart_ble_link');
  static const EventChannel _eventChannel = EventChannel(
    'smart_ble_link_events',
  );

  // 初始化配网服务
  static Future<bool> init() async {
    return await _channel.invokeMethod('init');
  }

  // 开始配网
  static Future<bool> startLinking({
    required String ssid,
    required String password,
    required String bleName,
    String? userData,
    int deviceFindingType = 3, // 1: UDP, 2: BLE, 3: UDP+BLE
  }) async {
    return await _channel.invokeMethod('startLinking', {
      'ssid': ssid,
      'password': password,
      'bleName': bleName,
      'userData': userData,
      'deviceFindingType': deviceFindingType,
    });
  }

  // 停止配网
  static Future<bool> stopLinking() async {
    return await _channel.invokeMethod('stopLinking');
  }

  // 监听配网状态
  static Stream<LinkingEvent> get linkingEvents {
    return _eventChannel.receiveBroadcastStream().map((event) {
      final Map<dynamic, dynamic> data = event;
      final String type = data['type'];

      switch (type) {
        case 'progress':
          return LinkingProgress(data['message']);
        case 'success':
          return LinkingSuccess(data['mac'], data['ip'], data['id']);
        case 'error':
          return LinkingError(data['message']);
        case 'timeout':
          return LinkingTimeout();
        default:
          return LinkingDefaultEvent(type);
      }
    });
  }
}

// 配网事件基类
abstract class LinkingEvent {
  final String type;
  LinkingEvent(this.type);
}

// 配网进度事件
class LinkingProgress extends LinkingEvent {
  final String message;
  LinkingProgress(this.message) : super('progress');
}

// 配网成功事件
class LinkingSuccess extends LinkingEvent {
  final String mac;
  final String ip;
  final String id;
  LinkingSuccess(this.mac, this.ip, this.id) : super('success');
}

// 配网错误事件
class LinkingError extends LinkingEvent {
  final String message;
  LinkingError(this.message) : super('error');
}

// 配网超时事件
class LinkingTimeout extends LinkingEvent {
  LinkingTimeout() : super('timeout');
}

// 默认配网事件
class LinkingDefaultEvent extends LinkingEvent {
  LinkingDefaultEvent(super.type);
}
