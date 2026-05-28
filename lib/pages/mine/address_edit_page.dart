import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../utils/constants.dart';
import '../../utils/network/api_service.dart';
import '../../utils/toast_utils.dart';

class AddressEditPage extends StatefulWidget {
  final String initialAddress;
  final String initialDetailAddress;
  final Function(int regionId, String detailAddress, String fullRegionName)
  onSave;

  const AddressEditPage({
    super.key,
    required this.initialAddress,
    required this.initialDetailAddress,
    required this.onSave,
  });

  @override
  State<AddressEditPage> createState() => _AddressEditPageState();
}

class _AddressEditPageState extends State<AddressEditPage> {
  late TextEditingController _detailController;
  String _selectedAddress = '';
  int? _selectedRegionId;
  List<dynamic> _regionTree = [];
  bool _isLoadingRegions = false;

  @override
  void initState() {
    super.initState();
    _detailController = TextEditingController(
      text: widget.initialDetailAddress,
    );
    _selectedAddress = widget.initialAddress;
    _fetchRegionTree();
  }

  Future<void> _fetchRegionTree() async {
    setState(() => _isLoadingRegions = true);
    try {
      final lang = Get.locale?.languageCode == 'zh' ? 'zh' : 'en';
      final response = await ApiService.getRegionTree(lang);
      if (response['code'] == 200) {
        setState(() {
          _regionTree = response['data'] ?? [];
        });
      }
    } catch (e) {
      ToastUtils.error('fetch_failed'.tr);
    } finally {
      setState(() => _isLoadingRegions = false);
    }
  }

  void _showRegionPicker() {
    if (_regionTree.isEmpty) {
      if (_isLoadingRegions) {
        ToastUtils.info('loading'.tr);
      } else {
        _fetchRegionTree();
      }
      return;
    }

    _showMultiLevelPicker(_regionTree, []);
  }

