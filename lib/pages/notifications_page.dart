import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../utils/constants.dart';

class NotificationsPage extends StatefulWidget {
  const NotificationsPage({super.key});

  @override
  State<NotificationsPage> createState() => _NotificationsPageState();
}

class _NotificationsPageState extends State<NotificationsPage> {
  // 消息类型
  String _selectedType = 'Device';
  // 消息状态
  String _selectedStatus = 'All';
  // 选中的站点
  String _selectedSite = 'All Sites';
  // 站点列表
  final List<String> _sites = ['All Sites', 'Sunbox', '其他站点'];
  // 是否显示站点下拉菜单
  bool _showSiteDropdown = false;

  // 设备消息列表
  final List<NotificationItem> _deviceNotifications = [
    NotificationItem(
      id: 1,
      title: 'Fan Speed Too Low',
      content: 'If the issue persists, please contact the customer service.',
      site: 'Sunbox',
      time: 'Feb 26, 2026 05:08',
      type: 'Warning',
      read: false,
    ),
    NotificationItem(
      id: 2,
      title: 'Warning Recovery',
      content:
          'The warning has been resolved, and the device is now functioning normally.',
      site: 'Sunbox',
      time: 'Jan 28, 2026 10:15',
      type: 'Recovery',
      read: true,
    ),
    NotificationItem(
      id: 3,
      title: 'Fan Speed Too Low',
      content: 'If the issue persists, please contact the customer service.',
      site: 'Sunbox',
      time: 'Jan 21, 2026 08:45',
      type: 'Warning',
      read: true,
    ),
    NotificationItem(
      id: 4,
      title: 'Connected',
      content: 'The device is successfully connected and functioning properly.',
      site: 'Sunbox',
      time: 'Dec 9, 2025 07:08',
      type: 'Info',
      read: true,
    ),
  ];

  // 系统消息列表
  final List<NotificationItem> _systemNotifications = [
    NotificationItem(
      id: 1,
      title: 'OTA Update Successfully',
      content: 'Your device has been successfully updated to 12.0',
      site: 'Sunbox',
      time: 'Dec 2, 2025 12:42',
      type: 'Info',
      read: false,
    ),
    NotificationItem(
      id: 2,
      title: 'OTA Update Successfully',
      content: 'Your device has been successfully updated to 11.6',
      site: 'Sunbox',
      time: 'Nov 1, 2025 12:41',
      type: 'Info',
      read: true,
    ),
    NotificationItem(
      id: 3,
      title: 'OTA Update Successfully',
      content: 'Your device has been successfully updated to 11.5.1',
      site: 'Sunbox',
      time: 'Apr 5, 2025 09:19',
      type: 'Info',
      read: true,
    ),
    NotificationItem(
      id: 4,
      title: 'OTA Update Successfully',
      content: 'Your device has been successfully updated to 11.5.0',
      site: 'Sunbox',
      time: 'Apr 1, 2025 09:19',
      type: 'Info',
      read: true,
    ),
    NotificationItem(
      id: 5,
      title: 'OTA Update Successfully',
      content: 'Your device has been successfully updated to 11.4',
      site: 'Sunbox',
      time: 'Mar 15, 2025 09:19',
      type: 'Info',
      read: true,
    ),
  ];

  // 清除未读消息
  void _clearUnreadMessages() {
    setState(() {
      if (_selectedType == 'Device') {
        for (var notification in _deviceNotifications) {
          notification.read = true;
        }
      } else {
        for (var notification in _systemNotifications) {
          notification.read = true;
        }
      }
    });
    Get.snackbar('success'.tr, 'all_unread_marked'.tr);
  }

