import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../../utils/constants.dart';
import '../../../routes/app_routes.dart';
import '../../../controllers/feedback_controller.dart';
import '../../../model/ticket_model.dart';

class FeedbackPage extends StatelessWidget {
  const FeedbackPage({super.key});

  @override
  Widget build(BuildContext context) {
    final controller = Get.isRegistered<FeedbackController>()
        ? Get.find<FeedbackController>()
        : Get.put(FeedbackController());

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
          'feedback'.tr,
          style: const TextStyle(
            color: textColor,
            fontSize: 18,
            fontWeight: FontWeight.w600,
          ),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.add, color: textColor),
            onPressed: () async {
              final result = await Get.toNamed(AppRoutes.newTicket);
              if (result == true) {
                controller.refreshTickets();
              }
            },
          ),
        ],
      ),
      body: SafeArea(
        child: Obx(() {
          if (controller.isLoading.value && controller.tickets.isEmpty) {
            return const Center(child: CircularProgressIndicator());
          }

          if (controller.tickets.isEmpty) {
            return RefreshIndicator(
              onRefresh: controller.refreshTickets,
              child: ListView(
                children: [
                  SizedBox(height: MediaQuery.of(context).size.height * 0.2),
                  Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Container(
                          width: 120,
                          height: 120,
                          decoration: BoxDecoration(
                            color: primaryColor.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(60),
                          ),
                          child: const Center(
                            child: Icon(
                              Icons.question_mark,
                              size: 60,
                              color: primaryColor,
                            ),
                          ),
                        ),
                        const SizedBox(height: 20),
                        Text(
                          'no_ticket'.tr,
                          style: const TextStyle(
                            fontSize: 16,
                            color: textLightColor,
                          ),
                        ),
                        const SizedBox(height: 40),
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 40),
                          child: SizedBox(
                            width: double.infinity,
                            child: OutlinedButton(
                              onPressed: () async {
                                final result = await Get.toNamed(
                                  AppRoutes.newTicket,
                                );
                                if (result == true) {
                                  controller.refreshTickets();
                                }
                              },
                              style: OutlinedButton.styleFrom(
                                side: const BorderSide(color: primaryColor),
                                padding: const EdgeInsets.symmetric(
                                  vertical: 16,
                                ),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(12),
                                ),
                              ),
                              child: Text(
                                '+ ${'new_ticket'.tr}',
                                style: const TextStyle(
                                  color: primaryColor,
                                  fontSize: 16,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            );
          }

          return RefreshIndicator(
            onRefresh: controller.refreshTickets,
            child: ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: controller.tickets.length,
              itemBuilder: (context, index) {
                final ticket = controller.tickets[index];
                return _buildTicketCard(ticket);
              },
            ),
          );
        }),
      ),
    );
  }

  Widget _buildTicketCard(TicketModel ticket) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: primaryColor.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: Text(
                    ticket.ticketType == '1' ? 'inquiry'.tr : 'device_issue'.tr,
                    style: const TextStyle(
                      color: primaryColor,
                      fontSize: 12,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
                Text(
                  'ID: ${ticket.id}',
                  style: const TextStyle(color: textLightColor, fontSize: 12),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Text(
              ticket.remark ?? '',
              style: const TextStyle(
                color: textColor,
                fontSize: 14,
                fontWeight: FontWeight.w500,
              ),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
            const SizedBox(height: 12),
            if (ticket.picture != null && ticket.picture!.isNotEmpty)
              _buildImageThumbnails(ticket.picture!),
            const Divider(height: 24),
            Row(
              children: [
                const Icon(
                  Icons.contact_mail_outlined,
                  size: 14,
                  color: textLightColor,
                ),
                const SizedBox(width: 4),
                Text(
                  ticket.contact ?? '',
                  style: const TextStyle(color: textLightColor, fontSize: 12),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildImageThumbnails(String pictureStr) {
    final urls = pictureStr
        .split(',')
        .where((u) => u.trim().isNotEmpty)
        .toList();
    if (urls.isEmpty) return const SizedBox.shrink();

    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: SizedBox(
        height: 60,
        child: ListView.builder(
          scrollDirection: Axis.horizontal,
          itemCount: urls.length,
          itemBuilder: (context, index) {
            final url = urls[index].trim();
            return GestureDetector(
              onTap: () => _showFullScreenImage(context, urls, index),
              child: Container(
                width: 60,
                margin: const EdgeInsets.only(right: 8),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(4),
                  border: Border.all(color: borderColor),
                  image: DecorationImage(
                    image: NetworkImage(url),
                    fit: BoxFit.cover,
                  ),
                ),
              ),
            );
          },
        ),
      ),
    );
  }

  void _showFullScreenImage(
    BuildContext context,
    List<String> urls,
    int initialIndex,
  ) {
    Get.to(
      () => Scaffold(
        backgroundColor: Colors.black,
        body: Stack(
          children: [
            PageView.builder(
              itemCount: urls.length,
              controller: PageController(initialPage: initialIndex),
              itemBuilder: (context, index) {
                return Center(
                  child: InteractiveViewer(
                    minScale: 0.5,
                    maxScale: 4.0,
                    child: Image.network(
                      urls[index].trim(),
                      fit: BoxFit.contain,
                      loadingBuilder: (context, child, loadingProgress) {
                        if (loadingProgress == null) return child;
                        return const Center(
                          child: CircularProgressIndicator(color: Colors.white),
                        );
                      },
                    ),
                  ),
                );
              },
            ),
            SafeArea(
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: IconButton(
                  icon: const Icon(Icons.close, color: Colors.white, size: 30),
                  onPressed: () => Get.back(),
                ),
              ),
            ),
          ],
        ),
      ),
      opaque: false,
      transition: Transition.fade,
    );
  }
}
