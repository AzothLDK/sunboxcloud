import 'package:get/get.dart';
import '../pages/auth/login_page.dart';
import '../pages/auth/register_page.dart';
import '../pages/auth/register_success_page.dart';
import '../pages/auth/google_register_page.dart';
import '../pages/mine/complete_profile_page.dart';
import '../pages/mine/setting/language_page.dart';
import '../pages/home/home_page.dart';
import '../pages/device/backup_reserve_page.dart';
import '../pages/mine/my_devices_page.dart';
import '../pages/mine/feedback/feedback_page.dart';
import '../pages/mine/feedback/new_ticket_page.dart';
import '../pages/mine/setting/settings_page.dart';
import '../pages/mine/setting/privacy_policy_page.dart';
import '../pages/mine/setting/app_update_page.dart';
import '../pages/mine/setting/notification_settings_page.dart';
import '../pages/mine/setting/account_page.dart';
import '../pages/mine/setting/reset_password_page.dart';
import '../pages/mine/setting/change_email_page.dart';
import '../pages/mine/setting/notifications_page.dart';
import '../pages/network_config/network_config_page.dart';
import '../pages/network_config/add_device_page.dart';
import '../pages/network_config/scan_page.dart';
import '../pages/mine/device_detail_page.dart';
import '../pages/mine/add_site_page.dart';

class AppRoutes {
  static const String login = '/login';
  static const String register = '/register';
  static const String registerSuccess = '/register-success';
  static const String googleRegister = '/google-register';
  static const String completeProfile = '/complete-profile';
  static const String language = '/language';
  static const String home = '/home';
  static const String backupReserve = '/backup-reserve';
  static const String myDevices = '/my-devices';
  static const String feedback = '/feedback';
  static const String newTicket = '/new-ticket';
  static const String settings = '/settings';
  static const String privacyPolicy = '/privacy-policy';
  static const String appUpdate = '/app-update';
  static const String notificationSettings = '/notification-settings';
  static const String account = '/account';
  static const String resetPassword = '/reset-password';
  static const String notifications = '/notifications';
  static const String distributionNetwork = '/distribution-network';
  static const String bleConfig = '/ble-config';
  static const String scan = '/scan';
  static const String changeEmail = '/change-email';
  static const String deviceDetail = '/device-detail';
  static const String addSite = '/add-site';

  static final routes = [
    GetPage(
      name: addSite,
      page: () => const AddSitePage(),
      transition: Transition.rightToLeft,
    ),
    GetPage(
      name: login,
      page: () => const LoginPage(),
      transition: Transition.fade,
    ),
    GetPage(
      name: register,
      page: () => const RegisterPage(),
      transition: Transition.fade,
    ),
    GetPage(
      name: registerSuccess,
      page: () => const RegisterSuccessPage(),
      transition: Transition.fade,
    ),
    GetPage(
      name: googleRegister,
      page: () => GoogleRegisterPage(email: Get.arguments?['email'] ?? ''),
      transition: Transition.fade,
    ),
    GetPage(
      name: completeProfile,
      page: () => CompleteProfilePage(email: Get.arguments?['email'] ?? ''),
      transition: Transition.fade,
    ),
    GetPage(
      name: language,
      page: () => const LanguagePage(),
      transition: Transition.fade,
    ),
    GetPage(
      name: home,
      page: () => const HomePage(),
      transition: Transition.fade,
    ),
    GetPage(
      name: backupReserve,
      page: () => const BackupReservePage(),
      transition: Transition.fade,
    ),
    GetPage(
      name: myDevices,
      page: () => const MyDevicesPage(),
      transition: Transition.fade,
    ),
    GetPage(
      name: feedback,
      page: () => const FeedbackPage(),
      transition: Transition.fade,
    ),
    GetPage(
      name: newTicket,
      page: () => const NewTicketPage(),
      transition: Transition.fade,
    ),
    GetPage(
      name: settings,
      page: () => const SettingsPage(),
      transition: Transition.fade,
    ),
    GetPage(
      name: privacyPolicy,
      page: () => const PrivacyPolicyPage(),
      transition: Transition.fade,
    ),
    GetPage(
      name: appUpdate,
      page: () => const AppUpdatePage(),
      transition: Transition.fade,
    ),
    GetPage(
      name: notificationSettings,
      page: () => const NotificationSettingsPage(),
      transition: Transition.fade,
    ),
    GetPage(
      name: account,
      page: () => const AccountPage(),
      transition: Transition.fade,
    ),
    GetPage(
      name: resetPassword,
      page: () => const ResetPasswordPage(),
      transition: Transition.fade,
    ),
    GetPage(
      name: notifications,
      page: () => const NotificationsPage(),
      transition: Transition.fade,
    ),
    GetPage(
      name: bleConfig,
      page: () => const AddDevicePage(),
      transition: Transition.rightToLeft,
    ),
    GetPage(
      name: distributionNetwork,
      page: () => const NetworkConfigPage(),
      transition: Transition.rightToLeft,
    ),
    GetPage(
      name: scan,
      page: () => const ScanPage(),
      transition: Transition.rightToLeft,
    ),
    GetPage(
      name: changeEmail,
      page: () => const ChangeEmailPage(),
      transition: Transition.fade,
    ),
    GetPage(
      name: deviceDetail,
      page: () => const DeviceDetailPage(),
      transition: Transition.fade,
    ),
  ];
}
