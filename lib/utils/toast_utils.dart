import 'package:flutter/material.dart';
import 'package:get/get.dart';

class ToastUtils {
  static void showSnackBar(
    String title,
    String message, {
    Color? backgroundColor,
    Color? colorText,
    SnackPosition snackPosition = SnackPosition.TOP,
    Duration duration = const Duration(seconds: 1),
  }) {
    Get.closeAllSnackbars();
    Get.snackbar(
      title,
      message,
      backgroundColor: backgroundColor ?? Colors.grey[800],
      colorText: colorText ?? Colors.white,
      snackPosition: snackPosition,
      duration: duration,
      margin: const EdgeInsets.all(16),
      borderRadius: 12,
      isDismissible: true,
      dismissDirection: DismissDirection.horizontal,
    );
  }

  static void success(String message, {String? title}) {
    showSnackBar(title ?? 'success'.tr, message, backgroundColor: Colors.green);
  }

  static void error(String message, {String? title}) {
    showSnackBar(title ?? 'error'.tr, message, backgroundColor: Colors.red);
  }

  static void warning(String message, {String? title}) {
    showSnackBar(
      title ?? 'warning'.tr,
      message,
      backgroundColor: Colors.orange,
    );
  }

  static void info(String message, {String? title}) {
    showSnackBar(title ?? 'info'.tr, message, backgroundColor: Colors.blue);
  }
}
