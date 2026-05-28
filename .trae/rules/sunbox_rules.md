---
alwaysApply: true
---
# SunboxCloud Project Rules

**Role:** Senior Flutter Engineer. High-performance, clean, and maintainable code.

**Core Stack:**
* **State Management:** `GetX`. Use `.obs` for reactive variables and `Obx` for UI updates.
* **Navigation:** `GetX`. Use `Get.toNamed()`, `Get.back()`, and `Get.arguments`.
* **Dependency Injection:** `GetX`. Use `Get.put()`, `Get.find()`, and `Get.lazyPut()`.
* **Hardware:** `flutter_blue_plus` (Bluetooth), `device_info_plus` (Device info), `permission_handler` (Permissions).

**Architecture & Patterns:**
* **Folder Structure:** 
    * `lib/pages/`: UI screens.
    * `lib/controllers/`: Business logic (GetxControllers).
    * `lib/model/`: Data models.
    * `lib/routes/`: Route definitions in `app_routes.dart`.
* **Controller Lifecycle:**
    * **Global Controllers:** Use `Get.put(Controller(), permanent: true)` for states that must persist (e.g., `StationController`).
    * **Defensive Access:** Always use `Get.isRegistered<T>() ? Get.find<T>() : Get.put(T())` in build methods to prevent "Controller not found" crashes.
    * **Cleanup:** Manually call `Get.delete<T>(force: true)` for permanent controllers during logout.
* **Route Arguments:** Capture `Get.arguments` in `initState` or `onInit` and store them in local variables to avoid `null` issues after dialogs or nested navigation.

**Hardware & Native:**
* **Emulator Check:** Always check `!deviceInfo.isPhysicalDevice` before calling Bluetooth, WiFi, or other hardware APIs.
* **Permissions:** Use `permission_handler` to request `bluetoothScan`, `bluetoothConnect`, and `location` before hardware operations.

**UI & Design:**
* **Primary Color:** `0xFF2B5CFF` (Sunbox Blue).
* **Components:** Material 3, custom animations (e.g., Radar scan).
* **Toasts/Snackbars:** Always use `ToastUtils` (from `lib/utils/toast_utils.dart`) for user feedback. Avoid using `Get.snackbar` directly.
* **Localization (i18n):** All user-facing strings must use GetX localization. Use `'string_key'.tr` and ensure keys are defined in `lib/utils/messages.dart` (or the project's translation file). Avoid hardcoding Chinese or English strings directly in UI.
* **Lists:** Use `ListView.builder` for performance.

**Code Quality:**
* **Naming:** `PascalCase` for classes, `camelCase` for variables/methods, `snake_case` for files.
* **Async:** Use `async/await` with `try-catch` blocks.
* **Logging:** Use `debugPrint` or `dart:developer.log`.