  void _showMultiLevelPicker(
    List<dynamic> currentOptions,
    List<String> selectedNames, {
    List<List<dynamic>>? history,
  }) {
    final currentHistory = history ?? [];
    Get.bottomSheet(
      Container(
        height: Get.height * 0.6, // 稍微增加高度以适应更好的排版
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
        ),
        child: Column(
          children: [
            // 顶部控制栏
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
              decoration: BoxDecoration(
                border: Border(
                  bottom: BorderSide(color: Colors.grey.withValues(alpha: 0.2)),
                ),
              ),
              child: Row(
                children: [
                  // 左侧：后退按钮 或 占位
                  if (currentHistory.isNotEmpty)
                    IconButton(
                      icon: const Icon(
                        Icons.arrow_back_ios_new,
                        size: 20,
                        color: textColor,
                      ),
                      onPressed: () {
                        Get.back();
                        final previousOptions = currentHistory.last;
                        final newHistory = List<List<dynamic>>.from(
                          currentHistory,
                        )..removeLast();
                        final newSelectedNames = List<String>.from(
                          selectedNames,
                        )..removeLast();

                        _showMultiLevelPicker(
                          previousOptions,
                          newSelectedNames,
                          history: newHistory,
                        );
                      },
                      padding: EdgeInsets.zero,
                      constraints: const BoxConstraints(),
                    )
                  else
                    const SizedBox(width: 20), // 保持标题居中的占位
                  // 中间：标题
                  Expanded(
                    child: Text(
                      selectedNames.isEmpty
                          ? 'select_address'.tr
                          : selectedNames.last, // 显示当前层级名称
                      textAlign: TextAlign.center,
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: textColor,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),

                  // 右侧：关闭按钮
                  IconButton(
                    icon: const Icon(
                      Icons.close,
                      size: 24,
                      color: textLightColor,
                    ),
                    onPressed: () => Get.back(),
                    padding: EdgeInsets.zero,
                    constraints: const BoxConstraints(),
                  ),
                ],
              ),
            ),

            // 已选路径面包屑提示 (可选)
            if (selectedNames.isNotEmpty)
              Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(
                  horizontal: 20,
                  vertical: 12,
                ),
                color: backgroundColor,
                child: Text(
                  selectedNames.join(' > '),
                  style: const TextStyle(
                    fontSize: 13,
                    color: primaryColor,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),

            // 列表内容
            Expanded(
              child: ListView.separated(
                itemCount: currentOptions.length,
                separatorBuilder: (context, index) => Divider(
                  height: 1,
                  indent: 20,
                  endIndent: 20,
                  color: Colors.grey.withValues(alpha: 0.1),
                ),
                itemBuilder: (context, index) {
                  final option = currentOptions[index];
                  final name = option['name'] ?? '';
                  final children = option['children'] as List<dynamic>?;
                  final hasChildren = children != null && children.isNotEmpty;

                  return InkWell(
                    onTap: () {
                      final List<String> newSelectedNames = [
                        ...selectedNames,
                        name as String,
                      ];
                      if (hasChildren) {
                        Get.back(); // 关闭当前层
                        final newHistory = List<List<dynamic>>.from(
                          currentHistory,
                        )..add(currentOptions);
                        _showMultiLevelPicker(
                          children,
                          newSelectedNames,
                          history: newHistory,
                        );
                      } else {
                        setState(() {
                          _selectedAddress = newSelectedNames.join(', ');
                          _selectedRegionId = option['id'] as int?;
                        });
                        Get.back();
                      }
                    },
                    child: Padding(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 20,
                        vertical: 16,
                      ),
                      child: Row(
                        children: [
                          Expanded(
                            child: Text(
                              name,
                              style: const TextStyle(
                                fontSize: 16,
                                color: textColor,
                              ),
                            ),
                          ),
                          if (hasChildren)
                            const Icon(
                              Icons.chevron_right,
                              color: textLightColor,
                              size: 20,
                            ),
                        ],
                      ),
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: backgroundColor,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: textColor),
          onPressed: () => Get.back(),
        ),
        title: Text(
          'edit_address'.tr,
          style: const TextStyle(
            color: textColor,
            fontSize: 18,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
      body: SingleChildScrollView(
        child: Column(
          children: [
            const SizedBox(height: 16),
            Container(
              margin: const EdgeInsets.symmetric(horizontal: 16),
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.05),
                    blurRadius: 10,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Address Selection
                  GestureDetector(
                    onTap: _showRegionPicker,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'address'.tr,
                          style: const TextStyle(
                            fontSize: 14,
                            color: textLightColor,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Row(
                          children: [
                            Expanded(
                              child: Text(
                                _selectedAddress.isEmpty
                                    ? 'select_address'.tr
                                    : _selectedAddress,
                                style: TextStyle(
                                  fontSize: 16,
                                  color: _selectedAddress.isEmpty
                                      ? textLightColor
                                      : textColor,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ),
                            const Icon(
                              Icons.chevron_right,
                              color: textLightColor,
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                  const Padding(
                    padding: EdgeInsets.symmetric(vertical: 16),
                    child: Divider(height: 1),
                  ),
                  // Additional Address
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'additional_address'.tr,
                        style: const TextStyle(
                          fontSize: 14,
                          color: textLightColor,
                        ),
                      ),
                      const SizedBox(height: 8),
                      TextField(
                        controller: _detailController,
                        decoration: InputDecoration(
                          hintText: 'enter_additional_address'.tr,
                          hintStyle: const TextStyle(color: textLightColor),
                          border: InputBorder.none,
                          enabledBorder: InputBorder.none,
                          focusedBorder: InputBorder.none,
                          contentPadding: EdgeInsets.zero,
                        ),
                        style: const TextStyle(
                          fontSize: 16,
                          color: textColor,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 25),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: SizedBox(
                width: double.infinity,
                height: 50,
                child: ElevatedButton(
                  onPressed: () {
                    if (_selectedRegionId == null) {
                      ToastUtils.error('select_address'.tr);
                      return;
                    }
                    widget.onSave(
                      _selectedRegionId!,
                      _detailController.text,
                      _selectedAddress,
                    );
                    Get.back();
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: primaryColor,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(25),
                    ),
                    elevation: 0,
                  ),
                  child: Text(
                    'use_address'.tr,
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
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
