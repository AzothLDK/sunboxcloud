import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../utils/constants.dart';
import '../utils/network/api_service.dart';

class SitePage extends StatefulWidget {
  const SitePage({super.key});

  @override
  State<SitePage> createState() => _SitePageState();
}

class _SitePageState extends State<SitePage> {
  List<Map<String, dynamic>> _stationList = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadStationList();
  }

  Future<void> _loadStationList() async {
    try {
      final result = await ApiService.getStationList();
      if (result['code'] == 200 && result['data'] != null) {
        List<dynamic> data = result['data'];
        setState(() {
          _stationList = data
              .map(
                (e) => {
                  'id': e['id'],
                  'stationName': e['stationName'],
                  'detailAddress': e['detailAddress'],
                },
              )
              .toList();
          _isLoading = false;
        });
      } else {
        setState(() {
          _isLoading = false;
        });
      }
    } catch (e) {
      setState(() {
        _isLoading = false;
      });
    }
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
          onPressed: () {
            Get.back();
          },
        ),
        title: Text(
          'site'.tr,
          style: TextStyle(
            color: textColor,
            fontSize: 18,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _stationList.isEmpty
          ? Center(
              child: Text(
                'no_site_data'.tr,
                style: TextStyle(color: textLightColor, fontSize: 16),
              ),
            )
          : ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: _stationList.length,
              itemBuilder: (context, index) {
                final station = _stationList[index];
                return Container(
                  margin: const EdgeInsets.only(bottom: 12),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: ListTile(
                    leading: Container(
                      width: 48,
                      height: 48,
                      decoration: BoxDecoration(
                        color: primaryColor.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: const Icon(Icons.home, color: primaryColor),
                    ),
                    title: Text(
                      station['stationName'] ?? '',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w500,
                        color: textColor,
                      ),
                    ),
                    subtitle: Text(
                      station['detailAddress'] ?? '',
                      style: TextStyle(fontSize: 14, color: textLightColor),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    trailing: const Icon(
                      Icons.chevron_right,
                      color: textLightColor,
                    ),
                    onTap: () {
                      Get.to(SiteInfoPage(station: station));
                    },
                  ),
                );
              },
            ),
    );
  }
}

class SiteInfoPage extends StatefulWidget {
  final Map<String, dynamic> station;

  const SiteInfoPage({super.key, required this.station});

  @override
  State<SiteInfoPage> createState() => _SiteInfoPageState();
}

class _SiteInfoPageState extends State<SiteInfoPage> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: backgroundColor,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: textColor),
          onPressed: () {
            Get.back();
          },
        ),
        title: Text(
          'site_info'.tr,
          style: TextStyle(
            color: textColor,
            fontSize: 18,
            fontWeight: FontWeight.w600,
          ),
        ),
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 16),
            child: Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: secondaryColor,
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Icon(Icons.share, color: Colors.black, size: 20),
            ),
          ),
        ],
      ),
      body: Container(
        color: backgroundColor,
        child: Column(
          children: [
            Container(
              margin: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Column(
                children: [
                  ListTile(
                    title: Text(
                      'site_name'.tr,
                      style: TextStyle(fontSize: 14, color: textLightColor),
                    ),
                    subtitle: Text(
                      widget.station['stationName'] ?? '',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w500,
                        color: textColor,
                      ),
                    ),
                    trailing: const Icon(
                      Icons.chevron_right,
                      color: textLightColor,
                    ),
                  ),
                  const Divider(height: 1, indent: 16, endIndent: 16),
                  ListTile(
                    title: Text(
                      'address'.tr,
                      style: TextStyle(fontSize: 14, color: textLightColor),
                    ),
                    subtitle: Text(
                      widget.station['detailAddress'] ?? '',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w500,
                        color: textColor,
                      ),
                    ),
                    trailing: const Icon(
                      Icons.chevron_right,
                      color: textLightColor,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
