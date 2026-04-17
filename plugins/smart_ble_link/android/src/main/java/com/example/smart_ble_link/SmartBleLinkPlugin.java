package com.example.smart_ble_link;

import androidx.annotation.NonNull;
import io.flutter.embedding.engine.plugins.FlutterPlugin;
import io.flutter.plugin.common.MethodCall;
import io.flutter.plugin.common.MethodChannel;
import io.flutter.plugin.common.MethodChannel.MethodCallHandler;
import io.flutter.plugin.common.MethodChannel.Result;
import io.flutter.plugin.common.EventChannel;
import io.flutter.plugin.common.EventChannel.EventSink;

import hiflying.blelink.LinkedModule;
import hiflying.blelink.LinkingError;
import hiflying.blelink.LinkingProgress;
import hiflying.blelink.OnLinkListener;
import hiflying.blelink.v1.BleLinker;

import java.util.HashMap;
import java.util.Map;

public class SmartBleLinkPlugin implements FlutterPlugin, MethodCallHandler, OnLinkListener {
  private MethodChannel channel;
  private EventSink eventSink;
  private BleLinker bleLinker;

  @Override
  public void onAttachedToEngine(@NonNull FlutterPluginBinding flutterPluginBinding) {
    channel = new MethodChannel(flutterPluginBinding.getBinaryMessenger(), "smart_ble_link");
    channel.setMethodCallHandler(this);
    
    EventChannel eventChannel = new EventChannel(flutterPluginBinding.getBinaryMessenger(), "smart_ble_link_events");
    eventChannel.setStreamHandler(new EventChannel.StreamHandler() {
      @Override
      public void onListen(Object arguments, EventSink sink) {
        eventSink = sink;
      }

      @Override
      public void onCancel(Object arguments) {
        eventSink = null;
      }
    });
    
    // 初始化 BleLinker
    bleLinker = BleLinker.getInstance(flutterPluginBinding.getApplicationContext());
    bleLinker.init();
    bleLinker.setOnLinkListener(this);
  }

  @Override
  public void onMethodCall(@NonNull MethodCall call, @NonNull Result result) {
    switch (call.method) {
      case "init":
        result.success(true);
        break;
      case "startLinking":
        String ssid = call.argument("ssid");
        String password = call.argument("password");
        String bleName = call.argument("bleName");
        String userData = call.argument("userData");
        int deviceFindingType = call.argument("deviceFindingType");
        
        bleLinker.setSsid(ssid);
        bleLinker.setPassword(password);
        bleLinker.setBleName(bleName);
        bleLinker.setUserData(userData);
        bleLinker.setDeviceFindingType(deviceFindingType);
        
        try {
          bleLinker.start();
          result.success(true);
        } catch (Exception e) {
          result.success(false);
        }
        break;
      case "stopLinking":
        bleLinker.stop();
        result.success(true);
        break;
      default:
        result.notImplemented();
    }
  }

  @Override
  public void onWifiConnectivityChanged(boolean connected, String ssid, android.net.wifi.WifiInfo wifiInfo) {
    // 可选：发送 Wi-Fi 连接状态
  }

  @Override
  public void onBluetoothEnabledChanged(boolean enabled) {
    // 可选：发送蓝牙状态
  }

  @Override
  public void onModuleLinked(LinkedModule module) {
    if (eventSink != null) {
      Map<String, Object> data = new HashMap<>();
      data.put("type", "success");
      data.put("mac", module.getMac());
      data.put("ip", module.getIp());
      data.put("id", module.getId());
      eventSink.success(data);
    }
  }

  @Override
  public void onModuleLinkTimeOut() {
    if (eventSink != null) {
      Map<String, Object> data = new HashMap<>();
      data.put("type", "timeout");
      eventSink.success(data);
    }
  }

  @Override
  public void onFinished() {
    // 可选：发送结束事件
  }

  @Override
  public void onError(LinkingError error) {
    if (eventSink != null) {
      Map<String, Object> data = new HashMap<>();
      data.put("type", "error");
      data.put("message", error.name());
      eventSink.success(data);
    }
  }

  @Override
  public void onProgress(LinkingProgress progress) {
    if (eventSink != null) {
      Map<String, Object> data = new HashMap<>();
      data.put("type", "progress");
      data.put("message", progress.name());
      eventSink.success(data);
    }
  }

  @Override
  public void onDetachedFromEngine(@NonNull FlutterPluginBinding binding) {
    channel.setMethodCallHandler(null);
    bleLinker.destroy();
  }
}
