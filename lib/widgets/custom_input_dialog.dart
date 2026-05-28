import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../utils/constants.dart';

class InputFieldConfig {
  final String label;
  final String hintText;
  final TextEditingController controller;
  final int maxLines;

  InputFieldConfig({
    required this.label,
    required this.hintText,
    required this.controller,
    this.maxLines = 1,
  });
}

class CustomInputDialog extends StatelessWidget {
  final String title;
  final List<InputFieldConfig> fields;
  final List<Widget>? additionalWidgets;
  final VoidCallback onCancel;
  final VoidCallback onSave;

  const CustomInputDialog({
    super.key,
    required this.title,
    required this.fields,
    this.additionalWidgets,
    required this.onCancel,
    required this.onSave,
  });

  static Future<void> show({
    required BuildContext context,
    required String title,
    required List<InputFieldConfig> fields,
    List<Widget>? additionalWidgets,
    required VoidCallback onSave,
  }) {
    return showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => CustomInputDialog(
        title: title,
        fields: fields,
        additionalWidgets: additionalWidgets,
        onCancel: () => Navigator.pop(context),
        onSave: onSave,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      backgroundColor: Colors.white,
      insetPadding: const EdgeInsets.symmetric(horizontal: 24, vertical: 24),
      child: Padding(
        padding: const EdgeInsets.all(24.0),
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Title
              Text(
                title,
                style: const TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: textColor,
                ),
              ),
              const SizedBox(height: 10),

              // Fields
              ...fields.map((field) {
                return Padding(
                  padding: const EdgeInsets.only(bottom: 16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        field.label,
                        style: const TextStyle(
                          fontSize: 14,
                          color: textLightColor,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      const SizedBox(height: 8),
                      TextField(
                        controller: field.controller,
                        maxLines: field.maxLines,
                        style: const TextStyle(fontSize: 14, color: textColor),
                        decoration: InputDecoration(
                          hintText: field.hintText,
                          hintStyle: TextStyle(
                            color: textLightColor.withValues(alpha: 0.5),
                            fontSize: 14,
                          ),
                          contentPadding: const EdgeInsets.symmetric(
                            horizontal: 16,
                            vertical: 12,
                          ),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: const BorderSide(color: borderColor),
                          ),
                          enabledBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: const BorderSide(color: borderColor),
                          ),
                          focusedBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: const BorderSide(color: primaryColor),
                          ),
                          filled: true,
                          fillColor: Colors.white,
                        ),
                      ),
                    ],
                  ),
                );
              }),

              // Additional Widgets
              if (additionalWidgets != null) ...additionalWidgets!,

              const SizedBox(height: 24),

              // Buttons
              Row(
                children: [
                  Expanded(
                    child: TextButton(
                      onPressed: onCancel,
                      style: TextButton.styleFrom(
                        backgroundColor: const Color(0xFFF5F5F5),
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      child: Text(
                        'cancel'.tr,
                        style: const TextStyle(
                          color: textLightColor,
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: ElevatedButton(
                      onPressed: onSave,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: primaryColor,
                        elevation: 0,
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      child: Text(
                        'save'.tr,
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
            ],
          ),
        ),
      ),
    );
  }
}
