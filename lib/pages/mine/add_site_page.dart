import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../utils/constants.dart';
import '../../controllers/station_controller.dart';
import '../../utils/toast_utils.dart';
import 'address_edit_page.dart';

class AddSitePage extends StatefulWidget {
  const AddSitePage({super.key});

  @override
  State<AddSitePage> createState() => _AddSitePageState();
}

class _AddSitePageState extends State<AddSitePage> {
  final StationController _controller = Get.find<StationController>();
  final TextEditingController _nameController = TextEditingController();

  int? _tempRegionId;
  String _tempDetailAddress = '';
  String _tempFullAddress = '';
  bool _isLoading = false;

  @override
  void dispose() {
    _nameController.dispose();
    super.dispose();
  }

  Future<void> _handleSave() async {
    if (_isLoading) return;

    final name = _nameController.text.trim();
    if (name.isEmpty) {
      ToastUtils.error('enter_site_name'.tr);
      return;
    }
    if (_tempRegionId == null) {
      ToastUtils.error('select_address'.tr);
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      final success = await _controller.saveOrEditStation({
        'stationName': name,
        'regionId': _tempRegionId,
        'detailAddress': _tempDetailAddress,
      });

      if (success) {
        Get.back();
        ToastUtils.success('add_successfully'.tr);
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        Scaffold(
          backgroundColor: backgroundColor,
          appBar: AppBar(
            backgroundColor: Colors.white,
            elevation: 0,
            leading: IconButton(
              icon: const Icon(Icons.arrow_back, color: textColor),
              onPressed: () => Get.back(),
            ),
            title: Text(
              'new_station'.tr,
              style: const TextStyle(
                color: textColor,
                fontSize: 18,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          body: SingleChildScrollView(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Site Name
                      Text(
                        'site_name'.tr,
                        style: const TextStyle(
                          fontSize: 14,
                          color: textLightColor,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      const SizedBox(height: 8),
                      TextField(
                        controller: _nameController,
                        style: const TextStyle(fontSize: 16, color: textColor),
                        decoration: InputDecoration(
                          hintText: 'enter_site_name'.tr,
                          hintStyle: TextStyle(
                            color: textLightColor.withValues(alpha: 0.5),
                            fontSize: 16,
                          ),
                          contentPadding: const EdgeInsets.symmetric(
                            horizontal: 12,
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
                        ),
                      ),
                      const SizedBox(height: 24),

                      // Address Selection
                      Text(
                        'address'.tr,
                        style: const TextStyle(
                          fontSize: 14,
                          color: textLightColor,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      const SizedBox(height: 8),
                      GestureDetector(
                        behavior: HitTestBehavior.opaque,
                        onTap: () {
                          Get.to(
                            () => AddressEditPage(
                              initialAddress: _tempFullAddress,
                              initialDetailAddress: _tempDetailAddress,
                              onSave: (regionId, detail, fullRegionName) {
                                setState(() {
                                  _tempRegionId = regionId;
                                  _tempDetailAddress = detail;
                                  _tempFullAddress = '$fullRegionName $detail'
                                      .trim();
                                });
                              },
                            ),
                          );
                        },
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                            vertical: 12,
                            horizontal: 12,
                          ),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(color: borderColor),
                          ),
                          child: Row(
                            children: [
                              Expanded(
                                child: Text(
                                  _tempFullAddress.isNotEmpty
                                      ? _tempFullAddress
                                      : 'select_address'.tr,
                                  style: TextStyle(
                                    fontSize: 16,
                                    color: _tempFullAddress.isNotEmpty
                                        ? textColor
                                        : textLightColor.withValues(alpha: 0.5),
                                  ),
                                  maxLines: 2,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                              const Icon(
                                Icons.chevron_right,
                                color: textLightColor,
                                size: 24,
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 40),
                SizedBox(
                  width: double.infinity,
                  height: 50,
                  child: ElevatedButton(
                    onPressed: _handleSave,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: primaryColor,
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(25),
                      ),
                      elevation: 0,
                    ),
                    child: Text(
                      'save'.tr,
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
        if (_isLoading)
          Container(
            color: Colors.black.withValues(alpha: 0.3),
            child: const Center(
              child: CircularProgressIndicator(
                valueColor: AlwaysStoppedAnimation<Color>(primaryColor),
              ),
            ),
          ),
      ],
    );
  }
}