  // 获取当前显示的消息列表
  List<NotificationItem> _getCurrentNotifications() {
    List<NotificationItem> notifications = _selectedType == 'Device'
        ? _deviceNotifications
        : _systemNotifications;

    // 按状态筛选
    if (_selectedStatus == 'Read') {
      notifications = notifications.where((n) => n.read).toList();
    } else if (_selectedStatus == 'Unread') {
      notifications = notifications.where((n) => !n.read).toList();
    }

    // 按站点筛选
    if (_selectedSite != 'All Sites') {
      notifications = notifications
          .where((n) => n.site == _selectedSite)
          .toList();
    }

    return notifications;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: textColor),
          onPressed: () {
            Get.back();
          },
        ),
        title: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              'notifications'.tr,
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: textColor,
              ),
            ),
            IconButton(
              onPressed: _clearUnreadMessages,
              icon: const Icon(
                Icons.cleaning_services,
                color: primaryColor,
                size: 20,
              ),
              tooltip: 'clear_all_unread'.tr,
            ),
          ],
        ),
      ),
      body: Container(
        color: const Color(0xFFF5F5F5),
        child: Column(
          children: [
            // 消息类型切换
            Container(
              color: Colors.white,
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Row(
                children: [
                  GestureDetector(
                    onTap: () {
                      setState(() {
                        _selectedType = 'Device';
                        _selectedStatus = 'All';
                      });
                    },
                    child: Container(
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      margin: const EdgeInsets.only(right: 20),
                      child: Text(
                        'device'.tr,
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: _selectedType == 'Device'
                              ? FontWeight.bold
                              : FontWeight.normal,
                          color: _selectedType == 'Device'
                              ? primaryColor
                              : textColor,
                        ),
                      ),
                    ),
                  ),
                  GestureDetector(
                    onTap: () {
                      setState(() {
                        _selectedType = 'System';
                        _selectedStatus = 'All';
                      });
                    },
                    child: Container(
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      child: Text(
                        'system'.tr,
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: _selectedType == 'System'
                              ? FontWeight.bold
                              : FontWeight.normal,
                          color: _selectedType == 'System'
                              ? primaryColor
                              : textColor,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 1),
            // 消息状态筛选
            Container(
              color: Colors.white,
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
              child: Row(
                children: [
                  GestureDetector(
                    onTap: () {
                      setState(() {
                        _selectedStatus = 'All';
                      });
                    },
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 6,
                      ),
                      margin: const EdgeInsets.only(right: 10),
                      decoration: BoxDecoration(
                        color: _selectedStatus == 'All'
                            ? primaryColor
                            : const Color(0xFFF5F5F5),
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: Text(
                        'all'.tr,
                        style: TextStyle(
                          fontSize: 12,
                          color: _selectedStatus == 'All'
                              ? Colors.white
                              : textColor,
                        ),
                      ),
                    ),
                  ),
                  GestureDetector(
                    onTap: () {
                      setState(() {
                        _selectedStatus = 'Read';
                      });
                    },
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 6,
                      ),
                      margin: const EdgeInsets.only(right: 10),
                      decoration: BoxDecoration(
                        color: _selectedStatus == 'Read'
                            ? primaryColor
                            : const Color(0xFFF5F5F5),
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: Text(
                        'read'.tr,
                        style: TextStyle(
                          fontSize: 12,
                          color: _selectedStatus == 'Read'
                              ? Colors.white
                              : textColor,
                        ),
                      ),
                    ),
                  ),
                  GestureDetector(
                    onTap: () {
                      setState(() {
                        _selectedStatus = 'Unread';
                      });
                    },
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 6,
                      ),
                      decoration: BoxDecoration(
                        color: _selectedStatus == 'Unread'
                            ? primaryColor
                            : const Color(0xFFF5F5F5),
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: Text(
                        'unread'.tr,
                        style: TextStyle(
                          fontSize: 12,
                          color: _selectedStatus == 'Unread'
                              ? Colors.white
                              : textColor,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 1),
            // 站点选择
            Container(
              color: Colors.white,
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
              child: GestureDetector(
                onTap: () {
                  setState(() {
                    _showSiteDropdown = !_showSiteDropdown;
                  });
                },
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      _selectedSite,
                      style: TextStyle(fontSize: 14, color: textColor),
                    ),
                    const Icon(Icons.keyboard_arrow_down, color: textColor),
                  ],
                ),
              ),
            ),
            // 站点下拉菜单
            if (_showSiteDropdown)
              Container(
                color: Colors.white,
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: Column(
                  children: _sites.map((site) {
                    return GestureDetector(
                      onTap: () {
                        setState(() {
                          _selectedSite = site;
                          _showSiteDropdown = false;
                        });
                      },
                      child: Container(
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              site,
                              style: TextStyle(
                                fontSize: 14,
                                color: _selectedSite == site
                                    ? primaryColor
                                    : textColor,
                              ),
                            ),
                            if (_selectedSite == site)
                              const Icon(
                                Icons.check,
                                color: primaryColor,
                                size: 16,
                              ),
                          ],
                        ),
                      ),
                    );
                  }).toList(),
                ),
              ),
            const SizedBox(height: 1),
            // 消息列表
            Expanded(
              child: ListView.builder(
                itemCount: _getCurrentNotifications().length,
                itemBuilder: (context, index) {
                  final notification = _getCurrentNotifications()[index];
                  return Container(
                    color: Colors.white,
                    padding: const EdgeInsets.symmetric(
                      horizontal: 20,
                      vertical: 16,
                    ),
                    margin: const EdgeInsets.only(bottom: 1),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // 图标
                        Container(
                          width: 40,
                          height: 40,
                          decoration: BoxDecoration(
                            color: _getNotificationColor(notification.type),
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: Center(
                            child: _getNotificationIcon(notification.type),
                          ),
                        ),
                        const SizedBox(width: 12),
                        // 消息内容
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                notification.title,
                                style: TextStyle(
                                  fontSize: 14,
                                  fontWeight: FontWeight.bold,
                                  color: textColor,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                notification.content,
                                style: TextStyle(
                                  fontSize: 12,
                                  color: textLightColor,
                                ),
                                maxLines: 2,
                                overflow: TextOverflow.ellipsis,
                              ),
                              const SizedBox(height: 8),
                              Row(
                                mainAxisAlignment:
                                    MainAxisAlignment.spaceBetween,
                                children: [
                                  Text(
                                    notification.site,
                                    style: TextStyle(
                                      fontSize: 12,
                                      color: textLightColor,
                                    ),
                                  ),
                                  Text(
                                    notification.time,
                                    style: TextStyle(
                                      fontSize: 12,
                                      color: textLightColor,
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                        // 未读标记
                        if (!notification.read)
                          Container(
                            width: 8,
                            height: 8,
                            decoration: BoxDecoration(
                              color: primaryColor,
                              borderRadius: BorderRadius.circular(4),
                            ),
                          ),
                      ],
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  // 根据消息类型获取颜色
  Color _getNotificationColor(String type) {
    switch (type) {
      case 'Warning':
        return const Color(0xFFFFE0E0);
      case 'Recovery':
        return const Color(0xFFE0F5E0);
      case 'Info':
        return const Color(0xFFE0E0FF);
      default:
        return const Color(0xFFF0F0F0);
    }
  }

  // 根据消息类型获取图标
  Icon _getNotificationIcon(String type) {
    switch (type) {
      case 'Warning':
        return const Icon(Icons.warning, color: Colors.red, size: 20);
      case 'Recovery':
        return const Icon(Icons.check_circle, color: Colors.green, size: 20);
      case 'Info':
        return const Icon(Icons.info, color: Colors.blue, size: 20);
      default:
        return const Icon(Icons.notifications, color: textColor, size: 20);
    }
  }
}

class NotificationItem {
  final int id;
  final String title;
  final String content;
  final String site;
  final String time;
  final String type;
  bool read;

  NotificationItem({
    required this.id,
    required this.title,
    required this.content,
    required this.site,
    required this.time,
    required this.type,
    required this.read,
  });
}
