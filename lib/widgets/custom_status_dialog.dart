import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../utils/constants.dart';

enum CustomDialogType { success, error, info }

class CustomStatusDialog extends StatelessWidget {
  final CustomDialogType type;
  final String title;
  final String message;
  final String? confirmText;
  final VoidCallback? onConfirm;

  const CustomStatusDialog({
    super.key,
    required this.type,
    required this.title,
    required this.message,
    this.confirmText,
    this.onConfirm,
  });

  static void show({
    required CustomDialogType type,
    String? title,
    required String message,
    String? confirmText,
    VoidCallback? onConfirm,
  }) {
    Get.dialog(
      CustomStatusDialog(
        type: type,
        title: title ?? _getDefaultTitle(type),
        message: message,
        confirmText: confirmText ?? 'confirm'.tr,
        onConfirm: onConfirm,
      ),
      barrierDismissible: false,
    );
  }

  static String _getDefaultTitle(CustomDialogType type) {
    switch (type) {
      case CustomDialogType.success:
        return 'success'.tr;
      case CustomDialogType.error:
        return 'error'.tr;
      case CustomDialogType.info:
        return 'info'.tr;
    }
  }

  @override
  Widget build(BuildContext context) {
    Color statusColor;
    IconData iconData;

    switch (type) {
      case CustomDialogType.success:
        statusColor = const Color(0xFF24C18F);
        iconData = Icons.check_circle_outline;
        break;
      case CustomDialogType.error:
        statusColor = errorColor;
        iconData = Icons.error_outline;
        break;
      case CustomDialogType.info:
        statusColor = primaryColor;
        iconData = Icons.info_outline;
        break;
    }

    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      backgroundColor: Colors.white,
      child: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // 图标
            Container(
              width: 56,
              height: 56,
              decoration: BoxDecoration(
                color: statusColor.withValues(alpha: 0.1),
                shape: BoxShape.circle,
              ),
              child: Icon(
                iconData,
                color: statusColor,
                size: 28,
              ),
            ),
            const SizedBox(height: 20),
            // 标题
            Text(
              title,
              style: const TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: textColor,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 12),
            // 内容
            Text(
              message,
              style: const TextStyle(
                fontSize: 14,
                color: textLightColor,
                height: 1.5,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 28),
            // 确认按钮
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () {
                  Get.back();
                  if (onConfirm != null) {
                    onConfirm!();
                  }
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: primaryColor,
                  elevation: 0,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: Text(
                  confirmText ?? 'confirm'.tr,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
