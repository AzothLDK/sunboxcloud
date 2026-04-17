#import "SmartBleLinkPlugin.h"
#import "JYTools.h"
#import "UDPManage.h"

@interface SmartBleLinkPlugin () <BleDelegate, udpDelegate>
@property (nonatomic, strong) FlutterEventSink eventSink;
@property (nonatomic, strong) NSTimer *udpTimer;
@property (nonatomic, strong) NSTimer *timeoutTimer;
@property (nonatomic, copy) NSString *userData;
@end

@implementation SmartBleLinkPlugin

+ (void)registerWithRegistrar:(NSObject<FlutterPluginRegistrar>*)registrar {
  FlutterMethodChannel* channel = [FlutterMethodChannel
      methodChannelWithName:@"smart_ble_link"
            binaryMessenger:[registrar messenger]];
  FlutterEventChannel* eventChannel = [FlutterEventChannel
      eventChannelWithName:@"smart_ble_link_events"
            binaryMessenger:[registrar messenger]];
  
  SmartBleLinkPlugin* instance = [[SmartBleLinkPlugin alloc] init];
  [registrar addMethodCallDelegate:instance channel:channel];
  [eventChannel setStreamHandler:instance];
}

- (FlutterError* _Nullable)onMethodCall:(FlutterMethodCall* _Nonnull)call result:(FlutterResult _Nonnull)result {
  if ([@"init" isEqualToString:call.method]) {
    [[UDPManage shareUDPManage] setUDPDelegate:self];
    result(@YES);
  } else if ([@"startLinking" isEqualToString:call.method]) {
    NSString* ssid = call.arguments[@"ssid"];
    NSString* password = call.arguments[@"password"];
    NSString* bleName = call.arguments[@"bleName"];
    NSString* userData = call.arguments[@"userData"];
    
    self.userData = userData;
    
    [JYTools setSSID:ssid];
    [JYTools setPassword:password];
    [JYTools setBLEName:bleName];
    [JYTools setUserData:userData];
    [[JYTools shareInstance] scanDevice];
    [JYTools shareInstance].discoverDelegate = self;
    
    [self startUdpTimer];
    [self startTimeoutTimer];
    
    result(@YES);
  } else if ([@"stopLinking" isEqualToString:call.method]) {
    [self stopAllLinking];
    result(@YES);
  } else {
    result(FlutterMethodNotImplemented);
  }
  return nil;
}

- (void)stopAllLinking {
    [self stopUdpTimer];
    [self stopTimeoutTimer];
    [[JYTools shareInstance] stopScan];
    [[JYTools shareInstance] unConnectDevice];
}

- (void)startUdpTimer {
    [self stopUdpTimer];
    self.udpTimer = [NSTimer timerWithTimeInterval:1.0f target:self selector:@selector(sendUdpBroadcast) userInfo:nil repeats:YES];
    [[NSRunLoop mainRunLoop] addTimer:self.udpTimer forMode:NSDefaultRunLoopMode];
}

- (void)stopUdpTimer {
    if (self.udpTimer) {
        [self.udpTimer invalidate];
        self.udpTimer = nil;
    }
}

- (void)sendUdpBroadcast {
    [[UDPManage shareUDPManage] broadcast];
}

- (void)startTimeoutTimer {
    [self stopTimeoutTimer];
    self.timeoutTimer = [NSTimer timerWithTimeInterval:60.0f target:self selector:@selector(linkingTimeout) userInfo:nil repeats:NO];
    [[NSRunLoop mainRunLoop] addTimer:self.timeoutTimer forMode:NSDefaultRunLoopMode];
}

- (void)stopTimeoutTimer {
    if (self.timeoutTimer) {
        [self.timeoutTimer invalidate];
        self.timeoutTimer = nil;
    }
}

- (void)linkingTimeout {
    [self stopAllLinking];
    if (self.eventSink) {
        self.eventSink(@{
            @"type": @"timeout"
        });
    }
}

- (FlutterError* _Nullable)onListenWithArguments:(id _Nullable)arguments eventSink:(FlutterEventSink _Nonnull)events {
  self.eventSink = events;
  return nil;
}

- (FlutterError* _Nullable)onCancelWithArguments:(id _Nullable)arguments {
  self.eventSink = nil;
  return nil;
}

#pragma mark - BleDelegate
- (void)BLEDidDiscoverDeviceWithMAC:(CBPeripheral *)peripheral {
  [[JYTools shareInstance] stopScan];
  [[JYTools shareInstance] connectDevice:peripheral];
}

- (void)BLEDidFinishedWithResult:(BOOL)result andPara:(NSMutableArray *)para {
  [self stopAllLinking];
  if (self.eventSink) {
    if (result) {
      self.eventSink(@{
        @"type": @"success",
        @"mac": para[1] ? para[1] : @"",
        @"ip": para[0] ? para[0] : @"",
        @"id": @""
      });
    } else {
      self.eventSink(@{
        @"type": @"error",
        @"message": para[0] ? para[0] : @"Unknown error"
      });
    }
  }
}

- (void)BLEDidGetDeviceMac:(NSString *)mac {
  if (self.userData && self.userData.length > 0) {
      [[JYTools shareInstance] setUserDataAndContinue:self.userData];
  } else {
      [[JYTools shareInstance] setUserDataAndContinue:@""];
  }
}

- (void)BLEIsSuccesee:(NSString *)str {
  if (self.eventSink) {
    self.eventSink(@{
      @"type": @"progress",
      @"message": str ? str : @""
    });
  }
}

#pragma mark - udpDelegate
- (void)isUDPSuccess:(NSMutableArray *)arr {
  [self stopAllLinking];
  if (self.eventSink) {
    self.eventSink(@{
      @"type": @"success",
      @"mac": arr.count > 1 ? arr[1] : @"",
      @"ip": arr.count > 0 ? arr[0] : @"",
      @"id": @""
    });
  }
}

- (void)dataIsSuccess:(NSString *)str {
  if (self.eventSink) {
    self.eventSink(@{
      @"type": @"progress",
      @"message": str ? str : @""
    });
  }
}

@end
