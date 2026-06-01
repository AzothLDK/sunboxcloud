# Sunbox Cloud - Home (H版)

SunBox Cloud Home 是一款基于 Flutter 开发的家庭能源管理系统客户端。它通过 BLE（蓝牙低功耗）技术实现设备配网，并提供实时数据监控、图表可视化以及多语言支持。

---

## 🚀 功能特性

- **设备配网**：集成 `smart_ble_link` 插件，支持通过蓝牙快速为设备配置网络。
- **状态监控**：实时查看站点及设备运行详情，包括电池电量、功率流向等关键指标。
- **可视化报表**：基于 `flutter_echarts` 实现精美的动态图表，直观展示历史数据。
- **安全保障**：
  - 账号密码登录采用 AES 加密逻辑（`crypto_util.dart`）。
  - 支持 Google / Apple 第三方授权登录。
- **国际化**：基于 GetX 的多语言方案，支持中英文切换。
- **响应式 UI**：遵循 Material 3 设计规范，完美适配 Dark Mode。

---

## 🛠 技术栈

| 模块 | 技术方案 |
| :--- | :--- |
| **开发框架** | [Flutter](https://flutter.dev/) |
| **状态管理/路由** | [GetX](https://pub.dev/packages/get) |
| **网络请求** | [Dio](https://pub.dev/packages/dio) |
| **本地存储** | [SharedPreferences](https://pub.dev/packages/shared_preferences) |
| **数据可视化** | [flutter_echarts](https://pub.dev/packages/flutter_echarts) |
| **蓝牙通信** | [smart_ble_link](plugins/smart_ble_link/) |
| **权限管理** | [permission_handler](https://pub.dev/packages/permission_handler) |

---

## 📂 项目结构

```text
lib/
├── controllers/          # 业务逻辑 (GetX Controllers)
├── pages/                # UI 页面
│   ├── login/            # 登录模块
│   ├── home/             # 首页及设备列表
│   └── distribution/     # BLE 配网模块
├── model/                # 数据模型
├── routes/               # 路由定义 (app_routes.dart)
├── utils/                
│   ├── network/          # 网络请求封装 (Dio, ApiService)
│   ├── storage/          # 本地存储 (GlobalStorage)
│   └── i18n/             # 国际化语言包
└── plugins/              # 本地插件 (如 smart_ble_link)
```

---

## 🏁 快速开始

### 1. 环境准备
确保已安装 Flutter SDK (建议版本 >= 3.x) 且配置好 Android/iOS 开发环境。

### 2. 获取代码
```bash
git clone http://gitlab.smartwuxi.com/sunbox/sunbox-app.git
cd sunboxcloud
```

### 3. 安装依赖
```bash
flutter pub get
```

### 4. 运行项目
```bash
# 启动到连接的设备
flutter run

# 运行到特定设备
flutter run -d <device_id>
```

---

## ⚙️ 配置说明

### 后端环境
网络请求的基础 URL 在 [http_manager.dart](file:///Users/ludaokuo/Documents/项目/sunboxcloud/lib/utils/network/http_manager.dart) 中配置。

### 登录加密
所有敏感接口请求均经过 AES 加密处理，逻辑详见 [crypto_util.dart](file:///Users/ludaokuo/Documents/项目/sunboxcloud/lib/utils/network/crypto_util.dart)。

### 第三方登录配置
- **Google 登录**：需在 `lib/services/social_auth_service.dart` 配置 `serverClientId`，并确保 Android 端拥有 `google-services.json`。
- **Apple 登录**：需在开发者后台开启 Sign In with Apple 权限。

---

## 🌿 Git 规范

本项目采用多分支管理模式：
- **main**：主分支，保持代码稳定，对应生产环境。
- **develop**：开发分支，日常功能集成分支。

### 常用命令
```bash
# 推送到 GitLab
git push origin develop

# 同时同步到 GitHub (备用)
git push github develop
```

---

## ⚠️ 常见问题 (FAQ)

**Q: 启动时报 `SharedPreferences` 未初始化？**  
A: 请确保 `main.dart` 中已先调用 `WidgetsFlutterBinding.ensureInitialized()`，并正确初始化了 `GlobalStorage`。

**Q: Android 编译 `smart_ble_link` 失败？**  
A: 通常是 Gradle 版本冲突。请检查插件内部的 `build.gradle`，建议将版本控制权交给主工程。

---

© 2026 Sunbox Cloud Team. All rights reserved.
