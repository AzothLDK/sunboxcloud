# sunboxcloud

SunBox Cloud Flutter 客户端工程。

## 功能概览

- 登录：账号密码登录（含请求加密逻辑）
- 站点/设备：设备列表、设备详情（含图表展示）
- 配网：BLE 配网（集成 `smart_ble_link`）
- 多语言：基于 GetX 的 `tr` 机制
- 第三方登录：Google / Apple（需要各自平台配置）

## 技术栈

- Flutter + Material
- 状态管理/路由：GetX
- 网络：Dio（统一封装在 `HttpManager`）
- 图表：flutter_echarts
- 本地存储：shared_preferences（封装在 `GlobalStorage`）
- 加密：encrypt（用于请求加密）
- 权限：permission_handler

## 目录结构（核心）

- `lib/main.dart`：入口
- `lib/routes/`：路由定义
- `lib/controllers/`：业务控制器（登录等）
- `lib/pages/`：页面
  - `pages/login_page.dart`：登录页
  - `pages/home/`：主页/设备页
  - `pages/distributionNetwork/`：设备配网页
- `lib/utils/network/`：网络与加密
  - `http_manager.dart`：Dio 单例与拦截器、统一错误处理
  - `api_service.dart`：接口封装
  - `crypto_util.dart`：请求加密工具
- `lib/utils/storage.dart`：本地存储封装（token、账号密码等）
- `plugins/smart_ble_link/`：BLE 配网插件（本地 path 依赖）

## 快速开始

### 1) 安装依赖

```bash
flutter pub get
```

### 2) 运行（Android / iOS）

```bash
flutter run
```

如果要指定设备：

```bash
flutter devices
flutter run -d <device_id>
```

## 环境与配置

### 后端地址

项目网络请求入口在 [http_manager.dart](file:///Users/ludaokuo/Documents/项目/sunboxcloud/lib/utils/network/http_manager.dart) 中的 `host` 常量（`baseUrl`）。如需切换环境，修改该值即可。

### 登录接口

登录封装在 [api_service.dart](file:///Users/ludaokuo/Documents/项目/sunboxcloud/lib/utils/network/api_service.dart) 的 `login(...)`，控制器调用位于 [auth_controller.dart](file:///Users/ludaokuo/Documents/项目/sunboxcloud/lib/controllers/auth_controller.dart) 的 `login()`。

注意：登录请求包含加密逻辑（见 `crypto_util.dart`），需与后端保持一致。

### 本地存储（账号/密码/Token）

本地存储封装在 [storage.dart](file:///Users/ludaokuo/Documents/项目/sunboxcloud/lib/utils/storage.dart)。  
应用启动时需要先初始化（`main.dart` 中已处理）。

### Google / Apple 登录

- Google 登录需要 Android 侧完成配置，否则会报：
  `serverClientId must be provided on Android`
- `serverClientId` 在 [social_auth_service.dart](file:///Users/ludaokuo/Documents/项目/sunboxcloud/lib/services/social_auth_service.dart) 中配置
- Android 侧通常还需要 `google-services.json`、并完成对应 Gradle 配置

如果暂时不需要第三方登录，可以先不配置，代码已做异常捕获避免影响主流程。

### BLE 配网

- 页面入口：`lib/pages/distributionNetwork/distributionNetwork_page.dart`
- 插件：`plugins/smart_ble_link`
- Android / iOS 权限需正确配置（Android 动态申请 + iOS Info.plist 声明）

## 常见问题

### 1) 登录时报 SharedPreferences 未初始化

现象：`LateInitializationError: Field '_sp' has not been initialized`  
处理：确保 `main.dart` 中调用了 `WidgetsFlutterBinding.ensureInitialized()` 并初始化 `GlobalStorage`。

### 2) Android 编译 smart_ble_link 插件失败（Gradle 版本冲突）

如果插件 build.gradle 内部声明了 AGP version，可能与主工程冲突。建议保持插件侧不声明 version，统一由主工程管理。

## 关联 GitLab 仓库

目标仓库：`http://gitlab.smartwuxi.com/ludaokuo/sunboxcloud-h.git`

在项目根目录执行：

```bash
git init
git remote add origin http://gitlab.smartwuxi.com/ludaokuo/sunboxcloud-h.git
git remote -v
```

首次推送（按实际分支名调整）：

```bash
git add .
git commit -m "init"
git push -u origin main
```
